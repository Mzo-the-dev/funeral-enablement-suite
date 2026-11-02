import 'dotenv/config';
import 'reflect-metadata';

import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';

import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });
  app.useBodyParser('json', { limit: '1mb' });
  const origins = (process.env.CORS_ORIGINS ?? 'http://localhost:5322,http://127.0.0.1:5322')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.setGlobalPrefix('api');
  app.enableCors({ origin: origins, methods: ['GET', 'POST'], allowedHeaders: ['Content-Type', 'Authorization'] });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));

  const port = Number(process.env.API_PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  console.log(`Funeral Spaces development API listening on http://localhost:${port}/api`);
}

void bootstrap();
