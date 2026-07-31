import { NavLink } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard, Users, Map, Zap, LogOut,
  ChevronsLeft, X, ShieldAlert,
} from 'lucide-react'
import { cn } from '@/lib/utils'

const NAV = [
  { section: 'Command', items: [
    { to: '/', label: 'Dashboard', icon: LayoutDashboard, end: true },
    { to: '/map', label: 'Live Map', icon: Map, badge: 'LIVE' },
  ]},
  { section: 'Operations', items: [
    { to: '/drivers', label: 'Drivers', icon: Users },
    { to: '/events', label: 'Events', icon: Zap },
  ]},
]

interface SidebarProps {
  collapsed: boolean
  onToggle: () => void
  isDesktop: boolean
  mobileOpen: boolean
  onCloseMobile: () => void
}

export function Sidebar({ collapsed, onToggle, isDesktop, mobileOpen, onCloseMobile }: SidebarProps) {
  const showLabels = isDesktop ? !collapsed : true

  const handleLogout = () => {
    localStorage.removeItem('fleetguard_admin_token')
    window.location.reload()
  }

  return (
    <>
      {/* Mobile backdrop */}
      <AnimatePresence>
        {!isDesktop && mobileOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onCloseMobile}
            className="fixed inset-0 z-[480] bg-black/55 backdrop-blur-sm lg:hidden"
          />
        )}
      </AnimatePresence>

      <motion.aside
        initial={false}
        animate={
          isDesktop
            ? { width: collapsed ? 78 : 264, x: 0 }
            : { width: 272, x: mobileOpen ? 0 : -288 }
        }
        transition={{ type: 'spring', stiffness: 300, damping: 32 }}
        className={cn(
          'glass border-r border-slate-100 h-screen flex flex-col shrink-0 rounded-none',
          'fixed left-0 top-0 z-[490]',
          'lg:sticky lg:z-30',
        )}
      >
        {/* Brand */}
        <div className="flex items-center gap-3 px-5 h-16 shrink-0">
          <div className="grid place-items-center h-9 w-9 rounded-xl accent-gradient shadow-lg ring-glow shrink-0">
            <ShieldAlert className="h-5 w-5 text-white" />
          </div>
          {showLabels && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="min-w-0 flex-1">
              <div className="font-display font-bold text-[14px] leading-none text-primary">स्वदेशी FleetGuard</div>
              <div className="text-[9px] text-muted mt-1.5 tracking-wide">INDIAN COMMAND CENTER</div>
            </motion.div>
          )}
          {/* Close (mobile only) */}
          {!isDesktop && (
            <button onClick={onCloseMobile} className="grid place-items-center h-8 w-8 rounded-lg hover:bg-slate-100 text-secondary hover:text-primary lg:hidden">
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto no-scrollbar px-3 py-2">
          {NAV.map((group) => (
            <div key={group.section} className="mb-4">
              {showLabels && (
                <div className="px-3 mb-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted">{group.section}</div>
              )}
              <div className="space-y-0.5">
                {group.items.map((item) => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={(item as any).end}
                    className={({ isActive }) =>
                      cn(
                        'group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-[13.5px] font-medium transition-all',
                        isActive ? 'text-primary' : 'text-secondary hover:text-primary hover:bg-slate-50',
                        !showLabels && 'justify-center',
                      )
                    }
                  >
                    {({ isActive }) => (
                      <>
                         {isActive && (
                          <motion.div layoutId="nav-active" className="absolute inset-0 rounded-xl bg-[#10b981]/5 border border-[#10b981]/10"
                            transition={{ type: 'spring', stiffness: 380, damping: 32 }} />
                        )}
                        {isActive && <span className="absolute left-0 top-1/2 -translate-y-1/2 h-5 w-1 rounded-r-full accent-gradient" />}
                        <item.icon className={cn('h-[18px] w-[18px] shrink-0 relative z-10', isActive && 'text-[#10b981]')} />
                        {showLabels && <span className="relative z-10 truncate">{item.label}</span>}
                        {showLabels && (item as any).badge && (
                          <span className={cn('relative z-10 ml-auto text-[9px] font-bold px-1.5 py-0.5 rounded-full',
                            (item as any).badge === 'LIVE' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600')}>
                            {(item as any).badge}
                          </span>
                        )}
                      </>
                    )}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        {/* Logout Button */}
        <button
          onClick={handleLogout}
          className={cn(
            'flex items-center gap-3 px-5 h-12 border-t border-slate-100 text-rose-600 hover:text-rose-700 hover:bg-rose-50/50 transition-colors w-full text-left',
            !showLabels && 'justify-center',
          )}
        >
          <LogOut className="h-[18px] w-[18px] shrink-0" />
          {showLabels && <span className="text-[13px] font-medium">Sign Out</span>}
        </button>

        {/* Collapse (desktop only) */}
        {isDesktop && (
          <button onClick={onToggle} className="flex items-center gap-3 px-5 h-14 border-t border-slate-100 text-secondary hover:text-primary hover:bg-slate-50 transition-colors">
            <ChevronsLeft className={cn('h-[18px] w-[18px] transition-transform', collapsed && 'rotate-180')} />
            {showLabels && <span className="text-[13px]">Collapse</span>}
          </button>
        )}
      </motion.aside>
    </>
  )
}
