import { motion } from 'framer-motion'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'

export function SimplePage({ title, subtitle, icon: Icon }: { title: string; subtitle: string; icon: React.ElementType }) {
  return (
    <div>
      <PageHeader title={title} subtitle={subtitle} />
      <GlassCard className="grid place-items-center py-24 text-center">
        <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="grid place-items-center">
          <div className="grid place-items-center h-16 w-16 rounded-2xl accent-gradient ring-glow mb-4">
            <Icon className="h-7 w-7 text-white" />
          </div>
          <div className="font-display font-semibold text-primary text-lg">{title}</div>
          <p className="text-secondary text-sm mt-1 max-w-sm">{subtitle}</p>
          <span className="mt-4 text-[11px] text-muted px-3 py-1 rounded-full border border-white/10">Module scaffolded · ready for build-out</span>
        </motion.div>
      </GlassCard>
    </div>
  )
}
