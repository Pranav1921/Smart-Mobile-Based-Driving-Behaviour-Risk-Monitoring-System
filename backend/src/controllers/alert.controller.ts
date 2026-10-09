import { Request, Response } from 'express';
import { socketManager } from '../sockets/socket.manager';
import { logger } from '../config/logger';

export class AlertController {
  public sendVibration = async (req: Request, res: Response) => {
    try {
      const { driverId } = req.params;
      const { message = 'Urgent: Please check your app', level = 'warning' } = req.body;

      socketManager.sendVibrationAlert(driverId, message, level as 'info' | 'warning' | 'critical');
      
      res.status(200).json({
        success: true,
        message: `Vibration alert sent to driver ${driverId}`,
      });
    } catch (error: any) {
      logger.error(`Error sending vibration alert: ${error.message}`);
      res.status(500).json({ success: false, error: error.message });
    }
  };

  public simulateSos = async (req: Request, res: Response) => {
    try {
      const {
        driverId = 'DRV-PTR-2026-001',
        driverName = 'Pranav (Field Operator)',
        reason = 'Manual SOS Panic Triggered by Operator',
        latitude = 12.7749,
        longitude = 75.2023,
      } = req.body;

      const payload = {
        id: `SOS-${Date.now()}`,
        alertType: 'SOS',
        driverId,
        driverName,
        phone: '+91 94812 55667',
        vehiclePlate: 'KA-19-PT-2026',
        reason,
        severity: 'CRITICAL',
        latitude,
        longitude,
        speed: 42.5,
        status: 'emergency',
        region: 'Puttur',
        regionId: 'puttur_taluk',
        timestamp: new Date().toISOString(),
      };

      const io = socketManager.getIO();
      io?.emit('sos_alert', payload);
      io?.emit('driver_sos_alert', payload);
      io?.to('dashboards').emit('sos_alert', payload);

      logger.warn(`🚨 [TEST SIMULATION] SOS Alert broadcasted for ${driverName}`);
      res.status(200).json({ success: true, message: 'Simulated SOS alert emitted', payload });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  };

  public simulateNearestDriver = async (req: Request, res: Response) => {
    try {
      const {
        targetDriverId = 'DRV-PTR-2026-001',
        nearbyDriverName = 'Rajesh Kumar',
        nearbyVehiclePlate = 'KA-19-MB-4412',
        distanceMeters = 340,
        isAhead = true,
      } = req.body;

      const io = socketManager.getIO();

      // Emit proximity alert to mobile drivers
      io?.emit('v2v_proximity_message', {
        driverId: targetDriverId,
        partnerDriverId: 'DRV-SIM-002',
        partnerDriverName: nearbyDriverName,
        partnerVehiclePlate: nearbyVehiclePlate,
        distanceMeters,
        isAhead,
        speed: 48.0,
        message: `${nearbyDriverName} (${nearbyVehiclePlate}) is ${distanceMeters}m ${isAhead ? 'ahead of you ↗' : 'behind you ↘'}. Cooperative mesh active.`,
        timestamp: new Date().toISOString(),
      });

      // Emit fleet same direction summary for dashboard radar
      io?.emit('fleet_same_direction_summary', {
        count: 1,
        pairs: [
          {
            driver1: targetDriverId,
            driver2: 'DRV-SIM-002',
            distanceMeters,
            isAhead,
            partnerDriverName: nearbyDriverName,
            partnerVehiclePlate: nearbyVehiclePlate,
            speed: 48.0,
          }
        ],
        timestamp: new Date().toISOString(),
      });

      logger.info(`📡 [TEST SIMULATION] 500m V2V Proximity Alert broadcasted (${distanceMeters}m ${isAhead ? 'AHEAD' : 'BEHIND'})`);
      res.status(200).json({ success: true, message: 'Simulated V2V proximity emitted', distanceMeters, isAhead });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  };

  public simulateCrossDelivery = async (_req: Request, res: Response) => {
    try {
      const io = socketManager.getIO();
      const handoverData = {
        handoverId: `CDH-${Date.now()}`,
        troubledDriverId: 'DRV-PTR-2026-001',
        troubledDriverName: 'Pranav (Field Operator)',
        troubledDriverSplit: 30, // 30% payout
        relayDriverSplit: 70,    // 70% payout
        orderId: 'ORD-EXPRESS-992',
        dropAddress: 'KSRTC Bus Stand Road, Near City Center, Puttur',
        pickupAddress: 'Puttur Bypass Junction Corridor',
        totalFare: 100,
        urgency: 'HIGH',
        timestamp: new Date().toISOString(),
      };

      io?.emit('cross_delivery_available', handoverData);

      logger.info(`🤝 [TEST SIMULATION] 30/70 Cross-Delivery Handover broadcasted`);
      res.status(200).json({ success: true, message: 'Simulated 30/70 cross-delivery broadcasted', handoverData });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  };
}

export const alertController = new AlertController();
