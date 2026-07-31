import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatNumber(n: number): string {
  return new Intl.NumberFormat('en-IN').format(Math.round(n))
}

export function formatDistance(km: number): string {
  return `${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 1 }).format(km)} km`
}

/** Deterministic pseudo-random for stable mock jitter */
export function seeded(seed: number): number {
  const x = Math.sin(seed * 9973.13) * 10000
  return x - Math.floor(x)
}

// Return literal hex (not CSS var()) — these values are also fed to
// <canvas> gradients (Chart.js addColorStop), which cannot parse var().
export function scoreColor(score: number): string {
  if (score >= 85) return '#34d399' // safe
  if (score >= 70) return '#fbbf24' // warn
  return '#f43f5e' // danger
}

export function scoreTone(score: number): 'safe' | 'warn' | 'danger' {
  if (score >= 85) return 'safe'
  if (score >= 70) return 'warn'
  return 'danger'
}
