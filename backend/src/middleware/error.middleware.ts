import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../utils/app-error';
import { logger } from '../config/logger';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (err instanceof ZodError) {
    logger.debug(`Validation error triggered: ${JSON.stringify(err.errors)}`);
    return res.status(400).json({
      status: 'error',
      message: 'Input validation check failed',
      errors: err.errors.map((e) => ({
        path: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  if (err instanceof AppError) {
    logger.debug(`Operational AppError: [${err.statusCode}] - ${err.message}`);
    return res.status(err.statusCode).json({
      status: 'error',
      message: err.message,
    });
  }

  logger.error('Unhandled system exception caught in global handler:', err);

  const isProduction = process.env.NODE_ENV === 'production';
  return res.status(500).json({
    status: 'error',
    message: isProduction ? 'Internal Server Error' : err.message,
    stack: isProduction ? undefined : err.stack,
  });
};
export default errorHandler;
