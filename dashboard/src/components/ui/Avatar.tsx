import { cn } from '@/lib/utils'

const GRADIENTS = [
  'linear-gradient(135deg,#22d3ee,#3b82f6)',
  'linear-gradient(135deg,#34d399,#06b6d4)',
  'linear-gradient(135deg,#a78bfa,#3b82f6)',
  'linear-gradient(135deg,#f472b6,#a78bfa)',
  'linear-gradient(135deg,#fbbf24,#fb7185)',
  'linear-gradient(135deg,#60a5fa,#22d3ee)',
]

function initials(name: string) {
  if (!name) return 'AG'
  return name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
}

export function Avatar({ name, src, size = 40, className }: { name: string; src?: string; size?: number; className?: string }) {
  if (src && (src.startsWith('data:image') || src.startsWith('http') || src.startsWith('blob:'))) {
    return (
      <img
        src={src}
        alt={name || 'Driver'}
        className={cn('rounded-full object-cover shrink-0 shadow-md', className)}
        style={{ width: size, height: size }}
      />
    )
  }

  const safeName = name || 'Driver'
  const g = GRADIENTS[safeName.charCodeAt(0) % GRADIENTS.length]
  return (
    <div
      className={cn('grid place-items-center rounded-full font-semibold text-white shrink-0 shadow-lg', className)}
      style={{ width: size, height: size, background: g, fontSize: size * 0.36 }}
    >
      {initials(safeName)}
    </div>
  )
}
