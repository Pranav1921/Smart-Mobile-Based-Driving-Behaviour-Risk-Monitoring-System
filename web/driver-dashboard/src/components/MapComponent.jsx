import { MapContainer, TileLayer, Marker } from 'react-leaflet';
import L from 'leaflet';

const MapComponent = ({ drivers, onSelectDriver }) => {
  const createIcon = (d) => L.divIcon({
    className: 'custom-marker',
    html: `
      <div class="flex flex-col items-center">
        <div class="marker-label mb-2">${d.speed} km/h</div>
        <div class="w-6 h-6 ${d.status === 'speeding' ? 'bg-red-500' : d.status === 'idle' ? 'bg-slate-400' : 'bg-green-500'} rounded-full border-4 border-white shadow-lg"></div>
      </div>`,
    iconSize: [40, 40], iconAnchor: [20, 20]
  });

  return (
    <MapContainer center={[12.97, 77.59]} zoom={13} className="h-screen w-full">
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      {drivers.map(d => (
        <Marker key={d.id} position={d.pos} icon={createIcon(d)} eventHandlers={{ click: () => onSelectDriver(d) }} />
      ))}
    </MapContainer>
  );
};
export default MapComponent;