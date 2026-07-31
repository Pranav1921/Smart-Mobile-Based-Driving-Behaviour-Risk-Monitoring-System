import { useState } from 'react'
import { MapContainer, TileLayer, CircleMarker } from 'react-leaflet'
import { motion } from 'framer-motion'
import { Flame, Gauge, TrendingDown, CornerUpRight, ShieldAlert } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { drivers, FLEET_CENTER } from '@/data/mockData'
import { cn, seeded } from '@/lib/utils'

const LAYERS = [
  { key: 'crash', label: 'Crash', icon: ShieldAlert, color: '#f43f5e' },
  { key: 'overspeed', label: 'Overspeed', icon: Gauge, color: '#fb7185' },
  { key: 'braking', label: 'Harsh Braking', icon: TrendingDown, color: '#fbbf24' },
  { key: 'turn', label: 'Sharp Turn', icon: CornerUpRight, color: '#a78bfa' },
] as const

// build heat points from driver routes with weights
function points(color: string) {
  const pts: { lat: number; lng: number; w: number }[] = []
  drivers.forEach((d, di) => {
    d.route.forEach((p, i) => {
      pts.push({ lat: p.lat + (seeded(di + i) - 0.5) * 0.006, lng: p.lng + (seeded(di * 2 + i) - 0.5) * 0.006, w: seeded(di * 3 + i) })
    })
  })
  return pts.map((p) => ({ ...p, color }))
}

export default function Heatmaps() {
  const [layer, setLayer] = useState<(typeof LAYERS)[number]['key']>('crash')
  const active = LAYERS.find((l) => l.key === layer)!
  const pts = points(active.color)

  return (
    <div>
      <PageHeader title="Risk Heatmaps" subtitle="Spatial risk intelligence — unsafe roads and event density across the NH66 corridor." />
      <div className="flex items-center gap-2 mb-5 flex-wrap">
        {LAYERS.map((l) => (
          <button key={l.key} onClick={() => setLayer(l.key)}
            className={cn('h-10 px-4 rounded-xl text-[13px] font-medium border flex items-center gap-2 transition-colors',
              layer === l.key ? 'text-white border-transparent ring-glow' : 'bg-white/[0.04] border-white/8 text-secondary hover:text-primary')}
            style={layer === l.key ? { background: `linear-gradient(135deg, ${l.color}, ${l.color}aa)` } : undefined}>
            <l.icon className="h-4 w-4" /> {l.label}
          </button>
        ))}
      </div>

      <GlassCard padded={false} className="overflow-hidden">
        <div className="h-[560px] relative">
          <MapContainer center={FLEET_CENTER} zoom={13} className="h-full w-full">
            <TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" attribution="&copy; CARTO" />
            {pts.map((p, i) => (
              <CircleMarker key={i} center={[p.lat, p.lng]} radius={8 + p.w * 16}
                pathOptions={{ color: 'transparent', fillColor: p.color, fillOpacity: 0.12 + p.w * 0.25 }} />
            ))}
          </MapContainer>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="absolute top-4 left-4 z-[400] glass rounded-xl px-4 py-3 flex items-center gap-2.5">
            <Flame className="h-4 w-4" style={{ color: active.color }} />
            <div>
              <div className="text-[13px] font-semibold text-primary">{active.label} Heatmap</div>
              <div className="text-[11px] text-muted">{pts.length} data points · last 7 days</div>
            </div>
          </motion.div>
        </div>
      </GlassCard>
    </div>
  )
}
