import { Request, Response, NextFunction } from 'express';
import { vehicleService } from '../services/vehicle.service';
import { ForbiddenError } from '../utils/app-error';

export class VehicleController {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId;
      if (!orgId) {
        throw new ForbiddenError('Missing organization parameter context');
      }

      const vehicle = await vehicleService.createVehicle(orgId, req.body);
      res.status(201).json({
        status: 'success',
        message: 'Vehicle registered successfully',
        data: vehicle,
      });
    } catch (error) {
      next(error);
    }
  }

  async get(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const vehicle = await vehicleService.getVehicle(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        vehicle.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      res.status(200).json({
        status: 'success',
        data: vehicle,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const vehicle = await vehicleService.getVehicle(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        vehicle.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const updated = await vehicleService.updateVehicle(id, req.body);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const vehicle = await vehicleService.getVehicle(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        vehicle.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      await vehicleService.deleteVehicle(id);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  async getList(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId || (req.query.organizationId as string);

      const result = await vehicleService.getVehiclesList(orgId, req.query);
      res.status(200).json({
        status: 'success',
        data: result.vehicles,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const vehicleController = new VehicleController();
