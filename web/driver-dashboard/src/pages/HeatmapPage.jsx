import React from "react";
import { MapContainer, TileLayer, Circle } from "react-leaflet";
import { ShieldAlert, Info, MapPin } from "lucide-react";

export default function HeatmapPage() {
  // Hardcoded locations representing critical safety event clusters (harsh braking, overspeeding)
  const hotspots = [
    { id: 1, pos: [12.9716, 77.5946], intensity: 80, radius: 180, desc: "MG Road Junction - Harsh Braking Cluster" },
    { id: 2, pos: [12.9820, 77.5890], intensity: 95, radius: 240, desc: "Indiranagar Ring Road - Overspeeding Hotspot" },
    { id: 3, pos: [12.9550, 77.6010], intensity: 60, radius: 150, desc: "Koramangala 80ft Road - Sharp Turn Cluster" },
  ];

  return (
    <div className="flex-1 flex overflow-hidden bg-[#07080d] font-sans">
      
      {/* Sidebar detail list */}
      <div className="w-96 border-r border-white/5 h-full flex flex-col flex-shrink-0 bg-[#0e1017] overflow-hidden">
        <div className="p-6 border-b border-white/5">
          <h1 className="text-lg font-black text-white tracking-wide uppercase">RISK HOTSPOTS</h1>
          <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mt-1">Spatial safety distribution analysis</p>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          <div className="p-4 bg-orange-500/5 border border-orange-500/10 rounded-2xl flex gap-3 text-orange-400 text-xs">
            <Info className="w-5 h-5 flex-shrink-0 mt-0.5" />
            <p className="font-semibold leading-relaxed">Map visualizes cumulative telemetry violations grouped spatially. Higher radius indicates high repeat offense clusters.</p>
          </div>

          <div className="space-y-3">
            <p className="text-[9px] font-black text-slate-500 uppercase tracking-widest">Active Violation Nodes</p>
            {hotspots.map(h => (
              <div key={h.id} className="p-4 bg-[#07080d] border border-white/5 rounded-2xl flex gap-3.5 items-start">
                <MapPin className="w-5 h-5 text-red-500 mt-0.5 flex-shrink-0" />
                <div>
                  <h4 className="font-bold text-xs text-white uppercase tracking-wide">{h.desc.split(" - ")[0]}</h4>
                  <p className="text-[10px] text-slate-400 mt-1">{h.desc.split(" - ")[1]}</p>
                  <span className="inline-block mt-2 text-[9px] font-black tracking-widest text-red-400 uppercase bg-red-500/10 border border-red-500/20 px-2 py-0.5 rounded">
                    Risk Index: {h.intensity}%
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Fullscreen Map Panel */}
      <div className="flex-1 h-full relative">
        <MapContainer 
          center={[12.9716, 77.5946]} 
          zoom={13} 
          zoomControl={false}
          className="h-full w-full z-10"
        >
          <TileLayer
            attribution='&copy; OpenStreetMap contributors'
            url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          />
          {hotspots.map(h => (
            <Circle 
              key={h.id}
              center={h.pos}
              radius={h.radius}
              pathOptions={{
                color: '#ef4444',
                fillColor: '#ef4444',
                fillOpacity: h.intensity / 180, // opacity mapped to scale
                weight: 1.5
              }}
            />
          ))}
        </MapContainer>
      </div>
    </div>
  );
}
