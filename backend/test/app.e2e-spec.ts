import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { AllExceptionsFilter } from './../src/common/filters/all-exceptions.filter';

/**
 * SafeRide E2E Test Suite
 *
 * These tests run against AppModule with a real DB connection.
 * Ensure DATABASE_URL is set to a test database before running.
 *
 * Run: npm run test:e2e
 */
describe('SafeRide API (e2e)', () => {
  let app: INestApplication<App>;
  let adminToken: string;
  let driverToken: string;
  let parentToken: string;

  // IDs created during setup
  let busId: string;
  let tripId: string;
  let studentId: string;
  let notificationId: string;

  /* -------------------------------------------------------------------------
   * Bootstrap
   * ---------------------------------------------------------------------- */

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  /* -------------------------------------------------------------------------
   * Health check
   * ---------------------------------------------------------------------- */

  it('GET /api — health check returns 200', () => {
    return request(app.getHttpServer())
      .get('/api')
      .expect(200)
      .expect((res) => {
        expect(res.body.status).toBe('ok');
      });
  });

  /* -------------------------------------------------------------------------
   * Auth
   * ---------------------------------------------------------------------- */

  describe('Auth', () => {
    const adminEmail = `admin_e2e_${Date.now()}@test.com`;
    const driverEmail = `driver_e2e_${Date.now()}@test.com`;
    const parentEmail = `parent_e2e_${Date.now()}@test.com`;
    const password = 'TestPass123!';

    it('POST /api/auth/signup — creates admin account', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({ email: adminEmail, password, fullName: 'E2E Admin', role: 'ADMIN' })
        .expect(201);
      expect(res.body.email).toBe(adminEmail);
    });

    it('POST /api/auth/signup — creates driver account', async () => {
      await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({ email: driverEmail, password, fullName: 'E2E Driver', role: 'DRIVER' })
        .expect(201);
    });

    it('POST /api/auth/signup — creates parent account', async () => {
      await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({ email: parentEmail, password, fullName: 'E2E Parent', role: 'PARENT' })
        .expect(201);
    });

    it('POST /api/auth/login — logs in admin and returns token', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: adminEmail, password })
        .expect(201);

      expect(res.body.token).toBeDefined();
      adminToken = res.body.token as string;
    });

    it('POST /api/auth/login — logs in driver and returns token', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: driverEmail, password })
        .expect(201);
      driverToken = res.body.token as string;
    });

    it('POST /api/auth/login — logs in parent and returns token', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: parentEmail, password })
        .expect(201);
      parentToken = res.body.token as string;
    });

    it('GET /api/auth/me — returns authenticated user', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      expect(res.body.email).toBe(adminEmail);
      expect(res.body.role).toBe('ADMIN');
    });

    it('GET /api/auth/me — returns 401 without token', () => {
      return request(app.getHttpServer()).get('/api/auth/me').expect(401);
    });

    it('POST /api/auth/login — returns 401 with wrong password', () => {
      return request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: adminEmail, password: 'WrongPass' })
        .expect(401);
    });

    it('POST /api/auth/login — returns consistent error shape', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: adminEmail, password: 'bad' })
        .expect(401);
      expect(res.body).toMatchObject({
        statusCode: 401,
        error: expect.any(String),
        message: expect.any(String),
        timestamp: expect.any(String),
        path: '/api/auth/login',
      });
    });
  });

  /* -------------------------------------------------------------------------
   * Buses & Trips (ADMIN only)
   * ---------------------------------------------------------------------- */

  describe('Buses', () => {
    it('POST /api/buses — admin creates bus', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/buses')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ plateNumber: `E2E-${Date.now()}`, capacity: 40, routeName: 'Route Alpha' })
        .expect(201);
      busId = res.body.id as string;
      expect(busId).toBeDefined();
    });

    it('POST /api/buses — driver gets 403', () => {
      return request(app.getHttpServer())
        .post('/api/buses')
        .set('Authorization', `Bearer ${driverToken}`)
        .send({ plateNumber: 'UNAUTH-01', capacity: 30, routeName: 'Route X' })
        .expect(403);
    });
  });

  describe('Trips', () => {
    it('POST /api/trips — admin creates trip', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/trips')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'E2E Morning Trip',
          busId,
          tripDate: new Date().toISOString(),
        })
        .expect(201);
      tripId = res.body.id as string;
      expect(tripId).toBeDefined();
    });
  });

  /* -------------------------------------------------------------------------
   * Students
   * ---------------------------------------------------------------------- */

  describe('Students', () => {
    it('POST /api/students — admin creates student', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/students')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          studentCode: `E2E-STU-${Date.now()}`,
          fullName: 'E2E Student',
          grade: 'Grade 3',
        })
        .expect(201);
      studentId = res.body.id as string;
      expect(studentId).toBeDefined();
    });

    it('POST /api/students — parent gets 403', () => {
      return request(app.getHttpServer())
        .post('/api/students')
        .set('Authorization', `Bearer ${parentToken}`)
        .send({ studentCode: 'UNAUTH', fullName: 'Sneaky', grade: '1' })
        .expect(403);
    });
  });

  /* -------------------------------------------------------------------------
   * Attendance
   * ---------------------------------------------------------------------- */

  describe('Attendance', () => {
    it('POST /api/attendance — admin marks student PRESENT', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/attendance')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ studentId, tripId, status: 'PRESENT' })
        .expect(201);
      expect(res.body.status).toBe('PRESENT');
    });

    it('POST /api/attendance — idempotent update to ABSENT', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/attendance')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ studentId, tripId, status: 'ABSENT' })
        .expect(201);
      expect(res.body.status).toBe('ABSENT');
    });

    it('POST /api/attendance — parent gets 403', () => {
      return request(app.getHttpServer())
        .post('/api/attendance')
        .set('Authorization', `Bearer ${parentToken}`)
        .send({ studentId, tripId, status: 'PRESENT' })
        .expect(403);
    });

    it('POST /api/attendance — returns 400 on invalid status', () => {
      return request(app.getHttpServer())
        .post('/api/attendance')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ studentId, tripId, status: 'MAYBE' })
        .expect(400);
    });

    it('GET /api/attendance/trip/:tripId — admin retrieves trip attendance', async () => {
      const res = await request(app.getHttpServer())
        .get(`/api/attendance/trip/${tripId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('GET /api/attendance/trip/:tripId — parent gets 403', () => {
      return request(app.getHttpServer())
        .get(`/api/attendance/trip/${tripId}`)
        .set('Authorization', `Bearer ${parentToken}`)
        .expect(403);
    });

    it('GET /api/attendance/trip/nonexistent — returns consistent 404 shape', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/attendance/trip/nonexistent-id')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
      expect(res.body).toMatchObject({
        statusCode: 404,
        path: '/api/attendance/trip/nonexistent-id',
      });
    });
  });

  /* -------------------------------------------------------------------------
   * Dashboard
   * ---------------------------------------------------------------------- */

  describe('Dashboard', () => {
    it('GET /api/dashboard/admin — admin gets summary', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/dashboard/admin')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      expect(res.body).toHaveProperty('counts');
      expect(res.body.counts).toHaveProperty('students');
      expect(res.body.counts).toHaveProperty('trips');
    });

    it('GET /api/dashboard/admin — driver gets 403', () => {
      return request(app.getHttpServer())
        .get('/api/dashboard/admin')
        .set('Authorization', `Bearer ${driverToken}`)
        .expect(403);
    });

    it('GET /api/dashboard/driver — driver gets their view', async () => {
      // Driver may not have a Driver profile yet, expect 200 or 404
      const res = await request(app.getHttpServer())
        .get('/api/dashboard/driver')
        .set('Authorization', `Bearer ${driverToken}`);
      expect([200, 404]).toContain(res.status);
    });

    it('GET /api/dashboard/driver — admin gets 403', () => {
      return request(app.getHttpServer())
        .get('/api/dashboard/driver')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(403);
    });

    it('GET /api/dashboard/parent — parent gets their view', async () => {
      // Parent may not have a Parent profile yet, expect 200 or 404
      const res = await request(app.getHttpServer())
        .get('/api/dashboard/parent')
        .set('Authorization', `Bearer ${parentToken}`);
      expect([200, 404]).toContain(res.status);
    });

    it('GET /api/dashboard/parent — admin gets 403', () => {
      return request(app.getHttpServer())
        .get('/api/dashboard/parent')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(403);
    });
  });

  /* -------------------------------------------------------------------------
   * Notifications
   * ---------------------------------------------------------------------- */

  describe('Notifications', () => {
    it('POST /api/notifications — admin creates notification', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/notifications')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: 'Test Alert', body: 'School bus delayed', targetRole: 'PARENT' })
        .expect(201);
      notificationId = res.body.id as string;
      expect(notificationId).toBeDefined();
    });

    it('POST /api/notifications — driver gets 403', () => {
      return request(app.getHttpServer())
        .post('/api/notifications')
        .set('Authorization', `Bearer ${driverToken}`)
        .send({ title: 'Nope', body: 'Not allowed' })
        .expect(403);
    });

    it('GET /api/notifications — admin sees all', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/notifications')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
    });

    it('GET /api/notifications — parent sees role-targeted notifications', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/notifications')
        .set('Authorization', `Bearer ${parentToken}`)
        .expect(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('PATCH /api/notifications/:id/read — admin marks notification as read', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/notifications/${notificationId}/read`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      expect(res.body.isRead).toBe(true);
    });

    it('DELETE /api/notifications/:id — admin deletes notification', () => {
      return request(app.getHttpServer())
        .delete(`/api/notifications/${notificationId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
    });

    it('DELETE /api/notifications/:id — driver gets 403', async () => {
      // Create another first
      const create = await request(app.getHttpServer())
        .post('/api/notifications')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: 'Driver notif', body: 'body', targetRole: 'DRIVER' })
        .expect(201);
      return request(app.getHttpServer())
        .delete(`/api/notifications/${create.body.id}`)
        .set('Authorization', `Bearer ${driverToken}`)
        .expect(403);
    });
  });

  /* -------------------------------------------------------------------------
   * Auth — Logout
   * ---------------------------------------------------------------------- */

  describe('Auth Logout', () => {
    it('POST /api/auth/logout — invalidates the session', async () => {
      // Login a fresh session
      const loginRes = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email: `throwaway_${Date.now()}@test.com`, password: 'nope' })
        .catch(() => null);

      // Create a fresh user and log them in
      const email = `logout_e2e_${Date.now()}@test.com`;
      await request(app.getHttpServer())
        .post('/api/auth/signup')
        .send({ email, password: 'TestPass123!', fullName: 'Logout Test', role: 'ADMIN' });
      const res = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({ email, password: 'TestPass123!' })
        .expect(201);
      const freshToken = res.body.token as string;

      // Me works before logout
      await request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${freshToken}`)
        .expect(200);

      // Logout
      await request(app.getHttpServer())
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${freshToken}`)
        .expect(201);

      // Me returns 401 after logout
      await request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${freshToken}`)
        .expect(401);

      void loginRes;
    });
  });
});
