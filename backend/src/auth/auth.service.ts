import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../database/prisma.service';
import { SignUpDto } from './dto/sign-up.dto';
import { LoginDto } from './dto/login.dto';
import { AppRole } from '../common/auth/roles.enum';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) { }

  private async issueSession(userId: string) {
    const token = randomUUID();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 7);
    await this.prisma.session.create({
      data: {
        token,
        userId,
        expiresAt,
      },
    });
    return { token, expiresAt };
  }

  async signUp(dto: SignUpDto) {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const normalizedRole = dto.role.toString().toUpperCase() as AppRole;
    if (normalizedRole != AppRole.PARENT && normalizedRole != AppRole.DRIVER) {
      throw new ForbiddenException('Only PARENT and DRIVER can sign up publicly');
    }

    const exists = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (exists) {
      throw new ConflictException('Email already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          email: normalizedEmail,
          passwordHash,
          role: normalizedRole,
          fullName: dto.fullName,
        },
        select: {
          id: true,
          email: true,
          role: true,
          fullName: true,
        },
      });

      // Keep role tables in sync with user role from day one.
      await this.ensureRoleProfile(createdUser.id, createdUser.role as AppRole, tx);

      return createdUser;
    });

    const { token, expiresAt } = await this.issueSession(user.id);

    return {
      token,
      expiresAt,
      user,
    };
  }

  async login(dto: LoginDto) {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
    });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Self-heal legacy users created before role profile rows were enforced.
    await this.ensureRoleProfile(user.id, user.role as AppRole);

    const { token, expiresAt } = await this.issueSession(user.id);

    return {
      token,
      expiresAt,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        fullName: user.fullName,
      },
    };
  }

  async logout(token: string) {
    const session = await this.prisma.session.findUnique({ where: { token } });
    if (!session) {
      return { message: 'Logged out successfully' };
    }
    await this.prisma.session.delete({ where: { token } });
    return { message: 'Logged out successfully' };
  }

  private async ensureRoleProfile(
    userId: string,
    role: AppRole,
    prismaLike: Pick<
      PrismaService,
      'parent' | 'driver'
    > = this.prisma,
  ) {
    if (role === AppRole.DRIVER) {
      await prismaLike.driver.upsert({
        where: { userId },
        update: {},
        create: { userId },
      });
      return;
    }

    if (role === AppRole.PARENT) {
      await prismaLike.parent.upsert({
        where: { userId },
        update: {},
        create: { userId },
      });
    }
  }
}
