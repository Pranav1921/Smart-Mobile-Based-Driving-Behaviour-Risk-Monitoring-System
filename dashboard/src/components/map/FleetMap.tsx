import { useMemo, useEffect, useState, Fragment } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, Polygon, useMap, Circle, Tooltip } from 'react-leaflet'
import L from 'leaflet'
import type { Driver, LivePothole } from '@/types'
import type { GeofenceZone } from '@/types/geofence'
import { FLEET_CENTER, contextZones } from '@/data/mockData'
import type { RegionOption } from '@/data/regionsData'
import { useOverpassSchools } from '@/hooks/useOverpassSchools'
import { HeatmapLayer } from '@/components/map/HeatmapLayer'
import { geocodeLocationExternal, searchLocationsExternal, type GeocodedLocation } from '@/services/geocodingService'
import { Search, MapPin, X, Navigation2, Check, Loader2, Sparkles, Send } from 'lucide-react'
import { isDriverInRegion } from '@/lib/regionMatcher'

const STATUS_COLOR: Record<string, string> = {
  safe: '#10b981', warning: '#f59e0b', emergency: '#ef4444', idle: '#3b82f6', offline: '#94a3b8',
}

function LocateControl() {
  const map = useMap()
  const [locating, setLocating] = useState(false)
  const [userLoc, setUserLoc] = useState<[number, number] | null>(null)

  const handleLocate = (e: React.MouseEvent) => {
    e.stopPropagation()
    setLocating(true)
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser")
      setLocating(false)
      return
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords: [number, number] = [pos.coords.latitude, pos.coords.longitude]
        setUserLoc(coords)
        map.flyTo(coords, 16, { duration: 1.5 })
        setLocating(false)
      },
      (err) => {
        alert("Could not access your location: " + err.message)
        setLocating(false)
      },
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  return (
    <>
      <div style={{ position: 'absolute', top: '76px', right: '16px', zIndex: 1000 }}>
        <button
          onClick={handleLocate}
          disabled={locating}
          title="Center to My Exact Location"
          className="bg-white hover:bg-emerald-50 text-emerald-600 border-2 border-emerald-500 rounded-full p-2.5 shadow-xl flex items-center justify-center transition-all hover:scale-105 active:scale-95 cursor-pointer"
        >
          {locating ? (
            <div className="w-5 h-5 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
          ) : (
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <circle cx="12" cy="12" r="4" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 2v3m0 14v3M2 12h3m14 0h3" />
            </svg>
          )}
        </button>
      </div>
      {userLoc && (
        <>
          <Circle center={userLoc} radius={35} pathOptions={{ color: '#10b981', fillColor: '#10b981', fillOpacity: 0.25, weight: 2 }} />
          <Marker position={userLoc} icon={L.divIcon({
            className: 'my-loc-pointer',
            iconSize: [26, 26],
            iconAnchor: [13, 13],
            html: `<div style="width:26px;height:26px;background:#10b981;border:3px solid #fff;border-radius:50%;box-shadow:0 0 14px rgba(16,185,129,0.9);display:flex;align-items:center;justify-content:center;"><div style="width:8px;height:8px;background:#fff;border-radius:50%;"></div></div>`
          })} />
        </>
      )}
    </>
  )
}

// Map Tile Layers Configuration
export interface MapProviderConfig {
  name: string
  url: string
  referenceUrl?: string
  attribution: string
  maxZoom: number
  maxNativeZoom?: number
  className?: string
}

export const MAP_PROVIDERS: Record<string, MapProviderConfig> = {
  'tactical-dark': {
    name: 'Tactical Dark',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    referenceUrl: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri &mdash; Esri, DeLorme, NAVTEQ',
    maxZoom: 19,
    maxNativeZoom: 16,
  },
  'cartodb-dark': {
    name: 'Tactical Dark',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    referenceUrl: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri &mdash; Esri, DeLorme, NAVTEQ',
    maxZoom: 19,
    maxNativeZoom: 16,
  },
  'cyber-dark': {
    name: 'Cyberpunk Dark (OSM)',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19,
    className: 'tactical-dark-tile',
  },
  'google-satellite': {
    name: 'Satellite View',
    url: 'https://mt1.google.com/vt/lyrs=y,traffic&x={x}&y={y}&z={z}',
    attribution: '&copy; Google Satellite',
    maxZoom: 20,
  },
  'openstreetmap': {
    name: 'Road Network',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; OpenStreetMap',
    maxZoom: 19,
  },
}

