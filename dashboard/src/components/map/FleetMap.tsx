import { useMemo, useEffect, useState } from 'react'
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
export const MAP_PROVIDERS: Record<string, { name: string; url: string; attribution: string; maxZoom: number }> = {
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
  'cartodb-dark': {
    name: 'Tactical Dark',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: '&copy; CartoDB',
    maxZoom: 19,
  },
}

function markerIcon(driver: Driver, active: boolean) {
  const isDeadZone = (driver as any).isDeadZone === true
  const isOffline = driver.status === 'offline' && !isDeadZone
  const color = isDeadZone ? '#06b6d4' : isOffline ? '#64748b' : (STATUS_COLOR[driver.status] || STATUS_COLOR.safe)
  const pulse = driver.status === 'emergency' || isDeadZone
  const size = active ? 48 : 38
  const initial = driver.name ? driver.name.trim().charAt(0).toUpperCase() : 'D'
  return L.divIcon({
    className: 'fleet-marker',
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
    html: `
      <div style="position:relative;width:${size}px;height:${size}px;display:flex;justify-content:center;align-items:center;">
        ${pulse ? `<div style="position:absolute;width:${size + 20}px;height:${size + 20}px;border-radius:50%;background:${color};opacity:0.35;animation:pulse 1.2s infinite;"></div>` : ''}
        ${isDeadZone ? `<div style="position:absolute;top:-6px;right:-6px;padding:1px 4px;border-radius:6px;background:#0891b2;border:1.5px solid #fff;color:#fff;font-size:7.5px;font-weight:900;box-shadow:0 2px 6px rgba(0,0,0,0.6);" title="Dead Zone / Local Buffer Active">📡 DEAD ZONE</div>` : ''}
        ${isOffline && !isDeadZone ? `<div style="position:absolute;top:-4px;right:-4px;width:14px;height:14px;border-radius:50%;background:#f59e0b;border:2px solid #0f172a;display:flex;align-items:center;justify-content:center;font-size:8px;box-shadow:0 2px 5px rgba(0,0,0,0.5);" title="No Network Zone">📡</div>` : ''}
        <div style="
          width:${size}px;
          height:${size}px;
          border-radius:50%;
          background:${color};
          border:${isDeadZone ? '3px dashed #38bdf8' : isOffline ? '3px dashed #cbd5e1' : '4px solid #ffffff'};
          opacity:${isOffline ? 0.88 : 1};
          box-shadow: 0 10px 25px rgba(0,0,0,0.3);
          display:flex;
          align-items:center;
          justify-content:center;
          color:#ffffff;
          font-weight:900;
          font-family: Inter, system-ui, sans-serif;
          font-size:${active ? 20 : 16}px;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        ">
          ${initial}
        </div>
      </div>`,
  })
}

