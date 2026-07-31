import { Router } from 'express';
import { driverController } from '../controllers/driver.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import {
  updateProfileSchema,
  assignVehicleSchema,
} from '../validators/driver.validator';
import { Role } from '@prisma/client';

const router = Router();

// Secure all routes with authentication middleware
router.use(authenticate);

router.get(
  '/',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN, Role.FLEET_MANAGER),
  driverController.getList
);

router.get('/:id', driverController.getProfile);

router.put(
  '/:id',
  validateRequest(updateProfileSchema),
  driverController.updateProfile
);

router.post(
  '/:id/assign',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN, Role.FLEET_MANAGER),
  validateRequest(assignVehicleSchema),
  driverController.assignVehicle
);

router.post(
  '/:id/unassign',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN, Role.FLEET_MANAGER),
  driverController.unassignVehicle
);

router.get('/:id/scores-trend', driverController.getScoresTrend);

export default router;
