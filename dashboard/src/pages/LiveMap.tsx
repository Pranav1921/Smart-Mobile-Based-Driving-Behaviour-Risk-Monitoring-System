import { useEffect, useState, useMemo, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Radio, Layers, MapPin, Crosshair, ChevronRight, Activity, Zap, Shield, ShieldAlert, Smartphone, BatteryLow, SatelliteDish, Flame, Send, Volume2 } from 'lucide-react'
import { FleetMap, MAP_PROVIDERS } from '@/components/map/FleetMap'
import { VehiclePanel } from '@/components/map/VehiclePanel'
import { DispatchOrderModal } from '@/components/map/DispatchOrderModal'
import { VoiceBroadcastModal } from '@/components/broadcast/VoiceBroadcastModal'
import { GeofenceModal } from '@/components/map/GeofenceModal'
import { cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'
import { getRegionById, getOrGenerateRegion, resolveActiveRegion, type RegionOption, PREDEFINED_REGIONS } from '@/data/regionsData'
import { isDriverInRegion } from '@/lib/regionMatcher'

const LEGEND = [
  { c: '#00FF9D', label: 'Online' },
  { c: '#F59E0B', label: 'Warning' },
  { c: '#FF2D55', label: 'SOS' },
  { c: '#3b82f6', label: 'Standby' },
]

export default function LiveMap() {
  const { liveDrivers, livePotholes, liveGeofences, emitCreateGeofence, emitDeleteGeofence, isConnected, crashAlertDriver } = useSocket()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [hasClosedManually, setHasClosedManually] = useState<boolean>(false)
  const hasInitialAutoSelectedRef = useRef<boolean>(false)
  const [mapMode, setMapMode] = useState<string>('google-satellite')
  const [isFullMap, setIsFullMap] = useState<boolean>(false)
  const [showPotholes, setShowPotholes] = useState<boolean>(true)
  const [isDispatchModalOpen, setIsDispatchModalOpen] = useState<boolean>(false)
  const [isVoiceModalOpen, setIsVoiceModalOpen] = useState<boolean>(false)
  const [isGeofenceModalOpen, setIsGeofenceModalOpen] = useState<boolean>(false)

  const [selectedRegion, setSelectedRegion] = useState<RegionOption>(() => resolveActiveRegion())

  useEffect(() => {
    const handleRegionUpdate = () => {
      setSelectedRegion(resolveActiveRegion())
    }
    window.addEventListener('smartdrive_region_updated', handleRegionUpdate)
    window.addEventListener('storage', handleRegionUpdate)
    return () => {
      window.removeEventListener('smartdrive_region_updated', handleRegionUpdate)
      window.removeEventListener('storage', handleRegionUpdate)
    }
  }, [])

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const urlDriverId = params.get('driverId')
    const targetId = urlDriverId || localStorage.getItem('select_driver_id')
    if (targetId) {
      setSelectedId(targetId)
      setHasClosedManually(false)
      localStorage.removeItem('select_driver_id')
    }
  }, [])

  useEffect(() => {
    if (crashAlertDriver?.driverId || crashAlertDriver?.id) {
      setSelectedId(crashAlertDriver.driverId || crashAlertDriver.id)
      setHasClosedManually(false)
    }
  }, [crashAlertDriver])

  useEffect(() => {
    const handleOpenDispatch = () => {
      setIsDispatchModalOpen(true)
    }
    window.addEventListener('smartdrive_dispatch_to_coords', handleOpenDispatch)
    return () => window.removeEventListener('smartdrive_dispatch_to_coords', handleOpenDispatch)
  }, [])

  const regionalDrivers = useMemo(() => {
    // Strictly isolate drivers to only the admin's active region and filter out phantom IDs
    const filtered = liveDrivers.filter(d => isDriverInRegion(d, selectedRegion.id) && d.id !== 'agent-x' && d.id !== 'mobile-driver');
    const baseList = filtered.length === 0 && liveDrivers.some(d => d.status !== 'offline')
      ? liveDrivers.filter(d => (d.status !== 'offline' || isDriverInRegion(d, selectedRegion.id)) && d.id !== 'agent-x' && d.id !== 'mobile-driver')
      : filtered;

    const seen = new Set<string>();
    return baseList.filter(d => {
      const key = (d.name || d.id || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }, [liveDrivers, selectedRegion.id]);

  // Auto-select the first active streaming driver only once on initial load
  useEffect(() => {
    if (!hasInitialAutoSelectedRef.current && !selectedId && !hasClosedManually && regionalDrivers.length > 0) {
      const active = regionalDrivers.find(d => d.status !== 'offline');
      if (active) {
        setSelectedId(active.id);
        hasInitialAutoSelectedRef.current = true;
      }
    }
  }, [regionalDrivers, selectedId, hasClosedManually]);

  const handleSelectDriver = (id: string | null) => {
    setSelectedId(id)
    if (id) {
      setHasClosedManually(false)
    } else {
      setHasClosedManually(true)
    }
  }

  const selected = regionalDrivers.find((d) => d.id === selectedId) ?? null

  return (
    <div className="h-[calc(100vh-4rem)] w-full overflow-hidden bg-slate-950 relative">
      <FleetMap
        drivers={regionalDrivers}
        selectedId={selectedId}
        onSelect={handleSelectDriver}
        showHeat={false}
        potholes={livePotholes}
        showPotholes={showPotholes}
        geofences={liveGeofences}
        onDeleteGeofence={emitDeleteGeofence}
        mapMode={mapMode}
        activeRegion={selectedRegion}
        isFullMap={isFullMap}
      />

      {/* SLEEK MINIMAL HUD - TOP LEFT SECTOR & DRIVER SELECTOR */}
      <div className="absolute top-4 left-4 z-[400] flex items-center gap-2 pointer-events-none">
        <div className="bg-slate-950/90 backdrop-blur-xl rounded-2xl h-11 px-4 border border-slate-700/60 shadow-2xl pointer-events-auto flex items-center gap-3">
          <div className="flex items-center gap-2">
            <span className={cn("w-2.5 h-2.5 rounded-full", isConnected ? "bg-emerald-400 shadow-[0_0_10px_#10b981]" : "bg-rose-500 animate-pulse")} />
            <span className="text-xs font-black uppercase text-white tracking-wide">{selectedRegion.name}</span>
          </div>
          <div className="h-4 w-[1px] bg-slate-700" />
          <div className="flex items-center gap-1.5">
            <Crosshair className="h-3.5 w-3.5 text-slate-400" />
            <select
              value={selectedId || ''}
              onChange={(e) => handleSelectDriver(e.target.value || null)}
              className="bg-transparent text-[11px] font-bold uppercase text-emerald-400 outline-none cursor-pointer pr-1"
            >
              <option value="" className="bg-slate-900 text-slate-300">All Vehicles ({regionalDrivers.length})</option>
              {regionalDrivers.map((d) => (
                <option key={d.id} value={d.id} className="bg-slate-900 text-white font-semibold">
                  {d.name.toUpperCase()} ({d.status.toUpperCase()})
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* SLEEK MINIMAL HUD - TOP RIGHT ACTIONS BAR */}
      <div className="absolute top-4 right-4 z-[400] flex items-center gap-2 pointer-events-none flex-wrap justify-end">
        <div className="bg-slate-950/90 backdrop-blur-xl rounded-2xl h-11 pl-3 pr-2 flex items-center gap-2 border border-slate-700/60 shadow-2xl pointer-events-auto">
          <Layers className="h-3.5 w-3.5 text-sky-400" />
          <select
            value={mapMode}
            onChange={(e) => setMapMode(e.target.value)}
            className="bg-transparent text-[10px] font-bold uppercase text-white outline-none cursor-pointer pr-2"
          >
            {Object.entries(MAP_PROVIDERS).map(([key, provider]) => (
              <option key={key} value={key} className="bg-slate-900 text-white font-semibold">{provider.name}</option>
            ))}
          </select>
        </div>

        <button
          onClick={() => setIsVoiceModalOpen(true)}
          className="h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer bg-gradient-to-r from-cyan-500 to-blue-500 hover:from-cyan-400 text-slate-950 flex items-center gap-1.5 active:scale-95"
          title="Broadcast Voice Announcement"
        >
          <Volume2 size={13} className="animate-pulse" />
          <span>Voice</span>
        </button>

        <button
          onClick={() => setIsDispatchModalOpen(true)}
          className="h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer bg-emerald-500 hover:bg-emerald-400 text-slate-950 flex items-center gap-1.5 active:scale-95"
        >
          <Send size={12} />
          <span>Dispatch</span>
        </button>

        <button
          onClick={() => setShowPotholes(!showPotholes)}
          className={cn(
            "h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer border flex items-center gap-1.5 active:scale-95",
            showPotholes
              ? "bg-rose-500/20 text-rose-300 border-rose-500/50 shadow-rose-500/20"
              : "bg-slate-900/90 text-slate-400 border-slate-700 hover:text-white"
          )}
        >
          <span className={cn("w-2 h-2 rounded-full", showPotholes ? "bg-rose-500 animate-ping" : "bg-slate-500")} />
          <span>Hazards ({livePotholes.length})</span>
        </button>

        <button
          onClick={() => setIsFullMap(!isFullMap)}
          className={cn(
            "h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer border-0 active:scale-95",
            isFullMap
              ? "bg-sky-400 hover:bg-sky-300 text-slate-950"
              : "bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700"
          )}
        >
          {isFullMap ? 'Focus' : 'Global'}
        </button>
      </div>

      {/* SELECTION PANEL */}
      <VehiclePanel driver={selected} onClose={() => handleSelectDriver(null)} />

      {/* MISSION DISPATCHER MODAL */}
      <DispatchOrderModal
        isOpen={isDispatchModalOpen}
        onClose={() => setIsDispatchModalOpen(false)}
        drivers={regionalDrivers}
        selectedDriverId={selectedId}
      />

      {/* VOICE INTERCOM BROADCAST MODAL */}
      <VoiceBroadcastModal
        isOpen={isVoiceModalOpen}
        onClose={() => setIsVoiceModalOpen(false)}
        activeRegionName={selectedRegion.name}
      />

      {/* DYNAMIC GEOFENCE MODAL */}
      <GeofenceModal
        isOpen={isGeofenceModalOpen}
        onClose={() => setIsGeofenceModalOpen(false)}
        onSave={(newZone) => emitCreateGeofence(newZone)}
        initialCoords={selectedRegion.center}
        activeRegionId={selectedRegion.id}
      />
    </div>
  )
}
