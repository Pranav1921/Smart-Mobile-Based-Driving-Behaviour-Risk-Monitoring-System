import { prisma } from '../database/client';
import { Trip, TripPoint, Prisma } from '@prisma/client';

export class TripRepository {
  async findById(id: string) {
    return prisma.trip.findUnique({
      where: { id },
      include: {
        driver: { include: { user: true } },
        vehicle: true,
        tripPoints: { orderBy: { timestamp: 'asc' } },
        events: true,
        crashReports: true,
      },
    });
  }

  async create(data: Prisma.TripUncheckedCreateInput): Promise<Trip> {
    return prisma.trip.create({ data });
  }

  async update(id: string, data: Prisma.TripUpdateInput): Promise<Trip> {
    return prisma.trip.update({
      where: { id },
      data,
    });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.TripWhereInput;
    orderBy?: Prisma.TripOrderByWithRelationInput;
  }) {
    return prisma.trip.findMany({
      ...params,
      include: {
        driver: { include: { user: true } },
        vehicle: true,
      },
    });
  }

  async count(where?: Prisma.TripWhereInput): Promise<number> {
    return prisma.trip.count({ where });
  }

  async addTripPoint(
    data: Prisma.TripPointUncheckedCreateInput
  ): Promise<TripPoint> {
    return prisma.tripPoint.create({ data });
  }

  async getTripPoints(tripId: string): Promise<TripPoint[]> {
    return prisma.tripPoint.findMany({
      where: { tripId },
      orderBy: { timestamp: 'asc' },
    });
  }
}
export const tripRepository = new TripRepository();
