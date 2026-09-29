import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  X, MapPin, Activity, Truck, Package, Building2
} from 'lucide-react'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { getContextForLocation } from '@/data/mockData'
import { cn, scoreColor } from '@/lib/utils'
import type { Driver } from '@/types'

interface VehiclePanelProps {
  driver: Driver | null
  onClose: () => void
}

export function VehiclePanel({ driver, onClose }: VehiclePanelProps) {
  const [routeDeviated, setRouteDeviated] = useState(false)
  const [unauthorizedStop, setUnauthorizedStop] = useState(false)

  const isEmergency = driver?.status === 'emergency'

  useEffect(() => {
    if (!driver) return
    const currentZone = getContextForLocation(driver.location.lat, driver.location.lng)
    if (driver.speed === 0 && !currentZone && driver.status !== 'offline') {
      setUnauthorizedStop(true)
    } else {
      setUnauthorizedStop(false)
    }

    if (driver.startLocation) {
      const dist = Math.sqrt(
        Math.pow(driver.location.lat - driver.startLocation.lat, 2) +
        Math.pow(driver.location.lng - driver.startLocation.lng, 2)
      ) * 111
      if (dist > 15) setRouteDeviated(true)
      else setRouteDeviated(false)
    }
  }, [driver])

  if (!driver) return null

  return (
    <AnimatePresence>
      <div className="fixed inset-y-0 right-0 z-[500] w-full md:w-[500px] bg-slate-50/98 dark:bg-slate-900/98 border-l border-slate-200 dark:border-slate-800 shadow-2xl backdrop-blur-xl flex flex-col overflow-hidden text-slate-900 dark:text-white">
        {/* Header */}
        <div className="p-5 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between bg-white dark:bg-slate-900">
          <div className="flex items-center gap-3">
            <Avatar name={(driver.name || 'Driver').replace(/\s+applicant/gi, '').trim()} size={42} />
            <div>
              <h2 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                {(driver.name || 'Driver').replace(/\s+applicant/gi, '').trim()}
                <Badge tone={driver.status}>{driver.status}</Badge>
              </h2>
              <p className="text-[10px] text-slate-500 dark:text-slate-400 font-bold uppercase tracking-wider">{driver.employeeId} · {driver.fleet || 'Smart Fleet Tactical'}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="h-8 w-8 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 grid place-items-center text-slate-400 hover:text-slate-900 dark:hover:text-white transition cursor-pointer"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Live Tracking Header Bar */}
        <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 bg-white/50 dark:bg-slate-900/50 px-5 py-3">
          <div className="flex items-center gap-2">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-ping" />
            <span className="text-xs font-black uppercase tracking-widest text-emerald-600 dark:text-emerald-400">
              Live Tracking & Telemetry
            </span>
          </div>
          <span className="text-[10px] font-mono font-bold text-slate-400">
            ID: {driver.id}
          </span>
        </div>

        {/* Panel Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* No Network Zone Notice */}
          {driver.status === 'offline' && (
            <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-300 flex items-start gap-3">
              <div className="h-2.5 w-2.5 rounded-full bg-amber-400 shrink-0 mt-1 animate-pulse" />
              <div>
                <div className="font-bold text-xs uppercase tracking-wider text-amber-400 flex items-center gap-1.5">
                  <span>📡 NO NETWORK / DEAD ZONE ACTIVE</span>
                </div>
                <div className="text-[11px] text-slate-300 mt-1 leading-relaxed">
                  Driver has entered a cellular dead zone or has mobile data switched off. Pin shows <strong>Last Known Location</strong>. Telemetry points are buffered on device and will auto-sync on reconnect.
                </div>
              </div>
            </div>
          )}

          {/* Critical Alerts Banner (if active) */}
          {(routeDeviated || unauthorizedStop || isEmergency) && (
            <div className="space-y-2">
              {isEmergency && (
                <div className="p-4 rounded-2xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-rose-600 dark:text-rose-400 flex items-start gap-3">
                  <div className="h-2.5 w-2.5 rounded-full bg-rose-500 shrink-0 mt-1.5 animate-ping" />
                  <div>
                    <div className="font-bold text-sm text-rose-700 dark:text-rose-300 uppercase tracking-tight">CRITICAL SOS ALERT</div>
                    <div className="text-[11px] text-rose-600 dark:text-rose-400 mt-1 leading-relaxed">
                      Emergency impact or manual SOS reported at [{driver.location?.lat != null ? driver.location.lat.toFixed(4) : '12.7749'}, {driver.location?.lng != null ? driver.location.lng.toFixed(4) : '75.2023'}].
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Active Delivery Mission Banner */}
          {(driver.deliveryTo || driver.orderItems || driver.destLat != null) && (
            <div className="p-4 rounded-2xl bg-gradient-to-br from-emerald-950/40 via-slate-900 to-emerald-900/20 border border-emerald-500/40 text-white shadow-xl space-y-3">
              <div className="flex items-center justify-between border-b border-emerald-500/20 pb-2.5">
                <div className="flex items-center gap-2">
                  <div className="h-6 w-6 rounded-lg bg-emerald-500/20 text-emerald-400 grid place-items-center">
                    <Truck size={13} className="animate-bounce" />
                  </div>
                  <span className="text-[10px] font-black uppercase tracking-widest text-emerald-400 flex items-center gap-1.5">
                    <span className="h-2 w-2 rounded-full bg-emerald-400 animate-ping" />
                    ON DELIVERY / CURRENT MISSION
                  </span>
                </div>
                <span className="text-[9px] font-mono font-black bg-emerald-500 text-slate-950 px-2 py-0.5 rounded-md uppercase tracking-wider">
                  ACTIVE
                </span>
              </div>

              {/* What He Is Delivering */}
              <div className="p-2.5 rounded-xl bg-slate-950/60 border border-slate-800/80">
                <div className="flex items-center gap-1 text-[9px] font-black uppercase tracking-widest text-emerald-400 mb-0.5">
                  <Package size={11} />
                  <span>Delivering (What):</span>
                </div>
                <div className="text-xs font-black text-white">
                  {driver.orderItems || 'Tactical Logistics Package (Consignment)'}
                </div>
              </div>

              {/* Route: From Who -> To Where */}
              <div className="grid grid-cols-1 gap-2 text-[11px]">
                <div className="flex items-start gap-1.5 p-2 rounded-xl bg-slate-950/40 border border-slate-800/60">
                  <Building2 size={13} className="text-sky-400 shrink-0 mt-0.5" />
                  <div>
                    <div className="text-[8.5px] font-black uppercase tracking-widest text-sky-400">From Who (Pickup):</div>
                    <div className="text-xs font-bold text-slate-200">{driver.deliveryFrom || 'Main Logistics Hub, Sector 1'}</div>
                  </div>
                </div>

                <div className="flex items-start gap-1.5 p-2 rounded-xl bg-slate-950/40 border border-slate-800/60">
                  <MapPin size={13} className="text-rose-400 shrink-0 mt-0.5" />
                  <div>
                    <div className="text-[8.5px] font-black uppercase tracking-widest text-rose-400">To Where (Destination):</div>
                    <div className="text-xs font-bold text-slate-200">{driver.deliveryTo || 'Customer Delivery Destination'}</div>
                  </div>
                </div>
              </div>

              {driver.destLat != null && driver.destLng != null && (
                <div className="flex items-center justify-between pt-1 border-t border-white/5 text-[10px] text-slate-400 font-mono">
                  <span>Target Coordinates:</span>
                  <a
                    href={`https://www.google.com/maps/dir/?api=1&destination=${driver.destLat},${driver.destLng}&travelmode=driving`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-emerald-400 font-bold hover:underline"
                  >
                    [{driver.destLat.toFixed(4)}, {driver.destLng.toFixed(4)}] ↗
                  </a>
                </div>
              )}
            </div>
          )}

          {/* Telemetry Metrics */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-2xl p-3.5 text-center shadow-sm">
              <div className="text-[9px] text-slate-400 uppercase font-black tracking-widest">Velocity</div>
              <div className="text-xl font-black text-slate-900 dark:text-white mt-1">{(driver.speed || 0).toFixed(1)} <span className="text-[10px] font-bold text-slate-400">KM/H</span></div>
            </div>
            <div className="bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-2xl p-3.5 text-center shadow-sm">
              <div className="text-[9px] text-slate-400 uppercase font-black tracking-widest">Safety</div>
              <div className="text-xl font-black mt-1" style={{ color: scoreColor(driver.safetyScore) }}>{Math.round(driver.safetyScore || 100)}%</div>
            </div>
            <div className="bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-2xl p-3.5 text-center shadow-sm">
              <div className="text-[9px] text-slate-400 uppercase font-black tracking-widest">Traveled</div>
              <div className="text-xl font-black text-slate-900 dark:text-white mt-1">{(driver.distanceToday || 0).toFixed(1)} <span className="text-[10px] font-bold text-slate-400">KM</span></div>
            </div>
          </div>

          {/* Real-time Hardware Telemetry */}
          <div className="bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-[24px] p-5 space-y-3 shadow-sm">
            <div className="flex items-center justify-between">
              <div className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Live Hardware Telemetry</div>
              <Activity size={13} className="text-emerald-500 animate-pulse" />
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">GPS Position:</span>
              <span className="font-mono text-emerald-600 dark:text-emerald-400 font-black text-xs">
                {driver.location?.lat != null ? driver.location.lat.toFixed(5) : '12.77490'}, {driver.location?.lng != null ? driver.location.lng.toFixed(5) : '75.20230'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">Vibration / Force:</span>
              <span className={cn("font-mono font-black text-xs", (driver.vibrationRate || 0) > 2.0 ? "text-rose-500 animate-pulse" : "text-amber-500")}>
                {(driver.vibrationRate || 0.1).toFixed(2)} G-Mag
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">Accel [X,Y,Z]:</span>
              <span className="text-cyan-500 dark:text-cyan-400 font-mono font-black text-xs">
                [{(driver.accelX || 0).toFixed(2)}, {(driver.accelY || 0).toFixed(2)}, {(driver.accelZ || 0).toFixed(2)}]
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">Gyro [X,Y,Z]:</span>
              <span className="text-blue-500 dark:text-blue-400 font-mono font-black text-xs">
                [{(driver.gyroX || 0).toFixed(2)}, {(driver.gyroY || 0).toFixed(2)}, {(driver.gyroZ || 0).toFixed(2)}] rad/s
              </span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">Magneto [Z]:</span>
              <span className="text-purple-500 dark:text-purple-400 font-mono font-black text-xs">
                {(driver.magZ || 0).toFixed(0)} µT
              </span>
            </div>
          </div>
        </div>
      </div>
    </AnimatePresence>
  )
}
