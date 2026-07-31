import { Request, Response, NextFunction } from 'express';
import { reportGenerationQueue } from '../jobs/queue';
import { prisma } from '../database/client';
import { ForbiddenError, BadRequestError } from '../utils/app-error';

export class ReportController {
  async exportReport(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = req.user?.organizationId;
      const userId = req.user?.userId;
      if (!orgId || !userId) {
        throw new ForbiddenError('Missing organization parameter context');
      }

      const { format, startDate, endDate } = req.body;
      if (!format || !startDate || !endDate) {
        throw new BadRequestError(
          'Format, startDate, and endDate options are mandatory'
        );
      }

      // Enqueue the report generation job into BullMQ
      const job = await reportGenerationQueue.add('generate-report', {
        organizationId: orgId,
        userId,
        format,
        startDate,
        endDate,
      });

      res.status(202).json({
        status: 'success',
        message: 'Fleet report generation task queued successfully',
        data: { jobId: job.id },
      });
    } catch (error) {
      next(error);
    }
  }

  async getNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new ForbiddenError('Client is unauthenticated');
      }

      const notifications = await prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        status: 'success',
        data: notifications,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const reportController = new ReportController();
