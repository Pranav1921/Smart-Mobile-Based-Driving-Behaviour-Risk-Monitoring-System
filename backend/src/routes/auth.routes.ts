import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { validateRequest } from '../middleware/validation.middleware';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
} from '../validators/auth.validator';

import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/driver-apply', authController.applyDriver);
router.get('/application-status', authController.getApplicationStatus);
router.post('/change-initial-password', authController.changeInitialPassword);

router.post(
  '/register',
  validateRequest(registerSchema),
  authController.register
);
router.post('/login', validateRequest(loginSchema), authController.login);
router.post('/refresh', validateRequest(refreshSchema), authController.refresh);
router.put('/profile', authenticate, authController.updateProfile);

export default router;
