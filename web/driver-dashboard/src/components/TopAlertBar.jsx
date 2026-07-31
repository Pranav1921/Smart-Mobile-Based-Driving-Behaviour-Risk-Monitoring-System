const TopAlertBar = ({ drivers, onFilter }) => {
  const emergencyCount = drivers.filter(d => d.status === 'emergency').length;
  const warningCount = drivers.filter(d => d.status === 'speeding').length;

  return (
    <div className="absolute top-6 right-6 z-[600] flex gap-4">
      <button onClick={() => onFilter('emergency')} className="bg-red-600 text-white px-6 py-3 rounded-2xl font-black shadow-2xl flex items-center gap-2">
        🔴 EMERGENCY ({emergencyCount})
      </button>
      <button onClick={() => onFilter('speeding')} className="bg-orange-500 text-white px-6 py-3 rounded-2xl font-black shadow-2xl flex items-center gap-2">
        ⚠️ WARNING ({warningCount})
      </button>
      <button onClick={() => onFilter('all')} className="bg-white text-black px-6 py-3 rounded-2xl font-black shadow-2xl">
        ALL
      </button>
    </div>
  );
};
export default TopAlertBar;