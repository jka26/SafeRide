import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useWebSocketAdapter(new IoAdapter(app));
  const logger = new Logger('HTTP');

  app.use((req: Request, res: Response, next: NextFunction) => {
    const startedAt = Date.now();
    let responsePayload: unknown;

    const originalJson = res.json.bind(res);
    res.json = ((body: unknown) => {
      responsePayload = body;
      return originalJson(body);
    }) as Response['json'];

    res.on('finish', () => {
      const durationMs = Date.now() - startedAt;
      const base = `${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs}ms`;
      if (res.statusCode >= 400) {
        const message = extractErrorMessage(responsePayload);
        logger.warn(message ? `${base} - ${message}` : base);
        return;
      }
      logger.log(base);
    });
    next();
  });

  // ---------------------------------------------------------------------------
  // Global prefix
  // ---------------------------------------------------------------------------
  app.setGlobalPrefix('api');

  // ---------------------------------------------------------------------------
  // CORS — adjust origin list for production
  // ---------------------------------------------------------------------------
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
    credentials: true,
  });

  // ---------------------------------------------------------------------------
  // Global validation pipe
  // ---------------------------------------------------------------------------
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // ---------------------------------------------------------------------------
  // Global exception filter (consistent error envelope)
  // ---------------------------------------------------------------------------
  app.useGlobalFilters(new AllExceptionsFilter());

  // ---------------------------------------------------------------------------
  // Swagger / OpenAPI docs (available at /api/docs)
  // ---------------------------------------------------------------------------
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('SafeRide API')
      .setDescription('Backend API for the SafeRide school bus tracking app')
      .setVersion('1.0')
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'token' },
        'session-token',
      )
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  // ---------------------------------------------------------------------------
  // Start
  // ---------------------------------------------------------------------------
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`SafeRide backend listening on port ${port}`);
}

bootstrap();

function extractErrorMessage(payload: unknown): string | null {
  if (!payload || typeof payload !== 'object') return null;
  const maybeMessage = (payload as Record<string, unknown>).message;
  if (typeof maybeMessage === 'string') return maybeMessage;
  if (Array.isArray(maybeMessage)) {
    const normalized = maybeMessage
      .map((item) => item?.toString().trim())
      .filter((item): item is string => Boolean(item));
    return normalized.length > 0 ? normalized.join(', ') : null;
  }
  return maybeMessage ? maybeMessage.toString() : null;
}
