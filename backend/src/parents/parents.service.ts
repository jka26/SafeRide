import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Injectable()
export class ParentsService {
  constructor(private readonly prisma: PrismaService) {}

  async ensureParentRecord(userId: string) {
    const existing = await this.prisma.parent.findUnique({
      where: { userId },
    });
    if (existing) {
      return existing;
    }
    return this.prisma.parent.create({
      data: { userId },
    });
  }

  async getMe(actor: AuthenticatedUser) {
    const parent = await this.ensureParentRecord(actor.id);
    return this.prisma.parent.findUnique({
      where: { id: parent.id },
      include: {
        students: {
          orderBy: { fullName: 'asc' },
          select: {
            id: true,
            studentCode: true,
            fullName: true,
            grade: true,
            routeName: true,
            busLabel: true,
            stopName: true,
            dropOffTime: true,
            emergencyContactName: true,
            emergencyContactPhone: true,
          },
        },
      },
    });
  }

  async linkStudent(actor: AuthenticatedUser, studentId: string) {
    const parent = await this.ensureParentRecord(actor.id);
    const student = await this.prisma.student.findUnique({
      where: { id: studentId },
      select: { id: true, parentId: true },
    });
    if (!student) {
      throw new NotFoundException(`Student ${studentId} not found`);
    }
    if (student.parentId && student.parentId !== parent.id) {
      throw new ConflictException('Student is already linked to another parent');
    }
    return this.prisma.student.update({
      where: { id: studentId },
      data: { parentId: parent.id },
      select: {
        id: true,
        studentCode: true,
        fullName: true,
        grade: true,
        parentId: true,
      },
    });
  }

  async unlinkStudent(actor: AuthenticatedUser, studentId: string) {
    const parent = await this.prisma.parent.findUnique({
      where: { userId: actor.id },
      select: { id: true },
    });
    if (!parent) {
      throw new NotFoundException('Parent profile not found for this account');
    }
    const student = await this.prisma.student.findUnique({
      where: { id: studentId },
      select: { id: true, parentId: true },
    });
    if (!student) {
      throw new NotFoundException(`Student ${studentId} not found`);
    }
    if (student.parentId !== parent.id) {
      throw new ForbiddenException('Student is not linked to your account');
    }
    return this.prisma.student.update({
      where: { id: studentId },
      data: { parentId: null },
      select: {
        id: true,
        studentCode: true,
        fullName: true,
        grade: true,
        parentId: true,
      },
    });
  }

  async findByCode(studentCode: string) {
    const student = await this.prisma.student.findUnique({
      where: { studentCode },
      select: {
        id: true,
        studentCode: true,
        fullName: true,
        grade: true,
        routeName: true,
        busLabel: true,
        parentId: true,
      },
    });
    if (!student) throw new NotFoundException(`No student found with code ${studentCode}`);
    if (student.parentId) throw new ConflictException('This student is already linked to a parent');
    return student;
  }
}
