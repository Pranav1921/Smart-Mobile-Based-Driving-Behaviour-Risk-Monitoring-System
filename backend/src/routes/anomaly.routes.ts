import { Router, Request, Response } from 'express';
import { prisma } from '../database/client';

const router = Router();

// Haversine distance in meters
function getDistanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const clampedA = Math.min(1.0, Math.max(0.0, a));
  const c = 2 * Math.atan2(Math.sqrt(clampedA), Math.sqrt(1.0 - clampedA));

  return R * c;
}

/**
 * GET /api/v1/anomalies
 * Retrieve all road anomalies (potholes, bumps) for fleet map overlay
 */
router.get('/', async (_req: Request, res: Response) => {
  try {
    const anomalies = await prisma.roadAnomaly.findMany({
      orderBy: { detectionCount: 'desc' },
      take: 100,
    });
    return res.json({ success: true, count: anomalies.length, data: anomalies });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/v1/anomalies
 * Ingest or cluster a new road anomaly event
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { latitude, longitude, zShockG, roadName, anomalyType } = req.body;
    if (latitude == null || longitude == null) {
      return res.status(400).json({ success: false, error: 'latitude and longitude are required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const shock = parseFloat(zShockG || '2.0');

    // Spatial clustering: look for existing anomaly within 25 meters
    const recent = await prisma.roadAnomaly.findMany({
      where: {
        latitude: { gte: lat - 0.0005, lte: lat + 0.0005 },
        longitude: { gte: lng - 0.0005, lte: lng + 0.0005 },
      },
    });

    let matched = recent.find((r) => getDistanceMeters(lat, lng, r.latitude, r.longitude) <= 25.0);

    if (matched) {
      const updated = await prisma.roadAnomaly.update({
        where: { id: matched.id },
        data: {
          detectionCount: { increment: 1 },
          lastDetected: new Date(),
          zShockG: Math.max(matched.zShockG, shock),
        },
      });
      return res.json({ success: true, message: 'Anomaly clustered to existing node', data: updated });
    }

    const created = await prisma.roadAnomaly.create({
      data: {
        latitude: lat,
        longitude: lng,
        zShockG: shock,
        anomalyType: anomalyType || 'POTENTIAL_POTHOLE',
        roadName: roadName || 'Transit Corridor',
        detectionCount: 1,
      },
    });

    return res.status(201).json({ success: true, message: 'New road anomaly pinned', data: created });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * GET /api/v1/anomalies/hotspots
 * Retrieve traffic hazard hotspots (multi-driver cluster with 75% score discount)
 */
router.get('/hotspots', async (_req: Request, res: Response) => {
  try {
    const hotspots = await prisma.riskHotspot.findMany({
      orderBy: { incidentCount: 'desc' },
      take: 50,
    });
    return res.json({ success: true, count: hotspots.length, data: hotspots });
  } catch (error: any) {
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * POST /api/v1/anomalies/evidence
 * Store high-frequency (-5s to +5s) telemetry evidence buffer for a critical driving event
 */
router.post('/evidence', async (req: Request, res: Response) => {
  try {
    const { eventId, windowStart, windowEnd, sampleRateHz, sensorSeries } = req.body;
    const evidence = await prisma.eventEvidence.create({
      data: {
        eventId: eventId || null,
        windowStart: windowStart ? new Date(windowStart) : new Date(Date.now() - 5000),
        windowEnd: windowEnd ? new Date(windowEnd) : new Date(Date.now() + 5000),
        sampleRateHz: sampleRateHz || 20,
        sensorSeries: sensorSeries || [],
      },
    });

    res.status(201).json({ success: true, message: 'Event evidence window stored', data: evidence });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
