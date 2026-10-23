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

// Custom 3D realistic vehicle marker for public tracker
function getPublicVehicleMarkerIcon(driver: any) {
  const text = `${driver?.vehicleType ?? ''} ${driver?.vehicleName ?? ''} ${driver?.vehiclePlate ?? ''}`.toLowerCase()
  let path = '/markers/vehicle_car.png'
  let width = 38
  let height = 76

  if (text.includes('scoot') || text.includes('activa') || text.includes('dio') || text.includes('ola') || text.includes('ather')) {
    path = '/markers/vehicle_scooter.png'
    width = 30
    height = 68
  } else if (text.includes('auto') || text.includes('rickshaw') || text.includes('3-wheel') || text.includes('tuk')) {
    path = '/markers/vehicle_auto.png'
    width = 38
    height = 66
  } else if (text.includes('bike') || text.includes('motorcycle') || text.includes('pulsar') || text.includes('bullet') || text.includes('2-wheel')) {
    path = '/markers/vehicle_bike.png'
    width = 32
    height = 68
  } else if (text.includes('truck') || text.includes('van') || text.includes('pickup') || text.includes('cargo') || text.includes('lcv')) {
    path = '/markers/vehicle_truck.png'
    width = 46
    height = 92
  }

  const heading = typeof driver?.heading === 'number' ? driver.heading : 0
  const isEmergency = driver?.status === 'emergency'
  const isDeadZone = driver?.isDeadZone === true
  const badgeColor = isEmergency ? '#ef4444' : isDeadZone ? '#06b6d4' : '#10b981'
  const boxW = Math.max(width + 36, 96)
  const boxH = height + 48

  return new L.DivIcon({
    className: 'custom-fleet-vehicle-marker',
    iconSize: [boxW, boxH],
    iconAnchor: [boxW / 2, boxH / 2],
    html: `
      <div style="position:relative;width:${boxW}px;height:${boxH}px;display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;">
        ${isEmergency ? `<div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:${width + 24}px;height:${height + 24}px;border-radius:28px;background:#ef4444;opacity:0.35;animation:pulse 1s infinite;pointer-events:none;"></div>` : ''}

        <!-- Tactical Badge Tag -->
        <div style="
          position:absolute;
          top:0;
          display:flex;
          align-items:center;
          gap:4px;
          background:rgba(10, 15, 29, 0.96);
          border:1.5px solid ${badgeColor};
          box-shadow: 0 4px 14px rgba(0,0,0,0.85);
          border-radius:6px;
          padding:2px 7px;
          z-index:20;
          pointer-events:none;
        ">
          <span style="width:5px;height:5px;border-radius:50%;background:${badgeColor};box-shadow:0 0 6px ${badgeColor};"></span>
          <span style="font-family:ui-monospace, SFMono-Regular, monospace; font-size:10px; font-weight:900; color:#ffffff;">
            ${driver?.vehiclePlate || 'KA-19-PT-2026'}
          </span>
        </div>

        <!-- 3D Realistic Vehicle Model Body with Rotation -->
        <div style="
          position:relative;
          width:${width}px;
          height:${height}px;
          display:flex;
          align-items:center;
          justify-content:center;
          transform:rotate(${heading}deg);
          transition:transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
          filter: drop-shadow(0 12px 22px rgba(0,0,0,0.9)) drop-shadow(0 3px 6px rgba(0,0,0,0.95));
        ">
          <img 
            src="${path}" 
            alt="Vehicle 3D Model" 
            style="width:100%;height:100%;object-fit:contain;pointer-events:none;display:block;" 
          />
        </div>
      </div>
    `,
  })
}

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
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              maxZoom={19}
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
            <Marker position={centerPos} icon={getPublicVehicleMarkerIcon(driver)}>
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
