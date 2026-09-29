export type VehicleType =
  | 'scooter'
  | 'motorcycle'
  | 'car'
  | 'suv'
  | 'van'
  | 'truck'
  | 'pickup'

export type DriverStatus = 'safe' | 'warning' | 'emergency' | 'idle' | 'offline' | 'leave' | 'on_leave' | 'delivery'

export type DriverType = 'TACTICAL' | 'STANDARD'

export type EventType =
  | 'overspeed'
  | 'harsh_braking'
  | 'harsh_acceleration'
  | 'sharp_turn'
  | 'crash'
  | 'phone_usage'
  | 'low_battery'
  | 'gps_lost'
  | 'rule_violation'
  | 'one_way_breach'
  | 'school_zone_speed'
  | 'pothole_hazard'

export interface LivePothole {
  id: string
  latitude: number
  longitude: number
  intensity: number
  vibrationRate?: number
  driverId?: string
  driverName?: string
  roadName?: string
  regionId?: string
  timestamp: string
}

export interface RuleViolation {
  id: string
  driverId: string
  driverName: string
  ruleType: string
  ruleTitle: string
  severity: Severity
  latitude: number
  longitude: number
  speed: number
  speedLimit: number
  roadType: string
  roadName: string
  description: string
  timestamp: string
}

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
  batteryOrFuel?: number
  plateNumber?: string
  model?: string
  driverName?: string
}

export interface Driver {
  id: string
  userId?: string
  name: string
  email?: string
  phone?: string
  licenseNumber?: string
  emergencyContactName?: string
  emergencyContactPhone?: string
  emergencyRelationship?: string
  appliedVehicle?: string
  zone?: string
  badges?: string[]
  user?: any
  employeeId: string
  photo: string
  avatar?: string
  status: DriverStatus
  driverType?: DriverType
  leaveReason?: string
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
  vehicleName?: string
  vehiclePlate?: string
  activeOrder?: any
  maxSpeedToday?: number
  orderItems?: string
  deliveryFrom?: string
  deliveryTo?: string
  startLocation?: LatLng
  endLocation?: LatLng
  accelX?: number
  accelY?: number
  accelZ?: number
  vibrationRate?: number
  gyroX?: number
  gyroY?: number
  gyroZ?: number
  magX?: number
  magY?: number
  magZ?: number
  destLat?: number
  destLng?: number
  regionId?: string
  region?: string
  points?: number
  earnings?: number
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
