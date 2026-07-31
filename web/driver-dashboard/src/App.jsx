import React, { useState, useEffect } from "react";
import { 
  Compass, Users, Navigation, ShieldAlert, FileText, 
  Map, LogOut, ChevronRight, Menu 
} from "lucide-react";
import LoginPage from "./pages/LoginPage";
import DashboardHome from "./pages/DashboardHome";
import DriversPage from "./pages/DriversPage";
import TripsPage from "./pages/TripsPage";
import EventsPage from "./pages/EventsPage";
import ReportsPage from "./pages/ReportsPage";
import HeatmapPage from "./pages/HeatmapPage";

export default function App() {
  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState("home");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is cached
    const token = localStorage.getItem("fg_admin_token");
    const cachedUser = localStorage.getItem("fg_admin_user");
    if (token && cachedUser) {
      setUser(JSON.parse(cachedUser));
    }
    setLoading(false);
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("fg_admin_token");
    localStorage.removeItem("fg_admin_refresh");
    localStorage.removeItem("fg_admin_user");
    setUser(null);
  };

  if (loading) {
    return (
      <div className="h-screen w-screen bg-[#f8fafc] flex items-center justify-center text-slate-500">
        <Compass className="w-12 h-12 text-[#135B50] animate-spin" />
      </div>
    );
  }

  // Render Login if unauthorized
  if (!user) {
    return <LoginPage onLoginSuccess={setUser} />;
  }

  return (
    <div className="h-screen w-screen flex bg-[#f8fafc] text-slate-900 overflow-hidden font-sans">
      {/* Sidebar Navigation */}
      <aside className="w-20 md:w-24 h-full border-r border-slate-200/60 bg-white flex flex-col items-center py-8 justify-between flex-shrink-0 z-[1000]">
        <div className="flex flex-col items-center gap-10 w-full">
          {/* Logo */}
          <div className="p-2 bg-[#135B50]/10 rounded-xl border border-[#135B50]/20">
            <Compass className="w-6 h-6 text-[#135B50]" />
          </div>

          {/* Nav Items */}
          <nav className="flex flex-col gap-6 w-full items-center">
            <SidebarBtn icon={<Map />} active={activeTab === "home"} onClick={() => setActiveTab("home")} title="Command Center" />
            <SidebarBtn icon={<Users />} active={activeTab === "drivers"} onClick={() => setActiveTab("drivers")} title="Operators" />
            <SidebarBtn icon={<Navigation />} active={activeTab === "trips"} onClick={() => setActiveTab("trips")} title="Trips Log" />
            <SidebarBtn icon={<ShieldAlert />} active={activeTab === "events"} onClick={() => setActiveTab("events")} title="Telemetry Warnings" />
            <SidebarBtn icon={<Map />} active={activeTab === "heatmap"} onClick={() => setActiveTab("heatmap")} title="Risk Heatmap" />
            <SidebarBtn icon={<FileText />} active={activeTab === "reports"} onClick={() => setActiveTab("reports")} title="Reports" />
          </nav>
        </div>

        {/* Logout */}
        <button 
          onClick={handleLogout}
          className="p-3 bg-red-500/5 hover:bg-red-500/15 rounded-xl border border-red-500/10 text-red-400 cursor-pointer transition-all"
          title="Exit Command Center"
        >
          <LogOut className="w-5 h-5" />
        </button>
      </aside>

      {/* Viewport content */}
      <main className="flex-1 h-full flex flex-col overflow-hidden relative">
        {activeTab === "home" && <DashboardHome user={user} onLogout={handleLogout} />}
        {activeTab === "drivers" && <DriversPage />}
        {activeTab === "trips" && <TripsPage />}
        {activeTab === "events" && <EventsPage />}
        {activeTab === "heatmap" && <HeatmapPage />}
        {activeTab === "reports" && <ReportsPage />}
      </main>
    </div>
  );
}

function SidebarBtn({ icon, active, onClick, title }) {
  return (
    <button 
      onClick={onClick}
      className={`p-3.5 rounded-2xl border transition-all cursor-pointer relative group ${
        active 
          ? "bg-[#135B50]/10 border-[#135B50]/30 text-[#135B50]" 
          : "bg-transparent border-transparent text-slate-400 hover:text-slate-600 hover:bg-slate-100/50"
      }`}
      title={title}
    >
      {React.cloneElement(icon, { className: "w-5 h-5" })}
      
      {/* Floating tooltip */}
      <span className="absolute left-24 top-1/2 -translate-y-1/2 bg-white border border-slate-200 text-slate-800 text-[10px] font-bold uppercase tracking-wider px-3 py-1.5 rounded-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-[2000] whitespace-nowrap font-sans">
        {title}
      </span>
    </button>
  );
}