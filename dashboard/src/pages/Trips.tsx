import { motion } from 'framer-motion'
import { Play, Download, MapPin, Clock, Gauge, TriangleAlert } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { Sparkline } from '@/components/charts/Charts'
import { drivers } from '@/data/mockData'
import { scoreColor, seeded } from '@/lib/utils'

const trips = drivers.flatMap((d, di) =>
  Array.from({ length: 2 }, (_, i) => ({
    id: `${d.id}-t${i}`,
    driver: d.name,
    from: d.fleet.split('·')[1]?.trim() ?? 'Hub',
    to: d.locationName,
    distance: +(d.distanceToday / 2 + seeded(di + i) * 8).toFixed(1),
    duration: Math.round(d.tripDurationMin / 2 + seeded(di * 2 + i) * 20),
    maxSpeed: Math.round(60 + seeded(di + i * 3) * 40),
    events: Math.round(seeded(di * 3 + i) * 6),
    score: Math.max(55, Math.min(98, d.safetyScore + Math.round(seeded(di + i) * 10 - 5))),
  })),
)

export default function Trips() {
  return (
    <div>
      <PageHeader
        title="Trips"
        subtitle="Trip history, route replay and per-trip analytics."
        actions={
          <button className="flex items-center gap-2 h-10 px-4 rounded-xl bg-white/[0.04] border border-white/8 text-[13px] text-secondary hover:text-primary hover:border-cyan-400/30 transition">
            <Download className="h-4 w-4" /> Export
          </button>
        }
      />
      <div className="grid gap-3">
        {trips.map((t, i) => (
          <motion.div key={t.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03 }}>
            <GlassCard className="flex flex-col lg:flex-row lg:items-center gap-4">
              <div className="flex items-center gap-3 lg:w-56 shrink-0">
                <button className="grid place-items-center h-10 w-10 rounded-xl accent-gradient text-white shrink-0 hover:brightness-110 transition ring-glow">
                  <Play className="h-4 w-4 ml-0.5" />
                </button>
                <div>
                  <div className="text-primary font-medium text-[13px]">{t.driver}</div>
                  <div className="text-[11px] text-muted flex items-center gap-1"><MapPin className="h-2.5 w-2.5" />{t.from} → {t.to}</div>
                </div>
              </div>
              <div className="flex-1"><Sparkline data={Array.from({ length: 16 }, (_, k) => 40 + Math.sin(k * 0.7) * 20 + seeded(i + k) * 15)} color="#22d3ee" height={40} /></div>
              <div className="grid grid-cols-4 gap-4 lg:w-96 shrink-0 text-[12px]">
                <Stat icon={Gauge} label="Distance" value={`${t.distance} km`} />
                <Stat icon={Clock} label="Duration" value={`${t.duration}m`} />
                <Stat icon={Gauge} label="Max" value={`${t.maxSpeed}`} />
                <Stat icon={TriangleAlert} label="Events" value={`${t.events}`} />
              </div>
              <div className="lg:w-20 shrink-0 text-right">
                <div className="font-display font-bold text-lg" style={{ color: scoreColor(t.score) }}>{t.score}</div>
                <Badge tone={t.score >= 85 ? 'safe' : t.score >= 70 ? 'warn' : 'danger'}>score</Badge>
              </div>
            </GlassCard>
          </motion.div>
        ))}
      </div>
    </div>
  )
}

function Stat({ icon: Icon, label, value }: { icon: React.ElementType; label: string; value: string }) {
  return (
    <div>
      <div className="text-[10px] text-muted flex items-center gap-1"><Icon className="h-3 w-3" />{label}</div>
      <div className="text-primary font-medium mt-0.5">{value}</div>
    </div>
  )
}
