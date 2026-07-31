import { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Flame, Radio, Layers } from 'lucide-react'
import { FleetMap } from '@/components/map/FleetMap'
import { VehiclePanel } from '@/components/map/VehiclePanel'
import { drivers as seedDrivers, getContextForLocation } from '@/data/mockData'
import { cn } from '@/lib/utils'
import type { Driver } from '@/types'
import { useSocketDrivers } from '@/hooks/useSocketDrivers'

const LEGEND = [
  { c: '#34d399', label: 'Safe' },
  { c: '#fbbf24', label: 'Warning' },
  { c: '#f43f5e', label: 'Emergency' },
  { c: '#60a5fa', label: 'Idle' },
]

interface ComplianceAlert {
  id: string
  driverName: string
  zoneName: string
  speed: number
  limit: number
  type: 'school' | 'traffic'
  time: string
}

export default function LiveMap() {
  const { liveDrivers: drivers, isConnected } = useSocketDrivers(seedDrivers)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [showHeat, setShowHeat] = useState(false)
  const [alerts, setAlerts] = useState<ComplianceAlert[]>([])
  const [mapMode, setMapMode] = useState<'standard' | 'satellite-traffic'>('satellite-traffic')
  const stepRef = useRef(0)

  // live movement simulation — nudge active drivers along their route ONLY when socket is disconnected
  useEffect(() => {
    if (isConnected) return;
    const t = setInterval(() => {
      // We don't have setDrivers anymore, so local simulation is effectively disabled for now.
      // In a full implementation we'd keep local simulation for mock drivers and update the mock state.
      // But since we are showing true live integration, we'll just skip simulation when connected.
    }, 2200)
    return () => clearInterval(t)
  }, [isConnected])
  // Auto-clear alerts after 4.5 seconds
  useEffect(() => {
    if (alerts.length > 0) {
      const timer = setTimeout(() => {
        setAlerts((prev) => prev.slice(0, -1))
      }, 4500)
      return () => clearTimeout(timer)
    }
  }, [alerts])

  // Check if we redirected here from global alert banner
  useEffect(() => {
    const targetId = localStorage.getItem('select_driver_id')
    if (targetId) {
      setSelectedId(targetId)
      localStorage.removeItem('select_driver_id')
    }
  }, [])

  const selected = drivers.find((d) => d.id === selectedId) ?? null

  return (
    <div className="relative h-[calc(100vh-4rem)] w-full overflow-hidden">
      {/* Live Compliance Alerts Toast Stack */}
      <div className="absolute top-20 right-4 z-[400] flex flex-col gap-2 w-72 pointer-events-none">
        <AnimatePresence>
          {alerts.map((alert) => (
            <motion.div
              key={alert.id}
              initial={{ opacity: 0, x: 60, scale: 0.92 }}
              animate={{ opacity: 1, x: 0, scale: 1 }}
              exit={{ opacity: 0, x: 60, scale: 0.95 }}
              className="glass p-3 rounded-2xl border border-rose-500/20 bg-[#0c1224]/95 shadow-2xl pointer-events-auto flex items-start gap-2.5"
            >
              <div className={cn(
                'h-8 w-8 rounded-lg grid place-items-center shrink-0 text-sm font-semibold',
                alert.type === 'school' ? 'bg-amber-500/10 text-amber-300 border border-amber-500/20' : 'bg-rose-500/10 text-rose-300 border border-rose-500/20'
              )}>
                {alert.type === 'school' ? '🏫' : '🚨'}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center justify-between">
                  <span className="text-[12px] font-semibold text-primary truncate">{alert.driverName}</span>
                  <span className="text-[9px] text-muted font-mono">{alert.time}</span>
                </div>
                <div className="text-[10.5px] text-secondary truncate mt-0.5">{alert.zoneName}</div>
                <div className="text-[11px] text-rose-400 font-medium mt-1">
                  Speeding: <span className="font-bold">{alert.speed} km/h</span> <span className="text-muted text-[10px]">(Limit: {alert.limit})</span>
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      <FleetMap drivers={drivers} selectedId={selectedId} onSelect={setSelectedId} showHeat={showHeat} mapMode={mapMode} />

      {/* top-left title & driver selector */}
      <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }}
        className="absolute top-4 left-4 z-[400] glass rounded-2xl px-4 py-3 flex items-center gap-4">
        <div className="grid place-items-center h-9 w-9 rounded-xl accent-gradient ring-glow shrink-0">
          <Radio className="h-4 w-4 text-white" />
        </div>
        <div>
          <div className="font-display font-semibold text-primary text-sm leading-none">Live Fleet Map</div>
          <div className="text-[11px] text-muted mt-1.5 flex items-center gap-1.5">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse-glow" />
            {drivers.filter((d) => d.status !== 'offline').length} active
          </div>
        </div>
        <div className="border-l border-slate-200 h-7 shrink-0" />
        <select
          value={selectedId || ''}
          onChange={(e) => setSelectedId(e.target.value || null)}
          className="h-9 rounded-xl bg-white border border-slate-200 text-[12px] text-primary px-3 outline-none focus:border-[#10b981]/40 cursor-pointer shadow-sm"
        >
          <option value="" className="bg-white text-slate-400">⚡ Quick select...</option>
          {drivers.map((d) => (
            <option key={d.id} value={d.id} className="bg-white text-primary">
              {d.name} {d.status === 'emergency' ? '🚨 Crash' : d.status === 'warning' ? '⚠️ Warning' : '🟢 Safe'}
            </option>
          ))}
        </select>
      </motion.div>

      {/* controls */}
      <div className="absolute top-4 right-4 z-[400] flex flex-col gap-2">
        <button onClick={() => setShowHeat((h) => !h)}
          className={cn('glass rounded-xl h-11 px-3.5 flex items-center gap-2 text-[13px] font-medium transition-colors',
            showHeat ? 'text-rose-600 border-rose-600/30' : 'text-secondary hover:text-primary')}>
          <Flame className="h-4 w-4" /> Heatmap
        </button>
        <div className="glass rounded-xl h-11 px-3.5 flex items-center gap-2 text-[13px] font-medium text-[#10b981] border-[#10b981]/30">
          <Layers className="h-4 w-4" /> Google Satellite
        </div>
      </div>

      {/* legend */}
      <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
        className="absolute bottom-6 left-4 z-[400] glass rounded-2xl px-4 py-3">
        <div className="text-[10px] uppercase tracking-wider text-muted mb-2">Marker Status</div>
        <div className="flex items-center gap-4">
          {LEGEND.map((l) => (
            <div key={l.label} className="flex items-center gap-1.5">
              <span className="h-2.5 w-2.5 rounded-full" style={{ background: l.c, boxShadow: `0 0 8px ${l.c}` }} />
              <span className="text-[11px] text-secondary">{l.label}</span>
            </div>
          ))}
        </div>
      </motion.div>

      {/* driver strip (bottom right) */}
      {!selected && (
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
          className="absolute bottom-6 right-4 z-[400] glass rounded-2xl p-2 hidden md:flex gap-1.5 max-w-md overflow-x-auto no-scrollbar">
          {drivers.filter((d) => d.status !== 'offline').map((d) => (
            <button key={d.id} onClick={() => setSelectedId(d.id)}
              className="shrink-0 flex items-center gap-2 px-2.5 py-2 rounded-xl hover:bg-slate-50 transition-colors">
              <span className={cn('h-2 w-2 rounded-full',
                d.status === 'safe' ? 'bg-emerald-400' : d.status === 'warning' ? 'bg-amber-400' : d.status === 'emergency' ? 'bg-rose-500' : 'bg-sky-400')} />
              <span className="text-[12px] text-primary whitespace-nowrap">{d.name.split(' ')[0]}</span>
              <span className="text-[11px] text-muted">{d.speed}</span>
            </button>
          ))}
        </motion.div>
      )}

      <VehiclePanel driver={selected} onClose={() => setSelectedId(null)} />
    </div>
  )
}
