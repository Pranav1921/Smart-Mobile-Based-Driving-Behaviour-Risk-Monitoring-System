import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';

export class AuthController {
  async applyDriver(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.applyDriver(req.body);
      res.status(201).json({
        status: 'success',
        message: 'Driver registration submitted for Regional Admin approval',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async changeInitialPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.changeInitialPassword(req.body);
      res.status(200).json({
        status: 'success',
        message: 'Permanent password established successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.register(req.body);
      res.status(201).json({
        status: 'success',
        message: 'User registered successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.login(req.body);
      res.status(200).json({
        status: 'success',
        message: 'Authentication successful',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await authService.refreshToken(req.body.refreshToken);
      res.status(200).json({
        status: 'success',
        message: 'Refresh operation completed successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getApplicationStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const email = req.query.email ? String(req.query.email) : undefined;
      const trackingId = req.query.trackingId ? String(req.query.trackingId) : undefined;
      const licenseNumber = req.query.licenseNumber ? String(req.query.licenseNumber) : undefined;

      const result = await authService.getApplicationStatus({ email, trackingId, licenseNumber });
      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ status: 'fail', message: 'Unauthorized' });
        return;
      }

      const { firstName, lastName } = req.body;
      const updatedUser = await authService.updateUserProfile(userId, { firstName, lastName });
      res.status(200).json({
        status: 'success',
        message: 'Profile name updated successfully',
        data: updatedUser,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const authController = new AuthController();
