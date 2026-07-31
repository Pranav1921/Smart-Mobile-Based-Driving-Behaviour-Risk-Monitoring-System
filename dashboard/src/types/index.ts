export type VehicleType =
  | 'scooter'
  | 'motorcycle'
  | 'car'
  | 'suv'
  | 'van'
  | 'truck'
  | 'pickup'

export type DriverStatus = 'safe' | 'warning' | 'emergency' | 'idle' | 'offline'

export type EventType =
  | 'overspeed'
  | 'harsh_braking'
  | 'harsh_acceleration'
  | 'sharp_turn'
  | 'crash'
  | 'phone_usage'
  | 'low_battery'
  | 'gps_lost'

export type Severity = 'low' | 'medium' | 'high' | 'critical'

export interface LatLng {
  lat: number
  lng: number
}

export interface Vehicle {
  id: string
  name: string
  type: VehicleType
  registration: string
  health: number
  insuranceValid: string
}

export interface Driver {
  id: string
  name: string
  employeeId: string
  photo: string
  status: DriverStatus
  vehicleId: string
  industry: string
  fleet: string
  safetyScore: number
  riskScore: number
  crashProbability: number
  speed: number
  location: LatLng
  locationName: string
  route: LatLng[]
  distanceToday: number
  tripDurationMin: number
  drivingHours: number
  trips: number
  battery: number
  internet: number
  gps: boolean
  camera: boolean
  sensors: boolean
  ble: boolean
  overspeedCount: number
  harshBrakingCount: number
  sharpTurnCount: number
  weeklyTrend: number
  monthlyTrend: number
  drivingStyle: string
  aggressive: number
  recommendation: string
  heading: number
  orderItems?: string
  deliveryFrom?: string
  deliveryTo?: string
  startLocation?: LatLng
  endLocation?: LatLng
}

export interface FleetEvent {
  id: string
  driverId: string
  driverName: string
  vehicleReg: string
  type: EventType
  severity: Severity
  location: LatLng
  locationName: string
  time: string
  value?: string
}

export interface Kpi {
  key: string
  label: string
  value: number
  unit?: string
  decimals?: number
  delta: number
  icon: string
  tone: 'cyan' | 'electric' | 'safe' | 'warn' | 'danger'
}

export interface AiInsight {
  id: string
  tone: 'positive' | 'warning' | 'critical' | 'info'
  title: string
  detail: string
  driverId?: string
}
