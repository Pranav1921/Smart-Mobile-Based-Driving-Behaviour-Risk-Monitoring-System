import React, { useState, useEffect } from "react";
import { FileText, Calendar, ShieldCheck, Download, AlertCircle, RefreshCw } from "lucide-react";
import apiClient from "../api/apiClient";

export default function ReportsPage() {
  const [format, setFormat] = useState("PDF");
  const [startDate, setStartDate] = useState("2026-07-01");
  const [endDate, setEndDate] = useState("2026-07-31");
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    fetchNotifications();
  }, []);

  const fetchNotifications = async () => {
    try {
      const response = await apiClient.get("/reports/notifications");
      setNotifications(response.data.data || []);
    } catch (err) {
      console.error(err);
    }
  };

  const handleExport = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage("");
    setError("");

    try {
      const response = await apiClient.post("/reports/export", {
        format,
        startDate: new Date(startDate).toISOString(),
        endDate: new Date(endDate).toISOString(),
      });

      setMessage("Report generation task enqueued! Please wait a moment and refresh notifications.");
      fetchNotifications();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Failed to enqueue report task.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-[#0c0d12]">
      <div>
        <h1 className="text-2xl font-black text-white">Operational Reports & Analytics</h1>
        <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Generate compliance documents, PDFs, and Excel logs</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Export Form */}
        <div className="glass-panel p-8 rounded-3xl border border-white/5 space-y-6">
          <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider flex items-center gap-2">
            <FileText className="w-4 h-4 text-orange-500" /> Export Configuration
          </h2>

          {message && (
            <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 p-4 rounded-2xl text-xs font-bold">
              {message}
            </div>
          )}

          {error && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-2xl text-xs font-bold">
              {error}
            </div>
          )}

          <form onSubmit={handleExport} className="space-y-6">
            <div className="space-y-2">
              <label className="text-[10px] uppercase font-black tracking-wider text-slate-400">File Export Format</label>
              <div className="flex gap-4">
                {["PDF", "EXCEL"].map((f) => (
                  <button
                    key={f}
                    type="button"
                    onClick={() => setFormat(f)}
                    className={`flex-1 py-4 rounded-2xl font-bold border text-sm transition-all cursor-pointer ${
                      format === f
                        ? "bg-orange-500/10 border-orange-500 text-white"
                        : "bg-white/2 border-white/5 text-slate-400 hover:border-white/10"
                    }`}
                  >
                    {f} DOCUMENT
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] uppercase font-black tracking-wider text-slate-400">Start Date</label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
                    <Calendar className="w-4 h-4" />
                  </span>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-12 pr-4 text-sm text-white focus:outline-none"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] uppercase font-black tracking-wider text-slate-400">End Date</label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
                    <Calendar className="w-4 h-4" />
                  </span>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-12 pr-4 text-sm text-white focus:outline-none"
                    required
                  />
                </div>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-orange-500 to-amber-500 text-white font-bold py-4 rounded-2xl shadow-lg transition-transform active:scale-[0.98] disabled:opacity-50 cursor-pointer"
            >
              {loading ? "Queueing task..." : "Export Compliance Report"}
            </button>
          </form>
        </div>

        {/* Notifications and download lists */}
        <div className="glass-panel p-8 rounded-3xl border border-white/5 flex flex-col h-[400px]">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider">System Notifications</h2>
            <button 
              onClick={fetchNotifications}
              className="p-2 hover:bg-white/5 rounded-xl border border-white/5 transition-colors cursor-pointer"
            >
              <RefreshCw className="w-4 h-4 text-slate-400" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto space-y-3 pr-2">
            {notifications.map((n) => (
              <div 
                key={n.id}
                className="bg-white/2 border border-white/5 p-4 rounded-2xl flex justify-between items-start"
              >
                <div className="space-y-1">
                  <h4 className="font-bold text-white text-xs">{n.title}</h4>
                  <p className="text-[11px] text-slate-400">{n.message}</p>
                  <p className="text-[9px] text-slate-500 font-bold">{new Date(n.createdAt).toLocaleTimeString()}</p>
                </div>
                {n.title.toLowerCase().includes("report") && (
                  <button 
                    onClick={() => {
                      // Trigger download of latest mock/real static report in a new tab
                      window.open("http://localhost:3000/uploads/reports/", "_blank");
                    }}
                    className="p-2 bg-orange-500/15 border border-orange-500/20 hover:bg-orange-500/25 rounded-xl text-orange-400 transition-colors cursor-pointer"
                    title="Download Report file"
                  >
                    <Download className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
            {notifications.length === 0 && (
              <div className="h-full flex items-center justify-center text-slate-500 text-xs">
                No system alerts or compliance notification events.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}