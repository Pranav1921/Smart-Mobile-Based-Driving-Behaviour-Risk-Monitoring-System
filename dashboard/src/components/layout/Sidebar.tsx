import { useEffect, useState, useMemo } from 'react'
import { NavLink } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard, Users, Map, Package, Zap, LogOut,
  ChevronsLeft, X, ShieldAlert, Cpu, Activity, FileSpreadsheet,
  UserCheck, Radio
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useSocket } from '@/hooks/SocketContext'

export function Sidebar({ collapsed, onToggle, isDesktop, mobileOpen, onCloseMobile }: any) {
  const showLabels = isDesktop ? !collapsed : true
  const { pendingCount, isConnected } = useSocket()

  interface NavItem {
    to: string
    label: string
    icon: any
    end?: boolean
    badge?: number
  }

  const NAV: { section: string; items: NavItem[] }[] = useMemo(() => [
    { section: 'TELEMETRY & GRID', items: [
      { to: '/', label: 'Cockpit Overview', icon: LayoutDashboard, end: true },
      { to: '/map', label: 'Tactical Grid', icon: Map },
      { to: '/orders', label: 'Order Dispatch', icon: Package },
    ]},
    { section: 'FLEET & VERIFICATION', items: [
      { to: '/requests', label: 'Requests Hub', icon: UserCheck, badge: pendingCount },
      { to: '/drivers', label: 'Driver Registry', icon: Users },
      { to: '/events', label: 'Telemetry Alerts', icon: ShieldAlert },
      { to: '/reports', label: 'Audit Reports', icon: FileSpreadsheet },
    ]},
  ], [pendingCount])

  const handleLogout = () => {
    localStorage.removeItem('fg_real_backend_token')
    localStorage.removeItem('smartdrive_real_backend_token')
    localStorage.removeItem('smartdrive_jwt_token')
    localStorage.removeItem('smartdrive_admin_user')
    localStorage.removeItem('smartdrive_selected_region')
    window.location.reload()
  }

  return (
    <>
      <AnimatePresence>
        {!isDesktop && mobileOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onCloseMobile}
            className="fixed inset-0 z-[480] bg-black/60 backdrop-blur-sm lg:hidden"
          />
        )}
      </AnimatePresence>

      <motion.aside
        initial={false}
        animate={
          isDesktop
            ? { width: collapsed ? 72 : 270, x: 0 }
            : { width: 270, x: mobileOpen ? 0 : -320 }
        }
        transition={{ type: 'spring', stiffness: 380, damping: 32 }}
        className={cn(
          'bg-[var(--card-bg)] border-r-[1.5px] border-[var(--border-main)] h-screen min-h-screen flex flex-col shrink-0 relative transition-colors shadow-sm overflow-hidden z-[490]',
          'fixed left-0 top-0',
          'lg:sticky lg:top-0 lg:z-30',
        )}
      >
        {/* Hardware Module Header */}
        <div className="flex items-center gap-3 px-6 h-20 shrink-0 border-b-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)]/50">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-[#E53935] to-[#B71C1C] text-white grid place-items-center shadow-md shadow-red-500/20 shrink-0 relative">
            <Radio className="h-5 w-5 animate-pulse" />
            <span className={cn(
              "absolute -top-1 -right-1 h-3 w-3 rounded-full border-2 border-[var(--card-bg)]",
              isConnected ? "bg-[#10B981] shadow-[0_0_8px_#10b981]" : "bg-[#EF4444]"
            )} />
          </div>

          {showLabels && (
            <div className="min-w-0 flex-1">
              <div className="font-pixel text-[11px] text-[var(--text-primary)] leading-tight tracking-wider uppercase font-bold truncate">
                SMARTDRIVE
              </div>
              <div className="font-tech text-[9px] text-[#E53935] font-bold tracking-widest uppercase flex items-center gap-1.5 mt-0.5">
                <span>NODE v3.7.0</span>
                <span className="h-1 w-1 rounded-full bg-[#10B981]" />
                <span className="text-[var(--text-subtle)]">BLE/GPS</span>
              </div>
            </div>
          )}
        </div>

        {/* Navigation Rack */}
        <nav className="flex-1 overflow-y-auto no-scrollbar p-3.5 pt-6 space-y-6">
          {NAV.map((group) => (
            <div key={group.section} className="space-y-2">
              {showLabels && (
                <div className="px-3 text-[9px] font-tech font-bold uppercase tracking-[0.25em] text-[var(--text-subtle)] flex items-center justify-between">
                  <span>{group.section}</span>
                  <span className="h-1 w-1 rounded-full bg-[var(--border-main)]" />
                </div>
              )}
              <div className="space-y-1.5">
                {group.items.map((item) => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={(item as any).end}
                    className={({ isActive }) =>
                      cn(
                        'flex items-center gap-3.5 px-3.5 h-12 rounded-xl font-space text-xs font-bold uppercase tracking-tight transition-all relative group border-[1.5px]',
                        'active:translate-y-[1.5px] active:scale-[0.98]',
                        isActive
                          ? 'bg-[var(--debossed-slot)] text-[var(--text-primary)] border-[#E53935] shadow-sm'
                          : 'bg-transparent border-transparent text-[var(--text-secondary)] hover:bg-[var(--debossed-slot)]/60 hover:text-[var(--text-primary)] hover:border-[var(--border-main)]',
                      )
                    }
                  >
                    {({ isActive }) => (
                      <>
                        <item.icon className={cn(
                          'h-4.5 w-4.5 shrink-0 transition-transform group-hover:scale-110',
                          isActive ? 'text-[#E53935]' : 'text-[var(--text-subtle)]'
                        )} />
                        {showLabels && <span className="truncate">{item.label}</span>}
                        {item.badge !== undefined && item.badge > 0 && (
                          showLabels ? (
                            <span className="ml-auto px-2 py-0.5 rounded-md font-pixel text-[9px] font-black bg-[#D97706] text-black shadow-sm animate-pulse">
                              {item.badge}
                            </span>
                          ) : (
                            <span className="absolute top-2 right-2 w-2.5 h-2.5 rounded-full bg-[#D97706] shadow-sm animate-ping" />
                          )
                        )}
                        {isActive && (
                          <motion.span
                            layoutId="activeNavTab"
                            className="absolute left-0 top-2 bottom-2 w-1 rounded-r-full bg-[#E53935]"
                          />
                        )}
                      </>
                    )}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        {/* Tactical Footer Chassis Controls */}
        <div className="p-3.5 border-t-[1.5px] border-[var(--border-main)] bg-[var(--debossed-slot)]/30 flex items-center justify-between gap-2.5">
          {isDesktop && (
            <motion.button
              whileTap={{ scale: 0.94 }}
              onClick={onToggle}
              className="flex-1 h-10 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:border-[var(--border-highlight)] transition-colors flex items-center justify-center cursor-pointer shadow-sm"
              title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              <ChevronsLeft className={cn('h-4 w-4 transition-transform duration-300', collapsed && 'rotate-180')} />
            </motion.button>
          )}
          <motion.button
            whileTap={{ scale: 0.94 }}
            onClick={handleLogout}
            className="h-10 w-10 rounded-xl border-[1.5px] border-[var(--border-main)] bg-[var(--card-bg)] text-[var(--text-secondary)] hover:text-[#DC2626] hover:border-red-500/30 hover:bg-red-500/10 grid place-items-center transition-colors cursor-pointer shadow-sm"
            title="Sign Out Session"
          >
            <LogOut className="h-4 w-4" />
          </motion.button>
        </div>
      </motion.aside>
    </>
  )
}
