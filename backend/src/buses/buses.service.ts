import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateBusDto } from './dto/create-bus.dto';
import { UpdateBusDto } from './dto/update-bus.dto';

@Injectable()
export class BusesService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateBusDto) {
    return this.prisma.bus.create({ data: dto });
  }

  findAll() {
    return this.prisma.bus.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async findOne(id: string) {
    const bus = await this.prisma.bus.findUnique({ where: { id } });
    if (!bus) {
      throw new NotFoundException('Bus not found');
    }
    return bus;
  }

  async getBusStudents(id: string) {
    await this.findOne(id);

    const latestTrip = await this.prisma.trip.findFirst({
      where: { busId: id },
      orderBy: [{ tripDate: 'desc' }, { createdAt: 'desc' }],
      include: {
        attendances: {
          include: {
            student: {
              select: {
                id: true,
                fullName: true,
                grade: true,
                stopName: true,
                dropOffTime: true,
              },
            },
          },
          orderBy: { markedAt: 'desc' },
        },
      },
    });

    if (!latestTrip) {
      return {
        tripId: null,
        tripStatus: null,
        students: [],
      };
    }

    return {
      tripId: latestTrip.id,
      tripStatus: latestTrip.status,
      students: latestTrip.attendances.map((entry) => ({
        id: entry.student.id,
        fullName: entry.student.fullName,
        grade: entry.student.grade,
        stopName: entry.student.stopName,
        dropOffTime: entry.student.dropOffTime,
        attendanceStatus: entry.status,
      })),
    };
  }

  update(id: string, dto: UpdateBusDto) {
    return this.prisma.bus.update({ where: { id }, data: dto });
  }

  remove(id: string) {
    return this.prisma.bus.delete({ where: { id } });
  }
}
