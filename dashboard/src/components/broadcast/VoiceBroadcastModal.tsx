import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Volume2, Radio, Send, X, AlertTriangle, CloudRain, Construction, ShieldAlert, Sparkles, CheckCircle2 } from 'lucide-react'
import { useSocket } from '@/hooks/SocketContext'
import { cn } from '@/lib/utils'

interface VoiceBroadcastModalProps {
  isOpen: boolean
  onClose: () => void
  activeRegionName?: string
}

const PRESET_BROADCASTS = [
  {
    id: 'monsoon',
    icon: CloudRain,
    title: 'Monsoon Slippery Road Warning',
    text: 'Monsoon Alert: Heavy rainfall and slippery asphalt reported on sector roads. Restrict speed below 35 km/h and maintain double braking distance.',
    tone: 'blue',
  },
  {
    id: 'construction',
    icon: Construction,
    title: 'Active Road Works / Detour',
    text: 'Road Works Advisory: Narrow single-lane corridor active near main transit junction. Watch for road workers and follow pilot vehicle signals.',
    tone: 'amber',
  },
  {
    id: 'fog',
    icon: AlertTriangle,
    title: 'Reduced Visibility / Fog Hazard',
    text: 'Visibility Hazard Alert: Dense fog and low lighting detected on corridor roads. Switch on low-beam headlights and hazard indicators.',
    tone: 'amber',
  },
  {
    id: 'school',
    icon: ShieldAlert,
    title: 'School Hour Ingress & Crossing',
    text: 'School Zone Enforcement: Morning student arrival hours in progress. Strictly adhere to 25 km/h limit with zero overtaking.',
    tone: 'emerald',
  },
]

