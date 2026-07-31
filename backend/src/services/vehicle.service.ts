import { vehicleRepository } from '../repositories/vehicle.repository';
import { NotFoundError, ConflictError } from '../utils/app-error';
import { Vehicle, VehicleType, MaintenanceStatus, Prisma } from '@prisma/client';

export class VehicleService {
  async createVehicle(
    organizationId: string,
    data: {
      make: string;
      model: string;
      year: number;
      vehicleType: VehicleType;
      licensePlate: string;
      insuranceNumber: string;
      insuranceExpiry: string | Date;
      registrationNumber: string;
    }
  ): Promise<Vehicle> {
    const existing = await vehicleRepository.findByPlate(data.licensePlate);
    if (existing) {
      throw new ConflictError(
        'A vehicle with this license plate is already registered'
      );
    }

    return vehicleRepository.create({
      make: data.make,
      model: data.model,
      year: data.year,
      vehicleType: data.vehicleType,
      licensePlate: data.licensePlate,
      insuranceNumber: data.insuranceNumber,
      insuranceExpiry: new Date(data.insuranceExpiry),
      registrationNumber: data.registrationNumber,
      organization: { connect: { id: organizationId } },
    });
  }

  async getVehicle(id: string): Promise<Vehicle> {
    const vehicle = await vehicleRepository.findById(id);
    if (!vehicle) {
      throw new NotFoundError('Vehicle not found');
    }
    return vehicle;
  }

  async updateVehicle(id: string, data: any): Promise<Vehicle> {
    const vehicle = await vehicleRepository.findById(id);
    if (!vehicle) {
      throw new NotFoundError('Vehicle not found');
    }

    const payload = { ...data };
    if (payload.insuranceExpiry) {
      payload.insuranceExpiry = new Date(payload.insuranceExpiry);
    }

    return vehicleRepository.update(id, payload);
  }

  async deleteVehicle(id: string): Promise<void> {
    const vehicle = await vehicleRepository.findById(id);
    if (!vehicle) {
      throw new NotFoundError('Vehicle not found');
    }
    await vehicleRepository.delete(id);
  }

  async getVehiclesList(
    organizationId: string,
    query: {
      skip?: number;
      take?: number;
      vehicleType?: VehicleType;
      maintenanceStatus?: MaintenanceStatus;
    }
  ): Promise<{ vehicles: Vehicle[]; count: number }> {
    const where: Prisma.VehicleWhereInput = { organizationId };

    if (query.vehicleType) {
      where.vehicleType = query.vehicleType;
    }
    if (query.maintenanceStatus) {
      where.maintenanceStatus = query.maintenanceStatus;
    }

    const skip = Number(query.skip) || 0;
    const take = Number(query.take) || 10;

    const vehicles = await vehicleRepository.findMany({
      skip,
      take,
      where,
      orderBy: { createdAt: 'desc' },
    });

    const count = await vehicleRepository.count(where);

    return { vehicles, count };
  }
}
export const vehicleService = new VehicleService();
