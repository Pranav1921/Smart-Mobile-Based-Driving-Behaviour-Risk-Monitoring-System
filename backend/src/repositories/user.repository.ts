import { prisma } from '../database/client';
import { User, Prisma } from '@prisma/client';

export class UserRepository {
  async findById(id: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { id },
      include: { driverProfile: true },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { email },
      include: { driverProfile: true },
    });
  }

  async findByIdentifier(identifier: string): Promise<(User & { driverProfile?: any }) | null> {
    const trimmed = identifier.trim();
    // 1. Direct email lookup
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: { equals: trimmed, mode: 'insensitive' } },
          { phoneNumber: trimmed },
          { driverProfile: { licenseNumber: { equals: trimmed, mode: 'insensitive' } } },
        ],
      },
      include: { driverProfile: true },
    });

    if (user) return user;

    // 2. If identifier matches driver_code badge or ID
    try {
      const byBadge = await prisma.user.findFirst({
        where: {
          driverProfile: {
            badges: { has: `driver_code:${trimmed}` },
          },
        },
        include: { driverProfile: true },
      });
      if (byBadge) return byBadge;

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(trimmed);
      if (isUuid) {
        user = await prisma.user.findFirst({
          where: {
            OR: [
              { id: trimmed },
              { driverProfile: { id: trimmed } },
            ],
          },
          include: { driverProfile: true },
        });
      }
    } catch (_) {}

    return user;
  }

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return prisma.user.create({ data });
  }

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return prisma.user.update({ where: { id }, data });
  }

  async delete(id: string): Promise<User> {
    return prisma.user.delete({ where: { id } });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.UserWhereInput;
    orderBy?: Prisma.UserOrderByWithRelationInput;
  }): Promise<User[]> {
    return prisma.user.findMany({
      ...params,
      include: { driverProfile: true },
    });
  }

  async count(where?: Prisma.UserWhereInput): Promise<number> {
    return prisma.user.count({ where });
  }
}
export const userRepository = new UserRepository();
