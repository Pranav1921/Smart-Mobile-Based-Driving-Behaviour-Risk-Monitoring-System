import winston from 'winston';
import path from 'path';
import fs from 'fs';

const logDir = path.join(process.cwd(), 'logs');

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(
    (info) =>
      `[${info.timestamp}] [${info.level.toUpperCase()}]: ${info.message}${
        info.stack ? `\nStack Trace:\n${info.stack}` : ''
      }`
  )
);

const devFormat = winston.format.combine(
  winston.format.colorize({ all: true }),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(
    (info) =>
      `[${info.timestamp}] [${info.level}]: ${info.message}${
        info.stack ? `\n${info.stack}` : ''
      }`
  )
);

const transports = [
  new winston.transports.Console({
    format: devFormat,
    level: process.env.NODE_ENV === 'development' ? 'debug' : 'info',
  }),
  new winston.transports.File({
    filename: path.join(logDir, 'error.log'),
    level: 'error',
    format,
  }),
  new winston.transports.File({
    filename: path.join(logDir, 'app.log'),
    level: 'info',
    format,
  }),
];

export const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'development' ? 'debug' : 'info',
  transports,
});

export const requestLogger = winston.createLogger({
  level: 'info',
  transports: [
    new winston.transports.File({
      filename: path.join(logDir, 'requests.log'),
      format,
    }),
    new winston.transports.Console({
      format: devFormat,
    }),
  ],
});
