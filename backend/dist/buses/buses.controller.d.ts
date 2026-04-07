import { BusesService } from './buses.service';
import { CreateBusDto } from './dto/create-bus.dto';
import { UpdateBusDto } from './dto/update-bus.dto';
export declare class BusesController {
    private readonly busesService;
    constructor(busesService: BusesService);
    create(dto: CreateBusDto): import("@prisma/client").Prisma.Prisma__BusClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        plateNumber: string;
        capacity: number;
        routeName: string;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    findAll(): import("@prisma/client").Prisma.PrismaPromise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        plateNumber: string;
        capacity: number;
        routeName: string;
    }[]>;
    findOne(id: string): import("@prisma/client").Prisma.Prisma__BusClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        plateNumber: string;
        capacity: number;
        routeName: string;
    } | null, null, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    update(id: string, dto: UpdateBusDto): import("@prisma/client").Prisma.Prisma__BusClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        plateNumber: string;
        capacity: number;
        routeName: string;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    remove(id: string): import("@prisma/client").Prisma.Prisma__BusClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        plateNumber: string;
        capacity: number;
        routeName: string;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
}
