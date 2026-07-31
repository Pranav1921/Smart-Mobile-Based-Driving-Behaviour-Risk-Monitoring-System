import { Router } from 'express';
import { alertController } from '../controllers/alert.controller';

const router = Router();

// Endpoint for the dashboard admin to trigger a vibration alert on a driver's mobile app
router.post('/vibrate/:driverId', alertController.sendVibration);

export default router;
