import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowRight, MapPin, Radio } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { KpiCard } from '@/components/ui/KpiCard'
import { GlassCard } from '@/components/ui/GlassCard'
import { AiInsightCard, AiSummaryHeader } from '@/components/ui/AiInsightCard'
import { Badge } from '@/components/ui/Badge'
import { Avatar } from '@/components/ui/Avatar'
import { AreaLineChart, BarChartCard } from '@/components/charts/Charts'
import { kpis, aiInsights, scoreTrend, eventBreakdown, drivers, events } from '@/data/mockData'
import { cn } from '@/lib/utils'

const EVENT_LABEL: Record<string, string> = {
  crash: 'Crash', overspeed: 'Overspeed', harsh_braking: 'Harsh Braking',
  harsh_acceleration: 'Harsh Accel', sharp_turn: 'Sharp Turn', phone_usage: 'Phone Usage',
  low_battery: 'Low Battery', gps_lost: 'GPS Lost',
}

export default function Dashboard() {
  const navigate = useNavigate()
  const active = drivers.filter((d) => d.status !== 'offline')

  return (
    <div>
      <PageHeader
        title="Fleet Command Center"
        subtitle="Real-time intelligence across every driver, vehicle, trip and safety event."
        actions={
          <button onClick={() => navigate('/map')}
            className="flex items-center gap-2 h-10 px-4 rounded-xl accent-gradient text-white text-[13px] font-semibold shadow-lg ring-glow hover:brightness-110 transition">
            <Radio className="h-4 w-4" /> Open Live Map
          </button>
        }
      />

      {/* KPI grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-5 gap-3.5 mb-6">
        {kpis.map((k, i) => <KpiCard key={k.key} kpi={k} index={i} />)}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        {/* Left: charts */}
        <div className="xl:col-span-2 space-y-5">
          <GlassCard>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-display font-semibold text-primary">Fleet Safety Trend</h3>
                <p className="text-xs text-muted mt-0.5">7-day average · fleet vs top performer</p>
              </div>
              <Badge tone="positive" dot>+4.8% this week</Badge>
            </div>
            <AreaLineChart
              labels={scoreTrend.labels}
              series={[
                { name: 'Fleet Avg', data: scoreTrend.fleet, color: '#10b981' },
                { name: 'Top Performer', data: scoreTrend.best, color: '#059669', fill: false },
              ]}
            />
          </GlassCard>

          <div className="grid md:grid-cols-2 gap-5">
            <GlassCard>
              <h3 className="font-display font-semibold text-primary mb-1">Event Distribution</h3>
              <p className="text-xs text-muted mb-3">Detected events · today</p>
              <BarChartCard labels={eventBreakdown.labels} values={eventBreakdown.values} height={200} horizontal />
            </GlassCard>

            <GlassCard padded={false}>
              <div className="p-5 pb-2 flex items-center justify-between">
                <div>
                  <h3 className="font-display font-semibold text-primary">Recent Events</h3>
                  <p className="text-xs text-muted mt-0.5">Live safety feed</p>
                </div>
                <button onClick={() => navigate('/events')} className="text-xs text-cyan-300 flex items-center gap-1 hover:gap-1.5 transition-all">
                  All <ArrowRight className="h-3 w-3" />
                </button>
              </div>
              <div className="px-3 pb-3 space-y-1 max-h-[220px] overflow-y-auto no-scrollbar">
                {events.slice(0, 6).map((e, i) => (
                  <motion.div key={e.id} initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}
                    className="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-white shadow-sm hover:shadow-md transition-shadow border border-slate-100">
                    <span className={cn('h-2 w-2 rounded-full shrink-0',
                      e.severity === 'critical' ? 'bg-rose-500 animate-pulse-glow' : e.severity === 'high' ? 'bg-orange-400' : e.severity === 'medium' ? 'bg-amber-400' : 'bg-sky-400')} />
                    <div className="min-w-0 flex-1">
                      <div className="text-[12.5px] text-primary font-medium truncate">{EVENT_LABEL[e.type]} · {e.driverName}</div>
                      <div className="text-[11px] text-muted truncate flex items-center gap-1"><MapPin className="h-2.5 w-2.5" />{e.locationName}</div>
                    </div>
                    <div className="text-[10px] text-muted whitespace-nowrap">{e.time}</div>
                  </motion.div>
                ))}
              </div>
            </GlassCard>
          </div>
        </div>

        {/* Right: AI summary */}
        <div className="space-y-5">
          <GlassCard>
            <AiSummaryHeader />
            <div className="space-y-2.5">
              {aiInsights.map((ins, i) => (
                <AiInsightCard key={ins.id} insight={ins} index={i} onClick={() => navigate('/map')} />
              ))}
            </div>
          </GlassCard>

          <GlassCard padded={false}>
            <div className="p-5 pb-3 flex items-center justify-between">
              <h3 className="font-display font-semibold text-primary">Drivers Online</h3>
              <Badge tone="safe" dot>{active.length} active</Badge>
            </div>
            <div className="px-3 pb-3 space-y-2">
              {active.slice(0, 5).map((d, idx) => (
                <button key={d.id} onClick={() => navigate('/map')}
                  className={cn("w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all shadow-sm border",
                    idx === 1 // Selected item
                      ? "bg-emerald-500 border-emerald-500 text-white shadow-md shadow-emerald-500/20 transform scale-[1.02]" 
                      : "bg-white border-slate-100 hover:bg-slate-50 text-slate-800"
                  )}>
                  <Avatar name={d.name} size={34} />
                  <div className="min-w-0 flex-1 text-left">
                    <div className={cn("text-[13px] font-medium truncate", idx === 1 ? "text-white" : "text-primary")}>{d.name}</div>
                    <div className={cn("text-[11px] truncate", idx === 1 ? "text-white/80" : "text-muted")}>{d.locationName}</div>
                  </div>
                  <div className="text-right">
                    <div className="text-[13px] font-semibold tabular-nums" style={{ color: idx === 1 ? '#ffffff' : (d.safetyScore >= 85 ? '#10b981' : d.safetyScore >= 70 ? '#f59e0b' : '#ef4444') }}>{d.safetyScore}</div>
                    <div className={cn("text-[10px]", idx === 1 ? "text-white/80" : "text-muted")}>{d.speed} km/h</div>
                  </div>
                </button>
              ))}
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  )
}
