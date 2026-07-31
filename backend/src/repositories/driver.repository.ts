import { prisma } from '../database/client';
import { Prisma, VehicleAssignment, DriverScore } from '@prisma/client';

export class DriverRepository {
  async findById(id: string) {
    return prisma.driver.findUnique({
      where: { id },
      include: {
        user: true,
        vehicleAssignments: {
          where: { unassignedAt: null },
          include: { vehicle: true },
        },
      },
    });
  }

  async findByUserId(userId: string) {
    return prisma.driver.findUnique({
      where: { userId },
      include: { user: true },
    });
  }

  async create(data: Prisma.DriverCreateInput) {
    return prisma.driver.create({
      data,
      include: { user: true },
    });
  }

  async update(id: string, data: Prisma.DriverUpdateInput) {
    return prisma.driver.update({
      where: { id },
      data,
      include: { user: true },
    });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.DriverWhereInput;
    orderBy?: Prisma.DriverOrderByWithRelationInput;
  }) {
    return prisma.driver.findMany({
      ...params,
      include: {
        user: true,
        vehicleAssignments: {
          where: { unassignedAt: null },
          include: { vehicle: true },
        },
      },
    });
  }

  async count(where?: Prisma.DriverWhereInput): Promise<number> {
    return prisma.driver.count({ where });
  }

  async assignVehicle(
    driverId: string,
    vehicleId: string
  ): Promise<VehicleAssignment> {
    // End any current active assignment for this driver
    await prisma.vehicleAssignment.updateMany({
      where: { driverId, unassignedAt: null },
      data: { unassignedAt: new Date() },
    });

    // End any current active assignment for this vehicle
    await prisma.vehicleAssignment.updateMany({
      where: { vehicleId, unassignedAt: null },
      data: { unassignedAt: new Date() },
    });

    // Register new vehicle allocation
    return prisma.vehicleAssignment.create({
      data: {
        driverId,
        vehicleId,
      },
    });
  }

  async unassignVehicle(driverId: string): Promise<Prisma.BatchPayload> {
    return prisma.vehicleAssignment.updateMany({
      where: { driverId, unassignedAt: null },
      data: { unassignedAt: new Date() },
    });
  }

  async getScoresTrend(driverId: string, limit = 30): Promise<DriverScore[]> {
    return prisma.driverScore.findMany({
      where: { driverId },
      orderBy: { date: 'desc' },
      take: limit,
    });
  }

  async recordScore(
    driverId: string,
    safetyScore: number,
    riskScore: number,
    date: Date
  ): Promise<DriverScore> {
    return prisma.driverScore.create({
      data: {
        driverId,
        safetyScore,
        riskScore,
        date,
      },
    });
  }
}
export const driverRepository = new DriverRepository();
