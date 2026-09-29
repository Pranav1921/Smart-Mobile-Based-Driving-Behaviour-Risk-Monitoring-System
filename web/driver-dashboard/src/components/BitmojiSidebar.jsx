import { X, Phone, Mail, MapPin, Package, TriangleAlert as AlertTriangle, ShieldCheck, Gauge, User, Briefcase } from 'lucide-react';
import { motion } from 'framer-motion';

const DriverProfileSidebar = ({ driver, onClose }) => {
  if (!driver) return null;
  const isDanger = driver.status === 'speeding' || driver.status === 'emergency';

  return (
    <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} className="absolute right-0 top-0 h-full w-[450px] z-[1000] p-6">
      <div className="glass h-full w-full p-8 flex flex-col overflow-y-auto scrollbar-hide relative bg-white/90">
        <button onClick={onClose} className="absolute top-8 right-8 p-2 hover:bg-black/5 rounded-full"><X /></button>
        
        {/* Profile Header */}
        <div className="flex flex-col items-center pt-8 mb-8">
          <div className="w-32 h-32 rounded-3xl bg-slate-200 flex items-center justify-center mb-4 border-2 border-slate-300">
            <User size={64} className="text-slate-400" />
          </div>
          <h2 className="text-3xl font-black">{driver.name}</h2>
          <p className="text-slate-500 font-medium">{driver.gender} • {driver.age} Years</p>
        </div>

        {/* Persistent Emergency/Contact Bar */}
        <div className="flex gap-3 mb-8">
          <button className="flex-1 bg-black text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2">
            <Phone size={18}/> Call
          </button>
          {isDanger && (
            <button className="flex-1 bg-red-600 text-white py-4 rounded-2xl font-black animate-pulse flex items-center justify-center gap-2">
              <AlertTriangle size={18}/> EMERGENCY
            </button>
          )}
        </div>

        {/* Detailed Stats & History */}
        <div className="space-y-6">
          <InfoCard title="Operational Details">
            <Detail label="Current Speed" value={`${driver.speed} km/h`} />
            <Detail label="Route Traffic" value={`${driver.traffic}% Congestion`} />
            <Detail label="Driving Mode" value={driver.drivingMode} />
          </InfoCard>

          <InfoCard title="Delivery Mission">
            <Detail label="Package" value={driver.item} />
            <Detail label="Current Location" value={driver.currentLoc} />
            <Detail label="Destination" value={driver.destination} />
            <Detail label="Value" value={`₹${driver.price}`} />
          </InfoCard>

          <InfoCard title="Employee Profile">
            <Detail label="Email" value={driver.email} />
            <Detail label="Phone" value={driver.phone} />
            <Detail label="Experience" value={driver.experience} />
            <Detail label="Prev. Delivery" value={driver.prevDelivery} />
          </InfoCard>
        </div>
      </div>
    </motion.div>
  );
};

const InfoCard = ({ title, children }) => (
  <div className="bg-slate-50 p-6 rounded-3xl border border-slate-100">
    <h3 className="font-bold text-xs uppercase opacity-40 mb-4 tracking-widest">{title}</h3>
    {children}
  </div>
);

const Detail = ({ label, value }) => (
  <div className="flex justify-between py-2 border-b border-black/5 last:border-0">
    <span className="text-slate-500 text-sm">{label}</span>
    <span className="font-bold text-sm text-right">{value}</span>
  </div>
);

export default DriverProfileSidebar;