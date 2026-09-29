import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Shield, X, MapPin, Gauge, CircleDot, CheckCircle2, School, ShoppingBag, HeartPulse, CornerUpRight, Construction } from 'lucide-react'
import { GeofenceZone, GEOFENCE_PRESETS } from '@/types/geofence'
import { cn } from '@/lib/utils'

interface GeofenceModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (zone: Omit<GeofenceZone, 'id' | 'createdAt'>) => void
  initialCoords?: [number, number]
  activeRegionId?: string
}

export function GeofenceModal({
  isOpen,
  onClose,
  onSave,
  initialCoords = [12.7749, 75.2023],
  activeRegionId = 'puttur_taluk'
}: GeofenceModalProps) {
  const [selectedType, setSelectedType] = useState<GeofenceZone['type']>('school')
  const [name, setName] = useState('New Safety Speed Restriction Zone')
  const [speedLimit, setSpeedLimit] = useState(25)
  const [radiusMeters, setRadiusMeters] = useState(250)
  const [lat, setLat] = useState(initialCoords[0])
  const [lng, setLng] = useState(initialCoords[1])
  const [color, setColor] = useState('#38bdf8')

  if (!isOpen) return null

  const handleSelectPreset = (preset: typeof GEOFENCE_PRESETS[0]) => {
    setSelectedType(preset.type)
    setName(`${preset.label}`)
    setSpeedLimit(preset.defaultSpeedLimit)
    setRadiusMeters(preset.defaultRadius)
    setColor(preset.color)
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return

    onSave({
      name: name.trim(),
      type: selectedType,
      centerLat: Number(lat),
      centerLng: Number(lng),
      radiusMeters: Number(radiusMeters),
      speedLimitKph: Number(speedLimit),
      color,
      regionId: activeRegionId,
    })
    onClose()
  }

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[99999] flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-200">
        <motion.div
          initial={{ scale: 0.94, opacity: 0, y: 15 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.94, opacity: 0, y: 15 }}
          className="relative w-full max-w-xl rounded-3xl bg-slate-900 border border-slate-700/80 shadow-2xl p-6 sm:p-8 text-white overflow-hidden max-h-[90vh] overflow-y-auto"
        >
          {/* Neon Header Aura */}
          <div className="absolute top-0 right-0 w-60 h-60 bg-blue-500/10 blur-3xl pointer-events-none -mr-20 -mt-20" />

          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-6 right-6 p-2 rounded-xl bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition cursor-pointer"
          >
            <X size={18} />
          </button>

          {/* Modal Header */}
          <div className="flex items-center gap-3.5 mb-6">
            <div className="h-12 w-12 rounded-2xl bg-blue-500/10 border border-blue-500/30 flex items-center justify-center text-blue-400 shadow-inner shrink-0">
              <Shield size={24} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-blue-400 animate-ping" />
                <span className="text-[10px] font-black uppercase tracking-widest text-blue-400">
                  GEOSPATIAL POLICY // DYNAMIC GEOFENCING
                </span>
              </div>
              <h2 className="text-xl font-black uppercase tracking-tight text-white mt-0.5">
                Create Speed Restriction Geofence
              </h2>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Zone Type Presets */}
            <div>
              <label className="block text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400 mb-2">
                Select Safety Zone Type:
              </label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {GEOFENCE_PRESETS.map((p) => {
                  return (
                    <button
                      key={p.type}
                      type="button"
                      onClick={() => handleSelectPreset(p)}
                      className={cn(
                        "p-2.5 rounded-xl border text-left transition-all cursor-pointer flex items-center gap-2",
                        selectedType === p.type
                          ? "bg-slate-800 border-white/40 shadow-md text-white"
                          : "bg-slate-950/60 border-slate-800 text-slate-400 hover:border-slate-700"
                      )}
                    >
                      <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: p.color }} />
                      <span className="text-[11px] font-bold truncate">{p.label.split('/')[0]}</span>
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Zone Name */}
            <div>
              <label className="block text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400 mb-1.5">
                Geofence Zone Identifier:
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. St. Philomena Campus Safety Zone"
                className="w-full px-4 py-2.5 rounded-xl bg-slate-950/80 border border-slate-800 text-xs font-bold text-white placeholder:text-slate-600 outline-none focus:border-blue-500 transition-all"
                required
              />
            </div>

            {/* Speed Limit & Radius Row */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <div className="flex justify-between items-center mb-1.5">
                  <label className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400 flex items-center gap-1">
                    <Gauge size={13} className="text-amber-400" />
                    <span>Speed Ceiling:</span>
                  </label>
                  <span className="text-xs font-black text-amber-400 font-mono">
                    {speedLimit} KM/H
                  </span>
                </div>
                <input
                  type="range"
                  min={15}
                  max={80}
                  step={5}
                  value={speedLimit}
                  onChange={(e) => setSpeedLimit(Number(e.target.value))}
                  className="w-full accent-amber-400 cursor-pointer"
                />
              </div>

              <div>
                <div className="flex justify-between items-center mb-1.5">
                  <label className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400 flex items-center gap-1">
                    <CircleDot size={13} className="text-blue-400" />
                    <span>Radius Buffer:</span>
                  </label>
                  <span className="text-xs font-black text-blue-400 font-mono">
                    {radiusMeters} METERS
                  </span>
                </div>
                <input
                  type="range"
                  min={50}
                  max={800}
                  step={25}
                  value={radiusMeters}
                  onChange={(e) => setRadiusMeters(Number(e.target.value))}
                  className="w-full accent-blue-400 cursor-pointer"
                />
              </div>
            </div>

            {/* Coordinates Row */}
            <div className="p-3.5 rounded-2xl bg-slate-950/60 border border-slate-800">
              <span className="text-[9px] font-mono font-black uppercase text-slate-400 tracking-wider flex items-center gap-1 mb-2">
                <MapPin size={12} className="text-emerald-400" />
                <span>Geographical Anchor Coordinates</span>
              </span>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[9px] font-mono text-slate-500 uppercase">Latitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={lat}
                    onChange={(e) => setLat(Number(e.target.value))}
                    className="w-full px-2.5 py-1.5 rounded-lg bg-slate-900 border border-slate-800 text-xs font-mono text-white outline-none focus:border-blue-400"
                  />
                </div>
                <div>
                  <label className="text-[9px] font-mono text-slate-500 uppercase">Longitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={lng}
                    onChange={(e) => setLng(Number(e.target.value))}
                    className="w-full px-2.5 py-1.5 rounded-lg bg-slate-900 border border-slate-800 text-xs font-mono text-white outline-none focus:border-blue-400"
                  />
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold text-xs uppercase tracking-wider transition cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-cyan-400 hover:from-blue-400 hover:to-cyan-300 text-slate-950 font-black text-xs uppercase tracking-widest shadow-xl shadow-blue-500/20 active:scale-95 transition-all cursor-pointer flex items-center gap-2"
              >
                <CheckCircle2 size={16} />
                <span>Deploy Geofence</span>
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}
