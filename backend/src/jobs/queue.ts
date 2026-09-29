import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { logger } from '../config/logger';

const REDIS_URL = process.env.REDIS_URL || 'redis://127.0.0.1:6379';

// Setup connection options for Redis
export const redisConnection = new IORedis(REDIS_URL, {
  maxRetriesPerRequest: null,
  retryStrategy: (times) => {
    // Limited retry to prevent infinite log spam if Docker is off
    if (times > 3) {
      return null; // Stop retrying
    }
    return Math.min(times * 100, 3000);
  },
});

let lastError = '';
redisConnection.on('error', (err) => {
  const msg = err.message;
  if (msg !== lastError) {
    logger.error('Redis Connection Issue:', msg);
    lastError = msg;
  }
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
