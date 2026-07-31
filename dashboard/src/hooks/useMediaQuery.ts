import { useEffect, useState } from 'react'

/** Reactive CSS media-query matcher (SSR-safe-ish for this SPA). */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false,
  )

  useEffect(() => {
    const mql = window.matchMedia(query)
    const handler = () => setMatches(mql.matches)
    handler()
    mql.addEventListener('change', handler)
    return () => mql.removeEventListener('change', handler)
  }, [query])

  return matches
}

/** True at Tailwind's lg breakpoint and up (>=1024px). */
export function useIsDesktop() {
  return useMediaQuery('(min-width: 1024px)')
}
