import { useEffect, useState, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ShoppingBag, Landmark, MapPin, Clock, Navigation, Send, X, User, ChevronRight, Search, Eye, Package, Route, Sparkles, Loader2, CheckCircle2 } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { useSocket } from '@/hooks/SocketContext'
import { resolveActiveRegion } from '@/data/regionsData'
import { isDriverInRegion } from '@/lib/regionMatcher'
import { geocodeLocationExternal } from '@/services/geocodingService'

interface OrderLocation {
  latitude: number
  longitude: number
  address: string
}

interface Order {
  id: string
  customerName: string
  items: string[]
  amount: number
  status: string
  deliveryFrom?: string
  deliveryLocation: OrderLocation
  driverId?: string
  driverName?: string
  createdAt: string
  updatedAt?: string
  safetyScore?: number
}

// Translate number to Indian Currency words (Rupees Only)
function numberToIndianRupeesWords(num: number): string {
  const a = ['', 'One ', 'Two ', 'Three ', 'Four ', 'Five ', 'Six ', 'Seven ', 'Eight ', 'Nine ', 'Ten ', 'Eleven ', 'Twelve ', 'Thirteen ', 'Fourteen ', 'Fifteen ', 'Sixteen ', 'Seventeen ', 'Eighteen ', 'Nineteen '];
  const b = ['', '', 'Twenty ', 'Thirty ', 'Forty ', 'Fifty ', 'Sixty ', 'Seventy ', 'Eighty ', 'Ninety '];

  if (num.toString().length > 9) return 'overflow';
  const padded = ('000000000' + num).substr(-9);
  const n = padded.match(/^(\d{2})(\d{2})(\d{2})(\d{1})(\d{2})$/);
  if (!n) return '';

  let str = '';
  str += (Number(n[1]) != 0) ? (a[Number(n[1])] || b[Number(n[1].substr(0, 1))] + a[Number(n[1].substr(1))]) + 'Crore ' : '';
  str += (Number(n[2]) != 0) ? (a[Number(n[2])] || b[Number(n[2].substr(0, 1))] + a[Number(n[2].substr(1))]) + 'Lakh ' : '';
  str += (Number(n[3]) != 0) ? (a[Number(n[3])] || b[Number(n[3].substr(0, 1))] + a[Number(n[3].substr(1))]) + 'Thousand ' : '';
  str += (Number(n[4]) != 0) ? (a[Number(n[4])] || b[Number(n[4].substr(0, 1))] + a[Number(n[4].substr(1))]) + 'Hundred ' : '';
  str += (Number(n[5]) != 0) ? ((str != '') ? 'and ' : '') + (a[Number(n[5])] || b[Number(n[5].substr(0, 1))] + a[Number(n[5].substr(1))]) + 'Rupees ' : 'Rupees ';

  return str + 'Only';
}

