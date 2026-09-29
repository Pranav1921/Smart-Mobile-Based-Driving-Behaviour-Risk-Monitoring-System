import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { useTheme } from '@/lib/theme'
import { useSocket } from '@/hooks/SocketContext'
import { Menu, Clock, Calendar, Moon, Sun, MapPin, Radio, ShieldCheck, Activity } from 'lucide-react'
import { Avatar } from '@/components/ui/Avatar'
import { RegionLoginModal } from '@/components/auth/RegionLoginModal'
import { resolveActiveRegion } from '@/data/regionsData'

function useClock() {
  const [now, setNow] = useState(new Date())
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(t)
  }, [])
  return now
}

export function Topbar({ onOpenMobileSidebar }: { onOpenMobileSidebar: () => void }) {
  const navigate = useNavigate()
  const now = useClock()
  const { theme, toggle } = useTheme()
  const { isConnected } = useSocket()
  const [adminName, setAdminName] = useState('System Admin')
  const [adminRegion, setAdminRegion] = useState(() => resolveActiveRegion().name)
  const [isRegionModalOpen, setIsRegionModalOpen] = useState(false)

  useEffect(() => {
    const updateAdminInfo = () => {
      const storedUser = localStorage.getItem('smartdrive_admin_user')
      const storedRegion = localStorage.getItem('smartdrive_selected_region')

      let regionName = ''
      if (storedRegion) {
        try {
          const r = JSON.parse(storedRegion)
          regionName = r.name || r.district || r.state || ''
        } catch (e) {}
      }

      if (storedUser) {
        try {
          const u = JSON.parse(storedUser)
          if (u.firstName) {
            setAdminName(`${u.firstName} ${u.lastName || ''}`.trim())
          }
          if (!regionName && u.region) {
            regionName = u.region
          }
        } catch (e) {}
      }

      setAdminRegion(regionName || 'Puttur Taluk Hub (KA)')
    }

    updateAdminInfo()
    window.addEventListener('storage', updateAdminInfo)
    window.addEventListener('smartdrive_region_updated', updateAdminInfo)
    return () => {
      window.removeEventListener('storage', updateAdminInfo)
      window.removeEventListener('smartdrive_region_updated', updateAdminInfo)
    }
  }, [])

  const time = now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  const date = now.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })

  return (
    <header className="sticky top-0 z-20 h-18 bg-[var(--card-bg)]/95 backdrop-blur-md border-b-[1.5px] border-[var(--border-main)] flex items-center justify-between px-6 sm:px-8 shadow-sm transition-colors">
      {/* Left: Mobile Toggle & Mechanical Telemetry Clock */}
      <div className="flex items-center gap-5">
        <motion.button
          whileTap={{ scale: 0.92 }}
          onClick={onOpenMobileSidebar}
          className="p-2.5 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)] text-[var(--text-primary)] hover:border-[var(--border-highlight)] lg:hidden transition-colors cursor-pointer"
        >
          <Menu className="h-5 w-5" />
        </motion.button>

        {/* Telemetry Clock & Calendar in JetBrains Mono */}
        <div className="hidden md:flex items-center gap-6 font-tech text-xs text-[var(--text-secondary)] font-bold">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
            <Clock size={13} className="text-[#E53935]" />
            <span className="tabular-nums tracking-wider text-[var(--text-primary)] font-bold">{time}</span>
          </div>
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[var(--debossed-slot)] border border-[var(--border-main)]/60">
            <Calendar size={13} className="text-[#2563EB]" />
            <span className="tracking-wide text-[var(--text-primary)]">{date}</span>
          </div>
        </div>
      </div>

      {/* Right: Telemetry Link Badge, Regional Sector Badge, Theme Switcher & Commander Profile */}
      <div className="flex items-center gap-3 sm:gap-4">
        {/* Active Regional Command Sector Indicator */}
        <div 
          onClick={() => setIsRegionModalOpen(true)}
          className="hidden lg:flex items-center gap-2 px-3 py-1.5 rounded-xl border-[1.5px] border-emerald-500/40 bg-[var(--debossed-slot)] hover:border-emerald-400 cursor-pointer transition shadow-inner group"
          title="Click to Switch Regional Jurisdiction (States, Districts, Taluks)"
        >
          <MapPin size={12} className="text-[#10B981] animate-pulse group-hover:scale-110 transition-transform" />
          <span className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-primary)]">
            SECTOR: <span className="text-[#10B981] font-space font-black">{adminRegion}</span>
          </span>
          <span className="text-[9px] bg-emerald-500/10 text-emerald-400 font-bold px-1.5 py-0.5 rounded border border-emerald-500/20 uppercase tracking-tighter">
            CHANGE
          </span>
        </div>

        {/* Real-Time WebSocket Telemetry Health Badge */}
        <div className="hidden sm:flex items-center gap-2 px-3.5 py-1.5 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)] shadow-inner">
          <span className="relative flex h-2 w-2">
            <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${isConnected ? 'bg-[#10B981]' : 'bg-[#EF4444]'}`} />
            <span className={`relative inline-flex rounded-full h-2 w-2 ${isConnected ? 'bg-[#10B981]' : 'bg-[#EF4444]'}`} />
          </span>
          <span className="font-tech text-[10px] font-bold uppercase tracking-wider text-[var(--text-primary)]">
            {isConnected ? 'NODE LINK: 20Hz' : 'DISCONNECTED'}
          </span>
        </div>

        {/* Tactile Theme Switcher */}
        <motion.button
          whileTap={{ scale: 0.90, rotate: 15 }}
          onClick={toggle}
          className="h-10 w-10 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)] text-[var(--text-primary)] hover:border-[var(--border-highlight)] transition-colors grid place-items-center cursor-pointer shadow-sm"
          title={`Switch to ${theme === 'light' ? 'Dark' : 'Light'} Mode`}
        >
          {theme === 'light' ? (
            <Moon size={16} className="text-[var(--text-primary)]" />
          ) : (
            <Sun size={16} className="text-[#D97706]" />
          )}
        </motion.button>

        <div className="h-6 w-px bg-[var(--border-main)] hidden sm:block" />

        {/* Commander Profile Plate with Actual Regional Command */}
        <motion.div
          whileTap={{ scale: 0.98 }}
          onClick={() => navigate('/profile')}
          className="flex items-center gap-3 px-3 py-1.5 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)] hover:border-[var(--border-highlight)] transition-colors cursor-pointer group shadow-sm"
        >
          <div className="text-right hidden sm:block max-w-[150px]">
            <p className="font-space text-xs font-bold text-[var(--text-primary)] uppercase tracking-tight leading-none group-hover:text-[#E53935] transition-colors truncate">
              {adminName}
            </p>
            <p className="font-tech text-[9px] text-[#E53935] font-bold uppercase tracking-wider mt-1 flex items-center justify-end gap-1 truncate" title={adminRegion}>
              <MapPin size={9} className="shrink-0 text-[#E53935]" />
              <span className="truncate">{adminRegion}</span>
            </p>
          </div>
          <Avatar
            name={adminName}
            size={32}
            className="ring-2 ring-[var(--border-main)] group-hover:ring-[#E53935] transition-all"
          />
        </motion.div>
      </div>

      {isRegionModalOpen && (
        <RegionLoginModal
          onClose={() => setIsRegionModalOpen(false)}
          onSelectRegion={(reg) => {
            setAdminRegion(reg.name)
            setIsRegionModalOpen(false)
          }}
        />
      )}
    </header>
  )
}
