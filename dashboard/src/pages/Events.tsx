import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import {
  Gauge, TrendingDown, CornerUpRight, ShieldAlert, Smartphone, BatteryLow, SatelliteDish, Zap,
} from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { events } from '@/data/mockData'
import { cn } from '@/lib/utils'
import type { EventType, Severity } from '@/types'

const META: Record<EventType, { icon: React.ElementType; label: string; color: string }> = {
  overspeed: { icon: Gauge, label: 'Overspeed', color: '#fb7185' },
  harsh_braking: { icon: TrendingDown, label: 'Harsh Braking', color: '#fbbf24' },
  harsh_acceleration: { icon: Zap, label: 'Harsh Acceleration', color: '#22d3ee' },
  sharp_turn: { icon: CornerUpRight, label: 'Sharp Turn', color: '#a78bfa' },
  crash: { icon: ShieldAlert, label: 'Crash', color: '#f43f5e' },
  phone_usage: { icon: Smartphone, label: 'Phone Usage', color: '#60a5fa' },
  low_battery: { icon: BatteryLow, label: 'Low Battery', color: '#fb923c' },
  gps_lost: { icon: SatelliteDish, label: 'GPS Lost', color: '#94a3b8' },
}

const SEVERITIES: (Severity | 'all')[] = ['all', 'critical', 'high', 'medium', 'low']

export default function Events() {
  const [sev, setSev] = useState<Severity | 'all'>('all')
  const list = useMemo(() => (sev === 'all' ? events : events.filter((e) => e.severity === sev)), [sev])

  return (
    <div>
      <PageHeader title="Event Center" subtitle="Unified safety event timeline across the fleet." />

      <div className="flex items-center gap-2 mb-5 flex-wrap">
        {SEVERITIES.map((s) => (
          <button key={s} onClick={() => setSev(s)}
            className={cn('h-9 px-4 rounded-xl text-[12.5px] font-medium capitalize border transition-colors',
              sev === s ? 'accent-gradient text-white border-transparent ring-glow' : 'bg-white border-slate-200 text-secondary hover:text-[#10b981] hover:bg-slate-50 hover:border-slate-300')}>
            {s}
          </button>
        ))}
      </div>

      <div className="relative pl-6">
        <div className="absolute left-[9px] top-2 bottom-2 w-px bg-gradient-to-b from-[#10b981]/40 via-slate-200 to-transparent" />
        <div className="space-y-3">
          {list.map((e, i) => {
            const m = META[e.type]
            const Icon = m.icon
            return (
              <motion.div key={e.id} initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }} className="relative">
                <span className="absolute -left-[19px] top-4 h-3 w-3 rounded-full ring-4 ring-[var(--color-navy-900)]" style={{ background: m.color, boxShadow: `0 0 10px ${m.color}` }} />
                <GlassCard className="flex items-center gap-4 py-3.5">
                  <div className="grid place-items-center h-10 w-10 rounded-xl shrink-0" style={{ background: m.color + '1a', color: m.color }}>
                    <Icon className="h-5 w-5" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-primary font-medium text-[13.5px]">{m.label}</span>
                      <Badge tone={e.severity}>{e.severity}</Badge>
                    </div>
                    <div className="text-[11.5px] text-muted mt-0.5">{e.driverName} · {e.vehicleReg} · {e.locationName}</div>
                  </div>
                  {e.value && <span className="text-[13px] font-semibold" style={{ color: m.color }}>{e.value}</span>}
                  <span className="text-[11px] text-muted whitespace-nowrap w-20 text-right">{e.time}</span>
                </GlassCard>
              </motion.div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
