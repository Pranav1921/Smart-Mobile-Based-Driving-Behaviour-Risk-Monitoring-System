import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  X,
  User,
  Phone,
  Mail,
  FileText,
  MapPin,
  Truck,
  Shield,
  AlertTriangle,
  Save,
  CheckCircle2,
  Calendar,
  Sparkles,
} from 'lucide-react'
import { Driver } from '@/types'
import { updateDriverInApi } from '@/lib/apiClient'
import { cn } from '@/lib/utils'

interface EditDriverModalProps {
  driver: Driver | null
  isOpen: boolean
  onClose: () => void
  onSuccess: (updatedDriver: any) => void
}

const REGION_OPTIONS = [
  { label: 'Puttur Hub (Dakshina Kannada)', value: 'Karnataka, Dakshina Kannada, Puttur' },
  { label: 'Kadaba Hub (Dakshina Kannada)', value: 'Karnataka, Dakshina Kannada, Kadaba' },
  { label: 'Mangaluru City (Dakshina Kannada)', value: 'Karnataka, Dakshina Kannada, Mangaluru' },
  { label: 'Bantwal Taluk', value: 'Karnataka, Dakshina Kannada, Bantwal' },
  { label: 'Sullia Taluk', value: 'Karnataka, Dakshina Kannada, Sullia' },
  { label: 'Belthangady Taluk', value: 'Karnataka, Dakshina Kannada, Belthangady' },
  { label: 'Udupi Hub', value: 'Karnataka, Udupi, Manipal' },
  { label: 'Bengaluru Urban Hub', value: 'Karnataka, Bengaluru Urban, Indiranagar' },
  { label: 'Mysuru Hub', value: 'Karnataka, Mysuru' },
  { label: 'Mumbai Logistics Hub', value: 'Maharashtra, Mumbai' },
  { label: 'Pune Logistics Hub', value: 'Maharashtra, Pune' },
  { label: 'Chennai Hub', value: 'Tamil Nadu, Chennai' },
  { label: 'Hyderabad Hub', value: 'Telangana, Hyderabad' },
  { label: 'Kasaragod Hub', value: 'Kerala, Kasaragod' },
  { label: 'National Fleet (All Zones)', value: 'all' },
]

const VEHICLE_TYPES = [
  'SCOOTER',
  'MOTORCYCLE',
  'CAR',
  'PICKUP',
  'VAN',
  'TRUCK',
]

const STATUS_OPTIONS = [
  { label: 'Active (On Duty)', value: 'ACTIVE' },
  { label: 'On Trip (Delivering)', value: 'ON_TRIP' },
  { label: 'Standby (Available)', value: 'ACTIVE' },
  { label: 'On Leave', value: 'INACTIVE' },
  { label: 'Deactivated / Inactive', value: 'INACTIVE' },
]

