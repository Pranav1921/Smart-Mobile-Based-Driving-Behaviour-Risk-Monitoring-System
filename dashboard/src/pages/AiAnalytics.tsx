import { motion } from 'framer-motion'
import { Trophy, Brain, TrendingUp, Target } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { AreaLineChart, RadarCard, BarChartCard } from '@/components/charts/Charts'
import { drivers, scoreTrend } from '@/data/mockData'
import { scoreColor } from '@/lib/utils'

export default function AiAnalytics() {
  const ranked = [...drivers].sort((a, b) => b.safetyScore - a.safetyScore)
  const predictions = [
    { title: 'NH66 · Surathkal corridor', detail: '+23% incident likelihood this evening (18:00–21:00)', tone: 'critical' as const },
    { title: 'Imran Khan', detail: 'Trending toward high-risk band within 5 days without intervention', tone: 'warning' as const },
    { title: 'Fleet safety score', detail: 'Projected to reach 87.5 by end of month at current pace', tone: 'positive' as const },
  ]

  return (
    <div>
      <PageHeader title="AI Analytics" subtitle="Behaviour trends, fleet risk, driver ranking and predictive intelligence." />

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3.5 mb-5">
        <Kpi icon={Brain} label="Fleet Risk Index" value="Low–Med" tone="#fbbf24" />
        <Kpi icon={TrendingUp} label="Behaviour Trend" value="+6.3%" tone="#34d399" />
        <Kpi icon={Target} label="Model Accuracy" value="94.1%" tone="#22d3ee" />
        <Kpi icon={Trophy} label="Top Performer" value={ranked[0].name.split(' ')[0]} tone="#a78bfa" />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        <GlassCard className="xl:col-span-2">
          <h3 className="font-display font-semibold text-primary mb-1">Behaviour Trend</h3>
          <p className="text-xs text-muted mb-3">Fleet-wide safety score · 7 days</p>
          <AreaLineChart labels={scoreTrend.labels} series={[
            { name: 'Fleet Avg', data: scoreTrend.fleet, color: '#22d3ee' },
            { name: 'Top Performer', data: scoreTrend.best, color: '#34d399', fill: false },
          ]} height={260} />
        </GlassCard>

        <GlassCard>
          <h3 className="font-display font-semibold text-primary mb-1">Driving Profile</h3>
          <p className="text-xs text-muted mb-1">Fleet behaviour radar</p>
          <RadarCard
            labels={['Smoothness', 'Speed Control', 'Braking', 'Cornering', 'Focus', 'Consistency']}
            series={[
              { name: 'Fleet', data: [82, 68, 74, 71, 79, 80], color: '#22d3ee' },
              { name: 'Top 10%', data: [95, 92, 90, 88, 96, 94], color: '#34d399' },
            ]}
          />
        </GlassCard>

        <GlassCard padded={false} className="xl:col-span-2 overflow-hidden">
          <div className="p-5 pb-3 flex items-center gap-2">
            <Trophy className="h-4 w-4 text-amber-300" />
            <h3 className="font-display font-semibold text-primary">Driver Leaderboard</h3>
          </div>
          <div className="px-3 pb-3">
            {ranked.map((d, i) => (
              <motion.div key={d.id} initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-white/[0.03]">
                <span className={`w-6 text-center font-display font-bold ${i < 3 ? 'text-amber-300' : 'text-muted'}`}>{i + 1}</span>
                <Avatar name={d.name} size={34} />
                <div className="flex-1 min-w-0">
                  <div className="text-[13px] text-primary font-medium truncate">{d.name}</div>
                  <div className="text-[11px] text-muted">{d.drivingStyle} · {d.trips} trips</div>
                </div>
                <div className="w-28 hidden sm:block">
                  <div className="h-1.5 rounded-full bg-white/8 overflow-hidden">
                    <motion.div initial={{ width: 0 }} animate={{ width: `${d.safetyScore}%` }} transition={{ duration: 0.9, delay: i * 0.05 }}
                      className="h-full rounded-full" style={{ background: scoreColor(d.safetyScore) }} />
                  </div>
                </div>
                <span className="font-display font-bold w-8 text-right" style={{ color: scoreColor(d.safetyScore) }}>{d.safetyScore}</span>
              </motion.div>
            ))}
          </div>
        </GlassCard>

        <div className="space-y-4">
          <GlassCard>
            <h3 className="font-display font-semibold text-primary mb-1">Event Mix</h3>
            <BarChartCard labels={['O.Speed', 'Brake', 'Turn', 'Accel', 'Phone']} values={[14, 9, 7, 4, 2]} height={140} />
          </GlassCard>
          <GlassCard>
            <div className="flex items-center gap-2 mb-3"><Brain className="h-4 w-4 text-cyan-300" /><h3 className="font-display font-semibold text-primary">Predictions</h3></div>
            <div className="space-y-2">
              {predictions.map((p, i) => (
                <div key={i} className="glass rounded-xl p-3">
                  <div className="flex items-center justify-between mb-1"><span className="text-[12.5px] text-primary font-medium">{p.title}</span><Badge tone={p.tone}>{p.tone}</Badge></div>
                  <p className="text-[11.5px] text-muted leading-relaxed">{p.detail}</p>
                </div>
              ))}
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  )
}

function Kpi({ icon: Icon, label, value, tone }: { icon: React.ElementType; label: string; value: string; tone: string }) {
  return (
    <GlassCard className="flex items-center gap-3">
      <div className="grid place-items-center h-10 w-10 rounded-xl shrink-0" style={{ background: tone + '1a', color: tone }}><Icon className="h-5 w-5" /></div>
      <div><div className="text-[11px] text-muted">{label}</div><div className="font-display font-bold text-primary text-lg">{value}</div></div>
    </GlassCard>
  )
}
