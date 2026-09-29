/**
 * External Geocoding Service:
 * Resolves location names to precise geographic coordinates (latitude, longitude)
 * and addresses using live external APIs (Photon / OpenStreetMap / Open-Meteo).
 * Includes intelligent multi-tier caching (memory + localStorage) and graceful fallbacks.
 */

export interface GeocodedLocation {
  lat: number
  lng: number
  displayName: string
  state?: string
  district?: string
  country?: string
  source: 'photon' | 'open-meteo' | 'nominatim' | 'cache' | 'fallback'
}

// In-memory runtime cache
const memoryCache = new Map<string, GeocodedLocation>()

/**
 * Normalizes query string for reliable geocoding matching:
 * Strips tactical UI words ('Hub', 'Command', 'Sector', 'Jurisdiction', 'Logistics')
 */
export function cleanLocationQuery(rawName: string, state?: string, country = 'India'): string {
  let cleaned = rawName
    .replace(/\b(taluk|hub|command|sector|jurisdiction|logistics|depot|belt|corridor|central|hq|peninsula|lagoons|hills|zone|grid)\b/gi, '')
    .replace(/\s+/g, ' ')
    .trim()

  // Add state & country context if missing for accurate global resolution
  if (state && !cleaned.toLowerCase().includes(state.toLowerCase())) {
    cleaned = `${cleaned}, ${state}`
  }
  if (country && !cleaned.toLowerCase().includes(country.toLowerCase())) {
    cleaned = `${cleaned}, ${country}`
  }
  return cleaned
}

/**
 * Resolves any location name to exact latitude and longitude from external sources.
 */
