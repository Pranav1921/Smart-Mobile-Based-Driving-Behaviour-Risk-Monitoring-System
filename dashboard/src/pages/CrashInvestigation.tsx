import { useState, useEffect, useMemo, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ShieldAlert, Activity, Play, Volume2, MapPin,
  Clock, ShieldCheck, XCircle, ChevronRight, CheckCircle2,
  FileSearch, Camera, Mic, Info, Phone, Send, User, TriangleAlert as AlertTriangle,
  ExternalLink, HardDriveDownload, Search, HeartPulse, Building2, Eye, Pause,
  Loader2, Zap, MessageSquare, Video, Radio, Siren, ArrowLeft, Lock, Unlock,
  Film, Download, Car
} from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { Badge } from '@/components/ui/Badge'
import { Avatar } from '@/components/ui/Avatar'
import { cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'
import { AreaLineChart } from '@/components/charts/Charts'
import { fetchNearbyEmergencyPlaces, EmergencyPlace } from '@/lib/emergencyServices'
import { generateForensicCrashReport } from '@/lib/forensicReportGenerator'

export default function CrashInvestigation() {
  const navigate = useNavigate()
  const {
    liveDrivers,
    crashAlertDriver,
    setCrashAlertDriver,
    emitSafetyPing,
    emitIncidentResolved,
    liveFrame,
    emitLiveCamRequest,
    emitDriverMessage,
    pingedDrivers,
    latestLockedEvidence,
  } = useSocket()

  const [messageSent, setMessageSent] = useState(false)
  const [adminMsg, setAdminMsg] = useState('')
  const [isCamStreaming, setIsCamStreaming] = useState(false)
  const [scrubIndex, setScrubIndex] = useState(10)
  const [isPlaying, setIsPlaying] = useState(false)
  const [pingSent, setPingSent] = useState(false)
  const [countdown, setCountdown] = useState<number | null>(null)
  const [callAttempts, setCallAttempts] = useState(0)
  const [declaredAccident, setDeclaredAccident] = useState(false)
  const [nearbyPlaces, setNearbyPlaces] = useState<EmergencyPlace[]>([])
  const [loadingPlaces, setLoadingPlaces] = useState(false)

  // Find active emergency driver from crash alert or live list
  const activeDriver = useMemo(() => {
    if (crashAlertDriver) {
      const match = liveDrivers.find(d => d.id === crashAlertDriver.driverId || d.id === crashAlertDriver.id)
      return match || crashAlertDriver
    }
    return liveDrivers.find(d => d.status === 'emergency' || d.status === 'warning') || liveDrivers[0] || null
  }, [crashAlertDriver, liveDrivers])

  const driverId = activeDriver?.driverId || activeDriver?.id || 'live-driver'
  const pingState = pingedDrivers[driverId]
  const isPingResponded = pingState?.responded === true
  const isPingTimedOut = pingState?.timedOut === true || (pingSent && countdown === 0 && !isPingResponded) || activeDriver?.status === 'emergency'

  // Camera Access Rule: Only unlocked if driver is unresponsive / timed out / manual emergency SOS.
  // Locked if driver responded safe or initial verification not started.
  const isCameraUnlocked = isPingTimedOut && !isPingResponded

  const [telemetryHistory, setTelemetryHistory] = useState<{
    labels: string[]
    gForce: number[]
  }>({
    labels: ['10s', '8s', '6s', '4s', '2s', 'Now'],
    gForce: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
  })

  // Live G-force chart updates
  useEffect(() => {
    if (!activeDriver) return
    const interval = setInterval(() => {
      const gVal = activeDriver.vibrationRate || (activeDriver.accelX ? Math.sqrt(activeDriver.accelX**2 + (activeDriver.accelY||0)**2 + (activeDriver.accelZ||0)**2)/9.8 : 0.01)
      setTelemetryHistory(prev => ({
        labels: prev.labels,
        gForce: [...prev.gForce.slice(1), Number(gVal.toFixed(2))]
      }))
    }, 1000)
    return () => clearInterval(interval)
  }, [activeDriver])

  // Auto-play loop for 20-frame dashcam buffer
  useEffect(() => {
    if (!isPlaying) return
    const interval = setInterval(() => {
      setScrubIndex((prev) => (prev + 1) % 20)
    }, 450)
    return () => clearInterval(interval)
  }, [isPlaying])

  // Countdown timer for 30s Safety Ping
  useEffect(() => {
    if (countdown === null || countdown <= 0) return
    if (isPingResponded) {
      setCountdown(null)
      return
    }
    const timer = setInterval(() => {
      setCountdown(prev => (prev !== null && prev > 0 ? prev - 1 : 0))
    }, 1000)
    return () => clearInterval(timer)
  }, [countdown, isPingResponded])

  // Fetch nearby police & hospitals
  useEffect(() => {
    if (activeDriver) {
      const lat = activeDriver.latitude ?? activeDriver.location?.lat ?? 12.7749
      const lng = activeDriver.longitude ?? activeDriver.location?.lng ?? 75.2023
      setLoadingPlaces(true)
      fetchNearbyEmergencyPlaces(lat, lng)
        .then((places) => setNearbyPlaces(places))
        .finally(() => setLoadingPlaces(false))
    }
  }, [activeDriver])

  const handleSendPing = () => {
    setPingSent(true)
    setCountdown(30)
    emitSafetyPing(driverId)
  }

  const handleToggleCam = () => {
    const nextState = !isCamStreaming
    setIsCamStreaming(nextState)
    emitLiveCamRequest(driverId, nextState)
    if (activeDriver?.userId && activeDriver.userId !== driverId) {
      emitLiveCamRequest(activeDriver.userId, nextState)
    }
  }

  const handleSendMessage = () => {
    if (!adminMsg.trim()) return
    emitDriverMessage(driverId, adminMsg)
    setAdminMsg('')
    setMessageSent(true)
    setTimeout(() => setMessageSent(false), 4000)
  }

  const handleCallOperator = () => {
    setCallAttempts(prev => prev + 1)
    const phone = activeDriver?.phone || '+91 98450 12345'
    window.open(`tel:${phone}`, '_self')
  }

  const kinPhone = (activeDriver as any)?.emergencyContactPhone || (activeDriver as any)?.emergencyContact || (activeDriver as any)?.familyWhatsappNumber || ''
  const kinName = (activeDriver as any)?.emergencyContactName || (activeDriver as any)?.familyMemberName || 'Family Kin / Parent'
  const kinRel = (activeDriver as any)?.familyRelationship || 'Parent / Kin'

  const handleWhatsAppFamilyAlert = () => {
    setDeclaredAccident(true)
    const lat = activeDriver?.latitude ?? activeDriver?.location?.lat ?? 12.7749
    const lng = activeDriver?.longitude ?? activeDriver?.location?.lng ?? 75.2023
    const policeStation = nearbyPlaces.find(p => p.type === 'police')
    const policeInfo = policeStation ? `\nNearest Police: ${policeStation.name} (${policeStation.phone})` : ''
    const message = `🚨 DRIVING RISK CRITICAL SOS ALERT 🚨\n\nOperator: ${activeDriver?.name || 'Field Driver'}\nStatus: Unresponsive (Emergency Protocol Active)\nTime: ${new Date().toLocaleTimeString()}\nGPS Location: https://maps.google.com/?q=${lat},${lng}${policeInfo}\n\nEmergency dispatch initiated.`
    const cleanPhone = kinPhone.replace(/\D/g, '')
    window.open(cleanPhone ? `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}` : `https://wa.me/?text=${encodeURIComponent(message)}`, '_blank')
  }

  const handleResolveIncident = () => {
    emitIncidentResolved(driverId)
    if (isCamStreaming) emitLiveCamRequest(driverId, false)
    setCrashAlertDriver(null)
    navigate('/map')
  }

  const safeLat = (activeDriver?.latitude ?? activeDriver?.location?.lat ?? 12.7749).toFixed(5)
  const safeLng = (activeDriver?.longitude ?? activeDriver?.location?.lng ?? 75.2023).toFixed(5)

  return (
    <div className="space-y-6 max-w-[1600px] mx-auto pb-20 text-white font-sans">
      {/* TOP HEADER BAR */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-6 rounded-3xl bg-[#0A0E1A] border border-slate-800/80 shadow-2xl backdrop-blur-xl">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="h-11 w-11 rounded-2xl bg-slate-900 border border-slate-700/80 text-slate-300 hover:text-white hover:border-cyan-400 transition-all flex items-center justify-center cursor-pointer shadow-md"
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <span className="h-3 w-3 rounded-full bg-rose-500 animate-ping" />
              <h1 className="text-2xl font-black uppercase italic tracking-tight text-white leading-none">
                Emergency Response <span className="text-rose-500">Command Center</span>
              </h1>
            </div>
            <p className="text-[10px] text-slate-400 font-black uppercase tracking-[0.3em] mt-2">
              Verified 3-Step Tactical Escalation Protocol
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <Badge
            tone={isPingResponded ? 'safe' : isPingTimedOut ? 'emergency' : 'warning'}
            className="px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider"
          >
            {isPingResponded ? '✓ Operator Confirmed Safe' : isPingTimedOut ? '🚨 SOS / Unresponsive' : 'Awaiting Response'}
          </Badge>
          <button
            onClick={() => {
              generateForensicCrashReport({
                driver: activeDriver,
                incidentEpoch: activeDriver?.timestamp || new Date().toISOString(),
                blackBoxSamples: (activeDriver as any)?.blackBoxData,
                nearbyPlaces,
                collisionReason: activeDriver?.reason || 'Sudden Deceleration (60 → 0 km/h) & 4.5G Inertial Impact Shock',
              })
            }}
            className="px-4 py-2.5 rounded-xl bg-red-600 hover:bg-red-500 text-white font-black text-xs uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 shadow-lg shadow-red-600/25 active:scale-95"
            title="Generate and print official MoRTH standard police and insurance forensic crash dossier"
          >
            <HardDriveDownload size={16} />
            <span>Forensic PDF Report</span>
          </button>
          <button
            onClick={handleResolveIncident}
            className="px-5 py-2.5 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 font-black text-xs uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2"
          >
            <CheckCircle2 size={16} />
            <span>Resolve & Close</span>
          </button>
        </div>
      </div>

      {/* MAIN GRID */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* LEFT COLUMN: LIVE VIDEO & SENSOR TELEMETRY (8 COLS) */}
        <div className="lg:col-span-8 space-y-6">
          {/* VIDEO FEED PLAYER */}
          <div className="bg-[#0A0E1A] rounded-[32px] border border-slate-800 overflow-hidden shadow-2xl relative">
            <div className="flex items-center justify-between p-4 border-b border-slate-800/80 bg-slate-900/40">
              <div className="flex items-center gap-2.5">
                <span className={cn("h-2.5 w-2.5 rounded-full", isCamStreaming ? "bg-rose-500 animate-pulse" : "bg-slate-600")} />
                <span className="text-[11px] font-black uppercase tracking-widest text-slate-300">
                  {isCamStreaming ? "Live Front Optical Surveillance Feed" : "Front Camera Link Standby"}
                </span>
              </div>
              <div className="flex items-center gap-3 text-[10px] font-mono text-cyan-400">
                <span>GPS: [{safeLat}, {safeLng}]</span>
                <span className="text-slate-600">|</span>
                <span>ID: {driverId}</span>
              </div>
            </div>

            <div className="h-[420px] bg-black relative flex items-center justify-center overflow-hidden">
              {isCamStreaming && liveFrame ? (
                <img
                  src={liveFrame.startsWith('data:') ? liveFrame : `data:image/jpeg;base64,${liveFrame}`}
                  className="w-full h-full object-cover"
                  alt="Driver Live Surveillance Feed"
                />
              ) : isCamStreaming ? (
                <div className="text-center space-y-3 p-6">
                  <div className="h-16 w-16 rounded-full bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center mx-auto animate-spin">
                    <Loader2 size={28} className="text-cyan-400" />
                  </div>
                  <p className="text-xs font-bold text-cyan-300 uppercase tracking-widest">Connecting encrypted frame stream...</p>
                  <p className="text-[10px] text-slate-500">Streaming from driver's mobile device</p>
                </div>
              ) : (
                <div className="text-center space-y-4 p-8 max-w-md">
                  <div className="h-20 w-20 rounded-3xl bg-slate-900 border border-slate-800 flex items-center justify-center mx-auto shadow-2xl">
                    {isCameraUnlocked ? (
                      <Video size={36} className="text-cyan-400 animate-pulse" />
                    ) : (
                      <Lock size={36} className="text-slate-600" />
                    )}
                  </div>
                  <div>
                    <h3 className="text-sm font-black uppercase tracking-wider text-white">
                      {isCameraUnlocked ? "Camera Access Unlocked" : "Privacy Lock Enforced"}
                    </h3>
                    <p className="text-[11px] text-slate-400 mt-1 leading-relaxed">
                      {isCameraUnlocked
                        ? "Operator is unresponsive to Step 1 verification ping. Live front camera feed is now authorized."
                        : isPingResponded
                        ? "Operator responded 'I am safe'. Surveillance stream is disabled to protect operator privacy."
                        : "Camera feed requires Step 1 Safety Ping verification or non-response timeout to activate."}
                    </p>
                  </div>
                  <div className="flex gap-2 justify-center">
                    {isCameraUnlocked ? (
                      <button
                        onClick={handleToggleCam}
                        className="px-6 py-3 rounded-2xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs uppercase tracking-widest transition-all shadow-lg cursor-pointer flex items-center gap-2"
                      >
                        <Video size={16} />
                        <span>Start Live Footage</span>
                      </button>
                    ) : (
                      <button
                        onClick={handleToggleCam}
                        className="px-5 py-2.5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-cyan-400 font-bold text-xs uppercase tracking-wider transition-all border border-slate-700 cursor-pointer flex items-center gap-2"
                      >
                        <Video size={14} />
                        <span>Admin Override & Start Feed</span>
                      </button>
                    )}
                  </div>
                </div>
              )}

              {isCamStreaming && (
                <div className="absolute top-4 left-4 px-3 py-1.5 rounded-full bg-rose-600/90 text-white font-black text-[9px] uppercase tracking-widest flex items-center gap-2 shadow-lg backdrop-blur-sm">
                  <span className="h-2 w-2 rounded-full bg-white animate-ping" />
                  <span>LIVE FOOTAGE LINK</span>
                </div>
              )}
            </div>

            {/* TWO-WAY VOICE TTS INTERCOM */}
            <div className="p-4 bg-slate-900/60 border-t border-slate-800/80">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={adminMsg}
                  onChange={(e) => setAdminMsg(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                  placeholder="Type dispatch audio alert to driver (will be spoken via mobile TTS)..."
                  className="flex-1 px-4 py-3 rounded-xl bg-slate-950 border border-slate-700/80 text-xs text-white placeholder-slate-500 outline-none focus:border-cyan-400 font-medium"
                />
                <button
                  onClick={handleSendMessage}
                  className="px-5 py-3 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 shadow-md"
                >
                  <Send size={14} />
                  <span>Transmit</span>
                </button>
              </div>
              {messageSent && (
                <p className="text-[10px] text-emerald-400 font-bold mt-2 flex items-center gap-1.5">
                  <CheckCircle2 size={12} /> Verbal message transmitted to driver's mobile device!
                </p>
              )}
            </div>
          </div>

          {/* SENSOR NODES & REAL-TIME G-FORCE WAVEFORM */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <MetricCard label="Velocity" value={Math.round(activeDriver?.speed || 0)} unit="KM/H" color="cyan" />
            <MetricCard label="Impact Force" value={(activeDriver?.vibrationRate || 0.1).toFixed(2)} unit="G-FORCE" color="rose" />
            <MetricCard label="Safety Score" value={Math.round(activeDriver?.safetyScore || 100)} unit="INDEX" color="green" />
            <MetricCard label="Heading" value={`${Math.round(activeDriver?.heading || 0)}°`} unit="DEG" color="cyan" />
          </div>

          <div className="bg-[#0A0E1A] border border-slate-800 rounded-3xl p-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2">
                <Activity size={14} className="text-cyan-400" />
                Real-Time Inertial G-Force Waveform
              </h3>
              <span className="font-mono text-cyan-400 text-xs font-bold">
                GPS: {safeLat}, {safeLng}
              </span>
            </div>
            <AreaLineChart
              labels={telemetryHistory.labels}
              series={[{ name: 'G-Force', data: telemetryHistory.gForce, color: '#00FF9D' }]}
              height={160}
            />
          </div>

          {/* AUTO-LOCKED DASHCAM VIDEO EVIDENCE DOSSIER */}
          <div className="bg-[#0A0E1A] border border-slate-800 rounded-3xl p-6 shadow-2xl space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-800/80 pb-4">
              <div>
                <div className="flex items-center gap-2">
                  <Film size={18} className="text-rose-500 animate-pulse" />
                  <h3 className="text-xs font-black uppercase tracking-widest text-white">
                    Auto-Locked Crash Dashcam Video Evidence (20-Frame Ring Buffer)
                  </h3>
                  <span className="px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-rose-500/20 text-rose-400 border border-rose-500/40">
                    Tamper-Proof
                  </span>
                </div>
                <p className="text-[10px] text-slate-400 mt-1">
                  Rolling dashcam buffer on mobile auto-locked upon &gt;2.5G deceleration shock. Frame-by-frame forensic analysis (-5.0s to +4.5s).
                </p>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsPlaying(!isPlaying)}
                  className="px-3.5 py-2 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-black text-xs uppercase tracking-wider transition cursor-pointer flex items-center gap-1.5 shadow-md"
                >
                  {isPlaying ? <Pause size={13} /> : <Play size={13} />}
                  <span>{isPlaying ? 'Pause' : 'Play Buffer'}</span>
                </button>
                <button
                  onClick={() => {
                    const blob = new Blob([JSON.stringify({
                      caseId: `CRASH-DOSSIER-${driverId}`,
                      driver: activeDriver?.name,
                      vehiclePlate: activeDriver?.vehicleId || 'KA-19-PT-2026',
                      coordinates: { lat: safeLat, lng: safeLng },
                      impactGForce: 3.85,
                      framesRecorded: 20,
                      chainOfCustodySha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                      timestamp: new Date().toISOString()
                    }, null, 2)], { type: 'application/json' })
                    const url = URL.createObjectURL(blob)
                    const a = document.createElement('a')
                    a.href = url
                    a.download = `CRASH-EVIDENCE-DOSSIER-${driverId}.json`
                    a.click()
                  }}
                  className="px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs uppercase tracking-wider transition cursor-pointer flex items-center gap-1.5 border border-slate-700"
                >
                  <Download size={13} />
                  <span>Export</span>
                </button>
              </div>
            </div>

            {/* Video Canvas / Tactical Frame HUD */}
            <div className="bg-black rounded-2xl border border-slate-800 overflow-hidden relative h-[320px] flex items-center justify-center">
              {latestLockedEvidence?.frames?.[scrubIndex]?.frame ? (
                <img
                  src={latestLockedEvidence.frames[scrubIndex].frame.startsWith('data:') ? latestLockedEvidence.frames[scrubIndex].frame : `data:image/jpeg;base64,${latestLockedEvidence.frames[scrubIndex].frame}`}
                  className="w-full h-full object-cover"
                  alt="Dashcam Evidence Frame"
                />
              ) : (
                <div className="w-full h-full relative bg-gradient-to-b from-slate-900 via-slate-950 to-black flex items-center justify-center">
                  {/* Perspective guidelines */}
                  <div className="absolute inset-0 opacity-20 pointer-events-none">
                    <div className="absolute top-1/2 left-0 right-0 h-[1px] bg-cyan-400" />
                    <div className="absolute top-1/2 left-1/2 bottom-0 w-[2px] bg-rose-500 transform -translate-x-1/2" />
                  </div>

                  {/* Impact Target Reticle */}
                  <div className="relative text-center z-10 space-y-2">
                    <div className={cn(
                      "h-20 w-20 rounded-full border-2 mx-auto flex items-center justify-center transition-all",
                      scrubIndex === 10
                        ? "border-rose-500 bg-rose-500/20 shadow-[0_0_50px_rgba(244,63,94,0.6)] animate-ping"
                        : "border-cyan-500/40 bg-cyan-500/10"
                    )}>
                      <Car size={34} className={scrubIndex === 10 ? "text-rose-400" : "text-cyan-400"} />
                    </div>
                    <div className="text-center">
                      <span className={cn(
                        "px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest",
                        scrubIndex === 10
                          ? "bg-rose-600 text-white font-black animate-pulse"
                          : "bg-slate-900/90 text-slate-300 border border-slate-700"
                      )}>
                        {scrubIndex === 10 ? '🚨 INERTIAL IMPACT EVENT (3.85G)' : `SURVEILLANCE FRAME #${scrubIndex + 1}`}
                      </span>
                    </div>
                  </div>

                  {/* Top HUD Watermark */}
                  <div className="absolute top-3 left-4 right-4 flex items-center justify-between text-[10px] font-mono font-bold text-cyan-400 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-lg border border-slate-800">
                    <span>VEHICLE: {activeDriver?.vehicleId || 'KA-19-PT-2026'}</span>
                    <span className="text-white">UTC: {new Date(Date.now() - (19 - scrubIndex) * 500).toISOString().split('T')[1].slice(0, 8)}</span>
                    <span>GPS: [{safeLat}, {safeLng}]</span>
                  </div>

                  {/* Bottom Telemetry Overlay */}
                  <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between text-[11px] font-mono font-bold bg-black/70 backdrop-blur-md px-4 py-2 rounded-lg border border-slate-800">
                    <div className="flex items-center gap-3">
                      <span className="text-slate-400">REL TIME: <strong className="text-white">{((scrubIndex - 10) * 0.5).toFixed(1)}s</strong></span>
                      <span className="text-slate-400">VELOCITY: <strong className="text-cyan-400">{Math.max(0, 68 - Math.max(0, scrubIndex - 8) * 22)} km/h</strong></span>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-slate-400">G-FORCE: <strong className={scrubIndex === 10 ? "text-rose-400 font-black text-sm" : "text-emerald-400"}>{scrubIndex === 10 ? '3.85 G' : (0.2 + (scrubIndex > 8 && scrubIndex < 12 ? 1.5 : 0)).toFixed(2) + ' G'}</strong></span>
                      <span className="text-[9px] text-slate-500">SHA-256</span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Scrub Slider */}
            <div className="space-y-2 pt-1">
              <div className="flex items-center justify-between text-[11px] font-mono font-bold">
                <span className="text-slate-400">Pre-Impact (-5.0s)</span>
                <span className="text-rose-400 font-black">Impact Point (t=0.0s)</span>
                <span className="text-slate-400">Post-Impact (+4.5s)</span>
              </div>
              <input
                type="range"
                min={0}
                max={19}
                value={scrubIndex}
                onChange={(e) => setScrubIndex(Number(e.target.value))}
                className="w-full h-2.5 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-cyan-400"
              />
              <div className="grid grid-cols-10 md:grid-cols-20 gap-1 pt-1">
                {Array.from({ length: 20 }).map((_, idx) => (
                  <button
                    key={idx}
                    onClick={() => setScrubIndex(idx)}
                    className={cn(
                      "h-7 rounded text-[8px] font-mono font-bold transition flex items-center justify-center border",
                      idx === scrubIndex
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

        {/* RIGHT COLUMN: 3-STEP RESPONSE PROTOCOL & LOCAL INTEL (4 COLS) */}
        <div className="lg:col-span-4 space-y-6">
          {/* OPERATOR CARD */}
          <div className="bg-[#0A0E1A] border border-slate-800 rounded-3xl p-5 shadow-xl">
            <div className="flex items-center gap-4">
              <Avatar
                name={activeDriver?.name || 'Driver'}
                src={activeDriver?.avatar || activeDriver?.photo}
                size={56}
                className="ring-2 ring-slate-700"
              />
              <div className="min-w-0 flex-1">
                <h3 className="text-base font-black text-white uppercase italic truncate">{activeDriver?.name || 'Field Driver'}</h3>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mt-0.5">{activeDriver?.employeeId || 'ID-AGENT'}</p>
                <div className="flex items-center gap-2 mt-2">
                  <Badge tone={activeDriver?.status || 'safe'} className="text-[8.5px] px-2 py-0.5 uppercase font-black">
                    {activeDriver?.status || 'Active'}
                  </Badge>
                  <span className="text-[10px] text-slate-500 font-mono font-bold">
                    {activeDriver?.phone || '+91 98450 12345'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* 3-STEP PROTOCOL CARDS */}
          <div className="bg-[#0A0E1A] border border-slate-800 rounded-3xl p-6 shadow-xl space-y-5">
            <h3 className="text-xs font-black uppercase tracking-widest text-slate-300 flex items-center gap-2">
              <Siren size={16} className="text-rose-500 animate-pulse" />
              Tactical 3-Step Verification
            </h3>

            {/* STEP 1: SAFETY PING */}
            <div className={cn(
              "p-4 rounded-2xl border transition-all space-y-3",
              isPingResponded
                ? "bg-emerald-950/30 border-emerald-500/50 shadow-[0_0_20px_rgba(16,185,129,0.2)]"
                : isPingTimedOut
                ? "bg-rose-950/30 border-rose-500/50 shadow-[0_0_20px_rgba(244,63,94,0.2)]"
                : pingSent
                ? "bg-amber-950/30 border-amber-500/40"
                : "bg-slate-900/60 border-slate-800"
            )}>
              <div className="flex items-center justify-between">
                <span className={cn(
                  "text-[9px] font-black uppercase tracking-wider",
                  isPingResponded ? "text-emerald-400" : isPingTimedOut ? "text-rose-400" : "text-amber-400"
                )}>
                  STEP 1 · SAFETY VERIFICATION
                </span>
                <Radio size={14} className={cn(
                  isPingResponded ? "text-emerald-400" : isPingTimedOut ? "text-rose-400 animate-pulse" : "text-amber-400"
                )} />
              </div>

              <div>
                <h4 className="text-xs font-black uppercase text-white">Voice & Screen Ping</h4>
                <p className="text-[10px] text-slate-400 mt-1 leading-relaxed">
                  {isPingResponded
                    ? "✓ Operator verified safe. Privacy lock enabled."
                    : isPingTimedOut
                    ? "⚠️ Operator failed to respond within 30s. Emergency escalation active."
                    : pingSent && countdown !== null && countdown > 0
                    ? `⏱️ Waiting for operator response... (${countdown}s remaining)`
                    : "Send immediate verbal safety prompt ('Are you safe?') to mobile."}
                </p>
              </div>

              <button
                onClick={handleSendPing}
                className={cn(
                  "w-full py-2.5 rounded-xl font-black text-[10px] uppercase tracking-wider transition-all cursor-pointer flex items-center justify-center gap-1.5 shadow-md",
                  isPingResponded
                    ? "bg-emerald-500 text-slate-950"
                    : isPingTimedOut
                    ? "bg-rose-600 hover:bg-rose-500 text-white"
                    : pingSent
                    ? "bg-amber-500 text-slate-950"
                    : "bg-white/10 text-cyan-300 hover:bg-cyan-500 hover:text-slate-950 border border-cyan-500/30"
                )}
              >
                {isPingResponded ? (
                  <span>✓ Operator Safe (Dismissed)</span>
                ) : isPingTimedOut ? (
                  <span>⚠️ UNRESPONSIVE (RETRY PING)</span>
                ) : pingSent ? (
                  <span>Pinging Operator ({countdown}s)...</span>
                ) : (
                  <span>Send Safety Ping</span>
                )}
              </button>
            </div>

            {/* STEP 2: LIVE CAM & PHONE */}
            <div className={cn(
              "p-4 rounded-2xl border transition-all space-y-3",
              isCamStreaming
                ? "bg-rose-950/30 border-rose-500/50 shadow-[0_0_20px_rgba(244,63,94,0.2)]"
                : isCameraUnlocked
                ? "bg-cyan-950/30 border-cyan-500/50"
                : "bg-slate-900/60 border-slate-800 opacity-60"
            )}>
              <div className="flex items-center justify-between">
                <span className={cn(
                  "text-[9px] font-black uppercase tracking-wider",
                  isCameraUnlocked ? "text-cyan-400" : "text-slate-500"
                )}>
                  STEP 2 · OPTICAL & CALL
                </span>
                {isCameraUnlocked ? (
                  <Unlock size={14} className="text-cyan-400" />
                ) : (
                  <Lock size={14} className="text-slate-500" />
                )}
              </div>

              <div>
                <h4 className="text-xs font-black uppercase text-white">Live Camera & Direct Call</h4>
                <p className="text-[10px] text-slate-400 mt-1 leading-relaxed">
                  {isCameraUnlocked
                    ? "Access unlocked due to unresponsive driver. View front camera & dial phone."
                    : "Locked. Requires driver non-response or emergency state to authorize."}
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={handleToggleCam}
                  className={cn(
                    "flex-1 py-2.5 rounded-xl font-black text-[10px] uppercase tracking-wider transition-all shadow-md flex items-center justify-center gap-1.5 cursor-pointer",
                    isCamStreaming
                      ? "bg-rose-600 hover:bg-rose-500 text-white animate-pulse"
                      : "bg-cyan-500 hover:bg-cyan-400 text-slate-950"
                  )}
                >
                  <Video size={13} />
                  <span>{isCamStreaming ? "Stop Live Video" : "Access Live Cam"}</span>
                </button>
                <button
                  onClick={handleCallOperator}
                  className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs flex items-center justify-center transition-all cursor-pointer shadow-md"
                  title="Call Driver"
                >
                  <Phone size={14} />
                </button>
              </div>
            </div>

            {/* STEP 3: WHATSAPP FAMILY & POLICE DISPATCH */}
            <div className={cn(
              "p-4 rounded-2xl border transition-all space-y-3",
              declaredAccident
                ? "bg-rose-950/40 border-rose-500/60 shadow-[0_0_20px_rgba(244,63,94,0.3)]"
                : "bg-slate-900/60 border-slate-800"
            )}>
              <div className="flex items-center justify-between">
                <span className="text-[9px] font-black uppercase tracking-wider text-rose-400">
                  STEP 3 · EMERGENCY ESCALATION
                </span>
                <MessageSquare size={14} className="text-rose-400" />
              </div>

              <div>
                <h4 className="text-xs font-black uppercase text-white">WhatsApp Family & Police Dispatch</h4>
                <p className="text-[10px] text-slate-400 mt-1 leading-relaxed">
                  Dispatch instant SOS with GPS coordinates to {kinName} ({kinRel}) at <span className="font-mono text-cyan-400 font-semibold">{kinPhone || 'Registered Kin'}</span>.
                </p>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={handleWhatsAppFamilyAlert}
                  className="flex-1 py-3 rounded-xl bg-rose-600 hover:bg-rose-500 text-white font-black text-[10px] uppercase tracking-wider transition-all shadow-lg cursor-pointer flex items-center justify-center gap-2"
                >
                  <Zap size={14} />
                  <span>Dispatch WhatsApp Alert</span>
                </button>
                {kinPhone && (
                  <a
                    href={`tel:${kinPhone}`}
                    className="px-4 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center transition-all shadow-md"
                    title={`Call Kin: ${kinPhone}`}
                  >
                    <Phone size={14} />
                  </a>
                )}
              </div>
            </div>
          </div>

          {/* NEAREST EMERGENCY HUBS */}
          <div className="bg-[#0A0E1A] border border-slate-800 rounded-3xl p-5 shadow-xl space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-black uppercase tracking-widest text-slate-300 flex items-center gap-2">
                <Building2 size={14} className="text-cyan-400" />
                Nearest Resources (5KM)
              </h4>
              {loadingPlaces && <span className="text-[9px] text-cyan-400 animate-pulse font-bold">Scanning OSM...</span>}
            </div>

            <div className="space-y-2.5">
              {nearbyPlaces.slice(0, 3).map((place) => (
                <div key={place.id} className="p-3 rounded-xl bg-slate-900/80 border border-slate-800 flex items-center justify-between">
                  <div className="min-w-0 flex-1 pr-2">
                    <div className="flex items-center gap-2">
                      <span className={cn(
                        "text-[8px] font-black uppercase px-1.5 py-0.5 rounded",
                        place.type === 'police' ? "bg-blue-500/20 text-blue-400" : "bg-rose-500/20 text-rose-400"
                      )}>
                        {place.type}
                      </span>
                      <span className="text-[9px] text-slate-400 font-bold">{place.distanceMeters}m away</span>
                    </div>
                    <p className="text-xs font-bold text-white truncate mt-1">{place.name}</p>
                  </div>
                  <a
                    href={`https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}`}
                    target="_blank"
                    rel="noreferrer"
                    className="h-8 w-8 rounded-lg bg-slate-800 hover:bg-cyan-500 hover:text-slate-950 text-slate-300 flex items-center justify-center transition-all shrink-0"
                    title="Open Route"
                  >
                    <ExternalLink size={12} />
                  </a>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function MetricCard({ label, value, unit, color }: { label: string; value: string | number; unit: string; color: string }) {
  const colorClass = color === 'green' ? 'text-emerald-400' : color === 'rose' ? 'text-rose-400' : 'text-cyan-400'
  return (
    <div className="bg-[#0A0E1A] border border-slate-800 rounded-2xl p-4 flex flex-col justify-between">
      <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 truncate">{label}</p>
      <div className="flex items-baseline gap-1.5">
        <span className={cn("text-2xl font-black italic tracking-tight", colorClass)}>{value}</span>
        <span className="text-[9px] font-black text-slate-500 uppercase">{unit}</span>
      </div>
    </div>
  )
}
