import { Server, Socket } from 'socket.io';
import http from 'http';
import jwt from 'jsonwebtoken';
import { logger } from '../config/logger';
import { TokenPayload } from '../services/auth.service';

const ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ||
  'super-secret-access-key-smartdrive-ai-2026';

// ─────────────────────────────────────────────────────────────────────────────
// In-memory store so the system works even without a DB (lite/demo mode)
// ─────────────────────────────────────────────────────────────────────────────
interface LiveDriver {
  id?: string;
  driverId: string;
  name: string;
  driverName?: string;
  organizationId: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  status: 'safe' | 'warning' | 'emergency' | 'idle' | 'offline';
  lastSeen: string;
  isOnline?: boolean;
  safetyScore?: number;
  regionId?: string;
  region?: string;
  accelX?: number;
  accelY?: number;
  accelZ?: number;
  gyroX?: number;
  gyroY?: number;
  gyroZ?: number;
  magX?: number;
  magY?: number;
  magZ?: number;
  vibrationRate?: number;
  orderItems?: string;
  avatar?: string;
  points?: number;
  earnings?: number;
  trips?: number;
  distanceToday?: number;
  harshBrakingCount?: number;
  overspeedCount?: number;
  sharpTurnCount?: number;
  isDeadZone?: boolean;
  phone?: string;
  vehiclePlate?: string;
  alertType?: string;
  sosReason?: string;
}

export interface LivePothole {
  id: string;
  latitude: number;
  longitude: number;
  intensity: number; // 0.0 - 1.0
  vibrationRate?: number;
  driverId?: string;
  driverName?: string;
  roadName?: string;
  regionId?: string;
  timestamp: string;
}

export interface LiveGeofence {
  id: string;
  name: string;
  type: 'school' | 'market' | 'hospital' | 'curve' | 'construction' | 'custom';
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
  speedLimitKph: number;
  color?: string;
  regionId?: string;
  createdAt: string;
}

const liveDrivers = new Map<string, LiveDriver>();
const livePotholes: LivePothole[] = [];
const liveGeofences: LiveGeofence[] = [
  {
    id: 'geo-school-philomena',
    name: 'St. Philomena Educational Campus Zone',
    type: 'school',
    centerLat: 12.7742,
    centerLng: 75.2018,
    radiusMeters: 280,
    speedLimitKph: 25,
    color: '#38bdf8',
    regionId: 'puttur_taluk',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'geo-market-busstand',
    name: 'Puttur Bus Stand & Market Sector',
    type: 'market',
    centerLat: 12.7705,
    centerLng: 75.2045,
    radiusMeters: 220,
    speedLimitKph: 20,
    color: '#f59e0b',
    regionId: 'puttur_taluk',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'geo-curve-bypass',
    name: 'Highway Bypass Blind Hairpin Corridor',
    type: 'curve',
    centerLat: 12.7810,
    centerLng: 75.2120,
    radiusMeters: 350,
    speedLimitKph: 30,
    color: '#eab308',
    regionId: 'puttur_taluk',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'geo-hospital-adarsha',
    name: 'Adarsha Hospital Silence Sanctuary',
    type: 'hospital',
    centerLat: 12.7780,
    centerLng: 75.2060,
    radiusMeters: 200,
    speedLimitKph: 25,
    color: '#06b6d4',
    regionId: 'puttur_taluk',
    createdAt: new Date().toISOString(),
  },
];

export class SocketManager {
  private io: Server | null = null;
  private userSockets: Map<string, string[]> = new Map();

  initialize(server: http.Server) {
    this.io = new Server(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
      pingTimeout: 30000,
      pingInterval: 10000,
      allowEIO3: true, // Enable compatibility with older Socket.IO clients (like Flutter socket_io_client 1.x/2.x)
    });

    // ── Cooperative V2V Proximity Engine (Evaluates approaching fleet vehicles every 3s) ──
    const v2vCooldowns = new Map<string, number>();

    setInterval(() => {
      if (!this.io) return;
      const activeDrivers = Array.from(liveDrivers.values()).filter(d => 
        d.isOnline && 
        d.status !== 'offline' && 
        d.driverId !== 'agent-x' && 
        d.driverId !== 'mobile-driver'
      );
      if (activeDrivers.length < 2) return;

      const now = Date.now();

      for (let i = 0; i < activeDrivers.length; i++) {
        for (let j = i + 1; j < activeDrivers.length; j++) {
          const d1 = activeDrivers[i];
          const d2 = activeDrivers[j];

          const id1 = d1.id || d1.driverId;
          const id2 = d2.id || d2.driverId;

          // Skip if same vehicle / driver / phantom
          if (id1 === id2 || (d1.name && d2.name && d1.name.toLowerCase().trim() === d2.name.toLowerCase().trim())) {
            continue;
          }
          if (id1 === 'agent-x' || id2 === 'agent-x' || id1 === 'mobile-driver' || id2 === 'mobile-driver') {
            continue;
          }

          const distKm = Math.sqrt(
            Math.pow((d1.latitude - d2.latitude) * 111, 2) +
            Math.pow((d1.longitude - d2.longitude) * 111 * Math.cos(d1.latitude * Math.PI / 180), 2)
          );

          // Only alert when two real mobiles get a close connection within 500 meters (0.50 km)
          if (distKm <= 0.50) {
            const pairKey = [id1, id2].sort().join(':');
            if (v2vCooldowns.has(pairKey) && now - v2vCooldowns.get(pairKey)! < 60000) {
              continue; // 60-second cooldown per vehicle pair to prevent repetitive alert spam
            }
            v2vCooldowns.set(pairKey, now);

            const warningPayload = {
              v2vActive: true,
              distanceMeters: Math.round(distKm * 1000),
              curveName: 'Approaching Vehicle Proximity Corridor',
              driver1: { id: id1, name: d1.name, lat: d1.latitude, lng: d1.longitude, speed: d1.speed, heading: d1.heading },
              driver2: { id: id2, name: d2.name, lat: d2.latitude, lng: d2.longitude, speed: d2.speed, heading: d2.heading },
              timestamp: new Date().toISOString(),
            };

            // Notify both drivers via their personal rooms
            this.io.to(`user:${id1}`).to(`user:${d1.driverId}`).emit('blind_curve_warning', {
              ...warningPayload,
              oncomingDriver: d2.name,
              otherDriverName: d2.name,
            });
            this.io.to(`user:${id2}`).to(`user:${d2.driverId}`).emit('blind_curve_warning', {
              ...warningPayload,
              oncomingDriver: d1.name,
              otherDriverName: d1.name,
            });

            // Broadcast V2V cooperative vector ray to admin dashboards for LiveMap
            this.io.to('dashboards').emit('v2v_proximity_alert', warningPayload);
          }
        }
      }
    }, 3000);

    // ── JWT Auth middleware ───────────────────────────────────────────────────
    this.io.use((socket: Socket, next) => {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.split(' ')[1];

      // Allow unauthenticated dashboard connections with a special key for demo
      if (!token) {
        socket.data.user = {
          userId: socket.handshake.auth?.role === 'dashboard' ? 'dashboard' : 'mobile-driver',
          role: socket.handshake.auth?.role === 'dashboard' ? 'ADMIN' : 'DRIVER',
          organizationId: 'demo-org',
        };
        return next();
      }

      try {
        const decoded = jwt.verify(token, ACCESS_SECRET) as TokenPayload;
        socket.data.user = decoded;
        next();
      } catch (err) {
        try {
          const demo = JSON.parse(Buffer.from(token.split('.')[1] ?? '', 'base64').toString());
          if (demo?.userId && demo?.role) {
            socket.data.user = demo;
            return next();
          }
        } catch (_) {}

        // Fallback for demo: accept driver connection gracefully
        socket.data.user = {
          userId: 'mobile-driver',
          role: 'DRIVER',
          organizationId: 'demo-org',
        };
        next();
      }
    });

