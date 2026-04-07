import { PrismaService } from '../database/prisma.service';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
export declare class StudentsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateStudentDto): import("@prisma/client").Prisma.Prisma__StudentClient<{
        fullName: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentCode: string;
        grade: string;
        parentId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    findAll(): import("@prisma/client").Prisma.PrismaPromise<{
        fullName: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentCode: string;
        grade: string;
        parentId: string | null;
    }[]>;
    findOne(id: string): import("@prisma/client").Prisma.Prisma__StudentClient<{
        fullName: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentCode: string;
        grade: string;
        parentId: string | null;
    } | null, null, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    update(id: string, dto: UpdateStudentDto): import("@prisma/client").Prisma.Prisma__StudentClient<{
        fullName: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentCode: string;
        grade: string;
        parentId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    remove(id: string): import("@prisma/client").Prisma.Prisma__StudentClient<{
        fullName: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentCode: string;
        grade: string;
        parentId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
}
