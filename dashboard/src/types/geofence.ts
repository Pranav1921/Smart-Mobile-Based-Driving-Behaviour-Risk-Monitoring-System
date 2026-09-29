export interface GeofenceZone {
  id: string;
  name: string;
  type: 'school' | 'market' | 'hospital' | 'curve' | 'construction' | 'custom';
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
  speedLimitKph: number;
  color?: string;
  regionId?: string;
  createdAt?: string;
}

export const GEOFENCE_PRESETS: {
  type: GeofenceZone['type'];
  label: string;
  defaultRadius: number;
  defaultSpeedLimit: number;
  color: string;
  iconName: string;
}[] = [
  {
    type: 'school',
    label: 'School / Campus Zone',
    defaultRadius: 280,
    defaultSpeedLimit: 25,
    color: '#38bdf8',
    iconName: 'School',
  },
  {
    type: 'market',
    label: 'Market / Commercial Pedestrian Hub',
    defaultRadius: 220,
    defaultSpeedLimit: 20,
    color: '#f59e0b',
    iconName: 'ShoppingBag',
  },
  {
    type: 'hospital',
    label: 'Hospital Silence Sanctuary',
    defaultRadius: 200,
    defaultSpeedLimit: 25,
    color: '#06b6d4',
    iconName: 'HeartPulse',
  },
  {
    type: 'curve',
    label: 'Sharp Curve / Hill Pass Corridor',
    defaultRadius: 350,
    defaultSpeedLimit: 30,
    color: '#eab308',
    iconName: 'CornerUpRight',
  },
  {
    type: 'construction',
    label: 'Road Works & Construction Hazard',
    defaultRadius: 300,
    defaultSpeedLimit: 25,
    color: '#f97316',
    iconName: 'Construction',
  },
  {
    type: 'custom',
    label: 'Custom Speed Restriction Geofence',
    defaultRadius: 250,
    defaultSpeedLimit: 40,
    color: '#a855f7',
    iconName: 'Shield',
  },
];
