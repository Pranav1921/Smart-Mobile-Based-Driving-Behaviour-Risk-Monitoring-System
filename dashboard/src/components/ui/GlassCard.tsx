import { motion, type HTMLMotionProps } from 'framer-motion'
import { cn } from '@/lib/utils'

interface GlassCardProps extends HTMLMotionProps<'div'> {
  hover?: boolean
  padded?: boolean
}

export function GlassCard({ className, hover = true, padded = true, children, ...rest }: GlassCardProps) {
  return (
    <motion.div
      className={cn(
        'glass rounded-2xl relative overflow-hidden',
        hover && 'glass-hover',
        padded && 'p-5',
        className,
      )}
      {...rest}
    >
      {children}
    </motion.div>
  )
}
