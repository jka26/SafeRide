import { TripsService } from './trips.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';
export declare class TripsController {
    private readonly tripsService;
    constructor(tripsService: TripsService);
    create(dto: CreateTripDto): import("@prisma/client").Prisma.Prisma__TripClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        busId: string;
        driverId: string | null;
        tripDate: Date;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    findAll(): import("@prisma/client").Prisma.PrismaPromise<({
        driver: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
        } | null;
        bus: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            plateNumber: string;
            capacity: number;
            routeName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        busId: string;
        driverId: string | null;
        tripDate: Date;
    })[]>;
    findOne(id: string): import("@prisma/client").Prisma.Prisma__TripClient<({
        driver: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
        } | null;
        bus: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            plateNumber: string;
            capacity: number;
            routeName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        busId: string;
        driverId: string | null;
        tripDate: Date;
    }) | null, null, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    update(id: string, dto: UpdateTripDto): import("@prisma/client").Prisma.Prisma__TripClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        busId: string;
        driverId: string | null;
        tripDate: Date;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
    remove(id: string): import("@prisma/client").Prisma.Prisma__TripClient<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        busId: string;
        driverId: string | null;
        tripDate: Date;
    }, never, import("@prisma/client/runtime/library").DefaultArgs, import("@prisma/client").Prisma.PrismaClientOptions>;
}
