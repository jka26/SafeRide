import { Injectable, Logger } from '@nestjs/common';
import { AppRole } from '../common/auth/roles.enum';
import { PrismaService } from '../database/prisma.service';
import * as admin from 'firebase-admin';

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private initialized = false;

  constructor(private readonly prisma: PrismaService) {}

  async registerToken(userId: string, token: string, platform: string) {
    return this.prisma.deviceToken.upsert({
      where: { token },
      update: { userId, platform },
      create: { userId, token, platform },
    });
  }

  async sendToRole(role: AppRole, title: string, body: string) {
    const users = await this.prisma.user.findMany({
      where: { role },
      select: { id: true },
    });
    const userIds = users.map((u) => u.id);
    if (!userIds.length) return;
    await this.sendToUsers(userIds, title, body);
  }

  async sendToUsers(userIds: string[], title: string, body: string) {
    if (!userIds.length) return;
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds } },
      select: { id: true, token: true },
    });
    if (!tokens.length) return;
    await this.sendTokens(tokens, title, body);
  }

  private async sendTokens(
    deviceTokens: Array<{ id: string; token: string }>,
    title: string,
    body: string,
  ) {
    if (!this.ensureInitialized()) {
      this.logger.warn('Firebase push not configured; skipping push dispatch.');
      return;
    }

    const messaging = admin.messaging();
    const sendPromises = deviceTokens.map(async (d) => {
      try {
        await messaging.send({
          token: d.token,
          notification: { title, body },
          android: { priority: 'high' },
        });
      } catch (error: any) {
        const code = error?.code?.toString() ?? '';
        const shouldDelete =
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token');
        if (shouldDelete) {
          await this.prisma.deviceToken.delete({ where: { id: d.id } }).catch(() => undefined);
        }
        this.logger.warn(`Push send failed (${code || 'unknown'}): ${error?.message ?? error}`);
      }
    });
    await Promise.all(sendPromises);
  }

  private ensureInitialized() {
    if (this.initialized) return true;
    if (admin.apps.length > 0) {
      this.initialized = true;
      return true;
    }

    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    if (!projectId || !clientEmail || !privateKey) {
      return false;
    }

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
    this.initialized = true;
    return true;
  }
}
