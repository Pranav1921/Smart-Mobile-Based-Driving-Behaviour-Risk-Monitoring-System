import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Gauge, Battery, Wifi, Satellite, MapPin } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { drivers, vehicleById } from '@/data/mockData'
import { cn, scoreColor } from '@/lib/utils'

const STATUS_LABEL: Record<string, string> = { safe: 'On Trip', warning: 'Warning', emergency: 'Emergency', idle: 'Idle', offline: 'Offline' }

export default function FleetMonitoring() {
  const navigate = useNavigate()
  return (
    <div>
      <PageHeader title="Fleet Monitoring" subtitle="Every active driver and vehicle at a glance — live telemetry snapshot." />
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {drivers.map((d, i) => {
          const v = vehicleById(d.vehicleId)
          return (
            <motion.div key={d.id} initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.04 }}>
              <GlassCard onClick={() => navigate('/map')} className="cursor-pointer">
                <div className="flex items-center gap-3">
                  <Avatar name={d.name} size={44} />
                  <div className="min-w-0 flex-1">
                    <div className="text-primary font-medium text-[14px] truncate">{d.name}</div>
                    <div className="text-[11px] text-muted truncate">{v?.name} · {v?.registration}</div>
                  </div>
                  <Badge tone={d.status} dot={d.status !== 'idle'}>{STATUS_LABEL[d.status]}</Badge>
                </div>

                <div className="flex items-center gap-1.5 text-[11px] text-muted mt-3"><MapPin className="h-3 w-3" />{d.locationName}</div>

                <div className="grid grid-cols-4 gap-2 mt-3">
                  <Tele icon={Gauge} value={`${d.speed}`} sub="km/h" />
                  <Tele icon={Battery} value={`${d.battery}`} sub="%" warn={d.battery <= 20} />
                  <Tele icon={Wifi} value={`${d.internet}`} sub="%" warn={d.internet <= 40} />
                  <Tele icon={Satellite} value={d.gps ? 'OK' : '—'} sub="gps" warn={!d.gps} />
                </div>

                <div className="flex items-center justify-between mt-4 pt-3 border-t border-white/5">
                  <span className="text-[11px] text-muted">Safety Score</span>
                  <div className="flex items-center gap-2 flex-1 mx-3">
                    <div className="h-1.5 rounded-full bg-white/8 overflow-hidden flex-1">
                      <motion.div initial={{ width: 0 }} animate={{ width: `${d.safetyScore}%` }} transition={{ duration: 0.9 }}
                        className="h-full rounded-full" style={{ background: scoreColor(d.safetyScore) }} />
                    </div>
                  </div>
                  <span className="font-display font-bold" style={{ color: scoreColor(d.safetyScore) }}>{d.safetyScore}</span>
                </div>
              </GlassCard>
            </motion.div>
          )
        })}
      </div>
    </div>
  )
}

function Tele({ icon: Icon, value, sub, warn }: { icon: React.ElementType; value: string; sub: string; warn?: boolean }) {
  return (
    <div className={cn('glass rounded-lg p-2 text-center', warn && 'border-rose-500/30')}>
      <Icon className={cn('h-3.5 w-3.5 mx-auto', warn ? 'text-rose-300' : 'text-cyan-300')} />
      <div className="text-[13px] text-primary font-semibold mt-1 leading-none">{value}</div>
      <div className="text-[9px] text-muted mt-0.5">{sub}</div>
    </div>
  )
}
