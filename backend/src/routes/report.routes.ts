import { Router } from 'express';
import { reportController } from '../controllers/report.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/export', reportController.exportReport);
router.get('/notifications', reportController.getNotifications);

export default router;
