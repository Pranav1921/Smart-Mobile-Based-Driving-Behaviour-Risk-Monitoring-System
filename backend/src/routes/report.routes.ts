import { Router } from 'express';
import { reportController } from '../controllers/report.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Allow public/demo access or authenticated access to monthly drivers report and municipal potholes export
router.get('/monthly-drivers', reportController.getMonthlyDriversReport);
router.get('/potholes/export', reportController.exportMunicipalPotholes);

router.use(authenticate);

router.post('/export', reportController.exportReport);
router.get('/notifications', reportController.getNotifications);

export default router;