    this.io.on('connection', (socket: Socket) => {
      const user = socket.data.user as TokenPayload;
      const { userId, organizationId, role } = user;

      logger.info(
        `Socket connected: User ${userId} (Role: ${role}) → Socket ${socket.id}`
      );

      // Track all socket IDs for this user
      const currentSockets = this.userSockets.get(userId) || [];
      this.userSockets.set(userId, [...currentSockets, socket.id]);

      // Join personal room + org room
      socket.join(`user:${userId}`);
      if (organizationId) {
        socket.join(`org:${organizationId}`);
      }
      // All admin/dashboard connections also join a shared 'dashboards' room
      // so they receive updates from drivers of ANY organisation (demo mode)
      const isAdmin = role === 'SUPER_ADMIN' || role === 'FLEET_ADMIN' || role === 'FLEET_MANAGER' || (role as any) === 'ADMIN';
      if (isAdmin || socket.handshake.auth?.role === 'dashboard') {
        socket.join('dashboards');
      }

      // ── Dashboard: on connect, send current live driver & potholes snapshot ─────────
      if (isAdmin || socket.handshake.auth?.role === 'dashboard') {
        // Send cleaned, deduplicated live drivers snapshot
        const snapshot = this.getLiveDrivers();
        socket.emit('live_snapshot', snapshot);
        socket.emit('potholes_snapshot', livePotholes);
        socket.emit('geofences_sync', liveGeofences);
        logger.debug(`Sent snapshot of ${snapshot.length} live drivers, ${livePotholes.length} road hazards, and ${liveGeofences.length} geofences to dashboard`);
      } else {
        // Driver connection: send road hazard snapshot and active geofences
        socket.emit('potholes_snapshot', livePotholes);
        socket.emit('geofences_sync', liveGeofences);
      }

      // ── DRIVER: GPS telemetry stream ──────────────────────────────────────
      socket.on(
        'gps_update',
        async (data: {
          tripId?: string;
          driverName?: string;
          deliveryFrom?: string;
          deliveryTo?: string;
          orderItems?: string;
          latitude: number;
          longitude: number;
          speed: number;
          heading: number;
          altitude?: number;
          timestamp?: string;
        }) => {
          if (data.latitude === undefined || data.longitude === undefined) {
            socket.emit('gps_error', { message: 'Invalid coordinate values' });
            return;
          }

          // Determine effective user ID (allow override for demo/offline drivers)
          const effectiveUserId = (userId === 'mobile-driver' && (data as any).driverId) 
            ? (data as any).driverId 
            : ((data as any).driverId || userId);

          // Discard phantom dummy updates
          if (!effectiveUserId || effectiveUserId === 'agent-x' || effectiveUserId === 'mobile-driver') {
            return;
          }

          // CLEANUP: Purge any lingering phantom entries
          if (liveDrivers.has('agent-x')) {
            liveDrivers.delete('agent-x');
            this.io?.to('dashboards').emit('driver_location_update', {
              driverId: 'agent-x',
              status: 'offline',
              timestamp: new Date().toISOString()
            });
          }
          if (liveDrivers.has('mobile-driver')) {
            liveDrivers.delete('mobile-driver');
            this.io?.to('dashboards').emit('driver_location_update', {
              driverId: 'mobile-driver',
              status: 'offline',
              timestamp: new Date().toISOString()
            });
          }

          // Store it back in socket data for future reference (like disconnect)
          if (userId === 'mobile-driver' && (data as any).driverId) {
             const newId = (data as any).driverId;
             if (socket.data.user.userId !== newId) {
                logger.info(`Mapping socket ${socket.id} from mobile-driver to specific ID: ${newId}`);
                socket.leave(`user:mobile-driver`);
                socket.leave(`user:agent-x`);
                socket.join(`user:${newId}`);
                socket.data.user.userId = newId;
             }
          }

          // Determine driver status based on speed, but preserve emergency status
          const wasOffline = !liveDrivers.has(effectiveUserId) || !liveDrivers.get(effectiveUserId)?.isOnline;
          const existing = liveDrivers.get(effectiveUserId);
          let status: LiveDriver['status'] = (existing?.status === 'emergency') ? 'emergency' : 'safe';

          if (status !== 'emergency') {
            if (data.speed < 1.0) status = 'idle';
            else if (data.speed > 80) status = 'warning';
          }

          const driverName = data.driverName ?? user.email ?? effectiveUserId;

          // CLEANUP DUPLICATES: Purge any different-cased or old duplicate keys for this same driver
          const lowerId = effectiveUserId.toLowerCase();
          const cleanDriverName = driverName.toLowerCase().trim();
          for (const [key, existingDriver] of liveDrivers.entries()) {
            if (key !== effectiveUserId) {
              const existingName = (existingDriver.driverName || existingDriver.name || '').toLowerCase().trim();
              if (key.toLowerCase() === lowerId || (cleanDriverName && existingName === cleanDriverName)) {
                liveDrivers.delete(key);
                this.io?.to('dashboards').emit('driver_removed', { driverId: key });
              }
            }
          }
          const locationPayload = {
            driverId: effectiveUserId,
            driverName: driverName,
            name: driverName,
            organizationId: organizationId ?? 'demo-org',
            latitude: data.latitude,
            longitude: data.longitude,
            speed: data.speed,
            heading: data.heading ?? 0,
            status,
            safetyScore: (data as any).safetyScore ?? 100,
            regionId: (data as any).regionId || (data as any).region || (socket.data.user as any)?.zone || existing?.regionId || 'puttur_taluk',
            region: (data as any).region || (data as any).regionId || (socket.data.user as any)?.zone || existing?.region || 'puttur_taluk',
            accelX: (data as any).accelX,
            accelY: (data as any).accelY,
            accelZ: (data as any).accelZ,
            gyroX: (data as any).gyroX,
            gyroY: (data as any).gyroY,
            gyroZ: (data as any).gyroZ,
            magX: (data as any).magX,
            magY: (data as any).magY,
            magZ: (data as any).magZ,
            vibrationRate: (data as any).vibrationRate,
            deliveryFrom: data.deliveryFrom,
            deliveryTo: data.deliveryTo,
            orderItems: data.orderItems,
            destLat: (data as any).destLat,
            destLng: (data as any).destLng,
            points: (data as any).points ?? existing?.points ?? 0,
            earnings: (data as any).earnings ?? existing?.earnings ?? 0,
            trips: (data as any).trips ?? existing?.trips ?? 0,
            distanceToday: (data as any).distanceToday ?? existing?.distanceToday ?? 0,
            harshBrakingCount: (data as any).harshBrakingCount ?? existing?.harshBrakingCount ?? 0,
            overspeedCount: (data as any).overspeedCount ?? existing?.overspeedCount ?? 0,
            sharpTurnCount: (data as any).sharpTurnCount ?? existing?.sharpTurnCount ?? 0,
            email: (data as any).email || user?.email || existing?.email || '',
            phone: (data as any).phone || (data as any).phoneNumber || (user as any)?.phoneNumber || existing?.phone || '',
            emergencyContactName: (data as any).emergencyContactName || existing?.emergencyContactName || '',
            emergencyContactPhone: (data as any).emergencyContactPhone || existing?.emergencyContactPhone || '',
            familyRelationship: (data as any).familyRelationship || existing?.familyRelationship || 'Parent / Guardian',
            timestamp: data.timestamp ?? new Date().toISOString(),
          };

          // Update in-memory driver state
          liveDrivers.set(effectiveUserId, {
            ...locationPayload,
            isOnline: true,
            lastSeen: locationPayload.timestamp,
          });

          // Broadcast driver_online to org room AND to all dashboard connections
          if (wasOffline) {
            const onlinePayload = {
              driverId: effectiveUserId,
              driverName: driverName,
              regionId: (data as any).regionId,
              region: (data as any).region ?? (data as any).regionId,
              timestamp: new Date().toISOString(),
            };
            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            this.io?.to(orgRoom).to('dashboards').emit('driver_online', onlinePayload);
            logger.info(`Driver ${effectiveUserId} (${driverName}) just came ONLINE in region ${onlinePayload.regionId || 'default'}`);
          }

          // Broadcast to ALL dashboards room specifically (Ensures admin visibility in demo)
          this.io?.to('dashboards').emit('driver_location_update', locationPayload);

          // Also broadcast to the specific org room
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).emit('driver_location_update', locationPayload);

          // Broadcase Pothole Detection to ALL DRIVERS if the special flag is present
          if (data.orderItems === "POTHOLE_DETECTED") {
             logger.info(`🕳️ POTHOLE reported by driver ${effectiveUserId} at [${data.latitude}, ${data.longitude}]`);
             socket.broadcast.emit('pothole_detected', {
                lat: data.latitude,
                lng: data.longitude,
                intensity: (data as any).vibrationRate || 1.0,
                timestamp: new Date().toISOString()
             });
          }

          // Update database with latest coordinates for persistence
          try {
            const { prisma } = await import('../database/client');
            // We search for the driver by userId or driverId
            // Validate that we are passing valid UUIDs to avoid Prisma/Postgres errors
            const isUuid = (id: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);

            const queryConditions: any[] = [];
            if (isUuid(effectiveUserId)) {
              queryConditions.push({ id: effectiveUserId }, { userId: effectiveUserId });
            }
            if (effectiveUserId && !isUuid(effectiveUserId) && effectiveUserId !== 'mobile-driver') {
              queryConditions.push({ licenseNumber: effectiveUserId });
            }
            if (data.driverName && data.driverName.trim().length > 2) {
              const firstName = data.driverName.trim().split(' ')[0];
              queryConditions.push({ user: { firstName: { equals: firstName, mode: 'insensitive' } } });
            }

            if (queryConditions.length > 0) {
              const driver = await prisma.driver.findFirst({
                where: { OR: queryConditions }
              });

              if (driver) {
                await prisma.driver.update({
                  where: { id: driver.id },
                  data: {
                    latitude: data.latitude,
                    longitude: data.longitude,
                    lastSeen: data.timestamp ? new Date(data.timestamp) : new Date(),
                    status: (status.toUpperCase() === 'SAFE' || status.toUpperCase() === 'IDLE') ? 'ON_TRIP' : driver.status
                  }
                });
              }
            }
          } catch (dbErr) {
            logger.error(`Failed to persist telemetry to DB: ${dbErr}`);
          }

          // Log real-time telemetry with sensors to terminal for admin verification
          const aX = (data as any).accelX?.toFixed(2) || '0.00';
          const aY = (data as any).accelY?.toFixed(2) || '0.00';
          const aZ = (data as any).accelZ?.toFixed(2) || '0.00';
          const vib = (data as any).vibrationRate?.toFixed(2) || '0.00';

          logger.info(`[TELEMETRY] Driver: ${data.driverName || effectiveUserId} | Speed: ${data.speed?.toFixed(1)} km/h | Vibe: ${vib} G | Accel: [${aX}, ${aY}, ${aZ}] | ID: ${effectiveUserId}`);
          if (data.orderItems) {
            logger.debug(`[DISPATCH] Cargo: ${data.orderItems} | From: ${data.deliveryFrom} | To: ${data.deliveryTo}`);
          }

          // Persist to DB non-blockingly — fail silently in lite mode
          try {
            const { tripService } = await import('../services/trip.service');
            if (data.tripId) {
              await tripService.recordLocation(data.tripId, {
                latitude: data.latitude,
                longitude: data.longitude,
                speed: data.speed,
                heading: data.heading,
                altitude: data.altitude,
                timestamp: data.timestamp,
              });
            }
          } catch (_) {
            // Lite mode: DB unavailable, only relay via socket
          }
        }
      );

      // ── DRIVER: Shift status change (GO LIVE / END LIVE) ─────────────────
      socket.on(
        'shift_status',
        async (data: {
          driverId?: string;
          driverName?: string;
          status: string;
          latitude?: number;
          longitude?: number;
          regionId?: string;
          region?: string;
          timestamp?: string;
        }) => {
          const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : (data.driverId || userId);
          const driverName = data.driverName ?? user.email ?? effectiveUserId;
          const isOnline = data.status !== 'offline';
          const lat = (data.latitude != null && !isNaN(data.latitude) && data.latitude !== 0) ? data.latitude : 12.7749;
          const lng = (data.longitude != null && !isNaN(data.longitude) && data.longitude !== 0) ? data.longitude : 75.2023;

          const locationPayload = {
            driverId: effectiveUserId,
            driverName: driverName,
            name: driverName,
            organizationId: organizationId ?? 'demo-org',
            latitude: lat,
            longitude: lng,
            speed: 0,
            heading: 0,
            status: (isOnline ? 'safe' : 'offline') as LiveDriver['status'],
            safetyScore: 100,
            regionId: data.regionId,
            region: data.region ?? data.regionId,
            timestamp: data.timestamp ?? new Date().toISOString(),
          };

          if (isOnline) {
            liveDrivers.set(effectiveUserId, {
              ...locationPayload,
              isOnline: true,
              lastSeen: locationPayload.timestamp,
            });

            logger.info(`🟢 Driver ${effectiveUserId} (${driverName}) went LIVE (shift online) in region: ${data.regionId || 'default'}`);
            this.io?.to('dashboards').emit('driver_online', locationPayload);
            this.io?.to('dashboards').emit('driver_location_update', locationPayload);
            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            this.io?.to(orgRoom).emit('driver_online', locationPayload);
            this.io?.to(orgRoom).emit('driver_location_update', locationPayload);
          } else {
            if (liveDrivers.has(effectiveUserId)) {
              const prev = liveDrivers.get(effectiveUserId)!;
              prev.isOnline = false;
              prev.status = 'offline';
              liveDrivers.set(effectiveUserId, prev);
            }
            logger.info(`⚪ Driver ${effectiveUserId} (${driverName}) went OFFLINE (shift ended)`);
            this.io?.to('dashboards').emit('driver_location_update', {
              ...locationPayload,
              status: 'offline',
            });
          }
        }
      );

      // ── DRIVER: Crash/Emergency event ────────────────────────────────────
      socket.on(
        'crash_event',
        async (data: {
          tripId?: string;
          driverName?: string;
          latitude: number;
          longitude: number;
          severity?: string;
          speedBefore?: number;
          speedAfter?: number;
          accelX?: number;
          accelY?: number;
          accelZ?: number;
          noMotionSeconds?: number;
        }) => {
          logger.warn(
            `🚨 CRASH EVENT from driver ${userId} (${data.driverName || 'Unknown'}) at [${data.latitude}, ${data.longitude}]`
          );
          logger.warn(`[SENSOR READINGS] AccelX: ${data.accelX} | AccelY: ${data.accelY} | AccelZ: ${data.accelZ} | Impact Speed: ${data.speedBefore} km/h`);
          logger.warn(`[EVIDENCE PREP] Footage (30s prior) & Audio (2min) capture initiated for incident log.`);

          // Determine effective user ID (allow override for demo/offline drivers)
          const effectiveUserId = (userId === 'mobile-driver' && (data as any).driverId) ? (data as any).driverId : userId;

          // Mark driver as emergency in live store
          const existing = liveDrivers.get(effectiveUserId);
          if (existing) {
            existing.status = 'emergency';
            liveDrivers.set(effectiveUserId, existing);
          }

          // Persist crash to DB and get report ID
          let reportId = '';
          try {
            const { crashService } = await import('../services/crash.service');
            const { prisma } = await import('../database/client');

            const isUuid = (id: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);

            const queryConditions: any[] = [];
            if (isUuid(effectiveUserId)) queryConditions.push({ id: effectiveUserId });
            if (isUuid(effectiveUserId)) queryConditions.push({ userId: effectiveUserId });

            if (queryConditions.length > 0) {
              // Find the driver's vehicle and organization
              const driver = await prisma.driver.findFirst({
                where: { OR: queryConditions },
                include: { user: true, vehicleAssignments: { where: { unassignedAt: null } } }
              });

              if (driver) {
                const vehicleId = driver.vehicleAssignments[0]?.vehicleId || '00000000-0000-0000-0000-000000000000';
                const report = await crashService.reportCrash({
                  tripId: data.tripId,
                  driverId: driver.id,
                  vehicleId,
                  organizationId: driver.user.organizationId || organizationId || 'demo-org',
                  latitude: data.latitude,
                  longitude: data.longitude,
                  sensorValues: {
                    speedBefore: data.speedBefore,
                    accelX: data.accelX,
                    accelY: data.accelY,
                    accelZ: data.accelZ,
                  },
                  severity: (data.severity as any) || 'CRITICAL',
                });
                reportId = report.id;
              }
            }
          } catch (dbErr) {
            logger.error(`Failed to persist crash to DB: ${dbErr}`);
          }

          // Broadcast crash alert to entire org dashboard
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).to('dashboards').emit('crash_alert', {
            id: reportId, // Include the DB ID for media uploads
            driverId: effectiveUserId,
            driverName: data.driverName ?? existing?.name ?? effectiveUserId,
            tripId: data.tripId,
            latitude: data.latitude,
            longitude: data.longitude,
            severity: data.severity ?? 'CRITICAL',
            speedBefore: data.speedBefore,
            speedAfter: data.speedAfter,
            accelX: data.accelX,
            accelY: data.accelY,
            accelZ: data.accelZ,
            noMotionSeconds: data.noMotionSeconds,
            timestamp: new Date().toISOString(),
          });

          // Confirm receipt to driver with the report ID
          socket.emit('crash_confirmed', { received: true, reportId });
        }
      );

