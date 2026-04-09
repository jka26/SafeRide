import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Injectable()
export class NotificationsService {
    constructor(private readonly prisma: PrismaService) { }

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

        return this.prisma.notification.create({
            data: {
                title: dto.title,
                body: dto.body,
                studentId: dto.studentId ?? null,
                targetRole: dto.targetRole ?? null,
            },
        });
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
}
