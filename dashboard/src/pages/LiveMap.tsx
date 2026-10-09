import { useEffect, useState, useMemo, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Radio, Layers, MapPin, Crosshair, ChevronRight, Activity, Zap, Shield, ShieldAlert, Smartphone, BatteryLow, SatelliteDish, Flame, Send, Volume2, Truck, Box } from 'lucide-react'
import { FleetMap, MAP_PROVIDERS } from '@/components/map/FleetMap'
import { VehiclePanel } from '@/components/map/VehiclePanel'
import { DispatchOrderModal } from '@/components/map/DispatchOrderModal'
import { VoiceBroadcastModal } from '@/components/broadcast/VoiceBroadcastModal'
import { GeofenceModal } from '@/components/map/GeofenceModal'
import { RegionalRelaySection } from '@/components/map/RegionalRelaySection'
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
  const { liveDrivers, livePotholes, liveGeofences, emitCreateGeofence, emitDeleteGeofence, isConnected, crashAlertDriver, socket } = useSocket()
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [hasClosedManually, setHasClosedManually] = useState<boolean>(false)
  const hasInitialAutoSelectedRef = useRef<boolean>(false)
  const [mapMode, setMapMode] = useState<string>('tactical-dark')
  const [isFullMap, setIsFullMap] = useState<boolean>(false)
  const [is3DView, setIs3DView] = useState<boolean>(false)
  const [showPotholes, setShowPotholes] = useState<boolean>(true)
  const [isDispatchModalOpen, setIsDispatchModalOpen] = useState<boolean>(false)
  const [isVoiceModalOpen, setIsVoiceModalOpen] = useState<boolean>(false)
  const [isGeofenceModalOpen, setIsGeofenceModalOpen] = useState<boolean>(false)

  // 70/30 Regional Fleet Relay state
  const [isRelaySectionOpen, setIsRelaySectionOpen] = useState<boolean>(false)
  const [relayTroubledDriverId, setRelayTroubledDriverId] = useState<string | null>(null)
  const [relayCandidateId, setRelayCandidateId] = useState<string | null>(null)
  const [isAssigningRelay, setIsAssigningRelay] = useState<boolean>(false)
  const [relaySuccessMessage, setRelaySuccessMessage] = useState<string | null>(null)

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
    const params = new URLSearchParams(window.location.search)
    const relayTarget = params.get('relayDriverId') || localStorage.getItem('smartdrive_open_relay_section')
    if (relayTarget) {
      setIsRelaySectionOpen(true)
      setRelayTroubledDriverId(relayTarget)
      localStorage.removeItem('smartdrive_open_relay_section')
    }
  }, [])

  useEffect(() => {
    if (crashAlertDriver?.driverId || crashAlertDriver?.id) {
      const cId = crashAlertDriver.driverId || crashAlertDriver.id
      setSelectedId(cId)
      setRelayTroubledDriverId(cId)
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
    // Only real active drivers matching the selected region or active status!
    const baseList = liveDrivers.filter(d => {
      if (!d || d.id === 'agent-x' || d.id === 'mobile-driver') return false;
      if (d.status === 'emergency' || (d as any).isDeadZone === true || d.status !== 'offline') return true;
      return isDriverInRegion(d, selectedRegion.id);
    });

    const seen = new Set<string>();
    return baseList.filter(d => {
      const key = (d.name || d.id || '').toLowerCase().trim();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }, [liveDrivers, selectedRegion.id]);

  // Compute troubled driver (cargo carrier receiving 30%)
  const troubledDriver = useMemo(() => {
    if (relayTroubledDriverId) {
      const match = regionalDrivers.find((d) => d.id === relayTroubledDriverId)
      if (match) return match
    }
    const emergencyDriver = regionalDrivers.find((d) => d.status === 'emergency')
    if (emergencyDriver) return emergencyDriver
    return regionalDrivers.find((d) => d.id !== 'agent-x' && d.id !== 'mobile-driver') || null
  }, [regionalDrivers, relayTroubledDriverId])

  // Compute selected candidate relay driver (receiving 70%)
  const candidateRelayDriver = useMemo(() => {
    if (!troubledDriver) return null
    if (relayCandidateId && relayCandidateId !== troubledDriver.id) {
      const match = regionalDrivers.find((d) => d.id === relayCandidateId)
      if (match) return match
    }
    return regionalDrivers.find((d) => d.id !== troubledDriver.id && d.id !== 'agent-x' && d.id !== 'mobile-driver') || null
  }, [regionalDrivers, troubledDriver, relayCandidateId])

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

  const handleAssignRelay = () => {
    if (!troubledDriver || !candidateRelayDriver) return
    setIsAssigningRelay(true)
    setRelaySuccessMessage(null)

    const totalAmount = 150
    const troubledSplit = 45 // 30%
    const relaySplit = 105 // 70%

    const cleanTroubledName = (troubledDriver.name || 'Original Driver').replace(/\s+applicant/gi, '').trim()
    const cleanRelayName = (candidateRelayDriver.name || 'Relay Driver').replace(/\s+applicant/gi, '').trim()

    const relayMissionPayload = {
      orderId: 'ORD-RELAY-' + Date.now(),
      troubledDriverId: troubledDriver.id,
      troubledDriverName: cleanTroubledName,
      relayDriverId: candidateRelayDriver.id,
      relayDriverName: cleanRelayName,
      pickupAddress: `${cleanTroubledName}'s Location (${selectedRegion.name})`,
      dropAddress: troubledDriver.deliveryTo || `${selectedRegion.name} Central Logistics Depot`,
      dropLat: troubledDriver.destLat || (troubledDriver.location?.lat ? troubledDriver.location.lat + 0.015 : selectedRegion.center[0]),
      dropLng: troubledDriver.destLng || (troubledDriver.location?.lng ? troubledDriver.location.lng + 0.015 : selectedRegion.center[1]),
      totalAmount,
      troubledDriverSplit: troubledSplit,
      relayDriverSplit: relaySplit,
      reason: 'Admin Tactical 70/30 Regional Map Assignment',
    }

    socket?.emit('admin_assign_partnership_relay', relayMissionPayload)

    setRelaySuccessMessage(
      `Relay Assigned! ₹${relaySplit} (70%) dispatched to ${cleanRelayName}, ₹${troubledSplit} (30%) secured for ${cleanTroubledName}. Both drivers notified in real time on mobile app.`
    )

    setTimeout(() => {
      setIsAssigningRelay(false)
    }, 800)
  }

  const selected = regionalDrivers.find((d) => d.id === selectedId) ?? null

  return (
    <div className={cn("h-[calc(100vh-4rem)] w-full overflow-hidden bg-slate-950 relative", is3DView && "leaflet-perspective-3d")}>
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
        relayTroubledDriver={troubledDriver}
        relayCandidateDriver={candidateRelayDriver}
        isRelayMode={isRelaySectionOpen}
        onSelectRelayCandidate={(driverId) => {
          setRelayCandidateId(driverId)
        }}
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
        {/* 70/30 REGIONAL RELAY TOGGLE BUTTON */}
        <button
          onClick={() => {
            setIsRelaySectionOpen(!isRelaySectionOpen)
            if (!isRelaySectionOpen) {
              setRelaySuccessMessage(null)
            }
          }}
          className={cn(
            "h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer flex items-center gap-1.5 active:scale-95",
            isRelaySectionOpen
              ? "bg-gradient-to-r from-cyan-400 via-sky-400 to-blue-500 text-slate-950 shadow-cyan-500/40 ring-2 ring-cyan-400/50"
              : "bg-slate-950/90 text-cyan-400 border border-cyan-500/40 hover:bg-cyan-950/40"
          )}
          title="Open 70/30 Regional Fleet Relay Section"
        >
          <Truck size={13} className={cn(isRelaySectionOpen && "animate-bounce")} />
          <span>🤝 70/30 Relay</span>
        </button>

        <div className="bg-slate-950/90 backdrop-blur-xl rounded-2xl h-11 pl-3 pr-2 flex items-center gap-2 border border-slate-700/60 shadow-2xl pointer-events-auto">
          <Layers className="h-3.5 w-3.5 text-sky-400" />
          <select
            value={mapMode === 'cartodb-dark' ? 'tactical-dark' : mapMode}
            onChange={(e) => setMapMode(e.target.value)}
            className="bg-transparent text-[10px] font-bold uppercase text-white outline-none cursor-pointer pr-2"
          >
            {Object.entries(MAP_PROVIDERS)
              .filter(([key]) => key !== 'cartodb-dark')
              .map(([key, provider]) => (
                <option key={key} value={key} className="bg-slate-900 text-white font-semibold">{provider.name}</option>
              ))}
          </select>
        </div>

        {/* 3D PERSPECTIVE TILT TOGGLE */}
        <button
          onClick={() => setIs3DView(!is3DView)}
          className={cn(
            "h-11 px-3.5 rounded-2xl font-black text-[10px] uppercase tracking-wider transition-all shadow-xl pointer-events-auto cursor-pointer flex items-center gap-1.5 active:scale-95",
            is3DView
              ? "bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-500 text-slate-950 shadow-emerald-500/40 ring-2 ring-emerald-400/50"
              : "bg-slate-950/90 text-emerald-400 border border-emerald-500/40 hover:bg-emerald-950/40"
          )}
          title="Toggle 3D Cockpit Perspective Tilt"
        >
          <Box size={13} className={cn(is3DView && "animate-pulse text-slate-950")} />
          <span>{is3DView ? '📐 3D Tilt: ON' : '📐 3D Tilt: OFF'}</span>
        </button>

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

      {/* 70/30 REGIONAL FLEET RELAY SECTION (Direct Map Integration) */}
      <RegionalRelaySection
        isOpen={isRelaySectionOpen}
        onClose={() => setIsRelaySectionOpen(false)}
        activeRegion={selectedRegion}
        regionalDrivers={regionalDrivers}
        troubledDriver={troubledDriver}
        candidateRelayDriver={candidateRelayDriver}
        onSelectTroubledDriver={(id) => setRelayTroubledDriverId(id)}
        onSelectCandidateDriver={(id) => setRelayCandidateId(id)}
        onAssignRelay={handleAssignRelay}
        isAssigning={isAssigningRelay}
        successMessage={relaySuccessMessage}
      />

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