function FitRegionBounds({
  activeRegion,
  targetDriver,
  isFullMap,
}: {
  activeRegion?: RegionOption | null
  targetDriver?: Driver | null
  isFullMap: boolean
}) {
  const map = useMap()

  useEffect(() => {
    if (!map) return

    // If there is an active live driver with valid GPS, center directly on the live driver!
    if (targetDriver && targetDriver.location && typeof targetDriver.location.lat === 'number' && typeof targetDriver.location.lng === 'number' && targetDriver.location.lat !== 0 && targetDriver.location.lng !== 0) {
      map.flyTo([targetDriver.location.lat, targetDriver.location.lng], 16, { duration: 1.5 })
      return
    }

    if (!activeRegion) return

    try {
      if (isFullMap) {
        map.setMaxBounds(undefined)
        map.flyTo(activeRegion.center, 12, { duration: 1.5 })
      } else {
        if (activeRegion.boundaryPolygon && activeRegion.boundaryPolygon.length >= 3) {
          const bounds = L.latLngBounds(activeRegion.boundaryPolygon as [number, number][])
          if (bounds.isValid()) {
            map.fitBounds(bounds, { padding: [80, 80], maxZoom: 15, animate: true, duration: 1.5 })
          }
        } else {
          map.flyTo(activeRegion.center, 14, { duration: 1.5 })
        }
      }
    } catch (err) {
      map.flyTo(activeRegion.center, 13)
    }
  }, [activeRegion?.id, activeRegion?.center?.[0], activeRegion?.center?.[1], targetDriver?.id, targetDriver?.location?.lat, targetDriver?.location?.lng, isFullMap, map])

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

function generateRoadPath(start: {lat: number, lng: number}, end: {lat: number, lng: number}): [number, number][] {
  const p1: [number, number] = [start.lat, start.lng];
  const p2: [number, number] = [start.lat + 0.002, start.lng + 0.001];
  const p3: [number, number] = [start.lat + 0.004, start.lng - 0.002];
  const p4: [number, number] = [(start.lat + end.lat) / 2, (start.lng + end.lng) / 2 + 0.003];
  const p5: [number, number] = [end.lat - 0.003, end.lng + 0.002];
  const p6: [number, number] = [end.lat, end.lng];
  return [p1, p2, p3, p4, p5, p6];
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

export function FleetMap({
  drivers, 
  selectedId, 
  onSelect, 
  showHeat, 
  potholes = [],
  showPotholes = false,
  geofences = [],
  onDeleteGeofence,
  mapMode = 'google-satellite',
  activeRegion,
  isFullMap = false
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

  // Filter strictly by active region (preserve last known location for offline/no-network drivers)
  const regionActiveDrivers = drivers.filter(d => {
    if (!d) return false
    if (!activeRegion || !activeRegion.id || activeRegion.id === 'all' || activeRegion.id === 'default') return true
    const regId = (d.regionId || d.region || d.zone || '').toLowerCase().replace(/[^a-z0-9]/g, '')
    const activeRegId = (activeRegion.id || activeRegion.name || '').toLowerCase().replace(/[^a-z0-9]/g, '')
    return regId === activeRegId || regId.includes(activeRegId) || activeRegId.includes(regId)
  })

  // Only display drivers that are genuinely online and streaming real GPS coordinates
  const validDrivers = regionActiveDrivers.filter((d) => {
    if (!d || !d.location) return false
    const lat = d.location.lat
    const lng = d.location.lng
    if (typeof lat !== 'number' || typeof lng !== 'number' || isNaN(lat) || isNaN(lng) || (lat === 0 && lng === 0)) {
      return false
    }
    // Filter out synthetic fallback coordinates if driver is offline or has no real telemetry
    const isDefaultFallback = Math.abs(lat - 12.7749) < 0.0001 && Math.abs(lng - 75.2023) < 0.0001
    if (isDefaultFallback && (d.status === 'offline' || !d.speed || d.speed === 0)) {
      return false
    }
    const isDeadZone = (d as any).isDeadZone === true
    const isEmergency = d.status === 'emergency'
    return d.status !== 'offline' || isDeadZone || isEmergency
  })

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
  
  // Find a valid target driver with actual lat/lng
  const targetDriver = validDrivers.find(d => d.id === selectedId) || validDrivers.find(d => d.status !== 'offline') || validDrivers[0]
  
  // Prioritize actual live driver position if present
  const initialCenter: [number, number] = (targetDriver && targetDriver.location && !isNaN(targetDriver.location.lat) && !isNaN(targetDriver.location.lng) && targetDriver.location.lat !== 0)
    ? [targetDriver.location.lat, targetDriver.location.lng]
    : (geocodedSectorCenter || (activeRegion?.center && Array.isArray(activeRegion.center) && activeRegion.center.length === 2 && !isNaN(activeRegion.center[0]) ? activeRegion.center : [12.7749, 75.2023]))

  const activeProvider = MAP_PROVIDERS[mapMode] || MAP_PROVIDERS['google-satellite']
  const sectorCenter = geocodedSectorCenter || activeRegion?.center

  return (
    <MapContainer center={initialCenter} zoom={targetDriver ? 16 : (activeRegion?.zoom || 14)} zoomControl={false} className="h-full w-full" preferCanvas>
      <TileLayer
        key={mapMode}
        url={activeProvider.url}
        attribution={activeProvider.attribution}
        maxZoom={activeProvider.maxZoom}
      />

      <FitRegionBounds activeRegion={activeRegion} targetDriver={targetDriver} isFullMap={isFullMap} />
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
        >
          <Tooltip direction="top" className="bg-slate-950/95 border border-emerald-500/50 text-emerald-300 font-extrabold text-[10px] uppercase tracking-wider px-3 py-1.5 rounded-xl shadow-2xl backdrop-blur-md">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>{activeRegion.name} · Jurisdiction Boundary</span>
            </div>
          </Tooltip>
        </Polygon>
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
      {geofences.map((geo) => (
        <Circle
          key={geo.id}
          center={[geo.centerLat, geo.centerLng]}
          radius={geo.radiusMeters}
          pathOptions={{
            color: geo.color || '#38bdf8',
            fillColor: geo.color || '#38bdf8',
            fillOpacity: 0.16,
            weight: 2.5,
            dashArray: '6 6',
          }}
        >
          <Tooltip direction="top" offset={[0, -10]} className="bg-slate-950/95 border border-white/20 text-white rounded-xl shadow-2xl p-2.5 min-w-[200px]">
            <div className="flex items-center justify-between gap-2 pb-1 border-b border-slate-800">
              <span className="text-xs font-black uppercase text-white truncate">{geo.name}</span>
              <span className="text-[9px] font-black uppercase px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/40">
                {geo.speedLimitKph} KM/H MAX
              </span>
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
      ))}

      {selectedId && (() => {
        const d = validDrivers.find((drv) => drv.id === selectedId)
        if (!d || !d.location) return null
        const start = d.location
        const end = (d.destLat != null && d.destLng != null && !isNaN(d.destLat) && !isNaN(d.destLng)) 
          ? { lat: d.destLat, lng: d.destLng } 
          : (d.deliveryTo && resolvedDestMap[d.deliveryTo] ? resolvedDestMap[d.deliveryTo] : null)
        if (!end) return null
        const path = generateRoadPath(start, end);
        return (
          <>
            <Polyline
              positions={path}
              pathOptions={{
                color: '#10b981',
                weight: 6,
                opacity: 0.9,
                lineCap: 'round',
                lineJoin: 'round',
                dashArray: '1 12',
              }}
            />
            <Circle center={[start.lat, start.lng]} radius={15} pathOptions={{ color: '#10b981', fillColor: '#fff', fillOpacity: 1, weight: 4 }} />
            <Circle center={[end.lat, end.lng]} radius={20} pathOptions={{ color: '#f43f5e', fillColor: '#fff', fillOpacity: 1, weight: 5 }} >
               <Tooltip permanent direction="top" offset={[0, -15]} className="bg-slate-900 border-none text-white font-black text-[9px] uppercase tracking-widest px-3 py-1.5 rounded-lg shadow-2xl">
                 Target: {d.deliveryTo || 'Sector B'} · {end.lat.toFixed(4)}, {end.lng.toFixed(4)}
               </Tooltip>
            </Circle>
          </>
        )
      })()}

      {validDrivers.map((d) => {
        const isDeadZone = (d as any).isDeadZone === true
        const isOffline = d.status === 'offline' && !isDeadZone
        const cleanName = (d.name || 'Driver').replace(/\s+applicant/gi, '').trim()
        return (
          <Marker 
            key={d.id} 
            position={[d.location.lat, d.location.lng]} 
            icon={markerIcon(d, selectedId === d.id)}
            eventHandlers={{ click: () => onSelect(d.id) }} 
            zIndexOffset={isDeadZone ? 500 : 0}
          >
            <Tooltip direction="top" offset={[0, -22]} className="bg-slate-950/95 border border-slate-700 text-white rounded-xl shadow-2xl p-2.5 font-sans min-w-[190px]">
              <div className="flex items-center justify-between gap-2 pb-1 border-b border-slate-800">
                <span className="text-xs font-black text-white">{cleanName}</span>
                {isDeadZone ? (
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
    </MapContainer>
  )
}
