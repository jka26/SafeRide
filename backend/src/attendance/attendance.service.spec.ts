import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { PrismaService } from '../database/prisma.service';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

const mockPrisma = {
    trip: {
        findUnique: jest.fn(),
    },
    student: {
        findUnique: jest.fn(),
    },
    attendance: {
        upsert: jest.fn(),
        findMany: jest.fn(),
    },
};

const adminUser: AuthenticatedUser = {
    id: 'admin-1',
    email: 'admin@test.com',
    role: AppRole.ADMIN,
    fullName: 'Admin User',
};

const driverUser: AuthenticatedUser = {
    id: 'driver-user-1',
    email: 'driver@test.com',
    role: AppRole.DRIVER,
    fullName: 'Driver One',
};

const parentUser: AuthenticatedUser = {
    id: 'parent-user-1',
    email: 'parent@test.com',
    role: AppRole.PARENT,
    fullName: 'Parent One',
};

describe('AttendanceService', () => {
    let service: AttendanceService;

    beforeEach(async () => {
        jest.clearAllMocks();
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                AttendanceService,
                { provide: PrismaService, useValue: mockPrisma },
            ],
        }).compile();

        service = module.get<AttendanceService>(AttendanceService);
    });

    describe('markAttendance', () => {
        const dto = { studentId: 'stu-1', tripId: 'trip-1', status: 'PRESENT' as const };

        it('allows admin to mark attendance', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({
                id: 'trip-1',
                driver: { userId: 'other-driver' },
            });
            mockPrisma.student.findUnique.mockResolvedValue({ id: 'stu-1' });
            mockPrisma.attendance.upsert.mockResolvedValue({ id: 'att-1', status: 'PRESENT' });

            const result = await service.markAttendance(dto, adminUser);
            expect(result).toEqual({ id: 'att-1', status: 'PRESENT' });
            expect(mockPrisma.attendance.upsert).toHaveBeenCalledTimes(1);
        });

        it('allows assigned driver to mark attendance', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({
                id: 'trip-1',
                driver: { userId: driverUser.id },
            });
            mockPrisma.student.findUnique.mockResolvedValue({ id: 'stu-1' });
            mockPrisma.attendance.upsert.mockResolvedValue({ id: 'att-1', status: 'PRESENT' });

            await expect(service.markAttendance(dto, driverUser)).resolves.toBeDefined();
        });

        it('throws ForbiddenException for unassigned driver', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({
                id: 'trip-1',
                driver: { userId: 'another-driver' },
            });
            mockPrisma.student.findUnique.mockResolvedValue({ id: 'stu-1' });

            await expect(service.markAttendance(dto, driverUser)).rejects.toBeInstanceOf(
                ForbiddenException,
            );
        });

        it('throws NotFoundException when trip does not exist', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue(null);

            await expect(service.markAttendance(dto, adminUser)).rejects.toBeInstanceOf(
                NotFoundException,
            );
        });

        it('throws NotFoundException when student does not exist', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({ id: 'trip-1', driver: null });
            mockPrisma.student.findUnique.mockResolvedValue(null);

            await expect(service.markAttendance(dto, adminUser)).rejects.toBeInstanceOf(
                NotFoundException,
            );
        });
    });

    describe('getAttendanceByTrip', () => {
        it('returns attendance records for admin', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({ id: 'trip-1', driver: null });
            mockPrisma.attendance.findMany.mockResolvedValue([{ id: 'att-1' }]);

            const result = await service.getAttendanceByTrip('trip-1', adminUser);
            expect(result).toHaveLength(1);
        });

        it('throws ForbiddenException for parent', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({ id: 'trip-1', driver: null });

            await expect(
                service.getAttendanceByTrip('trip-1', parentUser),
            ).rejects.toBeInstanceOf(ForbiddenException);
        });

        it('throws ForbiddenException for unassigned driver', async () => {
            mockPrisma.trip.findUnique.mockResolvedValue({
                id: 'trip-1',
                driver: { userId: 'other-driver' },
            });

            await expect(
                service.getAttendanceByTrip('trip-1', driverUser),
            ).rejects.toBeInstanceOf(ForbiddenException);
        });
    });
});
