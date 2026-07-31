import React, { useState, useEffect } from "react";
import { MapContainer, TileLayer, Circle, Marker, Popup } from "react-leaflet";
import { AlertCircle, Flame, ShieldAlert } from "lucide-react";
import apiClient from "../api/apiClient";

export default function HeatmapPage() {
  const [events, setEvents] = useState([]);
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

  // Filter events that represent safety hazards
  const hotspots = events.map((e) => {
    let color = "#ef4444"; // red for critical/crash
    let radius = 250;
    
    if (e.eventType === "OVERSPEED") {
      color = "#f97316"; // orange
      radius = 180;
    } else if (e.eventType === "HARSH_BRAKING") {
      color = "#eab308"; // yellow
      radius = 120;
    }

    return {
      id: e.id,
      lat: e.latitude,
      lng: e.longitude,
      type: e.eventType,
      severity: e.severity,
      color,
      radius
    };
  });

  // Provide mock hotspots if database is empty so map looks populated initially
  const activeHotspots = hotspots.length > 0 ? hotspots : [
    { id: 1, lat: 12.9716, lng: 77.5946, type: "CRASH", severity: "CRITICAL", color: "#ef4444", radius: 250 },
    { id: 2, lat: 12.9352, lng: 77.6245, type: "OVERSPEED", severity: "HIGH", color: "#f97316", radius: 180 },
    { id: 3, lat: 12.9810, lng: 77.5790, type: "HARSH_BRAKING", severity: "MEDIUM", color: "#eab308", radius: 120 },
    { id: 4, lat: 12.9550, lng: 77.6420, type: "SHARP_TURN", severity: "MEDIUM", color: "#eab308", radius: 120 }
  ];

  return (
    <div className="flex-1 flex bg-[#0c0d12] overflow-hidden relative">
      {/* Full screen Map */}
      <div className="flex-1 h-full relative z-0">
        <MapContainer 
          center={[12.9716, 77.5946]} 
          zoom={12} 
          zoomControl={false}
          className="h-full w-full"
        >
          <TileLayer
            url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />
          {activeHotspots.map((h) => (
            <React.Fragment key={h.id}>
              {/* Highlight Circle */}
              <Circle
                center={[h.lat, h.lng]}
                pathOptions={{
                  fillColor: h.color,
                  color: h.color,
                  weight: 1,
                  opacity: 0.4,
                  fillOpacity: 0.15
                }}
                radius={h.radius}
              />
              {/* Core Pulse Marker */}
              <Circle
                center={[h.lat, h.lng]}
                pathOptions={{
                  fillColor: h.color,
                  color: h.color,
                  weight: 2,
                  opacity: 0.9,
                  fillOpacity: 0.6
                }}
                radius={15}
              />
            </React.Fragment>
          ))}
        </MapContainer>
      </div>

      {/* Float Widgets: Legend info panel */}
      <div className="absolute top-5 left-5 z-[500] glass-panel p-6 rounded-3xl w-72 space-y-4">
        <div>
          <h1 className="text-sm font-black text-white flex items-center gap-2">
            <Flame className="w-5 h-5 text-orange-500 animate-pulse" /> Risk Hotspots map
          </h1>
          <p className="text-slate-500 text-[10px] uppercase font-bold mt-0.5 tracking-wider">Overspeed & braking concentrations</p>
        </div>

        <div className="space-y-3 pt-2 border-t border-white/5 text-xs">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-slate-300">
              <span className="w-3 h-3 rounded-full bg-red-500" />
              <span>Crash Event Zones</span>
            </div>
            <span className="text-slate-500 font-bold">250m Radius</span>
          </div>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-slate-300">
              <span className="w-3 h-3 rounded-full bg-orange-500" />
              <span>Overspeed Concentrations</span>
            </div>
            <span className="text-slate-500 font-bold">180m Radius</span>
          </div>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-slate-300">
              <span className="w-3 h-3 rounded-full bg-yellow-500" />
              <span>Harsh Braking Incidents</span>
            </div>
            <span className="text-slate-500 font-bold">120m Radius</span>
          </div>
        </div>
      </div>
    </div>
  );
}