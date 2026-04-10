import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../database/prisma.service';
import { AppRole } from '../common/auth/roles.enum';

type SocketUser = {
  id: string;
  role: AppRole;
};

@WebSocketGateway({
  namespace: '/tracking',
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
    credentials: true,
  },
})
export class TrackingGateway implements OnGatewayConnection {
  private readonly logger = new Logger(TrackingGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(private readonly prisma: PrismaService) {}

  async handleConnection(client: Socket) {
    const raw =
      (client.handshake.auth?.token as string | undefined) ??
      (typeof client.handshake.query?.token === 'string'
        ? client.handshake.query.token
        : Array.isArray(client.handshake.query?.token)
          ? client.handshake.query.token[0]
          : undefined);
    const token = raw?.trim();
    if (!token) {
      this.logger.warn('WS disconnect: missing token');
      client.disconnect(true);
      return;
    }

    const session = await this.prisma.session.findUnique({
      where: { token },
      include: { user: true },
    });
    if (!session || session.expiresAt < new Date()) {
      client.disconnect(true);
      return;
    }

    client.data.user = {
      id: session.user.id,
      role: session.user.role as AppRole,
    } satisfies SocketUser;
  }

  @SubscribeMessage('subscribe')
  async subscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { tripId?: string },
  ) {
    const user = client.data.user as SocketUser | undefined;
    if (!user) {
      return { ok: false, error: 'Unauthorized' };
    }
    const tripId = body?.tripId?.trim();
    if (!tripId) {
      return { ok: false, error: 'tripId required' };
    }

    const allowed = await this.canAccessTrip(user, tripId);
    if (!allowed) {
      return { ok: false, error: 'Forbidden' };
    }

    await client.join(`trip:${tripId}`);
    return { ok: true };
  }

  emitLocation(
    tripId: string,
    payload: { latitude: number; longitude: number; recordedAt: Date },
  ) {
    this.server.to(`trip:${tripId}`).emit('location', {
      tripId,
      latitude: payload.latitude,
      longitude: payload.longitude,
      recordedAt: payload.recordedAt.toISOString(),
    });
  }

  private async canAccessTrip(user: SocketUser, tripId: string) {
    if (user.role === AppRole.ADMIN) {
      const exists = await this.prisma.trip.findUnique({
        where: { id: tripId },
        select: { id: true },
      });
      return !!exists;
    }

    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { driverId: true },
    });
    if (!trip) {
      return false;
    }

    if (user.role === AppRole.DRIVER) {
      const driver = await this.prisma.driver.findUnique({
        where: { userId: user.id },
        select: { id: true },
      });
      return !!driver && trip.driverId === driver.id;
    }

    if (user.role === AppRole.PARENT) {
      const parent = await this.prisma.parent.findUnique({
        where: { userId: user.id },
        select: { students: { select: { id: true } } },
      });
      const studentIds = parent?.students.map((s) => s.id) ?? [];
      if (!studentIds.length) {
        return false;
      }
      const n = await this.prisma.attendance.count({
        where: { tripId, studentId: { in: studentIds } },
      });
      return n > 0;
    }

    return false;
  }
}