export default function Orders() {
  const { liveDrivers, emitAssignJob } = useSocket()
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [assigningOrderId, setAssigningOrderId] = useState<string | null>(null)
  const [inspectingOrder, setInspectingOrder] = useState<Order | null>(null)

  // Search and Filter State
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PENDING' | 'ASSIGNED' | 'COMPLETED'>('ALL')

  const activeRegion = useMemo(() => resolveActiveRegion(), [])

  // Assign Task Form State
  const [customerName, setCustomerName] = useState('')
  const [itemsText, setItemsText] = useState('')
  const [pickupAddress, setPickupAddress] = useState(() => `Main Logistics Hub, ${activeRegion.name}`)
  const [dropAddress, setDropAddress] = useState('')
  const [dropLat, setDropLat] = useState(() => (activeRegion.center[0] + 0.005).toFixed(4))
  const [dropLng, setDropLng] = useState(() => (activeRegion.center[1] + 0.006).toFixed(4))
  const [amount, setAmount] = useState('120')
  const [selectedDriverId, setSelectedDriverId] = useState('')
  const [isSubmittingTask, setIsSubmittingTask] = useState(false)
  const [showTaskForm, setShowTaskForm] = useState(true)
  const [isGeocoding, setIsGeocoding] = useState(false)
  const [geocodeStatus, setGeocodeStatus] = useState<string | null>(null)

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

  const fetchOrders = async () => {
    try {
      const host = window.location.hostname === 'localhost' ? 'localhost:3000' : `${window.location.hostname}:3000`;
      const res = await fetch(`http://${host}/api/v1/orders`)
      if (res.ok) {
        const result = await res.json()
        setOrders(result.data || [])
      }
    } catch (err) {
      console.error('Failed to fetch orders in dashboard:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchOrders()
    const interval = setInterval(fetchOrders, 4000)
    return () => clearInterval(interval)
  }, [])

  const handleAssign = async (order: Order, driverId: string, driverName: string) => {
    try {
      const host = window.location.hostname === 'localhost' ? 'localhost:3000' : `${window.location.hostname}:3000`;
      const res = await fetch(`http://${host}/api/v1/orders/${order.id}/assign`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ driverId, driverName })
      })

      if (res.ok) {
        setAssigningOrderId(null)
        if (inspectingOrder?.id === order.id) {
          setInspectingOrder(prev => prev ? { ...prev, status: 'ASSIGNED', driverId, driverName } : null)
        }
        fetchOrders()
        alert(`Dispatch confirmed for ${driverName}`)
      } else {
        alert('Failed to assign driver. Check server logs.')
      }
    } catch (err) {
      console.error('Assign error:', err)
      alert('Network error during assignment.')
    }
  }

  const handleCreateAndAssignTask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!customerName || !dropAddress) {
      alert('Please enter a Customer / Mission title and Delivery Address.')
      return
    }

    const availableDrivers = liveDrivers.filter(d => d.status !== 'offline')
    const targetDriver = liveDrivers.find(d => d.id === selectedDriverId || d.userId === selectedDriverId) || availableDrivers[0] || liveDrivers[0]
    const driverId = targetDriver ? (targetDriver.id || targetDriver.userId) : (selectedDriverId || 'mobile-driver')
    const driverName = targetDriver ? targetDriver.name : 'Field Operator'

    setIsSubmittingTask(true)
    try {
      const host = window.location.hostname === 'localhost' ? 'localhost:3000' : `${window.location.hostname}:3000`
      const orderPayload = {
        customerName,
        items: itemsText ? itemsText.split(',').map(s => s.trim()) : ['Tactical Dispatch Package'],
        amount: Number(amount) || 120,
        deliveryFrom: pickupAddress || 'Main Logistics Hub, Puttur',
        deliveryLocation: {
          latitude: parseFloat(dropLat) || 12.7850,
          longitude: parseFloat(dropLng) || 75.2150,
          address: dropAddress,
        }
      }

      const res = await fetch(`http://${host}/api/v1/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderPayload)
      })

      if (res.ok) {
        const orderData = await res.json()
        const newOrder = orderData.data

        // Assign to target driver
        await fetch(`http://${host}/api/v1/orders/${newOrder.id}/assign`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ driverId, driverName })
        })

        // Real-time socket notification to driver
        emitAssignJob(driverId || '', {
          orderId: newOrder.id,
          driverId,
          customerName,
          items: newOrder.items,
          amount: newOrder.amount,
          deliveryFrom: newOrder.deliveryFrom || pickupAddress,
          dropAddress,
          dropLat: parseFloat(dropLat) || 12.7850,
          dropLng: parseFloat(dropLng) || 75.2150,
        })

        setCustomerName('')
        setItemsText('')
        setDropAddress('')
        fetchOrders()
        alert(`✅ Mission Assigned & Dispatched to ${driverName}!`)
      }
    } catch (err) {
      console.error('Task dispatch error:', err)
      alert('Error creating and dispatching task.')
    } finally {
      setIsSubmittingTask(false)
    }
  }

  const filteredOrders = useMemo(() => {
    return orders.filter(o => {
      const matchesSearch =
        o.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (o.deliveryLocation?.address && o.deliveryLocation.address.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (o.driverName && o.driverName.toLowerCase().includes(searchQuery.toLowerCase()))

      const matchesStatus =
        statusFilter === 'ALL' ||
        (statusFilter === 'PENDING' && o.status === 'PENDING') ||
        (statusFilter === 'ASSIGNED' && (o.status === 'ASSIGNED' || o.status === 'ACCEPTED' || o.status === 'IN_TRANSIT')) ||
        (statusFilter === 'COMPLETED' && (o.status === 'DELIVERED' || o.status === 'COMPLETED'))

      return matchesSearch && matchesStatus
    })
  }, [orders, searchQuery, statusFilter])

  const totalValue = orders.reduce((sum, o) => sum + (o.amount || 0), 0)
  const totalValueWords = numberToIndianRupeesWords(totalValue)

  return (
    <div className="space-y-6 pb-12">
      <PageHeader
        title="Orders & Mission Dispatch Control"
        subtitle="Full lifecycle inspection, telemetry history, and real-time delivery task dispatch."
        actions={
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowTaskForm(!showTaskForm)}
              className="h-10 px-4 rounded-xl bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 text-xs font-bold hover:bg-cyan-500/20 transition flex items-center gap-2 cursor-pointer"
            >
              <Send size={14} />
              <span>{showTaskForm ? 'Hide Dispatch Form' : '+ New Mission Dispatch'}</span>
            </button>
          </div>
        }
      />

      {showTaskForm && (
        <GlassCard className="p-6 border border-cyan-500/30 bg-gradient-to-b from-cyan-950/20 to-slate-900/40">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-cyan-500/20 text-cyan-300 grid place-items-center">
                <Send size={16} />
              </div>
              <div>
                <h3 className="text-sm font-black text-white uppercase tracking-wider">Deploy New Delivery Task</h3>
                <p className="text-[11px] text-slate-400">Instantly generate customer orders and assign to active field drivers</p>
              </div>
            </div>
          </div>

          <form onSubmit={handleCreateAndAssignTask} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1.5">Customer / Title</label>
              <input
                type="text"
                value={customerName}
                onChange={e => setCustomerName(e.target.value)}
                placeholder="e.g. Anand Medicos, Court Road"
                required
                className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-white outline-none focus:border-cyan-400"
              />
            </div>

            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1.5">Items (Comma separated)</label>
              <input
                type="text"
                value={itemsText}
                onChange={e => setItemsText(e.target.value)}
                placeholder="e.g. Life Saving Meds, Insulated Box"
                className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-white outline-none focus:border-cyan-400"
              />
            </div>

            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1.5">Pickup Location</label>
              <input
                type="text"
                value={pickupAddress}
                onChange={e => setPickupAddress(e.target.value)}
                placeholder={`Main Logistics Hub, ${activeRegion.name}`}
                className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-white outline-none focus:border-cyan-400"
              />
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-[10px] font-black uppercase tracking-wider text-slate-400">Drop Destination Address</label>
                <button
                  type="button"
                  onClick={() => handleAutoGeocode()}
                  disabled={isGeocoding || !dropAddress}
                  className="text-[9px] font-black uppercase tracking-wider text-cyan-400 hover:text-cyan-300 flex items-center gap-1 cursor-pointer transition disabled:opacity-40"
                >
                  {isGeocoding ? (
                    <>
                      <Loader2 size={11} className="animate-spin" />
                      <span>Resolving Coords...</span>
                    </>
                  ) : (
                    <>
                      <Sparkles size={11} />
                      <span>Auto-Geocode</span>
                    </>
                  )}
                </button>
              </div>
              <input
                type="text"
                value={dropAddress}
                onChange={e => setDropAddress(e.target.value)}
                onBlur={() => { if (dropAddress && !dropLat) handleAutoGeocode() }}
                placeholder={`e.g. Sector 3, Kadaba, Puttur, or any address`}
                required
                className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-white outline-none focus:border-cyan-400"
              />
              {geocodeStatus && (
                <div className="mt-1 text-[10px] font-bold text-cyan-400 flex items-center gap-1 bg-cyan-500/10 border border-cyan-500/20 px-2 py-1 rounded-lg">
                  <CheckCircle2 size={12} className="flex-shrink-0" />
                  <span className="truncate">{geocodeStatus}</span>
                </div>
              )}
            </div>

            <div>
              <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1.5">Assigned Field Driver</label>
              <select
                value={selectedDriverId}
                onChange={e => setSelectedDriverId(e.target.value)}
                className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-white outline-none focus:border-cyan-400"
              >
                <option value="">Auto-Assign Closest Active Driver</option>
                {liveDrivers.filter(d => isDriverInRegion(d, activeRegion.id)).map(d => (
                  <option key={d.id} value={d.id} className="bg-slate-900 text-white">
                    {d.name} • {d.status.toUpperCase()} ({d.fleet || 'KA-19'})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-[10px] font-black uppercase tracking-wider text-slate-400">Target Latitude</label>
                <button type="button" onClick={() => { setDropLat(activeRegion.center[0].toFixed(4)); setDropLng(activeRegion.center[1].toFixed(4)); }} className="text-[9px] text-cyan-400 hover:underline font-bold">{activeRegion.name} Center</button>
              </div>
              <input type="text" value={dropLat} onChange={e => setDropLat(e.target.value)} placeholder={activeRegion.center[0].toFixed(4)} required className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-mono font-bold text-cyan-300 outline-none focus:border-cyan-400" />
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-[10px] font-black uppercase tracking-wider text-slate-400">Target Longitude</label>
                <button type="button" onClick={() => { setDropLat((activeRegion.center[0] - 0.008).toFixed(4)); setDropLng((activeRegion.center[1] + 0.012).toFixed(4)); }} className="text-[9px] text-cyan-400 hover:underline font-bold">Industrial Hub</button>
              </div>
              <input type="text" value={dropLng} onChange={e => setDropLng(e.target.value)} placeholder={activeRegion.center[1].toFixed(4)} required className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-mono font-bold text-cyan-300 outline-none focus:border-cyan-400" />
            </div>

            <div className="flex items-end gap-3">
              <div className="w-1/2">
                <label className="text-[10px] font-black uppercase tracking-wider text-slate-400 block mb-1.5">Payout (INR ₹)</label>
                <input type="number" value={amount} onChange={e => setAmount(e.target.value)} placeholder="120" className="w-full h-11 rounded-xl bg-slate-900/90 border border-slate-700 px-3.5 text-xs font-bold text-emerald-400 outline-none focus:border-cyan-400" />
              </div>
              <button
                type="submit"
                disabled={isSubmittingTask}
                className="w-1/2 h-11 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs uppercase tracking-wider transition-all flex items-center justify-center gap-2 shadow-lg shadow-cyan-500/20 cursor-pointer"
              >
                <Send size={14} />
                <span>{isSubmittingTask ? 'Dispatching...' : 'Dispatch'}</span>
              </button>
            </div>
          </form>
        </GlassCard>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <GlassCard className="flex items-center gap-4">
          <div className="grid place-items-center h-12 w-12 rounded-2xl bg-cyan-500/10 text-cyan-300">
            <ShoppingBag className="h-6 w-6" />
          </div>
          <div>
            <div className="text-[11px] text-muted uppercase tracking-wider font-semibold">Total Dispatched Parcels</div>
            <div className="text-2xl font-bold text-primary mt-0.5">{orders.length} Orders Recorded</div>
          </div>
        </GlassCard>

        <GlassCard className="flex items-center gap-4">
          <div className="grid place-items-center h-12 w-12 rounded-2xl bg-emerald-500/10 text-emerald-300">
            <Landmark className="h-6 w-6" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-[11px] text-muted uppercase tracking-wider font-semibold">Gross Order Value (INR)</div>
            <div className="text-2xl font-bold text-primary mt-0.5 truncate">₹{totalValue.toLocaleString('en-IN')}</div>
            <div className="text-[10px] text-emerald-400 font-medium truncate mt-0.5">{totalValueWords}</div>
          </div>
        </GlassCard>
      </div>

      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Search by customer, order ID, or address..."
            className="w-full h-10 pl-10 pr-4 rounded-xl bg-white/[0.03] border border-white/10 text-xs text-white placeholder-slate-500 outline-none focus:border-cyan-400/50"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
          {(['ALL', 'PENDING', 'ASSIGNED', 'COMPLETED'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setStatusFilter(tab)}
              className={`h-9 px-3.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 cursor-pointer ${
                statusFilter === tab
                  ? 'bg-cyan-500 text-slate-950 shadow-lg shadow-cyan-500/20'
                  : 'bg-white/[0.03] border border-white/8 text-slate-400 hover:text-white'
              }`}
            >
              <span>{tab}</span>
              <span className="text-[10px] opacity-75">
                ({tab === 'ALL'
                  ? orders.length
                  : orders.filter(o =>
                      tab === 'PENDING'
                        ? o.status === 'PENDING'
                        : tab === 'ASSIGNED'
                        ? (o.status === 'ASSIGNED' || o.status === 'ACCEPTED' || o.status === 'IN_TRANSIT')
                        : (o.status === 'DELIVERED' || o.status === 'COMPLETED')
                    ).length})
              </span>
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-xs uppercase font-bold text-muted tracking-wider">Orders History & Stream ({filteredOrders.length})</h3>
            <span className="text-[11px] text-cyan-400 font-medium">Click order card for complete history inspection</span>
          </div>

          {loading && orders.length === 0 ? (
            <div className="text-center py-12 text-muted text-[13px]">Fetching dispatches...</div>
          ) : filteredOrders.length === 0 ? (
            <div className="text-center py-12 text-muted text-[13px] bg-white/[0.01] rounded-2xl border border-white/5">No orders matched the filter.</div>
          ) : (
            filteredOrders.slice().reverse().map((o, idx) => (
              <motion.div key={o.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.02 }}>
                <GlassCard onClick={() => setInspectingOrder(o)} className="flex flex-col md:flex-row md:items-center justify-between gap-4 hover:border-cyan-500/40 cursor-pointer transition-all group">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-[13.5px] text-primary group-hover:text-cyan-300 transition">{o.customerName}</span>
                      <span className="text-[10px] font-mono text-slate-500">#{o.id.slice(0, 8)}</span>
                      {o.driverName && (
                        <span className="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-md font-semibold flex items-center gap-1">
                          <User size={10} /> {o.driverName}
                        </span>
                      )}
                    </div>
                    <div className="text-[11px] text-muted mt-1">Ordered: <span className="text-slate-300 font-medium">{o.items.join(', ')}</span></div>
                    <div className="text-[11.5px] text-cyan-400 font-bold mt-1">₹{o.amount.toLocaleString('en-IN')}</div>
                    <div className="text-[11px] text-muted flex items-center gap-1.5 mt-2">
                      <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                      <span className="truncate">{o.deliveryLocation?.address}</span>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 shrink-0">
                    <div className="flex flex-col items-end gap-1.5">
                      <div className="text-[10px] text-muted flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        {new Date(o.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                      <Badge tone={o.status === 'PENDING' ? 'warning' : 'safe'}>{o.status}</Badge>
                    </div>

                    <div className="flex items-center gap-2">
                      {o.status === 'PENDING' && (
                        <button
                          onClick={(e) => { e.stopPropagation(); setAssigningOrderId(o.id) }}
                          className="h-9 px-3.5 rounded-xl bg-cyan-500 text-black text-[11px] font-black uppercase tracking-wider hover:bg-cyan-400 transition-all flex items-center gap-1.5 shadow-md shadow-cyan-500/20"
                        >
                          <Send className="h-3 w-3" /> Dispatch
                        </button>
                      )}
                      <button onClick={(e) => { e.stopPropagation(); setInspectingOrder(o) }} className="h-9 px-3 rounded-xl bg-white/[0.04] hover:bg-white/10 text-slate-300 hover:text-white text-xs font-bold border border-white/10 transition flex items-center gap-1.5">
                        <Eye size={13} />
                        <span>Inspect</span>
                      </button>
                    </div>
                  </div>
                </GlassCard>
              </motion.div>
            ))
          )}
        </div>

        <div>
          <h3 className="text-xs uppercase font-bold text-muted tracking-wider mb-3">Active Geolocation Points</h3>
          <GlassCard className="space-y-4">
            {orders.length === 0 ? (
              <div className="text-center py-8 text-muted text-[12px]">Waiting for order dispatch coordinates...</div>
            ) : (
              orders.slice(-5).map((o) => (
                <div key={o.id} onClick={() => setInspectingOrder(o)} className="p-3 bg-white/[0.02] hover:bg-white/[0.05] border border-white/5 rounded-xl flex items-center gap-3 cursor-pointer transition">
                  <div className="grid place-items-center h-8 w-8 rounded-lg bg-cyan-500/10 text-cyan-300 shrink-0">
                    <Navigation className="h-4 w-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="text-[12px] font-bold text-primary truncate">{o.customerName}</div>
                    <div className="text-[10px] text-muted mt-0.5 truncate">{o.deliveryLocation?.address}</div>
                    <div className="text-[9px] text-cyan-300 font-mono mt-1">
                      Lat: {(o.deliveryLocation?.latitude ?? 12.7749).toFixed(4)} · Lng: {(o.deliveryLocation?.longitude ?? 75.2023).toFixed(4)}
                    </div>
                  </div>
                  <ChevronRight size={14} className="text-slate-600" />
                </div>
              ))
            )}
          </GlassCard>
        </div>
      </div>

      <AnimatePresence>
        {inspectingOrder && (
          <div className="fixed inset-0 z-[1000] flex items-center justify-center p-4 sm:p-6 bg-slate-950/85 backdrop-blur-md">
            <motion.div initial={{ opacity: 0, scale: 0.93, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.93, y: 20 }} className="bg-[#0A0D14] w-full max-w-2xl rounded-[32px] border border-white/10 shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
              <div className="p-6 border-b border-white/10 flex items-center justify-between bg-white/[0.02]">
                <div className="flex items-center gap-3">
                  <div className="h-11 w-11 rounded-2xl bg-cyan-500/10 text-cyan-400 grid place-items-center border border-cyan-500/20">
                    <Package size={22} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="text-lg font-black text-white uppercase">{inspectingOrder.customerName}</h3>
                      <Badge tone={inspectingOrder.status === 'PENDING' ? 'warning' : 'safe'}>{inspectingOrder.status}</Badge>
                    </div>
                    <p className="text-xs text-slate-400 font-mono mt-0.5">Order ID: #{inspectingOrder.id} • Created {new Date(inspectingOrder.createdAt).toLocaleString()}</p>
                  </div>
                </div>
                <button onClick={() => setInspectingOrder(null)} className="h-9 w-9 rounded-full bg-white/5 flex items-center justify-center text-slate-400 hover:text-white hover:bg-white/10 transition cursor-pointer">
                  <X size={18} />
                </button>
              </div>

              <div className="p-6 overflow-y-auto space-y-6 flex-1 no-scrollbar">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/5">
                    <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Mission Payout</div>
                    <div className="text-xl font-black text-emerald-400 mt-1">₹{inspectingOrder.amount}</div>
                    <div className="text-[10px] text-slate-500 mt-0.5">{numberToIndianRupeesWords(inspectingOrder.amount)}</div>
                  </div>
                  <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/5">
                    <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Items / Cargo</div>
                    <div className="text-sm font-bold text-white mt-1 line-clamp-2">{inspectingOrder.items.join(', ')}</div>
                    <div className="text-[10px] text-cyan-400 mt-0.5">{inspectingOrder.items.length} item(s) manifest</div>
                  </div>
                  <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/5">
                    <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Assigned Driver</div>
                    <div className="text-sm font-bold text-white mt-1 flex items-center gap-1.5">
                      <User size={13} className="text-cyan-400" />
                      <span>{inspectingOrder.driverName || 'Unassigned'}</span>
                    </div>
                    <div className="text-[10px] text-slate-500 mt-0.5 font-mono">{inspectingOrder.driverId || 'Pending Dispatch'}</div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-white/[0.02] border border-white/5 space-y-4">
                  <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
                    <Route size={14} className="text-cyan-400" />
                    <span>Route & Geographical Vector</span>
                  </h4>
                  <div className="space-y-3">
                    <div className="flex items-start gap-3">
                      <div className="h-7 w-7 rounded-lg bg-emerald-500/10 text-emerald-400 grid place-items-center shrink-0 mt-0.5"><MapPin size={14} /></div>
                      <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase">Pickup Depot</div>
                        <div className="text-xs font-semibold text-white mt-0.5">{inspectingOrder.deliveryFrom || 'Main Logistics Hub, Puttur'}</div>
                      </div>
                    </div>
                    <div className="flex items-start gap-3">
                      <div className="h-7 w-7 rounded-lg bg-rose-500/10 text-rose-400 grid place-items-center shrink-0 mt-0.5"><Navigation size={14} /></div>
                      <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase">Delivery Destination</div>
                        <div className="text-xs font-semibold text-white mt-0.5">{inspectingOrder.deliveryLocation?.address}</div>
                        <div className="text-[10px] font-mono text-cyan-400 mt-1">Latitude: {inspectingOrder.deliveryLocation?.latitude ?? 12.7850} • Longitude: {inspectingOrder.deliveryLocation?.longitude ?? 75.2150}</div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-white/[0.02] border border-white/5 space-y-4">
                  <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
                    <Clock size={14} className="text-purple-400" />
                    <span>Chronological Order History & Lifecycle</span>
                  </h4>
                  <div className="space-y-3 relative pl-4 before:absolute before:left-1 before:top-2 before:bottom-2 before:w-0.5 before:bg-white/10">
                    <div className="relative">
                      <div className="absolute -left-[19px] top-1 h-3 w-3 rounded-full bg-emerald-500 ring-4 ring-emerald-500/20" />
                      <div className="text-xs font-bold text-white">Order Created & Logged</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">{new Date(inspectingOrder.createdAt).toLocaleTimeString()} - Task manifested with ₹{inspectingOrder.amount} payout guarantee</div>
                    </div>
                    <div className="relative">
                      <div className={`absolute -left-[19px] top-1 h-3 w-3 rounded-full ${inspectingOrder.driverName ? 'bg-cyan-500 ring-4 ring-cyan-500/20' : 'bg-slate-600'}`} />
                      <div className="text-xs font-bold text-white">{inspectingOrder.driverName ? `Assigned to ${inspectingOrder.driverName}` : 'Driver Assignment Pending'}</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">{inspectingOrder.driverName ? `Dispatched via WebSocket to operator terminal #${inspectingOrder.driverId}` : 'Awaiting dispatch confirmation from control room'}</div>
                    </div>
                    <div className="relative">
                      <div className={`absolute -left-[19px] top-1 h-3 w-3 rounded-full ${inspectingOrder.status === 'COMPLETED' || inspectingOrder.status === 'DELIVERED' ? 'bg-emerald-500 ring-4 ring-emerald-500/20' : 'bg-slate-600'}`} />
                      <div className="text-xs font-bold text-white">{inspectingOrder.status === 'COMPLETED' || inspectingOrder.status === 'DELIVERED' ? 'Mission Completed & Verified' : 'In Transit / Telemetry Monitored'}</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">Real-time gyro and accelerometer safety audit active during corridor transit</div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="p-6 border-t border-white/10 flex items-center justify-between bg-white/[0.02]">
                <button onClick={() => setInspectingOrder(null)} className="px-5 h-11 rounded-xl bg-white/5 hover:bg-white/10 text-slate-300 hover:text-white text-xs font-bold transition cursor-pointer">Close Inspection</button>
                {inspectingOrder.status === 'PENDING' && (
                  <button onClick={() => setAssigningOrderId(inspectingOrder.id)} className="px-6 h-11 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 text-xs font-black uppercase tracking-wider transition flex items-center gap-2 shadow-lg shadow-cyan-500/20 cursor-pointer">
                    <Send size={14} />
                    <span>Assign Operator</span>
                  </button>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {assigningOrderId && (
          <div className="fixed inset-0 z-[1000] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-md">
            <motion.div initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} className="bg-[#0A0D14] w-full max-w-md rounded-[32px] border border-white/10 shadow-2xl overflow-hidden">
              <div className="p-6 border-b border-white/5 flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-black text-white uppercase italic">Assign Driver</h3>
                  <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mt-1">Select available personnel</p>
                </div>
                <button onClick={() => setAssigningOrderId(null)} className="h-8 w-8 rounded-full bg-white/5 flex items-center justify-center text-slate-400 hover:text-white transition-all"><X size={16} /></button>
              </div>

              <div className="p-4 max-h-[400px] overflow-y-auto space-y-2 no-scrollbar">
                {liveDrivers.filter(d => d.status !== 'offline').length === 0 ? (
                  <div className="text-center py-12 text-slate-500 text-[11px] font-bold uppercase tracking-widest">No online drivers found</div>
                ) : (
                  liveDrivers.filter(d => d.status !== 'offline').map(d => (
                    <button
                      key={d.id}
                      onClick={() => { const order = orders.find(ord => ord.id === assigningOrderId); if (order) handleAssign(order, d.id, d.name); }}
                      className="w-full p-4 rounded-2xl bg-white/[0.02] border border-white/5 flex items-center gap-4 hover:bg-white/5 hover:border-white/10 transition-all group cursor-pointer"
                    >
                      <div className="h-10 w-10 rounded-full bg-cyan-500/10 flex items-center justify-center text-cyan-400 shrink-0 group-hover:bg-cyan-500 group-hover:text-black transition-all"><User size={18} /></div>
                      <div className="text-left flex-1 min-w-0">
                        <div className="text-sm font-black text-white uppercase italic truncate">{d.name}</div>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge tone={d.status} className="text-[8px] px-2 py-0.5">{d.status}</Badge>
                          <span className="text-[10px] text-slate-500 font-bold">{d.safetyScore}% Score</span>
                        </div>
                      </div>
                      <ChevronRight className="h-4 w-4 text-slate-600 group-hover:text-cyan-400" />
                    </button>
                  ))
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  )
}
