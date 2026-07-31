import React, { useState } from "react";
import { motion } from "framer-motion";
import { Shield, Lock, Mail, AlertTriangle } from "lucide-react";
import apiClient from "../api/apiClient";

export default function LoginPage({ onLoginSuccess }) {
  const [email, setEmail] = useState("admin@acmelogistics.com");
  const [password, setPassword] = useState("FleetGuard2026!");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please fill in all credentials.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const response = await apiClient.post("/auth/login", {
        email,
        password,
      });

      const data = response.data?.data;
      if (data && data.accessToken) {
        localStorage.setItem("fg_admin_token", data.accessToken);
        localStorage.setItem("fg_admin_refresh", data.refreshToken);
        localStorage.setItem("fg_admin_user", JSON.stringify(data.user));
        onLoginSuccess(data.user);
      } else {
        setError("Invalid server response schema.");
      }
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || "Authentication request failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen w-screen flex items-center justify-center bg-[#07080d] relative overflow-hidden font-sans">
      {/* Background radial glow */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-orange-600/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-orange-500/5 rounded-full blur-[120px] pointer-events-none" />

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-md p-10 bg-[#0e1017]/80 backdrop-blur-xl border border-white/5 rounded-[32px] shadow-2xl relative z-10"
      >
        <div className="flex flex-col items-center mb-8">
          <div className="p-4 bg-orange-500/10 rounded-2xl border border-orange-500/20 mb-4">
            <Shield className="w-8 h-8 text-orange-500" />
          </div>
          <h1 className="text-2xl font-black text-white uppercase tracking-wider">FleetGuard AI</h1>
          <p className="text-slate-500 text-[10px] tracking-widest font-black uppercase mt-1">Command Control Center</p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-2xl flex items-center gap-3 text-red-400 text-xs font-semibold">
            <AlertTriangle className="w-5 h-5 flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Email input */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest pl-1">Email address</label>
            <div className="flex items-center bg-[#12141d] border border-white/5 focus-within:border-orange-500/50 rounded-2xl p-4 transition-all">
              <Mail className="text-slate-500 w-5 h-5 mr-3 flex-shrink-0" />
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="bg-transparent outline-none w-full text-white text-sm"
                placeholder="admin@fleetguard.ai"
              />
            </div>
          </div>

          {/* Password input */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest pl-1">Security key</label>
            <div className="flex items-center bg-[#12141d] border border-white/5 focus-within:border-orange-500/50 rounded-2xl p-4 transition-all">
              <Lock className="text-slate-500 w-5 h-5 mr-3 flex-shrink-0" />
              <input 
                type="password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="bg-transparent outline-none w-full text-white text-sm"
                placeholder="••••••••••••"
              />
            </div>
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="w-full bg-orange-600 hover:bg-orange-700 text-white font-black py-4 rounded-3xl text-sm transition-all shadow-lg shadow-orange-600/10 cursor-pointer disabled:opacity-50 mt-8 uppercase tracking-widest"
          >
            {loading ? "Authenticating Session..." : "Secure Access"}
          </button>
        </form>
      </motion.div>
    </div>
  );
}
