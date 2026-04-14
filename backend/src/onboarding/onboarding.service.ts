import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { AppRole } from '../common/auth/roles.enum';
import { CompleteParentOnboardingDto } from './dto/complete-parent-onboarding.dto';
import { CompleteDriverOnboardingDto } from './dto/complete-driver-onboarding.dto';

@Injectable()
export class OnboardingService {
  constructor(private readonly prisma: PrismaService) {}

  async completeParent(
    actor: AuthenticatedUser,
    dto: CompleteParentOnboardingDto,
  ) {
    if (actor.role !== AppRole.PARENT) {
      throw new ForbiddenException('Parent role required');
    }

    const parent = await this.prisma.parent.upsert({
      where: { userId: actor.id },
      update: {},
      create: { userId: actor.id },
      select: { id: true },
    });

    const normalizedChildName = dto.childName.trim();
    const normalizedGrade = dto.grade.trim();
    const normalizedStop = dto.stopName.trim();
    const normalizedEmergencyName = dto.emergencyContactName.trim();
    const normalizedEmergencyPhone = dto.emergencyContactPhone.trim();

    const existingStudent = await this.prisma.student.findFirst({
      where: {
        parentId: parent.id,
        fullName: normalizedChildName,
        grade: normalizedGrade,
      },
      orderBy: { updatedAt: 'desc' },
      select: { id: true },
    });

    const student = existingStudent == null
        ? await this.prisma.student.create({
            data: {
              studentCode: await this.generateUniqueStudentCode(normalizedChildName),
              fullName: normalizedChildName,
              grade: normalizedGrade,
              parentId: parent.id,
              stopName: normalizedStop,
              emergencyContactName: normalizedEmergencyName,
              emergencyContactPhone: normalizedEmergencyPhone,
            },
            select: {
              id: true,
              studentCode: true,
              fullName: true,
              grade: true,
              stopName: true,
            },
          })
        : await this.prisma.student.update({
            where: { id: existingStudent.id },
            data: {
              stopName: normalizedStop,
              emergencyContactName: normalizedEmergencyName,
              emergencyContactPhone: normalizedEmergencyPhone,
            },
            select: {
              id: true,
              studentCode: true,
              fullName: true,
              grade: true,
              stopName: true,
            },
          });

    await this.prisma.user.update({
      where: { id: actor.id },
      data: { onboardingCompleted: true },
    });

    return {
      message:
          existingStudent == null
              ? 'Parent onboarding completed'
              : 'Parent onboarding updated existing child record',
      student,
    };
  }

  async completeDriver(
    actor: AuthenticatedUser,
    dto: CompleteDriverOnboardingDto,
  ) {
    if (actor.role !== AppRole.DRIVER) {
      throw new ForbiddenException('Driver role required');
    }

    await this.prisma.driver.upsert({
      where: { userId: actor.id },
      update: {},
      create: { userId: actor.id },
      select: { id: true },
    });

    const bus = await this.prisma.bus.upsert({
      where: { plateNumber: dto.busNumber.trim() },
      update: {
        routeName: dto.routeName.trim(),
      },
      create: {
        plateNumber: dto.busNumber.trim(),
        routeName: dto.routeName.trim(),
        capacity: 40,
      },
      select: {
        id: true,
        plateNumber: true,
        routeName: true,
      },
    });

    await this.prisma.user.update({
      where: { id: actor.id },
      data: { onboardingCompleted: true },
    });

    return {
      message: 'Driver onboarding completed',
      bus,
      emergencyContact: {
        name: dto.emergencyContactName.trim(),
        phone: dto.emergencyContactPhone.trim(),
      },
    };
  }

  private async generateUniqueStudentCode(childName: string) {
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const candidate = this.generateStudentCode(childName);
      const existing = await this.prisma.student.findUnique({
        where: { studentCode: candidate },
        select: { id: true },
      });
      if (!existing) {
        return candidate;
      }
    }

    return this.generateStudentCode(`${childName}${Math.random().toString().slice(-4)}`);
  }

  private generateStudentCode(childName: string) {
    const slug = childName
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]+/g, '')
      .slice(0, 6);
    const suffix = Date.now().toString().slice(-5);
    return `SR-${slug || 'STU'}-${suffix}`;
  }
}
