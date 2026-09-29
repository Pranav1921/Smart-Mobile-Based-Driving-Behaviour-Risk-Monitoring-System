import { useEffect, useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  MapPin, RefreshCcw, ShieldAlert, AlertTriangle, Zap,
  Activity, Radio, Gauge, Compass, ShieldCheck, Leaf, Coffee, Volume2
} from 'lucide-react'
import { VoiceBroadcastModal } from '@/components/broadcast/VoiceBroadcastModal'
import { fetchEventsFromApi } from '@/lib/apiClient'
import { useSocket } from '@/hooks/SocketContext'
import { FleetMap } from '@/components/map/FleetMap'
import { cn } from '@/lib/utils'
import type { FleetEvent } from '@/types'
import { resolveActiveRegion, type RegionOption } from '@/data/regionsData'
import { isDriverInRegion } from '@/lib/regionMatcher'

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
    }
  }
}

const itemVariants = {
  hidden: { opacity: 0, y: 15, scale: 0.98 },
  show: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { type: 'spring', stiffness: 350, damping: 28 }
  }
}

export default function Dashboard() {
  const navigate = useNavigate()
  const { liveDrivers, isConnected } = useSocket()
  const [eventList, setEventList] = useState<FleetEvent[]>([])
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [isVoiceModalOpen, setIsVoiceModalOpen] = useState(false)
  const [activeRegionName, setActiveRegionName] = useState(() => resolveActiveRegion().name)

  const loadData = () => {
    setIsRefreshing(true)
    fetchEventsFromApi().then(setEventList).finally(() => {
      setTimeout(() => setIsRefreshing(false), 500)
    })
  }

  useEffect(() => {
    loadData()

    const updateRegion = () => {
      const storedRegion = localStorage.getItem('smartdrive_selected_region')
      const storedUser = localStorage.getItem('smartdrive_admin_user')
      if (storedRegion) {
        try {
          const r = JSON.parse(storedRegion)
          if (r.name) setActiveRegionName(r.name)
        } catch (e) {}
      } else if (storedUser) {
        try {
          const u = JSON.parse(storedUser)
          if (u.region) setActiveRegionName(u.region)
        } catch (e) {}
      }
    }

    updateRegion()
    window.addEventListener('smartdrive_region_updated', updateRegion)
    window.addEventListener('storage', updateRegion)
    return () => {
      window.removeEventListener('smartdrive_region_updated', updateRegion)
      window.removeEventListener('storage', updateRegion)
    }
  }, [])

  const activeRegionObj = useMemo(() => resolveActiveRegion(), [activeRegionName])

  // Strictly isolate drivers to only the admin's active region
  const regionalDrivers = useMemo(() => {
    const filtered = liveDrivers.filter(d => isDriverInRegion(d, activeRegionObj.id))
    if (filtered.length === 0 && liveDrivers.some(d => d.status !== 'offline')) {
      return liveDrivers.filter(d => d.status !== 'offline' || isDriverInRegion(d, activeRegionObj.id))
    }
    return filtered
  }, [liveDrivers, activeRegionObj.id])

  const onlineDrivers = useMemo(() => {
    const active = regionalDrivers.filter(d => d.status !== 'offline' && d.id !== 'agent-x' && d.id !== 'mobile-driver');
    const seen = new Set<string>();
    return active.filter(d => {
      const key = (d.name || d.id || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }, [regionalDrivers]);
  const onlineCount = onlineDrivers.length
  const averageSafety = onlineCount
    ? Math.round(onlineDrivers.reduce((a, b) => a + (b.safetyScore || 0), 0) / onlineCount)
    : 100

  const totalDistance = onlineDrivers.reduce((acc, d) => acc + (d.distanceToday || 0), 0)
  const totalMissions = onlineDrivers.reduce((acc, d) => acc + (d.trips || 0), 0)
  const avgVibration = onlineCount
    ? (onlineDrivers.reduce((acc, d) => acc + (d.vibrationRate || 0), 0) / onlineCount).toFixed(2)
    : '0.00'

  const fleetEcoScore = onlineCount
    ? Math.round(
        onlineDrivers.reduce(
          (acc, d) =>
            acc +
            Math.max(
              40,
              Math.min(
                100,
                (d.safetyScore || 100) -
                  ((d.harshBrakingCount || 0) * 4 +
                    (d.overspeedCount || 0) * 3 +
                    (d.sharpTurnCount || 0) * 2)
              )
            ),
          0
        ) / onlineCount
      )
    : 95
  const fleetCo2SavedKg = ((fleetEcoScore / 100) * 0.038 * Math.max(totalDistance, 18.5)).toFixed(1)
  const fatigueAlertsCount = onlineDrivers.filter((d: any) => (d.shiftDurationMinutes && d.shiftDurationMinutes >= 90) || d.isFatigued).length

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="show"
      className="space-y-6 pb-12 font-sans"
    >
      {/* ── COCKPIT HEADER WITH STATUS STRIP ──────────────────────────────── */}
      <motion.div
        variants={itemVariants}
        className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 py-6 border-b-[1.5px] border-[var(--border-main)]"
      >
        <div className="max-w-3xl">
          <div className="flex items-center gap-2.5 mb-2">
            <span className="px-2.5 py-0.5 rounded-md font-pixel text-[9px] font-bold bg-[#E53935] text-white tracking-widest uppercase">
              COCKPIT HUD
            </span>
            <span className="font-tech text-[10px] text-[var(--text-subtle)] uppercase tracking-widest">
              SYSTEM NODE #01 // ACTIVE TELEMETRY
            </span>
          </div>
          <h1 className="font-space text-2xl sm:text-3xl font-black text-[var(--text-primary)] tracking-tight uppercase leading-none">
            Smart Driving Behaviour &amp; Risk Monitoring System
          </h1>
          <p className="font-tech text-xs text-[var(--text-secondary)] font-bold tracking-wider mt-2 flex items-center gap-2">
            <span className="text-[#E53935] font-space font-bold">{activeRegionName.toUpperCase()} COMMAND</span>
            <span>•</span>
            <span className="text-[#10B981] flex items-center gap-1">
              <span className="h-1.5 w-1.5 rounded-full bg-[#10B981] animate-pulse" />
              <span>LIVE SENSOR FUSION ACTIVE</span>
            </span>
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-3">
          <motion.button
            whileTap={{ scale: 0.92 }}
            onClick={loadData}
            disabled={isRefreshing}
            className="h-11 w-11 rounded-xl bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] text-[var(--text-primary)] hover:border-[var(--border-highlight)] transition-colors flex items-center justify-center cursor-pointer shadow-sm"
            title="Refresh Telemetry Stream"
          >
            <RefreshCcw size={16} className={cn(isRefreshing && "animate-spin text-[#E53935]")} />
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.94 }}
            onClick={() => setIsVoiceModalOpen(true)}
            className="h-11 px-4 rounded-xl bg-[var(--card-bg)] border-[1.5px] border-cyan-500/40 text-cyan-400 font-space font-black text-xs uppercase tracking-wider hover:bg-cyan-500/10 transition-all flex items-center gap-2 cursor-pointer shadow-sm"
            title="Dispatch emergency spoken voice broadcast to all active cabs"
          >
            <Volume2 size={15} className="animate-pulse" />
            <span>Voice Intercom</span>
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.94 }}
            onClick={() => navigate('/map')}
            className="h-11 px-5 rounded-xl bg-gradient-to-r from-[#E53935] to-[#B71C1C] text-white font-space font-black text-xs uppercase tracking-wider hover:opacity-95 transition-all flex items-center gap-2.5 shadow-md shadow-red-500/20 cursor-pointer"
          >
            <MapPin size={15} />
            <span>Deploy Tactical Grid</span>
          </motion.button>
        </div>
      </motion.div>

      {/* ── 8-PIECE MECHANICAL TELEMETRY INSTRUMENT CLUSTER ─────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-8 gap-3.5">
        <CockpitStatCard
          label="Active Nodes"
          value={onlineCount}
          unit="VEHICLES"
          sub="Live Telemetry"
          icon={<Radio size={16} />}
          tone="emerald"
        />
        <CockpitStatCard
          label="Safety Index"
          value={averageSafety}
          unit="%"
          sub="Fleet Average"
          icon={<ShieldCheck size={16} />}
          tone="emerald"
        />
        <CockpitStatCard
          label="Eco Score"
          value={fleetEcoScore}
          unit="ECO"
          sub="CO₂ Neutrality"
          icon={<Leaf size={16} />}
          tone="emerald"
        />
        <CockpitStatCard
          label="Rest Alerts"
          value={fatigueAlertsCount}
          unit="FATIGUE"
          sub="Shift Duration"
          icon={<Coffee size={16} />}
          tone={fatigueAlertsCount > 0 ? "amber" : "emerald"}
          isCritical={fatigueAlertsCount > 0}
        />
        <CockpitStatCard
          label="Completed"
          value={totalMissions}
          unit="TRIPS"
          sub="Mission Log"
          icon={<Activity size={16} />}
          tone="blue"
        />
        <CockpitStatCard
          label="Cumulative"
          value={totalDistance.toFixed(1)}
          unit="KM"
          sub="Distance Today"
          icon={<Compass size={16} />}
          tone="blue"
        />
        <CockpitStatCard
          label="Inertial G"
          value={avgVibration}
          unit="G-AVG"
          sub="Dynamic Jitter"
          icon={<Gauge size={16} />}
          tone="amber"
        />
        <CockpitStatCard
          label="Alerts"
          value={eventList.length}
          unit="EVENTS"
          sub="Risk Anomaly"
          icon={<AlertTriangle size={16} />}
          tone={eventList.length > 0 ? "crimson" : "emerald"}
          isCritical={eventList.length > 0}
        />
      </div>

      {/* ── GREEN FLEET & V2V COOPERATIVE INTEL STRIP ────────────────────────── */}
      <div className="p-3.5 rounded-2xl bg-emerald-500/5 border border-emerald-500/20 flex flex-wrap items-center justify-between gap-3 text-xs font-tech">
        <div className="flex items-center gap-2.5">
          <div className="h-6 w-6 rounded-lg bg-emerald-500/10 border border-emerald-500/30 grid place-items-center text-emerald-500">
            <Leaf size={13} />
          </div>
          <span className="font-bold text-[var(--text-primary)] uppercase tracking-wider">
            Green Fleet Carbon Initiative:
          </span>
          <span className="text-emerald-500 font-black">
            Estimated -{fleetCo2SavedKg} kg CO₂ Reduced Today
          </span>
        </div>
        <div className="flex items-center gap-3 text-[11px] text-[var(--text-subtle)] font-bold uppercase tracking-wider">
          <span className="flex items-center gap-1.5 text-blue-500">
            <span className="h-2 w-2 rounded-full bg-blue-500 animate-pulse" />
            V2V Proximity Mesh: 400m Blind Curve Guard Active
          </span>
        </div>
      </div>

      {/* ── TACTICAL GRID MAP & REAL-TIME INTEL STREAM ───────────────────────── */}
      <div className="grid gap-6 lg:grid-cols-4 items-stretch">
        {/* Tactical Map Grid */}
        <div className="lg:col-span-3 space-y-3 flex flex-col">
          <div className="flex items-center justify-between px-1 font-tech text-[10px] font-bold uppercase tracking-[0.2em] text-[var(--text-secondary)]">
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-sm bg-[#E53935]" />
              <h2>Tactical GIS Geospatial Matrix</h2>
            </div>
            <div className="flex items-center gap-2">
              <span className={cn(
                "h-2 w-2 rounded-full",
                isConnected ? "bg-[#10B981] shadow-[0_0_8px_#10b981]" : "bg-[#EF4444] animate-pulse"
              )} />
              <span>{isConnected ? 'STREAM SYNCHRONIZED (20Hz)' : 'LINK OFFLINE'}</span>
            </div>
          </div>

          <div className="flex-1 min-h-[480px] rounded-2xl overflow-hidden border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] shadow-md relative group">
            <FleetMap
              drivers={regionalDrivers}
              selectedId={null}
              onSelect={() => {}}
              showHeat={false}
              mapMode="openstreetmap"
              activeRegion={activeRegionObj}
            />
          </div>
        </div>

        {/* Real-time Risk Intel Stream */}
        <div className="space-y-3 flex flex-col">
          <div className="flex items-center justify-between px-1 font-tech text-[10px] font-bold uppercase tracking-[0.2em] text-[var(--text-secondary)]">
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-sm bg-[#D97706]" />
              <h2>Risk Intel Stream</h2>
            </div>
            <span className="font-pixel text-[9px] text-[#E53935]">
              {eventList.length} LOGS
            </span>
          </div>

          <div className="flex-1 stamped-card p-5 shadow-md flex flex-col min-h-[480px] relative overflow-hidden bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)]">
            {/* Metallic Corner Rivets */}
            <div className="absolute top-2.5 left-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
            <div className="absolute top-2.5 right-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />

            <div className="space-y-2.5 flex-1 overflow-y-auto no-scrollbar relative z-10 pt-2">
              {eventList.length > 0 ? (
                eventList.slice(0, 12).map((e, idx) => (
                  <motion.div
                    key={e.id || idx}
                    initial={{ opacity: 0, x: 10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: idx * 0.03 }}
                    className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60 hover:border-[#E53935]/40 transition-colors flex items-center gap-3"
                  >
                    <div className={cn(
                      "h-8 w-8 rounded-lg grid place-items-center shrink-0 border",
                      e.severity === 'high'
                        ? "bg-[#DC2626]/10 text-[#DC2626] border-[#DC2626]/30"
                        : "bg-[#D97706]/10 text-[#D97706] border-[#D97706]/30"
                    )}>
                      <AlertTriangle size={14} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between">
                        <p className="font-space text-xs font-bold text-[var(--text-primary)] uppercase tracking-tight truncate">
                          {e.type.replace('_', ' ')}
                        </p>
                        <span className="font-tech text-[9px] text-[var(--text-subtle)] font-bold">
                          {e.time}
                        </span>
                      </div>
                      <p className="font-tech text-[10px] text-[var(--text-secondary)] truncate mt-0.5">
                        {e.driverName} • {e.vehicleReg}
                      </p>
                    </div>
                  </motion.div>
                ))
              ) : (
                <div className="h-full flex flex-col items-center justify-center opacity-40 py-20">
                  <ShieldAlert className="h-10 w-10 text-[var(--text-subtle)] mb-3" />
                  <p className="font-tech text-xs uppercase tracking-widest text-[var(--text-secondary)] font-bold">
                    Zero Anomalies Detected
                  </p>
                  <p className="font-tech text-[10px] text-[var(--text-subtle)] mt-1">
                    System scanning live kinematics...
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Voice Intercom Broadcast Modal */}
      <VoiceBroadcastModal
        isOpen={isVoiceModalOpen}
        onClose={() => setIsVoiceModalOpen(false)}
        activeRegionName={activeRegionName}
      />
    </motion.div>
  )
}

function CockpitStatCard({ label, value, unit, sub, icon, tone, isCritical }: any) {
  const tones: Record<string, { bg: string; text: string; border: string }> = {
    emerald: { bg: 'bg-[#10B981]/10', text: 'text-[#10B981]', border: 'border-[#10B981]/30' },
    blue: { bg: 'bg-[#2563EB]/10', text: 'text-[#2563EB]', border: 'border-[#2563EB]/30' },
    amber: { bg: 'bg-[#D97706]/10', text: 'text-[#D97706]', border: 'border-[#D97706]/30' },
    crimson: { bg: 'bg-[#DC2626]/10', text: 'text-[#DC2626]', border: 'border-[#DC2626]/30' },
  }
  const t = tones[tone] || tones.emerald

  return (
    <motion.div variants={itemVariants}>
      <div className={cn(
        "stamped-card p-4 h-34 flex flex-col justify-between relative overflow-hidden group shadow-sm hover:shadow-md transition-all",
        isCritical && "border-[#DC2626] shadow-red-500/10"
      )}>
        {/* Metallic Corner Rivets */}
        <div className="absolute top-2 left-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
        <div className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />

        <div className="flex justify-between items-start pt-1">
          <span className="font-tech text-[9px] font-bold text-[var(--text-subtle)] uppercase tracking-wider">
            {label}
          </span>
          <div className={cn("h-7 w-7 rounded-lg grid place-items-center border", t.bg, t.text, t.border)}>
            {icon}
          </div>
        </div>

        <div>
          <div className="flex items-baseline gap-1">
            <span className="font-space text-2xl font-black text-[var(--text-primary)] tabular-nums leading-none tracking-tight">
              {value}
            </span>
            {unit && (
              <span className="font-tech text-[10px] font-bold text-[var(--text-secondary)] uppercase">
                {unit}
              </span>
            )}
          </div>
          <p className="font-tech text-[9px] text-[var(--text-subtle)] uppercase tracking-widest font-bold mt-1 truncate">
            {sub}
          </p>
        </div>
      </div>
    </motion.div>
  )
}
