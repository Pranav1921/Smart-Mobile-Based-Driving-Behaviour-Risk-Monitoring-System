import React, { useState, useMemo, useEffect } from 'react'
import { Send, MapPin, X, Package, User, DollarSign, Navigation, Sparkles, Loader2, CheckCircle2 } from 'lucide-react'
import type { Driver } from '@/types'
import { useSocket } from '@/hooks/SocketContext'
import { resolveActiveRegion, type RegionOption } from '@/data/regionsData'
import { geocodeLocationExternal } from '@/services/geocodingService'

interface DispatchOrderModalProps {
  isOpen: boolean
  onClose: () => void
  drivers: Driver[]
  selectedDriverId?: string | null
}

export function DispatchOrderModal({ isOpen, onClose, drivers, selectedDriverId }: DispatchOrderModalProps) {
  const activeRegion = useMemo(() => resolveActiveRegion(), [])
  const { emitAssignJob } = useSocket()
  const [targetDriverId, setTargetDriverId] = useState<string>(selectedDriverId || '')
  const [customerName, setCustomerName] = useState('')
  const [itemsText, setItemsText] = useState('')
  const [amount, setAmount] = useState('120')
  const [pickupAddress, setPickupAddress] = useState(`Main Dispatch Hub, ${activeRegion.name}`)
  const [dropAddress, setDropAddress] = useState('')
  const [dropLat, setDropLat] = useState((activeRegion.center[0] + 0.006).toFixed(4))
  const [dropLng, setDropLng] = useState((activeRegion.center[1] + 0.007).toFixed(4))
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isGeocoding, setIsGeocoding] = useState(false)
  const [geocodeStatus, setGeocodeStatus] = useState<string | null>(null)

  useEffect(() => {
    const handleCoordDispatch = (e: any) => {
      const detail = e.detail
      if (detail) {
        if (detail.address) setDropAddress(detail.address)
        if (detail.lat != null) setDropLat(Number(detail.lat).toFixed(4))
        if (detail.lng != null) setDropLng(Number(detail.lng).toFixed(4))
        if (detail.name) setCustomerName(`Mission: ${detail.name}`)
        setGeocodeStatus(`✓ External Coordinates Populated: ${Number(detail.lat).toFixed(4)}, ${Number(detail.lng).toFixed(4)}`)
      }
    }
    window.addEventListener('smartdrive_dispatch_to_coords', handleCoordDispatch)
    return () => window.removeEventListener('smartdrive_dispatch_to_coords', handleCoordDispatch)
  }, [])

  const handleAutoGeocode = async (customAddress?: string) => {
    const target = customAddress || dropAddress
    if (!target || target.trim().length < 2) return
    setIsGeocoding(true)
    setGeocodeStatus(null)
    try {
      const res = await geocodeLocationExternal(target, activeRegion.name, 'India')
      if (res) {
        setDropLat(res.lat.toFixed(4))
        setDropLng(res.lng.toFixed(4))
        setGeocodeStatus(`✓ Resolved via ${res.source.toUpperCase()}: ${res.lat.toFixed(4)}, ${res.lng.toFixed(4)}`)
      } else {
        setGeocodeStatus(`⚠️ Could not resolve coordinate externally.`)
      }
    } catch (_) {
      setGeocodeStatus(`⚠️ Lookup failed.`)
    } finally {
      setIsGeocoding(false)
    }
  }

  const dynamicPresets = useMemo(() => [
    { name: `${activeRegion.name} Commercial Center`, lat: +(activeRegion.center[0] + 0.006).toFixed(4), lng: +(activeRegion.center[1] + 0.007).toFixed(4) },
    { name: `${activeRegion.name} Industrial Logistics Sector`, lat: +(activeRegion.center[0] - 0.008).toFixed(4), lng: +(activeRegion.center[1] + 0.012).toFixed(4) },
    { name: `${activeRegion.name} Transit Junction`, lat: +(activeRegion.center[0] + 0.011).toFixed(4), lng: +(activeRegion.center[1] - 0.009).toFixed(4) },
    { name: `${activeRegion.district || activeRegion.name} Central Depot`, lat: +(activeRegion.center[0] - 0.005).toFixed(4), lng: +(activeRegion.center[1] - 0.006).toFixed(4) },
  ], [activeRegion])

  if (!isOpen) return null

  const handleSelectPreset = (preset: { name: string; lat: number; lng: number }) => {
    setDropAddress(preset.name)
    setDropLat(preset.lat.toString())
    setDropLng(preset.lng.toString())
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!customerName || !dropAddress) {
      alert('Please specify Customer / Mission Title and Destination Address.')
      return
    }

    const availableDrivers = drivers.filter(d => d.status !== 'offline')
    const targetDriver = drivers.find(d => d.id === targetDriverId) || availableDrivers[0] || drivers[0]
    const finalDriverId = targetDriver ? targetDriver.id : (targetDriverId || 'mobile-driver')
    const finalDriverName = targetDriver ? targetDriver.name : 'Field Operator'

    setIsSubmitting(true)
    try {
      const host = window.location.hostname === 'localhost' ? 'localhost:3000' : `${window.location.hostname}:3000`
      const orderPayload = {
        customerName,
        items: itemsText ? itemsText.split(',').map(s => s.trim()) : ['Tactical Express Package'],
        amount: Number(amount) || 120,
        deliveryFrom: pickupAddress || 'Main Dispatch Hub, Puttur',
        deliveryLocation: {
          latitude: parseFloat(dropLat) || 12.7850,
          longitude: parseFloat(dropLng) || 75.2150,
          address: dropAddress,
        },
      }

      const res = await fetch(`http://${host}/api/v1/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderPayload),
      })

      if (res.ok) {
        const orderData = await res.json()
        const newOrder = orderData.data

        // Assign to driver
        await fetch(`http://${host}/api/v1/orders/${newOrder.id}/assign`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ driverId: finalDriverId, driverName: finalDriverName }),
        })

        // Real-time socket notification directly to driver's room
        emitAssignJob(finalDriverId, {
          orderId: newOrder.id,
          customerName,
          items: orderPayload.items,
          amount: orderPayload.amount,
          deliveryFrom: orderPayload.deliveryFrom,
          deliveryTo: dropAddress,
          deliveryLocation: orderPayload.deliveryLocation,
          distanceKm: 5.4,
          estimatedTimeMinutes: 18,
        })

        alert(`🚀 Order Dispatched Successfully to ${finalDriverName}!\nTarget: ${dropAddress}`)
        onClose()
      } else {
        alert('Failed to save order on backend.')
      }
    } catch (err) {
      console.error('Dispatch error:', err)
      alert('Error creating and dispatching mission.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[600] flex items-center justify-center p-4 bg-black/75 backdrop-blur-md">
      <div className="w-full max-w-xl bg-slate-950 border border-emerald-500/40 rounded-3xl p-6 shadow-2xl relative overflow-hidden text-white">
        {/* Glow Accent */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-emerald-500/10 blur-3xl -mr-20 -mt-20 pointer-events-none" />

        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-2xl bg-emerald-500/15 border border-emerald-500/40 flex items-center justify-center text-emerald-400">
              <Send size={18} />
            </div>
            <div>
              <h2 className="text-base font-black text-white uppercase italic tracking-wide">Tactical Mission Dispatcher</h2>
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-0.5">Assign order directly to driver with live route tracking</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="h-8 w-8 rounded-xl bg-slate-800 hover:bg-slate-700 grid place-items-center text-slate-400 hover:text-white transition cursor-pointer"
          >
            <X size={16} />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="mt-5 space-y-4">
          {/* Driver Selection */}
          <div>
            <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1">
              Select Field Operator / Driver
            </label>
            <select
              value={targetDriverId}
              onChange={(e) => setTargetDriverId(e.target.value)}
              className="w-full h-11 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-bold text-white outline-none focus:border-emerald-400 cursor-pointer"
            >
              <option value="">Auto-Assign to Best Available Driver</option>
              {drivers.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name} · {d.status.toUpperCase()} ({d.fleet || 'Smart Fleet Tactical'})
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {/* Customer Title */}
            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1">
                Customer / Consignment Title
              </label>
              <input
                type="text"
                required
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                placeholder="e.g. Apollo Pharma Express"
                className="w-full h-11 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-bold text-white outline-none focus:border-emerald-400 placeholder:text-slate-600"
              />
            </div>

            {/* Payout */}
            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1">
                Payout Reward (₹)
              </label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="120"
                className="w-full h-11 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-bold text-white outline-none focus:border-emerald-400 placeholder:text-slate-600"
              />
            </div>
          </div>

          {/* Quick Preset Selector */}
          <div>
            <div className="flex items-center gap-1 text-[10px] font-black uppercase tracking-wider text-slate-400 mb-1.5">
              <Sparkles size={12} className="text-emerald-400" />
              <span>Quick Destination Presets</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {dynamicPresets.map((preset) => (
                <button
                  type="button"
                  key={preset.name}
                  onClick={() => handleSelectPreset(preset)}
                  className="text-[9px] font-bold px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 hover:border-emerald-500 hover:text-emerald-400 transition cursor-pointer"
                >
                  {preset.name.split(',')[0]}
                </button>
              ))}
            </div>
          </div>

          {/* Destination Address */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400">
                Destination Delivery Address
              </label>
              <button
                type="button"
                onClick={() => handleAutoGeocode()}
                disabled={isGeocoding || !dropAddress}
                className="text-[9px] font-black uppercase tracking-wider text-amber-400 hover:text-amber-300 flex items-center gap-1 cursor-pointer transition disabled:opacity-40"
              >
                {isGeocoding ? (
                  <>
                    <Loader2 size={11} className="animate-spin" />
                    <span>Resolving External Coords...</span>
                  </>
                ) : (
                  <>
                    <Sparkles size={11} />
                    <span>Auto-Geocode Coordinates</span>
                  </>
                )}
              </button>
            </div>
            <input
              type="text"
              required
              value={dropAddress}
              onChange={(e) => setDropAddress(e.target.value)}
              onBlur={() => { if (dropAddress && !dropLat) handleAutoGeocode() }}
              placeholder={`e.g. Sector 3, Kadaba, Puttur, or any address`}
              className="w-full h-11 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-bold text-white outline-none focus:border-emerald-400 placeholder:text-slate-600"
            />
            {geocodeStatus && (
              <div className="mt-1 text-[10px] font-bold text-emerald-400 flex items-center gap-1 bg-emerald-500/10 border border-emerald-500/20 px-2 py-1 rounded-lg">
                <CheckCircle2 size={12} className="flex-shrink-0" />
                <span className="truncate">{geocodeStatus}</span>
              </div>
            )}
          </div>

          {/* Lat & Lng */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1">
                Drop Latitude (External)
              </label>
              <input
                type="text"
                value={dropLat}
                onChange={(e) => setDropLat(e.target.value)}
                className="w-full h-10 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-mono text-emerald-400 outline-none focus:border-emerald-400"
              />
            </div>
            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1">
                Drop Longitude (External)
              </label>
              <input
                type="text"
                value={dropLng}
                onChange={(e) => setDropLng(e.target.value)}
                className="w-full h-10 rounded-xl bg-slate-900 border border-slate-700 px-3 text-xs font-mono text-emerald-400 outline-none focus:border-emerald-400"
              />
            </div>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full h-12 mt-2 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-xs uppercase tracking-widest transition flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/20 cursor-pointer disabled:opacity-50"
          >
            <Send size={15} />
            <span>{isSubmitting ? 'DISPATCHING MISSION...' : 'DISPATCH REAL-TIME MISSION'}</span>
          </button>
        </form>
      </div>
    </div>
  )
}
