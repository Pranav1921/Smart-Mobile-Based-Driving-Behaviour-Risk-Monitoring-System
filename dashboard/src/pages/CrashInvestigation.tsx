import { MapContainer, TileLayer, Marker, Circle } from 'react-leaflet'
import L from 'leaflet'
import { motion } from 'framer-motion'
import { Play, Phone, Brain, Activity, Camera, Clock, TriangleAlert } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'
import { AreaLineChart } from '@/components/charts/Charts'
import { driverById } from '@/data/mockData'

const crashIcon = L.divIcon({
  className: '', iconSize: [40, 40], iconAnchor: [20, 20],
  html: `<div style="position:relative;width:40px;height:40px;">
    <div style="position:absolute;inset:0;border-radius:50%;background:#f43f5e;opacity:.3;filter:blur(6px);"></div>
    <div style="position:absolute;inset:12px;border-radius:50%;background:#f43f5e;border:2px solid #fff;box-shadow:0 0 14px #f43f5e;"></div></div>`,
})

const timeline = [
  { t: '14:32:01', label: 'Normal driving · 78 km/h', tone: 'safe' },
  { t: '14:32:04', label: 'Overspeed detected · 94 km/h', tone: 'warn' },
  { t: '14:32:06', label: 'Harsh braking · -0.9 g', tone: 'warn' },
  { t: '14:32:07', label: 'Impact spike · 4.8 G', tone: 'danger' },
  { t: '14:32:08', label: 'Vehicle stationary · airbag signal', tone: 'danger' },
  { t: '14:32:20', label: 'Auto-upload: video, images, sensors', tone: 'info' },
]

const gForce = [0.1, 0.2, 0.15, 0.3, 0.9, 4.8, 2.1, 0.4, 0.1, 0.05, 0.05, 0.02]

export default function CrashInvestigation() {
  const d = driverById('d3')!
  return (
    <div>
      <PageHeader
        title="Crash Investigation"
        subtitle={`${d.name} · ${d.locationName} · 4.8G impact event`}
        actions={<Badge tone="critical" dot>Severity · Critical</Badge>}
      />
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        {/* left col */}
        <div className="space-y-5">
          <GlassCard>
            <SectionTitle icon={Clock} title="Crash Timeline" />
            <div className="relative pl-5 mt-2">
              <div className="absolute left-[5px] top-1 bottom-1 w-px bg-white/10" />
              {timeline.map((e, i) => (
                <motion.div key={i} initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.08 }} className="relative pb-3.5 last:pb-0">
                  <span className="absolute -left-[17px] top-1 h-2.5 w-2.5 rounded-full" style={{ background: e.tone === 'danger' ? '#f43f5e' : e.tone === 'warn' ? '#fbbf24' : e.tone === 'info' ? '#22d3ee' : '#34d399' }} />
                  <div className="text-[11px] text-muted tabular-nums">{e.t}</div>
                  <div className="text-[12.5px] text-primary">{e.label}</div>
                </motion.div>
              ))}
            </div>
          </GlassCard>

          <GlassCard>
            <SectionTitle icon={Phone} title="Emergency Contact" />
            <div className="space-y-2 mt-2">
              <ContactRow label="Fleet Manager" value="+91 98450 22190" />
              <ContactRow label="Emergency (108)" value="Ambulance dispatched" />
              <ContactRow label="Insurance · ICICI Lombard" value="Claim #CL-88213" />
            </div>
            <button className="w-full mt-3 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-200 text-[13px] font-semibold hover:bg-rose-500/25 transition">
              Trigger Emergency Protocol
            </button>
          </GlassCard>
        </div>

        {/* center: map + media */}
        <div className="space-y-5">
          <GlassCard padded={false} className="overflow-hidden">
            <div className="h-56">
              <MapContainer center={[d.location.lat, d.location.lng]} zoom={15} zoomControl={false} className="h-full w-full" scrollWheelZoom={false}>
                <TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" />
                <Circle center={[d.location.lat, d.location.lng]} radius={120} pathOptions={{ color: '#f43f5e', fillColor: '#f43f5e', fillOpacity: 0.12 }} />
                <Marker position={[d.location.lat, d.location.lng]} icon={crashIcon} />
              </MapContainer>
            </div>
            <div className="p-4 flex items-center gap-2 text-[12px] text-muted">
              <TriangleAlert className="h-3.5 w-3.5 text-rose-400" /> {d.locationName} · 12.936, 74.867
            </div>
          </GlassCard>

          <GlassCard>
            <SectionTitle icon={Play} title="Recorded Video" />
            <div className="relative h-40 rounded-xl bg-black/40 grid place-items-center overflow-hidden mt-2 border border-white/8">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(34,211,238,0.08),transparent)]" />
              <button className="grid place-items-center h-12 w-12 rounded-full accent-gradient text-white ring-glow z-10 hover:scale-105 transition"><Play className="h-5 w-5 ml-0.5" /></button>
              <span className="absolute bottom-2 left-3 text-[10px] text-muted">crash_clip_14-32-07.mp4 · last 30s</span>
            </div>
            <SectionTitle icon={Camera} title="Captured Images" />
            <div className="grid grid-cols-3 gap-2 mt-2">
              {[0, 1, 2].map((k) => (
                <div key={k} className="aspect-video rounded-lg bg-white/[0.04] border border-white/8 grid place-items-center">
                  <Camera className="h-4 w-4 text-muted" />
                </div>
              ))}
            </div>
          </GlassCard>
        </div>

        {/* right: sensors + AI */}
        <div className="space-y-5">
          <GlassCard>
            <SectionTitle icon={Activity} title="Sensor Graph · Impact" />
            <AreaLineChart labels={gForce.map((_, i) => `${i}`)} series={[{ name: 'G-Force', data: gForce, color: '#f43f5e' }]} height={180} />
          </GlassCard>

          <GlassCard className="border border-cyan-400/20">
            <SectionTitle icon={Brain} title="AI Crash Analysis" />
            <div className="grid grid-cols-2 gap-2 mt-2">
              <Metric label="Impact" value="4.8 G" tone="#f43f5e" />
              <Metric label="Severity" value="Critical" tone="#f43f5e" />
              <Metric label="Confidence" value="96%" tone="#22d3ee" />
              <Metric label="Airbag" value="Deployed" tone="#fbbf24" />
            </div>
            <p className="text-[12.5px] text-secondary leading-relaxed mt-3">
              Frontal collision pattern consistent with sudden deceleration after overspeed on NH66. High injury-risk profile.
              Immediate medical dispatch and on-site responder recommended. Vehicle telematics indicate no post-impact movement.
            </p>
          </GlassCard>
        </div>
      </div>
    </div>
  )
}

function SectionTitle({ icon: Icon, title }: { icon: React.ElementType; title: string }) {
  return <div className="flex items-center gap-2 mt-3 first:mt-0 mb-1"><Icon className="h-3.5 w-3.5 text-cyan-300" /><span className="text-[11px] font-semibold uppercase tracking-wider text-secondary">{title}</span></div>
}
function Metric({ label, value, tone }: { label: string; value: string; tone: string }) {
  return <div className="glass rounded-xl p-3"><div className="text-[10px] text-muted uppercase tracking-wide">{label}</div><div className="text-lg font-display font-bold mt-1" style={{ color: tone }}>{value}</div></div>
}
function ContactRow({ label, value }: { label: string; value: string }) {
  return <div className="glass rounded-xl p-2.5 flex items-center justify-between"><span className="text-[12px] text-secondary">{label}</span><span className="text-[12px] text-primary font-medium">{value}</span></div>
}
