import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class RoutesService {
  constructor(private readonly prisma: PrismaService) {}

  async listSummaries() {
    const buses = await this.prisma.bus.findMany({
      orderBy: { routeName: 'asc' },
      select: {
        id: true,
        plateNumber: true,
        routeName: true,
        capacity: true,
        _count: { select: { trips: true } },
      },
    });

    const byRoute = new Map<
      string,
      {
        routeName: string;
        buses: Array<{
          id: string;
          plateNumber: string;
          capacity: number;
          tripCount: number;
        }>;
      }
    >();

    for (const b of buses) {
      const existing = byRoute.get(b.routeName);
      const entry = {
        id: b.id,
        plateNumber: b.plateNumber,
        capacity: b.capacity,
        tripCount: b._count.trips,
      };
      if (existing) {
        existing.buses.push(entry);
      } else {
        byRoute.set(b.routeName, { routeName: b.routeName, buses: [entry] });
      }
    }

    return {
      routes: Array.from(byRoute.values()).map((r) => ({
        routeName: r.routeName,
        busCount: r.buses.length,
        buses: r.buses,
      })),
    };
  }
}