export function EditDriverModal({ driver, isOpen, onClose, onSuccess }: EditDriverModalProps) {
  if (!isOpen || !driver) return null

  const initialName = (driver.name || 'Driver').replace(/\s+applicant/gi, '').trim()
  const [name, setName] = useState(initialName)
  const [phoneNumber, setPhoneNumber] = useState((driver as any).phoneNumber || (driver as any).phone || '')
  const [email, setEmail] = useState((driver as any).email || (driver as any).user?.email || '')
  const [zone, setZone] = useState((driver as any).zone || (driver as any).region || (driver as any).fleet || 'Karnataka, Dakshina Kannada, Puttur')
  const [licenseNumber, setLicenseNumber] = useState((driver as any).licenseNumber || (driver as any).license || '')
  const [vehicleName, setVehicleName] = useState((driver as any).vehicleName || (driver as any).vehicleModel || 'Tata Ace Gold EV')
  const [vehiclePlate, setVehiclePlate] = useState((driver as any).vehiclePlateNumber || (driver as any).vehiclePlate || (driver.vehicleId !== 'v-live' ? driver.vehicleId : 'KA-19-PT-2026'))
  const [vehicleType, setVehicleType] = useState((driver as any).vehicleType || 'TRUCK')
  const [emergencyName, setEmergencyName] = useState((driver as any).emergencyContactName || '')
  const [emergencyPhone, setEmergencyPhone] = useState((driver as any).emergencyContactPhone || '')
  const [status, setStatus] = useState(String(driver.status || 'ACTIVE').toUpperCase())
  const [safetyScore, setSafetyScore] = useState(typeof driver.safetyScore === 'number' ? Math.round(driver.safetyScore) : 100)

  const [isSaving, setIsSaving] = useState(false)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [successToast, setSuccessToast] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSaving(true)
    setErrorMsg(null)

    try {
      const payload: any = {
        name: name.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email.trim(),
        zone: zone.trim(),
        licenseNumber: licenseNumber.trim().toUpperCase(),
        vehicleName: vehicleName.trim(),
        vehiclePlate: vehiclePlate.trim().toUpperCase(),
        vehicleType: vehicleType.toUpperCase(),
        emergencyContactName: emergencyName.trim(),
        emergencyContactPhone: emergencyPhone.trim(),
        status: status.toUpperCase(),
        safetyScore: Number(safetyScore),
      }

      const res = await updateDriverInApi(driver.id, payload)
      setSuccessToast(true)
      setTimeout(() => {
        onSuccess({
          ...driver,
          ...payload,
          id: driver.id,
          name: name.trim(),
          fleet: zone.trim(),
          vehicleId: vehiclePlate.trim().toUpperCase(),
        })
        onClose()
      }, 700)
    } catch (err: any) {
      console.error('Update driver error:', err)
      setErrorMsg(err.message || 'Failed to update operator profile. Please check database connectivity.')
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[1100] flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md">
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          className="bg-card text-card-foreground rounded-3xl shadow-2xl border border-border w-full max-w-2xl overflow-hidden flex flex-col max-h-[92vh]"
        >
          {/* Header */}
          <div className="p-6 border-b border-border flex items-center justify-between bg-secondary/30">
            <div className="flex items-center gap-3">
              <span className="p-2.5 rounded-2xl bg-primary/10 text-primary border border-primary/20">
                <User size={20} />
              </span>
              <div>
                <h2 className="text-xl font-black font-space uppercase tracking-tight text-foreground flex items-center gap-2">
                  <span>Edit Operator Profile</span>
                  <span className="text-xs px-2 py-0.5 rounded-full bg-primary/15 text-primary border border-primary/25 font-mono">
                    DB SYNC
                  </span>
                </h2>
                <p className="text-xs text-muted-foreground font-mono mt-0.5">
                  ID: {driver.employeeId || driver.id} • Updates persist directly into PostgreSQL
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="h-10 w-10 rounded-2xl bg-secondary/80 hover:bg-secondary text-muted-foreground hover:text-foreground flex items-center justify-center transition cursor-pointer"
            >
              <X size={18} />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-6 overflow-y-auto space-y-5 flex-1">
            {errorMsg && (
              <div className="p-3.5 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs flex items-center gap-2.5 font-bold">
                <AlertTriangle size={16} className="shrink-0" />
                <span>{errorMsg}</span>
              </div>
            )}

            {successToast && (
              <div className="p-3.5 rounded-2xl bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs flex items-center gap-2.5 font-bold animate-in fade-in">
                <CheckCircle2 size={16} className="shrink-0" />
                <span>Operator record successfully updated in database!</span>
              </div>
            )}

            {/* Section 1: Basic Identity */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-wider text-muted-foreground mb-2 flex items-center gap-1.5 font-space">
                <User size={13} className="text-primary" />
                <span>Operator Identity & Contact</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Full Name</label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="Operator Full Name"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Phone Number</label>
                  <input
                    type="tel"
                    required
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="+91 98450 12345"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Email Address</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="driver@smartdrive.io"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Driving License (DL)</label>
                  <input
                    type="text"
                    required
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-mono font-bold text-xs uppercase focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="KA1920210001234"
                  />
                </div>
              </div>
            </div>

            {/* Section 2: Regional Hub & Duty Status */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-wider text-muted-foreground mb-2 flex items-center gap-1.5 font-space">
                <MapPin size={13} className="text-primary" />
                <span>Regional Jurisdiction & Operations</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Assigned Region / Hub</label>
                  <select
                    value={zone}
                    onChange={(e) => setZone(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                  >
                    {REGION_OPTIONS.map((r) => (
                      <option key={r.value} value={r.value} className="bg-card text-foreground">
                        {r.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Duty Status</label>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-bold text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                  >
                    {STATUS_OPTIONS.map((s, idx) => (
                      <option key={idx} value={s.value} className="bg-card text-foreground">
                        {s.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Section 3: Assigned Vehicle */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-wider text-muted-foreground mb-2 flex items-center gap-1.5 font-space">
                <Truck size={13} className="text-primary" />
                <span>Assigned Fleet Vehicle</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Vehicle Model / Name</label>
                  <input
                    type="text"
                    value={vehicleName}
                    onChange={(e) => setVehicleName(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="Tata Ace Gold EV"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Plate / Registration</label>
                  <input
                    type="text"
                    value={vehiclePlate}
                    onChange={(e) => setVehiclePlate(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-mono font-bold text-xs uppercase focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="KA-19-PT-2026"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Vehicle Type</label>
                  <select
                    value={vehicleType}
                    onChange={(e) => setVehicleType(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-bold text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                  >
                    {VEHICLE_TYPES.map((t) => (
                      <option key={t} value={t} className="bg-card text-foreground">
                        {t}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Section 4: Emergency Guardian Contact */}
            <div>
              <div className="text-[10px] font-black uppercase tracking-wider text-muted-foreground mb-2 flex items-center gap-1.5 font-space">
                <AlertTriangle size={13} className="text-amber-500" />
                <span>Emergency Contact / Guardian (SOS Alert Dispatch)</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Guardian / Family Name</label>
                  <input
                    type="text"
                    value={emergencyName}
                    onChange={(e) => setEmergencyName(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="e.g. Ramesh Shetty"
                  />
                </div>
                <div>
                  <label className="text-[11px] font-bold text-muted-foreground block mb-1">Guardian Phone (WhatsApp SOS)</label>
                  <input
                    type="tel"
                    value={emergencyPhone}
                    onChange={(e) => setEmergencyPhone(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-secondary/60 border border-border text-foreground font-medium text-xs focus:outline-none focus:ring-2 focus:ring-primary/40"
                    placeholder="+91 98450 99999"
                  />
                </div>
              </div>
            </div>

            {/* Footer Buttons */}
            <div className="pt-4 border-t border-border flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-5 py-2.5 rounded-xl bg-secondary hover:bg-secondary/80 text-foreground font-space font-bold text-xs uppercase transition cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSaving}
                className="px-6 py-2.5 rounded-xl bg-primary hover:bg-primary/90 text-primary-foreground font-space font-black text-xs uppercase tracking-wider flex items-center gap-2 transition shadow-lg shadow-primary/25 cursor-pointer disabled:opacity-50"
              >
                <Save size={15} />
                <span>{isSaving ? 'Saving to Database...' : 'Save Changes'}</span>
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}
