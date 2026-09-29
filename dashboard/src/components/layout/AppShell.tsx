import { Suspense, useEffect, useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { ErrorBoundary } from '@/components/ui/ErrorBoundary'
import { PageLoader } from '@/components/ui/PageLoader'
import { useIsDesktop } from '@/hooks/useMediaQuery'
import { useSocket } from '@/hooks/SocketContext'
import { Truck, X, MapPin } from 'lucide-react'

export function AppShell() {
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()
  const isDesktop = useIsDesktop()
  const fullBleed = location.pathname === '/map'
  const { breakdownAlert, setBreakdownAlert } = useSocket()

  useEffect(() => {
    setMobileOpen(false)
  }, [location.pathname])

  return (
    <div className="flex min-h-screen bg-[var(--page-bg)] relative overflow-hidden font-sans text-[var(--text-primary)] transition-colors duration-300 selection:bg-[#E53935] selection:text-white">
      {/* Structural Chassis Sidebar */}
      <Sidebar
        collapsed={collapsed}
        onToggle={() => setCollapsed((c) => !c)}
        isDesktop={isDesktop}
        mobileOpen={mobileOpen}
        onCloseMobile={() => setMobileOpen(false)}
      />

      {/* Main Viewport */}
      <div className="flex-1 min-w-0 flex flex-col relative z-10">
        <Topbar onOpenMobileSidebar={() => setMobileOpen(true)} />

        <main className="flex-1 min-w-0 overflow-y-auto">
          <AnimatePresence mode="wait">
            <motion.div
              key={location.pathname}
              initial={{ opacity: 0, y: 12, scale: 0.995 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -8, scale: 0.995 }}
              transition={{
                type: 'spring',
                stiffness: 380,
                damping: 30,
                mass: 0.8,
              }}
              className={fullBleed ? '' : 'p-6 sm:p-8 lg:p-10 max-w-[1750px] mx-auto w-full'}
            >
              <ErrorBoundary key={location.pathname}>
                <Suspense fallback={<PageLoader />}>
                  <Outlet />
                </Suspense>
              </ErrorBoundary>
            </motion.div>
          </AnimatePresence>
        </main>
      </div>
    </div>
  )
}
