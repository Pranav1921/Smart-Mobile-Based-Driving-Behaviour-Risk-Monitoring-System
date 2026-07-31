import { motion } from 'framer-motion'
import { Server, Database, Plug, Satellite, Smartphone, Activity } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { AreaLineChart } from '@/components/charts/Charts'

const SERVICES = [
  { icon: Server, label: 'Backend API', status: 'Operational', uptime: '99.98%', latency: '82 ms', tone: 'safe' },
  { icon: Database, label: 'PostgreSQL', status: 'Operational', uptime: '99.99%', latency: '11 ms', tone: 'safe' },
  { icon: Plug, label: 'Socket.IO Gateway', status: 'Operational', uptime: '99.94%', latency: '38 ms', tone: 'safe' },
  { icon: Satellite, label: 'GPS Ingest', status: 'Degraded', uptime: '98.10%', latency: '210 ms', tone: 'warn' },
  { icon: Smartphone, label: 'Connected Devices', status: '6 / 8 online', uptime: '—', latency: '—', tone: 'warn' },
  { icon: Activity, label: 'ML Engine', status: 'Operational', uptime: '99.90%', latency: '124 ms', tone: 'safe' },
]

export default function SystemHealth() {
  return (
    <div>
      <PageHeader title="System Health" subtitle="Live status of backend, database, APIs, GPS ingest and connected devices."
        actions={<Badge tone="safe" dot>All core systems operational</Badge>} />

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 mb-5">
        {SERVICES.map((s, i) => (
          <motion.div key={s.label} initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
            <GlassCard>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`grid place-items-center h-10 w-10 rounded-xl ${s.tone === 'safe' ? 'bg-emerald-400/10 text-emerald-300' : 'bg-amber-400/10 text-amber-300'}`}><s.icon className="h-5 w-5" /></div>
                  <div><div className="text-[13.5px] text-primary font-medium">{s.label}</div><div className="text-[11px] text-muted">{s.status}</div></div>
                </div>
                <span className={`h-2.5 w-2.5 rounded-full ${s.tone === 'safe' ? 'bg-emerald-400' : 'bg-amber-400'} animate-pulse-glow`} />
              </div>
              <div className="grid grid-cols-2 gap-2 mt-4">
                <div className="glass rounded-lg p-2.5"><div className="text-[10px] text-muted">Uptime</div><div className="text-[13px] text-primary font-medium mt-0.5">{s.uptime}</div></div>
                <div className="glass rounded-lg p-2.5"><div className="text-[10px] text-muted">Latency</div><div className="text-[13px] text-primary font-medium mt-0.5">{s.latency}</div></div>
              </div>
            </GlassCard>
          </motion.div>
        ))}
      </div>

      <GlassCard>
        <h3 className="font-display font-semibold text-primary mb-1">API Response Time</h3>
        <p className="text-xs text-muted mb-3">Rolling 60-minute latency (ms)</p>
        <AreaLineChart labels={Array.from({ length: 20 }, (_, i) => `${i}`)}
          series={[{ name: 'Latency', data: Array.from({ length: 20 }, (_, i) => 70 + Math.sin(i * 0.6) * 25 + (i % 5 === 0 ? 30 : 0)), color: '#22d3ee' }]} height={220} />
      </GlassCard>
    </div>
  )
}