      // ── DRIVER: Shift Status (GO LIVE / END LIVE) ──────────────────────
      socket.on(
        'shift_status',
        (data: {
          driverId: string;
          driverName?: string;
          status: 'online' | 'offline';
          latitude?: number;
          longitude?: number;
          regionId?: string;
          region?: string;
          timestamp?: string;
        }) => {
          const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
          const driverName = data.driverName ?? user.email ?? effectiveUserId;
          const isOnline = data.status === 'online';
          const regionId = data.regionId || 'puttur_taluk';

          logger.info(`[SHIFT] Driver ${effectiveUserId} (${driverName}) switched shift to: ${data.status} (Region: ${regionId})`);

          if (isOnline) {
            const existing = liveDrivers.get(effectiveUserId);
            const liveEntry: LiveDriver = {
              driverId: effectiveUserId,
              name: driverName,
              organizationId: organizationId ?? 'demo-org',
              latitude: data.latitude ?? existing?.latitude ?? 12.7749,
              longitude: data.longitude ?? existing?.longitude ?? 75.2023,
              speed: existing?.speed ?? 0,
              heading: existing?.heading ?? 0,
              status: 'safe',
              lastSeen: data.timestamp ?? new Date().toISOString(),
              isOnline: true,
              regionId: regionId,
              region: data.region ?? regionId,
              safetyScore: existing?.safetyScore ?? 100,
            };
            // CLEANUP DUPLICATES: Purge any different-cased or old duplicate keys for this same driver
            const lowerId = effectiveUserId.toLowerCase();
            const cleanDriverName = driverName.toLowerCase().trim();
            for (const [key, existingDriver] of liveDrivers.entries()) {
              if (key !== effectiveUserId) {
                const existingName = (existingDriver.driverName || existingDriver.name || '').toLowerCase().trim();
                if (key.toLowerCase() === lowerId || (cleanDriverName && existingName === cleanDriverName)) {
                  liveDrivers.delete(key);
                  this.io?.to('dashboards').emit('driver_removed', { driverId: key });
                }
              }
            }

            liveDrivers.set(effectiveUserId, liveEntry);

            // Broadcast driver_go_live and driver_online to dashboards and org
            const livePayload = {
              driverId: effectiveUserId,
              driverName: driverName,
              name: driverName,
              regionId: regionId,
              region: data.region ?? regionId,
              latitude: liveEntry.latitude,
              longitude: liveEntry.longitude,
              status: 'safe',
              isOnline: true,
              timestamp: new Date().toISOString(),
            };

            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            this.io?.to(orgRoom).to('dashboards').emit('driver_go_live', livePayload);
            this.io?.to(orgRoom).to('dashboards').emit('driver_online', livePayload);
            this.io?.to('dashboards').emit('driver_location_update', livePayload);
          } else {
            const existing = liveDrivers.get(effectiveUserId);
            if (existing) {
              existing.status = 'offline';
              existing.isOnline = false;
              liveDrivers.set(effectiveUserId, existing);
            }
            const offlinePayload = {
              driverId: effectiveUserId,
              driverName: driverName,
              status: 'offline',
              isOnline: false,
              regionId: regionId,
              region: data.region ?? regionId,
              latitude: existing?.latitude ?? 12.7749,
              longitude: existing?.longitude ?? 75.2023,
              timestamp: new Date().toISOString(),
            };
            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            this.io?.to(orgRoom).to('dashboards').emit('driver_offline', offlinePayload);
            this.io?.to('dashboards').emit('driver_location_update', offlinePayload);
          }
        }
      );

