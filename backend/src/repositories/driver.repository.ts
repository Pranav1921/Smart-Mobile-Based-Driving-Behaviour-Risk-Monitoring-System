import { prisma } from '../database/client';
import { Prisma, VehicleAssignment, DriverScore } from '@prisma/client';

export class DriverRepository {
  async findById(id: string) {
    return prisma.driver.findFirst({
      where: {
        OR: [
          { id },
          { userId: id },
        ],
      },
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
      include: {
        user: true,
        vehicleAssignments: {
          where: { unassignedAt: null },
          include: { vehicle: true },
        },
      },
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

  async delete(id: string) {
    const driver = await this.findById(id);
    if (!driver) return null;
    const realDriverId = driver.id;
    const realUserId = driver.userId;

    // Purge dependent tables in sequence to avoid foreign key constraints
    await prisma.vehicleAssignment.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.driverScore.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.event.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.tripPoint.deleteMany({ where: { trip: { driverId: realDriverId } } }).catch(() => {});
    await prisma.trip.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.crashReport.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.media.deleteMany({ where: { driverId: realDriverId } }).catch(() => {});
    await prisma.notification.deleteMany({ where: { userId: realUserId } }).catch(() => {});
    await prisma.auditLog.deleteMany({ where: { userId: realUserId } }).catch(() => {});

    // Delete driver profile
    const deletedDriver = await prisma.driver.delete({ where: { id: realDriverId } }).catch(() => null);

    // Delete linked user record
    if (realUserId) {
      await prisma.user.delete({ where: { id: realUserId } }).catch(() => {});
    }

    return deletedDriver;
  }
}
export const driverRepository = new DriverRepository();
