import React, { useState, useEffect } from "react";
import { ShieldAlert, Search, Filter, AlertTriangle, AlertCircle, Info } from "lucide-react";
import apiClient from "../api/apiClient";

export default function EventsPage() {
  const [events, setEvents] = useState([]);
  const [search, setSearch] = useState("");
  const [severityFilter, setSeverityFilter] = useState("ALL");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get("/events");
      setEvents(response.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const filtered = events.filter(e => {
    const typeMatches = e.eventType.toLowerCase().includes(search.toLowerCase());
    const severityMatches = severityFilter === "ALL" || e.severity === severityFilter;
    return typeMatches && severityMatches;
  });

  return (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-[#0c0d12] font-sans">
      {/* Title */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-black text-white">Telemetry Warning Logs</h1>
          <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Tesla Cyber-HUD &bull; Sensor G-Force violations</p>
        </div>
        
        {/* Filters */}
        <div className="flex gap-4">
          <div className="relative">
            <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
              <Search className="w-4 h-4" />
            </span>
            <input
              type="text"
              placeholder="Search event type..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-11 pr-5 text-xs text-white focus:outline-none w-60 transition-all placeholder-slate-600 font-semibold"
            />
          </div>

          <select 
            value={severityFilter}
            onChange={(e) => setSeverityFilter(e.target.value)}
            className="bg-[#12141d] border border-white/5 text-xs font-black text-white px-5 py-3 rounded-2xl outline-none focus:border-orange-500/50 uppercase tracking-widest cursor-pointer"
          >
            <option value="ALL">ALL SEVERITIES</option>
            <option value="LOW">LOW</option>
            <option value="MEDIUM">MEDIUM</option>
            <option value="HIGH">HIGH</option>
            <option value="CRITICAL">CRITICAL</option>
          </select>
        </div>
      </div>

      {/* Events Table */}
      <div className="bg-[#0e1017] rounded-3xl border border-white/5 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5 text-[10px] text-slate-400 uppercase tracking-widest font-black">
                <th className="p-6">Event Type</th>
                <th className="p-6">Driver Profile</th>
                <th className="p-6">Trigger Value</th>
                <th className="p-6 text-center">Severity</th>
                <th className="p-6">Coordinates</th>
                <th className="p-6">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filtered.map(e => {
                const driverName = `${e.trip?.driver?.user?.firstName || 'David'} ${e.trip?.driver?.user?.lastName || 'Driver'}`;
                const isDanger = e.severity === "HIGH" || e.severity === "CRITICAL";
                const isWarning = e.severity === "MEDIUM";

                return (
                  <tr key={e.id} className="hover:bg-white/2 transition-colors">
                    <td className="p-6">
                      <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-xl ${isDanger ? "bg-red-500/10 border border-red-500/20" : isWarning ? "bg-amber-500/10 border border-amber-500/20" : "bg-slate-500/10 border border-slate-500/20"}`}>
                          <ShieldAlert className={`w-4 h-4 ${isDanger ? "text-red-400" : isWarning ? "text-amber-400" : "text-slate-400"}`} />
                        </div>
                        <span className="font-bold text-white text-sm uppercase tracking-wide">{e.eventType.replace("_", " ")}</span>
                      </div>
                    </td>
                    <td className="p-6 text-slate-300 font-bold text-sm">
                      {driverName}
                    </td>
                    <td className="p-6 text-slate-300 font-semibold text-xs">
                      {e.sensorValues?.triggerValue || "G-Force Delta: 1.45g"}
                    </td>
                    <td className="p-6 text-center">
                      <span className={`px-2.5 py-0.5 rounded text-[9px] font-black tracking-wider uppercase ${
                        isDanger ? "bg-red-500/20 text-red-400 border border-red-500/20" : isWarning ? "bg-amber-500/20 text-amber-400 border border-amber-500/20" : "bg-slate-800 text-slate-400 border border-slate-700"
                      }`}>
                        {e.severity}
                      </span>
                    </td>
                    <td className="p-6 text-slate-400 font-bold text-xs tracking-wider">
                      {e.latitude.toFixed(5)}, {e.longitude.toFixed(5)}
                    </td>
                    <td className="p-6 text-slate-400 font-semibold text-xs">
                      {new Date(e.timestamp).toLocaleString()}
                    </td>
                  </tr>
                );
              })}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan="6" className="p-12 text-center text-slate-600 text-xs font-black uppercase tracking-wider">
                    No matching violations found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
