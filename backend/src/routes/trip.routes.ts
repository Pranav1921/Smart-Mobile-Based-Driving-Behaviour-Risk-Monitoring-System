import { Router } from 'express';
import { tripController } from '../controllers/trip.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import {
  startTripSchema,
  locationUpdateSchema,
} from '../validators/trip.validator';
import { Role } from '@prisma/client';

const router = Router();

router.use(authenticate);

router.post(
  '/start',
  authorize(Role.DRIVER),
  validateRequest(startTripSchema),
  tripController.start
);

router.post('/:id/end', tripController.end);

router.post(
  '/:id/location',
  authorize(Role.DRIVER),
  validateRequest(locationUpdateSchema),
  tripController.recordLocation
);

router.get('/', tripController.getList);

router.get('/:id', tripController.get);

export default router;
