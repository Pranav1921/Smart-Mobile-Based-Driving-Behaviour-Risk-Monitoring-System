import { useState, useEffect, useMemo } from 'react'
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom'
import { AppShell } from './components/layout/AppShell'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard'
import LiveMap from './pages/LiveMap'
import Drivers from './pages/Drivers'
import Requests from './pages/Requests'
import Events from './pages/Events'
import Orders from './pages/Orders'
import Profile from './pages/Profile'
import CrashInvestigation from './pages/CrashInvestigation'
import Reports from './pages/Reports'
import PublicLiveTrack from './pages/PublicLiveTrack'
import { SocketProvider, useSocket } from './hooks/SocketContext'
import { 
  TriangleAlert as AlertTriangle, 
  UserCheck, 
  CheckCircle2, 
  XCircle, 
  Wrench, 
  Truck, 
  PhoneCall, 
  MapPin, 
  Video, 
  Radio, 
  ShieldAlert, 
  MessageSquare, 
  ExternalLink, 
  Siren 
} from 'lucide-react'

import { DriverDetailModal } from './components/drivers/DriverDetailModal'
import type { Driver } from './types'

export default function App() {
  return (
    <SocketProvider>
      <AppContent />
    </SocketProvider>
  )
}

function AppContent() {
  const navigate = useNavigate()
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null)
  const {
    liveDrivers,
    crashAlertDriver,
    setCrashAlertDriver,
    sosAlertDriver,
    setSosAlertDriver,
    deadZoneToast,
    dismissDeadZoneToast,
    driverOnlineToast,
    jobResponseToast,
    newRequestToast,
    dismissNewRequestToast,
    emitIncidentResolved,
    breakdownAlert,
    setBreakdownAlert,
    emitLiveCamRequest,
    liveFrame,
  } = useSocket()
  const [dismissedIncidentId, setDismissedIncidentId] = useState<string | null>(null)
  const [selectedProtocolDriver, setSelectedProtocolDriver] = useState<Driver | null>(null)
  const [decisionToast, setDecisionToast] = useState<{ type: 'approve' | 'reject'; name: string; detail: string } | null>(null)
  const [roadsideToast, setRoadsideToast] = useState<string | null>(null)

  useEffect(() => {
    const handleDecision = (e: any) => {
      if (e.detail) {
        setDecisionToast(e.detail)
        setTimeout(() => setDecisionToast(null), 5500)
      }
    }
    window.addEventListener('smartdrive_candidate_decision', handleDecision)
    return () => window.removeEventListener('smartdrive_candidate_decision', handleDecision)
  }, [])

  // Active incident data resolution
  const emergencyDriver = liveDrivers.find((d) => d.status === 'emergency')
  const activeIncident = sosAlertDriver || crashAlertDriver || breakdownAlert || (emergencyDriver ? {
    id: emergencyDriver.id,
    driverId: emergencyDriver.id,
    driverName: emergencyDriver.name,
    latitude: emergencyDriver.location?.lat ?? 12.7749,
    longitude: emergencyDriver.location?.lng ?? 75.2023,
    status: 'emergency',
    alertType: (emergencyDriver as any).alertType || 'SOS',
    reason: (emergencyDriver as any).sosReason || 'Emergency status active',
  } : null)

  const isSos = Boolean(
    sosAlertDriver || 
    activeIncident?.alertType === 'SOS' || 
    (emergencyDriver && (emergencyDriver as any).alertType === 'SOS') ||
    (activeIncident?.reason && activeIncident.reason.toLowerCase().includes('sos'))
  )
  const isBreakdown = Boolean(breakdownAlert && !isSos)
  const isCrash = Boolean(crashAlertDriver && !isSos && !isBreakdown)
  const isAlertActive = Boolean(activeIncident)

  const rawDriverName = String(
    sosAlertDriver?.driverName || 
    breakdownAlert?.driverName || 
    crashAlertDriver?.driverName || 
    emergencyDriver?.name || 
    'Pranav'
  )
  const cleanDriverName = rawDriverName.replace(/\s+applicant$/i, '').trim() || 'Pranav'
  const activeDriverId = 
    sosAlertDriver?.driverId || 
    breakdownAlert?.driverId || 
    crashAlertDriver?.driverId || 
    crashAlertDriver?.id || 
    emergencyDriver?.id || 
    ''
  
  const matchedDriver = liveDrivers.find(d => d.id === activeDriverId || d.userId === activeDriverId)
  const driverPhone = matchedDriver?.phone || (matchedDriver as any)?.phoneNumber || '+91 94812 55667'
  const vehiclePlate = breakdownAlert?.vehiclePlate || (matchedDriver as any)?.vehiclePlate || matchedDriver?.vehicleId || 'KA-19-PT-2026'
  const emergencyContactName = (matchedDriver as any)?.emergencyContactName || (matchedDriver as any)?.guardianName || 'Family Kin'
  const emergencyContactPhone = (matchedDriver as any)?.emergencyContactPhone || (matchedDriver as any)?.guardianPhone || '+91 94812 55667'

  const activeLat = (sosAlertDriver?.latitude && sosAlertDriver.latitude !== 0)
    ? sosAlertDriver.latitude
    : ((breakdownAlert?.latitude && breakdownAlert.latitude !== 0)
      ? breakdownAlert.latitude
      : ((crashAlertDriver?.latitude && crashAlertDriver.latitude !== 0)
        ? crashAlertDriver.latitude
        : ((emergencyDriver?.location?.lat && emergencyDriver.location.lat !== 0)
          ? emergencyDriver.location.lat
          : 12.7749)))

  const activeLng = (sosAlertDriver?.longitude && sosAlertDriver.longitude !== 0)
    ? sosAlertDriver.longitude
    : ((breakdownAlert?.longitude && breakdownAlert.longitude !== 0)
      ? breakdownAlert.longitude
      : ((crashAlertDriver?.longitude && crashAlertDriver.longitude !== 0)
        ? crashAlertDriver.longitude
        : ((emergencyDriver?.location?.lng && emergencyDriver.location.lng !== 0)
          ? emergencyDriver.location.lng
          : 75.2023)))

  const [isCameraActive, setIsCameraActive] = useState<boolean>(false)

  const handleToggleDriverCamera = () => {
    const nextState = !isCameraActive
    setIsCameraActive(nextState)
    if (activeDriverId) {
      emitLiveCamRequest(activeDriverId, nextState)
      if (matchedDriver?.userId && matchedDriver.userId !== activeDriverId) {
        emitLiveCamRequest(matchedDriver.userId, nextState)
      }
    }
  }

  const handleConfirmOperatorSafe = () => {
    if (activeDriverId) {
      emitIncidentResolved(activeDriverId)
    }
    if (isCameraActive) {
      emitLiveCamRequest(activeDriverId, false)
      setIsCameraActive(false)
    }
    setCrashAlertDriver(null)
    setSosAlertDriver(null)
    setBreakdownAlert(null)
  }

  const handleDismissAlert = () => {
    if (isCameraActive && activeDriverId) {
      emitLiveCamRequest(activeDriverId, false)
      setIsCameraActive(false)
    }
    setCrashAlertDriver(null)
    setSosAlertDriver(null)
    setBreakdownAlert(null)
  }

  const handleSendWhatsAppSos = () => {
    const mapsUrl = `https://maps.google.com/?q=${activeLat},${activeLng}`
    const message = `🚨 *SMARTDRIVE SOS ALERT* 🚨\n\nOperator *${cleanDriverName}* (${vehiclePlate}) has triggered an Emergency SOS Panic Beacon near Puttur Sector.\n\n📍 *Live Location*: ${mapsUrl}\n⏱️ *Time*: ${new Date().toLocaleTimeString()}\n\nFleet dispatch has initiated response protocols.`
    const cleanPhone = emergencyContactPhone.replace(/[^0-9]/g, '')
    const targetUrl = cleanPhone ? `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}` : `https://wa.me/?text=${encodeURIComponent(message)}`
    window.open(targetUrl, '_blank')
  }

  const handleOpenProtocolModal = () => {
    let target = liveDrivers.find(d => d.id === activeDriverId || d.userId === activeDriverId)
    if (!target && emergencyDriver) target = emergencyDriver
    if (!target && activeIncident) {
      target = {
        id: activeDriverId || 'emergency-driver',
        userId: activeDriverId || 'emergency-driver',
        name: cleanDriverName,
        employeeId: `AGENT-${(activeDriverId || '0000').slice(0, 4).toUpperCase()}`,
        status: 'emergency',
        driverType: 'TACTICAL',
        vehicleId: 'v-live',
        industry: 'Logistics',
        fleet: 'Smart Fleet Tactical',
        safetyScore: 0,
        riskScore: 95,
        crashProbability: 90,
        speed: 0,
        location: { lat: activeLat, lng: activeLng },
        locationName: 'Puttur Sector',
        photo: '',
        heading: 0,
        route: [],
        distanceToday: 0,
        tripDurationMin: 0,
        drivingHours: 0,
        trips: 0,
        battery: 100,
        internet: 100,
        gps: true,
        camera: false,
        sensors: true,
        ble: false,
        overspeedCount: 0,
        harshBrakingCount: 0,
        sharpTurnCount: 0,
        points: 0,
        earnings: 0,
        weeklyTrend: 0,
        monthlyTrend: 0,
        drivingStyle: 'Tactical',
        aggressive: 0,
        recommendation: 'Emergency SOS protocol active.',
      } as Driver
    }
    if (!target && liveDrivers.length > 0) target = liveDrivers[0]
    setSelectedProtocolDriver(target || null)
  }

  const liveSelectedProtocolDriver = useMemo(() => {
    if (!selectedProtocolDriver) return null
    return liveDrivers.find(d => d.id === selectedProtocolDriver.id || d.userId === selectedProtocolDriver.id) || selectedProtocolDriver
  }, [liveDrivers, selectedProtocolDriver])

  useEffect(() => {
    const token = localStorage.getItem('smartdrive_real_backend_token') || localStorage.getItem('fg_real_backend_token') || localStorage.getItem('smartdrive_jwt_token')
    setIsAuthenticated(!!token)
  }, [])

  // Public family/client tracking route requires no admin authentication
  if (window.location.pathname.startsWith('/track/')) {
    return (
      <Routes>
        <Route path="/track/:driverId" element={<PublicLiveTrack />} />
      </Routes>
    )
  }

  if (isAuthenticated === null) {
    return (
      <div className="fixed inset-0 grid place-items-center bg-[#070b18] text-cyan-400 font-display font-medium">
        Loading Command Center...
      </div>
    )
  }

  if (!isAuthenticated) {
    return <LoginPage onLogin={() => setIsAuthenticated(true)} />
  }

  return (
    <div className="relative min-h-screen">
      {/* HIGH-TECH TACTICAL EMERGENCY HUD: DEDICATED SOS vs CRASH vs BREAKDOWN */}
      {isAlertActive && (
        <div className={`fixed bottom-6 right-6 z-[99999] max-w-md w-full p-4 rounded-2xl text-white backdrop-blur-2xl animate-in fade-in slide-in-from-bottom-5 font-sans transition-all duration-300 ${
          isSos 
            ? 'bg-gradient-to-b from-[#1c0810]/98 via-[#130713]/98 to-[#090b16]/98 border-2 border-rose-500/80 shadow-[0_15px_55px_rgba(244,63,94,0.45)] ring-1 ring-rose-400/40' 
            : isCrash 
            ? 'bg-gradient-to-b from-[#1f0909]/98 via-[#14080d]/98 to-[#090b16]/98 border-2 border-red-600/90 shadow-[0_15px_55px_rgba(239,68,68,0.45)] ring-1 ring-red-500/40'
            : 'bg-[#0a0f1d]/95 border-2 border-amber-500/70 shadow-[0_12px_45px_rgba(245,158,11,0.35)]'
        }`}>
          {/* Top Bar with Pulsing Radar Beacon */}
          <div className={`flex items-center justify-between pb-3 border-b ${
            isSos ? 'border-rose-900/50' : isCrash ? 'border-red-900/50' : 'border-amber-900/40'
          }`}>
            <div className="flex items-center gap-2.5">
              <span className="relative flex h-3.5 w-3.5">
                <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${
                  isSos ? 'bg-rose-400' : isCrash ? 'bg-red-500' : 'bg-amber-400'
                }`}></span>
                <span className={`relative inline-flex rounded-full h-3.5 w-3.5 ${
                  isSos ? 'bg-rose-500' : isCrash ? 'bg-red-600' : 'bg-amber-500'
                }`}></span>
              </span>
              <div>
                <div className={`text-[12px] font-black uppercase tracking-wider flex items-center gap-1.5 ${
                  isSos ? 'text-rose-400' : isCrash ? 'text-red-400' : 'text-amber-400'
                }`}>
                  {isSos ? (
                    <>
                      <Radio size={14} className="animate-pulse" />
                      <span>DRIVER EMERGENCY SOS</span>
                    </>
                  ) : isCrash ? (
                    <>
                      <ShieldAlert size={14} className="animate-pulse" />
                      <span>VEHICLE IMPACT DETECTED</span>
                    </>
                  ) : (
                    <>
                      <Wrench size={14} />
                      <span>ROADSIDE ASSISTANCE</span>
                    </>
                  )}
                </div>
                <div className="text-[9px] font-mono text-slate-400">
                  {isSos 
                    ? 'MANUAL OPERATOR PANIC BEACON' 
                    : isCrash 
                    ? 'PHYSICAL SENSOR COLLISION SHOCK' 
                    : 'VEHICLE MECHANICAL BREAKDOWN'}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <span className={`px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider border ${
                isSos 
                  ? 'bg-rose-500/20 text-rose-300 border-rose-500/40' 
                  : isCrash 
                  ? 'bg-red-500/20 text-red-400 border-red-500/40' 
                  : 'bg-amber-500/20 text-amber-300 border-amber-500/40'
              }`}>
                {isSos 
                  ? 'PANIC BEACON' 
                  : isCrash 
                  ? 'CRASH IMPACT' 
                  : (breakdownAlert?.issueType || 'STALLED')}
              </span>
              <button
                onClick={handleDismissAlert}
                className="text-slate-400 hover:text-white p-1 rounded hover:bg-slate-800 transition cursor-pointer text-xs"
                title="Dismiss Alert"
              >
                ✕
              </button>
            </div>
          </div>

          {/* Incident Headline Details */}
          <div className="mt-3 flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center font-black text-sm shrink-0 border ${
                isSos 
                  ? 'bg-rose-600/30 text-rose-300 border-rose-500/40' 
                  : isCrash 
                  ? 'bg-red-600/30 text-red-300 border-red-500/40' 
                  : 'bg-amber-600/30 text-amber-300 border-amber-500/40'
              }`}>
                {cleanDriverName.charAt(0).toUpperCase()}
              </div>
              <div>
                <div className="text-base font-black uppercase tracking-tight text-white flex items-center gap-2">
                  <span>{cleanDriverName}</span>
                  <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700">
                    {vehiclePlate}
                  </span>
                </div>
                <div className="text-[11px] text-slate-300 font-medium mt-0.5">
                  {isSos 
                    ? (activeIncident?.reason || 'Operator triggered manual SOS panic beacon') 
                    : isCrash 
                    ? (activeIncident?.reason || '4.5G Inertial impact & sudden deceleration detected') 
                    : `${breakdownAlert?.issueType || 'Vehicle Stalled'} • Requesting Tow`}
                </div>
              </div>
            </div>

            <a
              href={`https://www.google.com/maps/search/?api=1&query=${activeLat},${activeLng}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[10px] font-extrabold text-cyan-400 hover:underline flex items-center gap-1 bg-cyan-950/60 px-2.5 py-1.5 rounded-lg border border-cyan-500/40 shrink-0 hover:bg-cyan-900/60 transition"
            >
              <MapPin size={11} />
              <span>Map ↗</span>
            </a>
          </div>

          {/* Coordinates Bar */}
          <div className="text-[10px] font-mono text-slate-400 mt-2 flex items-center justify-between bg-black/40 px-2.5 py-1.5 rounded-lg border border-slate-800">
            <span>📍 {activeLat.toFixed(4)}, {activeLng.toFixed(4)} • Puttur Transit Corridor</span>
            <span className="text-slate-500 font-sans">⏱️ Active Incident</span>
          </div>

          {/* Primary Response Grid */}
          <div className="mt-3 grid grid-cols-2 gap-2">
            <a
              href={`tel:${driverPhone}`}
              className="py-2 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-[11px] font-black uppercase tracking-wider flex items-center justify-center gap-2 transition shadow-sm truncate active:scale-95"
            >
              <PhoneCall size={12} />
              <span className="truncate">Call Driver</span>
            </a>
            <button
              onClick={handleToggleDriverCamera}
              className={`py-2 px-3 rounded-xl text-[11px] font-black uppercase tracking-wider flex items-center justify-center gap-2 transition border cursor-pointer active:scale-95 ${
                isCameraActive
                  ? 'bg-red-600 text-white border-red-400 animate-pulse'
                  : 'bg-slate-800 hover:bg-slate-700 text-cyan-300 border-cyan-500/30'
              }`}
            >
              <Video size={12} />
              <span>{isCameraActive ? 'Close Cam' : 'Live Dashcam'}</span>
            </button>
          </div>

          {/* Camera Feed Viewer (Smooth Inline Drawer) */}
          {isCameraActive && (
            <div className="mt-2.5 p-2 rounded-xl bg-black border border-cyan-500/60 animate-in fade-in">
              <div className="flex items-center justify-between pb-1.5 mb-1.5 border-b border-cyan-900/40 text-[9px] font-mono text-cyan-400 font-bold">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                  🔴 LIVE IN-CABIN DASHCAM FEED
                </span>
                <span className="text-slate-400">1080P HD STREAM</span>
              </div>
              {liveFrame ? (
                <img
                  src={liveFrame.startsWith('data:') ? liveFrame : `data:image/jpeg;base64,${liveFrame}`}
                  alt="Driver Live Camera"
                  className="w-full h-36 object-cover rounded-lg border border-cyan-500/30 shadow-inner"
                />
              ) : (
                <div className="w-full h-32 rounded-lg bg-slate-950 flex flex-col items-center justify-center text-center p-3">
                  <div className="w-5 h-5 border-2 border-cyan-400 border-t-transparent rounded-full animate-spin mb-2" />
                  <p className="text-[10px] font-bold text-cyan-300">Connecting to Mobile Dashcam Stream...</p>
                  <p className="text-[9px] text-slate-500 font-mono mt-0.5">Awaiting live frame sync over tailscale mesh</p>
                </div>
              )}
            </div>
          )}

          {/* SOS Specific Actions: WhatsApp Parent Alert */}
          {isSos && (
            <div className="mt-2.5 p-2.5 rounded-xl bg-rose-950/30 border border-rose-500/30 flex items-center justify-between gap-2">
              <div className="min-w-0">
                <div className="text-[10px] font-bold text-rose-300 truncate">
                  👨‍👩‍👧 Kin: {emergencyContactName} ({emergencyContactPhone})
                </div>
                <div className="text-[9px] text-slate-400 font-mono truncate">
                  Send pre-filled WhatsApp alert with live GPS
                </div>
              </div>
              <button
                onClick={handleSendWhatsAppSos}
                className="py-1.5 px-3 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-[9px] font-black uppercase tracking-wider shrink-0 transition flex items-center gap-1 active:scale-95 cursor-pointer shadow"
              >
                <MessageSquare size={11} />
                <span>WhatsApp</span>
              </button>
            </div>
          )}

          {/* Breakdown Specific Tow Truck Hotline */}
          {isBreakdown && (
            <div className="mt-2.5 p-2 rounded-xl bg-amber-950/30 border border-amber-500/30 flex items-center justify-between gap-2">
              <div className="text-[10px] font-bold text-amber-300 truncate">
                🚛 Tow Hotline: Puttur 24x7 (+91 94812 55667)
              </div>
              <a
                href="tel:+919481255667"
                className="py-1 px-2.5 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 text-[9px] font-black uppercase tracking-wider shrink-0 transition"
              >
                Call Tow
              </a>
            </div>
          )}

          {/* Bottom Control Bar: Confirm Safe vs Protocol */}
          <div className="mt-3 grid grid-cols-2 gap-2">
            <button
              onClick={handleConfirmOperatorSafe}
              className="py-2.5 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-black text-[11px] uppercase tracking-wider transition shadow-md cursor-pointer flex items-center justify-center gap-1.5 active:scale-95"
            >
              <CheckCircle2 size={13} />
              <span>Confirm Safe</span>
            </button>
            <button
              onClick={handleOpenProtocolModal}
              className={`py-2.5 px-3 rounded-xl font-black text-[11px] uppercase tracking-wider transition shadow-md cursor-pointer flex items-center justify-center gap-1.5 active:scale-95 ${
                isSos 
                  ? 'bg-rose-600 hover:bg-rose-500 text-white' 
                  : isCrash 
                  ? 'bg-red-600 hover:bg-red-500 text-white' 
                  : 'bg-amber-500 hover:bg-amber-400 text-slate-950'
              }`}
            >
              <AlertTriangle size={13} />
              <span>Protocol ↗</span>
            </button>
          </div>
        </div>
      )}

      {liveSelectedProtocolDriver && (
        <DriverDetailModal
          driver={liveSelectedProtocolDriver}
          initialTab="crisis"
          onClose={() => setSelectedProtocolDriver(null)}
        />
      )}

      <div>
        {/* Real-time Notifications: Dead Zone Sync / Driver Online / Job Response / New Onboarding Requests / Candidate Decision */}
        {(deadZoneToast || driverOnlineToast || jobResponseToast || newRequestToast || decisionToast) && (
          <div className="fixed top-4 right-4 z-[99998] flex flex-col gap-2.5 max-w-md pointer-events-none">
            {deadZoneToast && (
              <div className="bg-slate-900/95 border-2 border-cyan-500/80 text-white text-xs p-4 rounded-2xl shadow-2xl backdrop-blur-md flex items-center justify-between gap-4 pointer-events-auto transition-all animate-in fade-in slide-in-from-top-3">
                <div className="flex items-center gap-3 min-w-0">
                  <span className="p-2.5 rounded-xl bg-cyan-500 text-slate-950 font-black text-sm shrink-0">
                    📡
                  </span>
                  <div className="min-w-0">
                    <div className="font-black text-xs uppercase tracking-wider text-cyan-400">
                      Ghat Dead Zone Telemetry Synced
                    </div>
                    <div className="text-[11px] text-slate-300 font-medium truncate mt-0.5">
                      Recovered <strong className="text-white">{deadZoneToast.count} buffered GPS points</strong> from {deadZoneToast.driverName}.
                    </div>
                  </div>
                </div>
                <button
                  onClick={dismissDeadZoneToast}
                  className="text-slate-400 hover:text-white p-1 rounded hover:bg-slate-800 text-xs shrink-0 cursor-pointer"
                  title="Dismiss"
                >
                  ✕
                </button>
              </div>
            )}
            {newRequestToast && (
              <div
                onClick={() => {
                  dismissNewRequestToast()
                  if (newRequestToast.id) {
                    localStorage.setItem('smartdrive_inspect_request_id', newRequestToast.id)
                  }
                  navigate('/requests')
                }}
                className="bg-slate-900/95 dark:bg-slate-950/95 border-2 border-amber-500/70 text-white text-xs p-4 rounded-2xl shadow-2xl backdrop-blur-md flex items-center justify-between gap-4 pointer-events-auto transition-all animate-bounce cursor-pointer hover:border-amber-400"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <span className="p-2 rounded-xl bg-amber-500 text-slate-950 font-black shrink-0">
                    <UserCheck size={20} />
                  </span>
                  <div className="min-w-0">
                    <div className="font-black text-xs uppercase tracking-tight text-amber-400">
                      New Driver Onboarding Request!
                    </div>
                    <div className="text-[11px] text-slate-300 font-medium truncate mt-0.5">
                      <strong className="text-white">{newRequestToast.name}</strong> applied from <span className="text-amber-300">{newRequestToast.zone}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      dismissNewRequestToast()
                      if (newRequestToast.id) {
                        localStorage.setItem('smartdrive_inspect_request_id', newRequestToast.id)
                      }
                      navigate('/requests')
                    }}
                    className="px-3.5 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider transition cursor-pointer shadow-md active:scale-95 whitespace-nowrap"
                  >
                    View Report →
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      dismissNewRequestToast()
                    }}
                    className="text-slate-400 hover:text-white p-1 cursor-pointer"
                    title="Dismiss"
                  >
                    ✕
                  </button>
                </div>
              </div>
            )}
            {decisionToast && (
              <div className={`p-4 rounded-2xl shadow-2xl backdrop-blur-md flex items-center justify-between gap-3 pointer-events-auto transition-all border ${
                decisionToast.type === 'approve'
                  ? 'bg-slate-950/95 border-emerald-500/70 text-white'
                  : 'bg-slate-950/95 border-red-500/70 text-white'
              }`}>
                <div className="flex items-center gap-3 min-w-0">
                  <span className={`p-2 rounded-xl shrink-0 font-black ${
                    decisionToast.type === 'approve' ? 'bg-emerald-500 text-slate-950' : 'bg-red-500 text-white'
                  }`}>
                    {decisionToast.type === 'approve' ? <CheckCircle2 size={18} /> : <XCircle size={18} />}
                  </span>
                  <div className="min-w-0">
                    <div className={`font-black text-xs uppercase tracking-tight ${
                      decisionToast.type === 'approve' ? 'text-emerald-400' : 'text-red-400'
                    }`}>
                      {decisionToast.type === 'approve' ? 'Candidate Admitted & Cleared' : 'Application Rejected'}
                    </div>
                    <div className="text-[11px] text-slate-300 font-medium truncate mt-0.5">
                      <strong className="text-white">{decisionToast.name}</strong> • {decisionToast.detail}
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => setDecisionToast(null)}
                  className="text-slate-400 hover:text-white p-1 cursor-pointer shrink-0"
                >
                  ✕
                </button>
              </div>
            )}
            {driverOnlineToast && (
              <div className="bg-emerald-900/90 border border-emerald-500/40 text-emerald-200 text-xs font-bold px-4 py-2.5 rounded-2xl shadow-xl backdrop-blur-sm flex items-center gap-2">
                {driverOnlineToast}
              </div>
            )}
            {jobResponseToast && (
              <div className="bg-slate-900/90 border border-white/10 text-white text-xs font-bold px-4 py-2.5 rounded-2xl shadow-xl backdrop-blur-sm flex items-center gap-2">
                {jobResponseToast}
              </div>
            )}
          </div>
        )}

        {roadsideToast && (
          <div className="fixed bottom-6 left-6 z-[99998] bg-amber-500 text-slate-950 px-5 py-3 rounded-2xl shadow-2xl font-black text-xs uppercase tracking-wider flex items-center gap-2">
            <Truck size={18} />
            <span>{roadsideToast}</span>
          </div>
        )}

        {roadsideToast && (
          <div className="fixed bottom-6 left-6 z-[99998] bg-amber-500 text-slate-950 px-5 py-3 rounded-2xl shadow-2xl font-black text-xs uppercase tracking-wider flex items-center gap-2">
            <Truck size={18} />
            <span>{roadsideToast}</span>
          </div>
        )}

        <Routes>
          <Route path="/track/:driverId" element={<PublicLiveTrack />} />
          <Route element={<AppShell />}>
            <Route path="/" element={<Dashboard />} />
            <Route path="/map" element={<LiveMap />} />
            <Route path="/requests" element={<Requests />} />
            <Route path="/drivers" element={<Drivers />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/events" element={<Events />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/investigation" element={<CrashInvestigation />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </div>
    </div>
  )
}
