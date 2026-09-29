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
  Sparkles
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
import { Driver } from '@/types'
import { 
  deleteDriverFromApi, 
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
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [isVerificationOpen, setIsVerificationOpen] = useState(false)
  
  // Pending Employee Requests state
  const [pendingDrivers, setPendingDrivers] = useState<any[]>([])
  const [pendingLoading, setPendingLoading] = useState(false)
  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [approvalAlert, setApprovalAlert] = useState<{ name: string; email: string; driverCode: string; tempPassword: string } | null>(null)

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
    refreshPending(selectedRegion)
    const interval = setInterval(() => {
      refreshPending(selectedRegion)
    }, 8000)
    return () => clearInterval(interval)
  }, [selectedRegion])

  const rows = useMemo(() => {
    const list = (liveDrivers || [])
      .filter((d) => isDriverInRegion(d, selectedRegion))
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
  }, [liveDrivers, selectedRegion, q, sortKey]);

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

  const handleDeleteDriver = async (e: React.MouseEvent, driverId: string) => {
    e.stopPropagation()
    if (!confirm('Are you sure you want to remove this operator from the system?')) return
    setDeletingId(driverId)
    await deleteDriverFromApi(driverId)
    socket.removeDriverLocal(driverId)
    setDeletingId(null)
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
                    <td colSpan={7} className="py-36 text-center">
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
                              <span className="font-pixel text-[8px] px-2 py-0.5 rounded bg-primary/10 text-primary border border-primary/20 flex items-center gap-1">
                                <Truck size={10} /> ON MISSION
                              </span>
                            )}
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

                        {/* Telemetry Odometer */}
                        <td className="px-8 py-5 font-tech">
                          <div className="flex flex-col">
                            <span className="font-space font-black text-sm text-foreground">
                              {(d?.distanceToday ?? 0).toFixed(1)} <span className="font-pixel text-[8px] text-muted-foreground">KM</span>
                            </span>
                            <span className="font-pixel text-[8px] text-muted-foreground uppercase mt-0.5">
                              {d?.trips || 0} SORTIES COMPLETED
                            </span>
                          </div>
                        </td>

                        {/* Inspection & Delete */}
                        <td className="px-8 py-5 text-right">
                          <div className="inline-flex items-center gap-2">
                            <motion.button
                              whileHover={{ scale: 1.08 }}
                              whileTap={{ scale: 0.92 }}
                              onClick={(e) => handleDeleteDriver(e, d.id)}
                              disabled={deletingId === d.id}
                              title="De-register Operator"
                              className="h-9 w-9 rounded-xl border border-border text-muted-foreground hover:text-rose-500 hover:border-rose-500/50 hover:bg-rose-500/10 transition-all flex items-center justify-center cursor-pointer"
                            >
                              <Trash2 size={14} />
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

      {/* Driver MoRTH Sarathi Verification Modal */}
      <DriverVerificationModal 
        isOpen={isVerificationOpen} 
        onClose={() => {
          setIsVerificationOpen(false)
          refreshPending()
        }}
        onApproved={() => {
          refreshPending()
        }}
      />
    </div>
  )
}
