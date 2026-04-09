import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../database/prisma.service';
import { AppRole } from '../common/auth/roles.enum';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';

const mockPrisma = {
    notification: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
    },
    student: {
        findUnique: jest.fn(),
    },
    parent: {
        findUnique: jest.fn(),
    },
};

const adminUser: AuthenticatedUser = {
    id: 'admin-1',
    email: 'admin@test.com',
    role: AppRole.ADMIN,
    fullName: 'Admin',
};

const driverUser: AuthenticatedUser = {
    id: 'driver-1',
    email: 'driver@test.com',
    role: AppRole.DRIVER,
    fullName: 'Driver',
};

const parentUser: AuthenticatedUser = {
    id: 'parent-1',
    email: 'parent@test.com',
    role: AppRole.PARENT,
    fullName: 'Parent',
};

describe('NotificationsService', () => {
    let service: NotificationsService;

    beforeEach(async () => {
        jest.clearAllMocks();
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                NotificationsService,
                { provide: PrismaService, useValue: mockPrisma },
            ],
        }).compile();

        service = module.get<NotificationsService>(NotificationsService);
    });

    describe('create', () => {
        it('allows admin to create a notification', async () => {
            const dto = { title: 'Hello', body: 'Test notification' };
            mockPrisma.notification.create.mockResolvedValue({ id: 'notif-1', ...dto });

            const result = await service.create(dto, adminUser);
            expect(result.id).toBe('notif-1');
        });

        it('throws ForbiddenException for non-admin', async () => {
            await expect(
                service.create({ title: 'x', body: 'y' }, driverUser),
            ).rejects.toBeInstanceOf(ForbiddenException);
        });

        it('throws NotFoundException when targeted student does not exist', async () => {
            mockPrisma.student.findUnique.mockResolvedValue(null);

            await expect(
                service.create({ title: 'x', body: 'y', studentId: 'ghost-student' }, adminUser),
            ).rejects.toBeInstanceOf(NotFoundException);
        });
    });

    describe('findForUser', () => {
        it('returns all notifications for admin', async () => {
            mockPrisma.notification.findMany.mockResolvedValue([{ id: 'n1' }, { id: 'n2' }]);
            const result = await service.findForUser(adminUser);
            expect(result).toHaveLength(2);
        });

        it('returns role-filtered notifications for driver', async () => {
            mockPrisma.notification.findMany.mockResolvedValue([{ id: 'n1', targetRole: 'DRIVER' }]);
            const result = await service.findForUser(driverUser);
            expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
                expect.objectContaining({
                    where: {
                        OR: [{ targetRole: 'DRIVER' }, { targetRole: null }],
                    },
                }),
            );
            expect(result).toHaveLength(1);
        });

        it('fetches parent + children notifications for parent', async () => {
            mockPrisma.parent.findUnique.mockResolvedValue({
                students: [{ id: 'stu-1' }],
            });
            mockPrisma.notification.findMany.mockResolvedValue([]);
            await service.findForUser(parentUser);
            expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
                expect.objectContaining({
                    where: {
                        OR: [
                            { targetRole: 'PARENT' },
                            { studentId: { in: ['stu-1'] } },
                        ],
                    },
                }),
            );
        });
    });

    describe('markRead', () => {
        it('allows admin to mark any notification read', async () => {
            mockPrisma.notification.findUnique.mockResolvedValue({ id: 'n1', targetRole: null, studentId: null });
            mockPrisma.notification.update.mockResolvedValue({ id: 'n1', isRead: true });

            const result = await service.markRead('n1', adminUser);
            expect(result.isRead).toBe(true);
        });

        it('throws NotFoundException for missing notification', async () => {
            mockPrisma.notification.findUnique.mockResolvedValue(null);
            await expect(service.markRead('ghost', adminUser)).rejects.toBeInstanceOf(NotFoundException);
        });
    });
});
