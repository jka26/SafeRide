import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

import { AppModule } from './../src/app.module';
import { AllExceptionsFilter } from './../src/common/filters/all-exceptions.filter';

describe('Frontend/Backend Contract (e2e)', () => {
  jest.setTimeout(120000);

  let app: INestApplication<App>;
  const prisma = new PrismaClient();

  let adminToken: string;
  let driverToken: string;
  let parentToken: string;
  let tripId: string;
  let busId: string;

  const now = Date.now();
  const adminEmail = `contract_admin_${now}@test.com`;
  const driverEmail = `contract_driver_${now}@test.com`;
  const parentEmail = `contract_parent_${now}@test.com`;
  const password = 'TestPass123!';

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

    const adminHash = await bcrypt.hash(password, 10);
    await prisma.user.upsert({
      where: { email: adminEmail },
      update: { passwordHash: adminHash, fullName: 'Contract Admin', role: 'ADMIN' },
      create: { email: adminEmail, passwordHash: adminHash, fullName: 'Contract Admin', role: 'ADMIN' },
    });

    await request(app.getHttpServer())
      .post('/api/auth/signup')
      .send({ email: driverEmail, password, fullName: 'Contract Driver', role: 'DRIVER' })
      .expect(201);
    await request(app.getHttpServer())
      .post('/api/auth/signup')
      .send({ email: parentEmail, password, fullName: 'Contract Parent', role: 'PARENT' })
      .expect(201);

    const adminLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: adminEmail, password })
      .expect(201);
    adminToken = adminLogin.body.token as string;

    const driverLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: driverEmail, password })
      .expect(201);
    driverToken = driverLogin.body.token as string;

    const parentLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: parentEmail, password })
      .expect(201);
    parentToken = parentLogin.body.token as string;

    const busRes = await request(app.getHttpServer())
      .post('/api/buses')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ plateNumber: `CNT-${now}`, capacity: 40, routeName: 'Contract Route' })
      .expect(201);
    busId = busRes.body.id as string;

    const tripRes = await request(app.getHttpServer())
      .post('/api/trips')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Contract Trip',
        busId,
        tripDate: new Date().toISOString(),
      })
      .expect(201);
    tripId = tripRes.body.id as string;
  });

  afterAll(async () => {
    await prisma.$disconnect();
    await app.close();
  });

  it('auth/me shape matches frontend UserModel parser', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${parentToken}`)
      .expect(200);

    expect(res.body).toEqual(
      expect.objectContaining({
        id: expect.any(String),
        email: expect.any(String),
        role: expect.any(String),
      }),
    );
    expect(res.body.fullName).toBeDefined();
  });

  it('parent dashboard shape matches DashboardService + StudentModel + TripModel mapping', async () => {
    await request(app.getHttpServer())
      .post('/api/onboarding/parent')
      .set('Authorization', `Bearer ${parentToken}`)
      .send({
        childName: 'Contract Child',
        grade: 'Grade 4',
        stopName: 'Gate 2',
        emergencyContactName: 'Guardian',
        emergencyContactPhone: '+233000000001',
      })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/api/dashboard/parent')
      .set('Authorization', `Bearer ${parentToken}`)
      .expect(200);

    expect(Array.isArray(res.body.children)).toBe(true);
    if (res.body.children.length > 0) {
      const child = res.body.children[0];
      expect(child).toEqual(
        expect.objectContaining({
          id: expect.any(String),
          fullName: expect.any(String),
          grade: expect.any(String),
        }),
      );
      if (child.activeTrip) {
        expect(child.activeTrip).toEqual(
          expect.objectContaining({
            tripId: expect.any(String),
            status: expect.any(String),
            bus: expect.any(Object),
          }),
        );
      }
    }
  });

  it('driver dashboard shape matches DashboardService + TripModel.fromDriverDashboard', async () => {
    const driverUser = await prisma.user.findUnique({
      where: { email: driverEmail },
      select: { id: true },
    });
    const driver = await prisma.driver.findUnique({
      where: { userId: driverUser!.id },
      select: { id: true },
    });
    await prisma.trip.update({
      where: { id: tripId },
      data: { driverId: driver!.id },
    });

    const res = await request(app.getHttpServer())
      .get('/api/dashboard/driver')
      .set('Authorization', `Bearer ${driverToken}`)
      .expect(200);

    expect(Array.isArray(res.body.todaysTrips)).toBe(true);
    if (res.body.todaysTrips.length > 0) {
      const trip = res.body.todaysTrips[0];
      expect(trip).toEqual(
        expect.objectContaining({
          id: expect.any(String),
          status: expect.any(String),
          tripDate: expect.any(String),
          bus: expect.objectContaining({
            plateNumber: expect.any(String),
            routeName: expect.any(String),
          }),
          attendances: expect.any(Array),
        }),
      );
    }
  });

  it('admin dashboard shape matches DashboardService + BusModel.fromAdminTrip', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/dashboard/admin')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);

    expect(res.body).toEqual(
      expect.objectContaining({
        counts: expect.any(Object),
        todaysTrips: expect.any(Array),
        inProgressTrips: expect.any(Array),
        metrics: expect.any(Object),
      }),
    );
  });

  it('notification APIs match NotificationService and NotificationModel expectations', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/notifications')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ title: 'Contract Alert', body: 'Body', targetRole: 'PARENT' })
      .expect(201);

    const list = await request(app.getHttpServer())
      .get('/api/notifications')
      .set('Authorization', `Bearer ${parentToken}`)
      .expect(200);
    expect(Array.isArray(list.body)).toBe(true);
    if (list.body.length > 0) {
      expect(list.body[0]).toEqual(
        expect.objectContaining({
          id: expect.any(String),
          title: expect.any(String),
          body: expect.any(String),
          createdAt: expect.any(String),
        }),
      );
    }

    await request(app.getHttpServer())
      .patch(`/api/notifications/${created.body.id}/read`)
      .set('Authorization', `Bearer ${parentToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .get('/api/notifications/unread-count')
      .set('Authorization', `Bearer ${parentToken}`)
      .expect(200)
      .expect((res) => {
        expect(typeof res.body.unreadCount).toBe('number');
      });
  });

  it('emergency endpoint receives payload expected by frontend NotificationService.reportEmergency', async () => {
    await request(app.getHttpServer())
      .post('/api/notifications/emergency')
      .set('Authorization', `Bearer ${driverToken}`)
      .send({
        type: 'medical',
        tripId,
        latitude: 5.6037,
        longitude: -0.1870,
      })
      .expect(201);
  });

  it('map live endpoints used by frontend return expected keys', async () => {
    await request(app.getHttpServer())
      .post(`/api/driver/trips/${tripId}/start`)
      .set('Authorization', `Bearer ${driverToken}`)
      .expect((res) => {
        expect([201, 400]).toContain(res.status);
      });

    await request(app.getHttpServer())
      .post(`/api/driver/trips/${tripId}/location`)
      .set('Authorization', `Bearer ${driverToken}`)
      .send({ latitude: 5.6037, longitude: -0.1870 })
      .expect(201);

    const driverLive = await request(app.getHttpServer())
      .get(`/api/driver/trips/${tripId}/live`)
      .set('Authorization', `Bearer ${driverToken}`)
      .expect(200);
    expect(driverLive.body).toEqual(
      expect.objectContaining({
        trip: expect.any(Object),
        latestLocation: expect.any(Object),
        recentLocations: expect.any(Array),
      }),
    );

    const parentLive = await request(app.getHttpServer())
      .get(`/api/parent/tracking/trips/${tripId}`)
      .set('Authorization', `Bearer ${parentToken}`);
    expect([200, 403]).toContain(parentLive.status);
  });
});
