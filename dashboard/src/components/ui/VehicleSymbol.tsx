import React from 'react'
import { cn } from '@/lib/utils'

export type VehicleKey = 'scooter' | 'bike' | 'auto' | 'cab' | 'van'

export interface VehicleMeta {
  key: VehicleKey
  label: string
  wheelTag: '2W' | '3W' | '4W'
  wheelClass: string
  color: string
}

export function parseVehicleType(raw?: string): VehicleMeta {
  if (!raw) {
    return { key: 'scooter', label: 'Scooter', wheelTag: '2W', wheelClass: '2-Wheeler', color: '#10B981' }
  }
  const clean = raw.toLowerCase().trim()
  if (clean.includes('scoot') || clean.includes('activa') || clean.includes('jupiter') || clean.includes('vespa') || clean.includes('moped')) {
    return { key: 'scooter', label: 'Scooter', wheelTag: '2W', wheelClass: '2-Wheeler', color: '#10B981' }
  }
  if (clean.includes('bike') || clean.includes('motorcycle') || clean.includes('pulsar') || clean.includes('splendor') || clean.includes('royal')) {
    return { key: 'bike', label: 'Bike', wheelTag: '2W', wheelClass: '2-Wheeler', color: '#3B82F6' }
  }
  if (clean.includes('3-wheel') || clean.includes('auto') || clean.includes('rickshaw') || clean.includes('tuk') || clean.includes('three')) {
    return { key: 'auto', label: 'Auto Rickshaw', wheelTag: '3W', wheelClass: '3-Wheeler', color: '#F59E0B' }
  }
  if (clean.includes('cab') || clean.includes('taxi') || clean.includes('car') || clean.includes('sedan') || clean.includes('dzire') || clean.includes('etios')) {
    return { key: 'cab', label: 'Cab', wheelTag: '4W', wheelClass: '4-Wheeler', color: '#EC4899' }
  }
  if (clean.includes('van') || clean.includes('truck') || clean.includes('lcv') || clean.includes('ace') || clean.includes('delivery') || clean.includes('cargo')) {
    return { key: 'van', label: 'Delivery Van', wheelTag: '4W', wheelClass: '4-Wheeler', color: '#8B5CF6' }
  }
  return { key: 'scooter', label: raw, wheelTag: '2W', wheelClass: '2-Wheeler', color: '#10B981' }
}

interface VehicleSymbolProps {
  type?: string
  className?: string
  size?: number
  showBadge?: boolean
}

export function VehicleSymbol({ type, className = '', showBadge = true }: VehicleSymbolProps) {
  const meta = parseVehicleType(type)

  return (
    <div className={cn("inline-flex items-center gap-1.5", className)}>
      <span className="font-space font-bold text-xs tracking-tight text-foreground">
        {meta.label}
      </span>

      {showBadge && (
        <span 
          className="font-pixel text-[8px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded border"
          style={{
            color: meta.color,
            backgroundColor: `${meta.color}15`,
            borderColor: `${meta.color}35`,
          }}
        >
          {meta.wheelTag}
        </span>
      )}
    </div>
  )
}

export const VehicleNameBadge = VehicleSymbol
