import { useEffect, useState, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { Driver } from '@/types';

// Connect to backend (assumes running locally)
const SOCKET_URL = 'http://localhost:3000';

const socket = io(SOCKET_URL, {
  auth: { role: 'dashboard' },
  transports: ['websocket'],
  autoConnect: false,
});

export function useSocketDrivers(initialMockDrivers: Driver[]) {
  const [liveDrivers, setLiveDrivers] = useState<Driver[]>(initialMockDrivers);
  const [isConnected, setIsConnected] = useState(false);
  const [crashAlertDriver, setCrashAlertDriver] = useState<any | null>(null);

  useEffect(() => {
    if (!socket.connected) {
      socket.connect();
    }

    socket.on('connect', () => {
      console.log('Connected to FleetGuard WebSocket backend');
      setIsConnected(true);
    });

    socket.on('disconnect', () => {
      console.log('Disconnected from FleetGuard WebSocket backend');
      setIsConnected(false);
    });

    socket.on('live_snapshot', (snapshot: any[]) => {
      if (snapshot.length > 0) {
        setLiveDrivers(prev => {
          const updated = [...prev];
          snapshot.forEach(liveDriver => {
            const idx = updated.findIndex(d => d.id === liveDriver.driverId);
            if (idx >= 0) {
              updated[idx] = {
                ...updated[idx],
                location: { lat: liveDriver.latitude, lng: liveDriver.longitude },
                speed: liveDriver.speed,
                status: liveDriver.status,
              };
            }
          });
          return updated;
        });
      }
    });

    socket.on('driver_location_update', (data: any) => {
      setLiveDrivers(prev => {
        const updated = [...prev];
        const idx = updated.findIndex(d => d.id === data.driverId);
        if (idx >= 0) {
          updated[idx] = {
            ...updated[idx],
            location: { lat: data.latitude, lng: data.longitude },
            speed: data.speed,
            status: data.status || updated[idx].status,
          };
        }
        return updated;
      });
    });

    socket.on('crash_alert', (data: any) => {
      console.warn('Crash alert received!', data);
      setCrashAlertDriver(data);
    });

    return () => {
      socket.off('connect');
      socket.off('disconnect');
      socket.off('live_snapshot');
      socket.off('driver_location_update');
      socket.off('crash_alert');
    };
  }, []);

  return { liveDrivers, isConnected, crashAlertDriver, setCrashAlertDriver };
}