export type Vehicle3DType = 'scooter' | 'bike' | 'auto' | 'truck' | 'car'

function getVehicleIconDetails(driver: Driver): { path: string; width: number; height: number; type: Vehicle3DType } {
  const text = `${driver.appliedVehicle || ''} ${(driver as any).vehicleType || ''} ${(driver as any).vehicleName || ''} ${(driver as any).vehicleModel || ''} ${driver.vehicleId || ''}`.toLowerCase()
  
  // 1. Scooter / Scooty (Activa, Jupiter, Access, Dio, Moped, EV scooter, etc.)
  if (
    text.includes('scoot') || 
    text.includes('activa') || 
    text.includes('jupiter') || 
    text.includes('access') || 
    text.includes('dio') || 
    text.includes('moped') || 
    text.includes('ather') || 
    text.includes('ola') || 
    text.includes('chetak') || 
    text.includes('pleasure') || 
    text.includes('pep') || 
    text.includes('burgman') || 
    text.includes('ntorq') || 
    text.includes('grazio') || 
    text.includes('ray')
  ) {
    return { path: '/markers/vehicle_scooter.png', width: 30, height: 68, type: 'scooter' }
  }

  // 2. Auto Rickshaw (Three-wheeler / Tuk-Tuk)
  if (
    text.includes('auto') || 
    text.includes('rickshaw') || 
    text.includes('3-wheel') || 
    text.includes('three-wheel') || 
    text.includes('tuk') || 
    text.includes('ape')
  ) {
    return { path: '/markers/vehicle_auto.png', width: 38, height: 66, type: 'auto' }
  }

  // 3. Motorcycle / Bike
  if (
    text.includes('bike') || 
    text.includes('motorcycle') || 
    text.includes('pulsar') || 
    text.includes('splendor') || 
    text.includes('bullet') || 
    text.includes('royal enfield') || 
    text.includes('apache') || 
    text.includes('ktm') || 
    text.includes('fz') || 
    text.includes('shine') || 
    text.includes('platina') || 
    text.includes('2-wheel') || 
    text.includes('two-wheel')
  ) {
    return { path: '/markers/vehicle_bike.png', width: 32, height: 68, type: 'bike' }
  }

  // 4. Heavy Commercial Vehicle / Truck / LCV
  if (
    text.includes('truck') || 
    text.includes('ace') || 
    text.includes('lcv') || 
    text.includes('van') || 
    text.includes('cargo') || 
    text.includes('pickup') || 
    text.includes('bolero') || 
    text.includes('lorry') || 
    text.includes('eicher') || 
    text.includes('dost')
  ) {
    return { path: '/markers/vehicle_truck.png', width: 46, height: 92, type: 'truck' }
  }

  // 5. Default: Car / Cab / Taxi
  return { path: '/markers/vehicle_car.png', width: 38, height: 78, type: 'car' }
}

function getTacticalCode(driver: Driver, type: Vehicle3DType): string {
  const prefix = type === 'truck' ? 'T' : type === 'scooter' ? 'S' : type === 'auto' ? 'A' : type === 'bike' ? 'B' : 'C'
  const digits = (driver.vehicleId || driver.id || '').replace(/[^0-9]/g, '')
  if (digits.length >= 3) {
    return `${prefix}-${digits.slice(-3)}`
  }
  // Deterministic 3-digit number from driver name/id for uniform presentation
  const sum = (driver.name || driver.id || '100').split('').reduce((acc, c) => acc + c.charCodeAt(0), 0)
  const num = (sum % 900) + 100
  return `${prefix}-${num}`
}

