import { Request, Response, NextFunction } from 'express';
import { prisma } from '../database/client';
import { logger } from '../config/logger';

export const auditLogger = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Skip auditing during automated test suite runs
  if (process.env.NODE_ENV === 'test') {
    return next();
  }

  const originalSend = res.send;

  res.send = function (body): Response {
    res.send = originalSend;
    const responseResult = originalSend.call(this, body);

    try {
      const isModification = ['POST', 'PUT', 'DELETE', 'PATCH'].includes(
        req.method
      );
      const isSuccess = res.statusCode >= 200 && res.statusCode < 300;

      if (isModification && isSuccess) {
        const userId = req.user?.userId || null;
        const organizationId = req.user?.organizationId || null;
        const action = `${req.method} ${req.originalUrl}`;
        const ipAddress = req.ip || req.socket.remoteAddress || null;

        const sanitizedBody = { ...req.body };
        const sensitiveKeys = [
          'password',
          'passwordHash',
          'token',
          'refreshToken',
          'accessToken',
        ];
        sensitiveKeys.forEach((key) => {
          if (sanitizedBody[key]) sanitizedBody[key] = '[REDACTED]';
        });

        prisma.auditLog
          .create({
            data: {
              userId,
              organizationId,
              action,
              details: JSON.stringify(sanitizedBody),
              ipAddress,
            },
          })
          .catch((err) => {
            logger.error('Async audit log record failed:', err);
          });
      }
    } catch (err) {
      logger.error('Failed to log route audit transaction details:', err);
    }

    return responseResult;
  };

  next();
};
