import { Router } from 'express';
import { eventController } from '../controllers/event.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { logEventSchema } from '../validators/event.validator';
import { Role } from '@prisma/client';

const router = Router();

router.use(authenticate);

router.post(
  '/',
  authorize(Role.DRIVER),
  validateRequest(logEventSchema),
  eventController.log
);

router.get('/', eventController.getList);

export default router;
