import { Request, Response, NextFunction } from 'express';
import { eventService } from '../services/event.service';
import { driverRepository } from '../repositories/driver.repository';
import { ForbiddenError, BadRequestError } from '../utils/app-error';

export class EventController {
  async log(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId;
      if (!orgId) {
        throw new ForbiddenError('Missing organization parameter context');
      }

      const driver = await driverRepository.findByUserId(req.user!.userId);
      if (!driver) {
        throw new BadRequestError('User does not have an active driver profile');
      }

      const event = await eventService.logEvent({
        ...req.body,
        driverId: driver.id,
        organizationId: orgId,
      });

      res.status(201).json({
        status: 'success',
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  async getList(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId || (req.query.organizationId as string);

      const result = await eventService.getEventsList(orgId, req.query);
      res.status(200).json({
        status: 'success',
        data: result.events,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const eventController = new EventController();
