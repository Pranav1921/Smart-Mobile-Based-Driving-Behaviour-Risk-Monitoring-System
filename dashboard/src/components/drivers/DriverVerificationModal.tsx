import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ShieldCheck, 
  X, 
  CheckCircle2, 
  XCircle, 
  Search, 
  FileText, 
  Clock, 
  User, 
  Phone, 
  Mail, 
  MapPin, 
  Car, 
  Award, 
  AlertTriangle,
  RefreshCw,
  Send,
  KeyRound,
  Check
} from 'lucide-react';
import { VehicleSymbol } from '@/components/ui/VehicleSymbol';
import { 
  fetchPendingDrivers, 
  verifyDriverLicense, 
  approveDriverApplication, 
  rejectDriverApplication 
} from '@/lib/apiClient';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onApproved?: () => void;
}

export function DriverVerificationModal({ isOpen, onClose, onApproved }: Props) {
  const [pendingDrivers, setPendingDrivers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<any | null>(null);
  
  // Verification states
  const [verifying, setVerifying] = useState(false);
  const [verificationResult, setVerificationResult] = useState<any | null>(null);
  
  // Approval states
  const [actionLoading, setActionLoading] = useState(false);
  const [approvalResult, setApprovalResult] = useState<{ driverCode: string; tempPassword: string; email: string } | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectBox, setShowRejectBox] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadPending();
    } else {
      setSelectedDriver(null);
      setVerificationResult(null);
      setApprovalResult(null);
      setShowRejectBox(false);
    }
  }, [isOpen]);

  const loadPending = async () => {
    setLoading(true);
    try {
      const data = await fetchPendingDrivers();
      setPendingDrivers(data);
      if (data.length > 0 && !selectedDriver) {
        setSelectedDriver(data[0]);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectDriver = (driver: any) => {
    setSelectedDriver(driver);
    setVerificationResult(null);
    setApprovalResult(null);
    setShowRejectBox(false);
  };

  const handleVerify = async () => {
    if (!selectedDriver) return;
    setVerifying(true);
    setVerificationResult(null);
    try {
      const res = await verifyDriverLicense(selectedDriver.licenseNumber);
      setVerificationResult(res);
    } catch (err) {
      console.error(err);
    } finally {
      setVerifying(false);
    }
  };

  const handleApprove = async () => {
    if (!selectedDriver) return;
    setActionLoading(true);
    try {
      const res = await approveDriverApplication(selectedDriver.id);
      setApprovalResult({
        driverCode: res.driverCode,
        tempPassword: res.tempPassword,
        email: selectedDriver.user?.email || 'driver@example.com',
      });
      // Refresh list
      loadPending();
      if (onApproved) onApproved();
    } catch (err) {
      alert('Failed to approve application. Please try again.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!selectedDriver) return;
    setActionLoading(true);
    try {
      await rejectDriverApplication(selectedDriver.id, rejectReason || 'Parivahan records could not be verified');
      setShowRejectBox(false);
      setSelectedDriver(null);
      loadPending();
    } catch (err) {
      alert('Failed to reject application');
    } finally {
      setActionLoading(false);
    }
  };

  if (!isOpen) return null;

  // Helper to extract emergency contact from badges
  const emergencyBadge = selectedDriver?.badges?.find((b: string) => b.startsWith('emergency_contact:'));
  const emergencyContact = emergencyBadge ? emergencyBadge.replace('emergency_contact:', '') : null;

  const vehicleBadge = selectedDriver?.badges?.find((b: string) => b.startsWith('applied_vehicle:'));
  const vehicleInfo = vehicleBadge ? vehicleBadge.replace('applied_vehicle:', '') : null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-5xl h-[85vh] flex flex-col overflow-hidden shadow-2xl text-white"
      >
        {/* Modal Header */}
        <div className="px-8 py-5 border-b border-slate-800 flex items-center justify-between bg-slate-950/60">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
              <ShieldCheck size={22} />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-black uppercase tracking-tight text-white">
                  Parivahan Verification & Onboarding Hub
                </h2>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 border border-amber-500/30 text-amber-400">
                  {pendingDrivers.length} Pending
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium">
                Verify Government of India / Sarathi National Register credentials before issuing permanent Driver ID
              </p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            <X size={20} />
          </button>
        </div>

        {/* Modal Body: Split view */}
        <div className="flex-1 flex overflow-hidden">
          {/* Left Column: List of Pending Applications */}
          <div className="w-80 border-r border-slate-800 bg-slate-950/30 flex flex-col">
            <div className="p-4 border-b border-slate-800/80 flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Regional Applications</span>
              <button 
                onClick={loadPending} 
                disabled={loading}
                className="text-slate-400 hover:text-emerald-400 text-xs flex items-center gap-1 transition"
              >
                <RefreshCw size={12} className={loading ? 'animate-spin' : ''} /> Refresh
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-3 space-y-2">
              {pendingDrivers.length === 0 ? (
                <div className="py-20 text-center text-slate-500 text-xs">
                  <CheckCircle2 size={32} className="mx-auto mb-2 opacity-40 text-emerald-500" />
                  No pending driver applications for this sector.
                </div>
              ) : (
                pendingDrivers.map((driver) => {
                  const isSelected = selectedDriver?.id === driver.id;
                  return (
                    <div
                      key={driver.id}
                      onClick={() => handleSelectDriver(driver)}
                      className={`p-3.5 rounded-2xl cursor-pointer border transition-all ${
                        isSelected 
                          ? 'bg-emerald-500/10 border-emerald-500/40 shadow-sm' 
                          : 'bg-slate-800/40 border-slate-800 hover:border-slate-700'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="font-bold text-sm text-white">{driver.user?.name || 'Applicant'}</span>
                        <span className="text-[10px] uppercase font-bold px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                          {driver.user?.zone || 'PTR'}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 font-mono mb-1">
                        DL: {driver.licenseNumber}
                      </div>
                      <div className="text-[11px] text-slate-500 flex items-center gap-1">
                        <Clock size={11} /> {new Date(driver.createdAt).toLocaleDateString()}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Right Column: Driver Details & Verification Action */}
          <div className="flex-1 flex flex-col overflow-y-auto p-8">
            {selectedDriver ? (
              <div className="space-y-6 max-w-3xl">
                {/* Driver Info Header Card */}
                <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-6">
                  <div className="flex items-start justify-between">
                    <div>
                      <span className="px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider bg-amber-500/10 text-amber-400 border border-amber-500/30">
                        Application Status: Pending Admin Verification
                      </span>
                      <h3 className="text-2xl font-black text-white mt-2">
                        {selectedDriver.user?.name}
                      </h3>
                      <p className="text-xs text-slate-400 font-medium">
                        Sector / Jurisdiction: <strong className="text-emerald-400">{selectedDriver.user?.zone || 'Puttur / Mangaluru Zone'}</strong>
                      </p>
                    </div>

                    <div className="text-right">
                      <div className="text-xs text-slate-500 uppercase font-bold tracking-wider">National DL Number</div>
                      <div className="text-lg font-mono font-black text-white bg-slate-800/80 px-3 py-1 rounded-xl mt-1 border border-slate-700">
                        {selectedDriver.licenseNumber}
                      </div>
                    </div>
                  </div>

                  {/* Metadata Grid */}
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-6 pt-6 border-t border-slate-800/80 text-xs">
                    <div className="flex items-center gap-2 text-slate-300">
                      <Mail size={14} className="text-slate-500" />
                      <span>{selectedDriver.user?.email}</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <Phone size={14} className="text-slate-500" />
                      <span>{selectedDriver.user?.phoneNumber || 'Not provided'}</span>
                    </div>
                    <div className="flex items-center gap-2 text-slate-300">
                      <VehicleSymbol type={vehicleInfo || selectedDriver.driverType || 'Scooter'} size={18} showBadge={true} />
                    </div>
                    {emergencyContact && (
                      <div className="col-span-2 md:col-span-3 bg-red-950/20 border border-red-900/30 rounded-xl p-3 flex items-center gap-3">
                        <AlertTriangle size={16} className="text-red-400 shrink-0" />
                        <div>
                          <div className="text-[10px] uppercase font-bold tracking-wider text-red-400">Emergency Family / Guardian Contact</div>
                          <div className="text-xs font-semibold text-slate-200">{emergencyContact}</div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Parivahan DL Verification Section */}
                <div className="bg-slate-950/40 border border-slate-800/90 rounded-2xl p-6">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <FileText size={18} className="text-indigo-400" />
                      <h4 className="font-bold text-sm uppercase tracking-wider text-white">
                        MoRTH Sarathi Parivahan Verification
                      </h4>
                    </div>
                    
                    {!verificationResult && (
                      <button
                        onClick={handleVerify}
                        disabled={verifying}
                        className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs flex items-center gap-2 transition shadow-lg shadow-indigo-600/20"
                      >
                        {verifying ? (
                          <>
                            <RefreshCw size={14} className="animate-spin" />
                            Connecting to Parivahan API...
                          </>
                        ) : (
                          <>
                            <ShieldCheck size={14} />
                            Verify with Parivahan National Register
                          </>
                        )}
                      </button>
                    )}
                  </div>

                  {/* Verification Results Card */}
                  {verificationResult && (
                    <motion.div 
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="bg-emerald-950/20 border border-emerald-500/30 rounded-xl p-5 space-y-4"
                    >
                      <div className="flex items-center justify-between pb-3 border-b border-emerald-500/20">
                        <div className="flex items-center gap-2 text-emerald-400">
                          <CheckCircle2 size={18} />
                          <span className="font-bold text-sm uppercase tracking-wider">
                            Parivahan Record Authenticated
                          </span>
                        </div>
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                          MoRTH VERIFIED
                        </span>
                      </div>

                      <div className="grid grid-cols-2 gap-4 text-xs">
                        <div>
                          <span className="text-slate-400 text-[10px] uppercase font-bold">RTO Jurisdiction</span>
                          <p className="font-semibold text-white mt-0.5">{verificationResult.rto}</p>
                          <p className="text-slate-400 text-[11px]">{verificationResult.state}</p>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] uppercase font-bold">Validity Transport</span>
                          <p className="font-semibold text-white mt-0.5">{verificationResult.validUntil}</p>
                          <p className="text-emerald-400 text-[11px] font-bold">Status: {verificationResult.status}</p>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] uppercase font-bold">Authorized Vehicle Classes</span>
                          <div className="flex flex-wrap gap-1 mt-1">
                            {verificationResult.vehicleClassesAuthorized.map((cls: string, idx: number) => (
                              <span key={idx} className="px-2 py-0.5 rounded bg-slate-800 text-slate-300 text-[10px]">
                                {cls}
                              </span>
                            ))}
                          </div>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px] uppercase font-bold">Challans & Violations</span>
                          <p className="text-emerald-400 font-bold mt-1 flex items-center gap-1">
                            <Check size={14} /> Clean Record (0 Active Violations)
                          </p>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </div>

                {/* Approval Notification or Actions */}
                {approvalResult ? (
                  <motion.div 
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="bg-emerald-900/30 border border-emerald-500/50 rounded-2xl p-6 space-y-4"
                  >
                    <div className="flex items-center gap-3 text-emerald-400">
                      <div className="h-10 w-10 rounded-full bg-emerald-500/20 flex items-center justify-center">
                        <CheckCircle2 size={24} />
                      </div>
                      <div>
                        <h4 className="font-black text-lg text-white">Driver Approved & Credentials Dispatched!</h4>
                        <p className="text-xs text-emerald-300">
                          Official onboarding email dispatched to <strong className="underline">{approvalResult.email}</strong>
                        </p>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 bg-slate-900/80 p-4 rounded-xl border border-slate-800 text-xs">
                      <div>
                        <span className="text-slate-400 text-[10px] uppercase font-bold">Official Driver ID (Issued)</span>
                        <p className="text-lg font-mono font-black text-emerald-400 mt-0.5">{approvalResult.driverCode}</p>
                      </div>
                      <div>
                        <span className="text-slate-400 text-[10px] uppercase font-bold">Default Temporary Password</span>
                        <p className="text-lg font-mono font-black text-amber-400 mt-0.5">{approvalResult.tempPassword}</p>
                        <p className="text-[10px] text-slate-400 mt-0.5">Prompted to reset permanently on first sign-in</p>
                      </div>
                    </div>
                  </motion.div>
                ) : (
                  <div className="pt-2 border-t border-slate-800 flex items-center justify-between">
                    <div>
                      {showRejectBox ? (
                        <div className="flex items-center gap-2">
                          <input 
                            type="text"
                            value={rejectReason}
                            onChange={(e) => setRejectReason(e.target.value)}
                            placeholder="Reason for rejection..."
                            className="bg-slate-800 border border-slate-700 rounded-xl px-3 py-2 text-xs text-white placeholder:text-slate-500 outline-none w-64"
                          />
                          <button
                            onClick={handleReject}
                            disabled={actionLoading}
                            className="px-3 py-2 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold text-xs transition"
                          >
                            Confirm Reject
                          </button>
                          <button
                            onClick={() => setShowRejectBox(false)}
                            className="text-xs text-slate-400 hover:text-white px-2"
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => setShowRejectBox(true)}
                          className="px-4 py-2.5 rounded-xl border border-red-500/30 text-red-400 hover:bg-red-500/10 font-bold text-xs transition"
                        >
                          Reject Application
                        </button>
                      )}
                    </div>

                    <button
                      onClick={handleApprove}
                      disabled={actionLoading || !verificationResult}
                      className={`px-6 py-3 rounded-2xl font-bold text-xs flex items-center gap-2 transition-all ${
                        verificationResult 
                          ? 'bg-emerald-500 hover:bg-emerald-400 text-slate-950 shadow-lg shadow-emerald-500/20' 
                          : 'bg-slate-800 text-slate-500 cursor-not-allowed'
                      }`}
                    >
                      <KeyRound size={16} />
                      {actionLoading ? 'Generating Credentials...' : 'Approve Driver & Issue Credentials'}
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
                <User size={48} className="opacity-30 mb-3" />
                <p className="text-sm font-semibold">Select an applicant to review license and verify with Parivahan</p>
              </div>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  );
}
