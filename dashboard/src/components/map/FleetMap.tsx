import { useMemo } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, useMap, Circle, Tooltip } from 'react-leaflet'
import L from 'leaflet'
import type { Driver } from '@/types'
import { FLEET_CENTER, contextZones } from '@/data/mockData'

const STATUS_COLOR: Record<string, string> = {
  safe: '#10b981', warning: '#f59e0b', emergency: '#ef4444', idle: '#3b82f6', offline: '#94a3b8',
}

function markerIcon(driver: Driver, active: boolean) {
  const color = STATUS_COLOR[driver.status] || STATUS_COLOR.safe
  const pulse = driver.status === 'emergency'
  const size = active ? 42 : 34
  const initial = driver.name ? driver.name.trim().charAt(0).toUpperCase() : 'D'
  return L.divIcon({
    className: 'fleet-marker',
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
    html: `
      <div style="position:relative;width:${size}px;height:${size}px;display:flex;justify-content:center;align-items:center;">
        ${pulse ? `<div style="position:absolute;width:${size + 14}px;height:${size + 14}px;border-radius:50%;background:${color};opacity:0.5;animation:pulse 1s infinite;"></div>` : ''}
        <div style="
          width:${size}px;
          height:${size}px;
          border-radius:50%;
          background:${color};
          border:3px solid #ffffff;
          box-shadow: 0 4px 12px rgba(0,0,0,0.3);
          display:flex;
          align-items:center;
          justify-content:center;
          color:#ffffff;
          font-weight:800;
          font-family: Inter, system-ui, sans-serif;
          font-size:${active ? 18 : 14}px;
        ">
          ${initial}
        </div>
      </div>`,
  })
}



function Recenter({ center }: { center: [number, number] }) {
  const map = useMap()
  useMemo(() => { map.flyTo(center, map.getZoom(), { duration: 1 }) }, [center]) // eslint-disable-line
  return null
}

export function FleetMap({
  drivers, selectedId, onSelect, showHeat,
}: {
  drivers: Driver[]
  selectedId: string | null
  onSelect: (id: string) => void
  showHeat: boolean
  mapMode?: string
}) {
  return (
    <MapContainer center={FLEET_CENTER} zoom={13} zoomControl className="h-full w-full" preferCanvas>
      <TileLayer
        url="https://mt1.google.com/vt/lyrs=y,traffic&x={x}&y={y}&z={z}"
        attribution='&copy; Google Maps Satellite'
        maxZoom={20}
      />
      {contextZones.map((zone) => (
        <Circle
          key={zone.id}
          center={[zone.lat, zone.lng]}
          radius={zone.radiusMeters}
          pathOptions={{
            color: zone.type === 'school' ? '#fbbf24' : '#f43f5e',
            fillColor: zone.type === 'school' ? '#fbbf24' : '#f43f5e',
            fillOpacity: 0.1,
            weight: 1.5,
            dashArray: '3 5',
          }}
        >
          <Tooltip sticky direction="top" opacity={0.9}>
            <div className="text-[11px] font-sans font-semibold text-slate-200 flex flex-col leading-tight bg-slate-900/90 p-1.5 rounded-lg border border-white/5">
              <span className={zone.type === 'school' ? 'text-amber-400' : 'text-rose-400'}>
                {zone.type === 'school' ? '🏫 School Zone' : '🚨 Heavy Traffic'}
              </span>
              <span className="text-[10px] text-slate-300 font-normal mt-0.5">{zone.name}</span>
              <span className="text-[9px] text-slate-400 font-normal mt-0.5">Speed Limit: {zone.speedLimit} km/h</span>
            </div>
          </Tooltip>
        </Circle>
      ))}

      {selectedId && (() => {
        const d = drivers.find((drv) => drv.id === selectedId)
        if (!d || !d.startLocation || !d.endLocation || !d.route.length) return null
        
        const startIcon = L.divIcon({
          html: `<div style="background:#10b981;width:24px;height:24px;border:3px solid #ffffff;border-radius:50%;box-shadow:0 4px 12px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:900;font-size:12px;font-family:sans-serif;">A</div>`,
          iconSize: [24, 24],
          iconAnchor: [12, 12]
        })
        const endIcon = L.divIcon({
          html: `<div style="background:#ef4444;width:24px;height:24px;border:3px solid #ffffff;border-radius:50%;box-shadow:0 4px 12px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:#fff;font-weight:900;font-size:12px;font-family:sans-serif;">B</div>`,
          iconSize: [24, 24],
          iconAnchor: [12, 12]
        })
        
        const routeCoords = d.route.map((p) => [p.lat, p.lng]) as [number, number][]

        return (
          <>
            {/* Outline casing for satellite contrast */}
            <Polyline
              positions={routeCoords}
              pathOptions={{
                color: '#ffffff',
                weight: 8,
                opacity: 0.9,
              }}
            />
            {/* Main road polyline */}
            <Polyline
              positions={routeCoords}
              pathOptions={{
                color: '#10b981',
                weight: 5,
                opacity: 1,
              }}
            />
            <Marker position={[d.startLocation.lat, d.startLocation.lng]} icon={startIcon}>
              <Tooltip permanent direction="top" offset={[0, -10]}>
                <span className="font-bold text-emerald-600">Point A:</span> {d.deliveryFrom || 'Origin'}
              </Tooltip>
            </Marker>
            <Marker position={[d.endLocation.lat, d.endLocation.lng]} icon={endIcon}>
              <Tooltip permanent direction="top" offset={[0, -10]}>
                <span className="font-bold text-rose-600">Point B:</span> {d.deliveryTo || 'Destination'}
              </Tooltip>
            </Marker>
          </>
        )
      })()}
      {showHeat && drivers.flatMap((d) =>
        d.route.map((p, i) => (
          <Marker key={`h-${d.id}-${i}`} position={[p.lat, p.lng]}
            icon={L.divIcon({ className: '', iconSize: [26, 26], iconAnchor: [13, 13],
              html: `<div style="width:26px;height:26px;border-radius:50%;background:radial-gradient(circle, rgba(244,63,94,.5), transparent 70%);"></div>` })}
            interactive={false} />
        )),
      )}
      {drivers.map((d) => (
        <Marker key={d.id} position={[d.location.lat, d.location.lng]} icon={markerIcon(d, selectedId === d.id)}
          eventHandlers={{ click: () => onSelect(d.id) }} />
      ))}
      {selectedId && <Recenter center={[drivers.find((d) => d.id === selectedId)!.location.lat, drivers.find((d) => d.id === selectedId)!.location.lng]} />}
    </MapContainer>
  )
}