function markerIcon(driver: Driver, active: boolean) {
  const isDeadZone = (driver as any).isDeadZone === true
  const isEmergency = driver.status === 'emergency'
  const isOffline = driver.status === 'offline' && !isDeadZone
  const color = isDeadZone ? '#06b6d4' : isEmergency ? '#ef4444' : isOffline ? '#64748b' : (STATUS_COLOR[driver.status] || STATUS_COLOR.safe)
  const pulse = isEmergency || isDeadZone
  const heading = typeof driver.heading === 'number' ? driver.heading : 0
  const vehicle = getVehicleIconDetails(driver)
  const tacticalCode = getTacticalCode(driver, vehicle.type)
  const cleanName = (driver.name || 'Driver').replace(/\s+applicant/gi, '').split(' ')[0]
  
  const vWidth = active ? Math.round(vehicle.width * 1.18) : vehicle.width
  const vHeight = active ? Math.round(vehicle.height * 1.18) : vehicle.height
  const boxW = Math.max(vWidth + 36, 96)
  const boxH = vHeight + 48

  return L.divIcon({
    className: 'custom-fleet-vehicle-marker',
    iconSize: [boxW, boxH],
    iconAnchor: [boxW / 2, boxH / 2],
    html: `
      <div style="position:relative;width:${boxW}px;height:${boxH}px;display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;">
        ${pulse ? `<div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:${vWidth + 24}px;height:${vHeight + 24}px;border-radius:28px;background:${color};opacity:0.35;animation:pulse 1.2s infinite;pointer-events:none;"></div>` : ''}

        <!-- 3D Tactical Callout Tag Badge (e.g. T-102, C-215, B-309) -->
        <div style="
          position:absolute;
          top:0;
          display:flex;
          align-items:center;
          gap:4px;
          background:rgba(10, 15, 29, 0.96);
          border:1.5px solid ${isDeadZone ? '#06b6d4' : isEmergency ? '#ef4444' : '#22c55e'};
          box-shadow: 0 4px 14px rgba(0,0,0,0.85), 0 0 10px ${isDeadZone ? 'rgba(6,182,212,0.45)' : isEmergency ? 'rgba(239,68,68,0.45)' : 'rgba(34,197,94,0.35)'};
          border-radius:6px;
          padding:2px 7px;
          z-index:20;
          pointer-events:none;
        ">
          <span style="width:5px;height:5px;border-radius:50%;background:${color};box-shadow:0 0 6px ${color};"></span>
          <span style="font-family:ui-monospace, SFMono-Regular, Menlo, monospace; font-size:11px; font-weight:900; color:#ffffff; letter-spacing:0.5px;">
            ${tacticalCode}
          </span>
          ${isDeadZone ? `<span style="padding:1px 4px;border-radius:4px;background:#0891b2;color:#fff;font-size:7.5px;font-weight:900;letter-spacing:0.4px;">DEAD ZONE</span>` : ''}
          ${isEmergency ? `<span style="padding:1px 4px;border-radius:4px;background:#dc2626;color:#fff;font-size:7.5px;font-weight:900;animation:pulse 0.8s infinite;">SOS</span>` : ''}
        </div>

        <!-- 3D Realistic Vehicle Body with Rotation & Depth Shadow -->
        <div style="
          position:relative;
          width:${vWidth}px;
          height:${vHeight}px;
          display:flex;
          align-items:center;
          justify-content:center;
          transform:rotate(${heading}deg);
          transition:transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
          filter: drop-shadow(0 12px 22px rgba(0,0,0,0.9)) drop-shadow(0 3px 6px rgba(0,0,0,0.95)) ${isDeadZone ? 'drop-shadow(0 0 12px #06b6d4)' : ''};
        ">
          <img 
            src="${vehicle.path}" 
            alt="${vehicle.type}" 
            style="width:100%;height:100%;object-fit:contain;pointer-events:none;display:block;" 
          />
        </div>

        <!-- Driver Name Pill -->
        <div style="
          position:absolute;
          bottom:0;
          background:rgba(15, 23, 42, 0.95);
          border:1px solid ${color};
          border-radius:9999px;
          padding:1px 7px;
          display:flex;
          align-items:center;
          gap:3px;
          box-shadow:0 3px 8px rgba(0,0,0,0.6);
          pointer-events:none;
        ">
          <span style="width:4px;height:4px;border-radius:50%;background:${color};"></span>
          <span style="font-size:8.5px;font-weight:800;color:#ffffff;white-space:nowrap;max-width:75px;overflow:hidden;text-overflow:ellipsis;">
            ${cleanName}
          </span>
        </div>
      </div>`,
  })
}

function FitRegionBounds({
  activeRegion,
  selectedDriver,
  isFullMap,
}: {
  activeRegion?: RegionOption | null
  selectedDriver?: Driver | null
  isFullMap: boolean
}) {
  const map = useMap()

  // Only smooth-pan to driver if the admin EXPLICITLY clicked on a specific driver
  useEffect(() => {
    if (!map || !selectedDriver?.location) return
    const { lat, lng } = selectedDriver.location
    if (typeof lat === 'number' && typeof lng === 'number' && lat !== 0 && lng !== 0) {
      map.panTo([lat, lng], { animate: true, duration: 1.0 })
    }
  }, [selectedDriver?.id, map])

  // Center/fit region when active region changes - NEVER force high zoom on live updates!
  useEffect(() => {
    if (!map || !activeRegion) return

    try {
      if (isFullMap) {
        map.setMaxBounds(undefined)
        map.flyTo(activeRegion.center, 12, { duration: 1.5 })
      } else {
        if (activeRegion.boundaryPolygon && activeRegion.boundaryPolygon.length >= 3) {
          const bounds = L.latLngBounds(activeRegion.boundaryPolygon as [number, number][])
          if (bounds.isValid()) {
            map.fitBounds(bounds, { padding: [80, 80], maxZoom: 14, animate: true, duration: 1.5 })
          }
        } else {
          map.flyTo(activeRegion.center, 13, { duration: 1.5 })
        }
      }
    } catch (err) {
      map.flyTo(activeRegion.center, 13)
    }
  }, [activeRegion?.id, activeRegion?.center?.[0], activeRegion?.center?.[1], isFullMap, map])

  return null
}

function FollowLiveDriverControl({ targetDriver }: { targetDriver?: Driver | null }) {
  const map = useMap()
  if (!targetDriver || !targetDriver.location || targetDriver.location.lat === 0) return null

  return (
    <div style={{ position: 'absolute', top: '130px', right: '16px', zIndex: 1000 }}>
      <button
        onClick={(e) => {
          e.stopPropagation()
          if (targetDriver.location) {
            map.flyTo([targetDriver.location.lat, targetDriver.location.lng], 17, { duration: 1.2 })
          }
        }}
        title={`Focus Live Driver: ${targetDriver.name}`}
        className="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-[11px] px-3 py-2 rounded-full shadow-2xl flex items-center gap-1.5 transition-all hover:scale-105 active:scale-95 cursor-pointer uppercase tracking-wider"
      >
        <span className="w-2.5 h-2.5 rounded-full bg-slate-950 animate-ping" />
        <span>Live: {targetDriver.name?.split(' ')[0] || 'Driver'}</span>
      </button>
    </div>
  )
}


function externalPinIcon(loc: GeocodedLocation) {
  const shortName = (loc.displayName.split(',')[0] || 'Target').substring(0, 16)
  return L.divIcon({
    className: 'external-geocoded-pin',
    iconSize: [160, 52],
    iconAnchor: [80, 48],
    html: `
      <div style="display:flex;flex-direction:column;align-items:center;cursor:pointer;">
        <div style="
          display:flex;
          align-items:center;
          gap:6px;
          background:rgba(15, 23, 42, 0.96);
          border:1.5px solid #f59e0b;
          box-shadow: 0 8px 24px rgba(245, 158, 11, 0.45), inset 0 0 10px rgba(245, 158, 11, 0.2);
          border-radius:9999px;
          padding:4px 11px;
          backdrop-filter:blur(8px);
          color:#ffffff;
          white-space:nowrap;
          font-family:Inter,system-ui,sans-serif;
        ">
          <span style="width:8px;height:8px;border-radius:50%;background:#f59e0b;box-shadow:0 0 8px #f59e0b;animation:pulse 1s infinite;display:inline-block;"></span>
          <span style="font-size:11px;font-weight:900;color:#fef3c7;letter-spacing:0.02em;">${shortName}</span>
          <span style="font-size:8px;font-weight:800;background:rgba(245,158,11,0.25);color:#fde68a;padding:1px 5px;border-radius:4px;text-transform:uppercase;">${loc.source}</span>
        </div>
        <div style="
          width: 0; 
          height: 0; 
          border-left: 6px solid transparent;
          border-right: 6px solid transparent;
          border-top: 8px solid #f59e0b;
          margin-top: -1px;
        "></div>
      </div>
    `,
  })
}

function MapLegendControl() {
  return (
    <div style={{ position: 'absolute', bottom: '24px', left: '20px', zIndex: 1000, pointerEvents: 'auto' }}>
      <div className="bg-slate-950/92 backdrop-blur-md border border-white/10 rounded-xl px-3.5 py-2.5 shadow-2xl">
        <div className="text-[10px] font-black uppercase text-slate-400 tracking-wider mb-2">Fleet Radar Legend</div>
        <div className="flex flex-col gap-1.5 text-[11px] font-bold">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded bg-emerald-500/25 border-2 border-emerald-400 flex items-center justify-center">
              <span className="w-1 h-1 rounded-full bg-white"></span>
            </span>
            <span className="text-slate-200">Active Corridor Line</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded bg-cyan-500/25 border-2 border-cyan-400"></span>
            <span className="text-cyan-300">Cyan Deadzones (Ghat)</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded bg-rose-500/25 border-2 border-rose-500"></span>
            <span className="text-rose-300">High-Risk / No-Go Zones</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function FleetMap({
  drivers, 
  selectedId, 
  onSelect, 
  showHeat, 
  potholes = [],
  showPotholes = false,
  geofences = [],
  onDeleteGeofence,
  mapMode = 'tactical-dark',
  activeRegion,
  isFullMap = false,
  relayTroubledDriver = null,
  relayCandidateDriver = null,
  isRelayMode = false,
  onSelectRelayCandidate,
}: {
  drivers: Driver[]
  selectedId: string | null
  onSelect: (id: string) => void
  showHeat: boolean
  potholes?: LivePothole[]
  showPotholes?: boolean
  geofences?: GeofenceZone[]
  onDeleteGeofence?: (id: string) => void
  mapMode?: string
  activeRegion?: RegionOption | null
  isFullMap?: boolean
  relayTroubledDriver?: Driver | null
  relayCandidateDriver?: Driver | null
  isRelayMode?: boolean
  onSelectRelayCandidate?: (driverId: string) => void
}) {
  const { schools: osmSchools } = useOverpassSchools(activeRegion ?? null)

  // Marked locations resolved dynamically from external sources
  const [markedLocations, setMarkedLocations] = useState<GeocodedLocation[]>([])

  // Dynamically resolve driver destinations (deliveryTo) from external geocoding sources
  const [resolvedDestMap, setResolvedDestMap] = useState<Record<string, { lat: number; lng: number }>>({})

  // Dynamically verify and geocode active region center from external sources
  const [geocodedSectorCenter, setGeocodedSectorCenter] = useState<[number, number] | null>(null)

  useEffect(() => {
    if (activeRegion?.name) {
      geocodeLocationExternal(activeRegion.name, activeRegion.state, activeRegion.country).then(res => {
        if (res && typeof res.lat === 'number' && typeof res.lng === 'number' && !isNaN(res.lat)) {
          setGeocodedSectorCenter([res.lat, res.lng])
        }
      })
    }
  }, [activeRegion?.name, activeRegion?.state, activeRegion?.country])

  const fallbackLat = (activeRegion?.center && !isNaN(activeRegion.center[0]) && activeRegion.center[0] !== 0) ? activeRegion.center[0] : 12.7749
  const fallbackLng = (activeRegion?.center && !isNaN(activeRegion.center[1]) && activeRegion.center[1] !== 0) ? activeRegion.center[1] : 75.2023

  // Filter by active region with fallback to all drivers if region filter produces 0
  const regionActiveDrivers = useMemo(() => {
    if (!drivers || drivers.length === 0) return []
    if (!activeRegion || !activeRegion.id || activeRegion.id === 'all' || activeRegion.id === 'default') {
      return drivers
    }
    const filtered = drivers.filter(d => {
      if (!d) return false
      if ((d as any).isDeadZone === true || d.status === 'emergency' || d.status !== 'offline') return true
      return isDriverInRegion(d, activeRegion.id)
    })
    return filtered.length > 0 ? filtered : drivers
  }, [drivers, activeRegion])

  // Display all drivers with valid GPS coordinates (stationary, moving, or emergency)
  const validDrivers = useMemo(() => {
    return regionActiveDrivers.filter((d) => {
      if (!d || !d.location) return false
      const lat = d.location.lat
      const lng = d.location.lng
      if (typeof lat !== 'number' || typeof lng !== 'number' || isNaN(lat) || isNaN(lng)) {
        return false
      }
      if (lat === 0 && lng === 0) {
        return false
      }
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return false
      }
      return true
    })
  }, [regionActiveDrivers])

  useEffect(() => {
    validDrivers.forEach(d => {
      if (d.deliveryTo && (!d.destLat || !d.destLng) && !resolvedDestMap[d.deliveryTo]) {
        geocodeLocationExternal(d.deliveryTo, activeRegion?.state || 'Karnataka', activeRegion?.country || 'India').then(res => {
          if (res) {
            setResolvedDestMap(prev => ({ ...prev, [d.deliveryTo!]: { lat: res.lat, lng: res.lng } }))
          }
        })
      }
    })
  }, [validDrivers, activeRegion?.state, activeRegion?.country, resolvedDestMap])
  
  // Only track target driver when explicitly selected by admin
  const selectedDriver = selectedId ? validDrivers.find(d => d.id === selectedId) : null
  const firstActiveDriver = validDrivers.find(d => d.status !== 'offline') || validDrivers[0]
  
  const initialCenter: [number, number] = geocodedSectorCenter || (activeRegion?.center && Array.isArray(activeRegion.center) && activeRegion.center.length === 2 && !isNaN(activeRegion.center[0]) ? activeRegion.center : (firstActiveDriver?.location ? [firstActiveDriver.location.lat, firstActiveDriver.location.lng] : [12.7749, 75.2023]))

  const activeProvider = MAP_PROVIDERS[mapMode] || MAP_PROVIDERS['tactical-dark'] || MAP_PROVIDERS['google-satellite']
  const sectorCenter = geocodedSectorCenter || activeRegion?.center

  return (
    <MapContainer center={initialCenter} zoom={activeRegion?.zoom || 13} zoomControl={false} className="h-full w-full" preferCanvas>
      <TileLayer
        key={mapMode}
        url={activeProvider.url}
        attribution={activeProvider.attribution}
        maxZoom={activeProvider.maxZoom}
        maxNativeZoom={activeProvider.maxNativeZoom}
        className={activeProvider.className}
      />
      {activeProvider.referenceUrl && (
        <TileLayer
          key={`${mapMode}-ref`}
          url={activeProvider.referenceUrl}
          attribution=""
          maxZoom={activeProvider.maxZoom}
          maxNativeZoom={activeProvider.maxNativeZoom}
        />
      )}

      <FitRegionBounds activeRegion={activeRegion} selectedDriver={selectedDriver} isFullMap={isFullMap} />
      <LocateControl />

      {/* External Geocoded Locations Marked on the Map */}
      {markedLocations.map((loc, idx) => (
        <Marker
          key={`mark-${loc.lat}-${loc.lng}-${idx}`}
          position={[loc.lat, loc.lng]}
          icon={externalPinIcon(loc)}
        >
          <Tooltip direction="top" offset={[0, -25]} className="bg-slate-950/95 border border-amber-500/60 text-white rounded-xl shadow-2xl p-2.5 min-w-[210px]">
            <div className="flex items-center justify-between gap-2 pb-1 border-b border-slate-800">
              <span className="text-xs font-black text-amber-400 uppercase tracking-wide truncate">{loc.displayName.split(',')[0]}</span>
              <span className="text-[8px] font-bold uppercase tracking-wider bg-amber-500/20 text-amber-300 px-1.5 py-0.5 rounded">{loc.source}</span>
            </div>
            <div className="text-[10px] text-slate-300 mt-1 font-medium">{loc.displayName}</div>
            <div className="text-[9px] font-mono text-emerald-400 mt-0.5 font-bold">
              Lat: {loc.lat.toFixed(5)} · Lng: {loc.lng.toFixed(5)}
            </div>
            <div className="flex items-center gap-1.5 mt-2">
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  window.dispatchEvent(new CustomEvent('smartdrive_dispatch_to_coords', {
                    detail: {
                      address: loc.displayName,
                      name: loc.displayName.split(',')[0],
                      lat: loc.lat,
                      lng: loc.lng,
                    }
                  }))
                }}
                className="flex-1 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-[9px] uppercase tracking-wider py-1 px-2 rounded-lg flex items-center justify-center gap-1 cursor-pointer transition"
              >
                <Send size={10} />
                <span>Dispatch Here</span>
              </button>
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  setMarkedLocations(prev => prev.filter((_, i) => i !== idx))
                }}
                className="bg-slate-800 hover:bg-rose-500/40 text-slate-400 hover:text-rose-300 font-bold text-[9px] py-1 px-2 rounded-lg cursor-pointer transition"
              >
                Clear
              </button>
            </div>
          </Tooltip>
        </Marker>
      ))}

      {activeRegion?.boundaryPolygon && activeRegion.boundaryPolygon.length >= 3 && (
        <Polygon
          positions={activeRegion.boundaryPolygon}
          pathOptions={{
            color: '#10b981',
            fillColor: '#10b981',
            fillOpacity: isFullMap ? 0.05 : 0.08,
            weight: 2,
            dashArray: '6 8',
            lineCap: 'round',
            lineJoin: 'round',
          }}
        />
      )}

      {/* Pothole & Rough Road Heatmap Overlay */}
      {(showPotholes || showHeat) && potholes.map((pot) => (
        <Circle
          key={pot.id}
          center={[pot.latitude, pot.longitude]}
          radius={90}
          pathOptions={{
            color: '#ef4444',
            fillColor: '#ef4444',
            fillOpacity: 0.35 * (pot.intensity || 0.8),
            weight: 2,
          }}
        >
          <Tooltip direction="top" offset={[0, -10]} className="bg-slate-900 border border-rose-500/40 text-white text-[10px] font-bold p-2 rounded-xl shadow-2xl">
            <div className="flex items-center gap-1.5 text-rose-400">
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping" />
              <span>ROAD HAZARD / POTHOLE</span>
            </div>
            <div className="text-white font-black mt-0.5">{pot.roadName || 'Transit Corridor'}</div>
            <div className="text-slate-400 text-[9px] mt-0.5">Vibration: {(pot.vibrationRate || 2.1).toFixed(1)}G · Reported by {pot.driverName || 'Driver'}</div>
          </Tooltip>
        </Circle>
      ))}

      {/* Dynamic Speed Restriction Geofences */}
      {geofences.map((geo) => {
        const isDeadZoneType = geo.type === 'deadzone';
        return (
          <Circle
            key={geo.id}
            center={[geo.centerLat, geo.centerLng]}
            radius={geo.radiusMeters}
            pathOptions={{
              color: isDeadZoneType ? '#06b6d4' : (geo.color || '#38bdf8'),
              fillColor: isDeadZoneType ? '#0891b2' : (geo.color || '#38bdf8'),
              fillOpacity: isDeadZoneType ? 0.28 : 0.16,
              weight: isDeadZoneType ? 3.5 : 2.5,
              dashArray: isDeadZoneType ? '4 8' : '6 6',
            }}
          >
            <Tooltip direction="top" offset={[0, -10]} className="bg-slate-950/95 border border-white/20 text-white rounded-xl shadow-2xl p-2.5 min-w-[210px]">
              <div className="flex items-center justify-between gap-2 pb-1 border-b border-slate-800">
                <span className="text-xs font-black uppercase text-white truncate">
                  {isDeadZoneType ? `📡 ${geo.name}` : geo.name}
                </span>
                {isDeadZoneType ? (
                  <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded-full bg-cyan-500/20 text-cyan-300 border border-cyan-500/40">
                    📡 DEAD ZONE (GHAT)
                  </span>
                ) : (
                  <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/40">
                    {geo.speedLimitKph} KM/H MAX
                  </span>
                )}
              </div>
              <div className="text-[10px] text-slate-400 mt-1 font-mono">
                Radius: {geo.radiusMeters}m · Lat: {geo.centerLat.toFixed(4)}, Lng: {geo.centerLng.toFixed(4)}
              </div>
            {onDeleteGeofence && (
              <div className="mt-2 pt-1 border-t border-slate-800 text-right">
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation()
                    onDeleteGeofence(geo.id)
                  }}
                  className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-300 hover:bg-rose-500 hover:text-white text-[9px] font-bold cursor-pointer transition"
                >
                  Delete Geofence
                </button>
              </div>
            )}
          </Tooltip>
        </Circle>
      );
    })}

      {/* 70/30 PARTNERSHIP RELAY TACTICAL CORRIDOR (Only when relay mode is active) */}
      {isRelayMode && relayTroubledDriver?.location && relayCandidateDriver?.location && (() => {
        const start = relayTroubledDriver.location;
        const end = relayCandidateDriver.location;
        const midLat = (start.lat + end.lat) / 2;
        const midLng = (start.lng + end.lng) / 2;
        const dLat = (end.lat - start.lat) * 111;
        const dLng = (end.lng - start.lng) * 111 * Math.cos(midLat * Math.PI / 180);
        const distKm = Math.round(Math.sqrt(dLat * dLat + dLng * dLng) * 10) / 10;
        const etaMin = Math.max(2, Math.round((distKm / 35) * 60));

        return (
          <>
            <Polyline
              positions={[[start.lat, start.lng], [end.lat, end.lng]]}
              pathOptions={{
                color: '#06b6d4',
                weight: 5,
                opacity: 0.95,
                lineCap: 'round',
                lineJoin: 'round',
                dashArray: '6 10',
              }}
            />
            <Circle center={[start.lat, start.lng]} radius={40} pathOptions={{ color: '#f43f5e', fillColor: '#f43f5e', fillOpacity: 0.35, weight: 3 }} />
            <Circle center={[end.lat, end.lng]} radius={40} pathOptions={{ color: '#06b6d4', fillColor: '#06b6d4', fillOpacity: 0.35, weight: 3 }} />
            <Circle center={[midLat, midLng]} radius={12} pathOptions={{ color: '#06b6d4', fillColor: '#0891b2', fillOpacity: 0.9, weight: 2 }}>
              <Tooltip permanent direction="top" offset={[0, -12]} className="bg-slate-950 border border-cyan-400 text-white font-mono text-[9px] font-bold px-2 py-1 rounded-lg shadow-2xl">
                🤝 70/30 RELAY CORRIDOR · {distKm} km · ~{etaMin}m ETA
              </Tooltip>
            </Circle>
          </>
        );
      })()}

      {validDrivers.map((d) => {
        const isDeadZone = (d as any).isDeadZone === true
        const isOffline = d.status === 'offline' && !isDeadZone
        const cleanName = (d.name || 'Driver').replace(/\s+applicant/gi, '').trim()
        const isRelaySelected = isRelayMode && relayCandidateDriver?.id === d.id
        const isRelayTroubled = isRelayMode && relayTroubledDriver?.id === d.id

        return (
          <Marker 
            key={d.id} 
            position={[d.location.lat, d.location.lng]} 
            icon={markerIcon(d, selectedId === d.id || isRelaySelected || isRelayTroubled)}
            eventHandlers={{ 
              click: () => {
                if (isRelayMode && onSelectRelayCandidate) {
                  onSelectRelayCandidate(d.id)
                } else {
                  onSelect(d.id)
                }
              } 
            }} 
            zIndexOffset={isDeadZone ? 500 : (isRelaySelected || isRelayTroubled ? 600 : 0)}
          >
            <Tooltip direction="top" offset={[0, -22]} className="bg-slate-950/95 border border-slate-700 text-white rounded-xl shadow-2xl p-2.5 font-sans min-w-[190px]">
              <div className="flex items-center justify-between gap-2 pb-1 border-b border-slate-800">
                <span className="text-xs font-black text-white">{cleanName}</span>
                {isRelayTroubled ? (
                  <span className="text-[8px] font-black uppercase tracking-wider bg-rose-500/20 text-rose-300 border border-rose-500/40 px-1.5 py-0.5 rounded">
                    📦 30% TROUBLED ORIGIN
                  </span>
                ) : isRelaySelected ? (
                  <span className="text-[8px] font-black uppercase tracking-wider bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 px-1.5 py-0.5 rounded">
                    🚀 70% RELAY CANDIDATE
                  </span>
                ) : isDeadZone ? (
                  <span className="text-[8px] font-black uppercase tracking-wider bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 px-1.5 py-0.5 rounded">
                    📡 DEAD ZONE (GHAT)
                  </span>
                ) : isOffline ? (
                  <span className="text-[8px] font-black uppercase tracking-wider bg-amber-500/20 text-amber-300 border border-amber-500/40 px-1.5 py-0.5 rounded">
                    📡 NO NETWORK
                  </span>
                ) : (
                  <span className="text-[8px] font-black uppercase tracking-wider bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 px-1.5 py-0.5 rounded">
                    ● ONLINE
                  </span>
                )}
              </div>
              <div className="text-[10px] text-slate-300 mt-1">
                {isDeadZone ? (
                  <span className="text-cyan-300 font-bold">Offline Buffer Active • Last Known GPS</span>
                ) : isOffline ? (
                  <span className="text-amber-400 font-semibold">Last Known Location (Offline)</span>
                ) : (
                  <span>Speed: <strong className="text-emerald-400 font-bold">{d.speed || 0} km/h</strong></span>
                )}
              </div>
              <div className="text-[9px] font-mono text-slate-400 mt-0.5">
                Lat: {d.location.lat.toFixed(4)} · Lng: {d.location.lng.toFixed(4)}
              </div>
            </Tooltip>
          </Marker>
        )
      })}
      <MapLegendControl />
    </MapContainer>
  )
}
