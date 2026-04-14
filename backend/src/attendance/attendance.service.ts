import {
    ForbiddenException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { MarkAttendanceDto } from './dto/mark-attendance.dto';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class AttendanceService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly notificationsService: NotificationsService,
    ) { }

    /**
     * Mark or upsert attendance for a student on a trip.
     * - ADMIN: always allowed.
     * - DRIVER: only if they are assigned to that trip.
     */
    async markAttendance(dto: MarkAttendanceDto, actor: AuthenticatedUser) {
        // Verify trip exists
        const trip = await this.prisma.trip.findUnique({
            where: { id: dto.tripId },
            include: { driver: { select: { userId: true } } },
        });
        if (!trip) {
            throw new NotFoundException(`Trip ${dto.tripId} not found`);
        }

        // Verify student exists
        const student = await this.prisma.student.findUnique({
            where: { id: dto.studentId },
            select: { id: true },
        });
        if (!student) {
            throw new NotFoundException(`Student ${dto.studentId} not found`);
        }

        // Permission check for drivers
        if (actor.role === AppRole.DRIVER) {
            if (trip.driver?.userId !== actor.id) {
                throw new ForbiddenException(
                    'You are not assigned to this trip',
                );
            }
        }

        // Upsert so calling the endpoint twice is idempotent
        const attendance = await this.prisma.attendance.upsert({
            where: {
                studentId_tripId: {
                    studentId: dto.studentId,
                    tripId: dto.tripId,
                },
            },
            create: {
                studentId: dto.studentId,
                tripId: dto.tripId,
                status: dto.status,
                markedById: actor.id,
            },
            update: {
                status: dto.status,
                markedById: actor.id,
                markedAt: new Date(),
            },
            include: {
                student: { select: { id: true, fullName: true, studentCode: true } },
                trip: { select: { id: true, name: true, tripDate: true } },
            },
        });
        await this.sendParentAttendanceAlert(attendance.student.id, attendance.student.fullName, attendance.status);
        return attendance;
    }

    /**
     * Get all attendance records for a given trip.
     * - ADMIN: always allowed.
     * - DRIVER: only if assigned to that trip.
     * - PARENT: forbidden (parents use the child-tracking endpoint).
     */
    async getAttendanceByTrip(tripId: string, actor: AuthenticatedUser) {
        const trip = await this.prisma.trip.findUnique({
            where: { id: tripId },
            include: { driver: { select: { userId: true } } },
        });
        if (!trip) {
            throw new NotFoundException(`Trip ${tripId} not found`);
        }

        if (actor.role === AppRole.DRIVER && trip.driver?.userId !== actor.id) {
            throw new ForbiddenException('You are not assigned to this trip');
        }

        if (actor.role === AppRole.PARENT) {
            throw new ForbiddenException(
                'Parents cannot access trip-level attendance directly',
            );
        }

        return this.prisma.attendance.findMany({
            where: { tripId },
            include: {
                student: { select: { id: true, fullName: true, studentCode: true, grade: true } },
            },
            orderBy: { markedAt: 'asc' },
        });
    }

    /**
     * Get attendance history for a specific student across all trips.
     * Only ADMIN or the student's own parent.
     */
    async getAttendanceByStudent(studentId: string, actor: AuthenticatedUser) {
        const student = await this.prisma.student.findUnique({
            where: { id: studentId },
            include: { parent: { select: { userId: true } } },
        });
        if (!student) {
            throw new NotFoundException(`Student ${studentId} not found`);
        }

        if (actor.role === AppRole.PARENT) {
            if (student.parent?.userId !== actor.id) {
                throw new ForbiddenException('This student is not linked to your account');
            }
        }

        if (actor.role === AppRole.DRIVER) {
            throw new ForbiddenException('Drivers cannot access per-student attendance history');
        }

        return this.prisma.attendance.findMany({
            where: { studentId },
            include: {
                trip: {
                    select: {
                        id: true,
                        name: true,
                        tripDate: true,
                        bus: { select: { plateNumber: true, routeName: true } },
                    },
                },
            },
            orderBy: { markedAt: 'desc' },
        });
    }

    private async sendParentAttendanceAlert(
        studentId: string,
        studentName: string,
        status: string,
    ) {
        const statusLabel = status.toUpperCase();
        const title = 'Student Attendance Update';
        const body = `${studentName} marked as ${statusLabel}.`;
        await this.notificationsService.create(
            {
                title,
                body,
                studentId,
            },
            {
                id: 'system',
                email: 'system@saferide.local',
                role: AppRole.ADMIN,
                fullName: 'System',
                onboardingCompleted: true,
            },
        );
    }
}
