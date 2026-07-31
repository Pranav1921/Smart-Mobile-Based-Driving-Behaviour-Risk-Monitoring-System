import { motion } from 'framer-motion'
import { FileText, FileSpreadsheet, FileDown, Download, Calendar } from 'lucide-react'
import { PageHeader } from '@/components/ui/PageHeader'
import { GlassCard } from '@/components/ui/GlassCard'
import { Badge } from '@/components/ui/Badge'

const FORMATS = [
  { icon: FileText, label: 'PDF Report', desc: 'Executive fleet safety summary', color: '#f43f5e', ext: 'PDF' },
  { icon: FileSpreadsheet, label: 'Excel Export', desc: 'Full trip & event dataset', color: '#34d399', ext: 'XLSX' },
  { icon: FileDown, label: 'CSV Export', desc: 'Raw telemetry for analysis', color: '#22d3ee', ext: 'CSV' },
]

const recent = [
  { name: 'Weekly Fleet Safety · Jul W3', type: 'PDF', size: '2.4 MB', date: 'Jul 18, 2026' },
  { name: 'Driver Performance · June', type: 'XLSX', size: '860 KB', date: 'Jul 01, 2026' },
  { name: 'NH66 Incident Log', type: 'CSV', size: '1.1 MB', date: 'Jun 28, 2026' },
  { name: 'Monthly Executive Summary', type: 'PDF', size: '3.8 MB', date: 'Jun 30, 2026' },
]

export default function Reports() {
  return (
    <div>
      <PageHeader title="Reports" subtitle="Generate and export fleet intelligence reports." />
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-6">
        {FORMATS.map((f, i) => (
          <motion.div key={f.label} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.06 }}>
            <GlassCard className="group cursor-pointer">
              <div className="grid place-items-center h-12 w-12 rounded-xl mb-4" style={{ background: f.color + '1a', color: f.color }}>
                <f.icon className="h-6 w-6" />
              </div>
              <div className="font-display font-semibold text-primary">{f.label}</div>
              <p className="text-[12.5px] text-muted mt-1">{f.desc}</p>
              <button className="mt-4 w-full h-9 rounded-xl bg-white/[0.04] border border-white/8 text-[12.5px] text-secondary group-hover:text-primary group-hover:border-cyan-400/30 transition flex items-center justify-center gap-2">
                <Download className="h-3.5 w-3.5" /> Generate {f.ext}
              </button>
            </GlassCard>
          </motion.div>
        ))}
      </div>

      <GlassCard padded={false} className="overflow-hidden">
        <div className="p-5 pb-3 flex items-center gap-2"><Calendar className="h-4 w-4 text-cyan-300" /><h3 className="font-display font-semibold text-primary">Recent Reports</h3></div>
        <div className="px-3 pb-3">
          {recent.map((r, i) => (
            <motion.div key={i} initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.04 }}
              className="flex items-center gap-3 px-3 py-3 rounded-xl hover:bg-white/[0.03]">
              <div className="grid place-items-center h-9 w-9 rounded-lg bg-white/[0.04] text-secondary"><FileText className="h-4 w-4" /></div>
              <div className="flex-1 min-w-0"><div className="text-[13px] text-primary font-medium truncate">{r.name}</div><div className="text-[11px] text-muted">{r.date} · {r.size}</div></div>
              <Badge tone="cyan">{r.type}</Badge>
              <button className="grid place-items-center h-8 w-8 rounded-lg hover:bg-white/5 text-muted hover:text-cyan-300"><Download className="h-4 w-4" /></button>
            </motion.div>
          ))}
        </div>
      </GlassCard>
    </div>
  )
}
