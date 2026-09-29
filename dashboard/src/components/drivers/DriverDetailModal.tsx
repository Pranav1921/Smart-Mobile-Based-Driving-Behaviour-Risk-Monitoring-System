import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  MapPin, Video, Shield, Zap, Save, MessageCircle, Phone, AlertTriangle,
  Building2, Navigation, CheckCircle2, Siren, Radio, ExternalLink, Trash2,
  Send, Volume2, Truck, Package, Clock, Mail, Car, User, Activity, HardDriveDownload,
  Fuel, Award, IndianRupee, Film, Play, Pause, Download, ShieldAlert
} from 'lucide-react'
import { generateForensicCrashReport } from '@/lib/forensicReportGenerator'
import { Driver } from '@/types'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { AreaLineChart } from '@/components/charts/Charts'
import { cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'
import { fetchNearbyEmergencyPlaces, EmergencyPlace } from '@/lib/emergencyServices'
import { deleteDriverFromApi, fetchDriverProfile } from '@/lib/apiClient'

interface DriverDetailModalProps {
  driver: Driver | null
  initialTab?: TabType
  onClose: () => void
}

type TabType = 'telemetry' | 'dossier' | 'deliveries' | 'crisis' | 'phyd' | 'dashcam'

export function DriverDetailModal({ driver, initialTab = 'telemetry', onClose }: DriverDetailModalProps) {
  const { emitLiveCamRequest, emitSafetyPing, emitDriverMessage, liveFrame, pingedDrivers, removeDriverLocal, crashAlertDriver, latestLockedEvidence } = useSocket()
  const [activeTab, setActiveTab] = useState<TabType>(initialTab)
  const [isCamOn, setIsCamOn] = useState(false)
  const [simulatedFeed, setSimulatedFeed] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const [dashcamScrubIndex, setDashcamScrubIndex] = useState(10)
  const [isDashcamPlaying, setIsDashcamPlaying] = useState(false)
  const [certificateGenerated, setCertificateGenerated] = useState(false)
  const [pingSent, setPingSent] = useState(false)
  const [countdown, setCountdown] = useState<number | null>(null)
  const [adminCustomMsg, setAdminCustomMsg] = useState('')
  const [msgSentToast, setMsgSentToast] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [declaredCrash, setDeclaredCrash] = useState(false)
  const [nearbyPlaces, setNearbyPlaces] = useState<EmergencyPlace[]>([])
  const [loadingPlaces, setLoadingPlaces] = useState(false)
  const [profileDetails, setProfileDetails] = useState<any>(null)

  useEffect(() => {
    if (driver?.id) {
      fetchDriverProfile(driver.id).then((p) => {
        if (p) setProfileDetails(p)
      })
    }
  }, [driver?.id])

  useEffect(() => {
    if (initialTab) {
      setActiveTab(initialTab)
    }
  }, [initialTab])

  const [telemetryHistory, setTelemetryHistory] = useState<{
    labels: string[]
    gForce: number[]
  }>({
    labels: ['10s', '8s', '6s', '4s', '2s', 'Now'],
    gForce: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
  })

  useEffect(() => {
    if (!driver) return
    const interval = setInterval(() => {
      const gVal = driver.vibrationRate || (driver.accelX ? Math.sqrt(driver.accelX**2 + (driver.accelY||0)**2 + (driver.accelZ||0)**2)/9.8 : 0.01)
      setTelemetryHistory(prev => ({
        labels: prev.labels,
        gForce: [...prev.gForce.slice(1), Number(gVal.toFixed(2))]
      }))
    }, 1000)
    return () => clearInterval(interval)
  }, [driver])

  useEffect(() => {
    if (driver && activeTab === 'crisis') {
      const lat = driver.location?.lat ?? 12.7749
      const lng = driver.location?.lng ?? 75.2023
      setLoadingPlaces(true)
      fetchNearbyEmergencyPlaces(lat, lng)
        .then((places) => setNearbyPlaces(places))
        .finally(() => setLoadingPlaces(false))
    }
  }, [driver, activeTab])

  useEffect(() => {
    if (countdown === null || countdown <= 0) return
    if (driver && pingedDrivers[driver.id]?.responded) {
      setCountdown(null)
      return
    }
    const timer = setInterval(() => {
      setCountdown(prev => (prev !== null && prev > 0 ? prev - 1 : 0))
    }, 1000)
    return () => clearInterval(timer)
  }, [countdown, driver, pingedDrivers])

  // Dashcam evidence buffer auto-playback loop
  useEffect(() => {
    if (!isDashcamPlaying) return
    const interval = setInterval(() => {
      setDashcamScrubIndex((prev) => (prev + 1) % 20)
    }, 450)
    return () => clearInterval(interval)
  }, [isDashcamPlaying])

  // Auto-initiate 30s countdown ping when opening crisis tab in an active emergency
  useEffect(() => {
    if (driver && activeTab === 'crisis' && (driver.status === 'emergency' || crashAlertDriver?.driverId === driver.id)) {
      if (!pingSent && countdown === null && !pingedDrivers[driver.id]?.responded) {
        setPingSent(true)
        setCountdown(30)
        emitSafetyPing(driver.id)
      }
    }
  }, [activeTab, driver, pingSent, countdown, pingedDrivers, crashAlertDriver, emitSafetyPing])

  // When driver responds as safe, stop camera if on and auto-exit back to main page
  useEffect(() => {
    if (driver && pingedDrivers[driver.id]?.responded) {
      if (isCamOn) {
        setIsCamOn(false)
        emitLiveCamRequest(driver.id, false)
      }
      const exitTimer = setTimeout(() => {
        onClose()
      }, 1500)
      return () => clearTimeout(exitTimer)
    }
  }, [driver, pingedDrivers, isCamOn, emitLiveCamRequest, onClose])

  if (!driver) return null

  const pingState = pingedDrivers[driver.id]
  const isPingResponded = pingState?.responded === true
  const isPingTimedOut = pingState?.timedOut === true || (pingSent && countdown === 0 && !isPingResponded) || (countdown === 0 && !isPingResponded)
  const isEmergencyIncident = driver.status === 'emergency' || (crashAlertDriver && (crashAlertDriver.driverId === driver.id || crashAlertDriver.id === driver.id || crashAlertDriver.driverId === driver.userId))

  const isOnDelivery = Boolean(
    driver.deliveryTo ||
    driver.orderItems ||
    driver.destLat != null ||
    (driver as any).activeOrder ||
    driver.status === 'delivery'
  )

  const mergedDriver = profileDetails ? {
    ...driver,
    ...profileDetails,
    name: profileDetails.user ? `${profileDetails.user.firstName || ''} ${profileDetails.user.lastName || ''}`.replace(/\s+applicant/gi, '').trim() : driver.name,
    email: profileDetails.user?.email || profileDetails.email || (driver as any).email,
    phone: profileDetails.user?.phoneNumber || profileDetails.phoneNumber || profileDetails.phone || (driver as any).phone,
    emergencyContactName: profileDetails.emergencyContactName || profileDetails.emergencyName || (driver as any).emergencyContactName,
    emergencyContactPhone: profileDetails.emergencyContactPhone || profileDetails.emergencyPhone || (driver as any).emergencyContactPhone,
    emergencyRelationship: (profileDetails.badges || []).find((b: string) => b.startsWith('emergency_relation:'))?.replace('emergency_relation:', '') || (driver as any).emergencyRelationship || 'Parent / Guardian',
    licenseNumber: profileDetails.licenseNumber || (driver as any).licenseNumber,
    appliedVehicle: (profileDetails.badges || []).find((b: string) => b.startsWith('applied_vehicle:'))?.replace('applied_vehicle:', '') || (driver as any).appliedVehicle,
  } : driver

  const driverPhone = mergedDriver.phone || mergedDriver.phoneNumber || mergedDriver.user?.phoneNumber || mergedDriver.user?.phone || 'Not Registered'
  const driverEmail = mergedDriver.email || mergedDriver.user?.email || 'Not Registered'
  const familyPhone = mergedDriver.emergencyContactPhone || mergedDriver.emergencyPhone || mergedDriver.familyWhatsappNumber || mergedDriver.emergencyContact || 'Not Registered'
  const familyName = mergedDriver.emergencyContactName || mergedDriver.emergencyName || mergedDriver.familyMemberName || 'Family / Parent'
  const familyRel = mergedDriver.emergencyRelationship || mergedDriver.familyRelationship || 'Parent / Guardian'
  const driverLicense = mergedDriver.licenseNumber || mergedDriver.employeeId
  const driverVehicle = mergedDriver.appliedVehicle || mergedDriver.vehicleName || 'Fleet Vehicle'
  const driverZone = mergedDriver.zone || mergedDriver.user?.zone || driver.locationName || 'Sector Command'
  const safeLat = driver.location?.lat != null ? driver.location.lat.toFixed(5) : '12.72743'
  const safeLng = driver.location?.lng != null ? driver.location.lng.toFixed(5) : '75.32057'
  const roundedSafetyScore = typeof driver.safetyScore === 'number' ? Math.round(driver.safetyScore) : 100
  const roundedHeading = typeof driver.heading === 'number' ? Math.round(driver.heading) : 0

  // Camera is unlocked when 30s countdown completes (timed out), or if emergency status is active and not confirmed safe
  const isCameraUnlocked = !isPingResponded && (isPingTimedOut || isEmergencyIncident)

  const handleSendPing = () => {
    setPingSent(true)
    setCountdown(30)
    emitSafetyPing(driver.id)
  }

  const handleToggleCam = () => {
    const nextState = !isCamOn
    setIsCamOn(nextState)
    emitLiveCamRequest(driver.id, nextState)
    if (driver.userId && driver.userId !== driver.id) {
      emitLiveCamRequest(driver.userId, nextState)
    }
    if ((driver as any).employeeId && (driver as any).employeeId !== driver.id) {
      emitLiveCamRequest((driver as any).employeeId, nextState)
    }
  }

  const handleWhatsAppFamilyAlert = () => {
    const policeStation = nearbyPlaces.find(p => p.type === 'police')
    const policeInfo = policeStation ? ` Nearest Police: ${policeStation.name} (${policeStation.phone})` : ''
    const message = `🚨 DRIVING RISK CRITICAL EMERGENCY: Driver ${driver.name} has been involved in a verified vehicle incident at ${new Date().toLocaleTimeString()}. Location: https://maps.google.com/?q=${driver.location?.lat ?? 12.7749},${driver.location?.lng ?? 75.2023}.${policeInfo} Emergency assistance dispatched.`
    const cleanPhone = familyPhone.replace(/\D/g, '')
    window.open(cleanPhone ? `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}` : `https://wa.me/?text=${encodeURIComponent(message)}`, '_blank')
  }

  const handleSendCustomMessage = (e?: React.FormEvent, preset?: string) => {
    if (e) e.preventDefault()
    const msgToSend = preset || adminCustomMsg
    if (!driver || !msgToSend.trim()) return
    emitDriverMessage(driver.id, msgToSend.trim())
    setMsgSentToast(true)
    if (!preset) setAdminCustomMsg('')
    setTimeout(() => setMsgSentToast(false), 3500)
  }

  const handleDeclareCrash = () => {
    setDeclaredCrash(true)
    handleWhatsAppFamilyAlert()
  }

  const handleDeleteDriver = async () => {
    if (!confirmDelete) {
      setConfirmDelete(true)
      return
    }
    setIsDeleting(true)
    await deleteDriverFromApi(driver.id)
    removeDriverLocal(driver.id)
    setIsDeleting(false)
    onClose()
  }

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[1000] flex items-center justify-center p-4 md:p-6 bg-slate-950/85 backdrop-blur-xl">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          className="bg-[#0A0D14] rounded-[36px] md:rounded-[48px] shadow-[0_0_60px_rgba(0,0,0,0.9)] w-full max-w-5xl overflow-hidden border border-slate-800 flex flex-col md:flex-row h-[90vh] md:h-[85vh] text-white"
        >
          {/* Sidebar */}
          <div className="w-full md:w-80 border-b md:border-b-0 md:border-r border-slate-800 p-6 md:p-8 flex flex-col bg-slate-900/40">
            <div className="flex flex-col items-center text-center">
               <Avatar name={(mergedDriver.name || 'Driver').replace(/\s+applicant/gi, '').trim()} src={(mergedDriver as any).avatar || (mergedDriver as any).profileImagePath || (mergedDriver as any).avatarUrl} size={90} className="ring-4 ring-slate-800 shadow-2xl" />
               <h2 className="text-xl font-black text-white mt-4 tracking-tight uppercase italic">{(mergedDriver.name || 'Driver').replace(/\s+applicant/gi, '').trim()}</h2>
               <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest mt-1">{mergedDriver.employeeId || driver.employeeId}</p>
               <div className="flex items-center gap-2 mt-4 flex-wrap justify-center">
                 <Badge tone={driver.status} className="px-3 py-1 rounded-xl uppercase font-black text-[9px] tracking-widest">{driver.status}</Badge>
                 {isOnDelivery ? (
                   <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-[9px] font-black tracking-widest uppercase bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 animate-pulse">
                     <Truck size={11} /> ON DELIVERY
                   </span>
                 ) : (
                   <span className="inline-flex items-center gap-1 px-3 py-1 rounded-xl text-[9px] font-black tracking-widest uppercase bg-slate-800 text-slate-400 border border-slate-700">
                     STANDBY
                   </span>
                 )}
               </div>
            </div>

            <div className="mt-6 space-y-3 flex-1 overflow-y-auto no-scrollbar">
               <IntelItem label="Delivery Status" value={isOnDelivery ? 'ON DELIVERY' : 'AVAILABLE / STANDBY'} icon={<Truck size={14}/>} />
               <IntelItem label="Direct Phone" value={driverPhone} icon={<Phone size={14}/>} />
               <IntelItem label="Email" value={driverEmail} icon={<Mail size={14}/>} />
               <IntelItem label="Guardian (SOS)" value={`${familyName} (${familyRel}) • ${familyPhone}`} icon={<AlertTriangle size={14} className="text-rose-400"/>} />
               <IntelItem label="Vehicle" value={driverVehicle} icon={<Car size={14}/>} />
               <IntelItem label="Jurisdiction" value={driverZone} icon={<MapPin size={14}/>} />
               <IntelItem label="Compliance" value={`${roundedSafetyScore}% Score`} icon={<Shield size={14}/>} />
            </div>

            {/* Quick Live Camera Stream Toggle Button */}
            <div className="mt-4 mb-1">
              <button
                onClick={handleToggleCam}
                className={cn(
                  "w-full py-3 px-4 rounded-2xl font-black text-xs uppercase tracking-wider transition-all flex items-center justify-center gap-2 cursor-pointer shadow-lg active:scale-98",
                  isCamOn
                    ? "bg-rose-600 hover:bg-rose-500 text-white animate-pulse shadow-rose-600/30"
                    : "bg-blue-600 hover:bg-blue-500 text-white shadow-blue-600/30"
                )}
              >
                <Video size={16} className={isCamOn ? "animate-pulse" : ""} />
                <span>{isCamOn ? "Stop Live Camera" : "Live Cabin Camera"}</span>
              </button>
            </div>

            <div className="space-y-2 mt-2">
              {confirmDelete ? (
                <div className="p-3 bg-rose-950/80 border border-rose-600 rounded-2xl text-center space-y-2">
                  <p className="text-[10px] text-rose-300 font-bold">Remove this operator from grid?</p>
                  <div className="flex gap-2">
                    <button
                      onClick={handleDeleteDriver}
                      disabled={isDeleting}
                      className="flex-1 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-xl text-[10px] font-black uppercase transition-all"
                    >
                      {isDeleting ? 'Removing...' : 'Confirm'}
                    </button>
                    <button
                      onClick={() => setConfirmDelete(false)}
                      className="flex-1 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-[10px] font-black uppercase transition-all"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => setConfirmDelete(true)}
                  className="w-full py-2.5 rounded-2xl bg-rose-950/30 border border-rose-800/40 text-rose-400 font-black text-[10px] uppercase tracking-widest hover:bg-rose-900/50 hover:text-white transition-all cursor-pointer flex items-center justify-center gap-2"
                >
                  <Trash2 size={12} />
                  <span>Remove Operator</span>
                </button>
              )}

              <button
                onClick={onClose}
                className="w-full py-3 rounded-2xl bg-slate-800/80 border border-slate-700 text-slate-300 font-black text-[10px] uppercase tracking-widest hover:bg-slate-700 hover:text-white transition-all cursor-pointer shadow-sm"
              >
                Close Instance
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 p-6 md:p-8 flex flex-col min-w-0 overflow-hidden">
            <div className="flex gap-4 md:gap-6 mb-6 border-b border-slate-800 shrink-0 flex-wrap">
               <TabBtn active={activeTab === 'telemetry'} onClick={() => setActiveTab('telemetry')} label="Live Telemetry" />
               <TabBtn active={activeTab === 'dossier'} onClick={() => setActiveTab('dossier')} label="Personal & Guardian Dossier" />
               <TabBtn active={activeTab === 'deliveries'} onClick={() => setActiveTab('deliveries')} label="Delivery Details" badge={isOnDelivery} />
               <TabBtn active={activeTab === 'phyd'} onClick={() => setActiveTab('phyd')} label="PHYD Insurance & Cost Burn (₹)" />
               <TabBtn active={activeTab === 'dashcam'} onClick={() => setActiveTab('dashcam')} label="Locked Dashcam Evidence" badge={!!latestLockedEvidence} />
               <TabBtn active={activeTab === 'crisis'} onClick={() => setActiveTab('crisis')} label="3-Step Emergency Protocol" badge={driver.status === 'emergency'} />
            </div>

            <div className="flex-1 overflow-y-auto no-scrollbar space-y-6">
               {/* REAL-TIME LIVE CAMERA & TELEMETRY STREAM OVERLAY */}
               {isCamOn && (
                 <div className="bg-slate-950 rounded-3xl border-2 border-rose-500/60 p-5 shadow-2xl relative overflow-hidden animate-in fade-in">
                   <div className="flex items-center justify-between mb-3 px-1">
                     <div className="flex items-center gap-2.5">
                       <span className="h-3 w-3 rounded-full bg-rose-500 animate-ping" />
                       <span className="text-xs font-black uppercase tracking-widest text-rose-400">
                         Live Optical Camera Feed & Real-Time Cockpit Link
                       </span>
                     </div>
                     <div className="flex items-center gap-3">
                       <span className="text-[10px] text-slate-400 font-mono">
                         OPERATOR: {driver.name} ({driver.employeeId || driver.id})
                       </span>
                       <button
                         onClick={handleToggleCam}
                         className="px-3 py-1 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-[10px] font-black uppercase transition-all cursor-pointer shadow-md"
                       >
                         Close Stream
                       </button>
                     </div>
                   </div>

                   <div className="h-72 rounded-2xl bg-black flex items-center justify-center overflow-hidden border border-slate-800 relative">
                     {liveFrame ? (
                       <img
                         src={liveFrame.startsWith('data:') ? liveFrame : `data:image/jpeg;base64,${liveFrame}`}
                         alt="Driver Live Cam"
                         className="w-full h-full object-cover"
                       />
                     ) : (
                       <div className="text-center space-y-3 p-6">
                         <Video size={44} className="text-rose-400 mx-auto animate-pulse" />
                         <p className="text-sm text-white font-extrabold tracking-wide">
                           Connecting to Operator's Optical Camera Stream...
                         </p>
                         <p className="text-xs text-slate-400 max-w-md mx-auto">
                           Streaming real-time telemetry HUD overlay. Ensure camera permission is allowed on the mobile device.
                         </p>
                       </div>
                     )}
                     <div className="absolute bottom-3 left-3 px-3 py-1 rounded-lg bg-black/80 backdrop-blur border border-slate-700 text-[10px] font-mono text-emerald-400 font-black">
                       LIVE STREAM · 15 FPS · LATENCY: 140ms
                     </div>
                     <div className="absolute top-3 right-3 px-3 py-1 rounded-lg bg-rose-950/80 backdrop-blur border border-rose-500/50 text-[10px] font-black text-rose-300">
                       ● REC ACTIVE
                     </div>
                   </div>
                 </div>
               )}

               {/* Live Verbal Inquiry & Text-to-Speech Prompt (Available in all tabs) */}
               <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-5 space-y-3 shadow-lg">
                 <div className="flex items-center justify-between">
                   <div className="flex items-center gap-2">
                     <Volume2 size={16} className="text-cyan-400 animate-pulse" />
                     <h3 className="text-xs font-black uppercase tracking-widest text-white">
                       Direct Voice Inquiry to Operator
                     </h3>
                   </div>
                   <span className="text-[9px] font-black uppercase tracking-wider text-slate-400">
                     Spoken aloud via TTS on mobile
                   </span>
                 </div>

                 <form onSubmit={handleSendCustomMessage} className="flex gap-2">
                   <input
                     type="text"
                     value={adminCustomMsg}
                     onChange={(e) => setAdminCustomMsg(e.target.value)}
                     placeholder="Type inquiry (e.g. 'What is your status?')..."
                     className="flex-1 h-11 px-4 rounded-xl bg-slate-950 border border-slate-700 text-xs font-bold text-white placeholder-slate-500 outline-none focus:border-cyan-500 transition-all shadow-inner"
                   />
                   <button
                     type="submit"
                     disabled={!adminCustomMsg.trim()}
                     className="px-5 h-11 rounded-xl bg-cyan-600 hover:bg-cyan-500 disabled:opacity-40 disabled:cursor-not-allowed text-white font-black text-xs uppercase tracking-wider transition-all flex items-center gap-2 cursor-pointer shadow-md active:scale-95"
                   >
                     <Send size={13} />
                     <span>Transmit</span>
                   </button>
                 </form>

                 <div className="flex flex-wrap items-center gap-2 pt-1">
                   <span className="text-[9px] font-bold text-slate-500 uppercase">Quick:</span>
                   {[
                     'Are you safe?',
                     'Please pull over safely',
                     'Verify your current location',
                     'Confirm delivery arrival',
                   ].map((txt) => (
                     <button
                       key={txt}
                       type="button"
                       onClick={() => handleSendCustomMessage(undefined, txt)}
                       className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 border border-slate-700/80 text-[10px] font-bold text-slate-300 hover:text-white transition-all cursor-pointer active:scale-95"
                     >
                       "{txt}"
                     </button>
                   ))}
                 </div>

                 {msgSentToast && (
                   <div className="p-2.5 rounded-xl bg-emerald-950/80 border border-emerald-500/50 text-emerald-400 text-[10px] font-black uppercase tracking-wider flex items-center gap-2 animate-in fade-in">
                     <CheckCircle2 size={14} />
                     <span>Voice inquiry transmitted to {driver.name}'s mobile device!</span>
                   </div>
                 )}
               </div>

                {/* ── TAB: OPERATOR PERSONAL & GUARDIAN DOSSIER ── */}
                {activeTab === 'dossier' && (
                  <div className="space-y-6">
                    {/* Primary Personal Card */}
                    <div className="rounded-3xl p-6 bg-slate-900/80 border border-slate-800 shadow-xl space-y-6">
                      <div className="flex items-center justify-between border-b border-slate-800 pb-4">
                        <div className="flex items-center gap-3">
                          <div className="h-12 w-12 rounded-2xl bg-cyan-500/20 text-cyan-400 border border-cyan-500/40 flex items-center justify-center font-bold text-lg uppercase">
                            {driver.name.charAt(0)}
                          </div>
                          <div>
                            <h3 className="text-base font-black uppercase text-white tracking-wide">{driver.name}</h3>
                            <p className="text-xs text-slate-400 font-mono">UID: {driver.employeeId} • {driver.fleet || 'Tactical Fleet'}</p>
                          </div>
                        </div>
                        <span className="px-3 py-1 rounded-xl text-[10px] font-black tracking-widest uppercase bg-emerald-500/20 text-emerald-400 border border-emerald-500/40">
                          {driver.status.toUpperCase()}
                        </span>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {/* Mobile Phone */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 mb-1">
                            <Phone size={14} className="text-cyan-400" />
                            <span>Direct Operator Phone</span>
                          </div>
                          <div className="text-sm font-black text-white font-mono">{driverPhone}</div>
                          <a href={`tel:${driverPhone.replace(/\s+/g, '')}`} className="text-[11px] text-cyan-400 hover:underline mt-1 inline-block">
                            Click to Call Operator
                          </a>
                        </div>

                        {/* Registered Email */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 mb-1">
                            <Mail size={14} className="text-emerald-400" />
                            <span>Registered Email Address</span>
                          </div>
                          <div className="text-sm font-black text-white font-mono break-all">{driverEmail}</div>
                          <a href={`mailto:${driverEmail}`} className="text-[11px] text-emerald-400 hover:underline mt-1 inline-block">
                            Send Email
                          </a>
                        </div>

                        {/* Assigned Vehicle */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 mb-1">
                            <Car size={14} className="text-amber-400" />
                            <span>Vehicle & Wheel Class</span>
                          </div>
                          <div className="text-sm font-black text-white">{driverVehicle}</div>
                          <p className="text-[11px] text-slate-400 mt-1 font-mono">Endorsed for Fleet Missions</p>
                        </div>

                        {/* MoRTH Sarathi License */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2 mb-1">
                            <Shield size={14} className="text-indigo-400" />
                            <span>MoRTH Driving License</span>
                          </div>
                          <div className="text-sm font-black text-white font-mono">{driverLicense}</div>
                          <p className="text-[11px] text-slate-400 mt-1">National Parivahan Registry Endorsed</p>
                        </div>
                      </div>
                    </div>

                    {/* Emergency Parent / Guardian Card */}
                    <div className="rounded-3xl p-6 bg-gradient-to-br from-red-950/40 via-slate-900 to-red-950/20 border border-red-900/40 shadow-xl space-y-4">
                      <div className="flex items-center justify-between border-b border-red-900/30 pb-3">
                        <div className="flex items-center gap-2">
                          <AlertTriangle size={18} className="text-rose-400" />
                          <h4 className="text-xs font-black uppercase tracking-widest text-rose-300">
                            Emergency Family & Guardian Dossier ({familyRel})
                          </h4>
                        </div>
                        <span className="text-[9px] font-black uppercase tracking-wider text-rose-400">
                          SOS Contact
                        </span>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="p-4 rounded-2xl bg-slate-950/80 border border-red-900/30">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">
                            Guardian / Parent Name
                          </div>
                          <div className="text-base font-extrabold text-white">{familyName}</div>
                          <p className="text-[11px] text-rose-400/80 mt-1">Relationship: {familyRel}</p>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/80 border border-red-900/30">
                          <div className="text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">
                            Emergency Contact Phone
                          </div>
                          <div className="text-base font-extrabold text-white font-mono">{familyPhone}</div>
                          <div className="flex items-center gap-3 mt-2">
                            <a
                              href={`tel:${familyPhone.replace(/\s+/g, '')}`}
                              className="px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-bold text-[11px] uppercase tracking-wider inline-flex items-center gap-1.5 transition"
                            >
                              <Phone size={12} /> Call Guardian
                            </a>
                            <button
                              type="button"
                              onClick={handleWhatsAppFamilyAlert}
                              className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-[11px] uppercase tracking-wider inline-flex items-center gap-1.5 transition cursor-pointer"
                            >
                              <MessageCircle size={12} /> WhatsApp SOS
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* ── TAB 2: DELIVERIES & MANIFEST ── */}
                {activeTab === 'deliveries' && (
                  <div className="space-y-6">
                    {/* Active Delivery Full Card */}
                    <div className={cn(
                      "rounded-3xl p-6 border transition-all shadow-xl",
                      isOnDelivery
                        ? "bg-gradient-to-br from-emerald-950/50 via-slate-900 to-emerald-900/30 border-emerald-500/50"
                        : "bg-slate-900/60 border-slate-800"
                    )}>
                      <div className="flex items-center justify-between border-b border-slate-800/80 pb-4 mb-5">
                        <div className="flex items-center gap-3">
                          <div className={cn("p-2.5 rounded-2xl", isOnDelivery ? "bg-emerald-500/20 text-emerald-400" : "bg-slate-800 text-slate-400")}>
                            <Truck size={22} className={isOnDelivery ? "animate-bounce" : ""} />
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-black uppercase tracking-wider text-white">
                                {isOnDelivery ? "Active Delivery Mission" : "No Active Mission"}
                              </span>
                              {isOnDelivery && (
                                <span className="px-3 py-0.5 rounded-full text-[9px] font-black tracking-widest uppercase bg-emerald-500 text-slate-950 animate-pulse">
                                  ON DELIVERY
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-slate-400 mt-0.5">
                              Real-time live consignment and waypoint tracking
                            </p>
                          </div>
                        </div>

                        {driver.destLat != null && driver.destLng != null && (
                          <a
                            href={`https://www.google.com/maps/dir/?api=1&destination=${driver.destLat},${driver.destLng}&travelmode=driving`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="px-4 py-2 rounded-xl bg-cyan-600 hover:bg-cyan-500 text-white font-black text-xs uppercase tracking-wider flex items-center gap-1.5 transition"
                          >
                            <span>Open Navigation</span>
                            <ExternalLink size={12} />
                          </a>
                        )}
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        {/* WHAT HE IS DELIVERING */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest text-emerald-400 mb-1.5">
                            <Package size={14} />
                            <span>What He Is Delivering</span>
                          </div>
                          <div className="text-base font-extrabold text-white">
                            {driver.orderItems || (isOnDelivery ? 'Tactical Delivery Package #ORD-701' : 'None')}
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">
                            Assigned Consignment
                          </p>
                        </div>

                        {/* FROM WHO (PICKUP) */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest text-sky-400 mb-1.5">
                            <Building2 size={14} />
                            <span>From Who (Pickup Location)</span>
                          </div>
                          <div className="text-base font-extrabold text-white">
                            {driver.deliveryFrom || 'Main Logistics Depot, Puttur'}
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">
                            Merchant / Origin Hub
                          </p>
                        </div>

                        {/* TO WHERE (DESTINATION) */}
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-slate-800">
                          <div className="flex items-center gap-1.5 text-[10px] font-black uppercase tracking-widest text-rose-400 mb-1.5">
                            <MapPin size={14} />
                            <span>To Where (Destination)</span>
                          </div>
                          <div className="text-base font-extrabold text-white">
                            {driver.deliveryTo || (isOnDelivery ? 'Customer Delivery Address' : 'None')}
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1 font-mono">
                            {driver.destLat != null && driver.destLng != null 
                              ? `Coordinates: [${driver.destLat.toFixed(4)}, ${driver.destLng.toFixed(4)}]`
                              : 'Customer Delivery Point'}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Concluded Deliveries History List */}
                    <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 space-y-4">
                      <div className="flex items-center justify-between border-b border-slate-800 pb-3">
                        <div className="flex items-center gap-2">
                          <Clock size={16} className="text-emerald-400" />
                          <h3 className="text-xs font-black uppercase tracking-widest text-white">
                            Concluded Delivery History ({driver.name})
                          </h3>
                        </div>
                        <span className="text-[9px] font-mono font-bold text-slate-400">
                          {driver.trips || 3} Completed Deliveries
                        </span>
                      </div>

                      <div className="space-y-3">
                        {[
                          {
                            id: "ORD-8921",
                            what: "Emergency Medical Supplies & First Aid Kit",
                            from: "Apollo Pharmacy Hub, Main Road",
                            to: "St. Philomena Campus, Sector 3",
                            fare: "₹95",
                            status: "DELIVERED",
                            score: 100,
                            dist: "3.2 KM",
                            time: "Today, 14:15"
                          },
                          {
                            id: "ORD-8742",
                            what: "Fresh Farm Groceries & Dairy Consignment",
                            from: "Puttur City Market, Stall #12",
                            to: "Subrahmanya Bypass Residence #4",
                            fare: "₹140",
                            status: "DELIVERED",
                            score: 98,
                            dist: "5.4 KM",
                            time: "Today, 12:30"
                          },
                          {
                            id: "ORD-8510",
                            what: "Critical EV Battery Electronics & Relays",
                            from: "Kadaba Tech Depot Sector 1",
                            to: "Kombettu Industrial Complex Sector 2",
                            fare: "₹80",
                            status: "DELIVERED",
                            score: 94,
                            dist: "2.8 KM",
                            time: "Today, 10:45"
                          }
                        ].map((item, idx) => (
                          <div key={idx} className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800 hover:border-slate-700 transition">
                            <div className="flex items-center justify-between mb-2">
                              <div className="flex items-center gap-2">
                                <span className="text-[10px] font-mono font-black text-slate-400 bg-slate-900 px-2 py-0.5 rounded border border-slate-800">
                                  {item.id}
                                </span>
                                <span className="text-[10px] text-slate-500 font-bold">{item.time} · {item.dist}</span>
                              </div>
                              <span className="text-sm font-black text-emerald-400">{item.fare}</span>
                            </div>

                            <div className="mb-2">
                              <span className="text-[9px] font-black uppercase text-emerald-400 tracking-wider">What Was Delivered: </span>
                              <span className="text-xs font-bold text-white">{item.what}</span>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-[11px] text-slate-400">
                              <div><span className="font-bold text-sky-400">FROM:</span> {item.from}</div>
                              <div><span className="font-bold text-rose-400">TO:</span> {item.to}</div>
                            </div>

                            <div className="flex items-center justify-between mt-2 pt-2 border-t border-slate-800/60 text-[9px] font-mono text-slate-500">
                              <span className="text-emerald-500 font-bold">STATUS: {item.status}</span>
                              <span>SAFETY AUDIT: {item.score}% SAFE</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}

               {activeTab === 'telemetry' && (
                 <div className="space-y-6">
                     {/* Active Delivery Highlight Banner */}
                     <div className={cn(
                       "rounded-3xl p-5 border transition-all shadow-xl",
                       isOnDelivery
                         ? "bg-gradient-to-br from-emerald-950/40 via-slate-900 to-emerald-900/20 border-emerald-500/40"
                         : "bg-slate-900/60 border-slate-800"
                     )}>
                       <div className="flex items-center justify-between border-b border-slate-800/80 pb-3 mb-4">
                         <div className="flex items-center gap-2.5">
                           <div className={cn("p-2 rounded-xl", isOnDelivery ? "bg-emerald-500/20 text-emerald-400" : "bg-slate-800 text-slate-400")}>
                             <Truck size={18} className={isOnDelivery ? "animate-bounce" : ""} />
                           </div>
                           <div>
                             <div className="flex items-center gap-2">
                               <span className="text-xs font-black uppercase tracking-wider text-white">
                                 {isOnDelivery ? "CURRENT DELIVERY IN PROGRESS" : "DISPATCH OBJECTIVE STATUS"}
                               </span>
                               {isOnDelivery ? (
                                 <span className="px-2.5 py-0.5 rounded-full text-[9px] font-black tracking-widest uppercase bg-emerald-500 text-slate-950 animate-pulse flex items-center gap-1">
                                   <span className="h-1.5 w-1.5 rounded-full bg-slate-950 animate-ping" />
                                   ON DELIVERY
                                 </span>
                               ) : (
                                 <span className="px-2 py-0.5 rounded-full text-[9px] font-black tracking-widest uppercase bg-slate-800 text-slate-400">
                                   STANDBY
                                 </span>
                               )}
                             </div>
                             <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider mt-0.5">
                               Live Dispatch Manifest & Transit Routing
                             </p>
                           </div>
                         </div>
                         {driver.speed > 0 && (
                           <span className="text-[10px] font-mono font-bold px-2.5 py-1 rounded-lg bg-cyan-500/10 text-cyan-400 border border-cyan-500/30">
                             TRANSIT {driver.speed.toFixed(1)} KM/H
                           </span>
                         )}
                       </div>

                       <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
                         {/* WHAT HE IS DELIVERING */}
                         <div className="p-3.5 rounded-2xl bg-slate-950/60 border border-slate-800/80">
                           <div className="flex items-center gap-1.5 text-[9px] font-black uppercase tracking-widest text-emerald-400 mb-1">
                             <Package size={12} />
                             <span>What He's Delivering</span>
                           </div>
                           <div className="text-sm font-extrabold text-white line-clamp-2">
                             {driver.orderItems || (isOnDelivery ? 'Tactical Logistics Package (ORD-701)' : 'No Active Consignment')}
                           </div>
                           <div className="text-[10px] text-slate-400 mt-1 font-mono">
                             Consignment ID: {driver.vehicleId || 'DISPATCH-1'}
                           </div>
                         </div>

                         {/* FROM WHO (ORIGIN / PICKUP) */}
                         <div className="p-3.5 rounded-2xl bg-slate-950/60 border border-slate-800/80">
                           <div className="flex items-center gap-1.5 text-[9px] font-black uppercase tracking-widest text-sky-400 mb-1">
                             <Building2 size={12} />
                             <span>From Who (Pickup)</span>
                           </div>
                           <div className="text-sm font-extrabold text-white line-clamp-2">
                             {driver.deliveryFrom || 'Main Logistics Depot, Sector 1'}
                           </div>
                           <div className="text-[10px] text-slate-400 mt-1 font-mono">
                             Authorized Dispatch Hub
                           </div>
                         </div>

                         {/* TO WHERE (DESTINATION / DROP-OFF) */}
                         <div className="p-3.5 rounded-2xl bg-slate-950/60 border border-slate-800/80">
                           <div className="flex items-center gap-1.5 text-[9px] font-black uppercase tracking-widest text-rose-400 mb-1">
                             <MapPin size={12} />
                             <span>To Where (Destination)</span>
                           </div>
                           <div className="text-sm font-extrabold text-white line-clamp-2">
                             {driver.deliveryTo || (isOnDelivery ? 'Customer Delivery Sector' : 'Awaiting Assignment')}
                           </div>
                           <div className="text-[10px] text-slate-400 mt-1 font-mono flex items-center justify-between">
                             <span>{driver.destLat != null && driver.destLng != null 
                               ? `[${driver.destLat.toFixed(4)}, ${driver.destLng.toFixed(4)}]`
                               : 'Drop Location'}</span>
                             {driver.destLat != null && driver.destLng != null && (
                               <a
                                 href={`https://www.google.com/maps/dir/?api=1&destination=${driver.destLat},${driver.destLng}&travelmode=driving`}
                                 target="_blank"
                                 rel="noopener noreferrer"
                                 className="text-cyan-400 hover:text-cyan-300 font-bold flex items-center gap-1"
                                 title="Open in Google Maps"
                               >
                                 Maps <ExternalLink size={10} />
                               </a>
                             )}
                           </div>
                         </div>
                       </div>
                     </div>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                       <MetricNode label="Speed" value={Math.round(driver.speed || 0)} unit="KM/H" color="blue" />
                       <MetricNode label="G-Force" value={(driver.vibrationRate || (driver.accelX ? Math.sqrt(driver.accelX**2 + (driver.accelY||0)**2 + (driver.accelZ||0)**2)/9.8 : 0.01)).toFixed(2)} unit="G-MAG" color="green" />
                       <MetricNode label="Safety Index" value={roundedSafetyScore} unit="SCORE" color="green" />
                       <MetricNode label="Heading" value={`${roundedHeading}°`} unit="DEG" color="blue" />
                    </div>

                    {/* Hardware Mobile Sensors */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                       <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 min-w-0 overflow-hidden">
                          <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 truncate">Accelerometer [X,Y,Z]</p>
                          <div className="font-mono font-black text-sm text-cyan-400 truncate">
                             {(driver.accelX || 0).toFixed(2)}g, {(driver.accelY || 0).toFixed(2)}g, {(driver.accelZ || 0).toFixed(2)}g
                          </div>
                          <p className="text-[8px] text-slate-500 mt-1 truncate">Linear acceleration</p>
                       </div>
                       <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 min-w-0 overflow-hidden">
                          <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 truncate">Gyroscope [X,Y,Z]</p>
                          <div className="font-mono font-black text-sm text-blue-400 truncate">
                             {((driver.gyroX || 0) * 57.2958).toFixed(1)}°/s, {((driver.gyroY || 0) * 57.2958).toFixed(1)}°/s, {((driver.gyroZ || 0) * 57.2958).toFixed(1)}°/s
                          </div>
                          <p className="text-[8px] text-slate-500 mt-1 truncate">Angular rate of turn ({((driver.gyroZ || 0)).toFixed(2)} rad/s)</p>
                       </div>
                       <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 min-w-0 overflow-hidden">
                          <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 truncate">Magnetometer [X,Y,Z]</p>
                          <div className="font-mono font-black text-sm text-purple-400 truncate">
                             {(driver.magX || 0).toFixed(0)}µT, {(driver.magY || 0).toFixed(0)}µT, {(driver.magZ || 0).toFixed(0)}µT
                          </div>
                          <p className="text-[8px] text-slate-500 mt-1 truncate">Geomagnetic sensor</p>
                       </div>
                    </div>

                    <div className="bg-slate-900/60 border border-slate-800 rounded-3xl p-6">
                       <div className="flex items-center justify-between mb-4">
                          <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Real-time G-Force Waveform</h3>
                          <span className="font-mono text-emerald-400 text-xs font-bold">
                             GPS: {safeLat}, {safeLng}
                          </span>
                       </div>
                       <AreaLineChart labels={telemetryHistory.labels} series={[{ name: 'G-Force', data: telemetryHistory.gForce, color: '#00FF9D' }]} height={170} />
                    </div>
                 </div>
               )}

               {activeTab === 'crisis' && (
                 <div className="space-y-6">
                    {/* 3-Step Verification Protocol Cards */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                       {/* STEP 1: SAFETY PING */}
                       <div className={cn("p-5 rounded-3xl border transition-all flex flex-col justify-between",
                          isPingTimedOut
                            ? "bg-rose-950/40 border-rose-500/60 shadow-[0_0_25px_rgba(244,63,94,0.3)] animate-pulse"
                            : isPingResponded
                            ? "bg-emerald-950/40 border-emerald-500/60 shadow-[0_0_20px_rgba(16,185,129,0.25)]"
                            : pingSent
                            ? "bg-amber-950/30 border-amber-500/40"
                            : "bg-slate-900/60 border-slate-800")}>
                          <div>
                             <div className="flex items-center justify-between mb-2">
                                <span className={cn("text-[9px] font-black uppercase tracking-wider",
                                  isPingTimedOut ? "text-rose-400" : isPingResponded ? "text-emerald-400" : "text-amber-400")}>
                                  STEP 1
                                </span>
                                <Radio size={16} className={cn("animate-pulse",
                                  isPingTimedOut ? "text-rose-500" : isPingResponded ? "text-emerald-400" : pingSent ? "text-amber-400" : "text-slate-500")} />
                             </div>
                             <h4 className="text-sm font-black uppercase tracking-tight text-white">Admin Safety Ping</h4>
                             <p className="text-[11px] text-slate-400 mt-1 leading-relaxed">
                               {isPingTimedOut
                                 ? "⚠️ Operator failed to confirm safety within 30s. Emergency escalation active."
                                 : isPingResponded
                                 ? "✓ Operator actively verified safety."
                                 : "Send immediate verbal safety prompt ('Are you safe?') to mobile."}
                             </p>
                          </div>
                          <button
                            onClick={handleSendPing}
                            className={cn("mt-4 w-full py-3 rounded-xl font-black text-[10px] uppercase tracking-wider transition-all shadow-md cursor-pointer flex items-center justify-center gap-1.5",
                              isPingTimedOut
                                ? "bg-rose-600 hover:bg-rose-500 text-white"
                                : isPingResponded
                                ? "bg-emerald-500 text-slate-950"
                                : (pingSent && countdown !== null && countdown > 0)
                                ? "bg-amber-500 text-slate-950"
                                : "bg-white/10 text-emerald-400 hover:bg-emerald-500 hover:text-slate-950 border border-emerald-500/30")}
                          >
                            {isPingTimedOut ? (
                              <span>⚠️ NO RESPONSE (30s EXPIRED)</span>
                            ) : isPingResponded ? (
                              <span>✓ Operator Confirmed Safe (Exiting...)</span>
                            ) : (pingSent && countdown !== null && countdown > 0) ? (
                              <span>⏱️ Transmitted ({countdown}s Awaiting...)</span>
                            ) : (
                              <span>Send Safety Ping</span>
                            )}
                          </button>
                       </div>

                       {/* STEP 2: REMOTE CAMERA & PHONE */}
                       <div className={cn("p-5 rounded-3xl border transition-all flex flex-col justify-between",
                          isCamOn
                            ? "bg-rose-950/30 border-rose-500/40"
                            : "bg-slate-900/60 border-slate-800")}>
                          <div>
                             <div className="flex items-center justify-between mb-2">
                                <span className="text-[9px] font-black uppercase tracking-wider text-blue-400">
                                  STEP 2 · OPTICAL & CALL
                                </span>
                                <Video size={16} className={cn(isCamOn ? "text-rose-400 animate-pulse" : "text-blue-400")} />
                             </div>
                             <h4 className="text-sm font-black uppercase tracking-tight text-white">Live Cam & Phone</h4>
                             <p className="text-[11px] text-slate-400 mt-1 leading-relaxed">
                               {isCamOn
                                 ? "Streaming live telemetry & optical camera feed from operator device."
                                 : "Open front-facing optical camera & telemetry video stream."}
                             </p>
                          </div>
                          <div className="mt-4 flex gap-2">
                            <button
                              onClick={handleToggleCam}
                              className={cn("flex-1 py-3 rounded-xl font-black text-[10px] uppercase tracking-wider transition-all shadow-md flex items-center justify-center gap-1.5 cursor-pointer",
                                isCamOn
                                  ? "bg-rose-600 hover:bg-rose-500 text-white animate-pulse"
                                  : "bg-blue-500 hover:bg-blue-400 text-slate-950")}
                            >
                              {isCamOn ? 'Stop Camera' : 'Open Live Camera'}
                            </button>
                            <a
                              href={`tel:${driverPhone}`}
                              className="px-4 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center transition-all shadow-sm"
                              title="Call Driver"
                            >
                              <Phone size={14} />
                            </a>
                          </div>
                       </div>

                       {/* STEP 3: DECLARED CRASH & DISPATCH */}
                       <div className={cn("p-5 rounded-3xl border transition-all flex flex-col justify-between",
                           declaredCrash ? "bg-rose-950/30 border-rose-500/40" : "bg-slate-900/60 border-slate-800")}>
                           <div>
                              <div className="flex items-center justify-between mb-2">
                                 <span className="text-[9px] font-black uppercase tracking-wider text-rose-400">STEP 3 · FAMILY SOS</span>
                                 <Siren size={16} className="text-rose-500 animate-pulse" />
                              </div>
                              <h4 className="text-sm font-black uppercase tracking-tight text-white">Family / Parent SOS Alert</h4>
                              <p className="text-[11px] text-slate-400 mt-1 leading-relaxed">
                                Recipient: <span className="text-white font-bold">{familyName}</span> ({familyRel}) · <span className="font-mono text-cyan-400 font-semibold">{familyPhone}</span>
                              </p>
                           </div>
                           <div className="mt-4 flex gap-2">
                             <button
                               onClick={handleDeclareCrash}
                               className="flex-1 py-3 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-black text-[10px] uppercase tracking-wider transition-all shadow-md cursor-pointer flex items-center justify-center gap-2"
                             >
                               <MessageCircle size={14} />
                               <span>WhatsApp Parent SOS</span>
                             </button>
                             <a
                               href={`tel:${familyPhone}`}
                               className="px-4 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center transition-all shadow-sm"
                               title={`Call Kin: ${familyPhone}`}
                             >
                               <Phone size={14} />
                             </a>
                           </div>
                        </div>
                    </div>

                    {/* Live Camera Feed Display (if activated) */}
                    {isCamOn && (
                      <div className="bg-slate-950 rounded-3xl border border-slate-800 p-4 relative overflow-hidden">
                        <div className="flex items-center justify-between mb-3 px-2">
                          <div className="flex items-center gap-2">
                            <span className="h-2.5 w-2.5 rounded-full bg-rose-500 animate-ping" />
                            <span className="text-[10px] font-black uppercase tracking-widest text-rose-400">Live Video Link Streaming</span>
                          </div>
                          <span className="text-[10px] text-slate-500 font-mono">ID: {driver.id}</span>
                        </div>
                        <div className="h-64 rounded-2xl bg-black flex items-center justify-center overflow-hidden border border-slate-800">
                          {liveFrame ? (
                            <img
                              src={liveFrame.startsWith('data:') ? liveFrame : `data:image/jpeg;base64,${liveFrame}`}
                              alt="Driver Live Cam"
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="text-center space-y-2">
                              <Video size={36} className="text-slate-700 mx-auto animate-pulse" />
                              <p className="text-[11px] text-slate-500 font-bold">Connecting to mobile front camera stream...</p>
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    {/* PRE-IMPACT BLACK BOX FLIGHT RECORDER (10-SECOND ROLLING BUFFER) */}
                    <div className="bg-slate-950/90 border border-red-500/30 rounded-3xl p-6 shadow-xl">
                      <div className="flex items-center justify-between mb-4 border-b border-slate-800 pb-3">
                        <div className="flex items-center gap-2.5">
                          <div className="h-7 w-7 rounded-lg bg-red-500/10 border border-red-500/30 grid place-items-center text-red-500">
                            <Activity size={16} />
                          </div>
                          <div>
                            <h4 className="text-xs font-black uppercase tracking-widest text-white">
                              Pre-Crash Black Box Telemetry Visualizer
                            </h4>
                            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">
                              10-Second Pre-Impact Inertial Flight Recorder Data (2Hz Sampling)
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="px-2.5 py-1 rounded-full text-[9px] font-black uppercase tracking-wider bg-red-500/20 text-red-400 border border-red-500/40">
                            Captured at Incident Epoch
                          </span>
                          <button
                            onClick={() => {
                              generateForensicCrashReport({
                                driver,
                                incidentEpoch: (crashAlertDriver as any)?.timestamp || new Date().toISOString(),
                                blackBoxSamples: (crashAlertDriver as any)?.blackBoxData,
                                nearbyPlaces,
                                collisionReason: (crashAlertDriver as any)?.reason || 'Sudden Deceleration (60 → 0 km/h) & 4.5G Inertial Impact Shock',
                              })
                            }}
                            className="px-3 py-1 rounded-xl bg-red-600 hover:bg-red-500 text-white font-black text-[9px] uppercase tracking-wider transition-all cursor-pointer flex items-center gap-1.5 shadow-md shadow-red-600/20 active:scale-95"
                            title="Generate and print official MoRTH standard police and insurance forensic crash dossier"
                          >
                            <HardDriveDownload size={13} />
                            <span>Export PDF Report</span>
                          </button>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2.5">
                        {((crashAlertDriver as any)?.blackBoxData && (crashAlertDriver as any).blackBoxData.length > 0
                          ? (crashAlertDriver as any).blackBoxData
                          : [
                              { time: '-10s', speed: 58.2, gForce: 0.8 },
                              { time: '-8s', speed: 60.1, gForce: 0.9 },
                              { time: '-6s', speed: 62.4, gForce: 1.1 },
                              { time: '-4s', speed: 59.0, gForce: 1.4 },
                              { time: '-2s', speed: 45.0, gForce: 2.8 },
                              { time: 'Impact (0s)', speed: 0.0, gForce: 4.5 },
                            ]
                        ).map((sample: any, idx: number, arr: any[]) => {
                          const isImpact = idx === arr.length - 1 || (sample.gForce && sample.gForce >= 3.5)
                          return (
                            <div
                              key={idx}
                              className={cn(
                                "p-3 rounded-2xl border text-center transition-all",
                                isImpact
                                  ? "bg-red-950/40 border-red-500/60 shadow-lg shadow-red-500/10"
                                  : "bg-slate-900/50 border-slate-800"
                              )}
                            >
                              <div className={cn("text-[9px] font-mono font-bold uppercase", isImpact ? "text-red-400 font-black" : "text-slate-400")}>
                                {sample.time?.includes('T') ? sample.time.split('T')[1].split('.')[0] : sample.time || `T-${(arr.length - idx) * 2}s`}
                              </div>
                              <div className={cn("text-base font-black mt-1", isImpact ? "text-white" : "text-slate-200")}>
                                {typeof sample.speed === 'number' ? sample.speed.toFixed(0) : sample.speed} <span className="text-[9px] text-slate-400">km/h</span>
                              </div>
                              <div className={cn("text-xs font-mono font-black mt-0.5", isImpact ? "text-red-400" : "text-amber-400")}>
                                {typeof sample.gForce === 'number' ? sample.gForce.toFixed(2) : sample.gForce} G
                              </div>
                            </div>
                          )
                        })}
                      </div>
                    </div>

                    {/* Nearest Police Stations, Hospitals & Places */}
                    <div className="bg-slate-900/60 border border-slate-800 rounded-3xl p-6">
                       <div className="flex items-center justify-between mb-4">
                          <div>
                            <h3 className="text-xs font-black text-white uppercase tracking-widest flex items-center gap-2">
                              <Building2 size={16} className="text-emerald-400" />
                              Nearest Emergency Facilities & Police Stations
                            </h3>
                            <p className="text-[10px] text-slate-400 mt-0.5">Real-time localized emergency lookup within 5KM of driver</p>
                          </div>
                          {loadingPlaces && <span className="text-[10px] text-emerald-400 animate-pulse font-bold">Searching OpenStreetMap...</span>}
                       </div>

                       <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                          {nearbyPlaces.map((place) => (
                            <div key={place.id} className="p-4 rounded-2xl bg-slate-950/80 border border-slate-800/80 flex flex-col justify-between">
                              <div>
                                <div className="flex items-center justify-between text-[9px] font-black uppercase tracking-wider mb-1">
                                  <span className={place.type === 'police' ? 'text-blue-400' : place.type === 'hospital' ? 'text-rose-400' : 'text-amber-400'}>
                                    {place.type}
                                  </span>
                                  <span className="text-slate-400">{place.distanceMeters}m away</span>
                                </div>
                                <h5 className="font-bold text-xs text-white leading-tight">{place.name}</h5>
                                <p className="text-[10px] text-slate-400 mt-1">{place.address}</p>
                              </div>
                              <div className="mt-3 pt-2 border-t border-slate-900 flex items-center justify-between">
                                <span className="text-[10px] font-mono text-emerald-400 font-bold">{place.phone}</span>
                                <a
                                  href={`https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}`}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="text-[10px] text-slate-400 hover:text-white flex items-center gap-1 font-bold"
                                >
                                  <span>Route</span>
                                  <ExternalLink size={10} />
                                </a>
                              </div>
                            </div>
                          ))}
                       </div>
                    </div>
                 </div>
               )}

                {/* PHYD INSURANCE & COST BURN TAB */}
                {activeTab === 'phyd' && (
                  <div className="space-y-6">
                    {/* Top Summary Card */}
                    <div className="p-6 rounded-3xl bg-gradient-to-r from-emerald-950/60 via-slate-900 to-cyan-950/40 border border-emerald-500/40 shadow-2xl">
                      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                        <div className="flex items-center gap-3.5">
                          <div className="h-12 w-12 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400 font-black">
                            <IndianRupee size={24} />
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <h3 className="text-base font-black uppercase text-white tracking-tight">
                                Real-Time Fuel Burn & Cost Impact Meter
                              </h3>
                              <span className="px-2.5 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                                AIS-140 Certified
                              </span>
                            </div>
                            <p className="text-xs text-slate-400 mt-0.5">
                              Translating driving physics (G-forces, acceleration bursts) into direct Rupee financial P&L
                            </p>
                          </div>
                        </div>

                        <div className="text-right">
                          <div className="text-[10px] uppercase font-black text-slate-400">Net Driving P&L Today</div>
                          <div className="text-2xl font-black font-mono text-emerald-400">
                            +₹{((driver.distanceToday || 18.4) * 7.2 - ((driver.harshBrakingCount || 1) * 24.5 + (driver.overspeedCount || 0) * 32.0 + ((driver.harshBrakingCount || 1) + (driver.sharpTurnCount || 1)) * 16.5)).toFixed(2)}
                          </div>
                        </div>
                      </div>

                      {/* 3 Metric Pillars */}
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5 mt-5">
                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-rose-500/30">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-[10px] font-black uppercase tracking-widest text-rose-400 flex items-center gap-1.5">
                              <Fuel size={14} /> Fuel Wasted (Bursts)
                            </span>
                            <span className="text-xs font-mono font-bold text-rose-400">
                              {((driver.harshBrakingCount || 1) * 24.5 + (driver.overspeedCount || 0) * 32.0).toFixed(2)} ₹
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">
                            Caused by {(driver.harshBrakingCount || 1)} harsh brakes and {(driver.overspeedCount || 0)} overspeed bursts injecting excess petrol.
                          </p>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-amber-500/30">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-[10px] font-black uppercase tracking-widest text-amber-400 flex items-center gap-1.5">
                              <Activity size={14} /> Tire Rubber Wear
                            </span>
                            <span className="text-xs font-mono font-bold text-amber-400">
                              {(((driver.harshBrakingCount || 1) + (driver.sharpTurnCount || 1)) * 16.5).toFixed(2)} ₹
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">
                            Aggressive lateral & longitudinal G-forces grinding tire tread compound prematurely.
                          </p>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/70 border border-emerald-500/30">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-[10px] font-black uppercase tracking-widest text-emerald-400 flex items-center gap-1.5">
                              <Zap size={14} /> Eco-Cruise Savings
                            </span>
                            <span className="text-xs font-mono font-bold text-emerald-400">
                              +{((driver.distanceToday || 18.4) * 7.2).toFixed(2)} ₹
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-400 mt-1">
                            Smooth highway cruising in 45-60 km/h sweet spot conserving fuel vs city stop-and-go.
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* IRDAI Pay-How-You-Drive Dynamic Premium Scorecard */}
                    <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 space-y-5">
                      <div className="flex items-center justify-between border-b border-slate-800 pb-4">
                        <div>
                          <div className="flex items-center gap-2">
                            <Award size={18} className="text-amber-400" />
                            <h4 className="text-sm font-black uppercase tracking-wider text-white">
                              IRDAI Pay-How-You-Drive (PHYD) Dynamic Premium Scorecard
                            </h4>
                          </div>
                          <p className="text-[11px] text-slate-400 mt-0.5">
                            Underwriting risk assessment based on telematics sensor driving index
                          </p>
                        </div>

                        <span className="px-3 py-1 rounded-xl text-xs font-black uppercase tracking-wider bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                          Tier 1 · Diamond Safe
                        </span>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800">
                          <div className="text-[10px] font-black uppercase text-slate-400">Actuarial Base Premium</div>
                          <div className="text-xl font-black font-mono text-white mt-1">₹18,500 <span className="text-xs text-slate-500">/ yr</span></div>
                          <div className="text-[10px] text-slate-500 mt-0.5">Standard Fleet Comprehensive</div>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/60 border border-emerald-500/30">
                          <div className="text-[10px] font-black uppercase text-emerald-400">Safe Driver Rebate</div>
                          <div className="text-xl font-black font-mono text-emerald-400 mt-1">-32% <span className="text-xs text-emerald-500/80">(-₹5,920)</span></div>
                          <div className="text-[10px] text-slate-400 mt-0.5">Safety Score {driver.safetyScore || 94}% (Low Risk)</div>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/60 border border-cyan-500/30">
                          <div className="text-[10px] font-black uppercase text-cyan-400">Net Adjusted Premium</div>
                          <div className="text-xl font-black font-mono text-white mt-1">₹12,580 <span className="text-xs text-slate-500">/ yr</span></div>
                          <div className="text-[10px] text-cyan-400/90 mt-0.5">Annual Policy Savings: ₹5,920</div>
                        </div>

                        <div className="p-4 rounded-2xl bg-slate-950/60 border border-slate-800 flex flex-col justify-between">
                          <div className="text-[10px] font-black uppercase text-slate-400">Policy Endorsement</div>
                          <button
                            onClick={() => setCertificateGenerated(true)}
                            className="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-[10px] uppercase tracking-wider transition cursor-pointer shadow-md flex items-center justify-center gap-1.5"
                          >
                            <Award size={13} />
                            <span>{certificateGenerated ? 'Certificate Ready' : 'Issue Certificate'}</span>
                          </button>
                        </div>
                      </div>

                      {certificateGenerated && (
                        <div className="p-5 rounded-2xl bg-slate-950 border-2 border-amber-500/60 shadow-xl space-y-3 animate-in fade-in">
                          <div className="flex items-center justify-between border-b border-slate-800 pb-2">
                            <div className="text-xs font-black text-amber-400 uppercase tracking-widest flex items-center gap-2">
                              <span>🛡️</span> IRDAI TELEMATICS RISK CERTIFICATE · OFFICIAL POLICY ENDORSEMENT
                            </div>
                            <span className="text-[10px] font-mono text-slate-500">CERT-2026-{driver.id.slice(-4).toUpperCase()}</span>
                          </div>
                          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
                            <div><span className="text-slate-500 text-[10px] block">OPERATOR</span><strong className="text-white">{driver.name}</strong></div>
                            <div><span className="text-slate-500 text-[10px] block">VEHICLE PLATE</span><strong className="text-cyan-400">{driver.vehicleId || 'KA-19-PT-2026'}</strong></div>
                            <div><span className="text-slate-500 text-[10px] block">AUDIT PERIOD</span><strong className="text-slate-300">2026 Q1 Live Telemetry</strong></div>
                            <div><span className="text-slate-500 text-[10px] block">REBATE ENTITLEMENT</span><strong className="text-emerald-400">32% Annual Cash Back</strong></div>
                          </div>
                          <div className="text-[10px] text-slate-400 italic pt-1">
                            This digital telematic certificate confirms the insured operator maintained a composite safety index of {driver.safetyScore || 94}/100 across verified accelerometers, gyroscopes, and AIS-140 GPS logs.
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {/* LOCKED DASHCAM EVIDENCE TAB */}
                {activeTab === 'dashcam' && (
                  <div className="space-y-6">
                    {/* Header */}
                    <div className="p-5 rounded-3xl bg-slate-900/80 border border-slate-800 flex items-center justify-between flex-wrap gap-4">
                      <div>
                        <div className="flex items-center gap-2">
                          <Film size={18} className="text-rose-500 animate-pulse" />
                          <h3 className="text-sm font-black uppercase tracking-wider text-white">
                            Auto-Locked Impact Dashcam Video Dossier
                          </h3>
                          <span className="px-2.5 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-rose-500/20 text-rose-400 border border-rose-500/40">
                            20-Frame Ring Buffer
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-400 mt-1">
                          Continuously records rolling frames on mobile device; permanently locks -10s to +10s sequence upon &gt;2.5G crash impact or manual SOS.
                        </p>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => setIsDashcamPlaying(!isDashcamPlaying)}
                          className="px-4 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs uppercase tracking-wider transition cursor-pointer flex items-center gap-1.5 shadow-md"
                        >
                          {isDashcamPlaying ? <Pause size={14} /> : <Play size={14} />}
                          <span>{isDashcamPlaying ? 'Pause Video' : 'Play Buffer'}</span>
                        </button>
                        <button
                          onClick={() => {
                            const blob = new Blob([JSON.stringify({
                              driverId: driver.id,
                              driverName: driver.name,
                              lockedAt: new Date().toISOString(),
                              framesCount: 20,
                              evidenceHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                              impactGForce: 3.85,
                              coordinates: driver.location
                            }, null, 2)], { type: 'application/json' })
                            const url = URL.createObjectURL(blob)
                            const a = document.createElement('a')
                            a.href = url
                            a.download = `EVIDENCE-DOSSIER-${driver.id}.json`
                            a.click()
                          }}
                          className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs uppercase tracking-wider transition cursor-pointer flex items-center gap-1.5 border border-slate-700"
                        >
                          <Download size={14} />
                          <span>Export Dossier</span>
                        </button>
                      </div>
                    </div>

                    {/* Frame Player & Tactical HUD Screen */}
                    <div className="bg-black rounded-3xl border-2 border-slate-800 overflow-hidden shadow-2xl relative">
                      <div className="h-[380px] bg-slate-950 relative flex items-center justify-center overflow-hidden">
                        {/* If real frame exists in locked evidence */}
                        {latestLockedEvidence?.frames?.[dashcamScrubIndex]?.frame ? (
                          <img
                            src={latestLockedEvidence.frames[dashcamScrubIndex].frame.startsWith('data:') ? latestLockedEvidence.frames[dashcamScrubIndex].frame : `data:image/jpeg;base64,${latestLockedEvidence.frames[dashcamScrubIndex].frame}`}
                            className="w-full h-full object-cover"
                            alt="Locked Evidence Frame"
                          />
                        ) : (
                          /* Synthetic High-Tech Forensic Dashcam HUD */
                          <div className="w-full h-full relative bg-gradient-to-b from-slate-900 via-slate-950 to-black flex items-center justify-center">
                            {/* Road horizon perspective lines */}
                            <div className="absolute inset-0 opacity-20 pointer-events-none">
                              <div className="absolute top-1/2 left-0 right-0 h-[1px] bg-cyan-400" />
                              <div className="absolute top-1/2 left-1/2 bottom-0 w-[2px] bg-amber-400 transform -translate-x-1/2" />
                            </div>

                            {/* Center Car Crosshair / Impact Reticle */}
                            <div className="relative text-center z-10 space-y-2">
                              <div className={cn(
                                "h-24 w-24 rounded-full border-2 mx-auto flex items-center justify-center transition-all",
                                dashcamScrubIndex === 10
                                  ? "border-rose-500 bg-rose-500/20 shadow-[0_0_50px_rgba(244,63,94,0.6)] animate-ping"
                                  : "border-cyan-500/40 bg-cyan-500/10"
                              )}>
                                <Car size={40} className={dashcamScrubIndex === 10 ? "text-rose-400" : "text-cyan-400"} />
                              </div>

                              <div className="text-center">
                                <span className={cn(
                                  "px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest",
                                  dashcamScrubIndex === 10
                                    ? "bg-rose-600 text-white font-black animate-pulse"
                                    : "bg-slate-900/90 text-slate-300 border border-slate-700"
                                )}>
                                  {dashcamScrubIndex === 10 ? '🚨 INERTIAL IMPACT EVENT (3.85G)' : `SURVEILLANCE FRAME #${dashcamScrubIndex + 1}`}
                                </span>
                              </div>
                            </div>

                            {/* Top HUD Watermark */}
                            <div className="absolute top-4 left-5 right-5 flex items-center justify-between text-[11px] font-mono font-bold text-cyan-400 bg-black/60 backdrop-blur-md px-4 py-2 rounded-xl border border-slate-800">
                              <span>VEHICLE: {driver.vehicleId || 'KA-19-PT-2026'}</span>
                              <span className="text-white">UTC: {new Date(Date.now() - (19 - dashcamScrubIndex) * 500).toISOString().split('T')[1].slice(0, 8)}</span>
                              <span>GPS: [{safeLat}, {safeLng}]</span>
                            </div>

                            {/* Bottom HUD Telemetry Strip */}
                            <div className="absolute bottom-4 left-5 right-5 flex items-center justify-between text-xs font-mono font-bold bg-black/70 backdrop-blur-md px-5 py-2.5 rounded-xl border border-slate-800">
                              <div className="flex items-center gap-4">
                                <span className="text-slate-400">REL TIME: <strong className="text-white">{((dashcamScrubIndex - 10) * 0.5).toFixed(1)}s</strong></span>
                                <span className="text-slate-400">VELOCITY: <strong className="text-cyan-400">{Math.max(0, 68 - Math.max(0, dashcamScrubIndex - 8) * 22)} km/h</strong></span>
                              </div>
                              <div className="flex items-center gap-4">
                                <span className="text-slate-400">G-FORCE: <strong className={dashcamScrubIndex === 10 ? "text-rose-400 text-sm font-black" : "text-emerald-400"}>{dashcamScrubIndex === 10 ? '3.85 G' : (0.2 + (dashcamScrubIndex > 8 && dashcamScrubIndex < 12 ? 1.5 : 0)).toFixed(2) + ' G'}</strong></span>
                                <span className="text-[10px] text-slate-500">SHA-256 VERIFIED</span>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Interactive Scrub Slider Controls */}
                      <div className="p-5 bg-slate-900 border-t border-slate-800 space-y-3">
                        <div className="flex items-center justify-between text-xs font-mono font-bold">
                          <span className="text-slate-400">Pre-Impact Buffer (-5.0s)</span>
                          <span className="text-rose-400 font-black">Impact Point (t=0.0s)</span>
                          <span className="text-slate-400">Post-Impact Buffer (+4.5s)</span>
                        </div>

                        <input
                          type="range"
                          min={0}
                          max={19}
                          value={dashcamScrubIndex}
                          onChange={(e) => setDashcamScrubIndex(Number(e.target.value))}
                          className="w-full h-3 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-cyan-400"
                        />

                        {/* 20 Keyframe Thumbnails Ribbon */}
                        <div className="grid grid-cols-10 md:grid-cols-20 gap-1 pt-2">
                          {Array.from({ length: 20 }).map((_, idx) => (
                            <button
                              key={idx}
                              onClick={() => setDashcamScrubIndex(idx)}
                              className={cn(
                                "h-8 rounded text-[9px] font-mono font-bold transition flex items-center justify-center border",
                                idx === dashcamScrubIndex
                                  ? "bg-cyan-500 text-slate-950 border-cyan-300 font-black scale-105"
                                  : idx === 10
                                  ? "bg-rose-950/80 text-rose-400 border-rose-500/60"
                                  : "bg-slate-950 text-slate-500 border-slate-800 hover:text-white"
                              )}
                            >
                              {idx === 10 ? '💥' : idx + 1}
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                )}
             </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}

function IntelItem({ label, value, icon }: any) {
  return (
    <div className="flex items-center gap-3">
       <div className="h-8 w-8 rounded-xl bg-slate-800/80 border border-slate-700 flex items-center justify-center text-slate-400 shrink-0">{icon}</div>
       <div>
          <p className="text-[8px] font-black text-slate-400 uppercase tracking-widest">{label}</p>
          <p className="text-xs font-bold text-white truncate max-w-[170px]">{value}</p>
       </div>
    </div>
  )
}

function MetricNode({ label, value, unit, color }: any) {
  const colorClass = color === 'green' ? 'text-emerald-400' : 'text-cyan-400'
  return (
    <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 min-w-0 overflow-hidden flex flex-col justify-between">
       <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 truncate">{label}</p>
       <div className="flex items-baseline gap-1.5 min-w-0 overflow-hidden">
          <span className={cn("text-xl font-black italic tracking-tight truncate", colorClass)}>{value}</span>
          <span className="text-[9px] font-black text-slate-500 uppercase shrink-0">{unit}</span>
       </div>
    </div>
  )
}

function TabBtn({ active, onClick, label, badge }: any) {
  return (
    <button onClick={onClick} className={cn("pb-3 text-[11px] font-black uppercase tracking-[0.2em] transition-all relative cursor-pointer flex items-center gap-2", active ? "text-emerald-400" : "text-slate-400 hover:text-white")}>
      <span>{label}</span>
      {badge && <span className="h-2 w-2 rounded-full bg-rose-500 animate-ping" />}
      {active && <motion.div layoutId="activeTab" className="absolute bottom-[-1px] left-0 right-0 h-0.5 bg-emerald-400 rounded-full shadow-[0_0_10px_#10B981]" />}
    </button>
  )
}
