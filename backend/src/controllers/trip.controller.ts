import { Request, Response, NextFunction } from 'express';
import { tripService } from '../services/trip.service';
import { tripRepository } from '../repositories/trip.repository';
import { driverRepository } from '../repositories/driver.repository';
import { ForbiddenError, BadRequestError, NotFoundError } from '../utils/app-error';

export class TripController {
  async start(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId;
      if (!orgId) {
        throw new ForbiddenError('Missing organization parameter context');
      }

      const driver = await driverRepository.findByUserId(req.user!.userId);
      if (!driver) {
        throw new BadRequestError('User does not have an active driver profile');
      }

      const { vehicleId, deliveryFrom, deliveryTo, orderItems, orderId } = req.body;
      const trip = await tripService.startTrip(driver.id, vehicleId, orgId, {
        deliveryFrom,
        deliveryTo,
        orderItems,
        orderId,
      });

      res.status(201).json({
        status: 'success',
        message: 'Trip started successfully',
        data: trip,
      });
    } catch (error) {
      next(error);
    }
  }

  async end(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const trip = await tripService.endTrip(id);

      res.status(200).json({
        status: 'success',
        message: 'Trip ended successfully',
        data: trip,
      });
    } catch (error) {
      next(error);
    }
  }

  async recordLocation(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const point = await tripService.recordLocation(id, req.body);
      res.status(201).json({
        status: 'success',
        data: point,
      });
    } catch (error) {
      next(error);
    }
  }

  async getList(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId || (req.query.organizationId as string);

      const result = await tripService.getTripsList(orgId, req.query);
      res.status(200).json({
        status: 'success',
        data: result.trips,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }

  async get(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const fullTrip = await tripRepository.findById(id);

      if (!fullTrip) {
        throw new NotFoundError('Trip record not found');
      }

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        fullTrip.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      res.status(200).json({
        status: 'success',
        data: fullTrip,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const tripController = new TripController();