      // ── DRIVER: Accept a job assignment ────────────────────────────────
      socket.on('job_accepted', (data: { orderId: string; driverName?: string }) => {
        logger.info(`Driver ${userId} accepted job ${data.orderId}`);
        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).emit('job_response', {
          orderId: data.orderId,
          driverId: userId,
          driverName: data.driverName ?? liveDrivers.get(userId)?.name ?? userId,
          response: 'accepted',
          timestamp: new Date().toISOString(),
        });
      });

      // ── DRIVER: Reject a job assignment ───────────────────────────────
      socket.on('job_rejected', (data: { orderId: string; reason?: string }) => {
        logger.warn(`Driver ${userId} rejected job ${data.orderId}: ${data.reason ?? 'No reason'}`);
        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).emit('job_response', {
          orderId: data.orderId,
          driverId: userId,
          driverName: liveDrivers.get(userId)?.name ?? userId,
          response: 'rejected',
          reason: data.reason,
          timestamp: new Date().toISOString(),
        });
      });

      socket.on('driver_check_ping', (data: { driverId: string, message?: string }) => {
        logger.info(`Admin requested safety ping for driver ${data.driverId}`);
        const pingPayload = {
          driverId: data.driverId,
          message: data.message || 'Safety verification required. Please respond if you are okay.'
        };
        this.io?.to(`user:${data.driverId}`).to('user:mobile-driver').emit('driver_check_ping', pingPayload);
        this.io?.emit('driver_check_ping', pingPayload);
      });

      socket.on('request_live_cam', (data: { driverId: string, active: boolean }) => {
        logger.info(`Admin requested live cam (${data.active}) for driver ${data.driverId}`);
        const camPayload = {
          driverId: data.driverId,
          active: data.active
        };
        this.io?.to(`user:${data.driverId}`).to('user:mobile-driver').emit('request_live_cam', camPayload);
        this.io?.emit('request_live_cam', camPayload);
      });

      // ── ADMIN: Voice / Audio Intercom Broadcast to Drivers ────────────────
      socket.on('admin_voice_broadcast', (data: { message: string; regionId?: string; priority?: string }) => {
        const msg = data.message || 'Fleet Command alert: Drive with extreme caution.';
        logger.info(`📢 [VOICE BROADCAST] Admin dispatched announcement: "${msg}"`);
        const payload = {
          id: `broadcast-${Date.now()}`,
          message: msg,
          priority: data.priority || 'high',
          regionId: data.regionId,
          timestamp: new Date().toISOString(),
        };

        // Emit to all driver rooms, dashboards, and global broadcast channel
        this.io?.to('user:mobile-driver').emit('admin_voice_broadcast', payload);
        this.io?.to('dashboards').emit('admin_voice_broadcast', payload);
        this.io?.emit('admin_voice_broadcast', payload);
        socket.emit('voice_broadcast_confirmed', { success: true, count: liveDrivers.size });
      });

      // ── ADMIN: Create / Update Geofence ────────────────────────────────────
      socket.on('geofence_create', (data: LiveGeofence) => {
        logger.info(`🛡️ [GEOFENCE CREATED] ${data.name} (Speed limit: ${data.speedLimitKph} km/h, Radius: ${data.radiusMeters}m)`);
        const newZone: LiveGeofence = {
          ...data,
          id: data.id || `geo-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
          createdAt: new Date().toISOString(),
        };
        liveGeofences.unshift(newZone);
        this.io?.emit('geofence_updated', { action: 'create', geofence: newZone, allGeofences: liveGeofences });
        this.io?.emit('geofences_sync', liveGeofences);
      });

      // ── ADMIN: Delete Geofence ─────────────────────────────────────────────
      socket.on('geofence_delete', (data: { id: string }) => {
        logger.info(`🛡️ [GEOFENCE DELETED] ${data.id}`);
        const idx = liveGeofences.findIndex(g => g.id === data.id);
        if (idx !== -1) {
          liveGeofences.splice(idx, 1);
        }
        this.io?.emit('geofence_updated', { action: 'delete', geofenceId: data.id, allGeofences: liveGeofences });
        this.io?.emit('geofences_sync', liveGeofences);
      });

      socket.on('resolve_incident', (data: { driverId: string }) => {
        logger.info(`Admin resolved incident for driver ${data.driverId}`);
        let targetKey = data.driverId;
        let existing = liveDrivers.get(targetKey);
        if (!existing) {
          for (const [key, d] of liveDrivers.entries()) {
            if (key === data.driverId || d.driverId === data.driverId || d.name === data.driverId || (d as any).userId === data.driverId) {
              targetKey = key;
              existing = d;
              break;
            }
          }
        }
        if (existing) {
          existing.status = 'safe';
          liveDrivers.set(targetKey, existing);
        }

        const safePayload = {
          driverId: targetKey || data.driverId,
          targetId: data.driverId,
          driverName: existing?.name || (existing as any)?.driverName || data.driverId,
          status: 'safe',
          timestamp: new Date().toISOString()
        };

        // Broadcast update to all dashboards and notify mobile app
        this.io?.to('dashboards').emit('driver_safety_confirmed', safePayload);
        if (existing) {
          this.io?.to('dashboards').emit('driver_location_update', {
            ...existing,
            ...safePayload,
          });
        }
        this.io?.to(`user:${data.driverId}`).to('user:mobile-driver').emit('incident_resolved', {
          driverId: data.driverId,
          message: 'Incident marked resolved by fleet command.'
        });
      });

      // ── DRIVER: Safety Confirmation (Driver tapped 'I AM SAFE' or responded to ping) ──
      socket.on('safety_response', (data: { driverId?: string; driverName?: string; status?: string }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data?.driverId) ? data.driverId : (data?.driverId || userId);
        logger.info(`✅ [SAFETY CONFIRMED] Driver ${effectiveUserId} responded SAFE.`);

        let targetKey = effectiveUserId;
        let existing = liveDrivers.get(targetKey);
        if (!existing) {
          for (const [key, d] of liveDrivers.entries()) {
            if (key === effectiveUserId || d.driverId === effectiveUserId || d.name === effectiveUserId || (d as any).userId === effectiveUserId) {
              targetKey = key;
              existing = d;
              break;
            }
          }
        }

        if (existing) {
          existing.status = 'safe';
          liveDrivers.set(targetKey, existing);
        }

        const payload = {
          driverId: targetKey || effectiveUserId,
          targetId: effectiveUserId,
          driverName: data?.driverName || existing?.name || effectiveUserId,
          status: 'safe',
          regionId: existing?.regionId,
          region: existing?.region,
          timestamp: new Date().toISOString(),
        };

        // Notify all dashboards immediately that driver is confirmed safe!
        this.io?.to('dashboards').emit('driver_safety_confirmed', payload);
        this.io?.to('dashboards').emit('driver_responded', payload);
        this.io?.to('dashboards').emit('driver_location_update', {
          ...(existing || {}),
          ...payload,
        });
      });

      // ── ADMIN: Live Camera Stream Request (Relay to mobile driver) ──────
      socket.on('request_live_cam', (data: { driverId: string; active: boolean }) => {
        logger.info(`[CAMERA] Admin requested live cam for driver ${data.driverId}: active=${data.active}`);
        this.io?.to(`user:${data.driverId}`).to('user:mobile-driver').emit('request_live_cam', data);
        this.io?.emit('request_live_cam', data);
      });

      // ── DRIVER: Live Camera Frame Relay ─────────────────────────────────
      socket.on('live_frame', (data: { driverId: string; frame: string }) => {
        // Relay this frame to all dashboards
        this.io?.to('dashboards').emit('live_frame', data);
        this.io?.emit('live_frame', data);
      });

      // ── ADMIN: Send text message to driver (TTS on mobile) ──────────────
      socket.on('driver_message', (data: { driverId: string; message: string }) => {
        logger.info(`Admin message to driver ${data.driverId}: ${data.message}`);
        const payload = {
          driverId: data.driverId,
          message: data.message,
          timestamp: new Date().toISOString()
        };
        this.io?.to(`user:${data.driverId}`).to('user:mobile-driver').emit('driver_message', payload);
        this.io?.emit('driver_message', payload);
      });

      // ── DRIVER: Duty & Leave Status Update ──────────────────────────────
      socket.on('driver_leave_status', (data: { driverId: string; driverName?: string; isOnLeave: boolean; reason?: string; regionId?: string }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
        const driverName = data.driverName ?? user.email ?? effectiveUserId;
        const status = data.isOnLeave ? 'leave' : 'offline';

        logger.info(`[LEAVE] Driver ${effectiveUserId} (${driverName}) updated leave: ${data.isOnLeave ? 'ON LEAVE' : 'DUTY'} | Reason: ${data.reason || 'N/A'}`);

        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.status = status as any;
          (existing as any).leaveReason = data.reason || '';
          liveDrivers.set(effectiveUserId, existing);
        }

        const leavePayload = {
          driverId: effectiveUserId,
          driverName: driverName,
          name: driverName,
          status: status,
          leaveReason: data.reason || '',
          regionId: data.regionId || existing?.regionId,
          timestamp: new Date().toISOString(),
        };

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).to('dashboards').emit('driver_leave_status', leavePayload);
        this.io?.to('dashboards').emit('driver_location_update', leavePayload);
      });

      socket.on('assign_job', (data: { driverId: string; [key: string]: any }) => {
        logger.info(`Admin assigning job to driver ${data.driverId}`);
        this.io?.to(`user:${data.driverId}`).emit('job_assigned', data);
      });

      // ── DRIVER: Update Profile Avatar (from Mobile Gallery/Camera) ─────
      socket.on('driver_avatar_update', (data: { driverId: string; driverName?: string; avatar?: string; avatarBase64?: string }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
        const avatarData = data.avatarBase64 || data.avatar;
        logger.info(`[AVATAR] Driver ${effectiveUserId} updated profile photo from device gallery.`);
        
        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.avatar = avatarData;
          liveDrivers.set(effectiveUserId, existing);
        }

        // Broadcast to all dashboard connections
        this.io?.to('dashboards').emit('driver_avatar_updated', {
          driverId: effectiveUserId,
          avatar: avatarData,
          timestamp: new Date().toISOString(),
        });
        this.io?.to('dashboards').emit('driver_location_update', {
          ...(existing || {}),
          driverId: effectiveUserId,
          name: data.driverName ?? existing?.name ?? effectiveUserId,
          avatar: avatarData,
          timestamp: new Date().toISOString(),
        });
      });

      // ── DRIVER: Trip Telemetry & Safety Analysis Audit ───────────────────
      socket.on('trip_telemetry_analysis', (data: {
        driverId: string;
        tripId?: string;
        startTime?: string;
        endTime?: string;
        distanceKm?: number;
        durationMinutes?: number;
        averageSpeed?: number;
        maxSpeed?: number;
        safetyScore?: number;
        harshBrakingCount?: number;
        lateralGForce?: number;
        deliveryFrom?: string;
        deliveryTo?: string;
        payout?: number;
      }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
        logger.info(`[TRIP AUDIT] Received completed trip telemetry for driver ${effectiveUserId} | Safety Score: ${data.safetyScore ?? 100}% | Distance: ${data.distanceKm} KM`);

        // Broadcast to all dashboard screens (Drivers, Trips, Reports)
        this.io?.to('dashboards').emit('trip_analysis_received', {
          ...data,
          driverId: effectiveUserId,
          timestamp: new Date().toISOString(),
        });
      });

      // ── DRIVER: Roadside Breakdown / Tow-Truck SOS Dispatch ───────────
      socket.on('roadside_breakdown_alert', (data: {
        id?: string;
        driverId?: string;
        driverName?: string;
        issueType?: string;
        breakdownType?: string;
        notes?: string;
        latitude?: number;
        longitude?: number;
        vehiclePlate?: string;
        nearestLandmark?: string;
        timestamp?: number | string;
      }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : (data.driverId || userId);
        const resolvedIssue = data.issueType || data.breakdownType || 'Mechanical Stall / Towing';
        const existing = liveDrivers.get(effectiveUserId);
        const lat = data.latitude ?? existing?.latitude ?? 12.7749;
        const lng = data.longitude ?? existing?.longitude ?? 75.2023;

        logger.warn(`🚨 [ROADSIDE BREAKDOWN] Driver ${effectiveUserId} (${data.driverName || existing?.name || 'Driver'}) requested assistance: ${resolvedIssue} at [${lat}, ${lng}]`);

        if (existing) {
          existing.status = 'emergency';
          existing.latitude = lat;
          existing.longitude = lng;
          liveDrivers.set(effectiveUserId, existing);
        }

        const payload = {
          id: data.id || `BRK-${Date.now()}`,
          driverId: effectiveUserId,
          driverName: data.driverName || existing?.name || 'Field Operator',
          issueType: resolvedIssue,
          breakdownType: resolvedIssue,
          notes: data.notes || '',
          latitude: lat,
          longitude: lng,
          vehiclePlate: data.vehiclePlate || (existing as any)?.vehiclePlate || 'KA-19-LIVE',
          nearestLandmark: data.nearestLandmark || 'Transit Highway Corridor',
          status: 'emergency',
          createdAt: new Date().toISOString(),
          timestamp: typeof data.timestamp === 'number' ? data.timestamp : Date.now(),
        };

        // Broadcast to all dashboard connections & org rooms
        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).to('dashboards').emit('roadside_breakdown_alert', payload);
        this.io?.to('dashboards').emit('roadside_breakdown_alert', payload);
        this.io?.emit('roadside_breakdown_alert', payload);
      });

      // ── DRIVER: Auto-Lock Dashcam Video Evidence Dossier (20 Frames) ──
      socket.on('locked_dashcam_evidence', (data: {
        driverId?: string;
        driverName?: string;
        incidentId?: string;
        reason?: string;
        frames?: any[];
        timestamp?: number | string;
      }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : (data.driverId || userId);
        logger.warn(`📹 [LOCKED EVIDENCE] Received 20-frame dashcam dossier for driver ${effectiveUserId} (Trigger: ${data.reason})`);

        const payload = {
          ...data,
          driverId: effectiveUserId,
          lockedAt: new Date().toISOString(),
        };

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).to('dashboards').emit('locked_dashcam_evidence', payload);
        this.io?.to('dashboards').emit('locked_dashcam_evidence', payload);
        this.io?.emit('locked_dashcam_evidence', payload);
      });

      // ── DRIVER: Offline "Ghat Mode" FIFO Burst Synchronization ─────────
      socket.on('batch_offline_telemetry', (data: {
        driverId?: string;
        count?: number;
        points: Array<any>;
        syncedAt?: string;
      }) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : (data.driverId || userId);
        const points = Array.isArray(data.points) ? data.points : [];
        const count = points.length || data.count || 0;
        logger.info(`⚡ [GHAT OFFLINE SYNC] Burst synced ${count} telemetry points from driver ${effectiveUserId}`);

        if (points.length > 0) {
          const validPoints = points.filter(p => p && (p.latitude !== undefined || p.lat !== undefined));
          if (validPoints.length > 0) {
            const latestPoint = validPoints[validPoints.length - 1];
            const existing = liveDrivers.get(effectiveUserId);
            const lat = latestPoint.latitude ?? latestPoint.lat ?? existing?.latitude;
            const lng = latestPoint.longitude ?? latestPoint.lng ?? existing?.longitude;
            const speed = latestPoint.speed ?? existing?.speed ?? 0;

            if (existing) {
              existing.latitude = lat;
              existing.longitude = lng;
              existing.speed = speed;
              existing.isOnline = true;
              existing.lastSeen = latestPoint.timestamp ? new Date(latestPoint.timestamp).toISOString() : new Date().toISOString();
              liveDrivers.set(effectiveUserId, existing);
            }

            // Emit location update for the latest coordinates
            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            const locUpdate = {
              ...(existing || {}),
              driverId: effectiveUserId,
              latitude: lat,
              longitude: lng,
              speed: speed,
              isOnline: true,
              isDeadZone: false,
              status: existing?.status === 'emergency' ? 'emergency' : 'safe',
              timestamp: latestPoint.timestamp || new Date().toISOString(),
            };
            this.io?.to(orgRoom).to('dashboards').emit('driver_location_update', locUpdate);
            this.io?.to('dashboards').emit('driver_location_update', locUpdate);
            this.io?.emit('driver_location_update', locUpdate);

            // Broadcast deadzone burst sync celebration to dashboards
            this.io?.to('dashboards').emit('deadzone_burst_synced', {
              driverId: effectiveUserId,
              driverName: existing?.name || effectiveUserId,
              count: validPoints.length,
              syncedAt: new Date().toISOString(),
              latestLocation: { lat, lng },
              points: validPoints,
            });
          }
        }
      });



      // ── DRIVER: No Response to Safety Ping (30s Timer Timeout) ─────────────
      socket.on('driver_no_response', (data: { driverId?: string; reason?: string }) => {
        const effectiveUserId = data.driverId || userId;
        logger.warn(`⚠️ DRIVER NO RESPONSE to Safety Ping: ${effectiveUserId}`);

        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.status = 'emergency';
          liveDrivers.set(effectiveUserId, existing);
        }

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        const alertData = {
          driverId: effectiveUserId,
          driverName: existing?.name || effectiveUserId,
          reason: data.reason || 'Admin Safety Ping Expired: No Response from Driver (30s elapsed)',
          severity: 'CRITICAL',
          latitude: existing?.latitude ?? 12.7749,
          longitude: existing?.longitude ?? 75.2023,
          timestamp: new Date().toISOString(),
        };

        this.io?.to(orgRoom).to('dashboards').emit('driver_no_response', alertData);
        this.io?.to(orgRoom).to('dashboards').emit('crash_alert', alertData);
      });

      // ── DRIVER: Emergency Escalation (Manual SOS or Unanswered Ping) ───────
      socket.on('emergency_escalation', (data: { driverId?: string; reason?: string; alertType?: string }) => {
        const effectiveUserId = data.driverId || userId;
        const isManualSos = data.alertType === 'SOS' || (data.reason && data.reason.toLowerCase().includes('sos'));
        logger.warn(`🚨 ${isManualSos ? 'MANUAL SOS ESCALATION' : 'EMERGENCY ESCALATION'} from driver ${effectiveUserId}: ${data.reason || 'SOS Triggered'}`);

        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.status = 'emergency';
          existing.alertType = isManualSos ? 'SOS' : 'CRASH';
          liveDrivers.set(effectiveUserId, existing);
        }

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        const alertData = {
          id: `sos-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          alertType: isManualSos ? 'SOS' : 'CRASH',
          driverId: effectiveUserId,
          driverName: existing?.name || effectiveUserId,
          reason: data.reason || (isManualSos ? 'Driver Manual SOS Panic Beacon Triggered' : 'Emergency SOS Escalation / No Response'),
          severity: 'CRITICAL',
          latitude: existing?.latitude ?? 12.7749,
          longitude: existing?.longitude ?? 75.2023,
          timestamp: new Date().toISOString(),
        };

        if (isManualSos) {
          this.io?.to(orgRoom).to('dashboards').emit('sos_alert', alertData);
          this.io?.emit('sos_alert', alertData);
        } else {
          this.io?.to(orgRoom).to('dashboards').emit('driver_no_response', alertData);
          this.io?.to(orgRoom).to('dashboards').emit('crash_alert', alertData);
        }
      });

      // ── DRIVER: Dedicated Manual SOS Panic Alert ───────────────────────────
      const handleDriverSos = async (data: any) => {
        const effectiveUserId = data.driverId || userId;
        logger.warn(`🚨 [MANUAL SOS PANIC] Driver ${effectiveUserId} (${data.driverName || 'Operator'}) triggered SOS at [${data.latitude}, ${data.longitude}]`);
        
        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.status = 'emergency';
          existing.alertType = 'SOS';
          existing.sosReason = data.reason || 'Manual SOS Panic Triggered by Operator';
          liveDrivers.set(effectiveUserId, existing);
        }

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        const sosData = {
          id: data.id || `SOS-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          alertType: 'SOS',
          driverId: effectiveUserId,
          driverName: data.driverName || existing?.name || 'Driver',
          phone: data.phone || data.phoneNumber || (existing as any)?.phone || '+91 94812 55667',
          vehiclePlate: data.vehiclePlate || (existing as any)?.vehiclePlate || 'KA-19-PT-2026',
          reason: data.reason || 'Manual SOS Panic Triggered by Operator',
          severity: 'CRITICAL',
          latitude: (data.latitude && !isNaN(data.latitude) && data.latitude !== 0) ? data.latitude : (existing?.latitude ?? 12.7749),
          longitude: (data.longitude && !isNaN(data.longitude) && data.longitude !== 0) ? data.longitude : (existing?.longitude ?? 75.2023),
          speed: data.speed ?? existing?.speed ?? 0,
          timestamp: data.timestamp || new Date().toISOString(),
          status: 'emergency',
        };

        const googleMapsLink = `https://maps.google.com/?q=${sosData.latitude},${sosData.longitude}`;
        logger.info(`[SOS PANIC DISPATCH] Emitting SOS Alert for ${sosData.driverName} at ${googleMapsLink}`);

        // Broadcast dedicated sos_alert to all dashboard rooms (NOT crash_alert)
        this.io?.to(orgRoom).to('dashboards').emit('sos_alert', sosData);
        this.io?.emit('sos_alert', sosData);
      };

      socket.on('driver_sos_alert', handleDriverSos);
      socket.on('sos_alert', handleDriverSos);

      // ── DRIVER: crash_detected alias for mobile ────────────────────────────
      socket.on('crash_detected', async (data: any) => {
        logger.warn(`🚨 CRASH DETECTED from driver ${data.driverId || userId} (${data.reason || 'Impact'})`);
        const effectiveUserId = data.driverId || userId;
        const existing = liveDrivers.get(effectiveUserId);
        if (existing) {
          existing.status = 'emergency';
          liveDrivers.set(effectiveUserId, existing);
        }

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        const alertData = {
          driverId: effectiveUserId,
          driverName: data.driverName || existing?.name || effectiveUserId,
          reason: data.reason || 'Critical Vehicle Impact / Sudden Deceleration',
          severity: data.severity || 'CRITICAL',
          latitude: data.latitude ?? existing?.latitude ?? 12.7749,
          longitude: data.longitude ?? existing?.longitude ?? 75.2023,
          speedBefore: data.speedBefore ?? 60,
          speedAfter: data.speedAfter ?? 0,
          gForce: data.gForce ?? 4.2,
          blackBoxData: data.blackBoxData || data.blackBox || [],
          timestamp: new Date().toISOString(),
        };

        const googleMapsLink = `https://maps.google.com/?q=${alertData.latitude},${alertData.longitude}`;
        const smsMessage = `🚨 CRITICAL SAFETY ALERT: Driver ${alertData.driverName} reported impact near coordinates ${alertData.latitude.toFixed(4)}, ${alertData.longitude.toFixed(4)}. Impact: ${alertData.gForce || 4.2}G. Live GPS: ${googleMapsLink}`;

        logger.info(`[EMERGENCY SMS DISPATCH] Generated SMS alert: "${smsMessage}"`);

        // Emit emergency SMS dispatch confirmation
        this.io?.to(orgRoom).to('dashboards').emit('emergency_sms_dispatched', {
          driverId: effectiveUserId,
          driverName: alertData.driverName,
          phone: data.emergencyContactPhone || 'Emergency Services (108)',
          message: smsMessage,
          mapsLink: googleMapsLink,
          timestamp: alertData.timestamp,
        });

        this.io?.to(orgRoom).to('dashboards').emit('crash_alert', alertData);
      });

      // ── DRIVER: Pothole & Road Roughness Detection ────────────────────────
      socket.on('pothole_detected', (data: any) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
        const lat = data.latitude ?? data.lat;
        const lng = data.longitude ?? data.lng;
        if (lat !== undefined && lng !== undefined && !isNaN(Number(lat)) && !isNaN(Number(lng))) {
          const newPothole: LivePothole = {
            id: `pothole-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
            latitude: Number(lat),
            longitude: Number(lng),
            intensity: Number(data.intensity || (data.vibrationRate ? Math.min(1.0, data.vibrationRate / 4.0) : 0.85)),
            vibrationRate: data.vibrationRate ?? 3.2,
            driverId: effectiveUserId,
            driverName: data.driverName ?? liveDrivers.get(effectiveUserId)?.name ?? effectiveUserId,
            roadName: data.roadName || 'Active Transit Sector',
            regionId: data.regionId || liveDrivers.get(effectiveUserId)?.regionId || 'puttur_taluk',
            timestamp: data.timestamp || new Date().toISOString(),
          };

          // Filter duplicate if reported nearby within 35 meters
          const isNearby = livePotholes.some(p => {
            const dLat = (p.latitude - newPothole.latitude) * 111000;
            const dLng = (p.longitude - newPothole.longitude) * 111000 * Math.cos(p.latitude * Math.PI / 180);
            return Math.sqrt(dLat * dLat + dLng * dLng) < 35;
          });

          if (!isNearby) {
            livePotholes.unshift(newPothole);
            if (livePotholes.length > 250) livePotholes.pop();
          }

          logger.info(`🕳️ ROAD HAZARD DETECTED: [${lat}, ${lng}] by driver ${newPothole.driverName} | Intensity: ${newPothole.intensity.toFixed(2)} | Vibe: ${newPothole.vibrationRate}G`);

          // Broadcast to all Admin dashboards (for Heatmaps & LiveMap)
          this.io?.to('dashboards').emit('pothole_detected', newPothole);
          // Broadcast to all active Drivers so other drivers are warned in real time
          this.io?.emit('pothole_broadcast', newPothole);
        }
      });

      // ── DRIVER: Traffic Rule Violation Alert ─────────────────────────────
      socket.on('rule_violation_alert', (data: any) => {
        const effectiveUserId = (userId === 'mobile-driver' && data.driverId) ? data.driverId : userId;
        const driverName = data.driverName ?? liveDrivers.get(effectiveUserId)?.name ?? effectiveUserId;
        const violationPayload = {
          id: `rule-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
          driverId: effectiveUserId,
          driverName: driverName,
          ruleType: data.ruleType || 'RULE_BREACH',
          ruleTitle: data.ruleTitle || 'Traffic Rule Breach',
          severity: data.severity || 'high',
          latitude: data.latitude ?? liveDrivers.get(effectiveUserId)?.latitude ?? 12.7749,
          longitude: data.longitude ?? liveDrivers.get(effectiveUserId)?.longitude ?? 75.2023,
          speed: data.speed ?? 0,
          speedLimit: data.speedLimit ?? 30,
          roadType: data.roadType || 'City Road',
          roadName: data.roadName || 'Main Corridor',
          description: data.description || 'Driver detected violating road safety rules.',
          timestamp: data.timestamp || new Date().toISOString(),
        };

        logger.warn(`⚠️ RULE VIOLATION from driver ${effectiveUserId} (${driverName}): [${violationPayload.ruleType}] ${violationPayload.ruleTitle} on ${violationPayload.roadName}`);

        // Broadcast to Admin dashboards alert section & org
        this.io?.to('dashboards').emit('rule_violation_alert', violationPayload);
        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).emit('rule_violation_alert', violationPayload);
      });

      // ── ADMIN: Voice / Intercom Broadcast Dispatch ───────────────────────
      socket.on('admin_voice_broadcast', (data: { message: string; priority?: string; targetGroup?: string; region?: string; adminName?: string }) => {
        logger.info(`[VOICE BROADCAST] Admin dispatch: "${data.message}" | Priority: ${data.priority || 'WARNING'}`);
        const payload = {
          message: data.message,
          priority: data.priority || 'WARNING',
          targetGroup: data.targetGroup || 'ALL',
          region: data.region || 'ALL',
          adminName: data.adminName || 'Fleet Command HQ',
          timestamp: new Date().toISOString(),
        };

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).to('dashboards').emit('admin_voice_broadcast', payload);
        this.io?.to('user:mobile-driver').emit('admin_voice_broadcast', payload);
        this.io?.emit('admin_voice_broadcast', payload);
      });

      // ── GEOFENCING: Dynamic Speed Zone Editor ─────────────────────────────
      socket.on('geofence_create', (data: any) => {
        const newGeo: LiveGeofence = {
          id: data.id || `geo-${Date.now()}`,
          name: data.name || 'Enforced Speed Zone',
          type: data.type || 'custom',
          centerLat: data.centerLat ?? data.lat ?? 12.7749,
          centerLng: data.centerLng ?? data.lng ?? 75.2023,
          radiusMeters: data.radiusMeters || 300,
          speedLimitKph: data.speedLimitKph || 30,
          color: data.color || '#3b82f6',
          regionId: data.regionId || 'puttur_taluk',
          createdAt: new Date().toISOString(),
        };

        liveGeofences.push(newGeo);
        logger.info(`🌐 [GEOFENCE CREATED] ${newGeo.name} (Limit: ${newGeo.speedLimitKph} km/h, Radius: ${newGeo.radiusMeters}m)`);

        const orgRoom = `org:${organizationId ?? 'demo-org'}`;
        this.io?.to(orgRoom).to('dashboards').emit('geofence_updated', { action: 'create', geofence: newGeo, all: liveGeofences });
        this.io?.emit('geofence_updated', { action: 'create', geofence: newGeo, all: liveGeofences });
      });

      socket.on('geofence_delete', (data: { id: string }) => {
        const idx = liveGeofences.findIndex(g => g.id === data.id);
        if (idx >= 0) {
          const removed = liveGeofences.splice(idx, 1)[0];
          logger.info(`🗑️ [GEOFENCE DELETED] ${removed.name} (${removed.id})`);
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).to('dashboards').emit('geofence_updated', { action: 'delete', id: data.id, all: liveGeofences });
          this.io?.emit('geofence_updated', { action: 'delete', id: data.id, all: liveGeofences });
        }
      });

      socket.on('get_geofences', () => {
        socket.emit('geofences_sync', liveGeofences);
      });


      // ── Heartbeat ping/pong ───────────────────────────────────────────────
      socket.on('ping', () => socket.emit('pong', { ts: Date.now() }));

      socket.on('disconnect', () => {
        logger.info(`Socket disconnected: ${socket.id} (User ${userId})`);
        const current = this.userSockets.get(userId) || [];
        this.userSockets.set(
          userId,
          current.filter((id) => id !== socket.id)
        );

        // Mark driver offline and notify dashboard
        const effectiveId = socket.data?.user?.userId || userId;
        if (role === 'DRIVER' || effectiveId) {
          liveDrivers.delete(effectiveId);
          liveDrivers.delete(userId);
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).to('dashboards').emit('driver_location_update', {
            driverId: effectiveId,
            status: 'offline',
            isOnline: false,
            timestamp: new Date().toISOString(),
          });
        }
      });
    });
  }

  /** Send a vibration/alert command from admin to a specific driver */
  sendVibrationAlert(driverId: string, message: string, level: 'info' | 'warning' | 'critical' = 'warning') {
    if (!this.io) return;
    this.io.to(`user:${driverId}`).emit('vibration_alert', {
      message,
      level,
      timestamp: new Date().toISOString(),
    });
    logger.info(`Vibration alert sent to driver ${driverId}: [${level}] ${message}`);
  }

  broadcastToOrg(organizationId: string, eventName: string, data: any) {
    if (!this.io) {
      logger.error('Socket server is uninitialized.');
      return;
    }
    this.io.to(`org:${organizationId}`).to('dashboards').emit(eventName, data);
  }

  sendToUser(userId: string, eventName: string, data: any) {
    if (!this.io) {
      logger.error('Socket server is uninitialized.');
      return;
    }
    // Send to specific user room
    this.io.to(`user:${userId}`).emit(eventName, data);
    // Broadcast job_assigned to all connected clients so demo drivers (web or mobile) catch it
    if (eventName === 'job_assigned') {
      this.io.emit('job_assigned', data);
    }
  }

  getLivePotholes(): LivePothole[] {
    return livePotholes;
  }

  getLiveGeofences(): LiveGeofence[] {
    return liveGeofences;
  }

  getLiveDrivers(organizationId?: string): LiveDriver[] {
    const now = Date.now();
    for (const [id, d] of liveDrivers.entries()) {
       if (id === 'agent-x' || id === 'mobile-driver' || d.driverId === 'agent-x' || d.driverId === 'mobile-driver') {
          liveDrivers.delete(id);
          continue;
       }
       const elapsedMs = now - new Date(d.lastSeen).getTime();
       // In Dead Zone (ghat road / cellular loss), mobile buffers up to 15 minutes
       if (elapsedMs > 25000 && elapsedMs <= 900000) {
         // Mark as in dead zone, keep last known coordinate
         d.isDeadZone = true;
         if (d.status !== 'emergency') {
           d.status = 'offline';
         }
       } else if (elapsedMs > 900000) {
         // Purge after 15 minutes of complete inactivity
         liveDrivers.delete(id);
       }
    }
    const all = Array.from(liveDrivers.values());
    // Deduplicate by driver name or driverId so admin dashboard shows exactly 1 per actual driver
    const uniqueMap = new Map<string, LiveDriver>();
    for (const d of all) {
      const key = (d.name || d.driverId || d.id || '').toLowerCase().trim();
      if (!uniqueMap.has(key)) {
        uniqueMap.set(key, d);
      }
    }
    const unique = Array.from(uniqueMap.values());
    if (!organizationId) return unique;
    return unique.filter((d) => d.organizationId === organizationId);
  }

  getIO(): Server | null {
    return this.io;
  }

  emitToDashboards(eventName: string, data: any) {
    if (!this.io) {
      logger.warn(`Cannot emit ${eventName}: socket server uninitialized.`);
      return;
    }
    logger.info(`[Socket Broadcast -> Dashboards] Event: ${eventName}`);
    this.io.to('dashboards').emit(eventName, data);
    this.io.emit(eventName, data);
  }

  removeDriver(driverId: string) {
    liveDrivers.delete(driverId);
    if (this.io) {
      this.io.to('dashboards').emit('driver_removed', { driverId });
    }
  }
}

export const socketManager = new SocketManager();
