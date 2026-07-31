import { prisma } from '../database/client';
import { Event, Prisma } from '@prisma/client';

export class EventRepository {
  async findById(id: string): Promise<Event | null> {
    return prisma.event.findUnique({
      where: { id },
      include: {
        driver: { include: { user: true } },
        trip: true,
      },
    });
  }

  async create(data: Prisma.EventUncheckedCreateInput): Promise<Event> {
    return prisma.event.create({ data });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.EventWhereInput;
    orderBy?: Prisma.EventOrderByWithRelationInput;
  }): Promise<Event[]> {
    return prisma.event.findMany({
      ...params,
      include: {
        driver: { include: { user: true } },
        trip: true,
      },
    });
  }

  async count(where?: Prisma.EventWhereInput): Promise<number> {
    return prisma.event.count({ where });
  }
}
export const eventRepository = new EventRepository();
