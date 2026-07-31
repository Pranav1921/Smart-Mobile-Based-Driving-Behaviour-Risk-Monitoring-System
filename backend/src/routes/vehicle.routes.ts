import { Router } from 'express';
import { vehicleController } from '../controllers/vehicle.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import {
  createVehicleSchema,
  updateVehicleSchema,
} from '../validators/vehicle.validator';
import { Role } from '@prisma/client';

const router = Router();

router.use(authenticate);

router.post(
  '/',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN, Role.FLEET_MANAGER),
  validateRequest(createVehicleSchema),
  vehicleController.create
);

router.get('/', vehicleController.getList);

router.get('/:id', vehicleController.get);

router.put(
  '/:id',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN, Role.FLEET_MANAGER),
  validateRequest(updateVehicleSchema),
  vehicleController.update
);

router.delete(
  '/:id',
  authorize(Role.SUPER_ADMIN, Role.FLEET_ADMIN),
  vehicleController.delete
);

export default router;
