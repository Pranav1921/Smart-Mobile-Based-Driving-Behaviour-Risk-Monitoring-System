import type { Driver, FleetEvent, Kpi, AiInsight, Vehicle } from '@/types'

/* Region: Mangalore / NH66 coastal corridor, Karnataka, India */
export const FLEET_CENTER: [number, number] = [12.9141, 74.856]

function route(base: [number, number], n = 8, spread = 0.012): { lat: number; lng: number }[] {
  const pts: { lat: number; lng: number }[] = []
  let [lat, lng] = base
  for (let i = 0; i < n; i++) {
    lat += (Math.sin(i * 1.3) * spread) / n
    lng += (Math.cos(i * 0.9) * spread) / n + spread / n
    pts.push({ lat, lng })
  }
  return pts
}

export const vehicles: Vehicle[] = [
  { id: 'v1', name: 'Honda Activa 6G', type: 'scooter', registration: 'KA-19-EK-4821', health: 92, insuranceValid: '2026-11-04' },
  { id: 'v2', name: 'Bajaj Pulsar 150', type: 'motorcycle', registration: 'KA-19-HA-9033', health: 81, insuranceValid: '2026-03-22' },
  { id: 'v3', name: 'Tata Ace Gold', type: 'truck', registration: 'KA-19-C-7741', health: 74, insuranceValid: '2025-12-30' },
  { id: 'v4', name: 'Maruti Eeco Cargo', type: 'van', registration: 'KA-19-B-2290', health: 88, insuranceValid: '2026-06-18' },
  { id: 'v5', name: 'Mahindra Bolero', type: 'suv', registration: 'KA-19-N-5567', health: 79, insuranceValid: '2026-02-10' },
  { id: 'v6', name: 'Hero Splendor+', type: 'motorcycle', registration: 'KA-19-HB-1204', health: 95, insuranceValid: '2026-09-01' },
  { id: 'v7', name: 'Ashok Leyland Dost', type: 'pickup', registration: 'KA-19-D-8890', health: 68, insuranceValid: '2025-11-15' },
  { id: 'v8', name: 'Tata Nexon EV', type: 'car', registration: 'KA-19-EV-3311', health: 97, insuranceValid: '2027-01-08' },
]

