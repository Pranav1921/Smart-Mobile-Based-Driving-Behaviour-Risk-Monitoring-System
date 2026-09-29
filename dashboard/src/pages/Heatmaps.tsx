import { useState } from 'react'
import { MapContainer, TileLayer, CircleMarker, Tooltip } from 'react-leaflet'
import { motion } from 'framer-motion'
import { Flame, Gauge, TrendingDown, CornerUpRight, ShieldAlert, Activity } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { drivers } from '@/data/mockData'
import { resolveActiveRegion } from '@/data/regionsData'
import { cn, seeded } from '@/lib/utils'
import { HeatmapLayer } from '@/components/map/HeatmapLayer'
import { useSocket } from '@/hooks/SocketContext'

const LAYERS = [
  { key: 'potholes',  label: 'Potholes & Bad Roads', icon: Activity,      color: '#f43f5e', glow: 'rgba(244,63,94,0.5)' },
  { key: 'crash',     label: 'Crash Events',        icon: ShieldAlert,   color: '#ef4444', glow: 'rgba(239,68,68,0.5)' },
  { key: 'overspeed', label: 'Overspeed',            icon: Gauge,         color: '#f97316', glow: 'rgba(249,115,22,0.5)' },
  { key: 'braking',   label: 'Harsh Braking',       icon: TrendingDown,  color: '#eab308', glow: 'rgba(234,179,8,0.5)'  },
  { key: 'turn',      label: 'Sharp Turn',          icon: CornerUpRight,  color: '#a855f7', glow: 'rgba(168,85,247,0.5)' },
] as const

type LayerKey = (typeof LAYERS)[number]['key']

interface HeatPointMeta {
  lat: number
  lng: number
  w: number
  color: string
  intensity: 'Low' | 'Medium' | 'High'
  label: string
}

const INTENSITY_COLOR: Record<string, string> = {
  Low: '#4ade80',
  Medium: '#fbbf24',
  High: '#ef4444',
}

const EVENT_NAMES: Record<LayerKey, string[]> = {
  potholes:  ['Heavy Road Vibration', 'Pothole Impact Zone', 'Severe Surface Degradation', 'Rough Transit Segment'],
  crash:     ['Collision Detected', 'Hard Impact Event', 'Rear-End Alert', 'Side Impact'],
  overspeed: ['Speed Limit Breach', 'Excessive Speed', 'Speed Zone Violation', 'Rapid Acceleration'],
  braking:   ['Sudden Brake', 'Panic Braking', 'ABS Engagement', 'Emergency Stop'],
  turn:      ['Sharp Cornering', 'Lane Deviation', 'High-G Turn', 'Abrupt Swerve'],
}

function buildPoints(activeKey: LayerKey, color: string): HeatPointMeta[] {
  const pts: HeatPointMeta[] = []
  drivers.forEach((d, di) => {
    d.route.forEach((p, i) => {
      const w = seeded(di * 3 + i)
      pts.push({
        lat: p.lat + (seeded(di + i) - 0.5) * 0.006,
        lng: p.lng + (seeded(di * 2 + i) - 0.5) * 0.006,
        w,
        color,
        intensity: w < 0.33 ? 'Low' : w < 0.66 ? 'Medium' : 'High',
        label: EVENT_NAMES[activeKey][Math.floor(seeded(di * 5 + i) * EVENT_NAMES[activeKey].length)],
      })
    })
  })
  return pts
}

