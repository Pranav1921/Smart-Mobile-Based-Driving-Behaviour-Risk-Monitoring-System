import React, { useState, useEffect, useRef } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import { 
  Users, Navigation, ShieldAlert, Award, Compass, Gauge, 
  MapPin, AlertCircle, RefreshCw, LogOut, FileText, ChevronRight 
} from "lucide-react";
import apiClient from "../api/apiClient";

// Helper component to center map on selected driver
function MapRecenter({ coords }) {
  const map = useMap();
  useEffect(() => {
    if (coords) {
      map.setView(coords, 14, { animate: true });
    }
  }, [coords, map]);
  return null;
}

export default function DashboardHome({ user, onLogout }) {
  const [drivers, setDrivers] = useState([]);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [stats, setStats] = useState({
    activeDrivers: 0,
    averageSafety: 95.0,
    criticalIncidents: 0,
    totalDistance: 0
  });
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(false);

  // Poll intervals
  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchDashboardData = async () => {
    try {
      const response = await apiClient.get("/drivers");
      const fetchedDrivers = response.data.data || [];
      
      // Filter out only active driver records on shift
      const activeOnes = fetchedDrivers.filter(d => d.status === "ACTIVE" || d.status === "ON_TRIP");
      
      // Fetch active alerts/warnings
      const alertsResponse = await apiClient.get("/events?take=15");
      const fetchedAlerts = alertsResponse.data.data || [];

      // Calculate aggregated metrics
      const activeCount = activeOnes.length;
      const totalSafety = fetchedDrivers.reduce((acc, d) => acc + d.safetyScore, 0);
      const avgSafety = fetchedDrivers.length > 0 ? Math.round(totalSafety / fetchedDrivers.length) : 95.0;
      const criticalCount = fetchedAlerts.filter(a => a.severity === "HIGH" || a.severity === "CRITICAL").length;

      setDrivers(fetchedDrivers);
      setAlerts(fetchedAlerts);
      setStats({
        activeDrivers: activeCount,
        averageSafety: avgSafety,
        criticalIncidents: criticalCount,
        totalDistance: fetchedDrivers.length * 42.5 // mock scalar
      });
    } catch (err) {
      console.error("Dashboard statistics fetch error:", err);
    }
  };

  return (
    <div className="flex-1 flex overflow-hidden bg-[#07080d]">
      {/* Left section: Command stats panels & live Leaflet tracking map */}
      <div className="flex-1 flex flex-col overflow-hidden p-8 gap-6">
        
        {/* Top bar headers */}
        <div className="flex justify-between items-center flex-shrink-0">
          <div>
            <h1 className="text-xl font-black text-white tracking-wide uppercase">COMMAND CENTER HUD</h1>
            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mt-1">Acme Logistics Corp &bull; Real-time telematics</p>
          </div>
          <div className="flex items-center gap-3">
            <span className="flex h-2.5 w-2.5 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
            </span>
            <span className="text-[10px] text-slate-400 font-black tracking-widest uppercase">Telemetry Stream Active</span>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 flex-shrink-0">
          <StatBox label="Operators Active" value={stats.activeDrivers} icon={<Users className="text-orange-500 w-5 h-5" />} />
          <StatBox label="Fleet Safety Index" value={`${stats.averageSafety}%`} icon={<Award className="text-orange-500 w-5 h-5" />} />
          <StatBox label="Critical Warnings" value={stats.criticalIncidents} icon={<ShieldAlert className="text-orange-500 w-5 h-5" />} color={stats.criticalIncidents > 0 ? "text-red-400" : "text-white"} />
          <StatBox label="Distance Tracked" value={`${stats.totalDistance.toFixed(0)} mi`} icon={<Navigation className="text-orange-500 w-5 h-5" />} />
        </div>

        {/* Fullscreen Live Map container */}
        <div className="flex-1 rounded-[32px] border border-white/5 overflow-hidden relative shadow-inner min-h-[300px]">
          <MapContainer 
            center={[12.9716, 77.5946]} 
            zoom={13} 
            zoomControl={false}
            className="h-full w-full z-10"
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            />
            {drivers.map(d => {
              // Extract current position
              const lat = d.user?.latitude || 12.9716;
              const lng = d.user?.longitude || 77.5946;
              const isSelected = selectedDriver && selectedDriver.id === d.id;

              return (
                <Marker 
                  key={d.id} 
                  position={[lat, lng]}
                  eventHandlers={{
                    click: () => setSelectedDriver(d)
                  }}
                >
                  <Popup>
                    <div className="text-[#07080d] p-1">
                      <p className="font-black text-sm">{d.user?.firstName} {d.user?.lastName}</p>
                      <p className="text-[10px] text-slate-500 mt-0.5 uppercase tracking-wide">Vehicle: {d.licenseNumber}</p>
                    </div>
                  </Popup>
                </Marker>
              );
            })}
            {selectedDriver && (
              <MapRecenter coords={[selectedDriver.user?.latitude || 12.9716, selectedDriver.user?.longitude || 77.5946]} />
            )}
          </MapContainer>

          {/* Quick overlay selector */}
          <div className="absolute top-6 left-6 z-[500] max-h-48 overflow-y-auto bg-[#0e1017]/90 backdrop-blur-md border border-white/5 p-4 rounded-2xl w-60">
            <p className="text-[9px] font-black text-slate-500 uppercase tracking-widest mb-3">Live Fleet Roster</p>
            <div className="space-y-2">
              {drivers.map(d => (
                <button 
                  key={d.id}
                  onClick={() => setSelectedDriver(d)}
                  className={`w-full text-left p-2 rounded-xl flex justify-between items-center text-xs transition-all ${
                    selectedDriver?.id === d.id ? "bg-orange-500/10 border-orange-500/20 text-orange-500" : "hover:bg-white/5 border-transparent text-slate-300"
                  } border`}
                >
                  <span className="font-bold">{d.user?.firstName} {d.user?.lastName}</span>
                  <span className="font-black opacity-80">{d.safetyScore}%</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Right section: Cockpit visualizer & raw alerts stream */}
      <div className="w-96 border-l border-white/5 h-full flex flex-col flex-shrink-0 bg-[#0e1017] overflow-hidden">
        
        {/* Cockpit HUD Visualizer */}
        <div className="p-6 border-b border-white/5 flex-shrink-0">
          <p className="text-[10px] text-slate-500 font-black uppercase tracking-widest mb-4">Cockpit Telemetry HUD</p>
          <div className="h-52 bg-[#07080d] rounded-2xl border border-white/5 relative overflow-hidden flex items-center justify-center">
            <CanvasVisualizer speed={selectedDriver ? 65 : 0} gForce={selectedDriver ? 0.35 : 0} warning={selectedDriver?.safetyScore < 85} />
            
            {/* Speedometer Overlay */}
            <div className="absolute bottom-4 left-4 text-left">
              <span className="text-xs uppercase font-black text-slate-500 tracking-wider">Velocity</span>
              <p className="font-black text-lg text-white mt-0.5">{selectedDriver ? "65" : "0"} <span className="text-xs font-semibold text-slate-400">mph</span></p>
            </div>
          </div>
        </div>

        {/* Alerts stream ticker */}
        <div className="flex-1 flex flex-col overflow-hidden p-6 gap-4">
          <p className="text-[10px] text-slate-500 font-black uppercase tracking-widest flex-shrink-0">Real-time Warning Stream</p>
          
          <div className="flex-1 overflow-y-auto space-y-3 pr-1">
            {alerts.map((a, idx) => {
              const isDanger = a.severity === "HIGH" || a.severity === "CRITICAL";
              return (
                <div 
                  key={idx}
                  className={`p-4 rounded-2xl border flex gap-4 items-start ${
                    isDanger ? "bg-red-500/5 border-red-500/10 text-red-300" : "bg-orange-500/5 border-orange-500/10 text-orange-300"
                  }`}
                >
                  <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                  <div>
                    <h4 className="font-bold text-xs uppercase tracking-wide text-white">{a.eventType.replace("_", " ")}</h4>
                    <p className="text-[10px] text-slate-400 mt-1">Severity: {a.severity} &bull; Lat: {a.latitude.toFixed(4)}</p>
                  </div>
                </div>
              );
            })}
            {alerts.length === 0 && (
              <div className="h-full flex items-center justify-center text-slate-600 text-xs font-semibold uppercase tracking-wider">
                No alerts detected
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// 3D Canvas Wireframe car renderer
function CanvasVisualizer({ speed, gForce, warning }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    let animationId;
    let angle = 0;

    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      const cx = canvas.width / 2;
      const cy = canvas.height / 2;
      const size = 30;

      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(angle);

      // Define 3D wireframe car vertices
      const vertices = [
        {x: -1.2, y: -0.6, z: -0.4}, {x: 1.2, y: -0.6, z: -0.4},
        {x: 1.2, y: 0.6, z: -0.4},  {x: -1.2, y: 0.6, z: -0.4},
        {x: -1.2, y: -0.6, z: 0.4},  {x: 1.2, y: -0.6, z: 0.4},
        {x: 1.2, y: 0.6, z: 0.4},   {x: -1.2, y: 0.6, z: 0.4},
      ];

      // Project vertices to 2D using rotation perspective
      const projected = vertices.map(v => {
        const rad = 0.45;
        const cosY = Math.cos(rad);
        const sinY = Math.sin(rad);

        // Simple cabinet axonometric projection
        const rx = v.x * cosY - v.z * sinY;
        const rz = v.x * sinY + v.z * cosY;
        
        const scale = 50 / (50 + rz);
        return {
          x: rx * size * scale * 1.5,
          y: v.y * size * scale
        };
      });

      // Edge mappings
      const edges = [
        [0,1], [1,2], [2,3], [3,0],
        [4,5], [5,6], [6,7], [7,4],
        [0,4], [1,5], [2,6], [3,7]
      ];

      // Draw wireframe silhouette
      ctx.strokeStyle = warning ? "rgba(239, 68, 68, 0.4)" : "rgba(249, 115, 22, 0.35)";
      ctx.lineWidth = 1;
      edges.forEach(([u, v]) => {
        ctx.beginPath();
        ctx.moveTo(projected[u].x, projected[u].y);
        ctx.lineTo(projected[v].x, projected[v].y);
        ctx.stroke();
      });

      // Highlight wheels
      ctx.fillStyle = warning ? "#ef4444" : "#f97316";
      const wheels = [0, 1, 4, 5];
      wheels.forEach(i => {
        ctx.beginPath();
        ctx.arc(projected[i].x, projected[i].y, 3.5, 0, Math.PI * 2);
        ctx.fill();
      });

      ctx.restore();

      // Control rotation angle based on speed
      angle += 0.005 + (speed * 0.0003);
      animationId = requestAnimationFrame(render);
    };

    render();
    return () => cancelAnimationFrame(animationId);
  }, [speed, warning]);

  return <canvas ref={canvasRef} width={240} height={180} className="w-full h-full" />;
}

function StatBox({ label, value, icon, color = "text-white" }) {
  return (
    <div className="bg-[#0e1017] p-5 rounded-2xl border border-white/5 flex items-center justify-between shadow-sm">
      <div>
        <span className="text-[9px] uppercase font-black text-slate-500 tracking-wider">{label}</span>
        <p className={`text-xl font-black mt-1 ${color}`}>{value}</p>
      </div>
      <div className="p-3 bg-[#07080d] rounded-xl border border-white/5">{icon}</div>
    </div>
  );
}