export const drivers: Driver[] = [
  {
    id: 'd1', name: 'Rahul Shetty', employeeId: 'FG-0142', photo: '', status: 'safe', vehicleId: 'v1',
    industry: 'Food Delivery', fleet: 'Swiggy · Mangalore Hub', safetyScore: 91, riskScore: 12, crashProbability: 3,
    speed: 38, location: { lat: 12.9141, lng: 74.856 }, locationName: 'Hampankatta, Mangalore',
    route: route([12.905, 74.842]), distanceToday: 47.3, tripDurationMin: 96, drivingHours: 5.4, trips: 14,
    battery: 82, internet: 91, gps: true, camera: true, sensors: true, ble: false,
    overspeedCount: 1, harshBrakingCount: 2, sharpTurnCount: 1, weeklyTrend: 14, monthlyTrend: 9,
    drivingStyle: 'Smooth & Defensive', aggressive: 14, heading: 62,
    recommendation: 'Excellent consistency. Maintain gentle braking near market zones to stay above 90.',
    orderItems: '3x Peri Peri Fries, 2x Chicken Burger',
    deliveryFrom: 'Swadeshi Kitchens',
    deliveryTo: 'Hampankatta Towers',
    startLocation: { lat: 12.905, lng: 74.842 },
    endLocation: { lat: 12.918, lng: 74.865 },
  },
  {
    id: 'd2', name: 'Imran Khan', employeeId: 'FG-0088', photo: '', status: 'warning', vehicleId: 'v2',
    industry: 'Food Delivery', fleet: 'Zomato · Coastal', safetyScore: 74, riskScore: 41, crashProbability: 18,
    speed: 67, location: { lat: 12.925, lng: 74.848 }, locationName: 'NH66 · Kottara Junction',
    route: route([12.918, 74.838], 9, 0.02), distanceToday: 88.1, tripDurationMin: 141, drivingHours: 7.1, trips: 9,
    battery: 44, internet: 63, gps: true, camera: true, sensors: true, ble: false,
    overspeedCount: 6, harshBrakingCount: 5, sharpTurnCount: 4, weeklyTrend: -6, monthlyTrend: -2,
    drivingStyle: 'Assertive', aggressive: 58, heading: 118,
    recommendation: 'Repeated overspeed on NH66. Recommend speed-cap coaching and route rest breaks.',
    orderItems: '1x Loaded Cheese Pizza, 1x Garlic Bread',
    deliveryFrom: 'Pizza Hut, Kottara',
    deliveryTo: 'Kottara Junction Offices',
    startLocation: { lat: 12.918, lng: 74.838 },
    endLocation: { lat: 12.928, lng: 74.852 },
  },
  {
    id: 'd3', name: 'Suresh Nayak', employeeId: 'FG-0203', photo: '', status: 'emergency', vehicleId: 'v3',
    industry: 'Food Delivery', fleet: 'Swiggy · Delivery Core', safetyScore: 58, riskScore: 72, crashProbability: 61,
    speed: 0, location: { lat: 12.9142, lng: 74.8631 }, locationName: 'NH66 · Bunts Hostel Road',
    route: [
      { lat: 12.92605156980242, lng: 74.85825694920513 },
      { lat: 12.92180, lng: 74.85950 },
      { lat: 12.91810, lng: 74.86120 },
      { lat: 12.91420, lng: 74.86310 },
      { lat: 12.91100, lng: 74.86520 },
      { lat: 12.90923519348556, lng: 74.86683525229002 }
    ],
    distanceToday: 112.4, tripDurationMin: 188, drivingHours: 8.6, trips: 6,
    battery: 12, internet: 28, gps: true, camera: true, sensors: false, ble: false,
    overspeedCount: 9, harshBrakingCount: 8, sharpTurnCount: 6, weeklyTrend: -11, monthlyTrend: -7,
    drivingStyle: 'Aggressive', aggressive: 82, heading: 200,
    recommendation: 'CRASH pattern detected — vehicle stationary after high-G event. Dispatch response team.',
    orderItems: '2x Swadeshi Special Biryani, 1x Butter Naan',
    deliveryFrom: 'Swadeshi Kitchens, Kottara',
    deliveryTo: 'Kadri Heights, Mangalore',
    startLocation: { lat: 12.92605156980242, lng: 74.85825694920513 },
    endLocation: { lat: 12.90923519348556, lng: 74.86683525229002 },
  },
  {
    id: 'd4', name: 'Anita Rao', employeeId: 'FG-0311', photo: '', status: 'safe', vehicleId: 'v4',
    industry: 'Food Delivery', fleet: 'EatFit · Mangalore', safetyScore: 88, riskScore: 19, crashProbability: 6,
    speed: 44, location: { lat: 12.900, lng: 74.865 }, locationName: 'Kadri, Mangalore',
    route: route([12.895, 74.858]), distanceToday: 61.9, tripDurationMin: 120, drivingHours: 6.0, trips: 21,
    battery: 76, internet: 88, gps: true, camera: true, sensors: true, ble: true,
    overspeedCount: 2, harshBrakingCount: 1, sharpTurnCount: 2, weeklyTrend: 7, monthlyTrend: 11,
    drivingStyle: 'Smooth', aggressive: 21, heading: 300,
    recommendation: 'Strong performer. Eligible for the monthly safe-driver incentive tier.',
    orderItems: '1x Veg Biryani, 1x Paneer Tikka',
    deliveryFrom: 'Sagar Ratna, Kadri',
    deliveryTo: 'Kadri Hills Residency',
    startLocation: { lat: 12.895, lng: 74.858 },
    endLocation: { lat: 12.905, lng: 74.872 },
  },
  {
    id: 'd5', name: 'Vikram Bhat', employeeId: 'FG-0157', photo: '', status: 'idle', vehicleId: 'v5',
    industry: 'Food Delivery', fleet: 'Dunzo · Delivery', safetyScore: 83, riskScore: 24, crashProbability: 8,
    speed: 0, location: { lat: 12.870, lng: 74.843 }, locationName: 'Pumpwell Circle',
    route: route([12.866, 74.840]), distanceToday: 33.5, tripDurationMin: 74, drivingHours: 3.9, trips: 11,
    battery: 91, internet: 79, gps: true, camera: false, sensors: true, ble: false,
    overspeedCount: 2, harshBrakingCount: 3, sharpTurnCount: 1, weeklyTrend: 3, monthlyTrend: 5,
    drivingStyle: 'Balanced', aggressive: 27, heading: 15,
    recommendation: 'Idle at Pumpwell 12 min. Camera offline — prompt driver to re-enable.',
    orderItems: '2x South Indian Thali',
    deliveryFrom: 'Woodlands Restaurant',
    deliveryTo: 'Pumpwell Apts',
    startLocation: { lat: 12.866, lng: 74.840 },
    endLocation: { lat: 12.875, lng: 74.848 },
  },
  {
    id: 'd6', name: 'Fathima Zohra', employeeId: 'FG-0402', photo: '', status: 'safe', vehicleId: 'v6',
    industry: 'Food Delivery', fleet: 'Zomato · Mangalore Core', safetyScore: 94, riskScore: 8, crashProbability: 2,
    speed: 29, location: { lat: 12.882, lng: 74.870 }, locationName: 'Bendoorwell',
    route: route([12.878, 74.864]), distanceToday: 39.7, tripDurationMin: 88, drivingHours: 4.6, trips: 18,
    battery: 88, internet: 94, gps: true, camera: true, sensors: true, ble: false,
    overspeedCount: 0, harshBrakingCount: 1, sharpTurnCount: 0, weeklyTrend: 5, monthlyTrend: 8,
    drivingStyle: 'Very Smooth', aggressive: 9, heading: 240,
    recommendation: 'Top-ranked this week. Zero overspeed events across 18 trips.',
    orderItems: '1x Butter Chicken, 2x Roti',
    deliveryFrom: 'Moti Mahal Restaurant',
    deliveryTo: 'Bendoorwell Residency',
    startLocation: { lat: 12.878, lng: 74.864 },
    endLocation: { lat: 12.888, lng: 74.878 },
  },
  {
    id: 'd7', name: 'Ganesh Poojary', employeeId: 'FG-0129', photo: '', status: 'warning', vehicleId: 'v7',
    industry: 'Food Delivery', fleet: 'Dunzo · Hub', safetyScore: 69, riskScore: 47, crashProbability: 22,
    speed: 52, location: { lat: 12.948, lng: 74.878 }, locationName: 'NH66 · Baikampady',
    route: route([12.942, 74.870], 9, 0.02), distanceToday: 95.2, tripDurationMin: 160, drivingHours: 7.8, trips: 7,
    battery: 57, internet: 51, gps: false, camera: true, sensors: true, ble: false,
    overspeedCount: 5, harshBrakingCount: 6, sharpTurnCount: 5, weeklyTrend: -4, monthlyTrend: 1,
    drivingStyle: 'Assertive', aggressive: 52, heading: 88,
    recommendation: 'GPS intermittent near Baikampady. Verify mount and antenna line-of-sight.',
    orderItems: '5x Egg Puffs, 5x Tea',
    deliveryFrom: 'Baikampady Bakery',
    deliveryTo: 'Baikampady Industrial Hub',
    startLocation: { lat: 12.942, lng: 74.870 },
    endLocation: { lat: 12.952, lng: 74.882 },
  },
  {
    id: 'd8', name: 'Deepa Kamath', employeeId: 'FG-0356', photo: '', status: 'safe', vehicleId: 'v8',
    industry: 'Food Delivery', fleet: 'Swiggy · Kankanady', safetyScore: 90, riskScore: 14, crashProbability: 4,
    speed: 41, location: { lat: 12.860, lng: 74.860 }, locationName: 'Kankanady',
    route: route([12.856, 74.854]), distanceToday: 54.0, tripDurationMin: 108, drivingHours: 5.1, trips: 12,
    battery: 69, internet: 90, gps: true, camera: true, sensors: true, ble: true,
    overspeedCount: 1, harshBrakingCount: 2, sharpTurnCount: 1, weeklyTrend: 6, monthlyTrend: 7,
    drivingStyle: 'Smooth & Defensive', aggressive: 16, heading: 340,
    recommendation: 'EV fleet leader. Regenerative braking usage optimal — share as best practice.',
    orderItems: '1x Chicken Fried Rice',
    deliveryFrom: 'Chinese Wok, Kankanady',
    deliveryTo: 'Kankanady Officers Quarters',
    startLocation: { lat: 12.856, lng: 74.854 },
    endLocation: { lat: 12.865, lng: 74.868 },
  },
]

