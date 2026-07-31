import dotenv from 'dotenv';
// Load environment variables immediately
dotenv.config();

import http from 'http';
import { app } from './app';
import { socketManager } from './sockets/socket.manager';
import { logger } from './config/logger';
import { prisma } from './database/client';

// Trigger initialization of BullMQ workers
import './jobs/worker';

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

// Mount Socket.IO broadcast handlers
socketManager.initialize(server);

// Start server listening loop
server.listen(PORT, async () => {
  logger.info(`=======================================================`);
  logger.info(`  FleetGuard AI Backend Service active on Port ${PORT} `);
  logger.info(`  Documentation Swagger UI: http://localhost:${PORT}/api-docs`);
  logger.info(`=======================================================`);

  try {
    await prisma.$connect();
    logger.info('PostgreSQL database verification completed successfully.');
  } catch (err) {
    logger.error(
      'Startup failed: Unable to connect to PostgreSQL database.',
      err
    );
    process.exit(1);
  }
});

// Graceful shutdowns and error intercept logs
process.on('unhandledRejection', (reason: Error) => {
  logger.error('CRITICAL ERROR: Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (error: Error) => {
  logger.error('CRITICAL ERROR: Uncaught Exception event:', error);
  process.exit(1);
});

process.on('SIGTERM', () => {
  logger.warn('SIGTERM signal received. Commencing graceful shutdown...');
  server.close(() => {
    logger.info('HTTP listener shut down.');
    prisma.$disconnect().then(() => {
      logger.info('Database connection pool cleanly closed.');
      process.exit(0);
    });
  });
});
export default server;
