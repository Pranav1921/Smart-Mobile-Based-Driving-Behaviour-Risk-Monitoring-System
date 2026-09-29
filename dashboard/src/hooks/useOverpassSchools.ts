import { useState, useEffect } from 'react'
import type { RegionOption } from '@/data/regionsData'

export interface OsmSchool {
  id: number
  name: string
  amenity: string // 'school' | 'college' | 'university' | 'kindergarten'
  lat: number
  lng: number
}

/**
 * Fetches ALL schools, colleges, universities, and kindergartens
 * within a bounding box derived from the active region's center.
 * Uses the free public Overpass API (OpenStreetMap data).
 */
export function useOverpassSchools(activeRegion: RegionOption | null) {
  const [schools, setSchools] = useState<OsmSchool[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!activeRegion?.center) return

    const [lat, lng] = activeRegion.center
    // Build a ~10km radius bounding box around the region center
    const delta = 0.12  // ~13 km
    const south = lat - delta
    const north = lat + delta
    const west = lng - delta
    const east = lng + delta

    const query = `
      [out:json][timeout:15];
      (
        node["amenity"="school"](${south},${west},${north},${east});
        node["amenity"="college"](${south},${west},${north},${east});
        node["amenity"="university"](${south},${west},${north},${east});
        node["amenity"="kindergarten"](${south},${west},${north},${east});
        way["amenity"="school"](${south},${west},${north},${east});
        way["amenity"="college"](${south},${west},${north},${east});
        way["amenity"="university"](${south},${west},${north},${east});
      );
      out center;
    `.trim()

    const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`

    setLoading(true)
    setError(null)

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 12000)

    fetch(url, { signal: controller.signal })
      .then((res) => {
        if (!res.ok) throw new Error(`Overpass API error: ${res.status}`)
        return res.json()
      })
      .then((data) => {
        const results: OsmSchool[] = []
        for (const el of data.elements ?? []) {
          const name: string = el.tags?.name || el.tags?.['name:en'] || 'Unnamed School'
          const amenity: string = el.tags?.amenity || 'school'

          let elLat: number | undefined
          let elLng: number | undefined

          if (el.type === 'node') {
            elLat = el.lat
            elLng = el.lon
          } else if (el.type === 'way' && el.center) {
            elLat = el.center.lat
            elLng = el.center.lon
          }

          if (elLat !== undefined && elLng !== undefined) {
            results.push({ id: el.id, name, amenity, lat: elLat, lng: elLng })
          }
        }
        setSchools(results)
      })
      .catch((err) => {
        if (err.name !== 'AbortError') {
          setError(err.message)
          console.warn('[useOverpassSchools] Fetch failed:', err.message)
        }
      })
      .finally(() => {
        clearTimeout(timeout)
        setLoading(false)
      })

    return () => {
      controller.abort()
      clearTimeout(timeout)
    }
  }, [activeRegion?.id])  // Re-fetch only when region changes

  return { schools, loading, error }
}
