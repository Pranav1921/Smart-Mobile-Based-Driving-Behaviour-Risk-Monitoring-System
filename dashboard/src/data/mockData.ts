import { Driver, Vehicle, FleetEvent } from '@/types'

// NO MOCK DATA - Real field telemetry only
export const drivers: Driver[] = []

export const vehicles: Vehicle[] = []

export const events: FleetEvent[] = []

export const scoreTrend = {
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  fleet: [0, 0, 0, 0, 0, 0, 0],
  best: [0, 0, 0, 0, 0, 0, 0],
}

export const contextZones: any[] = []

export const FLEET_CENTER: [number, number] = [12.7749, 75.2023] // Default viewport focus

export const vehicleById = (id: string) => vehicles.find((v) => v.id === id)
export const getContextForLocation = (lat: number, lng: number) => {
  return null
}
