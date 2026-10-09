import { useState, useMemo, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, Tooltip, Circle, useMap } from 'react-leaflet'
import L from 'leaflet'
import {
  X, AlertTriangle, ShieldAlert, Navigation2, CheckCircle2,
  Package, DollarSign, Clock, User, Phone, Car, ArrowRight,
  Sparkles, Radio, Send, Check
} from 'lucide-react'
import type { Driver } from '@/types'
import { useSocket } from '@/hooks/SocketContext'
import { cn } from '@/lib/utils'

interface PartnershipRelayModalProps {
  isOpen: boolean
  onClose: () => void
  troubledDriver: Driver | null
  activeOrder?: {
    orderId?: string
    customerName?: string
    items?: string[]
    pickupAddress?: string
    dropAddress?: string
    dropLat?: number
    dropLng?: number
    amount?: number
  } | null
}

function computeDistKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return Math.round(R * c * 100) / 100
}

function RecenterMap({ coords }: { coords: [number, number] }) {
  const map = useMap()
  useEffect(() => {
    map.flyTo(coords, 14, { duration: 1.2 })
  }, [coords, map])
  return null
}

export function PartnershipRelayModal({ isOpen, onClose, troubledDriver, activeOrder }: PartnershipRelayModalProps) {
  const { liveDrivers, socket } = useSocket()

  // Base coordinates for troubled driver
  const troubledLat = troubledDriver?.location?.lat ?? (troubledDriver as any)?.latitude ?? 12.7749
  const troubledLng = troubledDriver?.location?.lng ?? (troubledDriver as any)?.longitude ?? 75.2023

  // Destination drop point (defaults to urban hub nearby if unspecified)
  const defaultDropLat = +(troubledLat + 0.015).toFixed(4)
  const defaultDropLng = +(troubledLng + 0.018).toFixed(4)
  const dropLat = activeOrder?.dropLat ?? defaultDropLat
  const dropLng = activeOrder?.dropLng ?? defaultDropLng
  const dropAddress = activeOrder?.dropAddress || 'Central Commercial Hub, Mission Drop Point'

  const [totalFee, setTotalFee] = useState<number>(activeOrder?.amount || 150)
  const [selectedRelayDriverId, setSelectedRelayDriverId] = useState<string | null>(null)
  const [isDispatching, setIsDispatching] = useState(false)
  const [dispatchSuccess, setDispatchSuccess] = useState(false)
  const [successInfo, setSuccessInfo] = useState<{ relayName: string; troubledSplit: number; relaySplit: number } | null>(null)

  // Filter ONLY candidate drivers who are nearest to troubled driver
  const nearestCandidates = useMemo(() => {
    if (!troubledDriver) return []
    const tId = troubledDriver.id

    return liveDrivers
      .filter(d => {
        const dId = d.id
        if (dId === tId || dId === 'agent-x') return false
        const lat = d.location?.lat ?? (d as any).latitude
        const lng = d.location?.lng ?? (d as any).longitude
        return lat != null && lng != null && !isNaN(lat) && !isNaN(lng) && lat !== 0
      })
      .map(d => {
        const lat = d.location?.lat ?? (d as any).latitude ?? 12.7749
        const lng = d.location?.lng ?? (d as any).longitude ?? 75.2023
        const dist = computeDistKm(troubledLat, troubledLng, lat, lng)
        const etaMin = Math.max(1, Math.round((dist / 35.0) * 60))
        return {
          ...d,
          computedDist: dist,
          etaMinutes: etaMin,
          candidateLat: lat,
          candidateLng: lng,
        }
      })
      .sort((a, b) => a.computedDist - b.computedDist)
      .slice(0, 6) // Focus exclusively on top 6 nearest candidate drivers
  }, [liveDrivers, troubledDriver, troubledLat, troubledLng])

  // Default select the nearest candidate driver
  useEffect(() => {
    if (nearestCandidates.length > 0 && !selectedRelayDriverId) {
      setSelectedRelayDriverId(nearestCandidates[0].id)
    }
  }, [nearestCandidates, selectedRelayDriverId])

  if (!isOpen || !troubledDriver) return null

  const selectedCandidate = nearestCandidates.find(c => c.id === selectedRelayDriverId) || nearestCandidates[0]

  // Financial Split calculation (30% troubled, 70% relay)
  const troubledPayout = Math.round(totalFee * 0.30)
  const relayPayout = totalFee - troubledPayout

  // Create custom Leaflet markers
  const troubledMarkerIcon = L.divIcon({
    className: 'troubled-driver-marker',
    iconSize: [44, 44],
    iconAnchor: [22, 22],
    html: `
      <div style="position:relative; width:44px; height:44px; display:flex; align-items:center; justify-content:center;">
        <div style="position:absolute; width:44px; height:44px; background:rgba(239, 68, 68, 0.4); border-radius:50%; animation: ping 1.2s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
        <div style="width:36px; height:36px; background:#dc2626; border:3px solid #ffffff; border-radius:50%; box-shadow:0 0 18px rgba(220, 38, 38, 0.9); display:flex; align-items:center; justify-content:center; color:#ffffff; font-size:16px;">
          🚨
        </div>
      </div>
    `,
  })

  const dropMarkerIcon = L.divIcon({
    className: 'destination-drop-marker',
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    html: `
      <div style="width:40px; height:40px; background:#10b981; border:3px solid #ffffff; border-radius:50%; box-shadow:0 0 16px rgba(16, 185, 129, 0.9); display:flex; align-items:center; justify-content:center; color:#ffffff; font-size:16px;">
        📦
      </div>
    `,
  })

  const createCandidateIcon = (name: string, distKm: number, isSelected: boolean) => {
    const initial = name ? name.charAt(0).toUpperCase() : 'D'
    const bg = isSelected ? '#38bdf8' : '#334155'
    const border = isSelected ? '#ffffff' : '#64748b'
    const glow = isSelected ? '0 0 16px rgba(56, 189, 248, 0.9)' : '0 2px 8px rgba(0,0,0,0.5)'
    return L.divIcon({
      className: 'candidate-driver-marker',
      iconSize: [80, 40],
      iconAnchor: [40, 20],
      html: `
        <div style="display:flex; flex-direction:column; align-items:center;">
          <div style="width:32px; height:32px; background:${bg}; border:2.5px solid ${border}; border-radius:50%; box-shadow:${glow}; display:flex; align-items:center; justify-content:center; font-weight:900; font-size:12px; color:#ffffff;">
            ${initial}
          </div>
          <div style="background:#0f172a; border:1px solid ${isSelected ? '#38bdf8' : '#475569'}; border-radius:10px; padding:1px 6px; font-size:9px; font-weight:800; color:#38bdf8; margin-top:-2px; white-space:nowrap; box-shadow:0 2px 6px rgba(0,0,0,0.6);">
            ${distKm.toFixed(1)} km
          </div>
        </div>
      `,
    })
  }

  const handleAuthorizeRelay = () => {
    if (!selectedCandidate) {
      alert('Please select a nearby rescue candidate driver.')
      return
    }

    setIsDispatching(true)

    const relayMissionPayload = {
      orderId: activeOrder?.orderId || `ORD-RELAY-${Date.now()}`,
      troubledDriverId: troubledDriver.id,
      troubledDriverName: troubledDriver.name,
      relayDriverId: selectedCandidate.id,
      relayDriverName: selectedCandidate.name,
      pickupAddress: activeOrder?.pickupAddress || 'Troubled Vehicle Incident Coordinates',
      dropAddress,
      dropLat,
      dropLng,
      totalAmount: totalFee,
      packageItems: activeOrder?.items?.join(', ') || 'Urgent Consignment Package',
      reason: troubledDriver.status === 'emergency' ? 'Incident / Crash Standby Takeover' : 'Admin Partnership Dispatch',
    }

    // Emit socket event to backend socket manager
    if (socket) {
      socket.emit('admin_assign_partnership_relay', relayMissionPayload)
    }

    setTimeout(() => {
      setIsDispatching(false)
      setDispatchSuccess(true)
      setSuccessInfo({
        relayName: selectedCandidate.name,
        troubledSplit: troubledPayout,
        relaySplit: relayPayout,
      })
    }, 800)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-7xl h-[92vh] bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl flex flex-col overflow-hidden text-slate-100">
        
        {/* Top Command Bar */}
        <div className="flex items-center justify-between px-6 py-4 bg-slate-950 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-2xl bg-rose-500/20 border border-rose-500/40 text-rose-400">
              <ShieldAlert className="w-6 h-6 animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md bg-rose-950/80 border border-rose-500/50 text-rose-300">
                  CRISIS PROTOCOL ACTIVE
                </span>
                <span className="text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md bg-sky-950/80 border border-sky-500/50 text-sky-300">
                  PARTNERSHIP DISPATCH RADAR
                </span>
              </div>
              <h2 className="text-lg font-black tracking-tight text-white mt-0.5">
                Full-Screen Tactical Rescue Map & Consignment Handover
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Troubled Driver Status Pill */}
            <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-700">
              <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping" />
              <span className="text-xs font-bold text-white">Troubled: {troubledDriver.name}</span>
              <span className="text-[10px] text-slate-400 font-mono">({troubledDriver.id})</span>
            </div>

            <button
              onClick={onClose}
              className="p-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-400 hover:text-white transition-all cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Modal Body: Split Map & Rescue Drawer */}
        <div className="flex-1 flex flex-col lg:flex-row overflow-hidden relative">
          
          {/* LEFT: Full Tactical Interactive Map */}
          <div className="flex-1 h-[50vh] lg:h-full relative bg-slate-950">
            <MapContainer
              center={[troubledLat, troubledLng]}
              zoom={14}
              style={{ width: '100%', height: '100%', background: '#090d16' }}
              zoomControl={false}
            >
              <RecenterMap coords={[troubledLat, troubledLng]} />

              <TileLayer
                url="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}"
                attribution='&copy; Esri &mdash; Esri, DeLorme, NAVTEQ'
                maxZoom={19}
                maxNativeZoom={16}
              />
              <TileLayer
                url="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}"
                attribution=""
                maxZoom={19}
                maxNativeZoom={16}
              />

              {/* Proximity Corridor Circle around Troubled Driver */}
              <Circle
                center={[troubledLat, troubledLng]}
                radius={3500}
                pathOptions={{ color: '#ef4444', fillColor: '#ef4444', fillOpacity: 0.08, weight: 1.5, dashArray: '6, 6' }}
              />

              {/* Troubled Driver Distress Marker */}
              <Marker position={[troubledLat, troubledLng]} icon={troubledMarkerIcon}>
                <Tooltip permanent direction="top" offset={[0, -22]}>
                  <div className="bg-rose-950 border border-rose-500 text-rose-200 text-[10px] font-black px-2 py-0.5 rounded shadow">
                    🚨 {troubledDriver.name} (CRISIS INCIDENT)
                  </div>
                </Tooltip>
              </Marker>

              {/* Delivery Consignment Destination Marker */}
              <Marker position={[dropLat, dropLng]} icon={dropMarkerIcon}>
                <Tooltip permanent direction="top" offset={[0, -20]}>
                  <div className="bg-emerald-950 border border-emerald-500 text-emerald-200 text-[10px] font-black px-2 py-0.5 rounded shadow">
                    📦 DROP: {dropAddress.split(',')[0]}
                  </div>
                </Tooltip>
              </Marker>

              {/* Nearest Candidate Rescue Drivers Markers */}
              {nearestCandidates.map(cand => (
                <Marker
                  key={cand.id}
                  position={[cand.candidateLat, cand.candidateLng]}
                  icon={createCandidateIcon(cand.name, cand.computedDist, cand.id === selectedCandidate?.id)}
                  eventHandlers={{
                    click: () => setSelectedRelayDriverId(cand.id),
                  }}
                >
                  <Tooltip direction="bottom" offset={[0, 18]}>
                    <div className="bg-slate-900 border border-slate-700 text-white text-[10px] font-bold px-2 py-1 rounded shadow">
                      {cand.name} · {cand.computedDist.toFixed(1)} km away (~{cand.etaMinutes} min)
                    </div>
                  </Tooltip>
                </Marker>
              ))}

              {/* Route: Selected Candidate -> Troubled Driver -> Drop Point */}
              {selectedCandidate && (
                <>
                  {/* Leg 1: Relay Driver to Troubled Driver Handover point (Pulsing Amber) */}
                  <Polyline
                    positions={[
                      [selectedCandidate.candidateLat, selectedCandidate.candidateLng],
                      [troubledLat, troubledLng],
                    ]}
                    pathOptions={{ color: '#f59e0b', weight: 4, dashArray: '8, 8', opacity: 0.9 }}
                  />

                  {/* Leg 2: Handover Point to Final Delivery Drop (Cyan solid) */}
                  <Polyline
                    positions={[
                      [troubledLat, troubledLng],
                      [dropLat, dropLng],
                    ]}
                    pathOptions={{ color: '#38bdf8', weight: 4, opacity: 0.85 }}
                  />
                </>
              )}
            </MapContainer>

            {/* Map Legend Overlay */}
            <div className="absolute top-4 left-4 z-[1000] bg-slate-950/85 backdrop-blur-md border border-slate-800 p-3 rounded-2xl shadow-xl flex flex-col gap-2">
              <div className="text-[10px] font-black uppercase tracking-wider text-slate-400">Tactical Map Legend</div>
              <div className="flex items-center gap-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-rose-500 shadow-[0_0_8px_#ef4444]" />
                <span className="text-white font-medium">Distressed Operator ({troubledDriver.name})</span>
              </div>
              <div className="flex items-center gap-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-sky-400 shadow-[0_0_8px_#38bdf8]" />
                <span className="text-slate-300">Nearest Rescue Candidates ({nearestCandidates.length} Active)</span>
              </div>
              <div className="flex items-center gap-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-emerald-500 shadow-[0_0_8px_#10b981]" />
                <span className="text-slate-300">Consignment Drop Target</span>
              </div>
            </div>
          </div>

          {/* RIGHT: Rescue Fleet Selection & Financial Split Drawer */}
          <div className="w-full lg:w-[460px] bg-slate-900 border-l border-slate-800 flex flex-col overflow-y-auto">
            
            {/* Header */}
            <div className="p-5 border-b border-slate-800 bg-slate-950/50">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-black uppercase tracking-tight text-white flex items-center gap-2">
                    <Radio className="w-4 h-4 text-sky-400 animate-pulse" />
                    Nearest Candidate Drivers ({nearestCandidates.length})
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Proximity-filtered fleet available for immediate consignment takeover.
                  </p>
                </div>
              </div>
            </div>

            {/* Candidate Drivers List */}
            <div className="p-4 space-y-2.5 flex-1">
              {nearestCandidates.length === 0 ? (
                <div className="p-6 text-center text-slate-500 text-xs">
                  No online drivers detected within the 25km operational rescue corridor.
                </div>
              ) : (
                nearestCandidates.map(cand => {
                  const isSelected = cand.id === selectedCandidate?.id
                  return (
                    <div
                      key={cand.id}
                      onClick={() => setSelectedRelayDriverId(cand.id)}
                      className={cn(
                        "p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between group",
                        isSelected
                          ? "bg-sky-950/40 border-sky-500 shadow-[0_0_20px_rgba(56,189,248,0.2)]"
                          : "bg-slate-950/60 border-slate-800 hover:border-slate-700 hover:bg-slate-800/40"
                      )}
                    >
                      <div className="flex items-center gap-3">
                        <div className={cn(
                          "w-10 h-10 rounded-xl flex items-center justify-center font-black text-sm transition-all",
                          isSelected ? "bg-sky-500 text-slate-950 shadow-md" : "bg-slate-800 text-slate-300"
                        )}>
                          {cand.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-bold text-white group-hover:text-sky-300 transition-colors">
                              {cand.name}
                            </span>
                            {isSelected && (
                              <span className="text-[9px] font-black uppercase px-1.5 py-0.5 rounded bg-sky-500 text-slate-950">
                                SELECTED
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                            <span className="font-mono">{cand.vehiclePlate || 'KA-19-PT-2026'}</span>
                            <span>•</span>
                            <span className="text-emerald-400 font-semibold">{cand.computedDist.toFixed(1)} km away</span>
                            <span>•</span>
                            <span className="text-amber-400">~{cand.etaMinutes} min ETA</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center">
                        <div className={cn(
                          "w-5 h-5 rounded-full border flex items-center justify-center transition-all",
                          isSelected ? "bg-sky-500 border-sky-500 text-slate-950" : "border-slate-700"
                        )}>
                          {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                        </div>
                      </div>
                    </div>
                  )
                })
              )}
            </div>

            {/* Consignment & 70/30 Revenue Split Matrix */}
            <div className="p-5 border-t border-slate-800 bg-slate-950/80 space-y-4">
              
              {/* Mission Details */}
              <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800">
                <div className="flex items-center justify-between text-xs text-slate-400 mb-1">
                  <span className="font-bold uppercase tracking-wider text-slate-300 flex items-center gap-1.5">
                    <Package className="w-3.5 h-3.5 text-amber-400" /> Consignment Mission
                  </span>
                  <span className="font-mono text-[10px] text-slate-500">{activeOrder?.orderId || 'ORD-RELAY-771'}</span>
                </div>
                <div className="text-xs text-slate-200 font-medium truncate mt-1">
                  Drop: <span className="text-white font-bold">{dropAddress}</span>
                </div>
              </div>

              {/* 70/30 Revenue Split Card */}
              <div className="p-4 rounded-2xl bg-gradient-to-br from-slate-900 via-slate-900 to-sky-950/30 border border-slate-700">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-1.5">
                    <Sparkles className="w-4 h-4 text-amber-400" />
                    <span className="text-xs font-black uppercase tracking-wider text-white">
                      70 / 30 Revenue Division Matrix
                    </span>
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="text-xs text-slate-400">Total:</span>
                    <span className="text-sm font-black text-white font-mono">₹{totalFee}</span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {/* 30% Troubled Driver Protected Compensation */}
                  <div className="p-3 rounded-xl bg-slate-950/80 border border-rose-500/30">
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-black uppercase text-rose-400">30% BASE SPLIT</span>
                      <span className="text-[9px] px-1 py-0.5 rounded bg-rose-950 text-rose-300 font-bold">PROTECTED</span>
                    </div>
                    <div className="text-lg font-black text-rose-200 font-mono mt-1">₹{troubledPayout}</div>
                    <p className="text-[10px] text-slate-400 mt-1 truncate">
                      Credited to: <strong className="text-white">{troubledDriver.name}</strong>
                    </p>
                  </div>

                  {/* 70% Rescue Relay Driver Delivery Bounty */}
                  <div className="p-3 rounded-xl bg-slate-950/80 border border-sky-500/30">
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-black uppercase text-sky-400">70% RELAY SPLIT</span>
                      <span className="text-[9px] px-1 py-0.5 rounded bg-sky-950 text-sky-300 font-bold">DELIVERY BOUNTY</span>
                    </div>
                    <div className="text-lg font-black text-sky-300 font-mono mt-1">₹{relayPayout}</div>
                    <p className="text-[10px] text-slate-400 mt-1 truncate">
                      Earned by: <strong className="text-white">{selectedCandidate?.name || 'Selected Relay'}</strong>
                    </p>
                  </div>
                </div>
              </div>

              {/* Success Notification Alert */}
              {dispatchSuccess && successInfo && (
                <div className="p-4 rounded-2xl bg-emerald-950/80 border border-emerald-500/60 text-emerald-200 animate-in fade-in slide-in-from-bottom duration-200">
                  <div className="flex items-center gap-2 font-bold text-sm text-emerald-300">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                    Partnership Relay Dispatched!
                  </div>
                  <p className="text-xs text-emerald-200 mt-1">
                    Mission dispatched to <strong>{successInfo.relayName}</strong> for ₹{successInfo.relaySplit} (70%).
                    Base compensation of ₹{successInfo.troubledSplit} (30%) secured for <strong>{troubledDriver.name}</strong>.
                  </p>
                </div>
              )}

              {/* Dispatch Action Button */}
              <button
                onClick={handleAuthorizeRelay}
                disabled={isDispatching || dispatchSuccess || !selectedCandidate}
                className={cn(
                  "w-full py-4 rounded-2xl font-black text-xs uppercase tracking-wider transition-all flex items-center justify-center gap-2 shadow-lg cursor-pointer",
                  dispatchSuccess
                    ? "bg-emerald-500 text-slate-950"
                    : isDispatching
                    ? "bg-sky-600 text-white animate-pulse"
                    : "bg-gradient-to-r from-sky-500 to-blue-600 hover:from-sky-400 hover:to-blue-500 text-slate-950 shadow-sky-500/25 active:scale-[0.99]"
                )}
              >
                {dispatchSuccess ? (
                  <>
                    <CheckCircle2 className="w-4 h-4" />
                    <span>RELAY MISSION CONFIRMED & ACTIVE</span>
                  </>
                ) : isDispatching ? (
                  <>
                    <Radio className="w-4 h-4 animate-spin" />
                    <span>TRANSMITTING RELAY ASSIGNMENT...</span>
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    <span>AUTHORIZE PARTNERSHIP RELAY (70% / 30% SPLIT)</span>
                  </>
                )}
              </button>
            </div>

          </div>

        </div>

      </div>
    </div>
  )
}
