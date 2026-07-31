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

      const { user, accessToken, refreshToken } = response.data.data;
      
      if (user.role === "DRIVER") {
        setError("Access Denied: Drivers must authenticate through the mobile application.");
        setLoading(false);
        return;
      }

      // Cache admin details
      localStorage.setItem("fg_admin_token", accessToken);
      localStorage.setItem("fg_admin_refresh", refreshToken);
      localStorage.setItem("fg_admin_user", JSON.stringify(user));

      onLoginSuccess(user);
    } catch (err) {
      console.error(err);
      setError(
        err.response?.data?.message || 
        "Authentication failed. Please verify network connections."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-screen flex items-center justify-center bg-[#07080d] relative overflow-hidden px-4">
      {/* Background Decorative Accents */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[60%] rounded-full bg-orange-600/10 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[60%] rounded-full bg-pink-600/10 blur-[120px] pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="glass-panel max-w-md w-full p-10 rounded-3xl shadow-2xl relative z-10"
      >
        <div className="flex flex-col items-center mb-8">
          <div className="p-4 bg-orange-500/10 rounded-2xl border border-orange-500/30 mb-4">
            <Shield className="w-10 h-10 text-orange-500 animate-pulse" />
          </div>
          <h1 className="text-3xl font-black tracking-tight text-white">FleetGuard <span className="text-orange-500">AI</span></h1>
          <p className="text-slate-400 mt-2 text-sm text-center">
            Centralized Enterprise Command & Safety Intelligence
          </p>
        </div>

        {error && (
          <div className="flex items-center gap-3 bg-red-500/10 border border-red-500/30 p-4 rounded-2xl text-red-400 text-sm mb-6">
            <AlertTriangle className="w-5 h-5 flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider block">
              Fleet Admin Email
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
                <Mail className="w-5 h-5" />
              </span>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@organization.com"
                className="w-full bg-[#12141d]/50 border border-slate-800 focus:border-orange-500/50 rounded-2xl py-4 pl-12 pr-4 text-white placeholder-slate-600 focus:outline-none transition-colors"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-400 uppercase tracking-wider block">
              Password
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 flex items-center pl-4 text-slate-500">
                <Lock className="w-5 h-5" />
              </span>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full bg-[#12141d]/50 border border-slate-800 focus:border-orange-500/50 rounded-2xl py-4 pl-12 pr-4 text-white placeholder-slate-600 focus:outline-none transition-colors"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 text-white font-bold py-4 rounded-2xl shadow-lg transition-transform active:scale-[0.98] focus:outline-none disabled:opacity-50"
          >
            {loading ? "Establishing secure link..." : "Enter Command Center"}
          </button>
        </form>

        <div className="mt-8 text-center text-xs text-slate-600">
          FleetGuard AI Telematics &bull; v1.0.0
        </div>
      </motion.div>
    </div>
  );
}