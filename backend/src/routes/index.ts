import { Router } from 'express';
import authRoutes from './auth.routes';
import driverRoutes from './driver.routes';
import vehicleRoutes from './vehicle.routes';
import tripRoutes from './trip.routes';
import eventRoutes from './event.routes';
import crashRoutes from './crash.routes';
import reportRoutes from './report.routes';
import orderRoutes from './order.routes';
import alertRoutes from './alert.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/drivers', driverRoutes);
router.use('/vehicles', vehicleRoutes);
router.use('/trips', tripRoutes);
router.use('/events', eventRoutes);
router.use('/crashes', crashRoutes);
router.use('/reports', reportRoutes);
router.use('/orders', orderRoutes);
router.use('/alerts', alertRoutes);

export default router;
