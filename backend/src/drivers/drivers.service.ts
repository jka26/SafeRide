import { Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class DriversService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lists all drivers for admin assignment UI.
   * Self-heals: creates a `Driver` row for any `User` with role DRIVER that is missing one
   * (legacy accounts or pre-fix signups).
   */
  async listForAdmin() {
    const orphaned = await this.prisma.user.findMany({
      where: { role: Role.DRIVER, driver: null },
      select: { id: true },
    });
    for (const { id } of orphaned) {
      await this.prisma.driver.create({
        data: { userId: id },
      });
    }

    return this.prisma.driver.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { fullName: true, email: true } },
      },
    });
  }
}
