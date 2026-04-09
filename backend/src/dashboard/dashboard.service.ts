import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

@Injectable()
export class DashboardService {
    constructor(private readonly prisma: PrismaService) { }

    /**
     * Admin dashboard: operational summary counts + today's trips.
     */
    async getAdminSummary() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const [totalStudents, totalBuses, totalTrips, totalDrivers, todaysTrips, recentNotifications] =
            await Promise.all([
                this.prisma.student.count(),
                this.prisma.bus.count(),
                this.prisma.trip.count(),
                this.prisma.driver.count(),
                this.prisma.trip.findMany({
                    where: {
                        tripDate: { gte: today, lt: tomorrow },
                    },
                    include: {
                        bus: { select: { plateNumber: true, routeName: true } },
                        driver: {
                            include: { user: { select: { fullName: true } } },
                        },
                        _count: { select: { attendances: true } },
                    },
                    orderBy: { tripDate: 'asc' },
                }),
                this.prisma.notification.findMany({
                    orderBy: { createdAt: 'desc' },
                    take: 5,
                    select: {
                        id: true,
                        title: true,
                        body: true,
                        targetRole: true,
                        createdAt: true,
                    },
                }),
            ]);

        const presentToday = await this.prisma.attendance.count({
            where: {
                status: 'PRESENT',
                trip: { tripDate: { gte: today, lt: tomorrow } },
            },
        });

        const absentToday = await this.prisma.attendance.count({
            where: {
                status: 'ABSENT',
                trip: { tripDate: { gte: today, lt: tomorrow } },
            },
        });

        return {
            counts: {
                students: totalStudents,
                buses: totalBuses,
                trips: totalTrips,
                drivers: totalDrivers,
            },
            todaysAttendance: {
                present: presentToday,
                absent: absentToday,
            },
            todaysTrips,
            recentNotifications,
        };
    }

    /**
     * Driver dashboard: their upcoming/today trips with full passenger roster.
     */
    async getDriverDashboard(actor: AuthenticatedUser) {
        // Resolve driver profile from User id
        const driver = await this.prisma.driver.findUnique({
            where: { userId: actor.id },
            select: { id: true },
        });
        if (!driver) {
            throw new NotFoundException('Driver profile not found for this account');
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        // Today's assigned trips with full roster
        const todaysTrips = await this.prisma.trip.findMany({
            where: {
                driverId: driver.id,
                tripDate: { gte: today, lt: tomorrow },
            },
            include: {
                bus: { select: { plateNumber: true, routeName: true, capacity: true } },
                attendances: {
                    include: {
                        student: {
                            select: { id: true, fullName: true, studentCode: true, grade: true },
                        },
                    },
                },
            },
            orderBy: { tripDate: 'asc' },
        });

        // Upcoming trips (next 7 days, excluding today)
        const nextWeek = new Date(tomorrow);
        nextWeek.setDate(nextWeek.getDate() + 6);
        const upcomingTrips = await this.prisma.trip.findMany({
            where: {
                driverId: driver.id,
                tripDate: { gte: tomorrow, lt: nextWeek },
            },
            include: {
                bus: { select: { plateNumber: true, routeName: true } },
                _count: { select: { attendances: true } },
            },
            orderBy: { tripDate: 'asc' },
        });

        return { todaysTrips, upcomingTrips };
    }

    /**
     * Parent dashboard: all children, their attendance summaries and latest trip status.
     */
    async getParentDashboard(actor: AuthenticatedUser) {
        const parent = await this.prisma.parent.findUnique({
            where: { userId: actor.id },
            include: {
                students: {
                    include: {
                        attendances: {
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
                            take: 5,
                        },
                        notifications: {
                            orderBy: { createdAt: 'desc' },
                            take: 3,
                            select: {
                                id: true,
                                title: true,
                                body: true,
                                isRead: true,
                                createdAt: true,
                            },
                        },
                    },
                },
            },
        });

        if (!parent) {
            throw new NotFoundException('Parent profile not found for this account');
        }

        // Enrich each student with summary stats
        const children = parent.students.map((student) => {
            const totalMarked = student.attendances.length;
            const presentCount = student.attendances.filter(
                (a) => a.status === 'PRESENT',
            ).length;
            const latestRecord = student.attendances[0] ?? null;

            return {
                id: student.id,
                fullName: student.fullName,
                studentCode: student.studentCode,
                grade: student.grade,
                attendanceSummary: {
                    totalMarked,
                    present: presentCount,
                    absent: totalMarked - presentCount,
                },
                latestAttendance: latestRecord,
                recentNotifications: student.notifications,
            };
        });

        return { children };
    }
}
