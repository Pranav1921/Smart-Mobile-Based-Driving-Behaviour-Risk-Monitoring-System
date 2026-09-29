import React, { createContext, useContext, ReactNode } from 'react';
import { useSocketDrivers } from './useSocketDrivers';
import { Driver, LivePothole, RuleViolation } from '@/types';
import { GeofenceZone } from '@/types/geofence';

export interface SocketContextType {
  liveDrivers: Driver[];
  livePotholes: LivePothole[];
  liveGeofences: GeofenceZone[];
  ruleViolations: RuleViolation[];
  isConnected: boolean;
  crashAlertDriver: any | null;
  setCrashAlertDriver: (d: any | null) => void;
  sosAlertDriver: any | null;
  setSosAlertDriver: (d: any | null) => void;
  deadZoneToast: { driverName: string; count: number; timestamp: string } | null;
  dismissDeadZoneToast: () => void;
  driverOnlineToast: string | null;
  jobResponseToast: string | null;
  pingedDrivers: Record<string, { time: number; responded: boolean; timedOut?: boolean }>;
  emitSafetyPing: (driverId: string) => void;
  emitLiveCamRequest: (driverId: string, active: boolean) => void;
  emitIncidentResolved: (driverId: string) => void;
  emitDriverMessage: (driverId: string, message: string) => void;
  emitAssignJob: (driverId: string, data: any) => void;
  emitCreateGeofence: (zone: Omit<GeofenceZone, 'id' | 'createdAt'>) => void;
  emitDeleteGeofence: (id: string) => void;
  emitVoiceBroadcast: (data: { message: string; priority?: string; regionName?: string }) => void;
  removeDriverLocal: (driverId: string) => void;
  liveFrame: string | null;
  setLiveFrame: (frame: string | null) => void;
  socket?: any;
  // Roadside breakdown alert & locked dashcam evidence
  breakdownAlert: {
    id: string;
    driverId: string;
    driverName: string;
    issueType: string;
    notes?: string;
    latitude: number;
    longitude: number;
    vehiclePlate?: string;
    timestamp: number;
  } | null;
  setBreakdownAlert: (alert: any | null) => void;
  latestLockedEvidence: {
    driverId: string;
    driverName?: string;
    reason: string;
    timestamp: number;
    frames: Array<{ frame: string; timestamp: number; speed: number; gForce: number }>;
  } | null;
  setLatestLockedEvidence: (evidence: any | null) => void;
  // Dedicated Driver Onboarding Requests
  pendingDrivers: any[];
  pendingCount: number;
  newRequestToast: { id: string; name: string; zone: string; time: string; count: number } | null;
  dismissNewRequestToast: () => void;
  refreshPendingDrivers: (zone?: string) => Promise<void>;
}

const defaultContext: SocketContextType = {
  liveDrivers: [],
  livePotholes: [],
  liveGeofences: [],
  ruleViolations: [],
  isConnected: false,
  crashAlertDriver: null,
  setCrashAlertDriver: () => {},
  sosAlertDriver: null,
  setSosAlertDriver: () => {},
  deadZoneToast: null,
  dismissDeadZoneToast: () => {},
  driverOnlineToast: null,
  jobResponseToast: null,
  pingedDrivers: {},
  emitSafetyPing: () => {},
  emitLiveCamRequest: () => {},
  emitIncidentResolved: () => {},
  emitDriverMessage: () => {},
  emitAssignJob: () => {},
  emitCreateGeofence: () => {},
  emitDeleteGeofence: () => {},
  emitVoiceBroadcast: () => {},
  removeDriverLocal: () => {},
  liveFrame: null,
  setLiveFrame: () => {},
  breakdownAlert: null,
  setBreakdownAlert: () => {},
  latestLockedEvidence: null,
  setLatestLockedEvidence: () => {},
  pendingDrivers: [],
  pendingCount: 0,
  newRequestToast: null,
  dismissNewRequestToast: () => {},
  refreshPendingDrivers: async () => {},
};

const SocketContext = createContext<SocketContextType | undefined>(undefined);

export function SocketProvider({ children }: { children: ReactNode }) {
  const socketData = useSocketDrivers([]);
  return <SocketContext.Provider value={socketData}>{children}</SocketContext.Provider>;
}

export function useSocket(): SocketContextType {
  const context = useContext(SocketContext);
  return context || defaultContext;
}
