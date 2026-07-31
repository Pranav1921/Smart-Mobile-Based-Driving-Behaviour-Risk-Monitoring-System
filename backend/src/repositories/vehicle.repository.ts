import { prisma } from '../database/client';
import { Vehicle, Prisma } from '@prisma/client';

export class VehicleRepository {
  async findById(id: string): Promise<Vehicle | null> {
    return prisma.vehicle.findUnique({
      where: { id },
      include: {
        vehicleAssignments: {
          where: { unassignedAt: null },
          include: { driver: { include: { user: true } } },
        },
      },
    });
  }

  async findByPlate(licensePlate: string): Promise<Vehicle | null> {
    return prisma.vehicle.findUnique({
      where: { licensePlate },
    });
  }

  async create(data: Prisma.VehicleCreateInput): Promise<Vehicle> {
    return prisma.vehicle.create({ data });
  }

  async update(id: string, data: Prisma.VehicleUpdateInput): Promise<Vehicle> {
    return prisma.vehicle.update({ where: { id }, data });
  }

  async delete(id: string): Promise<Vehicle> {
    return prisma.vehicle.delete({ where: { id } });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.VehicleWhereInput;
    orderBy?: Prisma.VehicleOrderByWithRelationInput;
  }): Promise<Vehicle[]> {
    return prisma.vehicle.findMany({
      ...params,
      include: {
        vehicleAssignments: {
          where: { unassignedAt: null },
          include: { driver: { include: { user: true } } },
        },
      },
    });
  }

  async count(where?: Prisma.VehicleWhereInput): Promise<number> {
    return prisma.vehicle.count({ where });
  }
}
export const vehicleRepository = new VehicleRepository();
