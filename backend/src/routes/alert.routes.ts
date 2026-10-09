import { Router } from 'express';
import { alertController } from '../controllers/alert.controller';

const router = Router();

// Endpoint for the dashboard admin to trigger a vibration alert on a driver's mobile app
router.post('/vibrate/:driverId', alertController.sendVibration);

// Test Simulation Endpoints
router.post('/simulate-sos', alertController.simulateSos);
router.post('/simulate-nearest-driver', alertController.simulateNearestDriver);
router.post('/simulate-cross-delivery', alertController.simulateCrossDelivery);

export default router;
