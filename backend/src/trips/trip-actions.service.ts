import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { TripStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { TrackingGateway } from './tracking.gateway';
import type { UpdateTripProgressDto } from './dto/update-trip-progress.dto';

@Injectable()
export class TripActionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly trackingGateway: TrackingGateway,
  ) {}

  async startTrip(tripId: string, actor: AuthenticatedUser) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { id: true, driverId: true, status: true },
    });
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    await this.assertCanOperateTrip(actor, trip);
    if (trip.status !== TripStatus.SCHEDULED) {
      throw new BadRequestException('Only scheduled trips can be started');
    }
    return this.prisma.trip.update({
      where: { id: tripId },
      data: {
        status: TripStatus.IN_PROGRESS,
        startedAt: new Date(),
        endedAt: null,
      },
      include: {
        bus: true,
        driver: { include: { user: true } },
      },
    });
  }

  async endTrip(tripId: string, actor: AuthenticatedUser) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { id: true, driverId: true, status: true },
    });
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    await this.assertCanOperateTrip(actor, trip);
    if (trip.status !== TripStatus.IN_PROGRESS) {
      throw new BadRequestException('Trip is not in progress');
    }
    return this.prisma.trip.update({
      where: { id: tripId },
      data: {
        status: TripStatus.COMPLETED,
        endedAt: new Date(),
      },
      include: {
        bus: true,
        driver: { include: { user: true } },
      },
    });
  }

  async reportLocation(
    tripId: string,
    actor: AuthenticatedUser,
    latitude: number,
    longitude: number,
  ) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { id: true, driverId: true, status: true },
    });
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    await this.assertCanOperateTrip(actor, trip);
    if (trip.status !== TripStatus.IN_PROGRESS) {
      throw new BadRequestException(
        'Location updates are only accepted while the trip is in progress',
      );
    }
    const row = await this.prisma.tripLocation.create({
      data: { tripId, latitude, longitude },
    });
    this.trackingGateway.emitLocation(tripId, {
      latitude: row.latitude,
      longitude: row.longitude,
      recordedAt: row.recordedAt,
    });
    return row;
  }

  async updateProgress(
    tripId: string,
    actor: AuthenticatedUser,
    dto: UpdateTripProgressDto,
  ) {
    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      select: { id: true, driverId: true, status: true },
    });
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }
    await this.assertCanOperateTrip(actor, trip);
    if (
      trip.status !== TripStatus.IN_PROGRESS &&
      trip.status !== TripStatus.SCHEDULED
    ) {
      throw new BadRequestException('Trip cannot be updated in its current state');
    }
    return this.prisma.trip.update({
      where: { id: tripId },
      data: {
        ...(dto.currentStopName !== undefined && {
          currentStopName: dto.currentStopName,
        }),
        ...(dto.etaMinutes !== undefined && { etaMinutes: dto.etaMinutes }),
      },
      include: { bus: true, driver: { include: { user: true } } },
    });
  }

  async getLiveForParent(tripId: string, actor: AuthenticatedUser) {
    if (actor.role !== AppRole.PARENT) {
      throw new ForbiddenException('Parent role required');
    }
    const parent = await this.prisma.parent.findUnique({
      where: { userId: actor.id },
      select: { students: { select: { id: true } } },
    });
    if (!parent) {
      throw new NotFoundException('Parent profile not found for this account');
    }
    const studentIds = parent.students.map((s) => s.id);
    const link = await this.prisma.attendance.findFirst({
      where: { tripId, studentId: { in: studentIds } },
      select: { studentId: true },
    });
    if (!link) {
      throw new ForbiddenException('No linked student on this trip');
    }

    const trip = await this.prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        bus: { select: { plateNumber: true, routeName: true } },
        locations: { orderBy: { recordedAt: 'desc' }, take: 1 },
      },
    });
    if (!trip) {
      throw new NotFoundException(`Trip ${tripId} not found`);
    }

    return {
      trip: {
        id: trip.id,
        name: trip.name,
        status: trip.status,
        tripDate: trip.tripDate,
        startedAt: trip.startedAt,
        endedAt: trip.endedAt,
        currentStopName: trip.currentStopName,
        etaMinutes: trip.etaMinutes,
        bus: trip.bus,
      },
      latestLocation: trip.locations[0] ?? null,
      studentId: link.studentId,
    };
  }

  private async assertCanOperateTrip(
    actor: AuthenticatedUser,
    trip: { driverId: string | null },
  ) {
    if (actor.role === AppRole.ADMIN) {
      return;
    }
    if (actor.role !== AppRole.DRIVER) {
      throw new ForbiddenException('Only drivers or admins can perform this action');
    }
    const driver = await this.prisma.driver.findUnique({
      where: { userId: actor.id },
      select: { id: true },
    });
    if (!driver || trip.driverId !== driver.id) {
      throw new ForbiddenException('You are not assigned to this trip');
    }
  }
}