export default function Heatmaps() {
  const { livePotholes } = useSocket()
  const activeRegion = resolveActiveRegion()
  const [layer, setLayer] = useState<LayerKey>('potholes')
  const active = LAYERS.find((l) => l.key === layer)!

  let pts: HeatPointMeta[] = []
  if (layer === 'potholes' && livePotholes.length > 0) {
    pts = livePotholes.map((pot) => {
      const w = pot.intensity || 0.75
      return {
        lat: pot.latitude,
        lng: pot.longitude,
        w,
        color: active.color,
        intensity: w < 0.33 ? 'Low' : w < 0.66 ? 'Medium' : 'High',
        label: `${pot.roadName || 'Transit Corridor'} (${(pot.vibrationRate || 2.2).toFixed(1)}G)`,
      }
    })
  } else {
    pts = buildPoints(layer, active.color)
  }

  // Convert to HeatmapLayer format
  const heatPoints = pts.map((p) => ({
    lat: p.lat,
    lng: p.lng,
    intensity: p.w,
    color: p.color,
  }))

  const highCount = pts.filter(p => p.intensity === 'High').length
  const medCount  = pts.filter(p => p.intensity === 'Medium').length
  const lowCount  = pts.filter(p => p.intensity === 'Low').length

  return (
    <div>
      <PageHeader
        title="Risk Heatmaps"
        subtitle="Spatial risk intelligence — unsafe roads and event density across the fleet jurisdiction."
      />

      {/* Layer selector */}
      <div className="flex items-center gap-2 mb-5 flex-wrap">
        {LAYERS.map((l) => (
          <button
            key={l.key}
            onClick={() => setLayer(l.key)}
            className={cn(
              'h-10 px-5 rounded-xl text-[12.5px] font-bold border flex items-center gap-2 transition-all cursor-pointer',
              layer === l.key
                ? 'text-white border-transparent shadow-lg'
                : 'bg-white border-slate-200 text-slate-500 hover:text-slate-900 hover:border-slate-300',
            )}
            style={layer === l.key ? { background: l.color, boxShadow: `0 4px 18px ${l.glow}` } : undefined}
          >
            <l.icon className="h-3.5 w-3.5" />
            {l.label}
          </button>
        ))}
      </div>

      {/* Severity stat row */}
      <div className="grid grid-cols-3 gap-3 mb-5">
        {[
          { label: 'High Severity',   count: highCount, color: '#ef4444', bg: '#fef2f2', border: '#fecaca' },
          { label: 'Medium Severity', count: medCount,  color: '#f97316', bg: '#fff7ed', border: '#fed7aa' },
          { label: 'Low Severity',    count: lowCount,  color: '#16a34a', bg: '#f0fdf4', border: '#bbf7d0' },
        ].map((s) => (
          <div
            key={s.label}
            className="rounded-2xl px-4 py-3 flex items-center justify-between"
            style={{ background: s.bg, border: `1px solid ${s.border}` }}
          >
            <div>
              <div className="text-[11px] font-bold uppercase tracking-wider" style={{ color: s.color }}>{s.label}</div>
              <div className="text-2xl font-black mt-0.5" style={{ color: s.color }}>{s.count}</div>
            </div>
            <Activity className="h-6 w-6 opacity-30" style={{ color: s.color }} />
          </div>
        ))}
      </div>

      <GlassCard padded={false} className="overflow-hidden rounded-3xl">
        <div className="h-[580px] relative">
          <MapContainer center={activeRegion.center} zoom={13} className="h-full w-full" zoomControl={false}>
            {/* Dark base for max contrast */}
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution="&copy; CARTO"
            />

            {/* TRUE CANVAS HEATMAP — smooth Gaussian blobs, no circles */}
            <HeatmapLayer
              points={heatPoints}
              radius={32}
              blur={28}
              minOpacity={0.06}
            />

            {/* Invisible hit-target markers for hover tooltips (very small, transparent) */}
            {pts.map((p, i) => (
              <CircleMarker
                key={i}
                center={[p.lat, p.lng]}
                radius={8}
                pathOptions={{ color: 'transparent', fillColor: 'transparent', fillOpacity: 0 }}
              >
                <Tooltip direction="top" offset={[0, -4]} opacity={1}>
                  <div
                    style={{
                      fontFamily: 'Inter, system-ui, sans-serif',
                      background: '#0f172a',
                      border: `1px solid ${p.color}55`,
                      borderRadius: '10px',
                      padding: '8px 12px',
                      minWidth: '168px',
                      boxShadow: `0 8px 24px rgba(0,0,0,0.75)`,
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '4px',
                    }}
                  >
                    <span style={{ fontSize: '9.5px', fontWeight: 800, letterSpacing: '0.07em', textTransform: 'uppercase', color: p.color }}>
                      {active.label}
                    </span>
                    <span style={{ fontSize: '12px', fontWeight: 700, color: '#f1f5f9' }}>
                      {p.label}
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '2px' }}>
                      <span
                        style={{
                          fontSize: '10px',
                          fontWeight: 700,
                          color: INTENSITY_COLOR[p.intensity],
                          background: `${INTENSITY_COLOR[p.intensity]}18`,
                          border: `1px solid ${INTENSITY_COLOR[p.intensity]}44`,
                          borderRadius: '5px',
                          padding: '1px 7px',
                        }}
                      >
                        {p.intensity} Risk
                      </span>
                      <span style={{ fontSize: '9.5px', color: '#64748b' }}>
                        Score {(p.w * 100).toFixed(0)}
                      </span>
                    </div>
                  </div>
                </Tooltip>
              </CircleMarker>
            ))}
          </MapContainer>

          {/* Top-left active layer badge */}
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            key={layer}
            className="absolute top-4 left-4 z-[400] flex items-center gap-3 px-4 py-2.5 rounded-2xl"
            style={{ background: '#0f172a', border: `1px solid ${active.color}44`, boxShadow: '0 6px 24px rgba(0,0,0,0.7)' }}
          >
            <div className="h-9 w-9 rounded-xl flex items-center justify-center shrink-0"
              style={{ background: `${active.color}22`, border: `1px solid ${active.color}44` }}>
              <active.icon className="h-4 w-4" style={{ color: active.color }} />
            </div>
            <div>
              <div className="text-[13px] font-bold text-white leading-none">{active.label} Heatmap</div>
              <div className="text-[10.5px] mt-0.5" style={{ color: '#64748b' }}>{pts.length} events · last 7 days</div>
            </div>
          </motion.div>

          {/* Bottom intensity legend */}
          <div
            className="absolute bottom-4 left-4 z-[400] flex items-center gap-4 px-4 py-2 rounded-xl"
            style={{ background: '#0f172aee', border: '1px solid #1e293b' }}
          >
            {['Low', 'Medium', 'High'].map((level) => (
              <div key={level} className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full" style={{ background: INTENSITY_COLOR[level] }} />
                <span style={{ fontSize: '10.5px', fontWeight: 600, color: '#94a3b8' }}>{level}</span>
              </div>
            ))}
          </div>
        </div>
      </GlassCard>
    </div>
  )
}
