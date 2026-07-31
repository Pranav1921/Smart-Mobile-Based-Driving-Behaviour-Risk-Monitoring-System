import React, { useState } from "react";
import { FileText, Download, Calendar, Filter, CheckCircle, RefreshCw } from "lucide-react";

export default function ReportsPage() {
  const [reportType, setReportType] = useState("SAFETY_AUDIT");
  const [format, setFormat] = useState("PDF");
  const [dateRange, setDateRange] = useState("LAST_30_DAYS");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    setLoading(true);
    setSuccess(false);

    // Mock enqueuing a background BullMQ worker job
    setTimeout(() => {
      setLoading(false);
      setSuccess(true);
    }, 1800);
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-[#0c0d12] font-sans">
      {/* Title */}
      <div>
        <h1 className="text-2xl font-black text-white">Compliance Reporting</h1>
        <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Tesla Cyber-HUD &bull; BullMQ Export Generator</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Export Form */}
        <div className="bg-[#0e1017] p-8 rounded-3xl border border-white/5 lg:col-span-2 space-y-6">
          <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider">Generate Compliance Export</h2>
          
          {success && (
            <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl flex items-center gap-3 text-emerald-400 text-xs font-semibold">
              <CheckCircle className="w-5 h-5 flex-shrink-0" />
              <span>Export job enqueued successfully. Check downloads in a few moments.</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Report Category */}
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest pl-1">Report Category</label>
                <select 
                  value={reportType}
                  onChange={(e) => setReportType(e.target.value)}
                  className="w-full bg-[#12141d] border border-white/5 text-xs font-black text-white p-4 rounded-2xl outline-none focus:border-orange-500/50 uppercase tracking-wider cursor-pointer"
                >
                  <option value="SAFETY_AUDIT">Driver Safety Audit</option>
                  <option value="CRASH_ANALYTICS">Crash Investigation Reports</option>
                  <option value="FLEET_EFFICIENCY">Fleet Efficiency Ratings</option>
                  <option value="TELEMETRY_RAW">Raw G-Force Logs</option>
                </select>
              </div>

              {/* Format */}
              <div className="space-y-1.5">
                <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest pl-1">Document Format</label>
                <select 
                  value={format}
                  onChange={(e) => setFormat(e.target.value)}
                  className="w-full bg-[#12141d] border border-white/5 text-xs font-black text-white p-4 rounded-2xl outline-none focus:border-orange-500/50 uppercase tracking-wider cursor-pointer"
                >
                  <option value="PDF">Portable Document Format (PDF)</option>
                  <option value="XLSX">Excel Spreadsheet (XLSX)</option>
                  <option value="CSV">Comma Separated Values (CSV)</option>
                </select>
              </div>
            </div>

            {/* Date Range */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest pl-1">Time Horizon</label>
              <select 
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value)}
                className="w-full bg-[#12141d] border border-white/5 text-xs font-black text-white p-4 rounded-2xl outline-none focus:border-orange-500/50 uppercase tracking-wider cursor-pointer"
              >
                <option value="LAST_7_DAYS">Last 7 Days</option>
                <option value="LAST_30_DAYS">Last 30 Days</option>
                <option value="THIS_QUARTER">This Quarter (90 Days)</option>
                <option value="CUSTOM">Custom Range...</option>
              </select>
            </div>

            <button 
              type="submit"
              disabled={loading}
              className="bg-orange-600 hover:bg-orange-700 text-white font-black px-8 py-4 rounded-3xl text-xs uppercase tracking-widest flex items-center gap-2 cursor-pointer shadow-lg shadow-orange-600/10 disabled:opacity-50"
            >
              {loading ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" /> Enqueuing Job...
                </>
              ) : (
                <>
                  <Download className="w-4 h-4" /> Trigger Export Job
                </>
              )}
            </button>
          </form>
        </div>

        {/* Audit status panel */}
        <div className="bg-[#0e1017] p-8 rounded-3xl border border-white/5 space-y-6">
          <h3 className="text-xs uppercase font-black text-slate-400 tracking-wider">Export Queue Status</h3>
          <div className="space-y-4">
            <QueueItem label="Job #10294 - SAFETY_AUDIT" status="COMPLETED" date="Today, 11:20 AM" />
            <QueueItem label="Job #10281 - CRASH_ANALYTICS" status="COMPLETED" date="Yesterday, 4:45 PM" />
            <QueueItem label="Job #10272 - FLEET_EFFICIENCY" status="COMPLETED" date="July 18, 2026" />
          </div>
        </div>
      </div>
    </div>
  );
}

function QueueItem({ label, status, date }) {
  return (
    <div className="p-4 bg-[#07080d] rounded-2xl border border-white/5 flex justify-between items-center text-xs">
      <div>
        <p className="font-bold text-white">{label}</p>
        <p className="text-[10px] text-slate-500 font-semibold mt-1">{date}</p>
      </div>
      <span className="px-2 py-0.5 rounded text-[9px] font-black tracking-wider bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 uppercase">
        {status}
      </span>
    </div>
  );
}
