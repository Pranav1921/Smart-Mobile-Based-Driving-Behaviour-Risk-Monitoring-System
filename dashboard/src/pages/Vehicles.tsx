import { motion } from 'framer-motion'
import { ShieldCheck, CalendarClock, Wrench } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { VehicleRender } from '@/components/map/VehicleRender'
import { vehicles, drivers } from '@/data/mockData'
import { cn } from '@/lib/utils'

export default function Vehicles() {
  return (
    <div>
      <PageHeader title="Vehicles" subtitle="Fleet inventory — health, assignment, insurance and registration." />
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {vehicles.map((v, i) => {
          const driver = drivers.find((d) => d.vehicleId === v.id)
          const healthTone = v.health >= 85 ? 'safe' : v.health >= 72 ? 'warn' : 'danger'
          return (
            <motion.div key={v.id} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
              <GlassCard className="overflow-hidden">
                <VehicleRender type={v.type} name={v.name} />
                <div className="flex items-start justify-between mt-2">
                  <div>
                    <div className="font-display font-semibold text-primary">{v.name}</div>
                    <div className="text-[11px] text-muted mt-0.5">{v.registration}</div>
                  </div>
                  <Badge tone={healthTone} className="capitalize">{v.type}</Badge>
                </div>

                <div className="mt-4 space-y-3">
                  <div>
                    <div className="flex items-center justify-between text-[11px] mb-1.5">
                      <span className="text-muted flex items-center gap-1.5"><Wrench className="h-3 w-3" /> Vehicle Health</span>
                      <span className="text-primary font-medium">{v.health}%</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-white/8 overflow-hidden">
                      <motion.div initial={{ width: 0 }} animate={{ width: `${v.health}%` }} transition={{ duration: 1, delay: 0.2 }}
                        className={cn('h-full rounded-full', healthTone === 'safe' ? 'bg-emerald-400' : healthTone === 'warn' ? 'bg-amber-400' : 'bg-rose-500')} />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-[12px]">
                    <div className="glass rounded-lg p-2.5">
                      <div className="text-[10px] text-muted flex items-center gap-1"><ShieldCheck className="h-3 w-3" /> Insurance</div>
                      <div className="text-primary font-medium mt-0.5">{v.insuranceValid}</div>
                    </div>
                    <div className="glass rounded-lg p-2.5">
                      <div className="text-[10px] text-muted flex items-center gap-1"><CalendarClock className="h-3 w-3" /> Assigned</div>
                      <div className="text-primary font-medium mt-0.5 truncate">{driver ? driver.name : 'Unassigned'}</div>
                    </div>
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          )
        })}
      </div>
    </div>
  )
}
