import React, { useState, useEffect } from "react";
import { MapContainer, TileLayer, Polyline, Marker, Popup, useMap } from "react-leaflet";
import { Calendar, Clock, Navigation, Flag, Award, Eye } from "lucide-react";
import apiClient from "../api/apiClient";

function MapBoundsRecenter({ points }) {
  const map = useMap();
  useEffect(() => {
    if (points && points.length > 0) {
      const bounds = points.map(p => [p[0], p[1]]);
      map.fitBounds(bounds, { padding: [30, 30] });
    }
  }, [points, map]);
  return null;
}

export default function TripsPage() {
  const [trips, setTrips] = useState([]);
  const [selectedTrip, setSelectedTrip] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchTrips();
  }, []);

  const fetchTrips = async () => {
    setLoading(true);
    try {
      const response = await apiClient.get("/trips");
      const list = response.data.data || [];
      setTrips(list);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Convert points for mapping helper
  const getMapPoints = (trip) => {
    if (!trip) return [];
    if (trip.tripPoints && trip.tripPoints.length > 0) {
      return trip.tripPoints.map(p => [p.latitude, p.longitude]);
    }
    // Fallback Mock Coordinates if database holds no coordinates yet
    return [
      [12.9716, 77.5946],
      [12.9752, 77.6045],
      [12.9821, 77.6112],
      [12.9912, 77.6256]
    ];
  };

  const activePoints = getMapPoints(selectedTrip);

  return (
    <div className="flex-1 flex bg-[#0c0d12] overflow-hidden">
      {/* Left panel: List of Trips */}
      <div className="w-[420px] h-full border-r border-white/5 bg-[#0e1017]/50 flex flex-col flex-shrink-0">
        <div className="p-6 border-b border-white/5">
          <h1 className="text-xl font-black text-white">Trips & Telematics Logs</h1>
          <p className="text-slate-400 text-xs mt-1 uppercase font-bold tracking-wider">Historical routes & safety telemetry</p>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {trips.map((t) => {
            const dateStr = new Date(t.startTime).toLocaleDateString();
            const durationMin = Math.round(t.duration / 60);
            return (
              <div 
                key={t.id}
                onClick={() => setSelectedTrip(t)}
                className={`p-5 rounded-3xl border transition-all cursor-pointer ${
                  selectedTrip?.id === t.id 
                    ? "bg-orange-500/10 border-orange-500/40 shadow-lg" 
                    : "bg-white/2 border-white/5 hover:border-white/12"
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="font-bold text-white text-sm">
                      {t.driver?.user?.firstName || 'David'} {t.driver?.user?.lastName || 'Driver'}
                    </h3>
                    <p className="text-xs text-slate-500 mt-1 uppercase font-bold tracking-wider">
                      {t.vehicle?.make} {t.vehicle?.model}
                    </p>
                  </div>
                  <span className="text-[10px] text-orange-400 font-black px-2 py-0.5 rounded bg-orange-500/10 border border-orange-500/20">
                    {t.status}
                  </span>
                </div>

                <div className="mt-5 grid grid-cols-3 gap-2 border-t border-white/5 pt-4">
                  <div className="text-center">
                    <p className="text-[9px] text-slate-500 font-bold uppercase tracking-wider">Distance</p>
                    <p className="text-xs font-black text-white mt-0.5">{t.distance.toFixed(1)} km</p>
                  </div>
                  <div className="text-center">
                    <p className="text-[9px] text-slate-500 font-bold uppercase tracking-wider">Duration</p>
                    <p className="text-xs font-black text-white mt-0.5">{durationMin} min</p>
                  </div>
                  <div className="text-center">
                    <p className="text-[9px] text-slate-500 font-bold uppercase tracking-wider">Safety</p>
                    <p className="text-xs font-black text-orange-500 mt-0.5">{t.driver?.safetyScore || 95}%</p>
                  </div>
                </div>
              </div>
            );
          })}
          {trips.length === 0 && (
            <div className="p-12 text-center text-slate-500 text-sm">
              No historical trips recorded.
            </div>
          )}
        </div>
      </div>

      {/* Right panel: Route Map visualization */}
      <div className="flex-1 h-full relative z-0">
        {selectedTrip ? (
          <>
            <MapContainer 
              center={[12.9716, 77.5946]} 
              zoom={13} 
              zoomControl={false}
              className="h-full w-full"
            >
              <TileLayer
                url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              />
              {activePoints.length > 0 && (
                <>
                  <Polyline positions={activePoints} color="#f97316" weight={4.5} opacity={0.85} />
                  
                  {/* Start Point */}
                  <Marker position={activePoints[0]}>
                    <Popup><div className="font-sans text-xs font-bold">Start Location</div></Popup>
                  </Marker>
                  
                  {/* End Point */}
                  <Marker position={activePoints[activePoints.length - 1]}>
                    <Popup><div className="font-sans text-xs font-bold">Destination</div></Popup>
                  </Marker>

                  <MapBoundsRecenter points={activePoints} />
                </>
              )}
            </MapContainer>

            {/* Quick Trip HUD widget overlay */}
            <div className="absolute top-5 right-5 z-[500] glass-panel p-6 rounded-3xl w-80">
              <h3 className="text-xs uppercase font-black text-slate-400 tracking-wider mb-4">Route telemetry Overview</h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-slate-400">Peak Velocity</span>
                  <span className="text-sm font-bold text-white">{selectedTrip.maxSpeed} km/h</span>
                </div>
                <div className="flex justify-between items-center py-2 border-b border-white/5">
                  <span className="text-xs text-slate-400">Avg Speed</span>
                  <span className="text-sm font-bold text-white">{selectedTrip.avgSpeed.toFixed(1)} km/h</span>
                </div>
                <div className="flex justify-between items-center py-2">
                  <span className="text-xs text-slate-400">Trip ID</span>
                  <span className="text-xs font-bold text-slate-400">{selectedTrip.id}</span>
                </div>
              </div>
            </div>
          </>
        ) : (
          <div className="h-full w-full flex flex-col items-center justify-center text-slate-500 bg-[#0f111a]">
            <Eye className="w-12 h-12 text-slate-700 animate-pulse mb-4" />
            <p className="text-sm font-bold">Select an operational trip to project route details on the map HUD</p>
          </div>
        )}
      </div>
    </div>
  );
}