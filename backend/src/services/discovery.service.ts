import dgram from 'dgram';
import { logger } from '../config/logger';

const DISCOVERY_PORT = 41234;
const DISCOVERY_MAGIC_REQ = 'SMARTDRIVE_DISCOVERY_REQ';
const DISCOVERY_MAGIC_RES = 'SMARTDRIVE_DISCOVERY_RES';

export class DiscoveryService {
  private socket: dgram.Socket | null = null;
  private beaconTimer: NodeJS.Timeout | null = null;

  start(httpPort: number = 3000) {
    try {
      this.socket = dgram.createSocket({ type: 'udp4', reuseAddr: true });

      this.socket.on('error', (err) => {
        logger.warn(`[DiscoveryService] UDP Error (Non-critical): ${err.message}`);
      });

      this.socket.on('message', (msg, rinfo) => {
        try {
          const str = msg.toString().trim();
          // Strictly reply ONLY to incoming discovery requests, NEVER to response beacons or self broadcasts
          if (str === DISCOVERY_MAGIC_REQ || str.endsWith('_DISCOVERY_REQ')) {
            const responsePayload = JSON.stringify({
              magic: DISCOVERY_MAGIC_RES,
              service: 'smartdrive-backend',
              port: httpPort,
              timestamp: new Date().toISOString(),
            });

            this.socket?.send(responsePayload, rinfo.port, rinfo.address, (err) => {
              if (!err) {
                logger.debug(`📡 [DiscoveryService] Auto-discovery beacon replied to ${rinfo.address}:${rinfo.port}`);
              }
            });
          }
        } catch (_) {}
      });

      this.socket.bind(DISCOVERY_PORT, '0.0.0.0', () => {
        try {
          this.socket?.setBroadcast(true);
          logger.info(`✨ [DiscoveryService] Zero-config auto-discovery beacon active on UDP:${DISCOVERY_PORT}`);
        } catch (_) {}

        // Broadcast periodic beacon every 4s for listening clients
        this.beaconTimer = setInterval(() => {
          try {
            const beaconMsg = JSON.stringify({
              magic: DISCOVERY_MAGIC_RES,
              service: 'smartdrive-backend',
              port: httpPort,
            });
            this.socket?.send(beaconMsg, DISCOVERY_PORT, '255.255.255.255');
          } catch (_) {}
        }, 4000);
      });
    } catch (err: any) {
      logger.warn(`[DiscoveryService] Could not initialize UDP socket: ${err?.message}`);
    }
  }

  stop() {
    if (this.beaconTimer) {
      clearInterval(this.beaconTimer);
      this.beaconTimer = null;
    }
    if (this.socket) {
      try {
        this.socket.close();
      } catch (_) {}
      this.socket = null;
    }
  }
}

export const discoveryService = new DiscoveryService();
