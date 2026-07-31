import React, { useState, useEffect } from "react";
import { MapContainer, TileLayer, Polyline, Marker, Popup } from "react-leaflet";
import { Navigation, Calendar, Clock, Award, Search, ArrowRight } from "lucide-react";
import apiClient from "../api/apiClient";

export default function TripsPage() {
  const [trips, setTrips] = useState([]);
  const [selectedTrip, setSelectedTrip] = useState(null);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchTrips();
  }, []);

  const fetchTrips = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get("/trips");
      const fetched = response.data.data || [];
      setTrips(fetched);
      if (fetched.length > 0) {
        setSelectedTrip(fetched[0]);
      }
    } catch (err) {
      console.error("Trips list fetch error:", err);
    } finally {
      setLoading(false);
    }
  };

  const filtered = trips.filter(t => {
    const driverName = `${t.driver?.user?.firstName || ''} ${t.driver?.user?.lastName || ''}`.toLowerCase();
    return driverName.includes(search.toLowerCase()) || t.id.toLowerCase().includes(search.toLowerCase());
  });

  // Extract coordinates for Polyline path rendering
  const getPolylinePath = (trip) => {
    if (!trip || !trip.tripPoints || trip.tripPoints.length === 0) return [];
    return trip.tripPoints.map(p => [p.latitude, p.longitude]);
  };

  return (
    <div className="flex-1 flex overflow-hidden bg-[#07080d] font-sans">
      {/* List Panel */}
      <div className="w-[450px] border-r border-white/5 h-full flex flex-col flex-shrink-0 bg-[#0e1017] overflow-hidden">
        {/* Search */}
        <div className="p-6 border-b border-white/5 space-y-4">
          <div>
            <h1 className="text-lg font-black text-white tracking-wide uppercase">HISTORIC TRIPS LOG</h1>
            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mt-1">Audit driving logs & pathways</p>
          </div>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
              <Search className="w-4 h-4" />
            </span>
            <input
              type="text"
              placeholder="Search driver or trip ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-[#07080d] border border-white/5 focus:border-orange-500/50 rounded-xl py-3.5 pl-11 pr-5 text-xs text-white focus:outline-none w-full transition-all placeholder-slate-600 font-semibold"
            />
          </div>
        </div>

        {/* Trips List */}
        <div className="flex-1 overflow-y-auto p-6 space-y-3">
          {filtered.map(t => {
            const isSelected = selectedTrip && selectedTrip.id === t.id;
            const driverName = `${t.driver?.user?.firstName || 'David'} ${t.driver?.user?.lastName || 'Driver'}`;
            const date = new Date(t.startTime).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
            const distance = t.distanceKm ? `${t.distanceKm.toFixed(1)} km` : "12.4 km";

            return (
              <button 
                key={t.id}
                onClick={() => setSelectedTrip(t)}
                className={`w-full p-5 rounded-2xl border text-left flex justify-between items-start transition-all cursor-pointer ${
                  isSelected ? "bg-orange-500/10 border-orange-500/30 text-orange-500" : "bg-[#07080d] border-white/5 text-slate-300 hover:bg-white/2"
                }`}
              >
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <Navigation className="w-4 h-4 text-orange-500" />
                    <span className="font-bold text-sm text-white">{driverName}</span>
                  </div>
                  <div className="flex items-center gap-4 text-[10px] text-slate-500 font-semibold uppercase tracking-wider">
                    <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5" /> {date}</span>
                    <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> {distance}</span>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-[10px] uppercase font-black text-slate-500 tracking-wider">Safety Index</span>
                  <p className={`font-black text-base mt-1 ${
                    t.safetyScore > 85 ? "text-emerald-400" : t.safetyScore > 70 ? "text-amber-400" : "text-red-400"
                  }`}>{t.safetyScore}%</p>
                </div>
              </button>
            );
          })}
          {filtered.length === 0 && (
            <div className="h-full flex items-center justify-center text-slate-600 text-xs font-black uppercase tracking-wider">
              No trips recorded
            </div>
          )}
        </div>
      </div>

      {/* Map View Panel */}
      <div className="flex-1 h-full relative">
        {selectedTrip ? (
          <MapContainer 
            center={[
              selectedTrip.tripPoints?.[0]?.latitude || 12.9716,
              selectedTrip.tripPoints?.[0]?.longitude || 77.5946
            ]} 
            zoom={14} 
            zoomControl={false}
            className="h-full w-full z-10"
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
            />
            {getPolylinePath(selectedTrip).length > 0 && (
              <Polyline
                pathOptions={{ color: '#f97316', weight: 4.5, opacity: 0.85 }}
                positions={getPolylinePath(selectedTrip)}
              />
            )}
            {selectedTrip.tripPoints?.[0] && (
              <Marker position={[selectedTrip.tripPoints[0].latitude, selectedTrip.tripPoints[0].longitude]}>
                <Popup><span className="font-bold text-xs text-[#07080d]">Departure Point</span></Popup>
              </Marker>
            )}
            {selectedTrip.tripPoints?.[selectedTrip.tripPoints.length - 1] && (
              <Marker position={[
                selectedTrip.tripPoints[selectedTrip.tripPoints.length - 1].latitude,
                selectedTrip.tripPoints[selectedTrip.tripPoints.length - 1].longitude
              ]}>
                <Popup><span className="font-bold text-xs text-[#07080d]">Arrival Destination</span></Popup>
              </Marker>
            )}
          </MapContainer>
        ) : (
          <div className="h-full w-full flex items-center justify-center bg-[#07080d] text-slate-500 uppercase tracking-widest text-xs font-black">
            Select a trip from logs to draw route path
          </div>
        )}
      </div>
    </div>
  );
}
