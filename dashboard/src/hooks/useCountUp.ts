import { useEffect, useRef, useState } from 'react'

/** Animated count-up with easeOutExpo, respects reduced motion. */
export function useCountUp(target: number, duration = 1400, decimals = 0) {
  const [value, setValue] = useState(0)
  const startRef = useRef<number | null>(null)
  const frameRef = useRef<number>(0)

  useEffect(() => {
    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (prefersReduced) {
      setValue(target)
      return
    }
    startRef.current = null
    const tick = (t: number) => {
      if (startRef.current === null) startRef.current = t
      const elapsed = t - startRef.current
      const p = Math.min(elapsed / duration, 1)
      const eased = p === 1 ? 1 : 1 - Math.pow(2, -10 * p)
      setValue(target * eased)
      if (p < 1) frameRef.current = requestAnimationFrame(tick)
    }
    frameRef.current = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(frameRef.current)
  }, [target, duration])

  const factor = Math.pow(10, decimals)
  return Math.round(value * factor) / factor
}
