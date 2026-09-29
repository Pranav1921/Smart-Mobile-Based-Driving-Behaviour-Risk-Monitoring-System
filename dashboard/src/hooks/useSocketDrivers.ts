import { useEffect, useState, useCallback } from 'react';
import { io } from 'socket.io-client';
import { Driver, LivePothole, RuleViolation } from '@/types';
import { GeofenceZone } from '@/types/geofence';
import { fetchDriversFromApi, fetchPendingDrivers } from '@/lib/apiClient';
import { isDriverInRegion, getActiveAdminRegionId } from '@/lib/regionMatcher';

const SOCKET_URL = window.location.hostname === 'localhost'
  ? 'http://localhost:3000'
  : `http://${window.location.hostname}:3000`;

const socket = io(SOCKET_URL, {
  auth: { role: 'dashboard' },
  transports: ['websocket', 'polling'],
  autoConnect: false,
});

// Synthesized Web Audio chime (High-tech two-tone alert chime)
function playNotificationChime() {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();
    const now = ctx.currentTime;

    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, now); // D5
    osc1.frequency.exponentialRampToValueAtTime(880, now + 0.15); // A5
    gain1.gain.setValueAtTime(0.25, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    osc1.start(now);
    osc1.stop(now + 0.35);

    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(880, now + 0.12);
    osc2.frequency.exponentialRampToValueAtTime(1174.66, now + 0.32); // D6
    gain2.gain.setValueAtTime(0.2, now + 0.12);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.55);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(now + 0.12);
    osc2.stop(now + 0.55);
  } catch (_) {}
}

