import { cn } from '@/lib/utils'

const TONES: Record<string, string> = {
  safe: 'text-emerald-300 bg-emerald-400/10 border-emerald-400/25',
  warning: 'text-amber-300 bg-amber-400/10 border-amber-400/25',
  warn: 'text-amber-300 bg-amber-400/10 border-amber-400/25',
  emergency: 'text-rose-300 bg-rose-500/10 border-rose-500/25',
  critical: 'text-rose-300 bg-rose-500/10 border-rose-500/25',
  danger: 'text-rose-300 bg-rose-500/10 border-rose-500/25',
  high: 'text-orange-300 bg-orange-400/10 border-orange-400/25',
  medium: 'text-amber-300 bg-amber-400/10 border-amber-400/25',
  low: 'text-sky-300 bg-sky-400/10 border-sky-400/25',
  idle: 'text-sky-300 bg-sky-400/10 border-sky-400/25',
  offline: 'text-slate-400 bg-slate-400/10 border-slate-400/20',
  cyan: 'text-cyan-300 bg-cyan-400/10 border-cyan-400/25',
  info: 'text-cyan-300 bg-cyan-400/10 border-cyan-400/25',
  positive: 'text-emerald-300 bg-emerald-400/10 border-emerald-400/25',
}

export function Badge({
  tone = 'cyan',
  children,
  dot = false,
  className,
}: {
  tone?: string
  children: React.ReactNode
  dot?: boolean
  className?: string
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-[11px] font-medium capitalize',
        TONES[tone] ?? TONES.cyan,
        className,
      )}
    >
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current animate-pulse-glow" />}
      {children}
    </span>
  )
}
