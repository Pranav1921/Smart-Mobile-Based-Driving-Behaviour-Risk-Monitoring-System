import { X, User, Gauge, BarChart, Package, MapPin, DollarSign, Phone } from 'lucide-react';
import { motion } from 'framer-motion';

const CockpitSidebar = ({ driver, onClose }) => {
  if (!driver) return null;

  return (
    <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} 
      className="absolute right-0 top-0 h-full w-[450px] z-[1000] p-6">
      <div className="glass-panel h-full w-full p-10 flex flex-col relative overflow-hidden">
        <button onClick={onClose} className="absolute top-8 right-8 p-3 hover:bg-slate-200 rounded-full text-slate-900"><X size={32}/></button>
        
        <div className="flex-1 overflow-y-auto scrollbar-hide space-y-10">
          <div className="flex flex-col items-center pt-8">
            <div className="w-28 h-28 bg-slate-200 rounded-full flex items-center justify-center mb-6 text-slate-900"><User size={50}/></div>
            <h2 className="text-4xl font-black text-slate-900">{driver.name}</h2>
            <p className="text-xl text-orange-600 font-black uppercase tracking-widest mt-2">{driver.status}</p>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <StatBox label="Speed" value={`${driver.speed} km/h`} />
            <StatBox label="Rating" value={`${driver.rating}/5`} />
          </div>

          <div className="space-y-4">
            <DetailRow label="Cargo" value={driver.item} />
            <DetailRow label="Destination" value={driver.destination} />
            <DetailRow label="Price" value={`₹${driver.price}`} />
            <DetailRow label="Phone" value={driver.phone} />
          </div>
        </div>

        <button className="w-full bg-slate-900 py-6 rounded-3xl font-black text-xl text-white mt-8 hover:bg-black">EMERGENCY DISPATCH</button>
      </div>
    </motion.div>
  );
};

const StatBox = ({ label, value }) => (
  <div className="bg-slate-100 p-8 rounded-3xl text-center border border-slate-200">
    <p className="text-sm uppercase opacity-50 font-black">{label}</p>
    <p className="font-black text-2xl mt-1 text-slate-900">{value}</p>
  </div>
);

const DetailRow = ({ label, value }) => (
  <div className="flex justify-between text-lg py-4 border-b border-slate-200">
    <span className="text-slate-500 font-bold">{label}</span>
    <span className="font-black text-slate-900">{value}</span>
  </div>
);

export default CockpitSidebar;