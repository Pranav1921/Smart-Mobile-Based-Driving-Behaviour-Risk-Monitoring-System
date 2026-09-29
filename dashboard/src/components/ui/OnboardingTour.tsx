import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronRight, X, LayoutDashboard, Map, ShoppingCart, Users, ShieldAlert } from 'lucide-react'

const STEPS = [
  { title: 'Command Dashboard', desc: 'Overview of fleet safety, active trips, and AI-driven risk alerts.', icon: LayoutDashboard },
  { title: 'Live Fleet Map', desc: 'Track all drivers in real-time within your selected jurisdiction.', icon: Map },
  { title: 'Dispatch Orders', desc: 'Monitor delivery mission dispatches and order statuses.', icon: ShoppingCart },
  { title: 'Driver Intelligence', desc: 'Detailed profiles, safety scores, and behavior analytics for each operator.', icon: Users },
  { title: 'Safety Events', desc: 'Logs of harsh braking, overspeeding, and crash detection incidents.', icon: ShieldAlert },
]

export function OnboardingTour() {
  const [step, setStep] = useState(-1)

  useEffect(() => {
    const hasSeen = localStorage.getItem('fg_onboarding_seen')
    if (!hasSeen) {
      setStep(0)
    }
  }, [])

  if (step === -1) return null

  const current = STEPS[step]

  const handleNext = () => {
    if (step < STEPS.length - 1) {
      setStep(step + 1)
    } else {
      localStorage.setItem('fg_onboarding_seen', 'true')
      setStep(-1)
    }
  }

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className='fixed inset-0 z-[100000] bg-black/60 backdrop-blur-sm flex items-center justify-center p-6'
      >
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className='max-w-md w-full bg-[#0c1224] border border-emerald-500/30 rounded-3xl p-8 shadow-2xl relative'
        >
          <button
            onClick={() => setStep(-1)}
            className='absolute top-4 right-4 text-slate-500 hover:text-white transition-colors'
          >
            <X className='h-5 w-5' />
          </button>

          <div className='flex flex-col items-center text-center'>
            <div className='h-16 w-16 rounded-2xl bg-emerald-500/10 text-emerald-400 grid place-items-center mb-6 border border-emerald-500/20'>
              <current.icon className='h-8 w-8' />
            </div>
            <h2 className='text-xl font-bold text-white mb-3'>{current.title}</h2>
            <p className='text-sm text-slate-400 leading-relaxed'>{current.desc}</p>
          </div>

          <div className='mt-10 flex items-center justify-between'>
            <div className='flex gap-1.5'>
              {STEPS.map((_, i) => (
                <div
                  key={i}
                  className={`h-1.5 rounded-full transition-all duration-300 ${i === step ? 'w-6 bg-emerald-500' : 'w-1.5 bg-slate-800'}`}
                />
              ))}
            </div>
            <button
              onClick={handleNext}
              className='h-11 px-6 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-bold flex items-center gap-2 transition-all shadow-lg'
            >
              {step === STEPS.length - 1 ? 'Get Started' : 'Next Step'}
              <ChevronRight className='h-4 w-4' />
            </button>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  )
}
