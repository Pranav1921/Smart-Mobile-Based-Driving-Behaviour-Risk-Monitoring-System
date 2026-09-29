import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Gauge, TrendingDown, CornerUpRight, ShieldAlert, Smartphone, BatteryLow,
  SatelliteDish, Zap, Activity, Search, RefreshCw, Trash2, X, CheckCircle2,
  AlertTriangle, Radio
} from 'lucide-react'
import { fetchEventsFromApi } from '@/lib/apiClient'
import { useSocket } from '@/hooks/SocketContext'
import { cn } from '@/lib/utils'
import type { EventType, FleetEvent, Severity } from '@/types'

const META: Record<EventType, { icon: React.ElementType; label: string; color: string; bg: string }> = {
  overspeed: { icon: Gauge, label: 'Overspeed Alert', color: '#EF4444', bg: 'rgba(239, 68, 68, 0.12)' },
  harsh_braking: { icon: TrendingDown, label: 'Harsh Braking', color: '#F59E0B', bg: 'rgba(245, 158, 11, 0.12)' },
  harsh_acceleration: { icon: Zap, label: 'Rapid Acceleration', color: '#10B981', bg: 'rgba(16, 185, 129, 0.12)' },
  sharp_turn: { icon: CornerUpRight, label: 'Aggressive Cornering', color: '#8B5CF6', bg: 'rgba(139, 92, 246, 0.12)' },
  crash: { icon: ShieldAlert, label: 'Critical SOS / Impact', color: '#F43F5E', bg: 'rgba(244, 63, 94, 0.15)' },
  phone_usage: { icon: Smartphone, label: 'Driver Distraction', color: '#3B82F6', bg: 'rgba(59, 130, 246, 0.12)' },
  low_battery: { icon: BatteryLow, label: 'Device Low Power', color: '#F97316', bg: 'rgba(249, 115, 22, 0.12)' },
  gps_lost: { icon: SatelliteDish, label: 'Signal Interruption', color: '#64748B', bg: 'rgba(100, 116, 139, 0.12)' },
  rule_violation: { icon: ShieldAlert, label: 'Traffic Rule Breach', color: '#E11D48', bg: 'rgba(225, 29, 72, 0.15)' },
  one_way_breach: { icon: CornerUpRight, label: 'One-Way Violation', color: '#8B5CF6', bg: 'rgba(139, 92, 246, 0.15)' },
  school_zone_speed: { icon: Gauge, label: 'School Zone Speeding', color: '#F59E0B', bg: 'rgba(245, 158, 11, 0.15)' },
  pothole_hazard: { icon: Activity, label: 'Severe Road Hazard', color: '#F43F5E', bg: 'rgba(244, 63, 94, 0.15)' },
}

const SEVERITIES: (Severity | 'all')[] = ['all', 'critical', 'high', 'medium', 'low']

