import { Request, Response, NextFunction } from 'express';
import { crashService } from '../services/crash.service';
import { driverRepository } from '../repositories/driver.repository';
import { ForbiddenError, BadRequestError } from '../utils/app-error';
import { LocalProvider } from '../storage/local.provider';
import { FileType } from '@prisma/client';

const storage = new LocalProvider();

export class CrashController {
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

      const report = await crashService.reportCrash({
        ...req.body,
        driverId: driver.id,
        organizationId: orgId,
      });

      res.status(201).json({
        status: 'success',
        data: report,
      });
    } catch (error) {
      next(error);
    }
  }

  async get(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const report = await crashService.getCrashReport(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        report.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      res.status(200).json({
        status: 'success',
        data: report,
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

      const result = await crashService.getCrashReportsList(orgId, req.query);
      res.status(200).json({
        status: 'success',
        data: result.reports,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const report = await crashService.getCrashReport(id);
      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        report.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const updated = await crashService.updateEmergencyStatus(id, status);
      res.status(200).json({
        status: 'success',
        message: 'Emergency dispatch status updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async uploadMedia(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { fileType } = req.body; // IMAGE, VIDEO, or AUDIO
      const file = req.file;

      if (!file) {
        throw new BadRequestError('No media file payload was uploaded');
      }

      let mediaType: FileType;
      if (fileType === 'VIDEO') mediaType = FileType.VIDEO;
      else if (fileType === 'AUDIO') mediaType = FileType.AUDIO;
      else mediaType = FileType.IMAGE;

      const media = await crashService.uploadCrashMedia(
        id,
        file,
        mediaType,
        storage
      );

      res.status(201).json({
        status: 'success',
        message: 'Crash incident media uploaded successfully',
        data: media,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const crashController = new CrashController();
