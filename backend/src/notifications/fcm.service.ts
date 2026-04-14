import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private readonly messaging: admin.messaging.Messaging | null = null;

  constructor(private readonly prisma: PrismaService) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (projectId && clientEmail && privateKey) {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
        });
      }
      this.messaging = admin.messaging();
    } else {
      this.logger.warn(
        'Firebase credentials not configured — push notifications disabled. ' +
          'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY in .env',
      );
    }
  }

  /** Send a push to a single FCM token. Never throws — failures are logged only. */
  async sendToToken(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.messaging || !token) return;
    try {
      await this.messaging.send({
        token,
        notification: { title, body },
        ...(data && { data }),
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
    } catch (err) {
      this.logger.warn(`FCM send failed [${token.slice(0, 10)}…]: ${err}`);
    }
  }

  /**
   * Look up the FCM token for the parent of the given student and send a push.
   * No-ops silently if the student has no parent or the parent has no token.
   */
  async notifyParentOfStudent(
    studentId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const student = await this.prisma.student.findUnique({
      where: { id: studentId },
      select: {
        parent: {
          select: { user: { select: { fcmToken: true } } },
        },
      },
    });
    const token = student?.parent?.user?.fcmToken;
    if (token) await this.sendToToken(token, title, body, data);
  }

  /**
   * Look up FCM tokens for all parents whose children are enrolled on a trip's
   * bus route (matched via student.routeName = bus.routeName), then send.
   * Deduplicates tokens so a parent with multiple children on the same route
   * only receives one notification.
   */
  async notifyParentsOfTrip(
    tripId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { bus: { select: { routeName: true } } },
    });
    if (!trip) return;

    const students = await this.prisma.student.findMany({
      where: { routeName: trip.bus.routeName },
      select: {
        parent: {
          select: { user: { select: { fcmToken: true } } },
        },
      },
    });

    const tokens = [
      ...new Set(
        students
          .map((s) => s.parent?.user?.fcmToken)
          .filter((t): t is string => !!t),
      ),
    ];

    await Promise.all(tokens.map((t) => this.sendToToken(t, title, body, data)));
  }
}
