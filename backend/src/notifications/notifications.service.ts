import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { ReportEmergencyDto } from './dto/report-emergency.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { PushService } from './push.service';

@Injectable()
export class NotificationsService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly pushService: PushService,
    ) { }

    registerDeviceToken(dto: RegisterDeviceTokenDto, actor: AuthenticatedUser) {
        return this.pushService.registerToken(actor.id, dto.token.trim(), dto.platform);
    }

    /**
     * Create a notification. Only ADMIN is allowed.
     * Can target a specific student, or a broad role group, or both.
     */
    async create(dto: CreateNotificationDto, actor: AuthenticatedUser) {
        if (actor.role !== AppRole.ADMIN) {
            throw new ForbiddenException('Only admins can create notifications');
        }

        // If a student is targeted, ensure it exists
        if (dto.studentId) {
            const student = await this.prisma.student.findUnique({
                where: { id: dto.studentId },
                select: { id: true },
            });
            if (!student) {
                throw new NotFoundException(`Student ${dto.studentId} not found`);
            }
        }

        const created = await this.prisma.notification.create({
            data: {
                title: dto.title,
                body: dto.body,
                studentId: dto.studentId ?? null,
                targetRole: dto.targetRole ?? null,
            },
        });

        if (dto.targetRole) {
            await this.pushService.sendToRole(dto.targetRole as AppRole, dto.title, dto.body);
        }
        if (dto.studentId) {
            const student = await this.prisma.student.findUnique({
                where: { id: dto.studentId },
                select: { parent: { select: { userId: true } } },
            });
            const parentUserId = student?.parent?.userId;
            if (parentUserId) {
                await this.pushService.sendToUsers([parentUserId], dto.title, dto.body);
            }
        }
        return created;
    }

    /**
     * Fetch notifications visible to the current user based on their role.
     * - ADMIN: sees all notifications.
     * - DRIVER: sees notifications with targetRole = DRIVER or no targetRole.
     * - PARENT: sees notifications targeting PARENT role plus notifications for
     *   their linked children.
     */
    async findForUser(actor: AuthenticatedUser) {
        if (actor.role === AppRole.ADMIN) {
            return this.prisma.notification.findMany({
                orderBy: { createdAt: 'desc' },
                include: {
                    student: { select: { id: true, fullName: true, studentCode: true } },
                },
            });
        }

        if (actor.role === AppRole.DRIVER) {
            return this.prisma.notification.findMany({
                where: {
                    OR: [{ targetRole: 'DRIVER' }, { targetRole: null }],
                },
                orderBy: { createdAt: 'desc' },
            });
        }

        // PARENT: role-targeted + any notifications for their children
        const parent = await this.prisma.parent.findUnique({
            where: { userId: actor.id },
            select: { students: { select: { id: true } } },
        });

        const studentIds = parent?.students.map((s) => s.id) ?? [];

        return this.prisma.notification.findMany({
            where: {
                OR: [
                    { targetRole: 'PARENT' },
                    { studentId: { in: studentIds } },
                ],
            },
            orderBy: { createdAt: 'desc' },
            include: {
                student: { select: { id: true, fullName: true, studentCode: true } },
            },
        });
    }

    /**
     * Count unread notifications visible to the current user (same scope as findForUser).
     */
    async countUnreadForUser(actor: AuthenticatedUser) {
        if (actor.role === AppRole.ADMIN) {
            return this.prisma.notification.count({ where: { isRead: false } });
        }

        if (actor.role === AppRole.DRIVER) {
            return this.prisma.notification.count({
                where: {
                    isRead: false,
                    OR: [{ targetRole: 'DRIVER' }, { targetRole: null }],
                },
            });
        }

        const parent = await this.prisma.parent.findUnique({
            where: { userId: actor.id },
            select: { students: { select: { id: true } } },
        });

        const studentIds = parent?.students.map((s) => s.id) ?? [];

        return this.prisma.notification.count({
            where: {
                isRead: false,
                OR: [
                    { targetRole: 'PARENT' },
                    { studentId: { in: studentIds } },
                ],
            },
        });
    }

    /**
     * Mark a notification as read.
     * Any authenticated user can mark notifications they can see.
     */
    async markRead(id: string, actor: AuthenticatedUser) {
        const notification = await this.prisma.notification.findUnique({
            where: { id },
        });
        if (!notification) {
            throw new NotFoundException(`Notification ${id} not found`);
        }

        // Admins can mark any; others can only mark their own visible notifications
        if (actor.role !== AppRole.ADMIN) {
            const isDriver =
                actor.role === AppRole.DRIVER &&
                (notification.targetRole === 'DRIVER' || notification.targetRole === null);

            let isParent = false;
            if (actor.role === AppRole.PARENT) {
                const parent = await this.prisma.parent.findUnique({
                    where: { userId: actor.id },
                    select: { students: { select: { id: true } } },
                });
                const studentIds = parent?.students.map((s) => s.id) ?? [];
                isParent =
                    notification.targetRole === 'PARENT' ||
                    (notification.studentId !== null &&
                        studentIds.includes(notification.studentId));
            }

            if (!isDriver && !isParent) {
                throw new ForbiddenException('You cannot mark this notification as read');
            }
        }

        return this.prisma.notification.update({
            where: { id },
            data: { isRead: true },
        });
    }

    /**
     * Delete a notification. ADMIN only.
     */
    async remove(id: string, actor: AuthenticatedUser) {
        if (actor.role !== AppRole.ADMIN) {
            throw new ForbiddenException('Only admins can delete notifications');
        }
        const existing = await this.prisma.notification.findUnique({ where: { id } });
        if (!existing) {
            throw new NotFoundException(`Notification ${id} not found`);
        }
        return this.prisma.notification.delete({ where: { id } });
    }

    async reportEmergency(dto: ReportEmergencyDto, actor: AuthenticatedUser) {
        if (actor.role !== AppRole.DRIVER && actor.role !== AppRole.ADMIN) {
            throw new ForbiddenException('Only drivers or admins can report emergencies');
        }

        const typeLabel = dto.type[0].toUpperCase() + dto.type.slice(1);
        const locationLabel =
            dto.latitude !== undefined && dto.longitude !== undefined
                ? ` @ (${dto.latitude.toFixed(5)}, ${dto.longitude.toFixed(5)})`
                : '';
        const tripLabel = dto.tripId ? ` [trip:${dto.tripId}]` : '';

        const created = await this.prisma.notification.create({
            data: {
                title: `Emergency Alert: ${typeLabel}`,
                body: `Reported by ${actor.email}${tripLabel}${locationLabel}`,
                targetRole: 'ADMIN',
            },
        });
        await this.pushService.sendToRole(
            AppRole.ADMIN,
            created.title,
            created.body,
        );
        return created;
    }
}
