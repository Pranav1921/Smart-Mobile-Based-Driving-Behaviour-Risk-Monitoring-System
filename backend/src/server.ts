import dotenv from 'dotenv';
// Load environment variables immediately
dotenv.config();

import http from 'http';
import { app } from './app';
import { socketManager } from './sockets/socket.manager';
import { discoveryService } from './services/discovery.service';
import { logger } from './config/logger';
import { prisma } from './database/client';

// Trigger initialization of BullMQ workers
import './jobs/worker';

import os from 'os';

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

// Mount Socket.IO broadcast handlers
socketManager.initialize(server);

// Start UDP Zero-Config Auto-Discovery responder
discoveryService.start(Number(PORT));

function getNetworkIps(): string[] {
  const interfaces = os.networkInterfaces();
  const ips: string[] = [];
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ips.push(iface.address);
      }
    }
  }
  return ips;
}

// Start server listening loop
server.listen(Number(PORT), '0.0.0.0', async () => {
  const activeIps = getNetworkIps();
  logger.info(`=======================================================`);
  logger.info(`  Smart Driving Monitoring Backend Service active on Port ${PORT} `);
  logger.info(`  Local:            http://localhost:${PORT}`);
  for (const ip of activeIps) {
    logger.info(`  Network (Active): http://${ip}:${PORT}`);
  }
  logger.info(`  Documentation:    http://localhost:${PORT}/api-docs`);
  logger.info(`=======================================================`);

  try {
    await prisma.$connect();
    logger.info('PostgreSQL database verification completed successfully.');
  } catch (err) {
    logger.warn(
      'PostgreSQL database verification failed. Operating in resilient / memory mode for Socket.IO and telemetry.',
      err
    );
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