export function VoiceBroadcastModal({ isOpen, onClose, activeRegionName = 'Puttur Taluk' }: VoiceBroadcastModalProps) {
  const { socket } = useSocket()
  const [customMessage, setCustomMessage] = useState('')
  const [priority, setPriority] = useState<'normal' | 'high' | 'critical'>('high')
  const [isTransmitting, setIsTransmitting] = useState(false)
  const [sentSuccess, setSentSuccess] = useState(false)

  if (!isOpen) return null

  const handleTransmit = (textToSend?: string) => {
    const text = textToSend || customMessage
    if (!text.trim()) return

    setIsTransmitting(true)
    socket?.emit('admin_voice_broadcast', {
      message: text.trim(),
      priority,
      regionName: activeRegionName,
      timestamp: new Date().toISOString(),
    })

    setTimeout(() => {
      setIsTransmitting(false)
      setSentSuccess(true)
      setTimeout(() => {
        setSentSuccess(false)
        onClose()
      }, 1600)
    }, 600)
  }

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[99999] flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-200">
        <motion.div
          initial={{ scale: 0.94, opacity: 0, y: 15 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.94, opacity: 0, y: 15 }}
          className="relative w-full max-w-2xl rounded-3xl bg-slate-900 border border-slate-700/80 shadow-2xl p-6 sm:p-8 text-white overflow-hidden"
        >
          {/* Neon Header Aura */}
          <div className="absolute top-0 right-0 w-60 h-60 bg-emerald-500/10 blur-3xl pointer-events-none -mr-20 -mt-20" />

          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-6 right-6 p-2 rounded-xl bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition cursor-pointer"
          >
            <X size={18} />
          </button>

          {/* Modal Header */}
          <div className="flex items-center gap-3.5 mb-6">
            <div className="h-12 w-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shadow-inner shrink-0">
              <Volume2 size={24} className="animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400 animate-ping" />
                <span className="text-[10px] font-black uppercase tracking-widest text-emerald-400">
                  LIVE INTERCOM DISPATCH // {activeRegionName.toUpperCase()}
                </span>
              </div>
              <h2 className="text-xl font-black uppercase tracking-tight text-white mt-0.5">
                Voice &amp; Audio Emergency Broadcast
              </h2>
            </div>
          </div>

          <p className="text-xs text-slate-400 leading-relaxed mb-5">
            Dispatches high-priority spoken voice guidance synthesized via Text-to-Speech (TTS) engine and full-screen heads-up alerts directly inside all active mobile driver cabs.
          </p>

          {/* Quick Preset Cards */}
          <div className="space-y-2 mb-5">
            <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400">
              Quick Safety Broadcast Presets:
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {PRESET_BROADCASTS.map((preset) => {
                const Icon = preset.icon
                return (
                  <button
                    key={preset.id}
                    onClick={() => {
                      setCustomMessage(preset.text)
                    }}
                    className={cn(
                      "p-3 rounded-2xl border text-left transition-all cursor-pointer flex items-start gap-2.5",
                      customMessage === preset.text
                        ? "bg-emerald-950/40 border-emerald-500/60 shadow-lg shadow-emerald-500/10"
                        : "bg-slate-950/60 border-slate-800 hover:border-slate-700"
                    )}
                  >
                    <div className="p-2 rounded-xl bg-slate-900 border border-slate-800 text-emerald-400 shrink-0 mt-0.5">
                      <Icon size={16} />
                    </div>
                    <div className="min-w-0">
                      <div className="text-xs font-black text-white uppercase tracking-tight truncate">
                        {preset.title}
                      </div>
                      <div className="text-[10px] text-slate-400 line-clamp-2 mt-0.5 leading-snug">
                        {preset.text}
                      </div>
                    </div>
                  </button>
                )
              })}
            </div>
          </div>

          {/* Custom Message Input */}
          <div className="space-y-2 mb-6">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-400">
                Spoken Broadcast Announcement:
              </span>
              <span className="text-[10px] font-mono text-slate-500">
                {customMessage.length} characters
              </span>
            </div>
            <textarea
              rows={3}
              value={customMessage}
              onChange={(e) => setCustomMessage(e.target.value)}
              placeholder="Type custom dispatch announcement to be read aloud in driver cockpits..."
              className="w-full p-3.5 rounded-2xl bg-slate-950/80 border border-slate-800 text-xs font-medium text-white placeholder:text-slate-600 outline-none focus:border-emerald-500 transition-all resize-none shadow-inner"
            />
          </div>

          {/* Action Row */}
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-2 border-t border-slate-800">
            <div className="flex items-center gap-2">
              <span className="text-[10px] font-mono uppercase text-slate-400 font-bold">Priority:</span>
              <div className="flex gap-1">
                {(['normal', 'high', 'critical'] as const).map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setPriority(p)}
                    className={cn(
                      "px-2.5 py-1 rounded-lg text-[9px] font-black uppercase tracking-wider transition-all cursor-pointer",
                      priority === p
                        ? p === 'critical'
                          ? "bg-rose-500 text-white"
                          : p === 'high'
                          ? "bg-amber-500 text-slate-950"
                          : "bg-emerald-500 text-slate-950"
                        : "bg-slate-800 text-slate-400 hover:text-white"
                    )}
                  >
                    {p}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-3 w-full sm:w-auto">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 sm:flex-none px-4 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold text-xs uppercase tracking-wider transition cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => handleTransmit()}
                disabled={isTransmitting || !customMessage.trim()}
                className={cn(
                  "flex-1 sm:flex-none px-6 py-3 rounded-xl font-black text-xs uppercase tracking-widest flex items-center justify-center gap-2 shadow-xl transition-all cursor-pointer disabled:opacity-50",
                  sentSuccess
                    ? "bg-emerald-500 text-slate-950 shadow-emerald-500/20"
                    : "bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-slate-950 shadow-emerald-500/25 active:scale-95"
                )}
              >
                {sentSuccess ? (
                  <>
                    <CheckCircle2 size={16} />
                    <span>Broadcast Transmitted!</span>
                  </>
                ) : isTransmitting ? (
                  <>
                    <div className="h-4 w-4 rounded-full border-2 border-slate-950 border-t-transparent animate-spin" />
                    <span>Transmitting to Cabs...</span>
                  </>
                ) : (
                  <>
                    <Send size={15} />
                    <span>Transmit Audio Broadcast</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}
