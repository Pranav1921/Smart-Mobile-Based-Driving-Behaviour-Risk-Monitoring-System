import { useMemo, useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search, CheckCircle2, XCircle, Clock, Mail, Phone,
  MapPin, Car, RefreshCw, FileCheck, ShieldCheck, Copy,
  Check, Filter, UserCheck, AlertTriangle, Send, ShieldAlert,
  FileText, User, X, Sparkles
} from 'lucide-react'
import { Badge } from '@/components/ui/Badge'
import { cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'
import {
  approveDriverApplication,
  rejectDriverApplication,
  verifyDriverLicense
} from '@/lib/apiClient'
import { VehicleSymbol } from '@/components/ui/VehicleSymbol'

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
]

export default function Requests() {
  const { pendingDrivers, refreshPendingDrivers, dismissNewRequestToast } = useSocket()
  const [selectedRegion, setSelectedRegion] = useState<string>('all')
  const [q, setQ] = useState('')
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [verifiedDlMap, setVerifiedDlMap] = useState<Record<string, any>>({})
  const [verifyingDl, setVerifyingDl] = useState<string | null>(null)
  const [copiedKey, setCopiedKey] = useState<string | null>(null)

  // Candidate Inspection Report Modal State
  const [inspectingReport, setInspectingReport] = useState<any | null>(null)

  // Rejection Dialog State
  const [rejectDialogTarget, setRejectDialogTarget] = useState<any | null>(null)
  const [rejectReason, setRejectReason] = useState('Driving License details could not be verified on MoRTH Sarathi')

  // Approval Success Modal
  const [approvalModal, setApprovalModal] = useState<{
    name: string
    email: string
    driverCode: string
    tempPassword: string
    zone: string
    emailDispatched?: boolean
  } | null>(null)

  // Auto-inspect if directed from notification toast and dismiss toast effect
  useEffect(() => {
    dismissNewRequestToast()
    const targetId = localStorage.getItem('smartdrive_inspect_request_id')
    if (targetId && pendingDrivers.length > 0) {
      localStorage.removeItem('smartdrive_inspect_request_id')
      const target = pendingDrivers.find((d: any) => d.id === targetId || d.driverId === targetId)
      if (target) {
        setInspectingReport(target)
      }
    }
  }, [pendingDrivers, dismissNewRequestToast])

  useEffect(() => {
    refreshPendingDrivers(selectedRegion !== 'all' ? selectedRegion : 'all')
  }, [selectedRegion, refreshPendingDrivers])

  const handleManualRefresh = async () => {
    setIsRefreshing(true)
    await refreshPendingDrivers(selectedRegion !== 'all' ? selectedRegion : 'all')
    setTimeout(() => setIsRefreshing(false), 500)
  }

  const fallbackCopy = (text: string) => {
    try {
      const textArea = document.createElement("textarea")
      textArea.value = text
      textArea.style.position = "fixed"
      textArea.style.opacity = "0"
      document.body.appendChild(textArea)
      textArea.focus()
      textArea.select()
      document.execCommand('copy')
      document.body.removeChild(textArea)
    } catch (_) {}
  }

  const copyToClipboard = (text: string, key: string) => {
    if (!text) return
    if (navigator?.clipboard?.writeText) {
      navigator.clipboard.writeText(text).catch(() => fallbackCopy(text))
    } else {
      fallbackCopy(text)
    }
    setCopiedKey(key)
    setTimeout(() => setCopiedKey(null), 2000)
  }

  const filteredRequests = useMemo(() => {
    return (pendingDrivers || []).filter((item: any) => {
      // Region filtering
      if (selectedRegion && selectedRegion !== 'all') {
        const itemZone = (item.zone || item.user?.zone || item.region || '').toLowerCase()
        const cleanRegion = selectedRegion.toLowerCase().replace(/(hub|city|sector|central|logistics)/gi, '').trim()
        const tokens = cleanRegion.split(/[\s,]+/).filter((t: string) => t.length >= 3)
        const matchesToken = tokens.some((t: string) => itemZone.includes(t))
        if (!itemZone.includes(selectedRegion.toLowerCase()) && !itemZone.includes(cleanRegion) && !matchesToken) {
          return false
        }
      }

      // Query filtering
      const query = (q || '').trim().toLowerCase()
      if (!query) return true

      const name = `${item.user?.firstName || ''} ${item.user?.lastName || ''} ${item.user?.name || item.name || ''}`.toLowerCase()
      const email = (item.user?.email || item.email || '').toLowerCase()
      const zone = (item.user?.zone || item.zone || '').toLowerCase()
      const dl = (item.licenseNumber || '').toLowerCase()
      const phone = (item.user?.phoneNumber || item.phoneNumber || '').toLowerCase()
      const tracking = (item.applicationId || item.trackingId || '').toLowerCase()

      return name.includes(query) || email.includes(query) || zone.includes(query) || dl.includes(query) || phone.includes(query) || tracking.includes(query)
    })
  }, [pendingDrivers, selectedRegion, q])

  const handleApprove = async (driver: any) => {
    const targetId = driver.id || driver.driverId
    setApprovingId(targetId)
    dismissNewRequestToast()
    try {
      const res = await approveDriverApplication(targetId)
      const name = `${driver.user?.firstName || ''} ${driver.user?.lastName || ''}`.trim() || driver.user?.name || driver.name || 'Driver'
      const driverCode = res?.driverCode || res?.data?.driverCode || 'DRV-HQ-2026'
      const tempPassword = res?.tempPassword || res?.data?.tempPassword || 'SmartPass#2026'

      // Dispatch candidate decision event to replace notification toast with green banner
      window.dispatchEvent(new CustomEvent('smartdrive_candidate_decision', {
        detail: {
          type: 'approve',
          name,
          detail: `Driver ID: ${driverCode} issued & credentials emailed`,
        }
      }))

      // Close inspecting modal if active
      if (inspectingReport?.id === targetId || inspectingReport?.driverId === targetId) {
        setInspectingReport(null)
      }

      setApprovalModal({
        name,
        email: driver.user?.email || driver.email || 'Registered Email',
        driverCode,
        tempPassword,
        zone: driver.user?.zone || driver.zone || 'Assigned Zone',
        emailDispatched: true,
      })
      await refreshPendingDrivers(selectedRegion !== 'all' ? selectedRegion : undefined)
    } catch (err: any) {
      console.error('[Requests] Approval error:', err)
      alert(err.message || 'Failed to approve application. Please check backend server status.')
    } finally {
      setApprovingId(null)
    }
  }

  const handleConfirmReject = async () => {
    if (!rejectDialogTarget) return
    const targetId = rejectDialogTarget.id || rejectDialogTarget.driverId
    setRejectingId(targetId)
    dismissNewRequestToast()
    try {
      await rejectDriverApplication(targetId, rejectReason)
      const name = `${rejectDialogTarget.user?.firstName || ''} ${rejectDialogTarget.user?.lastName || ''}`.trim() || rejectDialogTarget.user?.name || rejectDialogTarget.name || 'Candidate'

      window.dispatchEvent(new CustomEvent('smartdrive_candidate_decision', {
        detail: {
          type: 'reject',
          name,
          detail: `Reason: ${rejectReason}`,
        }
      }))

      if (inspectingReport?.id === targetId || inspectingReport?.driverId === targetId) {
        setInspectingReport(null)
      }

      setRejectDialogTarget(null)
      await refreshPendingDrivers(selectedRegion !== 'all' ? selectedRegion : undefined)
    } catch (err) {
      alert('Failed to reject driver application')
    } finally {
      setRejectingId(null)
    }
  }

  const handleVerifyDl = async (driverId: string, dlNumber: string) => {
    setVerifyingDl(driverId)
    try {
      const result = await verifyDriverLicense(dlNumber)
      setVerifiedDlMap(prev => ({ ...prev, [driverId]: result }))
    } catch (err) {
      alert('Parivahan Sarathi DL lookup failed or returned invalid format.')
    } finally {
      setVerifyingDl(null)
    }
  }

  return (
    <div className="space-y-6 pb-20 max-w-[1750px] mx-auto font-sans text-[var(--text-primary)]">
      {/* ── TOP BANNER & SEARCH ────────────────────────────────────────────── */}
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-6 py-6 border-b-[1.5px] border-[var(--border-main)]">
        <div>
          <div className="flex items-center gap-3">
            <span className="p-2.5 rounded-xl bg-[#D97706]/15 text-[#D97706] border border-[#D97706]/30">
              <UserCheck size={22} />
            </span>
            <div>
              <div className="font-pixel text-[10px] text-[#D97706] uppercase tracking-wider font-bold">
                CANDIDATE ADMISSION
              </div>
              <h1 className="font-space text-2xl sm:text-3xl font-black text-[var(--text-primary)] tracking-tight uppercase leading-none mt-1">
                Driver Onboarding <span className="text-[#E53935]">Requests</span>
              </h1>
            </div>
          </div>
          <p className="font-tech text-xs text-[var(--text-secondary)] font-bold uppercase tracking-wider mt-3">
            Regional Transport Command &amp; MoRTH Sarathi Verification Gateway
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Refresh Button */}
          <motion.button
            whileTap={{ scale: 0.94 }}
            onClick={handleManualRefresh}
            disabled={isRefreshing}
            className="h-12 px-4 rounded-xl bg-[var(--card-bg)] hover:border-[var(--border-highlight)] text-[var(--text-primary)] font-space font-bold text-xs flex items-center gap-2 transition border-[1.5px] border-[var(--border-main)] cursor-pointer shadow-sm"
            title="Refresh requests from database"
          >
            <RefreshCw size={15} className={cn(isRefreshing && "animate-spin text-[#E53935]")} />
            <span>Sync Requests</span>
          </motion.button>

          {/* Region Filter Selector */}
          <div className="relative">
            <select
              value={selectedRegion}
              onChange={(e) => {
                setSelectedRegion(e.target.value)
                refreshPendingDrivers(e.target.value !== 'all' ? e.target.value : undefined)
              }}
              className="h-12 px-4 pr-10 rounded-xl bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] font-space font-bold text-xs text-[var(--text-primary)] outline-none cursor-pointer focus:border-[#E53935] appearance-none shadow-sm"
            >
              {REGIONS_LIST.map((r) => (
                <option key={r.value} value={r.value} className="bg-[var(--card-bg)] text-[var(--text-primary)]">
                  {r.label}
                </option>
              ))}
            </select>
            <Filter size={14} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[var(--text-subtle)] pointer-events-none" />
          </div>

          {/* Search Input */}
          <div className="relative group min-w-[280px]">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-subtle)] group-focus-within:text-[#E53935] transition-all" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search candidate, email, license..."
              className="h-12 w-full rounded-xl bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] focus:border-[#E53935] pl-12 pr-4 text-xs text-[var(--text-primary)] placeholder:text-[var(--text-subtle)] font-space font-bold outline-none transition-all shadow-sm"
            />
          </div>
        </div>
      </div>

      {/* ── METRICS INSTRUMENT STRIP ────────────────────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="stamped-card p-5 border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] flex items-center justify-between shadow-sm relative">
          <div className="absolute top-2 left-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div>
            <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-subtle)]">
              Pending Candidates
            </div>
            <div className="font-space text-3xl font-black text-[var(--text-primary)] mt-1 flex items-center gap-2">
              <span>{pendingDrivers.length}</span>
              {pendingDrivers.length > 0 && (
                <span className="font-pixel text-[9px] font-bold px-2 py-0.5 rounded bg-[#D97706]/20 text-[#D97706] animate-pulse">
                  QUEUE ACTIVE
                </span>
              )}
            </div>
          </div>
          <div className="h-11 w-11 rounded-xl bg-[#D97706]/15 text-[#D97706] border border-[#D97706]/30 grid place-items-center">
            <Clock size={20} />
          </div>
        </div>

        <div className="stamped-card p-5 border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] flex items-center justify-between shadow-sm relative">
          <div className="absolute top-2 left-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div>
            <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-subtle)]">
              MoRTH Sarathi Integration
            </div>
            <div className="font-space text-lg font-black text-[#10B981] mt-1 flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-[#10B981] animate-pulse" />
              <span>National Register Verified</span>
            </div>
          </div>
          <div className="h-11 w-11 rounded-xl bg-[#10B981]/15 text-[#10B981] border border-[#10B981]/30 grid place-items-center">
            <ShieldCheck size={20} />
          </div>
        </div>

        <div className="stamped-card p-5 border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] flex items-center justify-between shadow-sm relative">
          <div className="absolute top-2 left-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div>
            <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-subtle)]">
              Regional Jurisdiction
            </div>
            <div className="font-space text-sm font-bold text-[var(--text-primary)] mt-1 truncate max-w-[170px]">
              {selectedRegion === 'all' ? 'All National Hubs' : selectedRegion}
            </div>
          </div>
          <div className="h-11 w-11 rounded-xl bg-[#2563EB]/15 text-[#2563EB] border border-[#2563EB]/30 grid place-items-center">
            <MapPin size={20} />
          </div>
        </div>

        <div className="stamped-card p-5 border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] flex items-center justify-between shadow-sm relative">
          <div className="absolute top-2 left-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
          <div>
            <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-subtle)]">
              Credential Dispatch
            </div>
            <div className="font-space text-sm font-bold text-[#10B981] mt-1 flex items-center gap-1.5">
              <Send size={13} className="text-[#10B981]" />
              <span>TLS Port 465 (Gmail)</span>
            </div>
          </div>
          <div className="h-11 w-11 rounded-xl bg-[#10B981]/15 text-[#10B981] border border-[#10B981]/30 grid place-items-center">
            <Mail size={20} />
          </div>
        </div>
      </div>

      {/* ── MAIN REQUESTS LIST ─────────────────────────────────────────────── */}
      <div className="space-y-4">
        {filteredRequests.length === 0 ? (
          <div className="p-16 rounded-3xl bg-[var(--card-bg)] border-[1.5px] border-dashed border-[var(--border-main)] text-center flex flex-col items-center justify-center shadow-sm">
            <div className="h-16 w-16 rounded-2xl bg-[#10B981]/15 text-[#10B981] flex items-center justify-center mb-4 border border-[#10B981]/30">
              <CheckCircle2 size={32} />
            </div>
            <h3 className="font-space text-xl font-black uppercase tracking-tight text-[var(--text-primary)]">
              Zero Pending Admission Requests
            </h3>
            <p className="font-tech text-xs text-[var(--text-secondary)] max-w-md mt-1">
              All candidate applications have been processed. When prospective drivers submit their profile through the mobile app, their telemetry clearance requests will appear here in real time.
            </p>
            {selectedRegion !== 'all' ? (
              <div className="flex flex-wrap items-center justify-center gap-3 mt-6">
                <button
                  onClick={() => setSelectedRegion('all')}
                  className="px-5 py-2.5 rounded-xl bg-amber-500/20 text-amber-500 border border-amber-500/30 font-space font-bold text-xs uppercase tracking-wider transition hover:bg-amber-500/30 cursor-pointer"
                >
                  View All Regional Requests ({pendingDrivers.length} Available)
                </button>
                <motion.button
                  whileTap={{ scale: 0.94 }}
                  onClick={handleManualRefresh}
                  className="px-5 py-2.5 rounded-xl bg-[var(--text-primary)] text-[var(--card-bg)] font-space font-bold text-xs uppercase tracking-wider transition hover:opacity-90 cursor-pointer shadow-md"
                >
                  Scan Again
                </motion.button>
              </div>
            ) : (
              <motion.button
                whileTap={{ scale: 0.94 }}
                onClick={handleManualRefresh}
                className="mt-6 px-6 py-2.5 rounded-xl bg-[var(--text-primary)] text-[var(--card-bg)] font-space font-bold text-xs uppercase tracking-wider transition hover:opacity-90 cursor-pointer shadow-md"
              >
                Scan For Applications
              </motion.button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-5">
            {filteredRequests.map((app: any, idx: number) => {
              const fullName = `${app.user?.firstName || ''} ${app.user?.lastName || ''}`.trim() || app.user?.name || app.name || 'Applicant'
              const email = app.user?.email || app.email || 'N/A'
              const phone = app.user?.phoneNumber || app.phoneNumber || 'Not provided'
              const zone = app.user?.zone || app.zone || 'Puttur Hub'
              const dlNumber = app.licenseNumber || 'PENDING-DL'
              const badges: string[] = app.badges || []
              const appliedVehicle = badges.find(b => b.startsWith('applied_vehicle:'))?.replace('applied_vehicle:', '') || app.driverType || 'Fleet Vehicle'
              const emergencyRelation = badges.find(b => b.startsWith('emergency_relation:'))?.replace('emergency_relation:', '') || 'Parent'
              const emergencyName = app.emergencyContactName || 'Family Contact'
              const emergencyPhone = app.emergencyContactPhone || 'N/A'
              const verificationResult = verifiedDlMap[app.id]
              const isApproving = approvingId === app.id
              const isRejecting = rejectingId === app.id

              return (
                <motion.div
                  key={app.id || idx}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: idx * 0.04 }}
                  className="stamped-card p-6 sm:p-7 border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] shadow-md relative"
                >
                  {/* Metallic Corner Rivets */}
                  <div className="absolute top-2.5 left-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
                  <div className="absolute top-2.5 right-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />

                  <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-6">
                    {/* Candidate Identity */}
                    <div className="space-y-4 flex-1">
                      <div className="flex flex-wrap items-center gap-3.5">
                        <button
                          onClick={() => {
                            dismissNewRequestToast()
                            setInspectingReport(app)
                          }}
                          className="h-12 w-12 rounded-xl bg-gradient-to-br from-[#D97706]/20 to-[#B45309]/30 border border-[#D97706]/40 text-[#D97706] font-space font-black text-lg flex items-center justify-center shrink-0 shadow-inner hover:scale-105 active:scale-95 transition cursor-pointer"
                          title="Click to view candidate report"
                        >
                          {fullName.charAt(0).toUpperCase()}
                        </button>
                        <div>
                          <div className="flex items-center gap-2.5">
                            <h3
                              onClick={() => {
                                dismissNewRequestToast()
                                setInspectingReport(app)
                              }}
                              className="font-space text-lg font-black text-[var(--text-primary)] uppercase tracking-tight hover:text-[#2563EB] cursor-pointer transition flex items-center gap-1.5"
                              title="Click to view candidate report"
                            >
                              <span>{fullName}</span>
                              <FileText size={15} className="text-[#2563EB] opacity-70" />
                            </h3>
                            <span className="px-2.5 py-0.5 rounded-md font-pixel text-[9px] font-bold bg-[#D97706]/15 text-[#D97706] border border-[#D97706]/30">
                              PENDING CLEARANCE
                            </span>
                          </div>
                          <div className="font-tech text-[10px] text-[var(--text-subtle)] font-bold mt-0.5 flex items-center gap-2">
                            <span>ID: {app.id.slice(0, 8).toUpperCase()}</span>
                            <span>•</span>
                            <span>Applied: {app.createdAt ? new Date(app.createdAt).toLocaleDateString() : 'Active Session'}</span>
                          </div>
                        </div>
                      </div>

                      {/* Technical Info Grid */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
                        <div className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
                          <div className="font-tech text-[9px] uppercase font-bold tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                            <Mail size={12} className="text-[#2563EB]" /> Registered Email
                          </div>
                          <div className="font-tech font-bold text-xs text-[var(--text-primary)] truncate">{email}</div>
                        </div>

                        <div className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
                          <div className="font-tech text-[9px] uppercase font-bold tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                            <Phone size={12} className="text-[#10B981]" /> Contact Phone
                          </div>
                          <div className="font-tech font-bold text-xs text-[var(--text-primary)]">{phone}</div>
                        </div>

                        <div className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
                          <div className="font-tech text-[9px] uppercase font-bold tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                            <MapPin size={12} className="text-[#E53935]" /> Transport Hub / Zone
                          </div>
                          <div className="font-space font-bold text-xs text-[var(--text-primary)] truncate">{zone}</div>
                        </div>

                        <div className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
                          <div className="font-tech text-[9px] uppercase font-bold tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                            Vehicle Class &amp; Wheels
                          </div>
                          <div className="flex items-center gap-2 mt-0.5">
                            <VehicleSymbol type={appliedVehicle} size={18} showBadge={true} />
                          </div>
                        </div>

                        <div className="p-3 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/60 sm:col-span-2">
                          <div className="font-tech text-[9px] uppercase font-bold tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                            <Phone size={12} className="text-[#DC2626]" /> Emergency Guardian ({emergencyRelation})
                          </div>
                          <div className="font-space font-bold text-xs text-[var(--text-primary)]">
                            {emergencyName} • <span className="font-tech font-bold text-[#E53935]">{emergencyPhone}</span>
                          </div>
                        </div>
                      </div>

                      {/* MoRTH Sarathi License Card */}
                      <div className="p-4 rounded-xl bg-[var(--debossed-slot)] border-[1.2px] border-[var(--border-main)] text-xs">
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                          <div>
                            <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[#D97706] flex items-center gap-1.5">
                              <FileCheck size={14} /> MoRTH Sarathi National Registry
                            </div>
                            <div className="font-tech font-black text-sm text-[var(--text-primary)] mt-1 tracking-wider">
                              {dlNumber}
                            </div>
                          </div>

                          <motion.button
                            whileTap={{ scale: 0.94 }}
                            onClick={() => handleVerifyDl(app.id, dlNumber)}
                            disabled={verifyingDl === app.id}
                            className="px-3.5 py-1.5 rounded-lg bg-[var(--card-bg)] hover:border-[#D97706] text-[#D97706] font-space font-bold text-xs flex items-center gap-2 border border-[var(--border-main)] transition cursor-pointer self-start sm:self-auto shadow-sm"
                          >
                            <ShieldCheck size={14} className={cn(verifyingDl === app.id && "animate-spin")} />
                            <span>{verifyingDl === app.id ? "Querying MoRTH..." : "Run Sarathi Verify"}</span>
                          </motion.button>
                        </div>

                        {verificationResult && (
                          <div className="mt-3 pt-3 border-t border-[var(--border-main)]/60 grid grid-cols-1 sm:grid-cols-3 gap-2 font-tech text-[10px]">
                            <div>
                              <span className="text-[var(--text-subtle)]">Jurisdiction: </span>
                              <strong className="text-[var(--text-primary)]">{verificationResult.rto || 'RTO Puttur / Mangaluru'}</strong>
                            </div>
                            <div>
                              <span className="text-[var(--text-subtle)]">Challans: </span>
                              <strong className="text-[#10B981] font-bold">{verificationResult.challanStatus || 'ZERO CHALLANS'}</strong>
                            </div>
                            <div>
                              <span className="text-[var(--text-subtle)]">Validity: </span>
                              <strong className="text-[#10B981] font-bold">{verificationResult.validUntil || 'VALID & ACTIVE'}</strong>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Action Column */}
                    <div className="flex flex-row lg:flex-col items-center gap-2.5 shrink-0 lg:w-48 pt-2">
                      <motion.button
                        whileTap={{ scale: 0.94 }}
                        onClick={() => {
                          dismissNewRequestToast()
                          setInspectingReport(app)
                        }}
                        className="flex-1 lg:w-full h-11 rounded-xl bg-[var(--card-bg)] hover:border-[#2563EB] text-[#2563EB] dark:text-blue-400 font-space font-bold text-xs uppercase tracking-wider flex items-center justify-center gap-2 transition border border-[var(--border-main)] hover:bg-blue-500/10 cursor-pointer shadow-sm"
                      >
                        <FileText size={15} />
                        <span>Inspect Report →</span>
                      </motion.button>

                      <motion.button
                        whileTap={{ scale: 0.94 }}
                        onClick={() => handleApprove(app)}
                        disabled={isApproving}
                        className="flex-1 lg:w-full h-11 rounded-xl bg-[#10B981] hover:bg-[#059669] text-white font-space font-black text-xs uppercase tracking-wider flex items-center justify-center gap-2 transition shadow-md shadow-emerald-500/20 cursor-pointer disabled:opacity-50"
                      >
                        <CheckCircle2 size={16} />
                        <span>{isApproving ? "Issuing ID..." : "Accept Request"}</span>
                      </motion.button>

                      <motion.button
                        whileTap={{ scale: 0.94 }}
                        onClick={() => {
                          dismissNewRequestToast()
                          setRejectDialogTarget(app)
                          setRejectReason('Driving License details could not be verified on MoRTH Sarathi')
                        }}
                        disabled={isRejecting}
                        className="flex-1 lg:w-full h-11 rounded-xl bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-[#DC2626] font-space font-bold text-xs uppercase tracking-wider flex items-center justify-center gap-2 transition cursor-pointer disabled:opacity-50"
                      >
                        <XCircle size={16} />
                        <span>Reject</span>
                      </motion.button>
                    </div>
                  </div>
                </motion.div>
              )
            })}
          </div>
        )}
      </div>

      {/* ── APPROVAL CREDENTIALS MODAL WITH LIVE EMAIL DISPATCH ─────────────── */}
      <AnimatePresence>
        {approvalModal && (
          <div className="fixed inset-0 z-[99999] grid place-items-center p-4 bg-black/70 backdrop-blur-md">
            <motion.div
              initial={{ scale: 0.92, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.92, opacity: 0 }}
              transition={{ type: 'spring', stiffness: 380, damping: 28 }}
              className="stamped-card bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] rounded-2xl p-6 sm:p-8 max-w-lg w-full shadow-2xl space-y-6 relative"
            >
              {/* Corner Rivets */}
              <div className="absolute top-2.5 left-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
              <div className="absolute top-2.5 right-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />

              <div className="flex items-center gap-4">
                <div className="h-14 w-14 rounded-2xl bg-[#10B981]/20 border border-[#10B981]/40 text-[#10B981] grid place-items-center shrink-0">
                  <CheckCircle2 size={32} />
                </div>
                <div>
                  <span className="font-pixel text-[9px] text-[#10B981] uppercase tracking-wider font-bold">
                    CREDENTIAL DISPATCH SUCCESS
                  </span>
                  <h3 className="font-space text-xl font-black text-[var(--text-primary)] uppercase tracking-tight leading-none mt-1">
                    Application Approved!
                  </h3>
                  <p className="font-tech text-xs text-[var(--text-secondary)] mt-1">
                    Official Driver ID issued &amp; credentials dispatched via SMTP.
                  </p>
                </div>
              </div>

              {/* Credential Data Box */}
              <div className="p-5 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)] space-y-3 font-tech text-xs">
                <div className="flex items-center justify-between py-1.5 border-b border-[var(--border-main)]/60">
                  <span className="text-[var(--text-subtle)] font-bold">Driver Name:</span>
                  <strong className="text-[var(--text-primary)] font-space font-bold">{approvalModal.name}</strong>
                </div>

                <div className="flex items-center justify-between py-1.5 border-b border-[var(--border-main)]/60">
                  <span className="text-[var(--text-subtle)] font-bold">Issued Driver ID:</span>
                  <div className="flex items-center gap-2">
                    <strong className="text-[#10B981] font-bold tracking-wider">{approvalModal.driverCode}</strong>
                    <button
                      onClick={() => copyToClipboard(approvalModal.driverCode, 'code')}
                      className="text-[var(--text-subtle)] hover:text-[var(--text-primary)] p-1 cursor-pointer"
                      title="Copy Driver ID"
                    >
                      {copiedKey === 'code' ? <Check size={14} className="text-[#10B981]" /> : <Copy size={14} />}
                    </button>
                  </div>
                </div>

                <div className="flex items-center justify-between py-1.5 border-b border-[var(--border-main)]/60">
                  <span className="text-[var(--text-subtle)] font-bold">Temporary Password:</span>
                  <div className="flex items-center gap-2">
                    <strong className="text-[#D97706] font-bold tracking-wider">{approvalModal.tempPassword}</strong>
                    <button
                      onClick={() => copyToClipboard(approvalModal.tempPassword, 'pw')}
                      className="text-[var(--text-subtle)] hover:text-[var(--text-primary)] p-1 cursor-pointer"
                      title="Copy Password"
                    >
                      {copiedKey === 'pw' ? <Check size={14} className="text-[#D97706]" /> : <Copy size={14} />}
                    </button>
                  </div>
                </div>

                <div className="flex items-center justify-between py-1.5">
                  <span className="text-[var(--text-subtle)] font-bold">Dispatched To:</span>
                  <strong className="text-[var(--text-primary)] truncate max-w-[220px]">{approvalModal.email}</strong>
                </div>
              </div>

              {/* Email Status Notification Banner */}
              <div className="p-3.5 rounded-xl bg-[#10B981]/10 border border-[#10B981]/30 font-tech text-xs text-[#10B981] flex items-center gap-2.5">
                <Send size={15} className="shrink-0" />
                <span>Encrypted credentials email transmitted to applicant over TLS Port 465 (Gmail).</span>
              </div>

              <motion.button
                whileTap={{ scale: 0.96 }}
                onClick={() => setApprovalModal(null)}
                className="w-full h-12 rounded-xl bg-[var(--text-primary)] text-[var(--card-bg)] font-space font-black text-xs uppercase tracking-wider transition hover:opacity-90 cursor-pointer shadow-md"
              >
                Close &amp; Continue
              </motion.button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ── REJECTION REASON MODAL ─────────────────────────────────────────── */}
      <AnimatePresence>
        {rejectDialogTarget && (
          <div className="fixed inset-0 z-[99999] grid place-items-center p-4 bg-black/70 backdrop-blur-md">
            <motion.div
              initial={{ scale: 0.92, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.92, opacity: 0 }}
              transition={{ type: 'spring', stiffness: 380, damping: 28 }}
              className="stamped-card bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] rounded-2xl p-6 sm:p-8 max-w-md w-full shadow-2xl space-y-5 relative"
            >
              {/* Corner Rivets */}
              <div className="absolute top-2.5 left-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />
              <div className="absolute top-2.5 right-2.5 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70" />

              <div className="flex items-center gap-3 text-[#DC2626]">
                <AlertTriangle size={24} />
                <h3 className="font-space text-lg font-black uppercase tracking-tight text-[var(--text-primary)]">
                  Reject Application
                </h3>
              </div>

              <p className="font-tech text-xs text-[var(--text-secondary)]">
                Rejecting candidate <strong className="text-[var(--text-primary)]">{rejectDialogTarget.user?.name || rejectDialogTarget.name || 'Applicant'}</strong>. Select verification reason:
              </p>

              <div className="space-y-2">
                {[
                  'Driving License details could not be verified on MoRTH Sarathi',
                  'Driving License is expired or outside valid vehicle category',
                  'Applicant regional jurisdiction outside active fleet hub',
                  'Incomplete documents / contact mismatch',
                ].map((reasonText) => (
                  <button
                    key={reasonText}
                    onClick={() => setRejectReason(reasonText)}
                    className={cn(
                      "w-full text-left p-3 rounded-xl border text-xs font-space font-bold transition cursor-pointer",
                      rejectReason === reasonText
                        ? "bg-red-500/15 border-red-500/40 text-[#DC2626]"
                        : "bg-[var(--debossed-slot)] border-[var(--border-main)] text-[var(--text-secondary)] hover:border-[var(--border-highlight)]"
                    )}
                  >
                    {reasonText}
                  </button>
                ))}
              </div>

              <input
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Or type custom reason..."
                className="w-full h-11 px-4 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)] text-xs text-[var(--text-primary)] font-space font-medium outline-none focus:border-[#DC2626]"
              />

              <div className="flex items-center gap-3 pt-2">
                <button
                  onClick={() => setRejectDialogTarget(null)}
                  className="flex-1 h-11 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)] text-[var(--text-secondary)] font-space font-bold text-xs transition cursor-pointer hover:border-[var(--border-highlight)]"
                >
                  Cancel
                </button>
                <button
                  onClick={handleConfirmReject}
                  className="flex-1 h-11 rounded-xl bg-[#DC2626] hover:bg-red-700 text-white font-space font-black text-xs uppercase tracking-wider transition cursor-pointer shadow-md shadow-red-600/20"
                >
                  Confirm Rejection
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ── CANDIDATE FULL INSPECTION REPORT MODAL ───────────────────────── */}
      <AnimatePresence>
        {inspectingReport && (() => {
          const app = inspectingReport
          const fullName = `${app.user?.firstName || ''} ${app.user?.lastName || ''}`.trim() || app.user?.name || app.name || 'Candidate Driver'
          const email = app.user?.email || app.email || 'N/A'
          const phone = app.user?.phoneNumber || app.phoneNumber || 'Not provided'
          const zone = app.user?.zone || app.zone || 'Puttur Hub'
          const dlNumber = app.licenseNumber || 'PENDING-DL'
          const badges: string[] = app.badges || []
          const appliedVehicle = badges.find(b => b.startsWith('applied_vehicle:'))?.replace('applied_vehicle:', '') || app.driverType || 'Fleet Vehicle'
          const emergencyRelation = badges.find(b => b.startsWith('emergency_relation:'))?.replace('emergency_relation:', '') || 'Parent'
          const emergencyName = app.emergencyContactName || 'Family Contact'
          const emergencyPhone = app.emergencyContactPhone || 'N/A'
          const verificationResult = verifiedDlMap[app.id]
          const isApproving = approvingId === app.id
          const isRejecting = rejectingId === app.id

          return (
            <div className="fixed inset-0 z-[99999] grid place-items-center p-4 sm:p-6 bg-black/75 backdrop-blur-md overflow-y-auto">
              <motion.div
                initial={{ scale: 0.94, opacity: 0, y: 15 }}
                animate={{ scale: 1, opacity: 1, y: 0 }}
                exit={{ scale: 0.94, opacity: 0, y: 15 }}
                transition={{ type: 'spring', stiffness: 360, damping: 28 }}
                className="stamped-card bg-[var(--card-bg)] border-[1.5px] border-[var(--border-main)] rounded-2xl max-w-2xl w-full shadow-2xl relative my-auto overflow-hidden text-[var(--text-primary)]"
              >
                {/* Mechanical Corner Rivets */}
                <div className="absolute top-3 left-3 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70 z-10" />
                <div className="absolute top-3 right-3 w-1.5 h-1.5 rounded-full bg-[var(--mechanical-screw)] opacity-70 z-10" />

                {/* Modal Header */}
                <div className="p-6 border-b border-[var(--border-main)] flex items-start justify-between gap-4 bg-[var(--debossed-slot)]/50">
                  <div className="flex items-center gap-3.5">
                    <span className="h-14 w-14 rounded-2xl bg-gradient-to-br from-[#2563EB]/20 to-[#1D4ED8]/30 border border-[#2563EB]/40 text-[#2563EB] font-space font-black text-2xl flex items-center justify-center shrink-0 shadow-inner">
                      {fullName.charAt(0).toUpperCase()}
                    </span>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-pixel text-[9px] text-[#2563EB] uppercase tracking-wider font-bold">
                          CANDIDATE DOSSIER &amp; REPORT
                        </span>
                        <span className="px-2 py-0.5 rounded-md font-pixel text-[9px] font-bold bg-[#D97706]/15 text-[#D97706] border border-[#D97706]/30">
                          AUDIT QUEUE
                        </span>
                      </div>
                      <h2 className="font-space text-xl font-black text-[var(--text-primary)] uppercase tracking-tight leading-tight mt-0.5">
                        {fullName}
                      </h2>
                      <p className="font-tech text-xs text-[var(--text-secondary)]">
                        Application Ref: <span className="font-bold text-[var(--text-primary)]">{app.id}</span>
                      </p>
                    </div>
                  </div>

                  <button
                    onClick={() => setInspectingReport(null)}
                    className="p-2 rounded-xl bg-[var(--card-bg)] hover:bg-[var(--debossed-slot)] border border-[var(--border-main)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] cursor-pointer transition"
                    title="Close Report"
                  >
                    <X size={18} />
                  </button>
                </div>

                {/* Modal Body / Report Content */}
                <div className="p-6 space-y-5 max-h-[calc(85vh-160px)] overflow-y-auto">
                  {/* Personal & Contact Profile */}
                  <div>
                    <h4 className="font-tech text-xs font-bold uppercase tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-2.5">
                      <User size={14} className="text-[#2563EB]" /> Personal &amp; Communication Details
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70">
                        <div className="font-tech text-[10px] uppercase font-bold text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                          <Mail size={12} className="text-[#2563EB]" /> Email Address
                        </div>
                        <div className="font-tech font-bold text-xs text-[var(--text-primary)] truncate">{email}</div>
                      </div>

                      <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70">
                        <div className="font-tech text-[10px] uppercase font-bold text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                          <Phone size={12} className="text-[#10B981]" /> Phone Number
                        </div>
                        <div className="font-tech font-bold text-xs text-[var(--text-primary)]">{phone}</div>
                      </div>

                      <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70">
                        <div className="font-tech text-[10px] uppercase font-bold text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                          <MapPin size={12} className="text-[#E53935]" /> Assigned Hub / Sector
                        </div>
                        <div className="font-space font-bold text-xs text-[var(--text-primary)]">{zone}</div>
                      </div>

                      <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70">
                        <div className="font-tech text-[10px] uppercase font-bold text-[var(--text-subtle)] flex items-center gap-1.5 mb-1">
                          <Clock size={12} className="text-[#D97706]" /> Application Date
                        </div>
                        <div className="font-tech font-bold text-xs text-[var(--text-primary)]">
                          {app.createdAt ? new Date(app.createdAt).toLocaleString() : 'Active Registration'}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Vehicle Fleet Profile */}
                  <div>
                    <h4 className="font-tech text-xs font-bold uppercase tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-2.5">
                      <Car size={14} className="text-[#D97706]" /> Vehicle Assignment &amp; Hardware Category
                    </h4>
                    <div className="p-4 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      <div>
                        <div className="font-space font-bold text-sm text-[var(--text-primary)]">
                          {appliedVehicle}
                        </div>
                        <div className="font-tech text-[11px] text-[var(--text-subtle)] mt-0.5">
                          Commercial Fleet Telemetry &amp; IMU Sensor Tracking Enabled
                        </div>
                      </div>
                      <VehicleSymbol type={appliedVehicle} size={22} showBadge={true} />
                    </div>
                  </div>

                  {/* Emergency Guardian Dossier */}
                  <div>
                    <h4 className="font-tech text-xs font-bold uppercase tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-2.5">
                      <ShieldAlert size={14} className="text-[#DC2626]" /> Emergency Guardian &amp; Next of Kin
                    </h4>
                    <div className="p-4 rounded-xl bg-[var(--debossed-slot)] border border-[var(--border-main)]/70 flex items-center justify-between gap-3">
                      <div>
                        <div className="font-space font-bold text-sm text-[var(--text-primary)]">
                          {emergencyName}
                        </div>
                        <div className="font-tech text-[11px] text-[var(--text-subtle)] mt-0.5">
                          Relationship: <span className="font-bold text-[var(--text-primary)]">{emergencyRelation}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-tech font-bold text-sm text-[#E53935]">{emergencyPhone}</div>
                        <span className="font-pixel text-[8px] uppercase tracking-wider px-2 py-0.5 rounded bg-red-500/10 text-red-500 font-bold border border-red-500/20">
                          Automated SOS Trigger
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* MoRTH Sarathi Registry Verification Report */}
                  <div>
                    <h4 className="font-tech text-xs font-bold uppercase tracking-wider text-[var(--text-subtle)] flex items-center gap-1.5 mb-2.5">
                      <FileCheck size={14} className="text-[#10B981]" /> MoRTH Sarathi National Registry Verification
                    </h4>
                    <div className="p-4 rounded-xl bg-[var(--debossed-slot)] border-[1.5px] border-[var(--border-main)] space-y-3">
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                        <div>
                          <div className="font-tech text-[10px] font-bold uppercase tracking-wider text-[#D97706]">
                            Driving License Number
                          </div>
                          <div className="font-tech font-black text-base text-[var(--text-primary)] tracking-wider mt-0.5">
                            {dlNumber}
                          </div>
                        </div>

                        <button
                          onClick={() => handleVerifyDl(app.id, dlNumber)}
                          disabled={verifyingDl === app.id}
                          className="px-3.5 py-2 rounded-lg bg-[var(--card-bg)] hover:border-[#D97706] text-[#D97706] font-space font-bold text-xs flex items-center gap-2 border border-[var(--border-main)] transition cursor-pointer self-start sm:self-auto shadow-sm"
                        >
                          <ShieldCheck size={15} className={cn(verifyingDl === app.id && "animate-spin")} />
                          <span>{verifyingDl === app.id ? "Querying MoRTH..." : "Run Sarathi Verify"}</span>
                        </button>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-2 border-t border-[var(--border-main)]/60 font-tech text-xs">
                        <div className="p-2.5 rounded-lg bg-[var(--card-bg)] border border-[var(--border-main)]/50">
                          <span className="text-[var(--text-subtle)] block text-[10px] uppercase font-bold">RTO Hub</span>
                          <strong className="text-[var(--text-primary)] font-space text-xs">
                            {verificationResult?.rto || 'RTO Puttur (KA-21)'}
                          </strong>
                        </div>
                        <div className="p-2.5 rounded-lg bg-[var(--card-bg)] border border-[var(--border-main)]/50">
                          <span className="text-[var(--text-subtle)] block text-[10px] uppercase font-bold">Challan History</span>
                          <strong className="text-[#10B981] font-bold text-xs">
                            {verificationResult?.challanStatus || 'ZERO CHALLANS'}
                          </strong>
                        </div>
                        <div className="p-2.5 rounded-lg bg-[var(--card-bg)] border border-[var(--border-main)]/50">
                          <span className="text-[var(--text-subtle)] block text-[10px] uppercase font-bold">License Status</span>
                          <strong className="text-[#10B981] font-bold text-xs">
                            {verificationResult?.validUntil || 'VALID & ACTIVE'}
                          </strong>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Clearance Decision Callout */}
                  <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-start gap-3">
                    <Sparkles size={18} className="text-emerald-500 shrink-0 mt-0.5" />
                    <div className="font-tech text-xs text-emerald-600 dark:text-emerald-400">
                      <strong>Automatic Clearance Recommendation:</strong> Candidate passes preliminary screening. Accepting will generate encrypted login credentials, dispatch an email via SMTP, and register the driver to the live telemetry fleet.
                    </div>
                  </div>
                </div>

                {/* Modal Footer with Accept / Reject Actions */}
                <div className="p-6 border-t border-[var(--border-main)] bg-[var(--debossed-slot)]/50 flex flex-col sm:flex-row items-center justify-between gap-3">
                  <button
                    onClick={() => setInspectingReport(null)}
                    className="w-full sm:w-auto px-5 h-12 rounded-xl bg-[var(--card-bg)] border border-[var(--border-main)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] font-space font-bold text-xs transition cursor-pointer"
                  >
                    Close Report
                  </button>

                  <div className="flex items-center gap-3 w-full sm:w-auto">
                    <motion.button
                      whileTap={{ scale: 0.94 }}
                      onClick={() => {
                        dismissNewRequestToast()
                        setRejectDialogTarget(app)
                        setRejectReason('Driving License details could not be verified on MoRTH Sarathi')
                      }}
                      disabled={isRejecting}
                      className="flex-1 sm:flex-initial px-5 h-12 rounded-xl bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-[#DC2626] font-space font-bold text-xs uppercase tracking-wider flex items-center justify-center gap-2 transition cursor-pointer disabled:opacity-50"
                    >
                      <XCircle size={16} />
                      <span>Reject</span>
                    </motion.button>

                    <motion.button
                      whileTap={{ scale: 0.94 }}
                      onClick={() => handleApprove(app)}
                      disabled={isApproving}
                      className="flex-1 sm:flex-initial px-6 h-12 rounded-xl bg-[#10B981] hover:bg-[#059669] text-white font-space font-black text-xs uppercase tracking-wider flex items-center justify-center gap-2 transition shadow-md shadow-emerald-500/20 cursor-pointer disabled:opacity-50"
                    >
                      <CheckCircle2 size={16} />
                      <span>{isApproving ? "Issuing ID..." : "Accept Request"}</span>
                    </motion.button>
                  </div>
                </div>
              </motion.div>
            </div>
          )
        })()}
      </AnimatePresence>
    </div>
  )
}
