import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

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
