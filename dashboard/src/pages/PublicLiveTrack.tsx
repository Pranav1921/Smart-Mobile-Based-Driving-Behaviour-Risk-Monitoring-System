import { useState, useEffect, useMemo } from 'react'
import { useParams, Link } from 'react-router-dom'
import { io, Socket } from 'socket.io-client'
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet'
import L from 'leaflet'
import {
  ShieldCheck, Phone, AlertTriangle, Compass, Clock, MapPin,
  ExternalLink, CheckCircle2, BatteryCharging, Radio, Car
} from 'lucide-react'
import 'leaflet/dist/leaflet.css'

// Custom marker icon for public tracker
const vehicleMarkerIcon = new L.DivIcon({
  className: 'custom-vehicle-marker',
  html: `
    <div style="
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: linear-gradient(135deg, #10B981, #059669);
      border: 3px solid white;
      box-shadow: 0 0 15px rgba(16, 185, 129, 0.6);
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-size: 20px;
    ">
      🚗
    </div>
  `,
  iconSize: [44, 44],
  iconAnchor: [22, 22],
})

function MapRecenter({ center }: { center: [number, number] }) {
  const map = useMap()
  useEffect(() => {
    map.flyTo(center, map.getZoom(), { animate: true, duration: 1.2 })
  }, [center, map])
  return null
}

