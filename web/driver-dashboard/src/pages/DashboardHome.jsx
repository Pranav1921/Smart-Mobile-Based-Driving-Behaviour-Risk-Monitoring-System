import React, { useState, useEffect, useRef } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import { io } from "socket.io-client";
import {
  ChevronRight, Package, CheckCircle, XCircle, Truck,
  Radio, ShieldAlert, Users, Navigation, AlertCircle,
  MapPin, TrendingUp, Activity
} from "lucide-react";
import apiClient from "../api/apiClient";

function MapRecenter({ coords }) {
  const map = useMap();
  useEffect(() => {
    if (coords) map.setView(coords, 14, { animate: true });
  }, [coords, map]);
  return null;
}

function WebLocateControl() {
  const map = useMap();
  const [locating, setLocating] = useState(false);
  const [myLoc, setMyLoc] = useState(null);

  const handleLocate = (e) => {
    e.stopPropagation();
    setLocating(true);
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser");
      setLocating(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords = [pos.coords.latitude, pos.coords.longitude];
        setMyLoc(coords);
        map.flyTo(coords, 15, { duration: 1.5 });
        setLocating(false);
      },
      (err) => {
        alert("Could not access location: " + err.message);
        setLocating(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <>
      <div style={{ position: 'absolute', top: '12px', right: '12px', zIndex: 1000 }}>
        <button
          onClick={handleLocate}
          disabled={locating}
          title="Center to My Exact Location"
          className="bg-white hover:bg-emerald-50 text-emerald-600 border border-emerald-500 rounded-full p-2 shadow-lg flex items-center justify-center transition-all hover:scale-105 active:scale-95 cursor-pointer"
        >
          {locating ? (
            <div className="w-4 h-4 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
          ) : (
            <Navigation className="w-4 h-4 text-emerald-600" />
          )}
        </button>
      </div>
      {myLoc && (
        <Marker position={myLoc}>
          <Popup>
            <p className="font-bold text-xs text-emerald-700">📍 Your Exact Location</p>
          </Popup>
        </Marker>
      )}
    </>
  );
}

export default function DashboardHome({ user, onLogout }) {
  const [drivers, setDrivers] = useState([]);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [socketConnected, setSocketConnected] = useState(false);
  const [stats, setStats] = useState({
    activeDrivers: 0,
    averageSafety: 0,
    criticalIncidents: 0,
    totalDistance: 0,
  });
  const [alerts, setAlerts] = useState([]);

  // Job assignment state
  const [pendingJob, setPendingJob] = useState(null);
  const [activeDelivery, setActiveDelivery] = useState(null);
  const [jobToastMsg, setJobToastMsg] = useState(null);
  const socketRef = useRef(null);

  // Socket.io for real-time job assignment
  useEffect(() => {
    const token = localStorage.getItem("fg_admin_token");
    const host = window.location.hostname && window.location.hostname !== 'localhost' ? window.location.hostname : 'localhost';
    const socket = io(`http://${host}:3000`, {
      auth: { token },
      transports: ["websocket"],
    });
    socketRef.current = socket;
    socket.on("connect", () => {
      console.log("Driver Dashboard Connected to Socket");
      setSocketConnected(true);
    });
    socket.on("job_assigned", (job) => setPendingJob(job));
    socket.on("driver_location_update", (data) => {
      setDrivers((prev) => {
        const updated = [...prev];
        const idx = updated.findIndex((d) => d.id === data.driverId);
        if (idx >= 0) {
          updated[idx] = { ...updated[idx], user: { ...updated[idx].user, latitude: data.latitude, longitude: data.longitude }, status: data.status.toUpperCase() };
        } else {
          updated.push({
            id: data.driverId,
            status: data.status.toUpperCase(),
            licenseNumber: "LIVE-MOBILE",
            safetyScore: 98,
            user: { firstName: data.driverName, lastName: "", latitude: data.latitude, longitude: data.longitude }
          });
        }
        return updated;
      });
    });
    return () => socket.disconnect();
  }, [user]);

  const handleAcceptJob = () => {
    if (!pendingJob) return;
    socketRef.current?.emit("job_accepted", {
      orderId: pendingJob.orderId,
      driverName: user?.firstName
        ? `${user.firstName} ${user.lastName}`
        : user?.name || user?.email || "Driver",
    });
    setActiveDelivery(pendingJob);
    setPendingJob(null);
    setJobToastMsg("✅ Job accepted!");
    setTimeout(() => setJobToastMsg(null), 4000);
  };

  const handleRejectJob = () => {
    if (!pendingJob) return;
    socketRef.current?.emit("job_rejected", {
      orderId: pendingJob.orderId,
      reason: "Driver unavailable",
    });
    setPendingJob(null);
    setJobToastMsg("❌ Job declined.");
    setTimeout(() => setJobToastMsg(null), 3000);
  };

  const handleMarkDelivered = () => {
    setActiveDelivery(null);
    setJobToastMsg("🎉 Delivery complete!");
    setTimeout(() => setJobToastMsg(null), 4000);
  };

  // Polling
  useEffect(() => {
    fetchDashboardData();
    const iv = setInterval(fetchDashboardData, 5000);
    return () => clearInterval(iv);
  }, []);

  const fetchDashboardData = async () => {
    try {
      const res = await apiClient.get("/drivers");
      const allDrivers = res.data.data || [];
      const activeOnes = allDrivers.filter(
        (d) => d.status === "ACTIVE" || d.status === "ON_TRIP"
      );
      const alertsRes = await apiClient.get("/events?take=10");
      const fetchedAlerts = alertsRes.data.data || [];
      const avgSafety =
        allDrivers.length > 0
          ? Math.round(
              allDrivers.reduce((acc, d) => acc + (d.safetyScore || 100), 0) /
                allDrivers.length
            )
          : 0;
      setDrivers(allDrivers);
      setAlerts(fetchedAlerts);
      setStats({
        activeDrivers: activeOnes.length,
        averageSafety: avgSafety,
        criticalIncidents: fetchedAlerts.filter(
          (a) => a.severity === "HIGH" || a.severity === "CRITICAL"
        ).length,
        totalDistance: allDrivers.reduce(
          (acc, d) => acc + (d.totalDistance || 0),
          0
        ),
      });
    } catch (err) {
      console.error("Dashboard fetch error:", err);
    }
  };

  const greeting = () => {
    const h = new Date().getHours();
    if (h < 12) return "Good morning";
    if (h < 18) return "Good afternoon";
    return "Good evening";
  };

  const adminName =
    user?.firstName
      ? user.firstName
      : user?.name?.split(" ")[0] || user?.email?.split("@")[0] || "Admin";

  const now = new Date();
  const timeStr = now.toLocaleTimeString("en-IN", {
    hour: "2-digit",
    minute: "2-digit",
  });
  const dateStr = now.toLocaleDateString("en-IN", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });

  return (
    <div className="flex-1 overflow-y-auto bg-[#F5F0E8] font-sans">

      {/* ── Job Assigned Modal ── */}
      {pendingJob && (
        <div className="fixed inset-0 z-[9000] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="w-full max-w-md bg-white rounded-[28px] p-8 shadow-2xl border border-slate-200">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-3 bg-[#1B3B2B]/10 rounded-2xl">
                <Package className="w-6 h-6 text-[#1B3B2B]" />
              </div>
              <div>
                <h2 className="text-base font-black text-[#1B3B2B] uppercase tracking-wide">New Job Assigned</h2>
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-0.5">Incoming delivery order</p>
              </div>
              <span className="ml-auto flex h-2.5 w-2.5 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
              </span>
            </div>

            <div className="bg-[#F5F0E8] rounded-2xl p-4 mb-5 space-y-3">
              <div className="flex items-start gap-3">
                <div className="w-2 h-2 rounded-full bg-emerald-500 mt-1.5 shrink-0" />
                <div>
                  <p className="text-[9px] text-slate-400 font-black uppercase tracking-widest">Pickup From</p>
                  <p className="text-sm font-bold text-[#1B3B2B] mt-0.5">{pendingJob.deliveryFrom || "Main Dispatch Hub"}</p>
                </div>
              </div>
              <div className="ml-[3px] border-l-2 border-dashed border-slate-300 h-4" />
              <div className="flex items-start gap-3">
                <div className="w-2 h-2 rounded-full bg-[#1B3B2B] mt-1.5 shrink-0" />
                <div>
                  <p className="text-[9px] text-slate-400 font-black uppercase tracking-widest">Deliver To</p>
                  <p className="text-sm font-bold text-[#1B3B2B] mt-0.5">{pendingJob.deliveryTo || "Customer Address"}</p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 mb-6">
              <div className="bg-[#F5F0E8] rounded-xl p-3">
                <p className="text-[9px] text-slate-400 font-black uppercase tracking-widest mb-1">Items</p>
                <p className="text-xs font-semibold text-slate-700">
                  {Array.isArray(pendingJob.items) ? pendingJob.items.join(", ") : pendingJob.items || "Package"}
                </p>
              </div>
              <div className="bg-[#F5F0E8] rounded-xl p-3">
                <p className="text-[9px] text-slate-400 font-black uppercase tracking-widest mb-1">Amount</p>
                <p className="text-sm font-black text-[#1B3B2B]">₹{(pendingJob.amount || 0).toLocaleString("en-IN")}</p>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleRejectJob}
                className="flex-1 py-3 rounded-2xl border border-red-200 text-red-500 font-black text-sm uppercase tracking-widest hover:bg-red-50 transition-all cursor-pointer flex items-center justify-center gap-2"
              >
                <XCircle className="w-4 h-4" /> Decline
              </button>
              <button
                onClick={handleAcceptJob}
                className="flex-1 py-3 rounded-2xl bg-[#1B3B2B] hover:bg-[#243f30] text-white font-black text-sm uppercase tracking-widest transition-all cursor-pointer flex items-center justify-center gap-2"
              >
                <CheckCircle className="w-4 h-4" /> Accept
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Toast ── */}
      {jobToastMsg && (
        <div className="fixed top-4 right-4 z-[9999] bg-white border border-slate-200 text-slate-800 text-sm font-bold px-5 py-3.5 rounded-2xl shadow-xl flex items-center gap-3">
          {jobToastMsg}
        </div>
      )}

      {/* ── Active Delivery Chip ── */}
      {activeDelivery && (
        <div className="fixed bottom-6 right-6 z-[8000] w-72 bg-white border border-emerald-200 rounded-[20px] p-4 shadow-xl">
          <div className="flex items-center gap-2 mb-3">
            <Truck className="w-4 h-4 text-emerald-600" />
            <span className="text-[10px] text-emerald-600 font-black uppercase tracking-widest">Active Delivery</span>
            <span className="ml-auto flex h-2 w-2 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
            </span>
          </div>
          <p className="text-xs text-slate-500 mb-1 truncate">📍 {activeDelivery.deliveryFrom || "Dispatch Hub"}</p>
          <p className="text-xs text-slate-700 font-semibold truncate">→ {activeDelivery.deliveryTo || "Customer"}</p>
          <button
            onClick={handleMarkDelivered}
            className="mt-3 w-full py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs uppercase tracking-widest transition-all cursor-pointer"
          >
            Mark Delivered
          </button>
        </div>
      )}

      {/* ── Main Content ── */}
      <div className="p-8 max-w-7xl mx-auto space-y-6">

        {/* Page Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-black text-[#1B3B2B]">
              {greeting()}, {adminName || 'Commander'}.
            </h1>
            <p className="text-xs text-slate-500 mt-1 font-medium">
              {timeStr} · Real-time vehicle telemetry &amp; safety score intelligence.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full border text-[10px] font-bold uppercase tracking-wider ${socketConnected ? 'bg-emerald-50 text-emerald-600 border-emerald-200' : 'bg-rose-50 text-rose-600 border-rose-200'}`}>
              <div className={`h-1.5 w-1.5 rounded-full ${socketConnected ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'}`} />
              {socketConnected ? 'Socket Live' : 'Socket Offline'}
            </div>
            <button className="flex items-center gap-2 bg-[#1B3B2B] hover:bg-[#243f30] text-white text-[13px] font-semibold px-5 py-2.5 rounded-xl shadow-lg transition-all cursor-pointer">
              <Radio className="h-4 w-4" /> Open Live Map
            </button>
          </div>
        </div>

        {/* KPI Cards Row */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <KpiCard
            label="Active Vehicles"
            value={stats.activeDrivers}
            icon={<Users className="w-5 h-5 text-[#1B3B2B]" />}
          />
          <KpiCard
            label="Avg. Safety Score"
            value={stats.averageSafety > 0 ? `${stats.averageSafety}%` : "—"}
            icon={<ShieldAlert className="w-5 h-5 text-[#1B3B2B]" />}
          />
        </div>

        {/* Map + Chart Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {/* Vector Map Card */}
          <div className="bg-white rounded-[20px] border border-slate-200/80 p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-sm font-bold text-[#1B3B2B]">Vector Map</h3>
                <p className="text-xs text-slate-400 mt-0.5">Real-time vehicle map style</p>
              </div>
              <span className="text-[10px] font-bold px-2.5 py-1 rounded-full bg-slate-100 text-slate-600 border border-slate-200">Map</span>
            </div>
            <div className="h-56 rounded-2xl overflow-hidden border border-slate-200 relative">
              <MapContainer
                center={[12.7749, 75.2023]}
                zoom={12}
                zoomControl={false}
                className="h-full w-full z-10"
              >
                <TileLayer
                  attribution='&copy; Google Maps'
                  url="https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}"
                />
                <WebLocateControl />
                {drivers.map((d) => {
                  const lat = d.user?.latitude || 12.7272;
                  const lng = d.user?.longitude || 75.3207;
                  return (
                    <Marker
                      key={d.id}
                      position={[lat, lng]}
                      eventHandlers={{ click: () => setSelectedDriver(d) }}
                    >
                      <Popup>
                        <p className="font-bold text-sm">{d.user?.firstName} {d.user?.lastName}</p>
                        <p className="text-[10px] text-slate-500">{d.licenseNumber}</p>
                      </Popup>
                    </Marker>
                  );
                })}
                {selectedDriver && (
                  <MapRecenter
                    coords={[
                      selectedDriver.user?.latitude || 12.7272,
                      selectedDriver.user?.longitude || 75.3207,
                    ]}
                  />
                )}
              </MapContainer>
            </div>
          </div>

          {/* Safety Performance Chart */}
          <div className="bg-white rounded-[20px] border border-slate-200/80 p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-sm font-bold text-[#1B3B2B]">Safety Performance</h3>
                <p className="text-xs text-slate-400 mt-0.5">7-day fleet safety trend</p>
              </div>
              <span className="text-[10px] font-bold px-2.5 py-1 rounded-full bg-slate-100 text-slate-600 border border-slate-200">Chart</span>
            </div>
            <SafetyLineChart />
          </div>
        </div>

        {/* Bottom Row: Alerts + Drivers Online */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {/* Recent Alerts */}
          <div className="bg-white rounded-[20px] border border-slate-200/80 p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-[#1B3B2B]">Recent Alerts</h3>
              <span className="text-[10px] font-bold px-2.5 py-1 rounded-full bg-red-50 text-red-500 border border-red-100">
                {stats.criticalIncidents} Critical
              </span>
            </div>
            {alerts.length === 0 ? (
              <div className="h-32 flex flex-col items-center justify-center text-center gap-2">
                <ShieldAlert className="w-8 h-8 text-slate-200" />
                <p className="text-xs text-slate-400 font-semibold">No alerts detected</p>
                <p className="text-[10px] text-slate-300">All systems operational</p>
              </div>
            ) : (
              <div className="space-y-2 max-h-48 overflow-y-auto">
                {alerts.slice(0, 6).map((a, i) => {
                  const isCritical = a.severity === "HIGH" || a.severity === "CRITICAL";
                  return (
                    <div
                      key={i}
                      className={`flex items-start gap-3 p-3 rounded-xl border ${
                        isCritical
                          ? "bg-red-50 border-red-100 text-red-700"
                          : "bg-amber-50 border-amber-100 text-amber-700"
                      }`}
                    >
                      <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                      <div className="min-w-0">
                        <p className="text-xs font-bold uppercase tracking-wide truncate">
                          {(a.eventType || a.type || "Event").replace(/_/g, " ")}
                        </p>
                        <p className="text-[10px] mt-0.5 opacity-70">{a.severity} · {a.driverName || "Unknown Driver"}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Drivers Online */}
          <div className="bg-white rounded-[20px] border border-slate-200/80 p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-[#1B3B2B]">Drivers Online</h3>
              <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full border ${
                stats.activeDrivers > 0
                  ? "bg-emerald-50 text-emerald-600 border-emerald-100"
                  : "bg-slate-100 text-slate-400 border-slate-200"
              }`}>
                {stats.activeDrivers} active
              </span>
            </div>
            {drivers.filter((d) => d.status === "ACTIVE" || d.status === "ON_TRIP").length === 0 ? (
              <div className="h-32 flex flex-col items-center justify-center text-center gap-2">
                <Users className="w-8 h-8 text-slate-200" />
                <p className="text-xs text-slate-400 font-semibold">No drivers online</p>
                <p className="text-[10px] text-slate-300">Drivers appear here when they tap Go Live</p>
              </div>
            ) : (
              <div className="space-y-2 max-h-48 overflow-y-auto">
                {drivers
                  .filter((d) => d.status === "ACTIVE" || d.status === "ON_TRIP")
                  .slice(0, 5)
                  .map((d, idx) => (
                    <button
                      key={d.id}
                      onClick={() => setSelectedDriver(d)}
                      className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                        idx === 0
                          ? "bg-[#1B3B2B] border-[#1B3B2B] text-white"
                          : "bg-[#F5F0E8] border-slate-200 hover:bg-slate-100 text-slate-800"
                      }`}
                    >
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-black shrink-0 ${
                        idx === 0 ? "bg-white/20 text-white" : "bg-[#1B3B2B]/10 text-[#1B3B2B]"
                      }`}>
                        {(d.user?.firstName?.[0] || "D")}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className={`text-[13px] font-semibold truncate ${idx === 0 ? "text-white" : "text-slate-800"}`}>
                          {d.user?.firstName} {d.user?.lastName}
                        </p>
                        <p className={`text-[10px] truncate ${idx === 0 ? "text-white/70" : "text-slate-400"}`}>
                          {d.licenseNumber || "—"}
                        </p>
                      </div>
                      <span className={`text-[13px] font-bold tabular-nums shrink-0 ${
                        idx === 0 ? "text-white" : d.safetyScore >= 85 ? "text-emerald-600" : d.safetyScore >= 70 ? "text-amber-500" : "text-red-500"
                      }`}>
                        {d.safetyScore ?? "—"}
                      </span>
                    </button>
                  ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── KPI Card ─────────────────────────────────────────────────────────────────
function KpiCard({ label, value, icon }) {
  return (
    <div className="bg-white rounded-[20px] border border-slate-200/80 p-6 shadow-sm">
      <div className="flex items-center justify-between">
        <span className="text-sm font-bold text-slate-600">{label}</span>
        <button className="h-7 w-7 rounded-xl bg-slate-100/80 hover:bg-slate-200 grid place-items-center text-slate-500 transition cursor-pointer">
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
      <div className="mt-4 text-4xl font-extrabold text-[#1B3B2B] tracking-tight">
        {value === 0 || value === "0" ? "0" : value || "—"}
      </div>
    </div>
  );
}

// ── Safety Line Chart (SVG) ───────────────────────────────────────────────────
function SafetyLineChart() {
  const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const data1 = [0, 0, 0, 0, 0, 0, 0];
  const data2 = [0, 0, 0, 0, 0, 0, 0];

  const W = 400, H = 180, PAD = 24;
  const maxVal = 100;

  const toX = (i) => PAD + (i / (labels.length - 1)) * (W - PAD * 2);
  const toY = (v) => H - PAD - (v / maxVal) * (H - PAD * 2);

  const pathD = (series) =>
    series
      .map((v, i) => `${i === 0 ? "M" : "L"} ${toX(i)} ${toY(v)}`)
      .join(" ");

  const areaD = (series) =>
    `${pathD(series)} L ${toX(series.length - 1)} ${toY(0)} L ${toX(0)} ${toY(0)} Z`;

  return (
    <div className="relative">
      <div className="flex items-center gap-4 mb-3 text-[10px] font-bold text-slate-400">
        <span className="flex items-center gap-1.5">
          <span className="w-3 h-0.5 bg-blue-400 rounded inline-block" /> Mon-Sun
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-3 h-0.5 bg-amber-500 rounded inline-block" /> Data-Sun
        </span>
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full" style={{ height: 200 }}>
        <defs>
          <linearGradient id="grad1" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#60a5fa" stopOpacity="0.18" />
            <stop offset="100%" stopColor="#60a5fa" stopOpacity="0" />
          </linearGradient>
          <linearGradient id="grad2" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#d97706" stopOpacity="0.12" />
            <stop offset="100%" stopColor="#d97706" stopOpacity="0" />
          </linearGradient>
        </defs>

        {/* Y-axis guide lines */}
        {[20, 40, 60, 80, 100].map((v) => (
          <g key={v}>
            <line
              x1={PAD} y1={toY(v)}
              x2={W - PAD} y2={toY(v)}
              stroke="#e2e8f0" strokeWidth="1"
            />
            <text x={PAD - 6} y={toY(v) + 4} fontSize={9} fill="#94a3b8" textAnchor="end">{v}</text>
          </g>
        ))}

        {/* Area fills */}
        <path d={areaD(data1)} fill="url(#grad1)" />
        <path d={areaD(data2)} fill="url(#grad2)" />

        {/* Lines */}
        <path d={pathD(data1)} fill="none" stroke="#60a5fa" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        <path d={pathD(data2)} fill="none" stroke="#d97706" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

        {/* X axis labels */}
        {labels.map((l, i) => (
          <text
            key={l}
            x={toX(i)}
            y={H - 4}
            fontSize={9}
            fill="#94a3b8"
            textAnchor="middle"
          >
            {l}
          </text>
        ))}
      </svg>
      <p className="text-center text-[10px] text-slate-300 font-medium mt-1">
        No driving data yet — chart will populate as drivers go live
      </p>
    </div>
  );
}
