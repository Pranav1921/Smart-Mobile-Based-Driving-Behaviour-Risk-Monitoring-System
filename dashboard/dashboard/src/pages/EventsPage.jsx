import React, { useState, useEffect } from "react";
import { AlertCircle, ShieldAlert, ShieldAlert as DangerIcon, CheckCircle, Search, Filter } from "lucide-react";
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

  const getSeverityStyle = (sev) => {
    switch (sev) {
      case "CRITICAL":
        return "bg-red-500/20 text-red-400 border border-red-500/20";
      case "HIGH":
        return "bg-orange-500/20 text-orange-400 border border-orange-500/20";
      case "MEDIUM":
        return "bg-yellow-500/20 text-yellow-400 border border-yellow-500/20";
      default:
        return "bg-slate-800 text-slate-400 border border-slate-700";
    }
  };

  const getEventIcon = (type) => {
    if (type === "CRASH") {
      return <DangerIcon className="w-5 h-5 text-red-500" />;
    }
    return <AlertCircle className="w-5 h-5 text-orange-500" />;
  };

  const filtered = events.filter(e => {
    const driverName = `${e.driver?.user?.firstName || ''} ${e.driver?.user?.lastName || ''}`.toLowerCase();
    const matchesSearch = driverName.includes(search.toLowerCase()) || e.eventType.toLowerCase().includes(search.toLowerCase());
    const matchesSeverity = severityFilter === "ALL" || e.severity === severityFilter;
    return matchesSearch && matchesSeverity;
  });

  return (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-[#0c0d12]">
      {/* Page Title & Filter options */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-black text-white">Telemetry & Safety Logs</h1>
          <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Chronological raw sensor warnings & driver events</p>
        </div>

        {/* Filter bars */}
        <div className="flex items-center gap-4 w-full md:w-auto">
          {/* Search */}
          <div className="relative flex-1 md:flex-initial">
            <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
              <Search className="w-5 h-5" />
            </span>
            <input
              type="text"
              placeholder="Search driver name or event..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-12 pr-6 text-sm text-white focus:outline-none w-full md:w-64 transition-all placeholder-slate-600"
            />
          </div>

          {/* Severity selector */}
          <div className="relative">
            <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
              <Filter className="w-4 h-4" />
            </span>
            <select
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
              className="bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-11 pr-8 text-sm text-white focus:outline-none appearance-none cursor-pointer"
            >
              <option value="ALL">All Severity</option>
              <option value="CRITICAL">Critical</option>
              <option value="HIGH">High</option>
              <option value="MEDIUM">Medium</option>
              <option value="LOW">Low</option>
            </select>
          </div>
        </div>
      </div>

      {/* Events Table Container */}
      <div className="glass-panel rounded-3xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5">
          <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider">Raw Telemetry Warning Stream</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5 text-[10px] text-slate-400 uppercase tracking-widest font-black">
                <th className="p-6">Event Type</th>
                <th className="p-6">Driver name</th>
                <th className="p-6">Coordinates</th>
                <th className="p-6 text-center">Severity</th>
                <th className="p-6">Timestamp</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filtered.map(e => {
                const driverName = `${e.driver?.user?.firstName || 'David'} ${e.driver?.user?.lastName || 'Driver'}`;
                const timeStr = new Date(e.timestamp).toLocaleString();
                return (
                  <tr key={e.id} className="hover:bg-white/2 transition-colors">
                    <td className="p-6">
                      <div className="flex items-center gap-3">
                        {getEventIcon(e.eventType)}
                        <span className="font-bold text-white text-sm uppercase tracking-wide">{e.eventType.replace("_", " ")}</span>
                      </div>
                    </td>
                    <td className="p-6 text-slate-300 font-bold text-sm">
                      {driverName}
                    </td>
                    <td className="p-6 text-slate-400 text-xs font-bold">
                      {e.latitude.toFixed(5)}, {e.longitude.toFixed(5)}
                    </td>
                    <td className="p-6 text-center">
                      <span className={`px-2.5 py-0.5 rounded text-[10px] font-black tracking-wider uppercase ${getSeverityStyle(e.severity)}`}>
                        {e.severity}
                      </span>
                    </td>
                    <td className="p-6 text-slate-500 text-xs font-bold">
                      {timeStr}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="p-12 text-center text-slate-500 text-sm">
              No safety events logged.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}