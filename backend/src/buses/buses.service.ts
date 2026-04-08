import { Injectable } from '@nestjs/common';
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

  findOne(id: string) {
    return this.prisma.bus.findUnique({ where: { id } });
  }

  update(id: string, dto: UpdateBusDto) {
    return this.prisma.bus.update({ where: { id }, data: dto });
  }

  remove(id: string) {
    return this.prisma.bus.delete({ where: { id } });
  }
}
