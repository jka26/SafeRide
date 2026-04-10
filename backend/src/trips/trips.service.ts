import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Injectable()
export class TripsService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateTripDto) {
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

  findOne(id: string) {
    return this.prisma.trip.findUnique({
      where: { id },
      include: { bus: true, driver: true },
    });
  }

  update(id: string, dto: UpdateTripDto) {
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
