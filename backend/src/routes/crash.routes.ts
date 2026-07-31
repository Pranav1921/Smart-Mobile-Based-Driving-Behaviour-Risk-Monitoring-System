import { Router } from 'express';
import multer from 'multer';
import { crashController } from '../controllers/crash.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import {
  reportCrashSchema,
  updateCrashStatusSchema,
} from '../validators/crash.validator';
import { Role } from '@prisma/client';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.use(authenticate);

router.post(
  '/',
  authorize(Role.DRIVER),
  validateRequest(reportCrashSchema),
  crashController.log
);

router.get('/', crashController.getList);

router.get('/:id', crashController.get);

router.put(
  '/:id/status',
  authorize(
    Role.SUPER_ADMIN,
    Role.FLEET_ADMIN,
    Role.FLEET_MANAGER,
    Role.SUPPORT
  ),
  validateRequest(updateCrashStatusSchema),
  crashController.updateStatus
);

router.post('/:id/media', upload.single('file'), crashController.uploadMedia);

export default router;
