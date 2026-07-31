import { Server, Socket } from 'socket.io';
import http from 'http';
import jwt from 'jsonwebtoken';
import { logger } from '../config/logger';
import { TokenPayload } from '../services/auth.service';

const ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ||
  'super-secret-access-key-fleetguard-ai-2026';

// ─────────────────────────────────────────────────────────────────────────────
// In-memory store so the system works even without a DB (lite/demo mode)
// ─────────────────────────────────────────────────────────────────────────────
interface LiveDriver {
  driverId: string;
  name: string;
  organizationId: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  status: 'safe' | 'warning' | 'emergency' | 'idle' | 'offline';
  lastSeen: string;
}

const liveDrivers = new Map<string, LiveDriver>();

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
    });

    // ── JWT Auth middleware ───────────────────────────────────────────────────
    this.io.use((socket: Socket, next) => {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.split(' ')[1];

      // Allow unauthenticated dashboard connections with a special key for demo
      if (!token) {
        if (socket.handshake.auth?.role === 'dashboard') {
          socket.data.user = { userId: 'dashboard', role: 'ADMIN', organizationId: 'demo-org' };
          return next();
        }
        return next(new Error('Authentication error: Token missing'));
      }

      try {
        const decoded = jwt.verify(token, ACCESS_SECRET) as TokenPayload;
        socket.data.user = decoded;
        next();
      } catch (err) {
        // Fallback: allow demo tokens shaped as { userId, role, organizationId }
        try {
          const demo = JSON.parse(Buffer.from(token.split('.')[1] ?? '', 'base64').toString());
          if (demo?.userId && demo?.role) {
            socket.data.user = demo;
            return next();
          }
        } catch (_) {}
        return next(new Error('Authentication error: Token invalid'));
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

      // ── Dashboard: on connect, send current live driver snapshot ─────────
      if (role === 'ADMIN' || socket.handshake.auth?.role === 'dashboard') {
        const snapshot = Array.from(liveDrivers.values()).filter(
          (d) => d.organizationId === (organizationId ?? 'demo-org')
        );
        socket.emit('live_snapshot', snapshot);
        logger.debug(`Sent snapshot of ${snapshot.length} live drivers to dashboard`);
      }

      // ── DRIVER: GPS telemetry stream ──────────────────────────────────────
      socket.on(
        'gps_update',
        async (data: {
          tripId?: string;
          driverName?: string;
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

          // Determine driver status based on speed
          const speed = data.speed ?? 0;
          let status: LiveDriver['status'] = 'safe';
          if (speed === 0) status = 'idle';
          else if (speed > 80) status = 'warning';

          // Update in-memory driver state
          liveDrivers.set(userId, {
            driverId: userId,
            name: data.driverName ?? user.email ?? userId,
            organizationId: organizationId ?? 'demo-org',
            latitude: data.latitude,
            longitude: data.longitude,
            speed,
            heading: data.heading ?? 0,
            status,
            lastSeen: data.timestamp ?? new Date().toISOString(),
          });

          // Broadcast to dashboard(s) in the org room
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).emit('driver_location_update', {
            tripId: data.tripId,
            driverId: userId,
            driverName: data.driverName ?? userId,
            latitude: data.latitude,
            longitude: data.longitude,
            speed,
            heading: data.heading ?? 0,
            altitude: data.altitude,
            status,
            timestamp: data.timestamp ?? new Date().toISOString(),
          });

          // Persist to DB non-blockingly — fail silently in lite mode
          try {
            const { tripService } = await import('../services/trip.service');
            if (data.tripId) {
              await tripService.recordLocation(data.tripId, {
                latitude: data.latitude,
                longitude: data.longitude,
                speed,
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
            `🚨 CRASH EVENT from driver ${userId} at [${data.latitude}, ${data.longitude}]`
          );

          // Mark driver as emergency in live store
          const existing = liveDrivers.get(userId);
          if (existing) {
            existing.status = 'emergency';
            liveDrivers.set(userId, existing);
          }

          // Broadcast crash alert to entire org dashboard
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).emit('crash_alert', {
            driverId: userId,
            driverName: data.driverName ?? existing?.name ?? userId,
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

          // Confirm receipt to driver
          socket.emit('crash_confirmed', { received: true });
        }
      );

      // ── DRIVER: Respond to safety ping (admin confirming driver is alive) ─
      socket.on('safety_response', () => {
        const existing = liveDrivers.get(userId);
        if (existing && existing.status === 'emergency') {
          existing.status = 'warning';
          liveDrivers.set(userId, existing);
          const orgRoom = `org:${organizationId ?? 'demo-org'}`;
          this.io?.to(orgRoom).emit('driver_responded', { driverId: userId });
        }
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
        if (role === 'DRIVER') {
          const existing = liveDrivers.get(userId);
          if (existing) {
            existing.status = 'offline';
            liveDrivers.set(userId, existing);
            const orgRoom = `org:${organizationId ?? 'demo-org'}`;
            this.io?.to(orgRoom).emit('driver_location_update', {
              ...existing,
              status: 'offline',
              timestamp: new Date().toISOString(),
            });
          }
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
    this.io.to(`org:${organizationId}`).emit(eventName, data);
  }

  sendToUser(userId: string, eventName: string, data: any) {
    if (!this.io) {
      logger.error('Socket server is uninitialized.');
      return;
    }
    this.io.to(`user:${userId}`).emit(eventName, data);
  }

  getLiveDrivers(organizationId?: string): LiveDriver[] {
    const all = Array.from(liveDrivers.values());
    if (!organizationId) return all;
    return all.filter((d) => d.organizationId === organizationId);
  }
}

export const socketManager = new SocketManager();