export const events: FleetEvent[] = [
  { id: 'e1', driverId: 'd3', driverName: 'Suresh Nayak', vehicleReg: 'KA-19-C-7741', type: 'crash', severity: 'critical', location: { lat: 12.936, lng: 74.867 }, locationName: 'NH66 · Surathkal Flyover', time: '2 min ago', value: '4.8 G impact' },
  { id: 'e2', driverId: 'd2', driverName: 'Imran Khan', vehicleReg: 'KA-19-HA-9033', type: 'overspeed', severity: 'high', location: { lat: 12.925, lng: 74.848 }, locationName: 'NH66 · Kottara', time: '4 min ago', value: '94 km/h' },
  { id: 'e3', driverId: 'd7', driverName: 'Ganesh Poojary', vehicleReg: 'KA-19-D-8890', type: 'gps_lost', severity: 'medium', location: { lat: 12.948, lng: 74.878 }, locationName: 'Baikampady', time: '6 min ago' },
  { id: 'e4', driverId: 'd3', driverName: 'Suresh Nayak', vehicleReg: 'KA-19-C-7741', type: 'low_battery', severity: 'high', location: { lat: 12.936, lng: 74.867 }, locationName: 'Surathkal', time: '7 min ago', value: '12%' },
  { id: 'e5', driverId: 'd2', driverName: 'Imran Khan', vehicleReg: 'KA-19-HA-9033', type: 'harsh_braking', severity: 'medium', location: { lat: 12.920, lng: 74.845 }, locationName: 'Kottara Junction', time: '11 min ago', value: '-0.62 g' },
  { id: 'e6', driverId: 'd7', driverName: 'Ganesh Poojary', vehicleReg: 'KA-19-D-8890', type: 'sharp_turn', severity: 'medium', location: { lat: 12.945, lng: 74.872 }, locationName: 'Baikampady Rd', time: '15 min ago', value: '138°/s' },
  { id: 'e7', driverId: 'd5', driverName: 'Vikram Bhat', vehicleReg: 'KA-19-N-5567', type: 'phone_usage', severity: 'low', location: { lat: 12.870, lng: 74.843 }, locationName: 'Pumpwell', time: '22 min ago', value: '18 s' },
  { id: 'e8', driverId: 'd1', driverName: 'Rahul Shetty', vehicleReg: 'KA-19-EK-4821', type: 'harsh_acceleration', severity: 'low', location: { lat: 12.910, lng: 74.850 }, locationName: 'Hampankatta', time: '28 min ago', value: '+0.55 g' },
  { id: 'e9', driverId: 'd4', driverName: 'Anita Rao', vehicleReg: 'KA-19-B-2290', type: 'overspeed', severity: 'low', location: { lat: 12.900, lng: 74.865 }, locationName: 'Kadri', time: '34 min ago', value: '61 km/h' },
  { id: 'e10', driverId: 'd8', driverName: 'Deepa Kamath', vehicleReg: 'KA-19-EV-3311', type: 'sharp_turn', severity: 'low', location: { lat: 12.860, lng: 74.860 }, locationName: 'Kankanady', time: '41 min ago', value: '96°/s' },
]

