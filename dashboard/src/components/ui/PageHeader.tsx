import { motion } from 'framer-motion'

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string
  subtitle?: string
  actions?: React.ReactNode
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="flex flex-wrap items-end justify-between gap-4 mb-6"
    >
      <div>
        <h1 className="font-display text-2xl md:text-[28px] font-bold tracking-tight text-primary">{title}</h1>
        {subtitle && <p className="text-secondary text-sm mt-1 max-w-2xl">{subtitle}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </motion.div>
  )
}
