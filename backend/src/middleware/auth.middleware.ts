import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';
import { UnauthorizedError, ForbiddenError } from '../utils/app-error';
import { TokenPayload } from '../services/auth.service';

const ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ||
  'super-secret-access-key-smartdrive-ai-2026';

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export const authenticate = (
  req: Request,
  _res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(
      new UnauthorizedError(
        'Authentication failed: Bearer token is missing or malformed'
      )
    );
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, ACCESS_SECRET) as TokenPayload;
    req.user = decoded;
    next();
  } catch {
    return next(
      new UnauthorizedError('Authentication failed: Invalid or expired token')
    );
  }
};

export const authorize = (...allowedRoles: Role[]) => {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new UnauthorizedError('Client is unauthenticated'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        new ForbiddenError(
          'Access denied: You do not possess the required role permissions'
        )
      );
    }

    next();
  };
};
