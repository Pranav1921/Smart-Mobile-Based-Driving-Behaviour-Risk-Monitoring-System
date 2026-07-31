import { driverRepository } from '../repositories/driver.repository';
import { NotFoundError } from '../utils/app-error';

export class DriverService {
  async getDriverProfile(driverId: string) {
    const driver = await driverRepository.findById(driverId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }
    return driver;
  }

  async getDriverByUserId(userId: string) {
    const driver = await driverRepository.findByUserId(userId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }
    return driver;
  }

  async updateProfile(driverId: string, data: any) {
    const driver = await driverRepository.findById(driverId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }

    return driverRepository.update(driverId, data);
  }

  async assignVehicle(driverId: string, vehicleId: string) {
    const driver = await driverRepository.findById(driverId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }

    return driverRepository.assignVehicle(driverId, vehicleId);
  }

  async unassignVehicle(driverId: string): Promise<void> {
    const driver = await driverRepository.findById(driverId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }

    await driverRepository.unassignVehicle(driverId);
  }

  async getScoresTrend(driverId: string, limit = 30) {
    const driver = await driverRepository.findById(driverId);
    if (!driver) {
      throw new NotFoundError('Driver profile not found');
    }

    return driverRepository.getScoresTrend(driverId, limit);
  }

  async getDriversList(organizationId: string, skip = 0, take = 10) {
    const where = { user: { organizationId } };
    const drivers = await driverRepository.findMany({
      skip,
      take,
      where,
      orderBy: { createdAt: 'desc' },
    });
    const count = await driverRepository.count(where);
    return { drivers, count };
  }
}
export const driverService = new DriverService();
