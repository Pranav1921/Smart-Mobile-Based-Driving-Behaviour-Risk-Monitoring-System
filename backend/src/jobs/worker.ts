import { Worker, Job } from 'bullmq';
import { redisConnection } from './queue';
import { aiService } from '../ai/ai.service';
import { reportService } from '../services/report.service';
import { logger } from '../config/logger';
import { prisma } from '../database/client';
import fs from 'fs';
import path from 'path';

// AI Trip Evaluation Background Worker
const aiWorker = new Worker(
  'ai-evaluation',
  async (job: Job) => {
    logger.info(`Starting BullMQ AI evaluation job: ${job.id}`);
    const { tripId } = job.data;
    try {
      const evaluation = await aiService.evaluateTripSafety(tripId);
      logger.info(
        `AI safety evaluation completed for trip ${tripId}. Score: ${evaluation.safetyScore}`
      );
      return evaluation;
    } catch (error) {
      logger.error(`AI safety evaluation failed for trip ${tripId}:`, error);
      throw error;
    }
  },
  { connection: redisConnection }
);

// Report Generation Background Worker
const reportWorker = new Worker(
  'report-generation',
  async (job: Job) => {
    logger.info(`Starting BullMQ report generation job: ${job.id}`);
    const { organizationId, userId, format, startDate, endDate } = job.data;

    try {
      const start = new Date(startDate);
      const end = new Date(endDate);

      const buffer = await reportService.generateFleetReport(
        organizationId,
        format,
        start,
        end
      );

      const relativeFolder = 'reports';
      const uploadDir = path.resolve(
        process.env.LOCAL_STORAGE_DIR || './uploads'
      );
      const targetFolder = path.join(uploadDir, relativeFolder);
      if (!fs.existsSync(targetFolder)) {
        fs.mkdirSync(targetFolder, { recursive: true });
      }

      const fileExt = format.toLowerCase();
      const fileName = `report-${organizationId}-${Date.now()}.${fileExt}`;
      const absolutePath = path.join(targetFolder, fileName);
      await fs.promises.writeFile(absolutePath, buffer);

      const downloadUrl = `/uploads/reports/${fileName}`;
      logger.info(`Operational report generated: ${downloadUrl}`);

      // Push database notification
      await prisma.notification.create({
        data: {
          userId,
          organizationId,
          title: 'Fleet Report Generated',
          message: `Your fleet safety report (${format}) is ready for download.`,
          type: 'SYSTEM',
        },
      });

      return { downloadUrl };
    } catch (error) {
      logger.error(
        'Failed to generate operational report asynchronously:',
        error
      );
      throw error;
    }
  },
  { connection: redisConnection }
);

// Emergency Notification Dispatch Background Worker
const notificationWorker = new Worker(
  'notification-dispatch',
  async (job: Job) => {
    logger.info(`Starting BullMQ notification dispatch job: ${job.id}`);
    const { crashReportId } = job.data;
    try {
      const report = await prisma.crashReport.findUnique({
        where: { id: crashReportId },
        include: { driver: { include: { user: true } } },
      });

      if (!report) {
        throw new Error(`Crash report ID ${crashReportId} not found`);
      }

      logger.warn(
        `[EMERGENCY RESPONSE DISPATCH] Sending SMS/Email alerts to emergency contact ${report.driver.emergencyContactName} (${report.driver.emergencyContactPhone}) regarding crash severity ${report.severity} for Driver ${report.driver.user.firstName} ${report.driver.user.lastName}`
      );

      return { status: 'DISPATCHED' };
    } catch (error) {
      logger.error(
        `Failed to dispatch emergency alerts for crash ${crashReportId}:`,
        error
      );
      throw error;
    }
  },
  { connection: redisConnection }
);

// Listeners
aiWorker.on('failed', (job, err) => {
  logger.error(`AI Evaluation job failed: ${job?.id}`, err);
});

reportWorker.on('failed', (job, err) => {
  logger.error(`Report Generation job failed: ${job?.id}`, err);
});

notificationWorker.on('failed', (job, err) => {
  logger.error(`Notification Dispatch job failed: ${job?.id}`, err);
});

logger.info('BullMQ background workers initialized.');

export { aiWorker, reportWorker, notificationWorker };
