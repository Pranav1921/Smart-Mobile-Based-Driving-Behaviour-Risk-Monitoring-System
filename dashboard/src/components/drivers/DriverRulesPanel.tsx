import React from 'react'
import { motion } from 'framer-motion'
import {
  ShieldCheck, TriangleAlert as AlertTriangle, Award, DollarSign, CheckCircle2, XCircle, FileText, TrendingUp, AlertCircle
} from 'lucide-react'
import { Driver } from '@/types'

export interface FleetRule {
  id: number
  name: string
  threshold: string
  description: string
  penalty: string
}

export const FLEET_RULES_10: FleetRule[] = [
  { id: 1, name: 'School Zone Compliance', threshold: 'Speed <= 30 km/h', description: 'Strict 30 km/h speed limit in registered school zones.', penalty: '-10 Pts' },
  { id: 2, name: 'Traffic Zone Caution', threshold: 'Speed <= 20 km/h', description: 'Low speed compliance in heavy congestion zones.', penalty: '-8 Pts' },
  { id: 3, name: 'Harsh Braking Prevention', threshold: 'Deceleration < 0.40 G', description: 'Smooth deceleration without emergency stops.', penalty: '-5 Pts' },
  { id: 4, name: 'Rapid Acceleration Limit', threshold: 'Acceleration < 0.35 G', description: 'Controlled throttle input during start.', penalty: '-5 Pts' },
  { id: 5, name: 'Sharp Cornering Deceleration', threshold: 'Lateral G < 0.40 G', description: 'Reduced entry speed into sharp turns.', penalty: '-5 Pts' },
  { id: 6, name: 'Maximum Highway Speed', threshold: 'Speed <= 80 km/h', description: 'Highway overspeed avoidance.', penalty: '-15 Pts' },
  { id: 7, name: 'Zero Distraction Usage', threshold: '0 Phone events while moving', description: 'No handheld mobile usage while driving.', penalty: '-20 Pts' },
  { id: 8, name: 'Continuous Shift Limit', threshold: 'Shift <= 8 hours', description: 'Mandatory rest breaks after continuous driving.', penalty: 'Rest Notice' },
  { id: 9, name: 'Authorized Route Tracking', threshold: '0 Unauthorized stops', description: 'No unverified stops in non-traffic areas.', penalty: 'Route Alert' },
  { id: 10, name: 'Crash/SOS Immediate Response', threshold: 'Instant status confirmation', description: 'Prompt acknowledgement of safety pings.', penalty: 'Critical Alert' },
]

export function DriverRulesPanel({ driver }: { driver: Driver }) {
  // Calculate violation count based on driver metrics
  const violationsCount = (driver.overspeedCount || 0) + (driver.harshBrakingCount || 0) + (driver.sharpTurnCount || 0)
  const isSevereDeduction = violationsCount >= 5
  const isEligibleForHike = violationsCount <= 1 && driver.safetyScore >= 90

  // Calculate Tier
  let tierName = 'Gold License'
  let tierColor = 'bg-amber-500/20 text-amber-300 border-amber-500/30'
  if (driver.safetyScore >= 95 && violationsCount === 0) {
    tierName = 'Master Tier 1'
    tierColor = 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30'
  } else if (driver.safetyScore < 75 || violationsCount >= 4) {
    tierName = 'Bronze License (Under Review)'
    tierColor = 'bg-rose-500/20 text-rose-300 border-rose-500/30'
  } else if (driver.safetyScore < 85) {
    tierName = 'Silver License'
    tierColor = 'bg-slate-500/20 text-slate-300 border-slate-500/30'
  }

  return (
    <div className="bg-[#0e121e] border border-slate-800 rounded-2xl p-5 text-white space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-slate-800 pb-4">
        <div>
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <ShieldCheck className="h-4 w-4 text-emerald-400" />
            10-Rule Driver Evaluation & Rating
          </h3>
          <p className="text-[11px] text-slate-400 mt-0.5">Daily SLA compliance, salary impact & license tiering</p>
        </div>
        <div className={`px-3 py-1 rounded-xl text-xs font-bold border ${tierColor}`}>
          {tierName}
        </div>
      </div>

      {/* Salary & Hike Status Banner */}
      <div className={`p-4 rounded-xl border flex items-start gap-3 text-xs ${
        isSevereDeduction
          ? 'bg-rose-500/10 border-rose-500/30 text-rose-200'
          : isEligibleForHike
          ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-200'
          : 'bg-indigo-500/10 border-indigo-500/30 text-indigo-200'
      }`}>
        {isSevereDeduction ? (
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0 mt-0.5" />
        ) : isEligibleForHike ? (
          <Award className="h-5 w-5 text-emerald-400 shrink-0 mt-0.5" />
        ) : (
          <DollarSign className="h-5 w-5 text-indigo-400 shrink-0 mt-0.5" />
        )}
        <div>
          <div className="font-bold text-sm">
            {isSevereDeduction
              ? 'Salary Deduction Warning Triggered'
              : isEligibleForHike
              ? 'Eligible for Performance Hike & Incentive Bonus'
              : 'Standard SLA Salary Compliance'}
          </div>
          <div className="text-[11px] opacity-90 mt-1">
            {isSevereDeduction
              ? `Driver has broken ${violationsCount} rules today (> 5 rule threshold). A 10% SLA deduction warning has been logged.`
              : isEligibleForHike
              ? `Driver maintained 9+ rules with ${driver.safetyScore} safety score. Eligible for Tier 1 salary bonus (+12%).`
              : `Current rule infractions: ${violationsCount}/10. Maintain score >90 to unlock performance hikes.`}
          </div>
        </div>
      </div>

      {/* 10 Rules Grid */}
      <div className="space-y-2">
        <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">10 Core Safety Rules Status</div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-64 overflow-y-auto pr-1">
          {FLEET_RULES_10.map((rule) => {
            let isViolated = false
            if (rule.id === 1 && (driver.overspeedCount || 0) > 0) isViolated = true
            if (rule.id === 3 && (driver.harshBrakingCount || 0) > 0) isViolated = true
            if (rule.id === 5 && (driver.sharpTurnCount || 0) > 0) isViolated = true

            return (
              <div
                key={rule.id}
                className={`p-2.5 rounded-xl border flex items-center justify-between text-xs ${
                  isViolated
                    ? 'bg-rose-950/20 border-rose-500/30 text-rose-200'
                    : 'bg-[#151926] border-slate-800 text-slate-300'
                }`}
              >
                <div className="flex items-center gap-2">
                  {isViolated ? (
                    <XCircle className="h-4 w-4 text-rose-400 shrink-0" />
                  ) : (
                    <CheckCircle2 className="h-4 w-4 text-emerald-400 shrink-0" />
                  )}
                  <div>
                    <div className="font-semibold text-[12px]">{rule.id}. {rule.name}</div>
                    <div className="text-[10px] text-slate-400">{rule.threshold}</div>
                  </div>
                </div>
                <span className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded ${isViolated ? 'bg-rose-500/20 text-rose-300' : 'bg-emerald-500/20 text-emerald-300'}`}>
                  {isViolated ? rule.penalty : 'OK'}
                </span>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
