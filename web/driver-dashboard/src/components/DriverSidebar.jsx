import { X, User, Briefcase, Mail, Phone, Package, MapPin } from 'lucide-react';
import { motion } from 'framer-motion';

const DriverProfileSidebar = ({ driver, onClose }) => {
  if (!driver) return null;

  return (
    <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} 
      className="absolute right-0 top-0 h-full w-[400px] z-[1000] glass-panel p-8 overflow-y-auto">
      <button onClick={onClose} className="absolute top-8 right-8 p-2 hover:bg-white/10 rounded-full"><X size={20}/></button>
      
      <div className="flex flex-col items-center pt-8 mb-8">
        <div className="w-24 h-24 bg-white/10 rounded-full flex items-center justify-center mb-4"><User size={40} /></div>
        <h2 className="text-2xl font-black">{driver.name}</h2>
        <p className="text-xs uppercase tracking-widest opacity-60 mt-1">{driver.status} • {driver.experience}</p>
      </div>

      <div className="space-y-6">
        <Section title="Personal Profile">
          <Detail label="Phone" value={driver.phone} />
          <Detail label="Email" value={driver.email} />
          <Detail label="Rating" value={`${driver.rating} / 5.0`} />
        </Section>
        
        <Section title="Mission Intelligence">
          <Detail label="Package" value={driver.item} />
          <Detail label="Route" value={driver.destination} />
          <Detail label="Traffic %" value={`${driver.traffic}%`} />
          <Detail label="Value" value={`₹${driver.price}`} />
        </Section>
      </div>
    </motion.div>
  );
};

const Section = ({ title, children }) => <div className="border-t border-white/10 pt-4"><h3 className="text-[10px] font-black uppercase opacity-40 mb-3">{title}</h3>{children}</div>;
const Detail = ({ label, value }) => <div className="flex justify-between py-1"><span className="text-sm opacity-60">{label}</span><span className="font-bold text-sm">{value}</span></div>;

export default DriverProfileSidebar;