import { Injectable, OnApplicationShutdown, ServiceUnavailableException } from '@nestjs/common';
import { Pool, PoolClient, QueryResult, QueryResultRow } from 'pg';

@Injectable()
export class DatabaseService implements OnApplicationShutdown {
  private readonly pool: Pool;

  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is required. Copy backend/.env.example to backend/.env and configure it.');
    }

    this.pool = new Pool({ connectionString, max: 10, connectionTimeoutMillis: 5_000 });
    this.pool.on('error', (error: Error) => {
      console.error('Unexpected PostgreSQL pool error:', error.message);
    });
  }

  query<T extends QueryResultRow = QueryResultRow>(sql: string, values: unknown[] = []): Promise<QueryResult<T>> {
    return this.pool.query<T>(sql, values);
  }

  async transaction<T>(work: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect().catch((error: unknown) => {
      console.error('PostgreSQL connection failed:', error);
      throw new ServiceUnavailableException('The database is temporarily unavailable.');
    });

    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async onApplicationShutdown(): Promise<void> {
    await this.pool.end();
  }
}
