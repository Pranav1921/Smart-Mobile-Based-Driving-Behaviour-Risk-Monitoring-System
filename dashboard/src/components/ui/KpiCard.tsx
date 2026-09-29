import { motion } from 'framer-motion'
import {
  Shield, Users, Truck, Route, Gauge, Activity, TriangleAlert,
  Star, TrendingUp, BarChart3, ArrowUpRight, ArrowDownRight,
} from 'lucide-react'
import { useCountUp } from '@/hooks/useCountUp'
import { cn, formatNumber } from '@/lib/utils'
import type { Kpi } from '@/types'

const ICONS: Record<string, React.ElementType> = {
  shield: Shield, users: Users, truck: Truck, route: Route, gauge: Gauge,
  activity: Activity, alert: TriangleAlert, star: Star, trendup: TrendingUp, chart: BarChart3,
}

const TONE_ACCENT: Record<string, { bg: string; text: string; border: string }> = {
  cyan: { bg: 'bg-[#10B981]/10', text: 'text-[#10B981]', border: 'border-[#10B981]/30' },
  electric: { bg: 'bg-[#2563EB]/10', text: 'text-[#2563EB]', border: 'border-[#2563EB]/30' },
  safe: { bg: 'bg-[#10B981]/10', text: 'text-[#10B981]', border: 'border-[#10B981]/30' },
  warn: { bg: 'bg-[#D97706]/10', text: 'text-[#D97706]', border: 'border-[#D97706]/30' },
  danger: { bg: 'bg-[#DC2626]/10', text: 'text-[#DC2626]', border: 'border-[#DC2626]/30' },
}

export function KpiCard({ kpi, index }: { kpi: Kpi; index: number }) {
  const Icon = ICONS[kpi?.icon] ?? Activity
  const val = useCountUp(kpi?.value ?? 0, 1200 + index * 50, kpi?.decimals ?? 0)
  const positive = (kpi?.delta ?? 0) >= 0
  const dangerDelta = kpi?.tone === 'danger' || kpi?.tone === 'warn'
  const style = TONE_ACCENT[kpi?.tone] ?? TONE_ACCENT['cyan']

  return (
    <motion.div
      initial={{ opacity: 0, y: 16, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{
        type: 'spring',
        stiffness: 360,
        damping: 28,
        delay: index * 0.04,
      }}
      whileHover={{ y: -3, scale: 1.015 }}
      whileTap={{ scale: 0.98 }}
      className="stamped-card p-5 relative overflow-hidden group border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] shadow-md"
    >
      {/* Metallic Corner Rivets */}
      <div className="absolute top-2.5 left-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] shadow-inner opacity-75" />
      <div className="absolute top-2.5 right-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] shadow-inner opacity-75" />

      {/* Top Header: Label & Icon */}
      <div className="flex items-start justify-between relative z-10 pt-1">
        <div>
          <span className="font-tech text-[9px] font-bold text-[var(--text-subtle)] uppercase tracking-[0.2em] block">
            {kpi.key.replace('_', ' ')}
          </span>
          <h3 className="font-space text-xs font-bold text-[var(--text-primary)] uppercase tracking-tight mt-0.5">
            {kpi.label}
          </h3>
        </div>

        <div className={cn(
          'h-9 w-9 rounded-xl grid place-items-center border-[1.5px] transition-transform group-hover:scale-105',
          style.bg, style.text, style.border
        )}>
          <Icon className="h-4.5 w-4.5" />
        </div>
      </div>

      {/* Center Value: Space Grotesk Bold Metric */}
      <div className="mt-4 flex items-baseline justify-between relative z-10">
        <div className="font-space text-3xl font-black tracking-tight text-[var(--text-primary)] tabular-nums leading-none">
          {formatNumber(Math.floor(val))}
          {kpi.decimals ? <span className="text-xl">{(val % 1).toFixed(kpi.decimals).slice(1)}</span> : null}
          {kpi.unit && (
            <span className="font-tech text-xs font-bold text-[var(--text-secondary)] ml-1.5 uppercase tracking-wider">
              {kpi.unit}
            </span>
          )}
        </div>

        {/* Delta Tag in Inset Well */}
        <div className={cn(
          'flex items-center gap-1 px-2 py-0.5 rounded-lg border font-tech text-[10px] font-bold',
          positive
            ? (dangerDelta ? 'text-[#DC2626] bg-[#DC2626]/10 border-[#DC2626]/30' : 'text-[#10B981] bg-[#10B981]/10 border-[#10B981]/30')
            : (dangerDelta ? 'text-[#10B981] bg-[#10B981]/10 border-[#10B981]/30' : 'text-[#DC2626] bg-[#DC2626]/10 border-[#DC2626]/30')
        )}>
          {positive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
          <span>{Math.abs(kpi.delta)}</span>
        </div>
      </div>
    </motion.div>
  )
}
