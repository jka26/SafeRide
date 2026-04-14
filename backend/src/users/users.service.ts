import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  listForAdmin() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        email: true,
        role: true,
        fullName: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOneForAdmin(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        role: true,
        fullName: true,
        createdAt: true,
      },
    });
    if (!user) {
      throw new NotFoundException(`User ${id} not found`);
    }
    return user;
  }

  updateProfile(actor: AuthenticatedUser, dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: actor.id },
      data: { fullName: dto.fullName },
      select: { id: true, email: true, role: true, fullName: true },
    });
  }

  saveFcmToken(userId: string, token: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken: token },
      select: { id: true },
    });
  }
}
