import { useState } from 'react'
import { ShieldAlert, Lock, User, AlertCircle, Briefcase } from 'lucide-react'

interface LoginPageProps {
  onLogin: () => void
}

export default function LoginPage({ onLogin }: LoginPageProps) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [department, setDepartment] = useState('Food Delivery')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    // Simulate login validation with department checks
    setTimeout(() => {
      if (username === 'admin' && password === 'admin123') {
        if (department === 'Food Delivery' || department === 'Logistics') {
          localStorage.setItem('fleetguard_admin_token', 'authenticated_session_token')
          localStorage.setItem('fleetguard_admin_department', department)
          onLogin()
        } else {
          setError('Access Denied. Admin portal is restricted to Food Delivery & Logistics departments.')
        }
      } else {
        setError('Invalid username or password. Use admin / admin123')
      }
      setLoading(false)
    }, 800)
  }

  return (
    <div className="fixed inset-0 grid place-items-center bg-[#070b18] z-[9999] overflow-y-auto px-4 py-8">
      {/* Background glow effects */}
      <div className="absolute top-1/4 left-1/4 h-[350px] w-[350px] rounded-full bg-cyan-500/10 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 h-[350px] w-[350px] rounded-full bg-indigo-500/10 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-[420px] glass rounded-3xl p-8 relative overflow-hidden shadow-2xl border border-white/5">
        <div className="flex flex-col items-center text-center mb-8">
          <div className="grid place-items-center h-14 w-14 rounded-2xl accent-gradient shadow-lg ring-glow mb-4">
            <ShieldAlert className="h-7 w-7 text-white" />
          </div>
          <h1 className="font-display font-bold text-2xl text-primary">स्वदेशी FleetGuard</h1>
          <p className="text-[10px] text-cyan-400 tracking-widest uppercase font-semibold mt-1">Admin Command Center</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="flex items-center gap-2.5 p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-[13px]">
              <AlertCircle className="h-4.5 w-4.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[11.5px] font-semibold text-secondary uppercase tracking-wider">Username</label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter admin username"
                className="h-11 w-full rounded-xl bg-white/[0.04] border border-white/8 pl-10 pr-4 text-[13.5px] text-primary placeholder:text-muted outline-none focus:border-cyan-400/40 transition-colors"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-[11.5px] font-semibold text-secondary uppercase tracking-wider">Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter admin password"
                className="h-11 w-full rounded-xl bg-white/[0.04] border border-white/8 pl-10 pr-4 text-[13.5px] text-primary placeholder:text-muted outline-none focus:border-cyan-400/40 transition-colors"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-[11.5px] font-semibold text-secondary uppercase tracking-wider">Department</label>
            <div className="relative">
              <Briefcase className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted" />
              <select
                value={department}
                onChange={(e) => setDepartment(e.target.value)}
                className="h-11 w-full rounded-xl bg-white/[0.04] border border-white/8 pl-10 pr-4 text-[13.5px] text-primary outline-none focus:border-cyan-400/40 transition-colors appearance-none cursor-pointer"
              >
                <option value="Food Delivery" className="bg-[#070b18] text-primary">Food Delivery (Active)</option>
                <option value="Logistics" className="bg-[#070b18] text-primary">Logistics</option>
                <option value="Courier" className="bg-[#070b18] text-primary">Courier</option>
                <option value="Passenger" className="bg-[#070b18] text-primary">Passenger</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full h-11 rounded-xl accent-gradient text-white text-[13.5px] font-semibold shadow-lg ring-glow hover:brightness-110 active:brightness-95 disabled:opacity-50 transition-all flex items-center justify-center gap-2 mt-2"
          >
            {loading ? 'Authenticating...' : 'Sign In to Command Center'}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-white/5 text-center">
          <p className="text-[11px] text-muted">
            Intended for authorized fleet administrators only.
          </p>
          <p className="text-[10px] text-cyan-400/60 mt-1 font-mono">
            Demo credentials: admin / admin123<br />
            Allowed Depts: Food Delivery or Logistics
          </p>
        </div>
      </div>
    </div>
  )
}