export function useSocketDrivers(initialMockDrivers: Driver[]) {
  const [liveDrivers, setLiveDrivers] = useState<Driver[]>([]);
  const [livePotholes, setLivePotholes] = useState<LivePothole[]>([]);
  const [liveGeofences, setLiveGeofences] = useState<GeofenceZone[]>([]);
  const [ruleViolations, setRuleViolations] = useState<RuleViolation[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [crashAlertDriver, setCrashAlertDriver] = useState<any | null>(null);
  const [driverOnlineToast, setDriverOnlineToast] = useState<string | null>(null);
  const [jobResponseToast, setJobResponseToast] = useState<string | null>(null);
  const [liveFrame, setLiveFrame] = useState<string | null>(null);
  const [pingedDrivers, setPingedDrivers] = useState<Record<string, { time: number; responded: boolean; timedOut?: boolean }>>({});

  // Roadside breakdown alert & locked dashcam evidence
  const [breakdownAlert, setBreakdownAlert] = useState<{
    id: string;
    driverId: string;
    driverName: string;
    issueType: string;
    notes?: string;
    latitude: number;
    longitude: number;
    vehiclePlate?: string;
    timestamp: number;
  } | null>(null);
  const [latestLockedEvidence, setLatestLockedEvidence] = useState<{
    driverId: string;
    driverName?: string;
    reason: string;
    timestamp: number;
    frames: Array<{ frame: string; timestamp: number; speed: number; gForce: number }>;
  } | null>(null);

  // Pending Driver Onboarding Requests
  const [pendingDrivers, setPendingDrivers] = useState<any[]>([]);
  const [newRequestToast, setNewRequestToast] = useState<{ id: string; name: string; zone: string; time: string; count: number } | null>(null);

  const refreshPendingDrivers = useCallback(async (zone?: string) => {
    try {
      const data = await fetchPendingDrivers(zone);
      if (Array.isArray(data)) {
        setPendingDrivers(data);
      }
    } catch (e) {
      console.error('[Dashboard] Error fetching pending drivers:', e);
    }
  }, []);

  useEffect(() => {
    const adminRegionId = getActiveAdminRegionId();

    fetchDriversFromApi().then((apiDrivers) => {
      setLiveDrivers((prev) => deduplicateDrivers([...prev, ...apiDrivers]));
    });

    refreshPendingDrivers('all');
    const pendingPollInterval = setInterval(() => {
      refreshPendingDrivers('all');
    }, 8000);

    if (!socket.connected) {
      socket.connect();
    }

    socket.on('connect', () => {
      setIsConnected(true);
    });

    socket.on('geofences_sync', (data: GeofenceZone[]) => {
      if (Array.isArray(data)) {
        setLiveGeofences(data);
      }
    });

    socket.on('geofence_updated', (data: { action: string; allGeofences?: GeofenceZone[]; geofence?: GeofenceZone; geofenceId?: string }) => {
      if (Array.isArray(data.allGeofences)) {
        setLiveGeofences(data.allGeofences);
      } else if (data.action === 'create' && data.geofence) {
        setLiveGeofences(prev => [data.geofence!, ...prev.filter(g => g.id !== data.geofence!.id)]);
      } else if (data.action === 'delete' && data.geofenceId) {
        setLiveGeofences(prev => prev.filter(g => g.id !== data.geofenceId));
      }
    });

    socket.on('connect_error', (err) => {
      console.error('[Socket] ❌ Connection Error:', err.message);
      setIsConnected(false);
    });

    socket.on('disconnect', (reason) => {
      setIsConnected(false);
    });

    // Real-time listener for incoming driver registration applications
    socket.on('new_driver_request', (data: any) => {
      console.log('[Dashboard] 📋 NEW DRIVER REGISTRATION REQUEST RECEIVED:', data);
      playNotificationChime();

      setPendingDrivers((prev) => {
        const exists = prev.some((d) => d.id === data.id || d.driverId === data.id || (d.user && d.user.email === data.email));
        if (exists) return prev;
        return [data, ...prev];
      });

      setNewRequestToast({
        id: data.id || data.driverId || '',
        name: data.name || (data.user ? `${data.user.firstName || ''} ${data.user.lastName || ''}`.trim() : 'New Applicant'),
        zone: data.zone || data.region || 'Regional Command',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        count: 1,
      });
    });

    socket.on('driver_request_updated', (data: any) => {
      console.log('[Dashboard] 🔄 Driver request resolved/updated:', data);
      setPendingDrivers((prev) => prev.filter((d) => d.id !== data.driverId && d.driverId !== data.driverId));
    });

    socket.on('driver_application_approved', (data: any) => {
      setPendingDrivers((prev) => prev.filter((d) => d.id !== data.driverId && d.driverId !== data.driverId));
    });

    socket.on('driver_application_rejected', (data: any) => {
      setPendingDrivers((prev) => prev.filter((d) => d.id !== data.driverId && d.driverId !== data.driverId));
    });

    socket.on('live_snapshot', (snapshot: any[]) => {
      if (snapshot && snapshot.length > 0) {
        setLiveDrivers(prev => {
          // Filter out any lingering phantom drivers
          const updated = prev.filter(d => d.id !== 'agent-x' && d.id !== 'mobile-driver' && d.userId !== 'agent-x' && d.userId !== 'mobile-driver');
          snapshot.forEach(liveDriver => {
            if (!liveDriver || liveDriver.driverId === 'agent-x' || liveDriver.driverId === 'mobile-driver') {
              return;
            }
            const cleanName = (liveDriver.driverName || liveDriver.name || '').toLowerCase().trim();
            const idx = updated.findIndex(d =>
              d.id === liveDriver.driverId ||
              d.userId === liveDriver.driverId ||
              (liveDriver.driverId && d.employeeId === liveDriver.driverId) ||
              (liveDriver.email && d.email && d.email.toLowerCase() === liveDriver.email.toLowerCase()) ||
              (cleanName && d.name && d.name.toLowerCase().trim() === cleanName)
            );
            if (idx >= 0) {
              const prevLoc = updated[idx].location || { lat: 0.0, lng: 0.0 };
              const validLat = (liveDriver.latitude != null && !isNaN(liveDriver.latitude) && liveDriver.latitude !== 0) ? liveDriver.latitude : prevLoc.lat;
              const validLng = (liveDriver.longitude != null && !isNaN(liveDriver.longitude) && liveDriver.longitude !== 0) ? liveDriver.longitude : prevLoc.lng;

              updated[idx] = {
                ...updated[idx],
                location: { lat: validLat, lng: validLng },
                speed: liveDriver.speed ?? updated[idx].speed,
                status: liveDriver.status ?? updated[idx].status,
                safetyScore: liveDriver.safetyScore ?? updated[idx].safetyScore,
                vibrationRate: liveDriver.vibrationRate ?? updated[idx].vibrationRate,
                regionId: liveDriver.regionId ?? updated[idx].regionId,
                region: liveDriver.region ?? updated[idx].region,
                points: liveDriver.points ?? updated[idx].points ?? 0,
                earnings: liveDriver.earnings ?? updated[idx].earnings ?? 0,
                trips: liveDriver.trips ?? updated[idx].trips ?? 0,
                distanceToday: liveDriver.distanceToday ?? updated[idx].distanceToday ?? 0,
              };
            } else if (liveDriver.status !== 'offline') {
              updated.push(createNewLiveDriver(liveDriver));
            }
          });
          return deduplicateDrivers(updated);
        });
      }
    });

    socket.on('driver_location_update', (data: any) => {
      if (!data || data.driverId === 'agent-x' || data.driverId === 'mobile-driver') {
        return;
      }
      console.log("[Dashboard] 📡 LIVE DRIVER DATA RECEIVED:", data.driverName, data.status, data.regionId, "Points:", data.points, "Earnings:", data.earnings);
      setLiveDrivers((prev) => {
        const updated = prev.filter(d => d.id !== 'agent-x' && d.id !== 'mobile-driver' && d.userId !== 'agent-x' && d.userId !== 'mobile-driver');
        const cleanName = (data.driverName || data.name || '').toLowerCase().trim();
        const incomingId = (data.driverId || data.id || '').toLowerCase().trim();
        const incomingEmail = (data.email || '').toLowerCase().trim();

        const idx = updated.findIndex((d) => {
          const dId = (d.id || '').toLowerCase().trim();
          const dUserId = (d.userId || '').toLowerCase().trim();
          const dEmpId = (d.employeeId || '').toLowerCase().replace(/^(agent-)/i, '').trim();
          const dEmail = (d.email || '').toLowerCase().trim();
          const dName = (d.name || '').toLowerCase().trim();

          const nameMatch = Boolean(cleanName && dName && (cleanName === dName || cleanName.includes(dName) || dName.includes(cleanName)));
          const emailMatch = Boolean(incomingEmail && dEmail && incomingEmail === dEmail);
          const empIdMatch = Boolean(incomingId && dEmpId && (incomingId.includes(dEmpId) || dEmpId.includes(incomingId)));
          const idMatch = Boolean(incomingId && (dId === incomingId || dUserId === incomingId));

          return nameMatch || emailMatch || empIdMatch || idMatch;
        });

        if (idx >= 0) {
          const prevLoc = updated[idx].location || { lat: 0.0, lng: 0.0 };
          const validLat = (data.latitude != null && !isNaN(data.latitude) && data.latitude !== 0) ? data.latitude : prevLoc.lat;
          const validLng = (data.longitude != null && !isNaN(data.longitude) && data.longitude !== 0) ? data.longitude : prevLoc.lng;

          updated[idx] = {
            ...updated[idx],
            location: { lat: validLat, lng: validLng },
            speed: data.speed ?? updated[idx].speed,
            status: data.status || updated[idx].status,
            safetyScore: data.safetyScore || updated[idx].safetyScore,
            regionId: data.regionId || updated[idx].regionId,
            region: data.region || updated[idx].region,
            points: data.points !== undefined ? data.points : (updated[idx].points ?? 0),
            earnings: data.earnings !== undefined ? data.earnings : (updated[idx].earnings ?? 0),
            trips: data.trips !== undefined ? data.trips : (updated[idx].trips ?? 0),
            distanceToday: data.distanceToday !== undefined ? data.distanceToday : (updated[idx].distanceToday ?? 0),
            harshBrakingCount: data.harshBrakingCount !== undefined ? data.harshBrakingCount : (updated[idx].harshBrakingCount ?? 0),
            overspeedCount: data.overspeedCount !== undefined ? data.overspeedCount : (updated[idx].overspeedCount ?? 0),
            sharpTurnCount: data.sharpTurnCount !== undefined ? data.sharpTurnCount : (updated[idx].sharpTurnCount ?? 0),
            accelX: data.accelX ?? updated[idx].accelX,
            accelY: data.accelY ?? updated[idx].accelY,
            accelZ: data.accelZ ?? updated[idx].accelZ,
            gyroX: data.gyroX ?? updated[idx].gyroX,
            gyroY: data.gyroY ?? updated[idx].gyroY,
            gyroZ: data.gyroZ ?? updated[idx].gyroZ,
            magX: data.magX ?? updated[idx].magX,
            magY: data.magY ?? updated[idx].magY,
            magZ: data.magZ ?? updated[idx].magZ,
            vibrationRate: data.vibrationRate ?? updated[idx].vibrationRate,
            heading: data.heading ?? updated[idx].heading,
            deliveryFrom: data.deliveryFrom ?? updated[idx].deliveryFrom,
            deliveryTo: data.deliveryTo ?? updated[idx].deliveryTo,
            orderItems: data.orderItems ?? updated[idx].orderItems,
            avatar: data.avatar ?? (updated[idx] as any).avatar,
            leaveReason: data.leaveReason !== undefined ? data.leaveReason : (updated[idx] as any).leaveReason,
          };
        } else if (data.status !== 'offline') {
          updated.push(createNewLiveDriver(data));
        }
        return deduplicateDrivers(updated);
      });
    });

    socket.on('driver_leave_status', (data: any) => {
      setLiveDrivers((prev) => {
        const updated = [...prev];
        const idx = updated.findIndex((d) => d.id === data.driverId || d.userId === data.driverId);
        if (idx >= 0) {
          updated[idx] = {
            ...updated[idx],
            status: data.status || (data.isOnLeave ? 'leave' : 'offline'),
            leaveReason: data.leaveReason || '',
          };
        } else {
          updated.push(createNewLiveDriver({
            ...data,
            status: data.status || (data.isOnLeave ? 'leave' : 'offline'),
            leaveReason: data.leaveReason || '',
          }));
        }
        return deduplicateDrivers(updated);
      });
    });

    socket.on('driver_avatar_updated', (data: { driverId: string; avatar: string }) => {
      setLiveDrivers((prev) => {
        const updated = [...prev];
        const idx = updated.findIndex((d) => d.id === data.driverId || d.userId === data.driverId);
        if (idx >= 0) {
          updated[idx] = { ...updated[idx], avatar: data.avatar } as any;
        }
        return updated;
      });
    });

    socket.on('live_frame', (data: { driverId: string; frame: string }) => {
      const frameStr = data.frame || (data as any);
      if (typeof frameStr === 'string' && frameStr.length > 0) {
        setLiveFrame(frameStr.startsWith('data:') ? frameStr : `data:image/jpeg;base64,${frameStr}`);
      }
    });

    socket.on('crash_alert', (data: any) => {
      const currentRegion = getActiveAdminRegionId();
      if (isDriverInRegion(data, currentRegion)) {
        const enriched = {
          ...data,
          alertId: `crash-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          timestamp: Date.now(),
        };
        setCrashAlertDriver(enriched);
      }
    });

    socket.on('driver_safety_confirmed', (data: any) => {
      console.log('[Dashboard] ✅ Driver safety confirmed event received:', data);
      setCrashAlertDriver(null);
      setBreakdownAlert(null);
      setLiveDrivers((prev) =>
        prev.map((d) => {
          const matches =
            d.id === data.driverId ||
            d.userId === data.driverId ||
            d.employeeId === data.driverId ||
            d.id === data.targetId ||
            d.userId === data.targetId ||
            (data.driverName && d.name.toLowerCase() === data.driverName.toLowerCase());
          return matches ? { ...d, status: 'safe' } : d;
        })
      );
    });

    socket.on('driver_go_live', (data: any) => {
      setDriverOnlineToast(`⚡ OPERATOR LIVE: ${data.driverName || 'Driver'} is now streaming from ${data.region || data.regionId || 'Assigned Sector'}`);
      setTimeout(() => setDriverOnlineToast(null), 6000);

      setLiveDrivers(prev => {
        const idx = prev.findIndex(d => d.id === data.driverId || d.userId === data.driverId);
        if (idx >= 0) {
          const updated = [...prev];
          const prevLoc = updated[idx].location || { lat: 12.7749, lng: 75.2023 };
          const validLat = (data.latitude != null && !isNaN(data.latitude) && data.latitude !== 0) ? data.latitude : prevLoc.lat;
          const validLng = (data.longitude != null && !isNaN(data.longitude) && data.longitude !== 0) ? data.longitude : prevLoc.lng;

          updated[idx] = {
            ...updated[idx],
            status: 'safe',
            location: { lat: validLat, lng: validLng },
            regionId: data.regionId || updated[idx].regionId,
            region: data.region || updated[idx].region,
          };
          return updated;
        }
        return [...prev, createNewLiveDriver(data)];
      });
    });

    socket.on('driver_online', (data: any) => {
      setLiveDrivers(prev => {
        const idx = prev.findIndex(d => d.id === data.driverId || d.userId === data.driverId);
        if (idx >= 0) {
          const updated = [...prev];
          updated[idx] = { ...updated[idx], status: 'safe' };
          return updated;
        }
        return [...prev, createNewLiveDriver(data)];
      });
    });

    socket.on('driver_offline', (data: any) => {
      const driverName = (data.driverName || data.name || 'Driver').replace(/\s+applicant/gi, '').trim()
      const currentRegion = getActiveAdminRegionId()
      if (isDriverInRegion(data, currentRegion)) {
        setJobResponseToast(`📡 No Network Zone: ${driverName} is in a dead zone (telemetry buffering offline)`)
        setTimeout(() => setJobResponseToast(null), 6000)
      }

      setLiveDrivers(prev => {
        const updated = [...prev]
        const idx = updated.findIndex(d => d.id === data.driverId || d.userId === data.driverId)
        if (idx >= 0) {
          // Preserve valid location coordinates when setting offline!
          updated[idx] = { ...updated[idx], status: 'offline' }
        }
        return updated
      })
    })

    socket.on('driver_responded', (data: any) => {
      const currentRegion = getActiveAdminRegionId();
      if (!isDriverInRegion(data, currentRegion)) return;

      setJobResponseToast(`✓ Operator SECURE: ${data.driverName || 'Driver'} confirmed safe`);
      setTimeout(() => setJobResponseToast(null), 5000);

      setPingedDrivers(prev => ({
        ...prev,
        [data.driverId]: { ...prev[data.driverId], responded: true, timedOut: false }
      }));

      // Immediately declare driver status as safe in live registry
      setLiveDrivers(prev => {
        const updated = [...prev];
        const idx = updated.findIndex(d => d.id === data.driverId || d.userId === data.driverId);
        if (idx >= 0) {
          updated[idx] = { ...updated[idx], status: 'safe' };
        }
        return updated;
      });

      // Clear emergency banner & camera stream
      setCrashAlertDriver(null);
      setLiveFrame(null);
    });

    socket.on('driver_no_response', (data: any) => {
      const currentRegion = getActiveAdminRegionId();
      if (!isDriverInRegion(data, currentRegion)) return;

      console.warn('[Socket] ⚠️ DRIVER NO RESPONSE TO SAFETY PING:', data);
      setJobResponseToast(`⚠️ NO RESPONSE: Driver ${data.driverName || data.driverId} failed safety check (30s elapsed)!`);
      setTimeout(() => setJobResponseToast(null), 8000);

      setPingedDrivers(prev => ({
        ...prev,
        [data.driverId]: { ...prev[data.driverId], responded: false, timedOut: true }
      }));

      setCrashAlertDriver(data);
    });

    socket.on('driver_removed', (data: { driverId: string }) => {
      setLiveDrivers(prev => prev.filter(d => d.id !== data.driverId && d.userId !== data.driverId));
    });

    socket.on('potholes_snapshot', (snapshot: LivePothole[]) => {
      if (Array.isArray(snapshot)) {
        setLivePotholes(snapshot);
      }
    });

    socket.on('pothole_detected', (pothole: LivePothole) => {
      setLivePotholes((prev) => {
        if (prev.some((p) => p.id === pothole.id)) return prev;
        return [pothole, ...prev];
      });
    });

    socket.on('rule_violation_alert', (violation: RuleViolation) => {
      setRuleViolations((prev) => {
        if (prev.some((v) => v.id === violation.id)) return prev;
        return [violation, ...prev];
      });
    });

    socket.on('roadside_breakdown_alert', (data: any) => {
      const currentRegion = getActiveAdminRegionId();
      if (isDriverInRegion(data, currentRegion)) {
        console.log('[Dashboard] 🚨 ROADSIDE BREAKDOWN ALERT:', data);
        playNotificationChime();
        const enriched = {
          ...data,
          alertId: `brk-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          timestamp: Date.now(),
        };
        setBreakdownAlert(enriched);
      }
    });

    socket.on('locked_dashcam_evidence', (data: any) => {
      console.log('[Dashboard] 📹 LOCKED DASHCAM EVIDENCE DOSSIER RECEIVED:', data);
      setLatestLockedEvidence(data);
    });

    return () => {
      socket.off('connect');
      socket.off('disconnect');
      socket.off('live_snapshot');
      socket.off('driver_location_update');
      socket.off('live_frame');
      socket.off('crash_alert');
      socket.off('driver_online');
      socket.off('driver_responded');
      socket.off('driver_no_response');
      socket.off('driver_removed');
      socket.off('potholes_snapshot');
      socket.off('pothole_detected');
      socket.off('rule_violation_alert');
      socket.off('new_driver_request');
      socket.off('driver_request_updated');
      socket.off('driver_application_approved');
      socket.off('driver_application_rejected');
      socket.off('roadside_breakdown_alert');
      socket.off('locked_dashcam_evidence');
      clearInterval(pendingPollInterval);
    };
  }, [crashAlertDriver, refreshPendingDrivers]);

  const emitSafetyPing = (driverId: string) => {
    setPingedDrivers(prev => ({
      ...prev,
      [driverId]: { time: Date.now(), responded: false, timedOut: false }
    }));
    socket.emit('driver_check_ping', { driverId, message: 'Safety check. Please confirm you are safe.' });
  };

  const removeDriverLocal = (driverId: string) => {
    setLiveDrivers(prev => prev.filter(d => d.id !== driverId && d.userId !== driverId));
  };

  const emitLiveCamRequest = (driverId: string, active: boolean) => {
    socket.emit('request_live_cam', { driverId, active });
  };

  const emitIncidentResolved = (driverId: string) => {
    socket.emit('resolve_incident', { driverId });
  }

  const emitDriverMessage = (driverId: string, message: string) => {
    socket.emit('driver_message', { driverId, message });
  }

  const emitAssignJob = (driverId: string, data: any) => {
    socket.emit('assign_job', { driverId, ...data });
  }

  const emitCreateGeofence = (zone: Omit<GeofenceZone, 'id' | 'createdAt'>) => {
    socket.emit('geofence_create', zone);
  }

  const emitDeleteGeofence = (id: string) => {
    socket.emit('geofence_delete', { id });
  }

  const emitVoiceBroadcast = (data: { message: string; priority?: string; regionName?: string }) => {
    socket.emit('admin_voice_broadcast', data);
  }

  const dismissNewRequestToast = () => {
    setNewRequestToast(null);
  };

  return {
    liveDrivers,
    livePotholes,
    liveGeofences,
    ruleViolations,
    isConnected,
    crashAlertDriver,
    setCrashAlertDriver,
    driverOnlineToast,
    jobResponseToast,
    pingedDrivers,
    emitSafetyPing,
    emitLiveCamRequest,
    emitIncidentResolved,
    liveFrame,
    setLiveFrame,
    emitDriverMessage,
    emitAssignJob,
    emitCreateGeofence,
    emitDeleteGeofence,
    emitVoiceBroadcast,
    removeDriverLocal,
    socket,
    // Breakdown & Locked Evidence additions
    breakdownAlert,
    setBreakdownAlert,
    latestLockedEvidence,
    setLatestLockedEvidence,
    // Onboarding Request additions
    pendingDrivers,
    pendingCount: pendingDrivers.length,
    newRequestToast,
    dismissNewRequestToast,
    refreshPendingDrivers,
  };
}

function createNewLiveDriver(data: any): Driver {
  let lat = data.latitude ?? data.lat ?? 12.7749;
  let lng = data.longitude ?? data.lng ?? 75.2023;
  if (!lat || isNaN(lat) || lat === 0) lat = 12.7749;
  if (!lng || isNaN(lng) || lng === 0) lng = 75.2023;

  const id = data.driverId || data.id || `live-${Math.random().toString(36).substr(2, 9)}`;
  const driverIdStr = String(data.driverId || data.id || '');
  const empId = driverIdStr.toUpperCase().startsWith('DRV-') 
    ? driverIdStr.toUpperCase() 
    : `AGENT-${(driverIdStr || '0000').slice(0, 4).toUpperCase()}`;

  const rawName = String(data.name || data.driverName || 'Field Agent');
  const cleanName = rawName.replace(/\s+applicant$/i, '').trim() || 'Field Agent';

  return {
    id: id,
    userId: data.driverId || data.userId,
    name: cleanName,
    employeeId: empId,
    photo: data.avatar || data.avatarBase64 || data.photo || '',
    avatar: data.avatar || data.avatarBase64 || data.photo || '',
    status: data.status || 'safe',
    driverType: data.driverType || 'TACTICAL',
    vehicleId: 'v-live',
    industry: 'Logistics',
    fleet: 'Smart Fleet Tactical',
    safetyScore: data.safetyScore || 100,
    riskScore: 0,
    crashProbability: 0,
    speed: data.speed || 0,
    location: { lat, lng },
    locationName: data.zone || data.region || 'Active Sector',
    zone: data.zone || data.region || 'Regional Sector',
    route: [{ lat, lng }],
    distanceToday: data.distanceToday ?? data.todayDistanceKm ?? 0,
    tripDurationMin: 0,
    drivingHours: 0,
    trips: data.trips ?? data.todayTripCount ?? 0,
    battery: 100,
    internet: 100,
    gps: true,
    camera: false,
    sensors: true,
    ble: false,
    overspeedCount: data.overspeedCount ?? 0,
    harshBrakingCount: data.harshBrakingCount ?? 0,
    sharpTurnCount: data.sharpTurnCount ?? 0,
    points: data.points ?? data.totalClaimedPoints ?? 0,
    earnings: data.earnings ?? data.todayEarnedIncome ?? 0,
    weeklyTrend: 0,
    monthlyTrend: 0,
    drivingStyle: 'Active',
    aggressive: 0,
    accelX: data.accelX || 0,
    accelY: data.accelY || 0,
    accelZ: data.accelZ || 1.0,
    vibrationRate: data.vibrationRate || 0,
    gyroX: data.gyroX || 0,
    gyroY: data.gyroY || 0,
    gyroZ: data.gyroZ || 0,
    magX: data.magX || 0,
    magY: data.magY || 0,
    magZ: data.magZ || 0,
    heading: data.heading || 0,
    regionId: data.regionId || data.region,
    region: data.region || data.regionId,
    deliveryFrom: data.deliveryFrom,
    deliveryTo: data.deliveryTo,
    orderItems: data.orderItems,
    destLat: data.destLat,
    destLng: data.destLng,
    email: data.email || data.user?.email || '',
    phone: data.phone || data.phoneNumber || data.user?.phoneNumber || '',
    emergencyContactName: data.emergencyContactName || data.emergencyName || data.familyMemberName || '',
    emergencyContactPhone: data.emergencyContactPhone || data.emergencyPhone || data.familyWhatsappNumber || '',
    emergencyRelationship: data.emergencyRelationship || data.familyRelationship || 'Parent / Guardian',
    appliedVehicle: data.appliedVehicle || data.vehicleName || 'Tata Ace Gold EV',
    licenseNumber: data.licenseNumber || '',
    recommendation: 'Handshake complete.',
  };
}

export function deduplicateDrivers(drivers: Driver[]): Driver[] {
  const map = new Map<string, Driver>();
  for (const d of drivers) {
    if (!d || d.id === 'agent-x' || d.id === 'mobile-driver' || d.userId === 'agent-x' || d.userId === 'mobile-driver') {
      continue;
    }
    const normName = (d.name || '').toLowerCase().trim();
    const normEmpId = (d.employeeId || '').toLowerCase().replace(/^(agent-)/i, '').trim();
    const normId = (d.id || '').toLowerCase().trim();
    const normEmail = (d.email || '').toLowerCase().trim();

    let foundKey: string | null = null;
    for (const [k, existing] of map.entries()) {
      const exName = (existing.name || '').toLowerCase().trim();
      const exEmpId = (existing.employeeId || '').toLowerCase().replace(/^(agent-)/i, '').trim();
      const exId = (existing.id || '').toLowerCase().trim();
      const exEmail = (existing.email || '').toLowerCase().trim();

      const nameMatch = Boolean(normName && exName && (normName === exName || normName.includes(exName) || exName.includes(normName)));
      const emailMatch = Boolean(normEmail && exEmail && normEmail === exEmail);
      const empIdMatch = Boolean(normEmpId && exEmpId && (normEmpId === exEmpId || normEmpId.includes(exEmpId) || exEmpId.includes(normEmpId)));
      const idMatch = Boolean(normId && exId && normId === exId);

      if (nameMatch || emailMatch || empIdMatch || idMatch) {
        foundKey = k;
        break;
      }
    }

    if (foundKey) {
      const existing = map.get(foundKey)!;
      // Intelligently merge so telemetry updates live coordinates/speed, but registered personal info is never lost!
      const activeStatus = (existing.status !== 'offline' && d.status === 'offline') 
        ? existing.status 
        : (d.status !== 'offline' ? d.status : existing.status);

      const validLocation = (d.location && d.location.lat !== 0) 
        ? d.location 
        : (existing.location || { lat: 12.7749, lng: 75.2023 });

      const merged: Driver = {
        ...existing,
        ...d,
        id: existing.id || d.id,
        userId: existing.userId || d.userId,
        name: (d.name && d.name !== 'Field Agent') ? d.name : (existing.name || 'Field Agent'),
        email: existing.email || d.email || '',
        phone: existing.phone || d.phone || '',
        emergencyContactName: existing.emergencyContactName || d.emergencyContactName || '',
        emergencyContactPhone: existing.emergencyContactPhone || d.emergencyContactPhone || '',
        emergencyRelationship: existing.emergencyRelationship || d.emergencyRelationship || 'Parent / Guardian',
        appliedVehicle: existing.appliedVehicle || d.appliedVehicle || 'Tata Ace Gold EV',
        licenseNumber: existing.licenseNumber || d.licenseNumber || '',
        employeeId: (existing.employeeId && !existing.employeeId.startsWith('AGENT-0000')) ? existing.employeeId : (d.employeeId || existing.employeeId),
        status: activeStatus,
        location: validLocation,
        speed: d.speed !== undefined ? d.speed : existing.speed,
        safetyScore: d.safetyScore ?? existing.safetyScore ?? 100,
      };
      map.set(foundKey, merged);
    } else {
      const primaryKey = normName || normEmail || normEmpId || normId;
      map.set(primaryKey, d);
    }
  }
  return Array.from(map.values());
}


