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
}

export const alertController = new AlertController();