export async function geocodeLocationExternal(
  rawName: string,
  state?: string,
  country = 'India'
): Promise<GeocodedLocation | null> {
  if (!rawName || !rawName.trim()) return null

  const query = cleanLocationQuery(rawName, state, country)
  const cacheKey = `geo_${query.toLowerCase().replace(/[^a-z0-9]/g, '_')}`

  // 1. Check in-memory cache
  if (memoryCache.has(cacheKey)) {
    return memoryCache.get(cacheKey)!
  }

  // 2. Check localStorage cache
  try {
    const cached = localStorage.getItem(cacheKey)
    if (cached) {
      const parsed: GeocodedLocation = JSON.parse(cached)
      if (parsed && typeof parsed.lat === 'number' && typeof parsed.lng === 'number') {
        memoryCache.set(cacheKey, { ...parsed, source: 'cache' })
        return { ...parsed, source: 'cache' }
      }
    }
  } catch (_) {}

  // 3. Query External Source 1: Photon by Komoot (CORS-enabled, OSM data, very fast in India & World)
  try {
    const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=1`
    const res = await fetch(url, { signal: AbortSignal.timeout(4000) })
    if (res.ok) {
      const data = await res.json()
      if (data.features && data.features.length > 0) {
        const feature = data.features[0]
        const [lon, lat] = feature.geometry.coordinates
        if (typeof lat === 'number' && typeof lon === 'number' && !isNaN(lat) && !isNaN(lon)) {
          const props = feature.properties || {}
          const result: GeocodedLocation = {
            lat,
            lng: lon,
            displayName: [props.name, props.county, props.state, props.country].filter(Boolean).join(', ') || query,
            state: props.state,
            district: props.county || props.district,
            country: props.country,
            source: 'photon',
          }
          memoryCache.set(cacheKey, result)
          try {
            localStorage.setItem(cacheKey, JSON.stringify(result))
          } catch (_) {}
          return result
        }
      }
    }
  } catch (err) {
    // Failover to secondary source
  }

  // 4. Query External Source 2: Open-Meteo Geocoding API (Fast global database)
  try {
    const simpleName = rawName.replace(/\b(taluk|hub|command|sector|logistics)\b/gi, '').trim().split(',')[0].trim()
    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(simpleName)}&count=1&language=en&format=json`
    const res = await fetch(url, { signal: AbortSignal.timeout(4000) })
    if (res.ok) {
      const data = await res.json()
      if (data.results && data.results.length > 0) {
        const item = data.results[0]
        if (typeof item.latitude === 'number' && typeof item.longitude === 'number') {
          const result: GeocodedLocation = {
            lat: item.latitude,
            lng: item.longitude,
            displayName: [item.name, item.admin2, item.admin1, item.country].filter(Boolean).join(', ') || query,
            state: item.admin1,
            district: item.admin2,
            country: item.country,
            source: 'open-meteo',
          }
          memoryCache.set(cacheKey, result)
          try {
            localStorage.setItem(cacheKey, JSON.stringify(result))
          } catch (_) {}
          return result
        }
      }
    }
  } catch (err) {
    // Failover
  }

  // 5. Query External Source 3: OpenStreetMap Nominatim
  try {
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1`
    const res = await fetch(url, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(4000),
    })
    if (res.ok) {
      const data = await res.json()
      if (Array.isArray(data) && data.length > 0) {
        const item = data[0]
        const lat = parseFloat(item.lat)
        const lon = parseFloat(item.lon)
        if (!isNaN(lat) && !isNaN(lon)) {
          const result: GeocodedLocation = {
            lat,
            lng: lon,
            displayName: item.display_name || query,
            source: 'nominatim',
          }
          memoryCache.set(cacheKey, result)
          try {
            localStorage.setItem(cacheKey, JSON.stringify(result))
          } catch (_) {}
          return result
        }
      }
    }
  } catch (_) {}

  // 6. Built-in Local Geographic Database Fallback (Instant & Offline resilient)
  const fallbackMatch = findLocalFallbackCoordinate(rawName, state)
  if (fallbackMatch) {
    memoryCache.set(cacheKey, fallbackMatch)
    return fallbackMatch
  }

  return null
}

/**
 * Searches external geocoding sources for multiple location suggestions
 */
export async function searchLocationsExternal(
  query: string,
  state?: string,
  country = 'India',
  limit = 5
): Promise<GeocodedLocation[]> {
  if (!query || query.trim().length < 2) return []

  const cleaned = cleanLocationQuery(query, state, country)
  const results: GeocodedLocation[] = []

  // 1. Photon Search
  try {
    const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(cleaned)}&limit=${limit}`
    const res = await fetch(url, { signal: AbortSignal.timeout(3500) })
    if (res.ok) {
      const data = await res.json()
      if (data.features && Array.isArray(data.features)) {
        for (const feature of data.features) {
          const [lon, lat] = feature.geometry.coordinates
          if (typeof lat === 'number' && typeof lon === 'number' && !isNaN(lat) && !isNaN(lon)) {
            const props = feature.properties || {}
            results.push({
              lat,
              lng: lon,
              displayName: [props.name, props.city || props.county, props.state, props.country].filter(Boolean).join(', ') || props.name || query,
              state: props.state,
              district: props.county || props.district,
              country: props.country,
              source: 'photon',
            })
          }
        }
      }
    }
  } catch (_) {}

  // 2. Fallback to Open-Meteo if Photon returned empty
  if (results.length === 0) {
    try {
      const simple = query.replace(/\b(taluk|hub|command|sector|logistics)\b/gi, '').trim().split(',')[0].trim()
      const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(simple)}&count=${limit}&language=en&format=json`
      const res = await fetch(url, { signal: AbortSignal.timeout(3500) })
      if (res.ok) {
        const data = await res.json()
        if (data.results && Array.isArray(data.results)) {
          for (const item of data.results) {
            results.push({
              lat: item.latitude,
              lng: item.longitude,
              displayName: [item.name, item.admin2, item.admin1, item.country].filter(Boolean).join(', '),
              state: item.admin1,
              district: item.admin2,
              country: item.country,
              source: 'open-meteo',
            })
          }
        }
      }
    } catch (_) {}
  }

  // 3. Fallback to local dictionary if still empty
  if (results.length === 0) {
    const local = findLocalFallbackCoordinate(query, state)
    if (local) results.push(local)
  }

  return results
}

const LOCAL_KNOWN_PLACES: Record<string, [number, number]> = {
  kadaba: [12.5700, 75.3200],
  puttur: [12.7749, 75.2023],
  mangaluru: [12.9141, 74.8560],
  mangalore: [12.9141, 74.8560],
  bantwal: [12.8943, 75.0352],
  belthangady: [13.0035, 75.2954],
  sullia: [12.5583, 75.3905],
  sulya: [12.5583, 75.3905],
  moodbidri: [13.0700, 74.9967],
  uppinangady: [12.8360, 75.2635],
  subrahmanya: [12.6631, 75.6179],
  kukke: [12.6631, 75.6179],
  alankar: [12.7214, 75.3852],
  bengaluru: [12.9716, 77.5946],
  bangalore: [12.9716, 77.5946],
  udupi: [13.3409, 74.7421],
  mysuru: [12.2958, 76.6394],
  mysore: [12.2958, 76.6394],
  hassan: [13.0072, 76.1011],
  coorg: [12.4244, 75.7382],
  madikeri: [12.4244, 75.7382],
  shivamogga: [13.9299, 75.5681],
  hubballi: [15.3647, 75.1240],
  mumbai: [19.0760, 72.8777],
  delhi: [28.6139, 77.2090],
  hyderabad: [17.3850, 78.4867],
  chennai: [13.0827, 80.2707],
}

function findLocalFallbackCoordinate(rawName: string, state?: string): GeocodedLocation | null {
  const norm = rawName.toLowerCase().replace(/[^a-z0-9]/g, ' ')
  for (const [key, [lat, lng]] of Object.entries(LOCAL_KNOWN_PLACES)) {
    if (norm.includes(key)) {
      const capKey = key.charAt(0).toUpperCase() + key.slice(1)
      return {
        lat,
        lng,
        displayName: `${capKey}, ${state || 'Karnataka'}, India`,
        state: state || 'Karnataka',
        country: 'India',
        source: 'fallback',
      }
    }
  }
  return null
}

/**
 * Reverse Geocodes coordinates to a human-readable location name via external sources
 */
export async function reverseGeocodeCoordinates(lat: number, lng: number): Promise<string | null> {
  if (lat === 0 && lng === 0) return null
  const cacheKey = `rev_${lat.toFixed(4)}_${lng.toFixed(4)}`

  try {
    const cached = localStorage.getItem(cacheKey)
    if (cached) return cached
  } catch (_) {}

  try {
    const url = `https://photon.komoot.io/reverse?lat=${lat}&lon=${lng}`
    const res = await fetch(url, { signal: AbortSignal.timeout(3500) })
    if (res.ok) {
      const data = await res.json()
      if (data.features && data.features.length > 0) {
        const props = data.features[0].properties || {}
        const name = [props.name, props.street, props.county || props.city, props.state].filter(Boolean).join(', ')
        if (name) {
          try {
            localStorage.setItem(cacheKey, name)
          } catch (_) {}
          return name
        }
      }
    }
  } catch (_) {}

  return null
}
