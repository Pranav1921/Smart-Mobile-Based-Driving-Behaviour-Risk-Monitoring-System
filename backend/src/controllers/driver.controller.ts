import { Request, Response, NextFunction } from 'express';
import { driverService } from '../services/driver.service';
import { ForbiddenError } from '../utils/app-error';

export class DriverController {
  async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError(
          'Access Denied: Drivers are isolated by Organization'
        );
      }

      res.status(200).json({
        status: 'success',
        data: driver,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const updated = await driverService.updateProfile(id, req.body);
      res.status(200).json({
        status: 'success',
        message: 'Driver profile updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async assignVehicle(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { vehicleId } = req.body;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const assignment = await driverService.assignVehicle(id, vehicleId);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle assignment completed successfully',
        data: assignment,
      });
    } catch (error) {
      next(error);
    }
  }

  async unassignVehicle(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      await driverService.unassignVehicle(id);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle unassigned successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  async getScoresTrend(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const trend = await driverService.getScoresTrend(id);
      res.status(200).json({
        status: 'success',
        data: trend,
      });
    } catch (error) {
      next(error);
    }
  }

  async getList(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId;
      if (!orgId) {
        throw new ForbiddenError('Missing organization parameter context');
      }

      const skip = Number(req.query.skip) || 0;
      const take = Number(req.query.take) || 10;

      const result = await driverService.getDriversList(orgId, skip, take);
      res.status(200).json({
        status: 'success',
        data: result.drivers,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const driverController = new DriverController();
