import { useState } from 'react'
import { Bike, Car, Truck, Caravan } from 'lucide-react'
import type { VehicleType } from '@/types'

/**
 * Tesla-style vehicle presentation stage.
 * Drops in a real render PNG from /public/vehicles/{type}.png (transparent bg)
 * and falls back to a stylized glyph until you add your own renders.
 */
const GLYPH: Record<VehicleType, React.ElementType> = {
  scooter: Bike, motorcycle: Bike, car: Car, suv: Car, van: Caravan, truck: Truck, pickup: Truck,
}

export function VehicleRender({ type, name }: { type: VehicleType; name: string }) {
  const [imgOk, setImgOk] = useState(true)
  const Glyph = GLYPH[type]

  return (
    <div className="relative h-44 grid place-items-center overflow-hidden rounded-2xl">
      {/* ambient */}
      <div className="absolute inset-0 bg-[radial-gradient(120px_120px_at_50%_35%,rgba(34,211,238,0.16),transparent_70%)]" />
      {/* underglow */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 h-6 w-40 rounded-[100%] bg-cyan-400/30 blur-2xl animate-pulse-glow" />
      <div className="absolute bottom-9 left-1/2 -translate-x-1/2 h-1.5 w-28 rounded-[100%] bg-cyan-300/40 blur-md" />

      <div className="animate-float-slow relative z-10">
        {imgOk ? (
          <img
            src={`/vehicles/${type}.png`}
            alt={name}
            onError={() => setImgOk(false)}
            className="h-32 object-contain drop-shadow-[0_18px_25px_rgba(34,211,238,0.25)]"
          />
        ) : (
          <div className="grid place-items-center">
            <div className="grid place-items-center h-24 w-24 rounded-3xl bg-white/[0.03] border border-white/10 backdrop-blur">
              <Glyph className="h-12 w-12 text-cyan-300" strokeWidth={1.4} />
            </div>
            <span className="text-[10px] text-muted mt-2 tracking-wide">render · drop PNG in /public/vehicles/</span>
          </div>
        )}
      </div>
    </div>
  )
}
