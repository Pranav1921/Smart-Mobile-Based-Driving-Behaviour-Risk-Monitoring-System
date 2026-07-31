import { driverRepository } from '../repositories/driver.repository';
import { tripRepository } from '../repositories/trip.repository';
import { EventType } from '@prisma/client';
import { logger } from '../config/logger';

export interface AISafetyReport {
  safetyScore: number;
  riskScore: number;
  behaviorClassification: 'CONSERVATIVE' | 'BALANCED' | 'AGGRESSIVE';
  recommendations: string[];
  xpEarned?: number;
  badgesEarned?: string[];
}

export class AIService {
  /**
   * Analyzes telemetry history of a completed trip to recalculate safety and risk ratings.
   */
  async evaluateTripSafety(tripId: string): Promise<AISafetyReport> {
    const trip = await tripRepository.findById(tripId);
    if (!trip) {
      throw new Error(`Trip safety assessment failed: Trip ID ${tripId} not found`);
    }

    const points = trip.tripPoints || [];
    const events = trip.events || [];

    const payload = {
      trip_id: tripId,
      points: points.map((p: any) => ({
        latitude: p.latitude,
        longitude: p.longitude,
        speed: p.speed,
        heading: p.heading,
        altitude: p.altitude,
        timestamp: p.timestamp instanceof Date ? p.timestamp.toISOString() : new Date(p.timestamp).toISOString(),
      })),
      events: events.map((e: any) => ({
        eventType: e.eventType,
        severity: e.severity,
        timestamp: e.timestamp instanceof Date ? e.timestamp.toISOString() : new Date(e.timestamp).toISOString(),
        sensor_values: e.sensorValues
      }))
    };

    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:5000';
    logger.info(`Forwarding telemetry details to FastAPI AI Engine: ${aiServiceUrl}/api/v1/ai/evaluate-trip`);
    
    const response = await fetch(`${aiServiceUrl}/api/v1/ai/evaluate-trip`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`FastAPI AI Service evaluation failed with status ${response.status}: ${response.statusText}`);
    }

    const report = (await response.json()) as AISafetyReport;

    const driverId = trip.driverId;
    const currentDriver = await driverRepository.findById(driverId);
    if (currentDriver) {
      const nextSafety = Math.round(
        currentDriver.safetyScore * 0.8 + report.safetyScore * 0.2
      );
      const nextRisk = Math.round(
        currentDriver.riskScore * 0.8 + report.riskScore * 0.2
      );

      // Accumulate XP, Levels, Streaks, and Achievements
      const nextXp = (currentDriver as any).xp + (report.xpEarned || 0);
      const nextLevel = Math.floor(nextXp / 1000) + 1;
      const currentStreak = (currentDriver as any).streak;
      const nextStreak = report.safetyScore > 85 ? currentStreak + 1 : 0;
      
      const currentBadges = (currentDriver as any).badges || [];
      const newBadges = report.badgesEarned || [];
      const uniqueBadges = Array.from(new Set([...currentBadges, ...newBadges]));

      await driverRepository.update(driverId, {
        safetyScore: nextSafety,
        riskScore: nextRisk,
        xp: nextXp,
        level: nextLevel,
        streak: nextStreak,
        badges: uniqueBadges
      } as any);

      await driverRepository.recordScore(
        driverId,
        nextSafety,
        nextRisk,
        new Date()
      );
    }

    return report;
  }

  /**
   * Generates crash summary from sensor values.
   */
  async generateCrashSummary(
    crashReportId: string,
    sensorValues: any
  ): Promise<{ summary: string; crashProbability: number }> {
    logger.debug(`Generating AI crash report details for incident ${crashReportId}`);

    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:5000';
    const response = await fetch(`${aiServiceUrl}/api/v1/ai/generate-crash-summary`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        crash_report_id: crashReportId,
        sensor_values: sensorValues
      }),
    });

    if (!response.ok) {
      throw new Error(`FastAPI AI Service crash analysis failed with status ${response.status}: ${response.statusText}`);
    }

    return (await response.json()) as { summary: string; crashProbability: number };
  }
}
export const aiService = new AIService();
