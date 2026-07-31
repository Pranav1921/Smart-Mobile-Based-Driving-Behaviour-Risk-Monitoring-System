import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  X, Gauge, MapPin, Clock, Route as RouteIcon, BatteryMedium, Wifi, Satellite,
  Camera, Cpu, Bluetooth, ShieldCheck, TriangleAlert, Brain, Zap, ArrowUpRight, ArrowDownRight,
} from 'lucide-react'
import { VehicleRender } from './VehicleRender'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { AreaLineChart } from '@/components/charts/Charts'
import { vehicleById, events as allEvents, getContextForLocation } from '@/data/mockData'
import { cn, scoreColor } from '@/lib/utils'
import type { Driver } from '@/types'

const STATUS_LABEL: Record<string, string> = { safe: 'Safe', warning: 'Warning', emergency: 'Emergency', idle: 'Idle', offline: 'Offline' }

function StatChip({ icon: Icon, label, value, ok }: { icon: React.ElementType; label: string; value: string; ok?: boolean }) {
  return (
    <div className="glass rounded-xl p-2.5 flex items-center gap-2.5">
      <div className={cn('grid place-items-center h-8 w-8 rounded-lg shrink-0', ok === false ? 'bg-rose-500/10 text-rose-300' : 'bg-cyan-400/10 text-cyan-300')}>
        <Icon className="h-4 w-4" />
      </div>
      <div className="min-w-0">
        <div className="text-[10px] text-muted leading-none">{label}</div>
        <div className="text-[13px] font-semibold text-primary mt-1 truncate">{value}</div>
      </div>
    </div>
  )
}

function Metric({ label, value, tone }: { label: string; value: React.ReactNode; tone?: string }) {
  return (
    <div className="glass rounded-xl p-3">
      <div className="text-[10px] text-muted uppercase tracking-wide">{label}</div>
      <div className="text-lg font-display font-bold mt-1" style={{ color: tone }}>{value}</div>
    </div>
  )
}

