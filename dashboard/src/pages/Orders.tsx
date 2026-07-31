import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { ShoppingBag, Landmark, MapPin, Clock, Navigation } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'

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
  deliveryLocation: OrderLocation
  createdAt: string
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
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)

  const fetchOrders = async () => {
    try {
      const res = await fetch('http://localhost:3000/api/v1/orders')
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

  const totalValue = orders.reduce((sum, o) => sum + o.amount, 0)
  const totalValueWords = numberToIndianRupeesWords(totalValue)

  return (
    <div>
      <PageHeader
        title="Swadeshi Dispatch Orders"
        subtitle="Indian Depot Delivery tracking log and active geocoding."
        actions={
          <div className="flex items-center gap-3">
            <Badge tone="cyan">{orders.length} Dispatched</Badge>
          </div>
        }
      />

      {/* Analytics Panel */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <GlassCard className="flex items-center gap-4">
          <div className="grid place-items-center h-12 w-12 rounded-2xl bg-cyan-500/10 text-cyan-300">
            <ShoppingBag className="h-6 w-6" />
          </div>
          <div>
            <div className="text-[11px] text-muted uppercase tracking-wider font-semibold">Total Dispatched Parcels</div>
            <div className="text-2xl font-bold text-primary mt-0.5">{orders.length} Orders</div>
          </div>
        </GlassCard>

        <GlassCard className="flex items-center gap-4">
          <div className="grid place-items-center h-12 w-12 rounded-2xl bg-emerald-500/10 text-emerald-300">
            <Landmark className="h-6 w-6" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-[11px] text-muted uppercase tracking-wider font-semibold">Gross Order Value (INR)</div>
            <div className="text-2xl font-bold text-primary mt-0.5 truncate">
              ₹{totalValue.toLocaleString('en-IN')}
            </div>
            <div className="text-[10px] text-emerald-400 font-medium truncate mt-0.5">
              {totalValueWords}
            </div>
          </div>
        </GlassCard>
      </div>

      {/* Orders List & Active Geocode Map */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Placed Orders List */}
        <div className="lg:col-span-2 space-y-3">
          <h3 className="text-xs uppercase font-bold text-muted tracking-wider mb-2">Live Order Stream</h3>
          
          {loading && orders.length === 0 ? (
            <div className="text-center py-12 text-muted text-[13px]">Fetching active dispatches...</div>
          ) : orders.length === 0 ? (
            <div className="text-center py-12 text-muted text-[13px]">No Swadeshi orders recorded yet. Dispatches placed via the ordering app will appear here.</div>
          ) : (
            orders.slice().reverse().map((o, idx) => (
              <motion.div key={o.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.02 }}>
                <GlassCard className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-[13px] text-primary">{o.customerName}</span>
                      <span className="text-[10px] text-muted">Ordered {o.items.join(', ')}</span>
                    </div>
                    <div className="text-[11px] text-cyan-400 font-bold mt-1">
                      ₹{o.amount.toLocaleString('en-IN')} ({numberToIndianRupeesWords(o.amount)})
                    </div>
                    <div className="text-[11px] text-muted flex items-center gap-1.5 mt-2">
                      <MapPin className="h-3 w-3 shrink-0" />
                      <span>{o.deliveryLocation.address}</span>
                    </div>
                  </div>

                  <div className="flex flex-col items-end gap-2 shrink-0">
                    <div className="text-[10px] text-muted flex items-center gap-1">
                      <Clock className="h-2.5 w-2.5" />
                      {new Date(o.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                    <Badge tone={o.status === 'PENDING' ? 'warning' : 'safe'}>{o.status}</Badge>
                  </div>
                </GlassCard>
              </motion.div>
            ))
          )}
        </div>

        {/* Telemetry Tracking Geolocation */}
        <div>
          <h3 className="text-xs uppercase font-bold text-muted tracking-wider mb-3">Active Geolocation Points</h3>
          <GlassCard className="space-y-4">
            {orders.length === 0 ? (
              <div className="text-center py-8 text-muted text-[12px]">Waiting for order dispatch coordinates...</div>
            ) : (
              orders.slice(-4).map((o) => (
                <div key={o.id} className="p-3 bg-white/[0.02] border border-white/5 rounded-xl flex items-center gap-3">
                  <div className="grid place-items-center h-8 w-8 rounded-lg bg-cyan-500/10 text-cyan-300 shrink-0">
                    <Navigation className="h-4 w-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="text-[12px] font-bold text-primary truncate">{o.customerName}</div>
                    <div className="text-[10px] text-muted mt-0.5 truncate">{o.deliveryLocation.address}</div>
                    <div className="text-[9px] text-cyan-300 font-mono mt-1">
                      Lat: {o.deliveryLocation.latitude.toFixed(4)} · Lng: {o.deliveryLocation.longitude.toFixed(4)}
                    </div>
                  </div>
                </div>
              ))
            )}
          </GlassCard>
        </div>
      </div>
    </div>
  )
}
