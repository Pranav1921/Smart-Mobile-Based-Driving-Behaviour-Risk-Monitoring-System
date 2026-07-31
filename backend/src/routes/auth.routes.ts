import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { validateRequest } from '../middleware/validation.middleware';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
} from '../validators/auth.validator';

const router = Router();

router.post(
  '/register',
  validateRequest(registerSchema),
  authController.register
);
router.post('/login', validateRequest(loginSchema), authController.login);
router.post('/refresh', validateRequest(refreshSchema), authController.refresh);

export default router;
