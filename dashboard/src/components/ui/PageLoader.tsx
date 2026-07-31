import { motion } from 'framer-motion'
import { ShieldAlert } from 'lucide-react'

/** Suspense fallback shown while a lazily-loaded route chunk downloads. */
export function PageLoader() {
  return (
    <div className="grid place-items-center py-32">
      <div className="flex flex-col items-center gap-4">
        <div className="relative h-12 w-12">
          <motion.span
            className="absolute inset-0 rounded-2xl border-2 border-cyan-400/25"
            animate={{ rotate: 360 }}
            transition={{ duration: 1.1, repeat: Infinity, ease: 'linear' }}
            style={{ borderTopColor: 'var(--color-cyan)' }}
          />
          <div className="absolute inset-0 grid place-items-center">
            <ShieldAlert className="h-5 w-5 text-cyan-300" />
          </div>
        </div>
        <span className="text-[12px] text-muted tracking-wide">Loading module…</span>
      </div>
    </div>
  )
}