export function VehiclePanel({ driver, onClose }: { driver: Driver | null; onClose: () => void }) {
  const vehicle = driver ? vehicleById(driver.vehicleId) : undefined
  const driverEvents = driver ? allEvents.filter((e) => e.driverId === driver.id) : []
  const isCrash = driver?.status === 'emergency'

  const currentZone = driver ? getContextForLocation(driver.location.lat, driver.location.lng) : null
  const limitSpeed = currentZone ? currentZone.speedLimit : 60
  const isViolating = driver ? driver.speed > limitSpeed : false

  const [crashSpeed, setCrashSpeed] = useState(60)

  // Escalation Flow states
  const [escalationStep, setEscalationStep] = useState<1 | 2 | 3>(1)
  const [step1Status, setStep1Status] = useState<'idle' | 'sending' | 'completed'>('idle')
  const [step2Status, setStep2Status] = useState<'idle' | 'calling' | 'completed'>('idle')
  const [step3Status, setStep3Status] = useState<'idle' | 'completed'>('idle')
  const [step1Timer, setStep1Timer] = useState(5)
  const [step2Timer, setStep2Timer] = useState(5)

  // Auto-advance step 1 timer
  useEffect(() => {
    if (step1Status !== 'sending') return
    if (step1Timer <= 0) {
      setStep1Status('completed')
      setEscalationStep(2)
      return
    }
    const timer = setTimeout(() => setStep1Timer((p) => p - 1), 1000)
    return () => clearTimeout(timer)
  }, [step1Status, step1Timer])

  // Auto-advance step 2 timer
  useEffect(() => {
    if (step2Status !== 'calling') return
    if (step2Timer <= 0) {
      setStep2Status('completed')
      setEscalationStep(3)
      return
    }
    const timer = setTimeout(() => setStep2Timer((p) => p - 1), 1000)
    return () => clearTimeout(timer)
  }, [step2Status, step2Timer])

  // Loop speed drop animation for emergency status
  useEffect(() => {
    if (driver?.status !== 'emergency') return
    setCrashSpeed(60) // reset
    const interval = setInterval(() => {
      setCrashSpeed((prev) => {
        if (prev <= 0) return 60
        if (prev === 60) return 50
        if (prev === 50) return 30
        if (prev === 30) return 10
        if (prev === 10) return 5
        return 0
      })
    }, 450)
    return () => clearInterval(interval)
  }, [driver?.id, driver?.status])

  const speedSeries = Array.from({ length: 14 }, (_, i) =>
    Math.max(0, (driver?.speed ?? 40) + Math.sin(i * 0.8) * 14 + (i % 3) * 3))
  const accelSeries = Array.from({ length: 14 }, (_, i) => Math.sin(i * 1.1) * 0.5 + (i % 4 === 0 ? 0.3 : 0))

  return (
    <AnimatePresence>
      {driver && (
        <>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={onClose} className="absolute inset-0 bg-black/40 z-[400]" />
          <motion.aside
            initial={{ x: '110%', opacity: 0 }} animate={{ x: 0, opacity: 1 }} exit={{ x: '110%', opacity: 0 }}
            transition={{ type: 'spring', stiffness: 280, damping: 30 }}
            className="absolute top-4 right-4 bottom-4 w-[calc(100vw-32px)] sm:w-[390px] z-[401] glass rounded-3xl border border-white/10 overflow-y-auto no-scrollbar shadow-2xl shadow-black/80"
          >
            {/* header */}
            <div className="sticky top-0 z-10 flex items-center justify-between px-5 h-14 glass rounded-t-3xl border-b border-white/8 text-primary">
              <div className="flex items-center gap-2">
                <span className={cn('h-2.5 w-2.5 rounded-full',
                  driver.status === 'safe' ? 'bg-emerald-400' : driver.status === 'warning' ? 'bg-amber-400' : driver.status === 'emergency' ? 'bg-rose-500 animate-pulse-glow' : 'bg-sky-400')} />
                <span className="font-display font-semibold text-primary text-sm">{STATUS_LABEL[driver.status]} · Live</span>
              </div>
              <button onClick={onClose} className="grid place-items-center h-8 w-8 rounded-lg hover:bg-white/5 text-secondary hover:text-primary">
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="p-5 space-y-5">
              {isCrash && (
                <motion.div initial={{ scale: 0.96 }} animate={{ scale: 1 }}
                  className="glass rounded-xl p-3 border border-rose-500/40 bg-rose-500/5 flex items-center gap-3">
                  <TriangleAlert className="h-5 w-5 text-rose-400 animate-pulse-glow shrink-0" />
                  <div>
                    <div className="text-[13px] font-semibold text-rose-200">Crash Detected · 4.8G impact</div>
                    <div className="text-[11px] text-rose-300/80">Vehicle stationary · emergency protocol armed</div>
                  </div>
                </motion.div>
              )}

              {/* vehicle render */}
              <VehicleRender type={vehicle?.type ?? 'car'} name={vehicle?.name ?? 'Vehicle'} />

              {/* identity */}
              <div className="flex items-center gap-3">
                <Avatar name={driver.name} size={48} />
                <div className="min-w-0">
                  <div className="font-display font-semibold text-primary">{driver.name}</div>
                  <div className="text-[11px] text-muted">{driver.employeeId} · {vehicle?.name}</div>
                </div>
                <div className="ml-auto text-right">
                  <div className="text-[11px] text-muted">{vehicle?.registration}</div>
                  <Badge tone={driver.status} className="mt-1">{driver.industry}</Badge>
                </div>
              </div>
              <div className="text-[11.5px] text-muted -mt-2">{driver.fleet}</div>

              {/* Delivery Order details (if available) */}
              {driver.orderItems && (
                <div className="glass rounded-xl p-3 border border-white/5 space-y-1.5 text-[12.5px]">
                  <div className="text-[10px] text-cyan-300 font-semibold uppercase tracking-wider">Active Food Delivery Order</div>
                  <div className="text-primary font-medium">{driver.orderItems}</div>
                  <div className="grid grid-cols-2 gap-2 text-[11px] text-secondary mt-1.5 pt-1.5 border-t border-white/5">
                    <div>
                      <span className="text-muted block text-[9px] uppercase">From</span>
                      {driver.deliveryFrom}
                    </div>
                    <div>
                      <span className="text-muted block text-[9px] uppercase">To</span>
                      {driver.deliveryTo}
                    </div>
                  </div>
                </div>
              )}

              {/* Accident Analysis (only if status is emergency, i.e., crash) */}
              {driver.status === 'emergency' && (
                <div className="space-y-4">
                  <div>
                    <SectionTitle icon={TriangleAlert} title="Critical Crash Telemetry" />
                    <div className="glass rounded-xl p-4 border border-rose-500/20 bg-rose-500/5 space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-[12.5px] font-semibold text-rose-300">Telemetry Log Analysis</span>
                        <span className="text-[10px] bg-rose-500/20 text-rose-300 px-2 py-0.5 rounded-full font-mono animate-pulse">
                          CRITICAL IMPACT
                        </span>
                      </div>
                      
                      {/* Telemetry cliff-drop animation */}
                      <div className="grid grid-cols-2 gap-3">
                        {/* Left: Speed Countdown Counter */}
                        <div className="bg-black/50 rounded-xl p-3 border border-white/10 flex flex-col justify-center items-center h-24">
                          <div className="text-[9.5px] uppercase tracking-wider font-bold" style={{ color: 'rgba(255, 255, 255, 0.85)' }}>Simulated Speed</div>
                          <div className="flex items-baseline gap-0.5 mt-1">
                            <span className="font-display font-extrabold text-2xl tabular-nums animate-pulse" style={{ color: '#ff4d6d' }}>
                              {crashSpeed}
                            </span>
                            <span className="text-[10px] font-bold" style={{ color: 'rgba(255, 255, 255, 0.65)' }}>km/h</span>
                          </div>
                          <div className="text-[9.5px] font-bold text-center mt-2.5 h-3" style={{ color: '#ff85a2' }}>
                            {crashSpeed === 60 && '🟢 Cruising'}
                            {crashSpeed > 0 && crashSpeed < 60 && '⚠️ Decelerating'}
                            {crashSpeed === 0 && '🚨 Impact / Stopped'}
                          </div>
                        </div>

                        {/* Right: Crash Details */}
                        <div className="bg-black/50 rounded-xl p-3 border border-white/10 flex flex-col justify-between h-24 text-[11px]">
                          <div>
                            <div className="text-[9.5px] uppercase tracking-wider font-bold" style={{ color: 'rgba(255, 255, 255, 0.85)' }}>Impact Force</div>
                            <div className="text-[13px] font-black mt-0.5" style={{ color: '#ff85a2' }}>4.8 G Force</div>
                          </div>
                          <div>
                            <div className="text-[9px] uppercase tracking-wider font-mono font-bold" style={{ color: 'rgba(255, 255, 255, 0.85)' }}>Inactivity Timer</div>
                            <div className="text-[10.5px] font-black mt-0.5 animate-pulse" style={{ color: '#ff4d6d' }}>NO MOVEMENTS (24s)</div>
                          </div>
                        </div>
                      </div>

                      {/* Inactivity indicator */}
                      <div className="flex items-center gap-2.5 p-3 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-300 animate-pulse">
                        <TriangleAlert className="h-5 w-5 shrink-0" />
                        <div>
                          <div className="text-[12px] font-bold">🚨 INACTIVITY DETECTED</div>
                          <div className="text-[10px] text-rose-300/80 mt-0.5">No driver response or phone movement detected for 24 seconds.</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Mock mobile camera feed */}
                  <div>
                    <SectionTitle icon={Camera} title="Mobile Camera Incident Feed" />
                    <div className="relative rounded-2xl overflow-hidden border border-rose-500/30 aspect-video bg-black flex flex-col justify-between p-3.5 shadow-2xl">
                      {/* Grid overlay */}
                      <div className="absolute inset-0 bg-grid-scanlines pointer-events-none opacity-20" />
                      
                      {/* Crack screen effect */}
                      <div className="absolute inset-0 pointer-events-none opacity-40 z-10">
                        <svg className="w-full h-full" viewBox="0 0 100 50">
                          <path d="M 50 25 L 30 10 M 50 25 L 75 15 M 50 25 L 45 40 M 50 25 L 60 38 M 30 10 L 10 15 M 75 15 L 90 5 M 45 40 L 40 48" stroke="#fff" strokeWidth="0.8" fill="none" opacity="0.8" />
                          <path d="M 50 25 M 35 18 L 40 5 M 50 25 L 58 10 M 60 38 L 78 45" stroke="#fff" strokeWidth="0.4" fill="none" opacity="0.6" />
                        </svg>
                      </div>

                      {/* Tilted, off-axis camera image (dropped phone) */}
                      <div className="absolute inset-0 bg-[#1e1c2a] flex items-center justify-center opacity-85 text-center p-4">
                        <div className="rotate-[-15deg] text-muted space-y-1">
                          <div className="text-[20px] opacity-10 font-bold text-slate-100 uppercase">COLLISION IMPACT</div>
                          <div className="text-[11px] font-semibold text-rose-300 uppercase tracking-widest">Feed Frozen Post-Crash</div>
                          <div className="text-[9.5px] text-slate-400 max-w-[240px] mx-auto leading-normal">Horizontal accelerometer locked. Mobile camera lens blocked by pavement debris.</div>
                        </div>
                      </div>

                      {/* Video overlay headers */}
                      <div className="relative z-20 flex justify-between items-start text-white text-[10px] font-mono">
                        <div className="flex items-center gap-1.5 bg-rose-600 px-2 py-0.5 rounded text-white font-bold animate-pulse">
                          <span className="h-2 w-2 rounded-full bg-white shrink-0" />
                          REC [POST-CRASH]
                        </div>
                        <div className="bg-black/60 px-2 py-0.5 rounded text-slate-300">CAM_1 (FRONT)</div>
                      </div>
                      
                      <div className="relative z-20 flex justify-between items-end text-white text-[9px] font-mono">
                        <span className="bg-black/60 px-1.5 py-0.5 rounded text-rose-300 font-bold">SIGNAL LOSS: 98%</span>
                        <span className="bg-black/60 px-1.5 py-0.5 rounded text-slate-300">30 JUL 2026</span>
                      </div>
                    </div>
                  </div>

                  {/* Emergency Response Protocol Escalation */}
                  <div>
                    <SectionTitle icon={Zap} title="Emergency Rescue Protocol" />
                    <div className="glass rounded-xl p-4 border border-rose-500/20 bg-rose-500/5 space-y-3.5">
                      <div className="text-[10px] text-rose-300 font-bold uppercase tracking-wider">Multi-Tier Escalation Sequence</div>
                      
                      <div className="space-y-3">
                        {/* Step 1: Vibration Alert */}
                        <div className={cn(
                          "p-3 rounded-lg border transition-all duration-300",
                          escalationStep === 1 
                            ? "bg-rose-500/10 border-rose-500/30" 
                            : step1Status === 'completed'
                            ? "bg-slate-900/40 border-emerald-500/20 opacity-70"
                            : "bg-slate-900/40 border-white/5 opacity-50"
                        )}>
                          <div className="flex items-center justify-between">
                            <span className="text-[12px] font-bold text-slate-100 flex items-center gap-1.5">
                              {step1Status === 'completed' ? '✅' : '1️⃣'} Vibration Alert Device
                            </span>
                            {step1Status === 'sending' && (
                              <span className="text-[10.5px] font-mono animate-pulse" style={{ color: '#ff4d6d' }}>Alerting ({step1Timer}s)...</span>
                            )}
                            {step1Status === 'completed' && (
                              <span className="text-[10px] text-emerald-400 font-semibold">NO RESPONSE</span>
                            )}
                          </div>
                          <p className="text-[10px] text-slate-400 mt-1 leading-normal">
                            Sends high-intensity vibration cycles and emergency audible sounds to driver's phone.
                          </p>
                          {escalationStep === 1 && step1Status === 'idle' && (
                            <button
                              onClick={() => setStep1Status('sending')}
                              className="mt-2 w-full py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-[11px] font-bold transition-all shadow-md cursor-pointer"
                            >
                              Send Vibration Alert
                            </button>
                          )}
                        </div>

                        {/* Step 2: Cellular Call */}
                        <div className={cn(
                          "p-3 rounded-lg border transition-all duration-300",
                          escalationStep === 2 
                            ? "bg-rose-500/10 border-rose-500/30" 
                            : step2Status === 'completed'
                            ? "bg-slate-900/40 border-emerald-500/20 opacity-70"
                            : "bg-slate-900/40 border-white/5 opacity-50"
                        )}>
                          <div className="flex items-center justify-between">
                            <span className="text-[12px] font-bold text-slate-100 flex items-center gap-1.5">
                              {step2Status === 'completed' ? '✅' : '2️⃣'} Trigger Emergency Call
                            </span>
                            {step2Status === 'calling' && (
                              <span className="text-[10.5px] font-mono animate-pulse" style={{ color: '#ff4d6d' }}>Dialing ({step2Timer}s)...</span>
                            )}
                            {step2Status === 'completed' && (
                              <span className="text-[10px] text-emerald-400 font-semibold">NO ANSWER</span>
                            )}
                          </div>
                          <p className="text-[10px] text-slate-400 mt-1 leading-normal">
                            Triggers high-volume synthetic voice warning call to verify driver consciousness.
                          </p>
                          {escalationStep === 2 && step2Status === 'idle' && (
                            <button
                              onClick={() => setStep2Status('calling')}
                              className="mt-2 w-full py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-[11px] font-bold transition-all shadow-md cursor-pointer"
                            >
                              Trigger Call Protocol
                            </button>
                          )}
                        </div>

                        {/* Step 3: Broadcast SOS & Nearest Services */}
                        <div className={cn(
                          "p-3 rounded-lg border transition-all duration-300",
                          escalationStep === 3 
                            ? "bg-rose-500/15 border-rose-500/40 shadow-inner" 
                            : "bg-slate-900/40 border-white/5 opacity-50"
                        )}>
                          <div className="flex items-center justify-between">
                            <span className="text-[12px] font-bold text-slate-100 flex items-center gap-1.5">
                              {step3Status === 'completed' ? '✅' : '3️⃣'} Broadcast SOS & Local Services
                            </span>
                            {step3Status === 'completed' && (
                              <span className="text-[10px] text-emerald-400 font-bold">DISPATCHED</span>
                            )}
                          </div>
                          <p className="text-[10px] text-slate-400 mt-1 leading-normal">
                            Forwards telemetry data, coordinates, and alerts police and emergency family contacts.
                          </p>
                          {escalationStep === 3 && step3Status === 'idle' && (
                            <button
                              onClick={() => setStep3Status('completed')}
                              className="mt-2 w-full py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-[11px] font-bold transition-all shadow-md cursor-pointer"
                            >
                              Broadcast SOS & Local Shops
                            </button>
                          )}

                          {step3Status === 'completed' && (
                            <div className="mt-3 pt-3 border-t border-white/10 space-y-2.5 text-[11px] text-slate-300">
                              <div className="flex items-center gap-2 text-[10.5px] font-semibold" style={{ color: '#34d399' }}>
                                <span>✓</span> SMS telemetry broadcasted to Spouse (Family Contact)
                              </div>
                              <div className="flex items-center gap-2 text-[10.5px] font-semibold" style={{ color: '#34d399' }}>
                                <span>✓</span> Crash coordinates sent to Bunts Hostel Police Station
                              </div>
                              <div className="bg-black/40 rounded-xl p-2.5 space-y-2.5 border border-white/5">
                                <div className="text-[9.5px] font-semibold uppercase tracking-wider" style={{ color: '#22d3ee' }}>Nearest Services (Google Maps)</div>
                                <div className="space-y-1">
                                  <div className="font-bold text-white leading-tight">Bunts Hostel Medicals & Pharmacy</div>
                                  <div className="text-slate-400 text-[10px]">Ph: +91 824 244 0122 (120m away)</div>
                                </div>
                                <div className="space-y-1 pt-1.5 border-t border-white/5">
                                  <div className="font-bold text-white leading-tight">Mangaluru Trauma Care Center</div>
                                  <div className="text-slate-400 text-[10px]">Ph: +91 824 223 8000 (450m away)</div>
                                </div>
                                <div className="space-y-1 pt-1.5 border-t border-white/5">
                                  <div className="font-bold text-white leading-tight">Suresh Auto Repair (Two Wheeler Specialists)</div>
                                  <div className="text-slate-400 text-[10px]">Ph: +91 98451 22941 (340m away)</div>
                                </div>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  <style>{`
                    .bg-grid-scanlines {
                      background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%), linear-gradient(90deg, rgba(255, 0, 0, 0.06), rgba(0, 255, 0, 0.02), rgba(0, 0, 255, 0.06));
                      background-size: 100% 4px, 6px 100%;
                    }
                  `}</style>
                </div>
              )}

              {/* live status */}
              <div>
                <SectionTitle icon={Gauge} title="Live Status" />
                <div className="grid grid-cols-2 gap-2">
                  <StatChip icon={Gauge} label="Current Speed" value={`${driver.speed} km/h`} />
                  <StatChip icon={RouteIcon} label="Distance" value={`${driver.distanceToday} km`} />
                  <StatChip icon={Clock} label="Trip Duration" value={`${driver.tripDurationMin} min`} />
                  <StatChip icon={MapPin} label="Location" value={driver.locationName} />
                </div>
                <div className="grid grid-cols-3 gap-2 mt-2">
                  <StatChip icon={BatteryMedium} label="Battery" value={`${driver.battery}%`} ok={driver.battery > 20} />
                  <StatChip icon={Wifi} label="Internet" value={`${driver.internet}%`} ok={driver.internet > 40} />
                  <StatChip icon={Satellite} label="GPS" value={driver.gps ? 'Locked' : 'Lost'} ok={driver.gps} />
                  <StatChip icon={Camera} label="Camera" value={driver.camera ? 'On' : 'Off'} ok={driver.camera} />
                  <StatChip icon={Cpu} label="Sensors" value={driver.sensors ? 'Active' : 'Fault'} ok={driver.sensors} />
                  <StatChip icon={Bluetooth} label="BLE / IMU" value={driver.ble ? 'Paired' : '—'} ok={driver.ble} />
                </div>
              </div>

              {/* Rules Compliance (Context-Aware) */}
              <div>
                <SectionTitle icon={ShieldCheck} title="Context Rules Compliance" />
                <div className="glass rounded-xl p-4 border border-white/5 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-[10px] text-muted uppercase tracking-wider">Current Zone Type</div>
                      <div className="text-[14px] font-semibold text-primary mt-0.5">
                        {currentZone ? (currentZone.type === 'school' ? '🏫 School Zone' : '🚨 Heavy Traffic Zone') : '🛣️ Normal Road/Highway'}
                      </div>
                      {currentZone && <div className="text-[11.5px] text-muted mt-0.5">{currentZone.name}</div>}
                    </div>
                    <Badge tone={isViolating ? 'danger' : 'safe'}>
                      {isViolating ? 'Violating Rules' : 'Compliant'}
                    </Badge>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 pt-2.5 border-t border-white/5">
                    <div>
                      <div className="text-[10px] text-muted uppercase tracking-wider">Zone Speed Limit</div>
                      <div className="text-[15px] font-bold text-primary mt-0.5">{limitSpeed} km/h</div>
                    </div>
                    <div>
                      <div className="text-[10px] text-muted uppercase tracking-wider">Current Speed</div>
                      <div className="text-[15px] font-bold mt-0.5" style={{ color: isViolating ? '#f43f5e' : '#34d399' }}>
                        {driver.speed} km/h
                      </div>
                    </div>
                  </div>

                  {isViolating && currentZone && (
                    <div className="flex items-center gap-2 p-2.5 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-300 text-[11.5px] font-semibold animate-pulse">
                      <TriangleAlert className="h-4 w-4 shrink-0" />
                      <span>Speeding by {driver.speed - currentZone.speedLimit} km/h in restricted zone!</span>
                    </div>
                  )}
                </div>
              </div>

              {/* AI safety */}
              <div>
                <SectionTitle icon={Brain} title="AI Safety Analysis" />
                <div className="grid grid-cols-3 gap-2">
                  <Metric label="Safety" value={driver.safetyScore} tone={scoreColor(driver.safetyScore)} />
                  <Metric label="Risk" value={driver.riskScore} tone={driver.riskScore > 50 ? '#f43f5e' : '#fbbf24'} />
                  <Metric label="Crash Prob" value={`${driver.crashProbability}%`} tone={driver.crashProbability > 30 ? '#f43f5e' : '#34d399'} />
                </div>
                <div className="grid grid-cols-2 gap-2 mt-2">
                  <Metric label="Driving Style" value={<span className="text-sm">{driver.drivingStyle}</span>} tone="var(--text-primary)" />
                  <Metric label="Aggressive" value={`${driver.aggressive}%`} tone={driver.aggressive > 50 ? '#fbbf24' : '#34d399'} />
                </div>
                <div className="grid grid-cols-3 gap-2 mt-2">
                  <Metric label="Overspeed" value={driver.overspeedCount} tone="var(--text-primary)" />
                  <Metric label="Harsh Brake" value={driver.harshBrakingCount} tone="var(--text-primary)" />
                  <Metric label="Sharp Turn" value={driver.sharpTurnCount} tone="var(--text-primary)" />
                </div>
                <div className="flex items-center gap-3 mt-2">
                  <TrendPill label="Weekly" value={driver.weeklyTrend} />
                  <TrendPill label="Monthly" value={driver.monthlyTrend} />
                </div>
                <div className="glass rounded-xl p-3 mt-3 border border-cyan-400/20 bg-cyan-400/[0.03] flex gap-2.5">
                  <ShieldCheck className="h-4 w-4 text-cyan-300 shrink-0 mt-0.5" />
                  <p className="text-[12px] text-secondary leading-relaxed"><span className="text-cyan-300 font-medium">AI Recommendation · </span>{driver.recommendation}</p>
                </div>
              </div>

              {/* live charts */}
              <div>
                <SectionTitle icon={Zap} title="Live Telemetry" />
                <div className="glass rounded-xl p-3 mb-2">
                  <div className="text-[11px] text-muted mb-1">Speed (km/h)</div>
                  <AreaLineChart labels={speedSeries.map((_, i) => `${i}`)} series={[{ name: 'Speed', data: speedSeries, color: '#22d3ee' }]} height={110} />
                </div>
                <div className="glass rounded-xl p-3">
                  <div className="text-[11px] text-muted mb-1">Acceleration (g)</div>
                  <AreaLineChart labels={accelSeries.map((_, i) => `${i}`)} series={[{ name: 'Accel', data: accelSeries, color: '#a78bfa' }]} height={110} />
                </div>
              </div>

              {/* recent events */}
              {driverEvents.length > 0 && (
                <div>
                  <SectionTitle icon={TriangleAlert} title="Recent Events" />
                  <div className="space-y-1.5">
                    {driverEvents.map((e) => (
                      <div key={e.id} className="glass rounded-xl p-2.5 flex items-center gap-3">
                        <span className={cn('h-2 w-2 rounded-full shrink-0',
                          e.severity === 'critical' ? 'bg-rose-500' : e.severity === 'high' ? 'bg-orange-400' : e.severity === 'medium' ? 'bg-amber-400' : 'bg-sky-400')} />
                        <div className="min-w-0 flex-1">
                          <div className="text-[12px] text-primary capitalize">{e.type.replace('_', ' ')}</div>
                          <div className="text-[10px] text-muted">{e.locationName}</div>
                        </div>
                        {e.value && <span className="text-[11px] text-secondary">{e.value}</span>}
                        <span className="text-[10px] text-muted">{e.time}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  )
}

function SectionTitle({ icon: Icon, title }: { icon: React.ElementType; title: string }) {
  return (
    <div className="flex items-center gap-2 mb-2.5">
      <Icon className="h-3.5 w-3.5 text-cyan-300" />
      <span className="text-[11px] font-semibold uppercase tracking-wider text-secondary">{title}</span>
    </div>
  )
}

function TrendPill({ label, value }: { label: string; value: number }) {
  const up = value >= 0
  return (
    <div className="flex items-center gap-1.5 text-[12px]">
      <span className="text-muted">{label}</span>
      <span className={cn('flex items-center gap-0.5 font-semibold', up ? 'text-emerald-300' : 'text-rose-300')}>
        {up ? <ArrowUpRight className="h-3.5 w-3.5" /> : <ArrowDownRight className="h-3.5 w-3.5" />}{Math.abs(value)}%
      </span>
    </div>
  )
}
