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
    return this.prisma.trip.update({
      where: { id },
      data: {
        ...dto,
        tripDate: dto.tripDate ? new Date(dto.tripDate) : undefined,
      },
    });
  }

  remove(id: string) {
    return this.prisma.trip.delete({ where: { id } });
  }
}
