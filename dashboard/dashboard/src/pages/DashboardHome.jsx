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
      const list = response.data.data || [];
      
      // Add mock coordinates and metrics for visual representation if empty
      const mapped = list.map((d, index) => {
        // Only mock coordinates if the driver doesn't have live latitude/longitude from backend
        const hasLiveCoords = d.latitude !== undefined && d.longitude !== undefined;

        const offsetLat = (index % 2 === 0 ? 0.015 : -0.015) * (index + 1);
        const offsetLng = (index % 2 === 0 ? -0.022 : 0.022) * (index + 1);

        return {
          id: d.id,
          name: `${d.user?.firstName || 'Driver'} ${d.user?.lastName || ''}`,
          license: d.licenseNumber,
          status: d.status || "ACTIVE",
          safetyScore: d.safetyScore,
          riskScore: d.riskScore,
          speed: d.speed !== undefined ? d.speed : (d.status === "ON_TRIP" ? 45 + (index * 12) % 40 : 0),
          heading: (index * 45) % 360,
          lat: hasLiveCoords ? d.latitude : 12.9716 + offsetLat,
          lng: hasLiveCoords ? d.longitude : 77.5946 + offsetLng,
          vehicle: {
            make: "Tesla",
            model: "Model Y",
            plate: "FG-101-AI"
          }
        };
      });

      setDrivers(mapped);

      // Compute statistics
      const activeCount = mapped.filter(d => d.status === "ON_TRIP").length;
      const totalSafety = mapped.reduce((acc, d) => acc + d.safetyScore, 0);
      const avgSafety = mapped.length > 0 ? (totalSafety / mapped.length).toFixed(1) : 95.0;
      const critical = mapped.filter(d => d.riskScore > 20).length;

      setStats({
        activeDrivers: activeCount,
        averageSafety: parseFloat(avgSafety),
        criticalIncidents: critical,
        totalDistance: 142.8 + mapped.length * 15.5
      });

      // Maintain a list of alerts for UI warnings panel
      const generatedAlerts = [];
      mapped.forEach(d => {
        if (d.speed > 80) {
          generatedAlerts.push({
            id: `overspeed-${d.id}`,
            driver: d.name,
            type: "Overspeed",
            detail: `${d.speed} km/h in 80km/h zone`,
            severity: "HIGH",
            time: new Date().toLocaleTimeString()
          });
        }
        if (d.riskScore > 20) {
          generatedAlerts.push({
            id: `risk-${d.id}`,
            driver: d.name,
            type: "High Risk profile",
            detail: `Safety Score dipped to ${d.safetyScore}%`,
            severity: "MEDIUM",
            time: new Date().toLocaleTimeString()
          });
        }
      });
      setAlerts(generatedAlerts);

      // Keep reference to selected driver updated
      if (selectedDriver) {
        const updated = mapped.find(d => d.id === selectedDriver.id);
        if (updated) {
          setSelectedDriver(updated);
        }
      }
    } catch (err) {
      console.error("Dashboard poll failure:", err);
    }
  };

  return (
    <div className="h-screen w-screen flex flex-col bg-[#07080d] overflow-hidden text-slate-200">
      {/* Header bar */}
      <header className="h-20 w-full flex items-center justify-between px-8 border-b border-white/5 bg-[#12141d]/40 backdrop-blur-md relative z-[1000]">
        <div className="flex items-center gap-4">
          <div className="p-2.5 bg-orange-500/10 rounded-xl border border-orange-500/20">
            <Compass className="w-6 h-6 text-orange-500 animate-spin" style={{ animationDuration: '6s' }} />
          </div>
          <div>
            <h1 className="text-xl font-black text-white flex items-center gap-1.5">
              SmartDrive <span className="text-orange-500 font-extrabold">AI</span>
            </h1>
            <p className="text-xs text-slate-400 font-bold uppercase tracking-widest">ORGANIZATION COMMAND CENTER</p>
          </div>
        </div>

        {/* Global Statistics */}
        <div className="hidden lg:flex items-center gap-10">
          <HeaderStatIcon label="Active Fleet" value={stats.activeDrivers} sub="Moving vehicles" icon={<Navigation className="text-orange-500 w-5 h-5" />} />
          <HeaderStatIcon label="Avg Safety Score" value={`${stats.averageSafety}%`} sub="Fleet rating" icon={<Award className="text-emerald-500 w-5 h-5" />} />
          <HeaderStatIcon label="Unsafe Profiles" value={stats.criticalIncidents} sub="Needs intervention" icon={<ShieldAlert className="text-red-500 w-5 h-5" />} />
        </div>

        <div className="flex items-center gap-4">
          <button 
            onClick={fetchDashboardData}
            className="p-3 bg-white/5 border border-white/5 hover:bg-white/10 rounded-xl transition-colors cursor-pointer text-slate-300"
            title="Refresh Fleet Link"
          >
            <RefreshCw className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-3 pl-4 border-l border-white/10">
            <div className="text-right">
              <p className="text-sm font-bold text-white">{user?.firstName || 'System'} Manager</p>
              <p className="text-[10px] text-orange-500 uppercase font-black tracking-wider">ACME LOGISTICS</p>
            </div>
            <button 
              onClick={onLogout}
              className="p-3 bg-red-500/10 border border-red-500/20 hover:bg-red-500/20 rounded-xl text-red-400 transition-colors cursor-pointer"
              title="Leave command center"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Command Center Body */}
      <div className="flex-1 flex w-full relative overflow-hidden">
        {/* Left Side: Drivers list */}
        <div className="w-80 h-full border-r border-white/5 bg-[#0e1017]/80 flex flex-col flex-shrink-0 z-[500]">
          <div className="p-5 border-b border-white/5">
            <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider flex items-center gap-2">
              <Users className="w-4 h-4 text-orange-500" /> Active Operators ({drivers.length})
            </h2>
          </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {drivers.map(d => (
              <div 
                key={d.id}
                onClick={() => setSelectedDriver(d)}
                className={`p-4 rounded-2xl border transition-all cursor-pointer ${
                  selectedDriver?.id === d.id 
                    ? "bg-orange-500/10 border-orange-500/40 shadow-lg" 
                    : "bg-white/2 border-white/5 hover:border-white/15"
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="font-bold text-white text-sm">{d.name}</h3>
                    <p className="text-slate-400 text-xs mt-0.5">{d.vehicle?.make} {d.vehicle?.model}</p>
                  </div>
                  <div className={`px-2.5 py-0.5 rounded text-[10px] font-black tracking-wider ${
                    d.status === "ON_TRIP" 
                      ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 pulse-safe"
                      : "bg-slate-800 text-slate-400 border border-slate-700"
                  }`}>
                    {d.status}
                  </div>
                </div>

                <div className="mt-4 flex items-center justify-between border-t border-white/5 pt-3">
                  <div className="flex items-center gap-1 text-slate-400">
                    <Gauge className="w-3.5 h-3.5" />
                    <span className="text-xs font-bold">{(d.speed || 0).toFixed(1)} km/h</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="text-[10px] text-slate-500 font-bold">Safety Score:</span>
                    <span className={`text-xs font-black ${
                      d.safetyScore > 85 ? "text-emerald-400" : d.safetyScore > 70 ? "text-amber-400" : "text-red-400"
                    }`}>{d.safetyScore}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Center: Live Map view */}
        <div className="flex-1 h-full relative z-0">
          <MapContainer 
            center={[12.9716, 77.5946]} 
            zoom={12} 
            zoomControl={false}
            className="h-full w-full"
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
            />
            {drivers.map(d => (
              <Marker 
                key={d.id} 
                position={[d.lat, d.lng]}
                eventHandlers={{
                  click: () => setSelectedDriver(d)
                }}
              >
                <Popup>
                  <div className="p-1 font-sans">
                    <h3 className="font-bold text-sm text-white">{d.name}</h3>
                    <p className="text-xs text-slate-400 mt-1">{d.vehicle.make} {d.vehicle.model} ({d.vehicle.plate})</p>
                    <div className="flex items-center gap-2 mt-2 pt-2 border-t border-white/5 justify-between">
                      <span className="text-[10px] font-bold uppercase text-slate-500">Speed: {(d.speed || 0).toFixed(1)} km/h</span>
                      <span className="text-[10px] font-bold text-emerald-400">Score: {d.safetyScore}</span>
                    </div>
                  </div>
                </Popup>
              </Marker>
            ))}

            {selectedDriver && <MapRecenter coords={[selectedDriver.lat, selectedDriver.lng]} />}
          </MapContainer>

          {/* Map Overlay bottom warnings block */}
          {alerts.length > 0 && (
            <div className="absolute bottom-5 left-5 right-5 z-[500] pointer-events-none">
              <div className="max-w-xl mx-auto pointer-events-auto">
                <div className="glass-panel alert-pulse-critical rounded-3xl p-5 shadow-2xl flex items-center justify-between border border-red-500/30">
                  <div className="flex items-center gap-4">
                    <div className="p-2 bg-red-500/20 text-red-500 rounded-xl">
                      <AlertCircle className="w-6 h-6 animate-bounce" />
                    </div>
                    <div>
                      <h4 className="font-black text-white text-sm">Critical Telemetry Warning</h4>
                      <p className="text-xs text-red-300 mt-0.5">
                        Driver {alerts[0].driver} triggered alert: {alerts[0].type} ({alerts[0].detail})
                      </p>
                    </div>
                  </div>
                  <span className="text-[10px] text-red-400 font-bold bg-red-500/10 px-3 py-1 rounded-full border border-red-500/20 uppercase tracking-widest">
                    Live Incident
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Right Side Panel: Cockpit HUD / 3D Visualizer */}
        {selectedDriver && (
          <div className="w-96 h-full border-l border-white/5 bg-[#0e1017]/90 flex flex-col flex-shrink-0 z-[500]">
            <div className="p-5 border-b border-white/5 flex items-center justify-between">
              <h2 className="text-xs uppercase font-black text-slate-400 tracking-wider">
                VEHICLE COCKPIT TELEMETRY
              </h2>
              <button 
                onClick={() => setSelectedDriver(null)}
                className="text-xs hover:text-white text-slate-500 font-bold border border-white/5 rounded-lg px-2 py-1"
              >
                Close HUD
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* 3D Wireframe Canvas Visualizer */}
              <div className="glass-panel p-4 rounded-3xl border border-white/5 overflow-hidden">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[10px] uppercase font-black text-slate-400">Tesla Model Y HUD</span>
                  <span className="text-[10px] text-emerald-400 font-bold tracking-widest flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" /> DIAGNOSTICS ACTIVE
                  </span>
                </div>
                
                {/* 3D Wireframe Vehicle Rendering */}
                <Vehicle3DVisualizer speed={selectedDriver.speed} riskScore={selectedDriver.riskScore} />
              </div>

              {/* Driver identity */}
              <div className="space-y-4">
                <div className="flex justify-between items-center py-3 border-b border-white/5">
                  <span className="text-xs font-bold text-slate-400">Driver Name</span>
                  <span className="text-sm font-black text-white">{selectedDriver.name}</span>
                </div>
                <div className="flex justify-between items-center py-3 border-b border-white/5">
                  <span className="text-xs font-bold text-slate-400">License ID</span>
                  <span className="text-sm font-bold text-slate-300">{selectedDriver.license}</span>
                </div>
                <div className="flex justify-between items-center py-3 border-b border-white/5">
                  <span className="text-xs font-bold text-slate-400">Active Vehicle</span>
                  <span className="text-sm font-bold text-slate-300">
                    {selectedDriver.vehicle.make} {selectedDriver.vehicle.model} ({selectedDriver.vehicle.plate})
                  </span>
                </div>
                <div className="flex justify-between items-center py-3 border-b border-white/5">
                  <span className="text-xs font-bold text-slate-400">Current Speed</span>
                  <span className="text-sm font-black text-orange-500">{(selectedDriver.speed || 0).toFixed(1)} km/h</span>
                </div>
              </div>

              {/* Score telemetry dials */}
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div className="glass-panel-light p-5 rounded-2xl border border-white/5 text-center">
                  <p className="text-[10px] uppercase font-black text-slate-500">Safety Index</p>
                  <p className={`text-3xl font-black mt-2 ${
                    selectedDriver.safetyScore > 85 ? "text-emerald-400" : "text-amber-400"
                  }`}>{selectedDriver.safetyScore}%</p>
                </div>
                <div className="glass-panel-light p-5 rounded-2xl border border-white/5 text-center">
                  <p className="text-[10px] uppercase font-black text-slate-500">Risk Profile</p>
                  <p className={`text-3xl font-black mt-2 ${
                    selectedDriver.riskScore > 20 ? "text-red-400" : "text-slate-400"
                  }`}>{selectedDriver.riskScore}%</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// 3D Canvas Projection Component
function Vehicle3DVisualizer({ speed, riskScore }) {
  const canvasRef = useRef(null);
  const angleRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    let animationId;

    // Define 3D wireframe coordinates for a Tesla Model Y box-silhouette
    // Center at (0, 0, 0)
    const vertices = [
      // Chassis box
      { x: -2.5, y: -0.6, z: -1.2 }, // 0
      { x: 2.5, y: -0.6, z: -1.2 },  // 1
      { x: 2.5, y: -0.6, z: 1.2 },   // 2
      { x: -2.5, y: -0.6, z: 1.2 },  // 3
      { x: -2.5, y: 0.1, z: -1.2 },  // 4
      { x: 2.5, y: 0.1, z: -1.2 },   // 5
      { x: 2.5, y: 0.1, z: 1.2 },    // 6
      { x: -2.5, y: 0.1, z: 1.2 },   // 7

      // Roof cabin box
      { x: -0.8, y: 0.1, z: -1.0 },  // 8
      { x: 0.8, y: 0.1, z: -1.0 },   // 9
      { x: 0.8, y: 0.1, z: 1.0 },    // 10
      { x: -0.8, y: 0.1, z: 1.0 },   // 11
      { x: -0.6, y: 0.9, z: -0.9 },  // 12
      { x: 0.5, y: 0.9, z: -0.9 },   // 13
      { x: 0.5, y: 0.9, z: 0.9 },    // 14
      { x: -0.6, y: 0.9, z: 0.9 }    // 15
    ];

    // Connect vertices by drawing lines
    const lines = [
      // Chassis lower loop
      [0, 1], [1, 2], [2, 3], [3, 0],
      // Chassis upper loop
      [4, 5], [5, 6], [6, 7], [7, 4],
      // Chassis pillars
      [0, 4], [1, 5], [2, 6], [3, 7],
      // Cabin lower loop (connected to chassis)
      [8, 9], [9, 10], [10, 11], [11, 8],
      // Cabin upper loop
      [12, 13], [13, 14], [14, 15], [15, 12],
      // Cabin pillars
      [8, 12], [9, 13], [10, 14], [11, 15]
    ];

    const draw = () => {
      // Clear canvas with deep space transparency
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Rotate geometry over Y axis based on speed multiplier
      const rotSpeed = 0.005 + (speed / 160) * 0.03;
      angleRef.current += rotSpeed;
      const cosA = Math.cos(angleRef.current);
      const sinA = Math.sin(angleRef.current);

      // Perspective projection constants
      const fov = 150;
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      
      const projected = [];

      // Rotate & project vertices
      vertices.forEach(v => {
        // Rotate around Y axis
        let x1 = v.x * cosA - v.z * sinA;
        let z1 = v.x * sinA + v.z * cosA;
        
        // Rotate slightly around X axis for tilt
        const cosX = Math.cos(0.3);
        const sinX = Math.sin(0.3);
        let y1 = v.y * cosX - z1 * sinX;
        let z2 = v.y * sinX + z1 * cosX;

        // Camera offset
        const camZ = 5.5;
        const screenX = (x1 * fov) / (z2 + camZ) + centerX;
        const screenY = (-y1 * fov) / (z2 + camZ) + centerY;

        projected.push({ x: screenX, y: screenY });
      });

      // Select line styling color based on risk profile
      ctx.lineWidth = 1.8;
      if (riskScore > 20) {
        ctx.strokeStyle = "rgba(239, 68, 68, 0.85)"; // Pulsing Red warning wireframe
      } else {
        ctx.strokeStyle = "rgba(249, 115, 22, 0.85)"; // Sleek Tesla Orange
      }

      // Draw wireframe grid lines
      lines.forEach(([start, end]) => {
        const p1 = projected[start];
        const p2 = projected[end];
        
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        ctx.stroke();
      });

      // Draw wireframe dots
      projected.forEach(p => {
        ctx.fillStyle = riskScore > 20 ? "rgba(239, 68, 68, 0.95)" : "rgba(255, 255, 255, 0.85)";
        ctx.beginPath();
        ctx.arc(p.x, p.y, 2.5, 0, 2 * Math.PI);
        ctx.fill();
      });

      animationId = requestAnimationFrame(draw);
    };

    draw();

    return () => cancelAnimationFrame(animationId);
  }, [speed, riskScore]);

  return (
    <canvas 
      ref={canvasRef} 
      width="340" 
      height="180" 
      className="bg-[#12141d]/50 rounded-2xl w-full border border-white/5 cursor-pointer hover:border-orange-500/20 transition-all"
    />
  );
}

function HeaderStatIcon({ label, value, sub, icon }) {
  return (
    <div className="flex items-center gap-3 border-r border-white/5 pr-8 last:border-0 last:pr-0">
      <div className="p-2 bg-white/5 rounded-xl border border-white/5">{icon}</div>
      <div>
        <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">{label}</p>
        <p className="text-sm font-black text-white">{value}</p>
        <p className="text-[9px] text-slate-400 font-medium">{sub}</p>
      </div>
    </div>
  );
}