export const kpis: Kpi[] = [
  { key: 'fleetScore', label: 'Fleet Safety Score', value: 84.2, decimals: 1, delta: 3.1, icon: 'shield', tone: 'cyan' },
  { key: 'online', label: 'Drivers Online', value: 6, delta: 2, icon: 'users', tone: 'electric' },
  { key: 'active', label: 'Vehicles Active', value: 6, delta: 1, icon: 'truck', tone: 'electric' },
  { key: 'running', label: 'Trips Running', value: 5, delta: 1, icon: 'route', tone: 'cyan' },
  { key: 'distance', label: 'Distance Today', value: 531.9, unit: 'km', decimals: 1, delta: 12.4, icon: 'gauge', tone: 'safe' },
  { key: 'events', label: 'Events Today', value: 37, delta: -8, icon: 'activity', tone: 'warn' },
  { key: 'critical', label: 'Critical Alerts', value: 1, delta: 1, icon: 'alert', tone: 'danger' },
  { key: 'avgScore', label: 'Avg Driver Score', value: 80.9, decimals: 1, delta: 1.7, icon: 'star', tone: 'cyan' },
  { key: 'weekly', label: 'Weekly Improvement', value: 4.8, unit: '%', decimals: 1, delta: 4.8, icon: 'trendup', tone: 'safe' },
  { key: 'monthly', label: 'Monthly Improvement', value: 6.3, unit: '%', decimals: 1, delta: 6.3, icon: 'chart', tone: 'safe' },
]

