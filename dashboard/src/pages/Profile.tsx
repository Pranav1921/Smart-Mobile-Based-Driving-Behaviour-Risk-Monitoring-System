import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  User, ShieldCheck, Mail, Building2, Check, AlertCircle, 
  MapPin, Globe, Compass, Radio, Save, RefreshCw, Cpu, 
  Shield, Layers, ChevronDown
} from 'lucide-react'
import { Avatar } from '@/components/ui/Avatar'
import { Badge } from '@/components/ui/Badge'
import { cn } from '@/lib/utils'
import { PREDEFINED_REGIONS, getOrGenerateRegion, resolveActiveRegion, type RegionOption } from '@/data/regionsData'

interface RegionPreset {
  id: string
  name: string
  district: string
  state: string
  country: string
  sectorCode: string
  center: [number, number]
}

const REGION_PRESETS: RegionPreset[] = PREDEFINED_REGIONS.map((r) => ({
  id: r.id,
  name: r.name,
  district: r.district,
  state: r.state,
  country: r.country,
  sectorCode: r.talukCode,
  center: r.center,
}))

export default function Profile() {
  const initialActive = resolveActiveRegion()
  const [firstName, setFirstName] = useState('Mohammed')
  const [lastName, setLastName] = useState('Afzal')
  const [email, setEmail] = useState('admin@smartdrive.ai')
  const [role, setRole] = useState('Fleet Intelligence Director')
  const [organization, setOrganization] = useState('Smart Driving Monitoring Agency')
  
  // Regional Command Jurisdiction state - synchronized with active region
  const [selectedRegionId, setSelectedRegionId] = useState(initialActive.id)
  const [regionCustomName, setRegionCustomName] = useState(initialActive.name)
  const [regionDistrict, setRegionDistrict] = useState(initialActive.district)
  const [regionState, setRegionState] = useState(initialActive.state)
  const [sectorCode, setSectorCode] = useState(initialActive.talukCode)
  const [coordinates, setCoordinates] = useState<[number, number]>(initialActive.center)

  const [saved, setSaved] = useState(false)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    // 1. Load stored user
    const storedUser = localStorage.getItem('smartdrive_admin_user')
    if (storedUser) {
      try {
        const u = JSON.parse(storedUser)
        if (u.firstName) setFirstName(u.firstName)
        if (u.lastName) setLastName(u.lastName)
        if (u.email) setEmail(u.email)
        if (u.role) setRole(u.role)
        if (u.organization) {
          setOrganization(typeof u.organization === 'string' ? u.organization : (u.organization.name || 'Smart Driving Monitoring Agency'))
        }
        if (u.region) {
          setRegionCustomName(u.region)
        }
      } catch (e) {
        console.warn('Failed to parse user data:', e)
      }
    }

    // 2. Load stored active region
    const storedRegion = localStorage.getItem('smartdrive_selected_region')
    if (storedRegion) {
      try {
        const r = JSON.parse(storedRegion)
        if (r.id) {
          const match = REGION_PRESETS.find(p => p.id === r.id)
          if (match) {
            setSelectedRegionId(match.id)
            setRegionCustomName(match.name)
            setRegionDistrict(match.district)
            setRegionState(match.state)
            setSectorCode(match.sectorCode)
            setCoordinates(match.center)
          } else {
            setSelectedRegionId('custom')
            setRegionCustomName(r.name || 'Custom Regional Hub')
            setRegionDistrict(r.district || 'Regional District')
            setRegionState(r.state || 'State Command')
            if (r.center) setCoordinates(r.center)
          }
        } else if (r.name) {
          setRegionCustomName(r.name)
        }
      } catch (e) {
        console.warn('Failed to parse region data:', e)
      }
    }
  }, [])

  const handleRegionSelect = (presetId: string) => {
    setSelectedRegionId(presetId)
    const match = REGION_PRESETS.find(p => p.id === presetId)
    if (match) {
      setRegionCustomName(match.name)
      setRegionDistrict(match.district)
      setRegionState(match.state)
      setSectorCode(match.sectorCode)
      setCoordinates(match.center)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage('')
    setSaved(false)

    try {
      // 1. Update smartdrive_admin_user
      const storedUser = localStorage.getItem('smartdrive_admin_user')
      const existing = storedUser ? JSON.parse(storedUser) : {}
      existing.firstName = firstName
      existing.lastName = lastName
      existing.organization = organization
      existing.region = regionCustomName
      existing.sectorCode = sectorCode
      localStorage.setItem('smartdrive_admin_user', JSON.stringify(existing))

      // 2. Update smartdrive_selected_region with guaranteed boundaryPolygon and center
      const match = PREDEFINED_REGIONS.find(p => p.id === selectedRegionId)
      const regionPayload: RegionOption = match ? {
        ...match,
        name: regionCustomName || match.name,
      } : getOrGenerateRegion(
        'India',
        regionState || 'Karnataka',
        regionDistrict || 'Dakshina Kannada',
        regionCustomName || `${regionDistrict} Hub`
      )

      localStorage.setItem('smartdrive_selected_region', JSON.stringify(regionPayload))
      localStorage.setItem('fg_selected_region', JSON.stringify(regionPayload))

      // 3. Notify all listeners (Topbar, Maps, Drivers) of the change
      window.dispatchEvent(new Event('smartdrive_region_updated'))
      window.dispatchEvent(new Event('storage'))

      setSaved(true)
      setMessage(`Profile & Regional Command updated to: ${regionCustomName}`)
    } catch (err: any) {
      setSaved(true)
      setMessage('Update failed. Please check local permissions.')
    } finally {
      setLoading(false)
      setTimeout(() => setSaved(false), 4500)
    }
  }

  const fullName = `${firstName} ${lastName}`.trim()
  const activePreset = REGION_PRESETS.find(p => p.id === selectedRegionId)

  return (
    <div className="space-y-8 pb-16 max-w-[1400px] mx-auto px-4 sm:px-8 text-foreground">
      {/* ── HEADER PLATE ────────────────────────────────────────────── */}
      <div className="stamped-card relative has-rivets p-6 sm:p-8 rounded-[28px] overflow-hidden">
        <div className="corner-screw top-left" />
        <div className="corner-screw top-right" />
        <div className="corner-screw bottom-left" />
        <div className="corner-screw bottom-right" />

        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div>
            <div className="flex items-center gap-3">
              <span className="h-3 w-3 rounded-full bg-[#E53935] animate-ping" />
              <h1 className="font-space text-2xl sm:text-3xl font-black uppercase tracking-tight text-foreground leading-none">
                Commander <span className="text-[#E53935]">Profile &amp; Regional Command</span>
              </h1>
            </div>
            <p className="font-pixel text-[9px] text-muted-foreground uppercase tracking-[0.3em] mt-2">
              Operator Credentials • Regional Jurisdiction Sector Assignment
            </p>
          </div>

          {/* Active Jurisdiction Chip */}
          <div className="flex items-center gap-2.5 px-4 py-2 rounded-2xl bg-[var(--debossed-slot)] border border-[var(--border-main)] font-tech text-xs">
            <MapPin size={14} className="text-[#E53935] shrink-0 animate-pulse" />
            <div>
              <div className="font-pixel text-[8px] text-muted-foreground uppercase">ACTIVE JURISDICTION</div>
              <div className="font-space font-black text-foreground uppercase tracking-tight leading-none mt-0.5">
                {regionCustomName}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        {/* ── LEFT COLUMN: HARDWARE IDENTITY & SECTOR PLATE ────────────────────────────────────────── */}
        <div className="lg:col-span-1 space-y-6">
          <div className="stamped-card relative has-rivets p-8 rounded-[32px] flex flex-col items-center text-center">
            <div className="corner-screw top-left" />
            <div className="corner-screw top-right" />
            <div className="corner-screw bottom-left" />
            <div className="corner-screw bottom-right" />

            <div className="relative">
              <Avatar 
                name={fullName || 'Commander'} 
                size={110} 
                className="ring-4 ring-[var(--border-main)] shadow-xl" 
              />
              <div className="absolute -bottom-2 -right-2 rounded-2xl bg-[#E53935] p-2.5 shadow-lg ring-4 ring-[var(--card-bg)] text-white">
                <ShieldCheck className="h-5 w-5" />
              </div>
            </div>

            <div className="mt-6">
              <h2 className="font-space text-2xl font-black text-foreground uppercase tracking-tight">
                {fullName}
              </h2>
              <span className="font-pixel text-[9px] px-3 py-1 rounded bg-[#E53935]/10 border border-[#E53935]/30 text-[#E53935] uppercase font-bold tracking-widest inline-block mt-2">
                {role}
              </span>
            </div>

            {/* Regional Sector Telemetry Card */}
            <div className="w-full mt-6 p-4 rounded-2xl bg-[var(--debossed-slot)] border border-[var(--border-main)] text-left space-y-3 font-tech">
              <div className="flex items-center justify-between pb-2 border-b border-[var(--border-main)]/60">
                <span className="font-pixel text-[8px] text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
                  <Radio size={11} className="text-[#E53935]" /> REGIONAL SECTOR
                </span>
                <span className="font-mono text-[10px] font-bold text-[#E53935] px-2 py-0.5 rounded bg-[var(--card-bg)] border border-[var(--border-main)]">
                  {sectorCode}
                </span>
              </div>

              <div>
                <div className="font-space font-black text-xs text-foreground uppercase tracking-tight">
                  {regionCustomName}
                </div>
                <div className="font-tech text-[11px] text-muted-foreground mt-0.5">
                  {regionDistrict}, {regionState}
                </div>
              </div>

              <div className="pt-2 border-t border-[var(--border-main)]/60 flex items-center justify-between text-[10px] text-muted-foreground">
                <span className="font-mono flex items-center gap-1">
                  <Compass size={11} className="text-[#2563EB]" />
                  {coordinates[0].toFixed(4)}° N, {coordinates[1].toFixed(4)}° E
                </span>
                <span className="font-pixel text-[8px] text-[#10B981] font-bold">GRID SYNCED</span>
              </div>
            </div>

            {/* Account Details */}
            <div className="w-full mt-4 space-y-2.5 font-tech text-xs">
              <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] flex items-center gap-3 border border-[var(--border-main)] text-muted-foreground">
                <Mail className="h-4 w-4 text-[#2563EB] shrink-0" />
                <span className="font-bold text-foreground truncate font-mono text-[11px]">{email}</span>
              </div>
              <div className="p-3.5 rounded-xl bg-[var(--debossed-slot)] flex items-center gap-3 border border-[var(--border-main)] text-muted-foreground">
                <Building2 className="h-4 w-4 text-[#D97706] shrink-0" />
                <span className="font-bold text-foreground truncate">{organization}</span>
              </div>
            </div>
          </div>
        </div>

        {/* ── RIGHT COLUMN: CONFIGURATION FORM WITH REGIONAL SECTOR PICKER ────────────────────────────────────────── */}
        <div className="lg:col-span-2">
          <div className="stamped-card relative has-rivets p-6 sm:p-10 rounded-[32px]">
            <div className="corner-screw top-left" />
            <div className="corner-screw top-right" />
            <div className="corner-screw bottom-left" />
            <div className="corner-screw bottom-right" />

            <div className="flex items-center justify-between mb-6 pb-4 border-b border-[var(--border-main)]">
              <div>
                <h3 className="font-space text-xl font-black text-foreground uppercase tracking-tight leading-none">
                  Regional Command Jurisdiction
                </h3>
                <p className="font-tech text-xs text-muted-foreground mt-1.5">
                  Configure and assign your active operational region for telemetry &amp; fleet monitoring.
                </p>
              </div>
              <Cpu size={24} className="text-[#E53935] opacity-60" />
            </div>

            <AnimatePresence>
              {saved && (
                <motion.div 
                  initial={{ opacity: 0, y: -10 }} 
                  animate={{ opacity: 1, y: 0 }} 
                  exit={{ opacity: 0, y: -10 }}
                  className="mb-6 rounded-2xl bg-[#10B981]/15 border-2 border-[#10B981]/40 px-5 py-3.5 font-tech text-xs font-bold text-[#10B981] flex items-center gap-2.5 shadow-md"
                >
                  <Check size={16} className="shrink-0 text-[#10B981]" /> 
                  <span>{message}</span>
                </motion.div>
              )}
            </AnimatePresence>

            <form onSubmit={handleSubmit} className="space-y-6 font-tech">
              {/* Regional Jurisdiction Selection */}
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="font-pixel text-[9px] text-[#E53935] uppercase tracking-widest font-bold">
                    OPERATIONAL REGIONAL COMMAND SECTOR
                  </span>
                  <span className="font-pixel text-[8px] text-muted-foreground uppercase">
                    FILTERS GRID &amp; ONBOARDING
                  </span>
                </div>

                <p className="font-tech text-xs text-muted-foreground leading-relaxed">
                  Select your assigned Regional Sector. Telemetry feeds, candidate driver verification queues, and active geofences will synchronize directly with this jurisdiction.
                </p>

                <div className="space-y-3">
                  <label className="font-pixel text-[9px] text-muted-foreground uppercase tracking-wider block ml-1">
                    Select Active Regional Hub
                  </label>
                  <div className="relative debossed-well rounded-xl overflow-hidden">
                    <select
                      value={selectedRegionId}
                      onChange={(e) => handleRegionSelect(e.target.value)}
                      className="h-12 w-full bg-transparent px-4 font-space font-bold text-xs uppercase tracking-wide text-foreground outline-none cursor-pointer appearance-none"
                    >
                      {REGION_PRESETS.map((preset) => (
                        <option 
                          key={preset.id} 
                          value={preset.id}
                          className="bg-[var(--card-bg)] text-foreground font-tech py-2"
                        >
                          {preset.name} — {preset.district}, {preset.state} ({preset.sectorCode})
                        </option>
                      ))}
                    </select>
                    <ChevronDown size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
                  </div>
                </div>

                {/* Custom Name / Hub Designation */}
                <div className="grid gap-5 sm:grid-cols-2 pt-1">
                  <div className="space-y-1.5">
                    <label className="font-pixel text-[9px] text-muted-foreground uppercase tracking-wider block ml-1">
                      Display Sector Name
                    </label>
                    <div className="debossed-well rounded-xl overflow-hidden">
                      <input
                        type="text"
                        value={regionCustomName}
                        onChange={(e) => setRegionCustomName(e.target.value)}
                        placeholder="e.g. Puttur Taluk Hub"
                        className="h-12 w-full bg-transparent px-4 font-space font-bold text-xs text-foreground outline-none"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-pixel text-[9px] text-muted-foreground uppercase tracking-wider block ml-1">
                      District Jurisdiction
                    </label>
                    <div className="debossed-well rounded-xl overflow-hidden">
                      <input
                        type="text"
                        value={regionDistrict}
                        onChange={(e) => setRegionDistrict(e.target.value)}
                        placeholder="e.g. Dakshina Kannada"
                        className="h-12 w-full bg-transparent px-4 font-tech font-bold text-xs text-foreground outline-none"
                        required
                      />
                    </div>
                  </div>
                </div>

                {/* Sector Code & State */}
                <div className="grid gap-5 sm:grid-cols-2">
                  <div className="space-y-1.5">
                    <label className="font-pixel text-[9px] text-muted-foreground uppercase tracking-wider block ml-1">
                      State / Union Territory
                    </label>
                    <div className="debossed-well rounded-xl overflow-hidden">
                      <input
                        type="text"
                        value={regionState}
                        onChange={(e) => setRegionState(e.target.value)}
                        placeholder="e.g. Karnataka"
                        className="h-12 w-full bg-transparent px-4 font-tech font-bold text-xs text-foreground outline-none"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-pixel text-[9px] text-muted-foreground uppercase tracking-wider block ml-1">
                      Assigned Sector UID
                    </label>
                    <div className="debossed-well rounded-xl overflow-hidden">
                      <input
                        type="text"
                        value={sectorCode}
                        onChange={(e) => setSectorCode(e.target.value)}
                        placeholder="e.g. SECTOR-KA-19"
                        className="h-12 w-full bg-transparent px-4 font-mono font-bold text-xs text-[#E53935] outline-none"
                        required
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <div className="pt-4 flex justify-end">
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.96 }}
                  type="submit"
                  disabled={loading}
                  className="h-12 px-8 rounded-xl bg-[#E53935] hover:bg-[#D32F2F] text-white font-space font-black text-xs uppercase tracking-wider transition shadow-lg shadow-red-500/25 flex items-center gap-2.5 cursor-pointer disabled:opacity-50"
                >
                  {loading ? (
                    <>
                      <RefreshCw size={14} className="animate-spin" />
                      <span>Synchronizing...</span>
                    </>
                  ) : (
                    <>
                      <Save size={15} />
                      <span>Save Profile &amp; Switch Region</span>
                    </>
                  )}
                </motion.button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  )
}
