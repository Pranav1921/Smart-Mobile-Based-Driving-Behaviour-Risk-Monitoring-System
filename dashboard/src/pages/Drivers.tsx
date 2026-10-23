import { useMemo, useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Search, 
  ArrowUpDown, 
  ChevronRight, 
  Shield, 
  ShieldAlert, 
  Trash2, 
  Truck, 
  UserPlus, 
  Users, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Mail, 
  Phone, 
  MapPin, 
  Car, 
  Send, 
  RefreshCw,
  FileCheck,
  Radio,
  ExternalLink,
  Sparkles,
  Navigation,
  Pencil
} from 'lucide-react'
import { isDriverInRegion, getActiveAdminRegionId } from '@/lib/regionMatcher'
import { VehicleSymbol } from '@/components/ui/VehicleSymbol'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { Sparkline } from '@/components/charts/Charts'
import { seeded, cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'
import { DriverDetailModal } from '@/components/drivers/DriverDetailModal'
import { DriverVerificationModal } from '@/components/drivers/DriverVerificationModal'
import { EditDriverModal } from '@/components/drivers/EditDriverModal'
import { PartnershipRelayModal } from '@/components/map/PartnershipRelayModal'
import { Driver } from '@/types'
import { 
  deleteDriverFromApi, 
  fetchDriversFromApi,
  fetchPendingDrivers, 
  approveDriverApplication, 
  rejectDriverApplication 
} from '@/lib/apiClient'

const STATUS_LABEL: Record<string, string> = {
  safe: 'SECURE', warning: 'WARNING', emergency: 'SOS ALERT', idle: 'STANDBY', offline: 'OFFLINE'
}

const REGIONS_LIST = [
  { label: 'All Regions (National)', value: 'all' },
  { label: 'Karnataka (All Districts)', value: 'Karnataka' },
  { label: 'Dakshina Kannada (Puttur / Mangaluru / Kadaba)', value: 'Dakshina Kannada' },
  { label: 'Kadaba Hub', value: 'Kadaba' },
  { label: 'Puttur Hub', value: 'Puttur' },
  { label: 'Mangaluru City', value: 'Mangaluru' },
  { label: 'Udupi Hub', value: 'Udupi' },
  { label: 'Bengaluru Urban', value: 'Bengaluru Urban' },
  { label: 'Bengaluru Rural', value: 'Bengaluru Rural' },
  { label: 'Mysuru Hub', value: 'Mysuru' },
  { label: 'Maharashtra (Mumbai / Pune)', value: 'Maharashtra' },
  { label: 'Mumbai City', value: 'Mumbai' },
  { label: 'Pune Hub', value: 'Pune' },
  { label: 'Tamil Nadu (Chennai / Coimbatore)', value: 'Tamil Nadu' },
  { label: 'Chennai Central', value: 'Chennai' },
  { label: 'Kerala (Kochi / Kasaragod)', value: 'Kerala' },
  { label: 'Ernakulam (Kochi)', value: 'Ernakulam' },
  { label: 'Kasaragod Hub', value: 'Kasaragod' },
  { label: 'Telangana (Hyderabad)', value: 'Telangana' },
  { label: 'Andhra Pradesh (Vizag / Vijayawada)', value: 'Andhra Pradesh' },
  { label: 'Delhi NCR', value: 'Delhi' },
  { label: 'Gujarat (Ahmedabad / Surat)', value: 'Gujarat' },
];

export default function Drivers() {
  const navigate = useNavigate()
  const socket = useSocket()
  const liveDrivers = socket?.liveDrivers || []
  const [activeTab, setActiveTab] = useState<'active' | 'pending'>('active')
  const [selectedRegion, setSelectedRegion] = useState<string>(() => {
    const adminReg = getActiveAdminRegionId()
    return adminReg && adminReg !== 'super_admin' && adminReg !== 'global' ? adminReg : 'all'
  })
  const [q, setQ] = useState('')
  const [sortKey, setSortKey] = useState<'safetyScore' | 'trips' | 'distanceToday'>('safetyScore')
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null)
  const [editingDriver, setEditingDriver] = useState<Driver | null>(null)
  const [relayModalDriver, setRelayModalDriver] = useState<Driver | null>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [deleteConfirmTarget, setDeleteConfirmTarget] = useState<Driver | null>(null)
  const [deleteSuccessToast, setDeleteSuccessToast] = useState<string | null>(null)
  const [isVerificationOpen, setIsVerificationOpen] = useState(false)
  const [apiDrivers, setApiDrivers] = useState<Driver[]>([])
  const [assignedOrders, setAssignedOrders] = useState<any[]>([])

  const loadAssignedOrders = async () => {
    try {
      const host = window.location.hostname === 'localhost' ? 'localhost:3000' : `${window.location.hostname}:3000`;
      const res = await fetch(`http://${host}/api/v1/orders`);
      if (res.ok) {
        const json = await res.json();
        setAssignedOrders(json.data || []);
      }
    } catch (_) {}
  };
  
  // Pending Employee Requests state
  const [pendingDrivers, setPendingDrivers] = useState<any[]>([])
  const [pendingLoading, setPendingLoading] = useState(false)
  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [approvalAlert, setApprovalAlert] = useState<{ name: string; email: string; driverCode: string; tempPassword: string } | null>(null)

  const { toggleDriverAvailability, toggleDriverDeadZone, sameDirectionSummary } = socket;

  const handleToggleAvailability = (e: React.MouseEvent, driverId: string, current: boolean) => {
    e.stopPropagation()
    toggleDriverAvailability(driverId, !current)
  }

  const handleToggleDeadZone = (e: React.MouseEvent, driverId: string, current: boolean) => {
    e.stopPropagation()
    toggleDriverDeadZone(driverId, !current)
  }

  const loadApiDrivers = async (region?: string) => {
    try {
      const list = await fetchDriversFromApi(region !== 'all' ? region : undefined)
      if (Array.isArray(list)) {
        setApiDrivers(list)
      }
    } catch (err) {
      console.error('[Drivers] Failed to fetch drivers from DB:', err)
    }
  }

  const refreshPending = async (region?: string) => {
    setPendingLoading(true)
    const targetRegion = region !== undefined ? region : selectedRegion
    try {
      const data = await fetchPendingDrivers(targetRegion !== 'all' ? targetRegion : 'all')
      setPendingDrivers(data)
    } catch (_) {}
    finally {
      setPendingLoading(false)
    }
  }

  useEffect(() => {
    loadApiDrivers(selectedRegion)
    refreshPending(selectedRegion)
    loadAssignedOrders()
    const interval = setInterval(() => {
      refreshPending(selectedRegion)
      loadAssignedOrders()
    }, 4000)
    return () => clearInterval(interval)
  }, [selectedRegion])

  const rows = useMemo(() => {
    // 1. Gather all drivers from database first
    const initialMap = new Map<string, Driver>();

    (apiDrivers || []).forEach((d) => {
      if (d && isDriverInRegion(d, selectedRegion)) {
        initialMap.set(d.id, d)
      }
    });

    // 2. Merge with live socket telemetry
    (liveDrivers || []).forEach((d) => {
      if (d && isDriverInRegion(d, selectedRegion)) {
        const existing = initialMap.get(d.id)
        initialMap.set(d.id, existing ? { ...existing, ...d } : d)
      }
    });

    // 3. Merge with assigned orders from backend
    (assignedOrders || []).forEach((o: any) => {
      if (o.status !== 'ASSIGNED') return;
      const oId = (o.assignedDriverId || '').toLowerCase();
      const oName = (o.assignedDriverName || '').toLowerCase().trim();

      for (const [key, d] of initialMap.entries()) {
        const dId = (d.id || '').toLowerCase();
        const dUserId = ((d as any).userId || '').toLowerCase();
        const dEmpId = ((d as any).employeeId || '').toLowerCase();
        const dName = (d.name || '').toLowerCase().trim();

        if (
          (dId && oId === dId) ||
          (dUserId && oId === dUserId) ||
          (dEmpId && oId === dEmpId) ||
          (dName && oName && (dName.includes(oName) || oName.includes(dName)))
        ) {
          initialMap.set(key, {
            ...d,
            status: d.status === 'emergency' ? 'emergency' : 'delivery',
            deliveryTo: o.deliveryLocation?.address,
            deliveryFrom: o.deliveryFrom,
            orderItems: Array.isArray(o.items) ? o.items.join(', ') : o.items,
            destLat: o.deliveryLocation?.latitude,
            destLng: o.deliveryLocation?.longitude,
            activeOrder: o,
          });
        }
      }
    });

    const list = Array.from(initialMap.values())
      .filter((d) => d && d.id !== 'agent-x' && d.id !== 'mobile-driver' && d.userId !== 'agent-x' && d.userId !== 'mobile-driver')
      .filter((d) => (((d?.name || '') + (d?.employeeId || '') + (d?.fleet || '')).toLowerCase().includes((q || '').toLowerCase())));

    // Deduplicate by name and identifiers so the exact same operator is never shown twice
    const map = new Map<string, Driver>();
    for (const d of list) {
      const normName = (d.name || '').toLowerCase().trim();
      const normEmail = (d.email || '').toLowerCase().trim();
      const normEmpId = (d.employeeId || '').toLowerCase().replace(/^(agent-)/i, '').trim();
      const normId = (d.id || '').toLowerCase().trim();

      let foundKey: string | null = null;
      for (const [k, existing] of map.entries()) {
        const exName = (existing.name || '').toLowerCase().trim();
        const exEmail = (existing.email || '').toLowerCase().trim();
        const exEmpId = (existing.employeeId || '').toLowerCase().replace(/^(agent-)/i, '').trim();
        const exId = (existing.id || '').toLowerCase().trim();

        const nameMatch = Boolean(normName && exName && (normName === exName || normName.includes(exName) || exName.includes(normName)));
        const emailMatch = Boolean(normEmail && exEmail && normEmail === exEmail);
        const empIdMatch = Boolean(normEmpId && exEmpId && (normEmpId === exEmpId || normEmpId.includes(exEmpId) || exEmpId.includes(normEmpId)));
        const idMatch = Boolean(normId && exId && normId === exId);

        if (nameMatch || emailMatch || empIdMatch || idMatch) {
          foundKey = k;
          break;
        }
      }

      if (foundKey) {
        const existing = map.get(foundKey)!;
        if (existing.status === 'offline' && d.status !== 'offline') {
          map.set(foundKey, { ...existing, ...d });
        } else if (d.status !== 'offline') {
          map.set(foundKey, { ...existing, ...d, id: existing.id || d.id });
        } else {
          map.set(foundKey, { ...d, ...existing });
        }
      } else {
        const primaryKey = normName || normEmail || normEmpId || normId;
        map.set(primaryKey, d);
      }
    }

    return Array.from(map.values())
      .sort((a, b) => {
        const valA = Number(a?.[sortKey] ?? 0);
        const valB = Number(b?.[sortKey] ?? 0);
        return valB - valA;
      });
  }, [liveDrivers, selectedRegion, q, sortKey, assignedOrders]);

  const pendingRows = useMemo(() => {
    // Combine fetched API applications with real-time socket applications
    const combined: any[] = [...(pendingDrivers || [])]
    if (socket?.pendingDrivers) {
      for (const sp of socket.pendingDrivers) {
        const id = sp.id || sp.driverId
        const exists = combined.some(
          (p) => (p.id && p.id === id) || (p.driverId && p.driverId === id) || (p.user?.email && p.user.email === sp.email) || (p.email && p.email === sp.email)
        )
        if (!exists) {
          combined.unshift(sp)
        }
      }
    }

    return combined.filter((d) => {
      // Strict Region filtering
      if (!isDriverInRegion(d, selectedRegion)) {
        return false
      }

      const query = (q || '').trim().toLowerCase()
      if (!query) return true
      const name = `${d.user?.firstName || ''} ${d.user?.lastName || ''} ${d.user?.name || d.name || ''}`.toLowerCase()
      const email = (d.user?.email || d.email || '').toLowerCase()
      const zone = (d.user?.zone || d.zone || '').toLowerCase()
      const dl = (d.licenseNumber || '').toLowerCase()
      const tracking = (d.applicationId || d.trackingId || '').toLowerCase()
      const phone = (d.user?.phoneNumber || d.phoneNumber || '').toLowerCase()
      return name.includes(query) || email.includes(query) || zone.includes(query) || dl.includes(query) || tracking.includes(query) || phone.includes(query)
    })
  }, [pendingDrivers, socket?.pendingDrivers, selectedRegion, q])

  const liveSelectedDriver = useMemo(() => {
    if (!selectedDriver) return null
    return (liveDrivers || []).find((d) => d?.id === selectedDriver.id) || selectedDriver
  }, [liveDrivers, selectedDriver])

  const handleDeleteDriver = (e: React.MouseEvent, driver: Driver) => {
    e.stopPropagation()
    setDeleteConfirmTarget(driver)
  }

  const executeDelete = async () => {
    if (!deleteConfirmTarget) return
    const targetId = deleteConfirmTarget.id
    const targetName = (deleteConfirmTarget.name || 'Driver').replace(/\s+applicant/gi, '').trim()
    setDeletingId(targetId)
    try {
      await deleteDriverFromApi(targetId)
      socket.removeDriverLocal(targetId)
      setApiDrivers((prev) => prev.filter((d) => d.id !== targetId && d.userId !== targetId))
      if (selectedDriver?.id === targetId) setSelectedDriver(null)
      setDeleteSuccessToast(`Operator "${targetName}" was permanently deleted from PostgreSQL database.`)
      setTimeout(() => setDeleteSuccessToast(null), 4000)
    } catch (err: any) {
      alert(`Failed to delete operator from database: ${err?.message || 'Check database connection'}`)
    } finally {
      setDeletingId(null)
      setDeleteConfirmTarget(null)
    }
  }

  const handleInlineApprove = async (driver: any) => {
    setApprovingId(driver.id)
    try {
      const res = await approveDriverApplication(driver.id)
      const name = `${driver.user?.firstName || ''} ${driver.user?.lastName || ''}`.trim() || driver.user?.name || 'Driver'
      setApprovalAlert({
        name,
        email: driver.user?.email || 'Registered Email',
        driverCode: res.driverCode,
        tempPassword: res.tempPassword,
      })
      await refreshPending()
    } catch (err) {
      alert('Failed to approve application. Please try again.')
    } finally {
      setApprovingId(null)
    }
  }

  const handleInlineReject = async (driverId: string) => {
    const reason = prompt('Please enter a rejection reason (e.g. Parivahan record mismatch, Expired license):', 'Driving License details could not be verified on MoRTH Sarathi')
    if (reason === null) return
    setRejectingId(driverId)
    try {
      await rejectDriverApplication(driverId, reason)
      await refreshPending()
    } catch (err) {
      alert('Failed to reject application')
    } finally {
      setRejectingId(null)
    }
  }

  return (
    <div className="space-y-6 pb-16 max-w-[1700px] mx-auto px-4 md:px-8 text-foreground">
      {/* ── TOP HEADER CHASSIS BANNER ────────────────────────────────────────────── */}
      <div className="stamped-card relative has-rivets p-6 md:p-8 rounded-[28px] overflow-hidden">
        <div className="corner-screw top-left" />
        <div className="corner-screw top-right" />
        <div className="corner-screw bottom-left" />
        <div className="corner-screw bottom-right" />

        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          <div>
            <div className="flex items-center gap-3">
              <span className="h-3 w-3 rounded-full bg-emerald-500 animate-ping" />
              <h1 className="text-2xl md:text-3xl font-black tracking-tight uppercase font-space text-foreground">
                Operator <span className="text-primary">Registry</span>
              </h1>
              <span className="font-pixel text-[9px] px-2.5 py-1 rounded bg-secondary text-muted-foreground border border-border">
                REV 3.7
              </span>
            </div>
            <p className="font-pixel text-[9px] text-muted-foreground tracking-[0.3em] uppercase mt-2">
              National Fleet Command • MoRTH Sarathi Verification Core
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Parivahan Modal Button */}
            <motion.button
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => setIsVerificationOpen(true)}
              className="h-12 px-5 rounded-2xl bg-secondary hover:bg-card text-foreground border border-border font-space font-black text-xs uppercase tracking-wider flex items-center gap-2.5 transition shadow-sm cursor-pointer"
            >
              <Shield size={16} className="text-primary" />
              <span>Sarathi DL Audit</span>
              {pendingDrivers.length > 0 && (
                <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-amber-500 text-slate-950 font-bold animate-pulse">
                  {pendingDrivers.length} PENDING
                </span>
              )}
            </motion.button>

            {/* Quick Requests Route Button */}
            <motion.button
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => navigate('/requests')}
              className="h-12 px-5 rounded-2xl bg-primary text-white font-space font-black text-xs uppercase tracking-wider flex items-center gap-2 transition shadow-lg shadow-primary/20 cursor-pointer"
            >
              <UserPlus size={16} />
              <span>Onboarding Hub</span>
            </motion.button>

            {/* Tactical Search */}
            <div className="relative debossed-well rounded-2xl overflow-hidden min-w-[260px] md:min-w-[300px]">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder={activeTab === 'active' ? "SEARCH OPERATORS / FLEET ID..." : "SEARCH APPLICANTS / DL..."}
                className="h-12 w-full bg-transparent pl-11 pr-4 text-xs font-tech font-bold uppercase tracking-wider text-foreground placeholder:text-muted-foreground outline-none"
              />
            </div>
          </div>
        </div>
      </div>

      {/* ── APPROVAL DISPATCH SUCCESS NOTIFICATION MODAL/CARD ────────────────────────────────── */}
      <AnimatePresence>
        {approvalAlert && (
          <motion.div
            initial={{ opacity: 0, scale: 0.96, y: -10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: -10 }}
            className="stamped-card relative has-rivets p-6 rounded-[28px] border-2 border-emerald-500/40 bg-emerald-500/10 text-foreground shadow-2xl"
          >
            <div className="corner-screw top-left" />
            <div className="corner-screw top-right" />
            <div className="corner-screw bottom-left" />
            <div className="corner-screw bottom-right" />

            <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
              <div className="flex items-start gap-4">
                <div className="h-12 w-12 rounded-2xl bg-emerald-500 text-slate-950 flex items-center justify-center font-black shrink-0 shadow-lg shadow-emerald-500/30">
                  <CheckCircle2 size={24} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-space font-black text-sm uppercase tracking-tight text-foreground">
                      Application Approved • TLS SMTP Credentials Dispatched!
                    </h3>
                    <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-emerald-500 text-slate-950 font-bold">
                      ACTIVE OPERATOR
                    </span>
                  </div>
                  <p className="font-tech text-xs text-muted-foreground mt-1.5">
                    Assigned Driver ID: <strong className="text-emerald-500 font-bold font-mono text-sm px-1.5 py-0.5 rounded bg-card border border-emerald-500/30">{approvalAlert.driverCode}</strong>
                    {' '}• Temp Password: <strong className="text-amber-500 font-bold font-mono text-sm px-1.5 py-0.5 rounded bg-card border border-amber-500/30">{approvalAlert.tempPassword}</strong>
                    {' '}dispatched securely to <strong className="text-foreground">{approvalAlert.email}</strong>.
                  </p>
                </div>
              </div>

              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => setApprovalAlert(null)}
                className="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-space font-black text-xs uppercase tracking-wider transition shrink-0 cursor-pointer shadow-md"
              >
                Acknowledge
              </motion.button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ── MECHANICAL TAB RACK CONTROLLER ────────────────────────────────────────── */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="debossed-well p-1.5 rounded-2xl flex items-center gap-2">
          <motion.button
            whileTap={{ scale: 0.96 }}
            onClick={() => setActiveTab('active')}
            className={cn(
              "h-11 px-5 rounded-xl font-space font-black text-xs uppercase tracking-wider flex items-center gap-2.5 transition cursor-pointer",
              activeTab === 'active'
                ? "bg-primary text-white shadow-md"
                : "text-muted-foreground hover:text-foreground"
            )}
          >
            <Users size={15} />
            <span>Active Operators</span>
            <span className={cn(
              "font-pixel text-[8px] px-2 py-0.5 rounded",
              activeTab === 'active' ? "bg-white text-slate-950 font-bold" : "bg-card text-muted-foreground"
            )}>
              {rows.length}
            </span>
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.96 }}
            onClick={() => {
              setActiveTab('pending')
              refreshPending(selectedRegion)
            }}
            className={cn(
              "h-11 px-5 rounded-xl font-space font-black text-xs uppercase tracking-wider flex items-center gap-2.5 transition cursor-pointer relative",
              activeTab === 'pending'
                ? "bg-primary text-white shadow-md"
                : "text-muted-foreground hover:text-foreground"
            )}
          >
            <UserPlus size={15} />
            <span>Pending Onboarding</span>
            {pendingRows.length > 0 ? (
              <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-amber-500 text-slate-950 font-bold animate-pulse">
                {pendingRows.length} QUEUED
              </span>
            ) : (
              <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-card text-muted-foreground">
                0
              </span>
            )}
          </motion.button>
        </div>

        {activeTab === 'pending' && (
          <div className="flex items-center gap-3">
            <div className="debossed-well px-3.5 py-2 rounded-xl flex items-center gap-2 text-xs font-tech">
              <MapPin size={14} className="text-primary shrink-0" />
              <span className="font-pixel text-[8px] text-muted-foreground uppercase">Hub:</span>
              <select
                value={selectedRegion}
                onChange={(e) => setSelectedRegion(e.target.value)}
                className="bg-transparent text-foreground font-tech font-bold outline-none cursor-pointer text-xs"
              >
                {REGIONS_LIST.map((r) => (
                  <option key={r.value} value={r.value} className="bg-card text-foreground">
                    {r.label}
                  </option>
                ))}
              </select>
            </div>

            <motion.button
              whileTap={{ scale: 0.92 }}
              onClick={() => refreshPending(selectedRegion)}
              disabled={pendingLoading}
              className="h-10 px-3 rounded-xl bg-card border border-border text-muted-foreground hover:text-foreground flex items-center gap-2 transition cursor-pointer"
              title="Refresh applications"
            >
              <RefreshCw size={13} className={cn(pendingLoading && "animate-spin text-primary")} />
            </motion.button>
          </div>
        )}
      </div>

      {/* ── SAME-DIRECTION FLEET CONVOY INTELLIGENCE BANNER ────────────────────── */}
      {sameDirectionSummary && sameDirectionSummary.count > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -6 }}
          animate={{ opacity: 1, y: 0 }}
          className="stamped-card relative has-rivets p-4 rounded-2xl border-2 border-cyan-500/40 bg-cyan-950/30 text-cyan-100 flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shadow-xl"
        >
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 flex items-center justify-center shrink-0 shadow-md">
              <Navigation size={20} className="animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-space font-black text-xs uppercase tracking-wider text-cyan-300">
                  Cooperative Convoy Radar • {sameDirectionSummary.count} Pair(s) Aligned
                </span>
                <span className="h-2 w-2 rounded-full bg-cyan-400 animate-ping" />
              </div>
              <p className="font-tech text-xs text-cyan-200/80 mt-0.5">
                Vehicles moving in the same heading corridor within 500m proximity. Peer-to-peer V2V telemetry, hazard relays, and proximity alerts active.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2 self-end md:self-auto font-mono text-[10px] font-bold px-3 py-1.5 rounded-xl bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 shrink-0">
            <span>500M V2V MESH ACTIVE</span>
          </div>
        </motion.div>
      )}

      {/* ── TAB 1: ACTIVE FLEET OPERATORS TABLE ────────────────────────────────────────── */}
      {activeTab === 'active' && (
        <div className="stamped-card relative has-rivets rounded-[32px] overflow-hidden">
          <div className="corner-screw top-left" />
          <div className="corner-screw top-right" />
          <div className="corner-screw bottom-left" />
          <div className="corner-screw bottom-right" />

          <div className="overflow-x-auto no-scrollbar">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-border font-pixel text-[9px] text-muted-foreground tracking-[0.25em] uppercase bg-secondary/40">
                  <th className="px-8 py-5 border-r border-border">CHASSIS UID</th>
                  <th className="px-8 py-5">OPERATOR</th>
                  <th className="px-8 py-5">TELEMETRY LINK</th>
                  <th className="px-6 py-5">RESCUE & DEAD ZONE DISPATCH</th>
                  <th 
                    className="px-8 py-5 cursor-pointer hover:text-foreground transition" 
                    onClick={() => setSortKey('safetyScore')}
                  >
                    <span className="inline-flex items-center gap-2">
                      SAFETY INDEX <ArrowUpDown size={10} />
                    </span>
                  </th>
                  <th className="px-8 py-5">G-FORCE WAVE</th>
                  <th className="px-8 py-5">ODOMETER</th>
                  <th className="px-8 py-5 text-right">INSPECTION</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="py-36 text-center">
                      <div className="flex flex-col items-center justify-center opacity-50">
                        <ShieldAlert size={48} className="text-muted-foreground mb-4 animate-pulse" />
                        <p className="font-pixel text-[10px] uppercase tracking-[0.4em] text-muted-foreground">
                          Awaiting Vehicle Telemetry Stream...
                        </p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  rows.map((d, i) => {
                    const score = typeof d?.safetyScore === 'number' ? Math.round(d.safetyScore) : 100
                    const spark = Array.from({ length: 8 }, (_, k) => score + Math.round(seeded(i * 8 + k) * 10 - 5))
                    const safeId = d?.id ? String(d.id).slice(0, 6).toUpperCase() : 'DRV-01'
                    const isSOS = d?.status === 'emergency'

                    return (
                      <motion.tr
                        key={d.id || i}
                        initial={{ opacity: 0, x: -8 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: i * 0.02 }}
                        onClick={() => setSelectedDriver(d)}
                        className={cn(
                          "group hover:bg-secondary/40 cursor-pointer transition-all duration-200",
                          isSOS && "bg-rose-500/10 hover:bg-rose-500/20"
                        )}
                      >
                        {/* UID */}
                        <td className="px-8 py-5 border-r border-border">
                          <span className="font-mono font-bold text-xs text-primary px-2.5 py-1 rounded bg-primary/10 border border-primary/20">
                            #{safeId}
                          </span>
                        </td>

                        {/* Operator */}
                        <td className="px-8 py-5">
                          <div className="flex items-center gap-4">
                            <Avatar 
                              name={(d?.name || 'Driver').replace(/\s+applicant/gi, '').trim()} 
                              src={(d as any)?.avatar || (d as any)?.profileImagePath || (d as any)?.avatarUrl} 
                              size={38} 
                              className="ring-2 ring-border group-hover:ring-primary transition-all" 
                            />
                            <div>
                              <div className="font-space font-black text-sm uppercase tracking-wide group-hover:text-primary transition-colors">
                                {(d?.name || 'Driver').replace(/\s+applicant/gi, '').trim()}
                              </div>
                              <div className="font-pixel text-[8px] text-muted-foreground uppercase tracking-widest mt-1">
                                {d?.employeeId || 'ID-LIVE'} • {d?.fleet || 'TACTICAL FLEET'}
                              </div>
                            </div>
                          </div>
                        </td>

                        {/* Status */}
                        <td className="px-8 py-5">
                          <div className="flex flex-col gap-1 items-start">
                            {(d as any)?.isDeadZone ? (
                              <span className="font-pixel text-[8px] px-2.5 py-1 rounded border uppercase tracking-wider font-bold flex items-center gap-1.5 bg-cyan-500/20 border-cyan-500/40 text-cyan-400">
                                <span className="h-1.5 w-1.5 rounded-full bg-cyan-400 animate-ping" />
                                📡 DEAD ZONE (GHAT)
                              </span>
                            ) : (
                              <span className={cn(
                                "font-pixel text-[8px] px-2.5 py-1 rounded border uppercase tracking-wider font-bold flex items-center gap-1.5",
                                d?.status === 'emergency' 
                                  ? "bg-rose-500/20 border-rose-500/40 text-rose-500 animate-pulse"
                                  : d?.status === 'warning'
                                  ? "bg-amber-500/20 border-amber-500/40 text-amber-500"
                                  : d?.status === 'offline'
                                  ? "bg-slate-500/20 border-slate-500/40 text-slate-400"
                                  : "bg-emerald-500/15 border-emerald-500/30 text-emerald-500"
                              )}>
                                <span className={cn(
                                  "h-1.5 w-1.5 rounded-full",
                                  d?.status === 'emergency' ? "bg-rose-500 animate-ping" : d?.status === 'offline' ? "bg-slate-400" : "bg-emerald-500"
                                )} />
                                {d?.status === 'emergency' 
                                  ? ((d as any)?.alertType === 'SOS' ? '🚨 MANUAL SOS' : (d as any)?.alertType === 'CRASH' ? '💥 CRASH IMPACT' : '🚨 SOS ALERT')
                                  : (STATUS_LABEL[d?.status || 'safe'] || d?.status || 'ACTIVE')}
                              </span>
                            )}
                            {(Boolean(d?.deliveryTo || d?.orderItems || d?.destLat != null || d?.status === 'delivery')) && (
                              <div className="flex flex-col gap-0.5 mt-1">
                                <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 flex items-center gap-1 font-bold animate-pulse">
                                  <Truck size={10} className="text-emerald-400" /> ON MISSION
                                </span>
                                {d?.deliveryTo && (
                                  <span className="font-mono text-[8px] text-emerald-300 truncate max-w-[150px]" title={`Destination: ${d.deliveryTo}`}>
                                    📍 {d.deliveryTo}
                                  </span>
                                )}
                                {d?.orderItems && (
                                  <span className="font-mono text-[8px] text-slate-400 truncate max-w-[150px]" title={`Items: ${d.orderItems}`}>
                                    📦 {d.orderItems}
                                  </span>
                                )}
                              </div>
                            )}
                          </div>
                        </td>

                        {/* Rescue Availability & Dead Zone Dispatch Controls */}
                        <td className="px-6 py-5" onClick={(e) => e.stopPropagation()}>
                          <div className="flex flex-col gap-1.5 items-start">
                            {/* Availability Toggle */}
                            <motion.button
                              whileHover={{ scale: 1.03 }}
                              whileTap={{ scale: 0.95 }}
                              onClick={(e) => handleToggleAvailability(e, d.id, (d as any).isAvailable !== false && (d as any).isAvailableForRescue !== false)}
                              title="Click to toggle driver standby availability for SOS/Rescue events"
                              className={cn(
                                "px-2.5 py-1 rounded-lg border text-[9px] font-space font-black uppercase tracking-wider flex items-center gap-1.5 transition-all cursor-pointer shadow-sm",
                                (d as any).isAvailable !== false && (d as any).isAvailableForRescue !== false
                                  ? "bg-emerald-500/15 border-emerald-500/40 text-emerald-400 hover:bg-emerald-500/25"
                                  : "bg-slate-800/80 border-slate-700 text-slate-400 hover:bg-slate-700/80"
                              )}
                            >
                              <span className={cn(
                                "h-2 w-2 rounded-full",
                                (d as any).isAvailable !== false && (d as any).isAvailableForRescue !== false ? "bg-emerald-400 animate-pulse" : "bg-slate-500"
                              )} />
                              <span>{(d as any).isAvailable !== false && (d as any).isAvailableForRescue !== false ? "🟢 RESCUE STANDBY" : "⛔ UNAVAILABLE"}</span>
                            </motion.button>

                            {/* Dead Zone Mode Toggle */}
                            <motion.button
                              whileHover={{ scale: 1.03 }}
                              whileTap={{ scale: 0.95 }}
                              onClick={(e) => handleToggleDeadZone(e, d.id, Boolean((d as any).isDeadZone))}
                              title="Click to activate or deactivate Dead Zone P2P Mesh mode for this operator"
                              className={cn(
                                "px-2.5 py-1 rounded-lg border text-[9px] font-space font-black uppercase tracking-wider flex items-center gap-1.5 transition-all cursor-pointer shadow-sm",
                                (d as any).isDeadZone
                                  ? "bg-cyan-500/25 border-cyan-400 text-cyan-300 shadow-[0_0_10px_rgba(6,182,212,0.3)] animate-pulse"
                                  : "bg-slate-800/40 border-slate-700 text-slate-400 hover:border-cyan-500/40 hover:text-cyan-400"
                              )}
                            >
                              <Radio size={11} className={cn((d as any).isDeadZone && "animate-spin text-cyan-300")} />
                              <span>{(d as any).isDeadZone ? "📡 DEAD ZONE ON" : "📡 MESH READY"}</span>
                            </motion.button>

                            {/* 70/30 Partnership Relay Tactical Map Launch Button */}
                            <motion.button
                              whileHover={{ scale: 1.03 }}
                              whileTap={{ scale: 0.95 }}
                              onClick={(e) => {
                                e.stopPropagation()
                                localStorage.setItem('smartdrive_open_relay_section', d.id)
                                window.location.href = `/map?relayDriverId=${d.id}`
                              }}
                              title="Open Tactical Map Section & Assign 70/30 Partnership Relay"
                              className="px-2.5 py-1 rounded-lg border text-[9px] font-space font-black uppercase tracking-wider flex items-center gap-1.5 transition-all cursor-pointer shadow-sm bg-sky-500/15 border-sky-500/40 text-sky-400 hover:bg-sky-500/25"
                            >
                              <Navigation size={11} className="text-sky-300" />
                              <span>🤝 70/30 RELAY MAP</span>
                            </motion.button>
                          </div>
                        </td>

                        {/* Stability Score */}
                        <td className="px-8 py-5">
                          <div className="flex items-baseline gap-1">
                            <span className={cn(
                              "font-space font-black text-2xl tabular-nums leading-none",
                              score < 70 ? 'text-rose-500' : 'text-emerald-500'
                            )}>
                              {score}
                            </span>
                            <span className="font-pixel text-[8px] text-muted-foreground">/ 100</span>
                          </div>
                        </td>

                        {/* Sparkline Wave */}
                        <td className="px-8 py-5 w-40">
                          <Sparkline data={spark} color="#10b981" height={24} />
                        </td>

                        {/* Telemetry Odometer & Reward Points */}
                        <td className="px-8 py-5 font-tech">
                          <div className="flex flex-col">
                            <span className="font-space font-black text-sm text-foreground">
                              {(d?.distanceToday ?? 0).toFixed(1)} <span className="font-pixel text-[8px] text-muted-foreground">KM</span>
                            </span>
                            <span className="font-pixel text-[8px] text-muted-foreground uppercase mt-0.5">
                              {d?.trips || 0} DELIVERIES
                            </span>
                            <span className="font-mono text-[10px] text-amber-400 font-bold mt-1 flex items-center gap-1">
                              ⭐ {((d as any)?.points ?? (d as any)?.xp ?? (d as any)?.totalPoints ?? 0)} PTS
                            </span>
                          </div>
                        </td>

                        {/* Inspection, Edit & Delete */}
                        <td className="px-8 py-5 text-right">
                          <div className="inline-flex items-center gap-2">
                            {/* Edit Button */}
                            <motion.button
                              whileHover={{ scale: 1.08 }}
                              whileTap={{ scale: 0.92 }}
                              onClick={(e) => {
                                e.stopPropagation()
                                setEditingDriver(d)
                              }}
                              title="Edit Operator Profile (Syncs to DB)"
                              className="h-9 w-9 rounded-xl border border-border text-muted-foreground hover:text-primary hover:border-primary/50 hover:bg-primary/10 transition-all flex items-center justify-center cursor-pointer shadow-sm"
                            >
                              <Pencil size={13} />
                            </motion.button>

                            {/* Delete Button */}
                            <motion.button
                              whileHover={{ scale: 1.08 }}
                              whileTap={{ scale: 0.92 }}
                              onClick={(e) => handleDeleteDriver(e, d)}
                              disabled={deletingId === d.id}
                              title="Permanently Delete Operator from Database"
                              className="h-9 w-9 rounded-xl border border-border text-muted-foreground hover:text-rose-500 hover:border-rose-500/50 hover:bg-rose-500/10 transition-all flex items-center justify-center cursor-pointer shadow-sm"
                            >
                              <Trash2 size={13} />
                            </motion.button>
                            
                            <motion.div 
                              whileHover={{ x: 2 }}
                              className="h-9 w-9 rounded-xl bg-secondary border border-border text-muted-foreground group-hover:bg-primary group-hover:text-white group-hover:border-primary transition-all flex items-center justify-center shadow-sm"
                            >
                              <ChevronRight size={16} />
                            </motion.div>
                          </div>
                        </td>
                      </motion.tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ── TAB 2: PENDING EMPLOYEE REQUESTS ────────────────────────────────────────── */}
      {activeTab === 'pending' && (
        <div className="stamped-card relative has-rivets rounded-[32px] overflow-hidden min-h-[450px]">
          <div className="corner-screw top-left" />
          <div className="corner-screw top-right" />
          <div className="corner-screw bottom-left" />
          <div className="corner-screw bottom-right" />

          {pendingRows.length === 0 ? (
            <div className="py-36 text-center flex flex-col items-center justify-center">
              <div className="h-16 w-16 rounded-3xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-500 flex items-center justify-center mb-4">
                <CheckCircle2 size={32} />
              </div>
              <h3 className="font-space font-black text-lg uppercase tracking-tight text-foreground">
                All Sector Applications Cleared
              </h3>
              <p className="font-tech text-xs text-muted-foreground mt-2 max-w-md">
                {selectedRegion !== 'all'
                  ? `No pending applications matching the "${selectedRegion}" jurisdiction filter.`
                  : "No pending driver employee applications awaiting MoRTH Sarathi verification."}
              </p>
              {selectedRegion !== 'all' && (
                <button
                  onClick={() => setSelectedRegion('all')}
                  className="mt-4 px-4 py-2 rounded-xl bg-primary text-white font-space font-bold text-xs uppercase tracking-wider hover:opacity-90 transition cursor-pointer"
                >
                  View All Regional Requests
                </button>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto no-scrollbar">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-border font-pixel text-[9px] text-muted-foreground tracking-[0.25em] uppercase bg-secondary/40">
                    <th className="px-8 py-5">APPLICANT</th>
                    <th className="px-6 py-5">REGIONAL JURISDICTION</th>
                    <th className="px-6 py-5">MORTH SARATHI DL</th>
                    <th className="px-6 py-5">EMERGENCY SOS CONTACT</th>
                    <th className="px-6 py-5">STATUS</th>
                    <th className="px-8 py-5 text-right">AUDIT & APPROVAL</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {pendingRows.map((app, i) => {
                    const name = `${app.user?.firstName || ''} ${app.user?.lastName || ''}`.trim() || app.user?.name || 'Applicant'
                    const email = app.user?.email || 'N/A'
                    const phone = app.user?.phoneNumber || 'N/A'
                    const zone = app.user?.zone || 'Regional Hub'
                    const licenseNo = app.licenseNumber || 'N/A'
                    const emergencyName = app.emergencyContactName || 'Family / Guardian'
                    const emergencyPhone = app.emergencyContactPhone || 'N/A'
                    const vehicleBadge = (app.badges || []).find((b: string) => b.startsWith('applied_vehicle:'))?.replace('applied_vehicle:', '') || app.driverType || 'Scooter'
                    const appId = (app.badges || []).find((b: string) => b.startsWith('application_id:'))?.replace('application_id:', '') || `REQ-${String(app.id).slice(0, 6)}`

                    return (
                      <motion.tr
                        key={app.id || i}
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: i * 0.03 }}
                        className="hover:bg-secondary/30 transition-all"
                      >
                        {/* Applicant */}
                        <td className="px-8 py-5">
                          <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-2xl bg-primary/10 border border-primary/20 text-primary flex items-center justify-center font-space font-black text-sm uppercase">
                              {name.charAt(0) || 'D'}
                            </div>
                            <div>
                              <div className="font-space font-black text-foreground uppercase text-sm tracking-tight leading-none">
                                {name}
                              </div>
                              <div className="flex items-center gap-2 mt-1.5 font-tech text-xs text-muted-foreground">
                                <span className="flex items-center gap-1 font-mono text-[11px]">
                                  <Mail size={11} className="text-primary" /> {email}
                                </span>
                                {phone !== 'N/A' && (
                                  <span className="flex items-center gap-1 font-mono text-[11px]">
                                    • <Phone size={11} className="text-muted-foreground" /> {phone}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                        </td>

                        {/* Zone */}
                        <td className="px-6 py-5">
                          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-secondary border border-border text-xs font-tech font-bold text-foreground">
                            <MapPin size={12} className="text-primary shrink-0" />
                            <span className="truncate max-w-[180px]">{zone}</span>
                          </div>
                          <div className="font-pixel text-[8px] text-muted-foreground mt-1 uppercase">
                            REF: {appId}
                          </div>
                        </td>

                        {/* DL & Vehicle */}
                        <td className="px-6 py-5">
                          <div className="font-mono text-xs font-bold text-foreground uppercase tracking-wider px-2 py-0.5 rounded bg-secondary/80 inline-block border border-border">
                            {licenseNo}
                          </div>
                          <div className="mt-1.5 flex items-center gap-1.5">
                            <VehicleSymbol type={vehicleBadge} size={16} showBadge={true} />
                          </div>
                        </td>

                        {/* Emergency Contact */}
                        <td className="px-6 py-5 font-tech">
                          <div className="text-xs font-bold text-foreground">
                            {emergencyName}
                          </div>
                          <div className="text-[11px] text-muted-foreground font-mono mt-0.5">
                            {emergencyPhone}
                          </div>
                        </td>

                        {/* Status */}
                        <td className="px-6 py-5">
                          <span className="font-pixel text-[8px] px-2.5 py-1 rounded border border-amber-500/30 bg-amber-500/10 text-amber-500 font-bold uppercase tracking-widest inline-flex items-center gap-1">
                            <Clock size={10} /> REVIEW
                          </span>
                        </td>

                        {/* Actions */}
                        <td className="px-8 py-5 text-right">
                          <div className="inline-flex items-center gap-2">
                            {/* Parivahan DL Inspect */}
                            <motion.button
                              whileHover={{ y: -1 }}
                              whileTap={{ scale: 0.94 }}
                              onClick={() => setIsVerificationOpen(true)}
                              className="h-9 px-3.5 rounded-xl bg-secondary hover:bg-card border border-border text-foreground font-space font-black text-[11px] uppercase tracking-wider flex items-center gap-1.5 cursor-pointer"
                              title="Inspect Parivahan record"
                            >
                              <FileCheck size={13} className="text-primary" />
                              <span>Sarathi</span>
                            </motion.button>

                            {/* Approve & Dispatch Password */}
                            <motion.button
                              whileHover={{ scale: 1.03 }}
                              whileTap={{ scale: 0.94 }}
                              onClick={() => handleInlineApprove(app)}
                              disabled={approvingId === app.id}
                              className="h-9 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-space font-black text-[11px] uppercase tracking-wider transition flex items-center gap-1.5 shadow-md shadow-emerald-600/20 disabled:opacity-50 cursor-pointer"
                            >
                              {approvingId === app.id ? (
                                <RefreshCw size={13} className="animate-spin" />
                              ) : (
                                <Send size={13} />
                              )}
                              <span>Approve & Email</span>
                            </motion.button>

                            {/* Reject Button */}
                            <motion.button
                              whileHover={{ scale: 1.08 }}
                              whileTap={{ scale: 0.92 }}
                              onClick={() => handleInlineReject(app.id)}
                              disabled={rejectingId === app.id}
                              className="h-9 px-3 rounded-xl border border-rose-500/20 text-rose-500 hover:bg-rose-500/10 transition flex items-center justify-center cursor-pointer"
                              title="Reject Application"
                            >
                              <XCircle size={15} />
                            </motion.button>
                          </div>
                        </td>
                      </motion.tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Driver Detail Telemetry & Crisis Modal */}
      <DriverDetailModal 
        driver={liveSelectedDriver} 
        onClose={() => setSelectedDriver(null)} 
      />

      {/* Edit Operator Modal */}
      <EditDriverModal
        driver={editingDriver}
        isOpen={Boolean(editingDriver)}
        onClose={() => setEditingDriver(null)}
        onSuccess={(updated) => {
          setApiDrivers((prev) => prev.map((d) => (d.id === updated.id ? { ...d, ...updated } : d)))
          if (selectedDriver?.id === updated.id) {
            setSelectedDriver((prev) => (prev ? { ...prev, ...updated } : null))
          }
          loadApiDrivers(selectedRegion)
        }}
      />

      {/* Permanent Deletion Confirmation Modal */}
      {deleteConfirmTarget && (
        <AnimatePresence>
          <div className="fixed inset-0 z-[1200] flex items-center justify-center p-4 bg-black/85 backdrop-blur-md">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="bg-[#0B0F19] text-white p-7 rounded-3xl border-2 border-rose-500/70 shadow-[0_0_60px_rgba(244,63,94,0.35)] max-w-md w-full text-center space-y-5 relative overflow-hidden"
            >
              {/* Subtle emergency backdrop glow */}
              <div className="absolute -top-24 -left-24 w-48 h-48 bg-rose-600/20 rounded-full blur-3xl pointer-events-none" />
              <div className="absolute -bottom-24 -right-24 w-48 h-48 bg-amber-600/10 rounded-full blur-3xl pointer-events-none" />

              <div className="h-14 w-14 rounded-2xl bg-rose-500/20 border-2 border-rose-500/40 text-rose-400 flex items-center justify-center mx-auto shadow-inner">
                <Trash2 size={26} className="animate-pulse" />
              </div>

              <div>
                <h3 className="text-xl font-black font-space uppercase tracking-tight text-white">
                  Permanently Delete Operator?
                </h3>
                <p className="text-xs text-slate-300 mt-2.5 leading-relaxed font-sans font-normal">
                  Are you sure you want to permanently delete{' '}
                  <span className="text-amber-300 font-bold bg-amber-400/15 border border-amber-400/30 px-2 py-0.5 rounded-md">
                    {(deleteConfirmTarget.name || 'Driver').replace(/\s+applicant/gi, '').trim()}
                  </span>{' '}
                  <span className="text-slate-400 font-mono text-[11px]">
                    ({deleteConfirmTarget.employeeId || deleteConfirmTarget.id.slice(0, 8)})
                  </span>?
                </p>
                <p className="text-[11px] text-rose-300/90 font-medium mt-2 bg-rose-950/40 border border-rose-900/50 p-2.5 rounded-xl">
                  ⚠️ This action is irreversible. All telemetry history, vehicle assignments, and credentials will be permanently purged from PostgreSQL.
                </p>
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setDeleteConfirmTarget(null)}
                  disabled={Boolean(deletingId)}
                  className="flex-1 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-space font-bold text-xs uppercase tracking-wider transition cursor-pointer disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={executeDelete}
                  disabled={Boolean(deletingId)}
                  className="flex-1 py-3 rounded-xl bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-500 hover:to-rose-500 text-white font-space font-black text-xs uppercase tracking-wider transition shadow-lg shadow-rose-600/40 cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <Trash2 size={14} />
                  <span>{deletingId ? 'Deleting...' : 'Delete from DB'}</span>
                </button>
              </div>
            </motion.div>
          </div>
        </AnimatePresence>
      )}

      {/* Delete Success Toast */}
      {deleteSuccessToast && (
        <div className="fixed bottom-6 right-6 z-[1200] max-w-md bg-emerald-950/95 border-2 border-emerald-500 text-white text-xs p-4 rounded-2xl shadow-2xl backdrop-blur-md flex items-center justify-between gap-3 animate-in fade-in slide-in-from-bottom-3">
          <div className="flex items-center gap-2.5">
            <CheckCircle2 size={18} className="text-emerald-400 shrink-0" />
            <span className="font-bold text-emerald-100">{deleteSuccessToast}</span>
          </div>
          <button
            onClick={() => setDeleteSuccessToast(null)}
            className="text-emerald-400 hover:text-white p-1 text-xs cursor-pointer"
          >
            ✕
          </button>
        </div>
      )}

      {/* Driver MoRTH Sarathi Verification Modal */}
      <DriverVerificationModal 
        isOpen={isVerificationOpen} 
        onClose={() => {
          setIsVerificationOpen(false)
          refreshPending()
        }}
        onApproved={() => {
          refreshPending()
          loadApiDrivers(selectedRegion)
        }}
      />

      {/* Full-Screen Visual Tactical Map for Partnership Rescue Handover */}
      {relayModalDriver && (
        <PartnershipRelayModal
          isOpen={!!relayModalDriver}
          onClose={() => setRelayModalDriver(null)}
          troubledDriver={relayModalDriver}
          activeOrder={{
            orderId: (relayModalDriver as any)?.orderId || 'ORD-RELAY-771',
            customerName: 'Priority Consignment',
            items: [(relayModalDriver as any)?.orderItems || 'Express Parcel Delivery'],
            dropAddress: 'Central Transit Sector, Main Hub',
            amount: (relayModalDriver as any)?.orderAmount || 150,
          }}
        />
      )}
    </div>
  )
}
