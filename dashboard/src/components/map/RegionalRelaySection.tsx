import { useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  X,
  Truck,
  CheckCircle2,
  Navigation,
  ArrowRight,
  ShieldAlert,
  Loader2,
  Sparkles,
  MapPin,
  Clock,
  Coins,
  Radio,
  ChevronRight,
  UserCheck,
} from 'lucide-react'
import type { Driver } from '@/types'
import type { RegionOption } from '@/data/regionsData'
import { Avatar } from '@/components/ui/Avatar'
import { cn } from '@/lib/utils'

interface RegionalRelaySectionProps {
  isOpen: boolean
  onClose: () => void
  activeRegion: RegionOption
  regionalDrivers: Driver[]
  troubledDriver: Driver | null
  candidateRelayDriver: Driver | null
  onSelectTroubledDriver: (driverId: string) => void
  onSelectCandidateDriver: (driverId: string) => void
  onAssignRelay: () => void
  isAssigning: boolean
  successMessage: string | null
}

export function RegionalRelaySection({
  isOpen,
  onClose,
  activeRegion,
  regionalDrivers,
  troubledDriver,
  candidateRelayDriver,
  onSelectTroubledDriver,
  onSelectCandidateDriver,
  onAssignRelay,
  isAssigning,
  successMessage,
}: RegionalRelaySectionProps) {
  // Available candidates: exclude the current troubled driver and phantom IDs
  const candidates = useMemo(() => {
    if (!troubledDriver) return []
    return regionalDrivers
      .filter((d) => d.id !== troubledDriver.id && d.id !== 'agent-x' && d.id !== 'mobile-driver')
      .map((d) => {
        let distKm = 0
        if (troubledDriver.location && d.location) {
          const dLat = (d.location.lat - troubledDriver.location.lat) * 111
          const dLng =
            (d.location.lng - troubledDriver.location.lng) *
            111 *
            Math.cos((troubledDriver.location.lat * Math.PI) / 180)
          distKm = Math.round(Math.sqrt(dLat * dLat + dLng * dLng) * 10) / 10
        }
        const etaMin = Math.max(2, Math.round((distKm / 35) * 60))
        return {
          driver: d,
          distKm,
          etaMin,
        }
      })
      .sort((a, b) => {
        const aOnline = a.driver.status !== 'offline' ? 1 : 0
        const bOnline = b.driver.status !== 'offline' ? 1 : 0
        if (aOnline !== bOnline) return bOnline - aOnline
        return a.distKm - b.distKm
      })
  }, [regionalDrivers, troubledDriver])

  const totalAmount = 150
  const troubledSplit = 45 // 30%
  const relaySplit = 105 // 70%

  if (!isOpen) return null

  return (
    <AnimatePresence>
      <motion.div
        initial={{ y: '100%', opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: '100%', opacity: 0 }}
        transition={{ type: 'spring', damping: 26, stiffness: 280 }}
        className="absolute bottom-4 left-4 right-4 z-[450] max-h-[85vh] md:max-h-[520px] bg-slate-950/95 border-2 border-cyan-500/70 rounded-3xl shadow-[0_0_60px_rgba(6,182,212,0.3),0_25px_50px_rgba(0,0,0,0.9)] backdrop-blur-2xl flex flex-col overflow-hidden text-white pointer-events-auto"
      >
        {/* Header HUD */}
        <div className="px-6 py-4 border-b border-slate-800 bg-slate-900/80 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-2xl bg-gradient-to-br from-cyan-400 to-blue-600 text-slate-950 flex items-center justify-center font-black shadow-lg shadow-cyan-500/30">
              <Truck size={20} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-black uppercase tracking-wider text-cyan-400 font-space flex items-center gap-1.5">
                  <Sparkles size={13} className="text-cyan-300 animate-spin" />
                  REGIONAL 70/30 FLEET RELAY
                </span>
                <span className="px-2 py-0.5 rounded-full bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 text-[9px] font-black uppercase tracking-wider">
                  📍 {activeRegion.name}
                </span>
                <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[9px] font-black uppercase tracking-wider">
                  {candidates.length} ACTIVE DRIVERS READY
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-medium mt-0.5">
                Click any driver directly on the map or in the list below to assign. Both drivers will be notified in real time.
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="h-9 w-9 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white flex items-center justify-center transition cursor-pointer border border-slate-700 active:scale-95"
            title="Close Relay Command"
          >
            <X size={16} />
          </button>
        </div>

        {/* Content Body: Split into 3 Logical Sections */}
        <div className="flex-1 overflow-y-auto p-5 grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* LEFT COLUMN: Origin / Troubled Driver (30% Base) */}
          <div className="lg:col-span-4 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-black uppercase tracking-widest text-amber-400 flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-amber-400 animate-pulse" />
                STEP 1 · ORIGIN / TROUBLED DRIVER (30%)
              </span>
              <span className="text-[10px] font-mono text-amber-300 bg-amber-950/60 px-2 py-0.5 rounded border border-amber-500/30">
                Secured: ₹{troubledSplit}
              </span>
            </div>

            {/* Troubled Driver Selector */}
            <div className="p-4 rounded-2xl bg-amber-950/20 border-2 border-amber-500/40 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <label className="text-[10px] font-bold text-slate-300 uppercase tracking-wider">
                  Select Stranded / Origin Driver:
                </label>
                <select
                  value={troubledDriver?.id || ''}
                  onChange={(e) => onSelectTroubledDriver(e.target.value)}
                  className="bg-slate-900 border border-slate-700 text-xs font-bold text-amber-300 rounded-lg px-2.5 py-1 outline-none cursor-pointer hover:border-amber-400 transition"
                >
                  {regionalDrivers
                    .filter((d) => d.id !== 'agent-x' && d.id !== 'mobile-driver')
                    .map((d) => (
                      <option key={d.id} value={d.id} className="bg-slate-900 text-white">
                        {d.name.replace(/\s+applicant/gi, '').trim()} ({d.status.toUpperCase()})
                      </option>
                    ))}
                </select>
              </div>

              {troubledDriver ? (
                <div className="flex items-start gap-3 bg-slate-900/80 p-3 rounded-xl border border-slate-800">
                  <Avatar name={troubledDriver.name} size={40} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between">
                      <h4 className="text-xs font-black text-white truncate">
                        {troubledDriver.name.replace(/\s+applicant/gi, '').trim()}
                      </h4>
                      <span
                        className={cn(
                          'text-[9px] font-black uppercase px-2 py-0.5 rounded',
                          troubledDriver.status === 'emergency'
                            ? 'bg-rose-500/20 text-rose-300 border border-rose-500/50'
                            : 'bg-amber-500/20 text-amber-300 border border-amber-500/50'
                        )}
                      >
                        {troubledDriver.status === 'emergency' ? 'CRASH / SOS' : troubledDriver.status.toUpperCase()}
                      </span>
                    </div>
                    <div className="text-[10px] text-slate-400 mt-1 flex items-center gap-1.5 font-mono">
                      <MapPin size={11} className="text-amber-400 shrink-0" />
                      <span className="truncate">
                        {troubledDriver.location
                          ? `Lat: ${troubledDriver.location.lat.toFixed(4)}, Lng: ${troubledDriver.location.lng.toFixed(4)}`
                          : 'Location streaming'}
                      </span>
                    </div>
                    <div className="text-[10px] text-slate-400 mt-0.5 flex items-center gap-1.5 font-mono">
                      <Truck size={11} className="text-slate-400 shrink-0" />
                      <span className="truncate">
                        Target: {troubledDriver.deliveryTo || `${activeRegion.name} Delivery Hub`}
                      </span>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="p-3 text-xs text-slate-400 text-center">No driver selected</div>
              )}

              <div className="text-[10px] text-amber-300/90 leading-relaxed font-mono bg-amber-950/40 p-2.5 rounded-lg border border-amber-500/20">
                ✓ Original driver retains <strong>30% base compensation (₹{troubledSplit})</strong> for cargo pickup & handover.
              </div>
            </div>
          </div>

          {/* MIDDLE COLUMN: Active Candidate Drivers in Region (Click to Select) */}
          <div className="lg:col-span-5 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-black uppercase tracking-widest text-cyan-400 flex items-center gap-1.5">
                <span className="h-2 w-2 rounded-full bg-cyan-400 animate-ping" />
                STEP 2 · ACTIVE DRIVERS IN {activeRegion.name.toUpperCase()} (CLICK TO PICK)
              </span>
              <span className="text-[10px] font-mono text-cyan-300 bg-cyan-950/60 px-2 py-0.5 rounded border border-cyan-500/30">
                {candidates.length} Available
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-[220px] overflow-y-auto pr-1">
              {candidates.length === 0 ? (
                <div className="col-span-2 p-6 rounded-2xl bg-slate-900 border border-slate-800 text-center text-xs text-slate-400">
                  No other drivers detected in {activeRegion.name}.
                </div>
              ) : (
                candidates.map(({ driver: cand, distKm, etaMin }) => {
                  const isSelected = candidateRelayDriver?.id === cand.id
                  const isOnline = cand.status !== 'offline'
                  const cleanName = cand.name.replace(/\s+applicant/gi, '').trim()

                  return (
                    <div
                      key={cand.id}
                      onClick={() => onSelectCandidateDriver(cand.id)}
                      className={cn(
                        'p-3 rounded-2xl border-2 transition-all cursor-pointer flex flex-col justify-between gap-2 text-left relative overflow-hidden',
                        isSelected
                          ? 'bg-gradient-to-br from-cyan-950/90 to-slate-900 border-cyan-400 shadow-[0_0_25px_rgba(6,182,212,0.4)] ring-2 ring-cyan-400/30'
                          : 'bg-slate-900/80 border-slate-800 hover:border-cyan-500/50 hover:bg-slate-900'
                      )}
                    >
                      {isSelected && (
                        <div className="absolute top-2 right-2 h-5 w-5 rounded-full bg-cyan-400 text-slate-950 flex items-center justify-center font-black shadow-md">
                          ✓
                        </div>
                      )}

                      <div className="flex items-center gap-2.5">
                        <Avatar name={cleanName} size={34} />
                        <div className="min-w-0 flex-1">
                          <h5 className="text-xs font-black text-white truncate">{cleanName}</h5>
                          <div className="flex items-center gap-1.5 mt-0.5">
                            <span
                              className={cn(
                                'h-1.5 w-1.5 rounded-full',
                                isOnline ? 'bg-emerald-400 animate-pulse' : 'bg-slate-500'
                              )}
                            />
                            <span className="text-[9px] font-bold text-slate-400 uppercase">
                              {isOnline ? `${cand.speed || 0} km/h` : 'Offline (Last GPS)'}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between text-[10px] font-mono">
                        <span className="text-cyan-300 font-bold flex items-center gap-1">
                          <Navigation size={10} className="text-cyan-400" />
                          {distKm} km
                        </span>
                        <span className="text-slate-400 flex items-center gap-1">
                          <Clock size={10} />
                          ~{etaMin}m ETA
                        </span>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
            <div className="text-[10px] text-slate-400 font-medium">
              💡 Tip: You can also <strong>click any driver pin directly on the live map</strong> to select them as the relay candidate.
            </div>
          </div>

          {/* RIGHT COLUMN: 70/30 Split Breakdown & One-Click Execution */}
          <div className="lg:col-span-3 flex flex-col justify-between gap-3 bg-slate-900/90 p-4 rounded-2xl border border-slate-800">
            <div>
              <span className="text-[10px] font-black uppercase tracking-widest text-emerald-400 flex items-center gap-1.5 mb-2">
                <Coins size={12} className="text-emerald-400" />
                STEP 3 · 70/30 SPLIT & AUTHORIZE
              </span>

              {/* Revenue Card */}
              <div className="space-y-2 p-3 rounded-xl bg-slate-950/80 border border-slate-800 font-mono text-xs">
                <div className="flex items-center justify-between text-amber-300">
                  <span>30% Original ({troubledDriver?.name.split(' ')[0] || 'Origin'}):</span>
                  <span className="font-black text-sm">₹{troubledSplit}</span>
                </div>
                <div className="flex items-center justify-between text-emerald-400">
                  <span>70% Relay ({candidateRelayDriver?.name.split(' ')[0] || 'Candidate'}):</span>
                  <span className="font-black text-sm">₹{relaySplit}</span>
                </div>
                <div className="pt-1.5 border-t border-slate-800 flex items-center justify-between text-slate-400 text-[10px]">
                  <span>Total Consignment Payout:</span>
                  <span className="font-bold text-white">₹{totalAmount}</span>
                </div>
              </div>
            </div>

            {/* Success Message Banner */}
            {successMessage && (
              <div className="p-2.5 rounded-xl bg-emerald-950/80 border border-emerald-500/60 text-emerald-200 text-xs font-medium flex items-start gap-2 animate-in fade-in">
                <CheckCircle2 size={16} className="text-emerald-400 shrink-0 mt-0.5" />
                <span className="leading-snug">{successMessage}</span>
              </div>
            )}

            {/* Assignment Button */}
            <button
              onClick={onAssignRelay}
              disabled={isAssigning || !troubledDriver || !candidateRelayDriver}
              className={cn(
                'w-full py-3.5 px-4 rounded-2xl font-black text-xs uppercase tracking-wider transition-all shadow-xl flex items-center justify-center gap-2 cursor-pointer active:scale-95',
                isAssigning || !troubledDriver || !candidateRelayDriver
                  ? 'bg-slate-800 text-slate-500 cursor-not-allowed border border-slate-700'
                  : 'bg-gradient-to-r from-cyan-500 via-blue-500 to-emerald-500 hover:from-cyan-400 hover:to-emerald-400 text-slate-950 shadow-cyan-500/30'
              )}
            >
              {isAssigning ? (
                <>
                  <Loader2 size={16} className="animate-spin text-slate-950" />
                  <span>TRANSMITTING RELAY...</span>
                </>
              ) : (
                <>
                  <UserCheck size={16} />
                  <span>
                    ASSIGN RELAY TO {candidateRelayDriver?.name.split(' ')[0].toUpperCase() || 'DRIVER'} ➔
                  </span>
                </>
              )}
            </button>
            <div className="text-[9px] text-center text-slate-400 font-mono">
              Both drivers will be notified in real time on their mobile devices
            </div>
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  )
}
