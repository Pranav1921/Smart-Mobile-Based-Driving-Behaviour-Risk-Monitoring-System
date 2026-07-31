import { useState, useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { AppShell } from '@/components/layout/AppShell'
import LoginPage from '@/pages/LoginPage'
import Dashboard from '@/pages/Dashboard'
import LiveMap from '@/pages/LiveMap'
import Drivers from '@/pages/Drivers'
import Events from '@/pages/Events'
import { drivers as mockDrivers } from '@/data/mockData'
import { useSocketDrivers } from '@/hooks/useSocketDrivers'

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null)
  const { liveDrivers, crashAlertDriver, setCrashAlertDriver } = useSocketDrivers(mockDrivers)
  
  // Also check if any driver is in emergency status as fallback
  const hasEmergency = liveDrivers.some((d) => d.status === 'emergency')
  const showCrashAlert = hasEmergency || !!crashAlertDriver

  useEffect(() => {
    const token = localStorage.getItem('fleetguard_admin_token')
    setIsAuthenticated(!!token)
  }, [])

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
      {showCrashAlert && (
        <div className="fixed top-0 left-0 right-0 z-[99999] bg-gradient-to-r from-rose-600 via-red-600 to-rose-700 text-white px-4 py-3 flex items-center justify-between shadow-2xl font-sans text-[13px] sm:text-[14px] font-semibold border-b border-red-500/20">
          <div className="flex items-center gap-3 min-w-0">
            <span className="flex h-3 w-3 relative shrink-0">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-white"></span>
            </span>
            <span className="truncate">
              🚨 <span className="font-bold text-yellow-300">CRITICAL COLLISION:</span> {crashAlertDriver?.driverName ?? 'Suresh Nayak'} — Impact detected! Inactivity alert armed.
            </span>
          </div>
          <div className="flex items-center gap-3 shrink-0 ml-4">
            <button
              onClick={() => {
                localStorage.setItem('select_driver_id', crashAlertDriver?.driverId ?? 'd3')
                window.location.href = '/map'
              }}
              className="bg-white text-rose-600 px-3.5 py-1.5 rounded-xl text-xs font-bold shadow-md hover:bg-slate-100 hover:scale-105 active:scale-95 transition-all cursor-pointer"
            >
              View Feed & Location
            </button>
            <button onClick={() => setCrashAlertDriver(null)} className="text-white/80 hover:text-white p-1 cursor-pointer">
              ✕
            </button>
          </div>
        </div>
      )}
      <div className={showCrashAlert ? 'pt-[46px]' : ''}>
        <Routes>
          <Route element={<AppShell />}>
            <Route path="/" element={<Dashboard />} />
            <Route path="/map" element={<LiveMap />} />
            <Route path="/drivers" element={<Drivers />} />
            <Route path="/events" element={<Events />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </div>
    </div>
  )
}
