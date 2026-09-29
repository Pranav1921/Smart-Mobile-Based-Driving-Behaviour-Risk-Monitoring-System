import { Request, Response, NextFunction } from 'express';
import { driverService } from '../services/driver.service';
import { ForbiddenError } from '../utils/app-error';
import { prisma } from '../database/client';

export class DriverController {
  async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError(
          'Access Denied: Drivers are isolated by Organization'
        );
      }

      res.status(200).json({
        status: 'success',
        data: driver,
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const updated = await driverService.updateProfile(id, req.body);
      res.status(200).json({
        status: 'success',
        message: 'Driver profile updated successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async assignVehicle(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { vehicleId } = req.body;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const assignment = await driverService.assignVehicle(id, vehicleId);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle assignment completed successfully',
        data: assignment,
      });
    } catch (error) {
      next(error);
    }
  }

  async unassignVehicle(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      await driverService.unassignVehicle(id);
      res.status(200).json({
        status: 'success',
        message: 'Vehicle unassigned successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  async getScoresTrend(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      const trend = await driverService.getScoresTrend(id);
      res.status(200).json({
        status: 'success',
        data: trend,
      });
    } catch (error) {
      next(error);
    }
  }

  async getList(req: Request, res: Response, next: NextFunction) {
    try {
      const orgId = (req.user?.organizationId || (req.query.organizationId as string)) || undefined;
      const queryZone = req.query.zone !== undefined ? String(req.query.zone).trim() : undefined;
      let zone: string | undefined = undefined;
      if (queryZone && queryZone.toLowerCase() !== 'all' && queryZone !== '') {
        zone = queryZone;
      }

      const skip = Number(req.query.skip) || 0;
      const take = Number(req.query.take) || 50;

      const result = await driverService.getDriversList(orgId, zone, skip, take);

      // Inject live telemetry from SocketManager memory if available
      const { socketManager } = await import('../sockets/socket.manager');
      const liveData = socketManager.getLiveDrivers();

      const enrichedDrivers = (result.drivers as any[]).map(d => {
        const driverCodeBadge = (d.badges || []).find((b: string) => b.startsWith('driver_code:'))?.replace('driver_code:', '');
        const fullName = d.user ? `${d.user.firstName || ''} ${d.user.lastName || ''}`.trim().toLowerCase() : '';
        const userEmail = d.user?.email ? d.user.email.toLowerCase().trim() : '';

        const live = liveData.find(l => {
          const lId = (l.driverId || '').toLowerCase().trim();
          const lName = (l.name || l.driverName || '').toLowerCase().trim();
          return (
            lId === d.id.toLowerCase() ||
            lId === d.userId.toLowerCase() ||
            (driverCodeBadge && lId === driverCodeBadge.toLowerCase()) ||
            (d.licenseNumber && lId === d.licenseNumber.toLowerCase()) ||
            (userEmail && lId === userEmail) ||
            (fullName && lName && (fullName === lName || fullName.includes(lName) || lName.includes(fullName)))
          );
        });

        if (live) {
          return {
            ...d,
            status: live.status, // Preserve live status (safe, warning, emergency, etc.)
            safetyScore: live.safetyScore ?? d.safetyScore,
            speed: live.speed,
            latitude: live.latitude,
            longitude: live.longitude,
            lastSeen: live.lastSeen,
            isOnline: true
          };
        }
        return d;
      });

      res.status(200).json({
        status: 'success',
        data: enrichedDrivers,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteDriver(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const driver = await driverService.getDriverProfile(id);

      if (
        req.user?.role !== 'SUPER_ADMIN' &&
        driver.user.organizationId !== req.user?.organizationId
      ) {
        throw new ForbiddenError('Access Denied');
      }

      await driverService.deleteDriver(id);

      // Purge from socket live memory
      const { socketManager } = await import('../sockets/socket.manager');
      socketManager.removeDriver(id);

      res.status(200).json({
        status: 'success',
        message: 'Driver removed from database and registry successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  async getPendingApplications(req: Request, res: Response, next: NextFunction) {
    try {
      const queryZone = req.query.zone !== undefined ? String(req.query.zone).trim() : undefined;
      let zone: string | undefined = undefined;
      
      // Only filter by zone if explicitly requested and not 'all'
      if (queryZone && queryZone.toLowerCase() !== 'all' && queryZone !== '') {
        zone = queryZone;
      }

      const pending = await driverService.getPendingApplications(zone);
      res.status(200).json({
        status: 'success',
        data: pending,
        count: pending.length,
      });
    } catch (error) {
      next(error);
    }
  }

  async verifyDrivingLicense(req: Request, res: Response, next: NextFunction) {
    try {
      const { licenseNumber } = req.body;
      if (!licenseNumber) {
        res.status(400).json({ status: 'error', message: 'License number is required' });
        return;
      }
      const verification = await driverService.verifyDrivingLicense(licenseNumber);
      res.status(200).json({
        status: 'success',
        data: verification,
      });
    } catch (error) {
      next(error);
    }
  }

  async approveApplication(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await driverService.approveDriverApplication(id);
      res.status(200).json({
        status: 'success',
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async rejectApplication(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { reason } = req.body;
      const result = await driverService.rejectDriverApplication(id, reason);
      res.status(200).json({
        status: 'success',
        message: result.message,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getLeaderboard(req: Request, res: Response, next: NextFunction) {
    try {
      const region = req.query.region ? String(req.query.region) : 'Puttur Taluk';
      const drivers = await prisma.driver.findMany({
        where: {
          status: { in: ['ACTIVE', 'active', 'ON_TRIP'] }
        },
        include: {
          user: true,
          trips: true,
        },
        orderBy: { safetyScore: 'desc' },
        take: 20,
      });

      const leaderboard = drivers.map((d, index) => {
        const name = d.user ? `${d.user.firstName || ''} ${d.user.lastName || ''}`.trim() : 'Operator';
        const tripsCount = d.trips?.length || Math.floor(12 + index * 3);
        const distanceKm = (d.trips?.reduce((acc: number, t: any) => acc + (t.distanceKm || 0), 0) || 0) + (85 + index * 20);
        const co2SavedKg = Math.round((distanceKm * 0.12 * ((d.safetyScore || 90) / 100)) * 10) / 10;
        const ecoIndex = Math.min(100, Math.round(((d.safetyScore || 90) * 0.6) + 38));

        return {
          rank: index + 1,
          driverId: d.id,
          name: name || `Agent ${index + 1}`,
          zone: d.user?.zone || 'Puttur Taluk',
          safetyScore: Math.round(d.safetyScore || 95),
          riskScore: Math.round(d.riskScore || 5),
          xp: d.xp || (1200 - index * 60),
          level: d.level || Math.floor((d.xp || 1200) / 1000) + 1,
          streak: d.streak || (7 - Math.min(index, 6)),
          trips: tripsCount,
          distanceKm,
          co2SavedKg,
          ecoIndex,
          badges: d.badges || ['smooth_operator', 'speed_sentinel'],
        };
      });

      res.status(200).json({
        status: 'success',
        region,
        count: leaderboard.length,
        data: leaderboard,
      });
    } catch (error) {
      next(error);
    }
  }
}
export const driverController = new DriverController();