export const aiInsights: AiInsight[] = [
  { id: 'i1', tone: 'critical', title: 'Crash pattern near NH66 · Surathkal', detail: 'Suresh Nayak — 4.8G impact, vehicle stationary 2 min. Response team dispatch recommended.', driverId: 'd3' },
  { id: 'i2', tone: 'warning', title: '2 drivers require attention', detail: 'Imran Khan and Ganesh Poojary show rising overspeed frequency on the NH66 corridor.', driverId: 'd2' },
  { id: 'i3', tone: 'positive', title: 'Driver Rahul improved by 14%', detail: 'Safety score up week-over-week — smoother braking near market zones is driving the gain.', driverId: 'd1' },
  { id: 'i4', tone: 'warning', title: 'GPS disconnected', detail: 'Ganesh Poojary — signal intermittent near Baikampady. Check device mount and antenna.', driverId: 'd7' },
  { id: 'i5', tone: 'critical', title: 'Phone battery critically low', detail: 'Suresh Nayak at 12%. Telemetry loss risk within ~20 min at current drain.', driverId: 'd3' },
  { id: 'i6', tone: 'info', title: 'Crash probability rising near NH66', detail: 'Model predicts +23% incident likelihood on the Surathkal–Baikampady stretch this evening.', driverId: 'd2' },
]

export const scoreTrend = {
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  fleet: [79, 80, 78, 82, 83, 82, 84],
  best: [88, 89, 91, 90, 92, 93, 94],
}

export const eventBreakdown = {
  labels: ['Overspeed', 'Harsh Brake', 'Sharp Turn', 'Harsh Accel', 'Phone Use', 'Crash'],
  values: [14, 9, 7, 4, 2, 1],
}

export function driverById(id?: string): Driver | undefined {
  return drivers.find((d) => d.id === id)
}
export function vehicleById(id?: string): Vehicle | undefined {
  return vehicles.find((v) => v.id === id)
}

export interface ContextZone {
  id: string
  name: string
  type: 'school' | 'traffic'
  lat: number
  lng: number
  radiusMeters: number
  speedLimit: number
}

export const contextZones: ContextZone[] = [
  { id: 'z1', name: 'Hampankatta School Zone', type: 'school', lat: 12.9141, lng: 74.856, radiusMeters: 400, speedLimit: 30 },
  { id: 'z2', name: 'Kadri Primary School Zone', type: 'school', lat: 12.9000, lng: 74.865, radiusMeters: 300, speedLimit: 30 },
  { id: 'z3', name: 'Kottara Junction Traffic Zone', type: 'traffic', lat: 12.9250, lng: 74.848, radiusMeters: 450, speedLimit: 20 },
  { id: 'z4', name: 'Baikampady Industrial Traffic Zone', type: 'traffic', lat: 12.9480, lng: 74.878, radiusMeters: 550, speedLimit: 20 },
]

export function getDistanceMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const dy = (lat1 - lat2) * 111132.9;
  const dx = (lng1 - lng2) * 111132.9 * Math.cos(lat1 * Math.PI / 180);
  return Math.sqrt(dx * dx + dy * dy);
}

export function getContextForLocation(lat: number, lng: number): ContextZone | null {
  for (const zone of contextZones) {
    const dist = getDistanceMeters(lat, lng, zone.lat, zone.lng)
    if (dist <= zone.radiusMeters) {
      return zone
    }
  }
  return null
}

