import { crashRepository } from '../repositories/crash.repository';
import { aiService } from '../ai/ai.service';
import { socketManager } from '../sockets/socket.manager';
import { notificationDispatchQueue } from '../jobs/queue';
import { FileType, Severity, EmergencyStatus, CrashReport, Media } from '@prisma/client';
import { NotFoundError } from '../utils/app-error';
import { logger } from '../config/logger';
import { StorageProvider } from '../storage/storage.provider';

export class CrashService {
  async reportCrash(data: {
    tripId?: string;
    driverId: string;
    vehicleId: string;
    organizationId: string;
    latitude: number;
    longitude: number;
    sensorValues: any;
    severity: Severity;
    timestamp?: string;
  }): Promise<CrashReport> {
    logger.warn(
      `Crash Event Triggered: Driver ${data.driverId} in Organization ${data.organizationId}`
    );

    const crashReport = await crashRepository.create({
      tripId: data.tripId || null,
      driverId: data.driverId,
      vehicleId: data.vehicleId,
      organizationId: data.organizationId,
      latitude: data.latitude,
      longitude: data.longitude,
      sensorValues: data.sensorValues,
      severity: data.severity,
      timestamp: data.timestamp ? new Date(data.timestamp) : new Date(),
    });

    const aiAnalysis = await aiService.generateCrashSummary(
      crashReport.id,
      data.sensorValues
    );

    const updatedReport = await crashRepository.update(crashReport.id, {
      aiSummary: aiAnalysis.summary,
      crashProbability: aiAnalysis.crashProbability,
    });

    // Send real-time Socket notifications to organization room
    socketManager.broadcastToOrg(data.organizationId, 'crash_alert', {
      reportId: updatedReport.id,
      driverId: data.driverId,
      vehicleId: data.vehicleId,
      latitude: data.latitude,
      longitude: data.longitude,
      severity: data.severity,
      aiSummary: aiAnalysis.summary,
      timestamp: updatedReport.timestamp,
    });

    // Queue emergency contacts notify job
    try {
      await notificationDispatchQueue.add('dispatch-emergency', {
        crashReportId: updatedReport.id,
        organizationId: data.organizationId,
      });
      logger.info(`Dispatched emergency job to BullMQ queue: ${updatedReport.id}`);
    } catch (err) {
      logger.error('Failed to enqueue emergency notification dispatch job:', err);
    }

    return updatedReport;
  }

  async uploadCrashMedia(
    crashReportId: string,
    file: Express.Multer.File,
    fileType: FileType,
    storageProvider: StorageProvider
  ): Promise<Media> {
    const report = await crashRepository.findById(crashReportId);
    if (!report) {
      throw new NotFoundError('Crash report not found');
    }

    const folder = fileType === FileType.IMAGE ? 'crashes/images' : 'crashes/videos';
    const upload = await storageProvider.uploadFile(file, folder);

    return crashRepository.addMedia({
      organizationId: report.organizationId,
      crashReportId,
      url: upload.url,
      publicId: upload.publicId || null,
      fileType,
      purpose: fileType === FileType.IMAGE ? 'CRASH_IMAGE' : 'CRASH_VIDEO',
    });
  }

  async getCrashReport(id: string): Promise<CrashReport> {
    const report = await crashRepository.findById(id);
    if (!report) {
      throw new NotFoundError('Crash report not found');
    }
    return report;
  }

  async getCrashReportsList(
    organizationId: string,
    query: {
      skip?: number;
      take?: number;
      severity?: Severity;
      status?: EmergencyStatus;
    }
  ): Promise<{ reports: CrashReport[]; count: number }> {
    const where: any = { organizationId };
    if (query.severity) {
      where.severity = query.severity;
    }
    if (query.status) {
      where.emergencyStatus = query.status;
    }

    const skip = Number(query.skip) || 0;
    const take = Number(query.take) || 10;

    const reports = await crashRepository.findMany({
      skip,
      take,
      where,
      orderBy: { timestamp: 'desc' },
    });
    const count = await crashRepository.count(where);

    return { reports, count };
  }

  async updateEmergencyStatus(
    id: string,
    status: EmergencyStatus
  ): Promise<CrashReport> {
    const report = await crashRepository.findById(id);
    if (!report) {
      throw new NotFoundError('Crash report not found');
    }

    return crashRepository.update(id, { emergencyStatus: status });
  }
}
export const crashService = new CrashService();
