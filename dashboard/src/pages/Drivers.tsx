import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { Search, ArrowUpDown } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { Sparkline } from '@/components/charts/Charts'
import { drivers, vehicleById } from '@/data/mockData'
import { scoreColor, seeded } from '@/lib/utils'

const STATUS_LABEL: Record<string, string> = { safe: 'On Trip', warning: 'Warning', emergency: 'Emergency', idle: 'Idle', offline: 'Offline' }

export default function Drivers() {
  const [q, setQ] = useState('')
  const [sortKey, setSortKey] = useState<'safetyScore' | 'trips' | 'distanceToday'>('safetyScore')

  const rows = useMemo(() => {
    return drivers
      .filter((d) => (d.name + d.employeeId + d.fleet).toLowerCase().includes(q.toLowerCase()))
      .sort((a, b) => (b[sortKey] as number) - (a[sortKey] as number))
  }, [q, sortKey])

  return (
    <div>
      <PageHeader
        title="Drivers"
        subtitle="Every driver, their live status, safety score and performance."
        actions={
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search drivers…"
              className="h-10 w-64 rounded-xl bg-slate-50 border border-slate-200 pl-9 pr-3 text-[13px] text-primary placeholder:text-muted outline-none focus:border-[#10b981]/40 shadow-inner" />
          </div>
        }
      />

      <GlassCard padded={false} className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-[13px]">
            <thead>
              <tr className="text-left text-muted border-b border-slate-100 text-[11px] uppercase tracking-wider bg-slate-50/50">
                <th className="font-medium px-5 py-3.5">Driver</th>
                <th className="font-medium px-4 py-3.5">Status</th>
                <th className="font-medium px-4 py-3.5 cursor-pointer" onClick={() => setSortKey('safetyScore')}>
                  <span className="inline-flex items-center gap-1">Safety <ArrowUpDown className="h-3 w-3" /></span>
                </th>
                <th className="font-medium px-4 py-3.5">Trend</th>
                <th className="font-medium px-4 py-3.5 cursor-pointer" onClick={() => setSortKey('trips')}>Trips</th>
                <th className="font-medium px-4 py-3.5 cursor-pointer" onClick={() => setSortKey('distanceToday')}>Distance</th>
                <th className="font-medium px-4 py-3.5">Hours</th>
                <th className="font-medium px-4 py-3.5">Vehicle</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((d, i) => {
                const v = vehicleById(d.vehicleId)
                const spark = Array.from({ length: 8 }, (_, k) => d.safetyScore + Math.round(seeded(i * 8 + k) * 12 - 6))
                return (
                  <motion.tr key={d.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.03 }}
                    className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <Avatar name={d.name} size={38} />
                        <div>
                          <div className="text-primary font-medium">{d.name}</div>
                          <div className="text-[11px] text-muted">{d.employeeId} · {d.fleet}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3"><Badge tone={d.status} dot={d.status !== 'idle'}>{STATUS_LABEL[d.status]}</Badge></td>
                    <td className="px-4 py-3"><span className="font-display font-bold text-base tabular-nums" style={{ color: scoreColor(d.safetyScore) }}>{d.safetyScore}</span></td>
                    <td className="px-4 py-3 w-28"><Sparkline data={spark} color={scoreColor(d.safetyScore)} height={34} /></td>
                    <td className="px-4 py-3 text-secondary tabular-nums">{d.trips}</td>
                    <td className="px-4 py-3 text-secondary tabular-nums">{d.distanceToday} km</td>
                    <td className="px-4 py-3 text-secondary tabular-nums">{d.drivingHours} h</td>
                    <td className="px-4 py-3 text-secondary">{v?.name}</td>
                  </motion.tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </GlassCard>
    </div>
  )
}
