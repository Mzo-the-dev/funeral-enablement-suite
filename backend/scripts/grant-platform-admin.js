require('dotenv/config');

const { Pool } = require('pg');

const [rawIdentity, ...reasonParts] = process.argv.slice(2);
const identity = rawIdentity?.trim().toLowerCase();
const reason = reasonParts.join(' ').trim();

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is required.');
  process.exitCode = 1;
} else if (!identity || !reason) {
  console.error('Usage: npm run admin:grant -- <username-or-verified-email> <reason>');
  process.exitCode = 1;
} else if (reason.length > 500) {
  console.error('The grant reason must be 500 characters or fewer.');
  process.exitCode = 1;
} else {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  async function grantPlatformAdmin() {
    const client = await pool.connect();
    let transactionStarted = false;

    try {
      await client.query('BEGIN');
      transactionStarted = true;

      const accounts = await client.query(
        `WITH candidates AS (
           SELECT user_id
             FROM funeral_spaces.auth_login_identifier
            WHERE normalized_value = $1
           UNION
           SELECT user_id
             FROM funeral_spaces.user_contact
            WHERE contact_type = 'email'
              AND is_verified = true
              AND normalized_value = $1
         )
         SELECT account.user_id, profile.given_name, profile.surname
           FROM candidates
           JOIN funeral_spaces.app_user account USING (user_id)
           JOIN funeral_spaces.user_profile profile USING (user_id)
          WHERE account.status = 'active'
          FOR UPDATE OF account`,
        [identity],
      );

      if (accounts.rowCount !== 1) {
        throw new Error('Exactly one active, verified account must match that username or email.');
      }

      const account = accounts.rows[0];
      const existing = await client.query(
        `SELECT is_active
           FROM funeral_spaces.platform_admin
          WHERE user_id = $1
          FOR UPDATE`,
        [account.user_id],
      );

      if (existing.rows[0]?.is_active) {
        throw new Error('That account is already a platform administrator.');
      }

      if (existing.rowCount === 1) {
        await client.query(
          `UPDATE funeral_spaces.platform_admin
              SET is_active = true, granted_at = now(), granted_by_user_id = NULL,
                  grant_reason = $2, revoked_at = NULL, revoked_by_user_id = NULL
            WHERE user_id = $1`,
          [account.user_id, reason],
        );
      } else {
        await client.query(
          `INSERT INTO funeral_spaces.platform_admin
             (user_id, grant_reason)
           VALUES ($1, $2)`,
          [account.user_id, reason],
        );
      }

      await client.query(
        `INSERT INTO funeral_spaces.platform_admin_audit
           (action, target_user_id, reason, before_data, after_data)
         VALUES ('platform_admin_granted', $1, $2, $3::jsonb, $4::jsonb)`,
        [
          account.user_id,
          reason,
          JSON.stringify({ is_active: existing.rows[0]?.is_active ?? false }),
          JSON.stringify({ given_name: account.given_name, surname: account.surname }),
        ],
      );

      await client.query('COMMIT');
      transactionStarted = false;
      console.log(`Platform admin granted to ${account.given_name} ${account.surname}.`);
    } catch (error) {
      if (transactionStarted) await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
      await pool.end();
    }
  }

  grantPlatformAdmin().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}