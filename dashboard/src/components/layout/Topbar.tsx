import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Search, Bell, Sun, Moon, ChevronDown, Cloud, Command, Menu, ShieldAlert } from 'lucide-react'
import { useTheme } from '@/lib/theme'
import { Avatar } from '@/components/ui/Avatar'
import { cn } from '@/lib/utils'

function useClock() {
  const [now, setNow] = useState(new Date())
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(t)
  }, [])
  return now
}

export function Topbar({ onOpenMobileSidebar }: { onOpenMobileSidebar: () => void }) {
  const { theme, toggle } = useTheme()
  const now = useClock()
  const [org, setOrg] = useState('FleetGuard · Mangalore')
  const [orgOpen, setOrgOpen] = useState(false)

  const time = now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
  const date = now.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })

  return (
    <header className="sticky top-0 z-20 h-16 glass rounded-none border-b border-slate-100 flex items-center gap-2 sm:gap-3 px-3 sm:px-5">
      {/* Hamburger + compact brand (mobile / tablet only) */}
      <button onClick={onOpenMobileSidebar}
        className="grid place-items-center h-10 w-10 rounded-xl bg-slate-50 border border-slate-200 text-secondary hover:text-[#10b981] hover:border-[#10b981]/30 transition-colors lg:hidden shrink-0">
        <Menu className="h-[18px] w-[18px]" />
      </button>
      <div className="flex items-center gap-2 lg:hidden shrink-0">
        <div className="grid place-items-center h-8 w-8 rounded-lg accent-gradient ring-glow">
          <ShieldAlert className="h-4 w-4 text-white" />
        </div>
        <span className="hidden min-[400px]:block font-display font-bold text-[14px] text-primary">FleetGuard<span className="text-accent-gradient"> AI</span></span>
      </div>

      {/* Search */}
      <div className="relative flex-1 max-w-md hidden sm:block">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
        <input
          placeholder="Search drivers, vehicles, trips…"
          className="w-full h-10 rounded-xl bg-slate-50 border border-slate-200 pl-9 pr-16 text-[13px] text-primary placeholder:text-muted outline-none focus:border-[#10b981]/40 focus:bg-white transition-all shadow-inner"
        />
        <kbd className="absolute right-3 top-1/2 -translate-y-1/2 hidden md:flex items-center gap-0.5 text-[10px] text-muted border border-slate-200 bg-white rounded px-1.5 py-0.5 shadow-sm">
          <Command className="h-2.5 w-2.5" />K
        </kbd>
      </div>

      <div className="flex-1" />

      {/* Search icon (small screens, when full search is hidden) */}
      <button className="grid place-items-center h-10 w-10 rounded-xl bg-slate-50 border border-slate-200 text-secondary hover:text-[#10b981] hover:border-[#10b981]/30 transition-colors sm:hidden shrink-0">
        <Search className="h-[18px] w-[18px]" />
      </button>

      {/* Org selector */}
      <div className="relative hidden lg:block">
        <button onClick={() => setOrgOpen((o) => !o)}
          className="flex items-center gap-2 h-10 px-3 rounded-xl bg-slate-50 border border-slate-200 hover:border-[#10b981]/30 transition-colors text-[13px] text-secondary">
          <span className="h-2 w-2 rounded-full accent-gradient" />
          <span className="text-primary font-medium">{org}</span>
          <ChevronDown className="h-3.5 w-3.5" />
        </button>
        <AnimatePresence>
          {orgOpen && (
            <motion.div initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 6 }}
              className="absolute right-0 mt-2 w-56 glass rounded-xl p-1.5 z-50">
              {['FleetGuard · Mangalore', 'Amazon Logistics · South', 'Swiggy · Coastal Hub', 'BlueDart · Karnataka'].map((o) => (
                <button key={o} onClick={() => { setOrg(o); setOrgOpen(false) }}
                  className={cn('w-full text-left px-3 py-2 rounded-lg text-[13px] hover:bg-slate-50 transition-colors',
                    o === org ? 'text-[#10b981]' : 'text-secondary')}>{o}</button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Weather */}
      <div className="hidden xl:flex items-center gap-2 h-10 px-3 rounded-xl bg-slate-50 border border-slate-200 text-[13px]">
        <Cloud className="h-4 w-4 text-[#10b981]" />
        <span className="text-primary font-medium">29°C</span>
        <span className="text-muted">Mangalore</span>
      </div>

      {/* Clock */}
      <div className="hidden md:flex flex-col items-end leading-none shrink-0">
        <span className="font-display text-[15px] font-semibold text-primary tabular-nums">{time}</span>
        <span className="text-[10px] text-muted mt-0.5">{date}</span>
      </div>

      {/* Theme */}
      <button onClick={toggle} className="grid place-items-center h-10 w-10 rounded-xl bg-slate-50 border border-slate-200 hover:border-[#10b981]/30 text-secondary hover:text-[#10b981] transition-colors shrink-0">
        <AnimatePresence mode="wait" initial={false}>
          <motion.span key={theme} initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }} transition={{ duration: 0.2 }}>
            {theme === 'dark' ? <Moon className="h-[18px] w-[18px]" /> : <Sun className="h-[18px] w-[18px]" />}
          </motion.span>
        </AnimatePresence>
      </button>

      {/* Notifications */}
      <button className="relative grid place-items-center h-10 w-10 rounded-xl bg-slate-50 border border-slate-200 hover:border-[#10b981]/30 text-secondary hover:text-[#10b981] transition-colors shrink-0">
        <Bell className="h-[18px] w-[18px]" />
        <span className="absolute top-2 right-2.5 h-2 w-2 rounded-full bg-rose-500 ring-2 ring-[var(--color-navy-900)] animate-pulse-glow" />
      </button>

      {/* Profile */}
      <button className="flex items-center gap-2 pl-1 pr-1 sm:pr-2 h-10 rounded-xl hover:bg-slate-50 transition-colors shrink-0">
        <Avatar name="Mohammed Afzal" size={32} />
        <div className="hidden xl:block text-left leading-none">
          <div className="text-[13px] font-medium text-primary">Mohammed Afzal</div>
          <div className="text-[10px] text-muted mt-0.5">Fleet Administrator</div>
        </div>
      </button>
    </header>
  )
}
