import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { logger } from '../config/logger';

const REDIS_URL = process.env.REDIS_URL || 'redis://127.0.0.1:6379';

// Setup connection options for Redis
// maxRetriesPerRequest is set to null per BullMQ requirements
export const redisConnection = new IORedis(REDIS_URL, {
  maxRetriesPerRequest: null,
});

redisConnection.on('error', (err) => {
  logger.error('Redis Connection Error:', err);
});

redisConnection.on('connect', () => {
  logger.info('Connected to Redis for background queue management.');
});

// Configure core BullMQ background job queues
export const aiEvaluationQueue = new Queue('ai-evaluation', {
  connection: redisConnection,
});

export const reportGenerationQueue = new Queue('report-generation', {
  connection: redisConnection,
});

export const notificationDispatchQueue = new Queue('notification-dispatch', {
  connection: redisConnection,
});