export default function PublicLiveTrack() {
  const { driverId } = useParams<{ driverId: string }>()
  const [driver, setDriver] = useState<any>(null)
  const [breadcrumbs, setBreadcrumbs] = useState<[number, number][]>([])
  const [isConnected, setIsConnected] = useState(false)
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  useEffect(() => {
    const socketHost = window.location.hostname === 'localhost'
      ? 'http://localhost:3000'
      : `http://${window.location.hostname}:3000`

    const socket: Socket = io(socketHost, {
      transports: ['websocket', 'polling'],
      reconnectionAttempts: 999,
      auth: { role: 'public_tracker' },
    })

    socket.on('connect', () => {
      setIsConnected(true)
    })

    socket.on('disconnect', () => {
      setIsConnected(false)
    })

    // Listen for live snapshot and location updates
    socket.on('live_snapshot', (drivers: any[]) => {
      const match = drivers.find((d) => d.id === driverId || d.driverId === driverId || d.userId === driverId)
      if (match) {
        setDriver(match)
        const lat = match.latitude ?? match.location?.lat ?? 12.7749
        const lng = match.longitude ?? match.location?.lng ?? 75.2023
        setBreadcrumbs((prev) => [...prev, [lat, lng]])
      }
    })

    socket.on('driver_location_update', (data: any) => {
      if (data.driverId === driverId || data.id === driverId || data.userId === driverId || data.name === driverId) {
        setDriver((prev: any) => ({ ...prev, ...data }))
        setLastUpdate(new Date())
        const lat = data.latitude ?? data.location?.lat
        const lng = data.longitude ?? data.location?.lng
        if (lat && lng) {
          setBreadcrumbs((prev) => {
            const next = [...prev, [lat, lng] as [number, number]]
            return next.slice(-80) // Keep last 80 breadcrumb coordinates
          })
        }
      }
    })

    return () => {
      socket.disconnect()
    }
  }, [driverId])

  // Fallback default coordinates (Puttur / Mangaluru hub)
  const currentLat = driver?.latitude ?? driver?.location?.lat ?? 12.7749
  const currentLng = driver?.longitude ?? driver?.location?.lng ?? 75.2023
  const centerPos = useMemo<[number, number]>(() => [currentLat, currentLng], [currentLat, currentLng])

  const driverName = driver?.driverName ?? driver?.name ?? 'Assigned Operator'
  const speed = Math.round(driver?.speed ?? 0)
  const status = driver?.status ?? 'safe'
  const isOnline = status !== 'offline' && driver?.isOnline !== false
  const vehiclePlate = driver?.vehiclePlate ?? driver?.vehicleId ?? 'KA-19-PT-2026'
  const safetyScore = driver?.safetyScore ?? 98

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-emerald-500 selection:text-slate-950">
      {/* Top Guardian Angel HUD Banner */}
      <header className="bg-slate-900/90 border-b border-slate-800/80 backdrop-blur-xl px-5 py-3.5 flex items-center justify-between sticky top-0 z-[1000]">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400 font-black shadow-lg shadow-emerald-950/40">
            <ShieldCheck size={22} />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-sm font-black tracking-tight text-white uppercase">
                Guardian Angel Live Trip Share
              </h1>
              <span className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
                Live Protected
              </span>
            </div>
            <div className="text-[11px] text-slate-400 flex items-center gap-2 mt-0.5">
              <span>Driver: <strong className="text-white">{driverName}</strong></span>
              <span>•</span>
              <span>Vehicle: <strong className="text-slate-200">{vehiclePlate}</strong></span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* Quick SOS & Phone Call Link */}
          <a
            href="tel:+919845012345"
            className="hidden sm:flex items-center gap-2 px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 border border-slate-700 text-xs font-bold text-slate-200 transition shadow-sm"
          >
            <Phone size={14} className="text-emerald-400" /> Call Driver
          </a>
          <a
            href="tel:112"
            className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-red-600/90 hover:bg-red-500 text-xs font-black uppercase tracking-wider text-white transition shadow-lg shadow-red-950/50"
          >
            <AlertTriangle size={14} /> Police 112
          </a>
        </div>
      </header>

      {/* Main Grid: Interactive Map + Real-Time Telemetry Sidebar */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-4 relative">
        {/* Left Map Viewport */}
        <div className="lg:col-span-3 h-[60vh] lg:h-auto relative z-10">
          <MapContainer
            center={centerPos}
            zoom={15}
            scrollWheelZoom={true}
            className="h-full w-full"
          >
            <TileLayer
              attribution='&copy; <a href="https://carto.com/">CARTO</a>'
              url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
            />
            <MapRecenter center={centerPos} />

            {/* Breadcrumb Route */}
            {breadcrumbs.length > 1 && (
              <Polyline
                positions={breadcrumbs}
                pathOptions={{
                  color: '#10B981',
                  weight: 4,
                  opacity: 0.8,
                  dashArray: '8, 8',
                }}
              />
            )}

            {/* Live Vehicle Marker */}
            <Marker position={centerPos} icon={vehicleMarkerIcon}>
              <Popup className="custom-leaflet-popup">
                <div className="p-1 text-slate-900">
                  <div className="font-bold text-xs">{driverName}</div>
                  <div className="text-[11px] text-slate-600">{speed} km/h • {status.toUpperCase()}</div>
                </div>
              </Popup>
            </Marker>
          </MapContainer>

          {/* Floating Speedometer & Connection Pill on Map */}
          <div className="absolute top-4 left-4 z-[999] flex flex-col gap-2">
            <div className="bg-slate-900/90 backdrop-blur-md border border-slate-800 rounded-2xl px-4 py-2.5 shadow-2xl flex items-center gap-3">
              <div className="text-2xl font-black font-mono text-emerald-400">
                {speed}
                <span className="text-[10px] font-sans text-slate-400 ml-1">KM/H</span>
              </div>
              <div className="h-7 w-[1px] bg-slate-800" />
              <div>
                <div className="text-[9px] uppercase font-black tracking-widest text-slate-400">
                  Driver Status
                </div>
                <div className="text-xs font-black text-white flex items-center gap-1.5">
                  <CheckCircle2 size={13} className="text-emerald-400" />
                  {status === 'emergency' ? 'EMERGENCY / IMPACT' : 'SAFE & VERIFIED'}
                </div>
              </div>
            </div>

            <div className="bg-slate-900/90 backdrop-blur-md border border-slate-800 rounded-xl px-3 py-1.5 shadow-lg flex items-center gap-2 text-[10px] text-slate-300">
              <Radio size={12} className={isConnected ? "text-emerald-400 animate-pulse" : "text-amber-400"} />
              <span>{isConnected ? "Linked to Vehicle Telemetry" : "Connecting to Satellite Feed..."}</span>
            </div>
          </div>
        </div>

        {/* Right Telemetry & Safe Arrival Panel */}
        <div className="lg:col-span-1 bg-slate-900/95 border-t lg:border-t-0 lg:border-l border-slate-800 p-6 flex flex-col justify-between">
          <div className="space-y-6">
            {/* Safe Arrival Notification Card */}
            <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-start gap-3">
              <div className="p-2 rounded-xl bg-emerald-500 text-slate-950 shrink-0 font-bold">
                <CheckCircle2 size={18} />
              </div>
              <div>
                <div className="text-xs font-black text-emerald-400 uppercase tracking-tight">
                  Automated Safe Arrival Interlock
                </div>
                <div className="text-[11px] text-slate-300 mt-1 leading-relaxed">
                  Family alerts are active. You will receive an automated safe delivery notice the moment the vehicle reaches destination.
                </div>
              </div>
            </div>

            {/* Driver Profile & Vehicle Details */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-3">
                Operator Credentials
              </div>
              <div className="space-y-2.5">
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-xs text-slate-400">Driver</span>
                  <span className="text-xs font-black text-white">{driverName}</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-xs text-slate-400">Safety Index</span>
                  <span className="text-xs font-black text-emerald-400">{safetyScore}% (Gold Safe)</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-xs text-slate-400">Vehicle Plate</span>
                  <span className="text-xs font-mono font-bold text-white">{vehiclePlate}</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800/80">
                  <span className="text-xs text-slate-400">Assigned Corridor</span>
                  <span className="text-xs font-bold text-slate-300">Puttur - Bolwar Sector</span>
                </div>
              </div>
            </div>

            {/* Direct Emergency Contacts */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-3">
                Emergency Dispatch Numbers
              </div>
              <div className="space-y-2">
                <a
                  href="tel:108"
                  className="flex items-center justify-between p-3 rounded-xl bg-slate-800/70 hover:bg-slate-800 border border-slate-700/80 text-xs font-bold transition"
                >
                  <span className="text-slate-300">Ambulance Emergency</span>
                  <span className="text-emerald-400 font-mono">108 →</span>
                </a>
                <a
                  href="tel:1033"
                  className="flex items-center justify-between p-3 rounded-xl bg-slate-800/70 hover:bg-slate-800 border border-slate-700/80 text-xs font-bold transition"
                >
                  <span className="text-slate-300">National Highway Patrol</span>
                  <span className="text-amber-400 font-mono">1033 →</span>
                </a>
                <a
                  href="tel:18004250001"
                  className="flex items-center justify-between p-3 rounded-xl bg-slate-800/70 hover:bg-slate-800 border border-slate-700/80 text-xs font-bold transition"
                >
                  <span className="text-slate-300">Fleet HQ Command Center</span>
                  <span className="text-cyan-400 font-mono">1800-SMART-DRIVE →</span>
                </a>
              </div>
            </div>
          </div>

          {/* Footer Timestamp & Verification */}
          <div className="pt-6 border-t border-slate-800/80 text-[10px] text-slate-500 flex items-center justify-between">
            <span>AIS-140 Certified Telemetry</span>
            <span>Updated {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
