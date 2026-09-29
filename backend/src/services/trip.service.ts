import { tripRepository } from '../repositories/trip.repository';
import { driverRepository } from '../repositories/driver.repository';
import { vehicleRepository } from '../repositories/vehicle.repository';
import { calculateHaversineDistance } from '../utils/distance';
import { encodePolyline } from '../utils/polyline';
import { NotFoundError, BadRequestError } from '../utils/app-error';
import { TripStatus, Trip, TripPoint } from '@prisma/client';
import { aiEvaluationQueue } from '../jobs/queue';
import { logger } from '../config/logger';

export class TripService {
  async startTrip(
    driverId: string,
    vehicleId: string,
    organizationId: string,
    deliveryDetails?: {
      deliveryFrom?: string;
      deliveryTo?: string;
      orderItems?: string;
      orderId?: string;
    }
  ): Promise<Trip> {
    const driver = await driverRepository.findById(driverId);
    if (!driver) throw new NotFoundError('Driver profile not found');

    const vehicle = await vehicleRepository.findById(vehicleId);
    if (!vehicle) throw new NotFoundError('Vehicle not found');

    // Confirm that the driver has no current active trips
    const activeTrips = await tripRepository.findMany({
      where: { driverId, status: TripStatus.ONGOING },
    });
    if (activeTrips.length > 0) {
      throw new BadRequestError('Driver is already on an active trip');
    }

    // Set status to ON_TRIP
    await driverRepository.update(driverId, { status: 'ON_TRIP' });

    return tripRepository.create({
      driverId,
      vehicleId,
      organizationId,
      status: TripStatus.ONGOING,
      startTime: new Date(),
      deliveryFrom: deliveryDetails?.deliveryFrom,
      deliveryTo: deliveryDetails?.deliveryTo,
      orderItems: deliveryDetails?.orderItems,
      orderId: deliveryDetails?.orderId,
    });
  }

  async endTrip(tripId: string): Promise<Trip> {
    const trip = await tripRepository.findById(tripId);
    if (!trip) throw new NotFoundError('Trip not found');
    if (trip.status !== TripStatus.ONGOING) {
      throw new BadRequestError('Trip has already been finalized');
    }

    const points = await tripRepository.getTripPoints(tripId);

    let distance = 0;
    let maxSpeed = 0;
    let totalSpeed = 0;
    const coordinates: [number, number][] = [];

    if (points.length > 0) {
      for (let i = 0; i < points.length; i++) {
        coordinates.push([points[i].latitude, points[i].longitude]);
        if (points[i].speed > maxSpeed) {
          maxSpeed = points[i].speed;
        }
        totalSpeed += points[i].speed;

        if (i > 0) {
          const prev = points[i - 1];
          const curr = points[i];
          distance += calculateHaversineDistance(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude
          );
        }
      }
    }

    const endTime = new Date();
    const duration = Math.round(
      (endTime.getTime() - trip.startTime.getTime()) / 1000
    ); // duration in seconds
    const avgSpeed = points.length > 0 ? totalSpeed / points.length : 0;
    const polyline = encodePolyline(coordinates);

    const updatedTrip = await tripRepository.update(tripId, {
      status: TripStatus.COMPLETED,
      endTime,
      distance: Number(distance.toFixed(2)),
      duration,
      avgSpeed: Number(avgSpeed.toFixed(2)),
      maxSpeed: Number(maxSpeed.toFixed(2)),
      polyline,
    });

    // Restore driver status to ACTIVE
    await driverRepository.update(trip.driverId, { status: 'ACTIVE' });

    // Async queue process for safety reviews
    try {
      await aiEvaluationQueue.add('evaluate-trip', { tripId });
      logger.info(`Enqueued trip safety check: ${tripId}`);
    } catch (err) {
      logger.warn('Redis queue unavailable, evaluating trip directly with AI engine:', err);
      try {
        const { aiService } = await import('../ai/ai.service');
        await aiService.evaluateTripSafety(tripId);
      } catch (evalErr) {
        logger.error('Direct trip evaluation error:', evalErr);
      }
    }

    return updatedTrip;
  }

  async recordLocation(
    tripId: string,
    data: {
      latitude: number;
      longitude: number;
      speed: number;
      heading: number;
      altitude?: number;
      timestamp?: string;
    }
  ): Promise<TripPoint> {
    const trip = await tripRepository.findById(tripId);
    if (!trip) throw new NotFoundError('Trip not found');
    if (trip.status !== TripStatus.ONGOING) {
      throw new BadRequestError('Cannot append telemetry to completed trip');
    }

    return tripRepository.addTripPoint({
      tripId,
      latitude: data.latitude,
      longitude: data.longitude,
      speed: data.speed,
      heading: data.heading,
      altitude: data.altitude,
      timestamp: data.timestamp ? new Date(data.timestamp) : new Date(),
    });
  }

  async getTripsList(
    organizationId?: string,
    query: { skip?: number; take?: number; driverId?: string } = {}
  ) {
    const where: any = organizationId ? { organizationId } : {};
    if (query.driverId) {
      where.driverId = query.driverId;
    }
    const skip = Number(query.skip) || 0;
    const take = Number(query.take) || 50;

    const trips = await tripRepository.findMany({
      skip,
      take,
      where,
      orderBy: { startTime: 'desc' },
    });
    const count = await tripRepository.count(where);

    return { trips, count };
  }
}
export const tripService = new TripService();