export default function Events() {
  const { liveDrivers, crashAlertDriver, sosAlertDriver, ruleViolations } = useSocket()
  const [eventList, setEventList] = useState<FleetEvent[]>([])
  const [sev, setSev] = useState<Severity | 'all'>('all')
  const [searchTerm, setSearchTerm] = useState('')
  const [isRefreshing, setIsRefreshing] = useState(false)

  const loadEvents = () => {
    setIsRefreshing(true)
    fetchEventsFromApi()
      .then((data) => {
        setEventList(data)
      })
      .finally(() => {
        setTimeout(() => setIsRefreshing(false), 400)
      })
  }

  useEffect(() => {
    loadEvents()
  }, [])

  // Listen for real-time incoming rule violation alerts
  useEffect(() => {
    if (ruleViolations.length > 0) {
      const latest = ruleViolations[0]
      const eventType: EventType = latest.ruleType === 'ONE_WAY_BREACH' 
        ? 'one_way_breach' 
        : latest.ruleType === 'SCHOOL_ZONE_SPEEDING' 
        ? 'school_zone_speed' 
        : 'rule_violation'

      const newEvt: FleetEvent = {
        id: latest.id || `violation-${Date.now()}`,
        driverId: latest.driverId,
        driverName: latest.driverName || 'Field Operator',
        vehicleReg: 'KA-19-LIVE',
        type: eventType,
        severity: latest.severity || 'high',
        location: {
          lat: latest.latitude,
          lng: latest.longitude,
        },
        locationName: latest.roadName || `${latest.roadType} Sector`,
        time: 'Just now',
        value: `${latest.ruleTitle}: ${latest.description}`,
      }

      setEventList((prev) => {
        if (prev.some((e) => e.id === newEvt.id)) return prev
        return [newEvt, ...prev]
      })
    }
  }, [ruleViolations])

  // Listen for real-time incoming crash or telemetry alerts from active sockets
  useEffect(() => {
    if (crashAlertDriver) {
      const newEvt: FleetEvent = {
        id: `crash-${Date.now()}`,
        driverId: crashAlertDriver.driverId || crashAlertDriver.id || 'live-driver',
        driverName: crashAlertDriver.driverName || 'Field Operator',
        vehicleReg: crashAlertDriver.vehiclePlate || 'KA-19-PT-2026',
        type: 'crash',
        severity: 'critical',
        location: {
          lat: crashAlertDriver.latitude ?? 12.7749,
          lng: crashAlertDriver.longitude ?? 75.2023,
        },
        locationName: crashAlertDriver.reason || 'Sensor Crash Impact Geofence',
        time: 'Just now',
        value: 'Critical deceleration impact & stillness alert',
      }

      setEventList((prev) => {
        if (prev.some((e) => e.id === newEvt.id)) return prev
        return [newEvt, ...prev]
      })
    }
  }, [crashAlertDriver])

  // Listen for real-time incoming dedicated SOS panic alerts
  useEffect(() => {
    if (sosAlertDriver) {
      const newEvt: FleetEvent = {
        id: `sos-${Date.now()}`,
        driverId: sosAlertDriver.driverId || sosAlertDriver.id || 'live-driver',
        driverName: sosAlertDriver.driverName || 'Field Operator',
        vehicleReg: sosAlertDriver.vehiclePlate || 'KA-19-PT-2026',
        type: 'crash',
        severity: 'critical',
        location: {
          lat: sosAlertDriver.latitude ?? 12.7749,
          lng: sosAlertDriver.longitude ?? 75.2023,
        },
        locationName: sosAlertDriver.reason || 'Manual Driver SOS Panic Beacon',
        time: 'Just now',
        value: 'Manual Emergency SOS Panic Triggered by Operator',
      }

      setEventList((prev) => {
        if (prev.some((e) => e.id === newEvt.id)) return prev
        return [newEvt, ...prev]
      })
    }
  }, [sosAlertDriver])

  const handleRemoveAll = () => {
    setEventList([])
  }

  const handleRemoveEvent = (id: string) => {
    setEventList((prev) => prev.filter((e) => e.id !== id))
  }

  const filteredList = useMemo(() => {
    return eventList.filter((e) => {
      const matchesSev = sev === 'all' || e.severity === sev
      const matchesSearch =
        searchTerm === '' ||
        e.driverName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        e.locationName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        e.type.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (e.value && e.value.toLowerCase().includes(searchTerm.toLowerCase()))
      return matchesSev && matchesSearch
    })
  }, [eventList, sev, searchTerm])

  const stats = useMemo(() => {
    const total = eventList.length
    const critical = eventList.filter((e) => e.severity === 'critical' || e.severity === 'high').length
    const speed = eventList.filter((e) => e.type === 'overspeed').length
    const maneuver = eventList.filter((e) => e.type === 'harsh_braking' || e.type === 'sharp_turn' || e.type === 'harsh_acceleration').length
    return { total, critical, speed, maneuver }
  }, [eventList])

  return (
    <div className="space-y-6 pb-16 max-w-[1400px] mx-auto px-4 md:px-8 text-foreground">
      {/* ── TOP HEADER PANEL ────────────────────────────────────────────── */}
      <div className="stamped-card relative has-rivets p-6 md:p-8 rounded-[28px] overflow-hidden">
        <div className="corner-screw top-left" />
        <div className="corner-screw top-right" />
        <div className="corner-screw bottom-left" />
        <div className="corner-screw bottom-right" />

        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div>
            <div className="flex items-center gap-3">
              <span className="h-3 w-3 rounded-full bg-rose-500 animate-ping" />
              <h1 className="text-2xl md:text-3xl font-black uppercase font-space tracking-tight text-foreground leading-none">
                Behavioral <span className="text-primary">Anomalies Log</span>
              </h1>
              <span className="font-pixel text-[9px] px-2.5 py-1 rounded bg-secondary text-muted-foreground border border-border">
                20 HZ SYNC
              </span>
            </div>
            <p className="font-pixel text-[9px] text-muted-foreground uppercase tracking-[0.3em] mt-2">
              Real-Time Risk Audit • Inertial Sensor Telemetry Events
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
            {/* Search Input */}
            <div className="relative debossed-well rounded-2xl overflow-hidden flex-1 md:w-72">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
              <input
                type="text"
                placeholder="SEARCH TELEMETRY LOGS..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full h-11 pl-10 pr-4 bg-transparent text-xs font-tech font-bold uppercase tracking-wider text-foreground placeholder:text-muted-foreground outline-none"
              />
            </div>

            {/* Clear All Button */}
            {eventList.length > 0 && (
              <motion.button
                whileHover={{ scale: 1.03 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleRemoveAll}
                className="h-11 px-4 rounded-2xl bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 text-rose-500 transition flex items-center gap-2 cursor-pointer text-xs font-space font-black uppercase tracking-wider"
                title="Clear all alerts"
              >
                <Trash2 size={14} />
                <span>Clear All</span>
              </motion.button>
            )}

            {/* Refresh Button */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={loadEvents}
              disabled={isRefreshing}
              className="h-11 px-4 rounded-2xl bg-secondary hover:bg-card border border-border text-foreground transition flex items-center gap-2 cursor-pointer text-xs font-space font-black uppercase tracking-wider"
            >
              <RefreshCw size={13} className={cn(isRefreshing && 'animate-spin text-primary')} />
              <span>Refresh</span>
            </motion.button>
          </div>
        </div>
      </div>

      {/* ── MECHANICAL STAT READOUT INSTRUMENTS ────────────────────────────────────────── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatInstrument
          label="TOTAL ANOMALIES"
          value={stats.total}
          sub="Logged Today"
          icon={<Activity size={18} />}
          color="cyan"
        />
        <StatInstrument
          label="HIGH RISK / SOS"
          value={stats.critical}
          sub="Requires Attention"
          icon={<ShieldAlert size={18} />}
          color="red"
          danger={stats.critical > 0}
        />
        <StatInstrument
          label="SPEED BREACHES"
          value={stats.speed}
          sub="Sector Limits"
          icon={<Gauge size={18} />}
          color="amber"
        />
        <StatInstrument
          label="MANEUVER FAULTS"
          value={stats.maneuver}
          sub="Braking & Yaw"
          icon={<TrendingDown size={18} />}
          color="emerald"
        />
      </div>

      {/* ── SEVERITY FILTER RACK ────────────────────────────────────────── */}
      <div className="flex flex-wrap items-center justify-between gap-4 pt-2">
        <div className="debossed-well p-1.5 rounded-2xl flex items-center gap-1.5 overflow-x-auto no-scrollbar">
          {SEVERITIES.map((s) => (
            <motion.button
              key={s}
              whileTap={{ scale: 0.95 }}
              onClick={() => setSev(s)}
              className={cn(
                'h-9 px-4 rounded-xl font-space font-black text-[10px] uppercase tracking-widest transition-all cursor-pointer flex items-center gap-1.5',
                sev === s
                  ? s === 'critical'
                    ? 'bg-rose-600 text-white shadow-md'
                    : 'bg-primary text-white shadow-md'
                  : 'text-muted-foreground hover:text-foreground'
              )}
            >
              {s === 'critical' && <span className="h-1.5 w-1.5 rounded-full bg-white animate-ping" />}
              <span>{s}</span>
            </motion.button>
          ))}
        </div>

        <div className="font-pixel text-[9px] text-muted-foreground uppercase tracking-widest">
          SYNCED {filteredList.length} OF {eventList.length} RECORDS
        </div>
      </div>

      {/* ── EVENT TIMELINE FEED ────────────────────────────────────────── */}
      <div className="space-y-3 pt-2">
        <AnimatePresence mode="popLayout">
          {filteredList.length === 0 ? (
            <motion.div
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              className="stamped-card relative has-rivets py-20 text-center rounded-[32px] p-8 space-y-4"
            >
              <div className="corner-screw top-left" />
              <div className="corner-screw top-right" />
              <div className="corner-screw bottom-left" />
              <div className="corner-screw bottom-right" />

              <div className="h-16 w-16 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center mx-auto text-emerald-500">
                <CheckCircle2 size={32} />
              </div>
              <div>
                <h3 className="font-space font-black text-sm uppercase tracking-widest text-foreground">
                  All Anomalies Cleared
                </h3>
                <p className="font-tech text-xs text-muted-foreground mt-1 max-w-sm mx-auto">
                  No active risk events recorded for this telemetry filter. Grid is operating securely.
                </p>
              </div>
              <motion.button
                whileTap={{ scale: 0.95 }}
                onClick={loadEvents}
                className="px-5 py-2.5 rounded-xl bg-secondary hover:bg-card border border-border text-foreground font-space font-black text-xs uppercase tracking-wider transition inline-flex items-center gap-2 cursor-pointer shadow-sm"
              >
                <RefreshCw size={12} />
                <span>Reload Logs</span>
              </motion.button>
            </motion.div>
          ) : (
            filteredList.map((e, i) => {
              const m = META[e.type] || META['overspeed']
              const Icon = m.icon
              const isCritical = e.severity === 'critical' || e.severity === 'high'

              return (
                <motion.div
                  key={e.id}
                  layout
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ delay: Math.min(i * 0.02, 0.2) }}
                  className={cn(
                    'stamped-card relative has-rivets rounded-[24px] p-5 md:p-6 transition-all flex flex-col md:flex-row items-start md:items-center justify-between gap-4 overflow-hidden',
                    isCritical && 'border-rose-500/40 bg-rose-500/5'
                  )}
                >
                  <div className="corner-screw top-left" />
                  <div className="corner-screw top-right" />
                  <div className="corner-screw bottom-left" />
                  <div className="corner-screw bottom-right" />

                  <div className="flex items-center gap-4 min-w-0 flex-1">
                    <div
                      className="h-12 w-12 rounded-2xl flex items-center justify-center shrink-0 border shadow-inner transition-transform group-hover:scale-105"
                      style={{
                        background: m.bg,
                        color: m.color,
                        borderColor: `${m.color}40`,
                      }}
                    >
                      <Icon size={22} />
                    </div>

                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-space font-black text-sm uppercase tracking-tight text-foreground">
                          {m.label}
                        </span>

                        <span
                          className={cn(
                            'font-pixel text-[8px] px-2.5 py-0.5 rounded uppercase tracking-wider font-bold',
                            e.severity === 'critical'
                              ? 'bg-rose-500 text-white animate-pulse'
                              : e.severity === 'high'
                              ? 'bg-rose-500/20 border border-rose-500/40 text-rose-500'
                              : e.severity === 'medium'
                              ? 'bg-amber-500/20 border border-amber-500/40 text-amber-500'
                              : 'bg-secondary text-muted-foreground border border-border'
                          )}
                        >
                          {e.severity}
                        </span>

                        <span className="font-mono text-[10px] text-muted-foreground font-bold">
                          [{e.vehicleReg || 'KA-19-FG'}]
                        </span>
                      </div>

                      <div className="flex flex-wrap items-center gap-x-3 gap-y-1 font-tech text-xs text-muted-foreground">
                        <span className="text-primary font-bold uppercase tracking-wide">
                          {e.driverName}
                        </span>
                        <span>•</span>
                        <span className="truncate">{e.locationName}</span>
                      </div>

                      {e.value && (
                        <p className="font-mono text-[11px] font-bold text-amber-500/90 pt-0.5">
                          TELEMETRY: {e.value}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-4 w-full md:w-auto justify-between md:justify-end pt-2 md:pt-0 border-t md:border-t-0 border-border shrink-0">
                    <div className="text-left md:text-right">
                      <span className="font-space font-black text-xs text-foreground tabular-nums tracking-wide">
                        {e.time}
                      </span>
                      <p className="font-pixel text-[8px] text-muted-foreground uppercase tracking-widest mt-0.5">
                        GPS VERIFIED
                      </p>
                    </div>

                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      onClick={() => handleRemoveEvent(e.id)}
                      className="h-8 w-8 rounded-xl bg-secondary hover:bg-rose-500/10 border border-border hover:border-rose-500/40 text-muted-foreground hover:text-rose-500 flex items-center justify-center transition cursor-pointer shadow-sm"
                      title="Dismiss alert"
                    >
                      <X size={14} />
                    </motion.button>
                  </div>
                </motion.div>
              )
            })
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}

function StatInstrument({ label, value, sub, icon, color, danger }: any) {
  const colorMap: Record<string, string> = {
    cyan: 'text-primary bg-primary/10 border-primary/20',
    red: 'text-rose-500 bg-rose-500/10 border-rose-500/20',
    amber: 'text-amber-500 bg-amber-500/10 border-amber-500/20',
    emerald: 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20',
  }

  return (
    <motion.div
      whileHover={{ y: -2 }}
      className={cn(
        'stamped-card relative has-rivets p-5 rounded-3xl transition-all flex flex-col justify-between',
        danger && 'border-rose-500/40 bg-rose-500/5'
      )}
    >
      <div className="corner-screw top-left" />
      <div className="corner-screw top-right" />
      <div className="corner-screw bottom-left" />
      <div className="corner-screw bottom-right" />

      <div className="flex items-center justify-between mb-3">
        <span className="font-pixel text-[8px] uppercase tracking-widest text-muted-foreground">{label}</span>
        <div className={cn('h-8 w-8 rounded-xl flex items-center justify-center border', colorMap[color])}>
          {icon}
        </div>
      </div>
      <div>
        <div className="font-space font-black text-2xl text-foreground tracking-tight">{value}</div>
        <p className="font-pixel text-[8px] text-muted-foreground uppercase tracking-wider mt-1">{sub}</p>
      </div>
    </motion.div>
  )
}
