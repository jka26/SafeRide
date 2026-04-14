import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Injectable()
export class TripsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateTripDto) {
    const bus = await this.prisma.bus.findUnique({
      where: { id: dto.busId },
      select: { id: true },
    });
    if (!bus) {
      throw new BadRequestException('Bus not found');
    }
    if (dto.driverId) {
      const driver = await this.prisma.driver.findUnique({
        where: { id: dto.driverId },
        select: { id: true },
      });
      if (!driver) {
        throw new BadRequestException(
          'Driver profile not found — use Driver id, not User id',
        );
      }
    }
    return this.prisma.trip.create({
      data: {
        ...dto,
        tripDate: new Date(dto.tripDate),
      },
    });
  }

  findAll() {
    return this.prisma.trip.findMany({
      include: { bus: true, driver: true },
      orderBy: { tripDate: 'desc' },
    });
  }

  async findOne(id: string) {
    const trip = await this.prisma.trip.findUnique({
      where: { id },
      include: { bus: true, driver: true },
    });
    if (!trip) {
      throw new NotFoundException('Trip not found');
    }
    return trip;
  }

  async update(id: string, dto: UpdateTripDto) {
    const {
      tripDate,
      startedAt,
      endedAt,
      status,
      currentStopName,
      etaMinutes,
      name,
      busId,
      driverId,
    } = dto;
    if (busId !== undefined) {
      const bus = await this.prisma.bus.findUnique({
        where: { id: busId },
        select: { id: true },
      });
      if (!bus) {
        throw new BadRequestException('Bus not found');
      }
    }
    if (driverId !== undefined && driverId !== null) {
      const driver = await this.prisma.driver.findUnique({
        where: { id: driverId },
        select: { id: true },
      });
      if (!driver) {
        throw new BadRequestException(
          'Driver profile not found — use Driver id, not User id',
        );
      }
    }
    return this.prisma.trip.update({
      where: { id },
      data: {
        ...(name !== undefined && { name }),
        ...(busId !== undefined && { busId }),
        ...(driverId !== undefined && { driverId }),
        ...(status !== undefined && { status }),
        ...(currentStopName !== undefined && { currentStopName }),
        ...(etaMinutes !== undefined && { etaMinutes }),
        tripDate: tripDate ? new Date(tripDate) : undefined,
        startedAt: startedAt ? new Date(startedAt) : undefined,
        endedAt: endedAt ? new Date(endedAt) : undefined,
      },
    });
  }

  remove(id: string) {
    return this.prisma.trip.delete({ where: { id } });
  }
}
