import React, { useState, useEffect } from "react";
import { 
  Award, ShieldCheck, TrendingUp, TriangleAlert as AlertTriangle,
  Search, ArrowUpDown, ChevronRight, Zap, Flame, Trophy 
} from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import apiClient from "../api/apiClient";

export default function DriversPage() {
  const [drivers, setDrivers] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get("/drivers");
      const fetched = response.data.data || [];
      
      // Inject fallback values for gamification indicators if database is empty/fresh
      const enriched = fetched.map((d, index) => ({
        ...d,
        xp: d.xp || (index === 0 ? 2450 : index === 1 ? 890 : 340),
        level: d.level || (index === 0 ? 3 : index === 1 ? 1 : 1),
        streak: d.streak || (index === 0 ? 5 : index === 1 ? 1 : 0),
        badges: d.badges && d.badges.length > 0 ? d.badges : (index === 0 ? ["smooth_operator", "speed_sentinel"] : index === 1 ? ["focus_champion"] : [])
      }));

      setDrivers(enriched);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const trendData = [
    { name: "Week 1", AvgScore: 92 },
    { name: "Week 2", AvgScore: 90 },
    { name: "Week 3", AvgScore: 94 },
    { name: "Week 4", AvgScore: 93 },
    { name: "Week 5", AvgScore: 95 },
  ];

  // Sort drivers for rankings podium
  const sortedDrivers = [...drivers].sort((a, b) => b.safetyScore - a.safetyScore);
  const topThree = sortedDrivers.slice(0, 3);

  const filtered = drivers.filter(d => {
    const name = `${d.user?.firstName || ''} ${d.user?.lastName || ''}`.toLowerCase();
    return name.includes(search.toLowerCase()) || d.licenseNumber.toLowerCase().includes(search.toLowerCase());
  });

  const getBadgeIcon = (badge) => {
    switch (badge) {
      case "smooth_operator":
        return <span className="px-2 py-1 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 rounded-lg text-[9px] font-black uppercase tracking-wider">🚀 Smooth</span>;
      case "speed_sentinel":
        return <span className="px-2 py-1 bg-orange-500/10 border border-orange-500/20 text-orange-400 rounded-lg text-[9px] font-black uppercase tracking-wider">🛡️ Speed</span>;
      case "focus_champion":
        return <span className="px-2 py-1 bg-pink-500/10 border border-pink-500/20 text-pink-400 rounded-lg text-[9px] font-black uppercase tracking-wider">📱 Focused</span>;
      default:
        return null;
    }
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 space-y-8 bg-[#0c0d12]">
      {/* Title */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-black text-white">Driver Performance & Leaderboards</h1>
          <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Tesla Cyber-HUD &bull; Gamified safety ranks</p>
        </div>
        
        {/* Search */}
        <div className="relative">
          <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
            <Search className="w-5 h-5" />
          </span>
          <input
            type="text"
            placeholder="Search active operator..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-[#12141d] border border-white/5 focus:border-orange-500/50 rounded-2xl py-3 pl-12 pr-6 text-sm text-white focus:outline-none w-72 transition-all placeholder-slate-600"
          />
        </div>
      </div>

      {/* Gamified Podium (Top 3 Ranks) */}
      {topThree.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {topThree[1] && (
            <PodiumBox 
              driver={topThree[1]} 
              rank={2} 
              color="border-slate-400/30 text-slate-300"
              bg="from-slate-400/5 to-transparent"
              trophyColor="text-slate-400"
            />
          )}
          {topThree[0] && (
            <PodiumBox 
              driver={topThree[0]} 
              rank={1} 
              color="border-amber-400/40 text-amber-300 scale-105"
              bg="from-amber-400/5 to-transparent"
              trophyColor="text-amber-400 animate-bounce"
            />
          )}
          {topThree[2] && (
            <PodiumBox 
              driver={topThree[2]} 
              rank={3} 
              color="border-amber-700/30 text-amber-600"
              bg="from-amber-700/5 to-transparent"
              trophyColor="text-amber-700"
            />
          )}
        </div>
      )}

      {/* Main split: Recharts Trend + Metric Summary */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="bg-[#0e1017] p-6 rounded-3xl xl:col-span-2 border border-white/5">
          <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider mb-6">FLEET SAFETY TRENDS</h2>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trendData}>
                <defs>
                  <linearGradient id="scoreColor" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f97316" stopOpacity={0.2}/>
                    <stop offset="95%" stopColor="#f97316" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis domain={[50, 100]} stroke="#64748b" fontSize={11} tickLine={false} />
                <Tooltip contentStyle={{ backgroundColor: '#12141d', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '12px' }} />
                <Area type="monotone" dataKey="AvgScore" stroke="#f97316" strokeWidth={2.5} fillOpacity={1} fill="url(#scoreColor)" name="Average Score" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Info panel */}
        <div className="space-y-4">
          <MetricPanel label="Safety Index" value="95.0" desc="Excellent safety threshold rating" icon={<ShieldCheck className="w-6 h-6 text-emerald-400" />} />
          <MetricPanel label="Average Risk Factor" value="5%" desc="Low-risk profile operations" icon={<TrendingUp className="w-6 h-6 text-orange-400" />} />
          <MetricPanel label="Warnings Issued" value="0" desc="Zero critical incidents logged" icon={<AlertTriangle className="w-6 h-6 text-red-400" />} />
        </div>
      </div>

      {/* Driver records Table */}
      <div className="bg-[#0e1017] rounded-3xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5">
          <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider">Active Operators Directory</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5 text-[10px] text-slate-400 uppercase tracking-widest font-black">
                <th className="p-6">Operator Detail</th>
                <th className="p-6">License ID</th>
                <th className="p-6 text-center">Streak</th>
                <th className="p-6">Achievements</th>
                <th className="p-6 text-center">Safety Rating</th>
                <th className="p-6">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filtered.map(d => {
                const name = `${d.user?.firstName || 'David'} ${d.user?.lastName || 'Driver'}`;
                return (
                  <tr key={d.id} className="hover:bg-white/2 transition-colors">
                    <td className="p-6">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-[#12141d] border border-white/10 flex items-center justify-center font-black text-xs text-orange-500">
                          {d.level}
                        </div>
                        <div>
                          <p className="font-bold text-white text-sm">{name}</p>
                          <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">{d.xp} XP total</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-6 text-slate-300 font-bold text-sm">
                      {d.licenseNumber}
                    </td>
                    <td className="p-6 text-center">
                      {d.streak > 0 ? (
                        <span className="inline-flex items-center gap-1 text-xs font-black text-orange-400 bg-orange-500/10 border border-orange-500/20 px-2.5 py-0.5 rounded-full">
                          <Flame className="w-3.5 h-3.5 fill-orange-500 text-orange-500 animate-pulse" /> {d.streak} days
                        </span>
                      ) : (
                        <span className="text-slate-600">-</span>
                      )}
                    </td>
                    <td className="p-6">
                      <div className="flex gap-2">
                        {d.badges?.map(b => getBadgeIcon(b))}
                        {(!d.badges || d.badges.length === 0) && <span className="text-xs text-slate-600">None yet</span>}
                      </div>
                    </td>
                    <td className="p-6 text-center">
                      <span className={`text-sm font-black ${
                        d.safetyScore > 85 ? "text-emerald-400" : d.safetyScore > 70 ? "text-amber-400" : "text-red-400"
                      }`}>{d.safetyScore}%</span>
                    </td>
                    <td className="p-6">
                      <span className={`px-2.5 py-0.5 rounded text-[10px] font-black tracking-wider uppercase ${
                        d.status === "ACTIVE" 
                          ? "bg-slate-800 text-slate-400 border border-slate-700" 
                          : "bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 pulse-safe"
                      }`}>
                        {d.status}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function PodiumBox({ driver, rank, color, bg, trophyColor }) {
  const name = `${driver.user?.firstName || 'Operator'} ${driver.user?.lastName || ''}`;
  return (
    <div className={`bg-[#0e1017] bg-gradient-to-b ${bg} border ${color} p-6 rounded-3xl flex items-center justify-between shadow-xl transition-all`}>
      <div className="flex items-center gap-4">
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-[#12141d] border border-white/10 flex items-center justify-center font-black text-slate-300">
            {driver.level}
          </div>
          <span className="absolute -top-2.5 -left-2.5 w-6 h-6 rounded-full bg-slate-900 border border-white/10 flex items-center justify-center text-[10px] font-black text-orange-500">
            #{rank}
          </span>
        </div>
        <div>
          <h3 className="font-black text-white text-sm">{name}</h3>
          <p className="text-[10px] text-slate-400 uppercase tracking-widest mt-0.5 font-bold">Lvl {driver.level} &bull; {driver.xp} XP</p>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <div className="text-right">
          <p className="text-xs uppercase font-black text-slate-500 tracking-wider">Score</p>
          <p className="font-black text-xl text-emerald-400 mt-0.5">{driver.safetyScore}%</p>
        </div>
        <Trophy className={`w-8 h-8 ${trophyColor}`} />
      </div>
    </div>
  );
}

function MetricPanel({ label, value, desc, icon }) {
  return (
    <div className="bg-[#0e1017] p-6 rounded-2xl border border-white/5 flex items-center gap-5">
      <div className="p-3 bg-white/5 rounded-xl border border-white/5">{icon}</div>
      <div>
        <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">{label}</p>
        <p className="text-2xl font-black text-white mt-1">{value}</p>
        <p className="text-[10px] text-slate-400 font-medium mt-0.5">{desc}</p>
      </div>
    </div>
  );
}
