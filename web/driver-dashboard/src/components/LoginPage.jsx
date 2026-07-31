import { User, Lock } from 'lucide-react';

const LoginPage = ({ onLogin }) => {
  return (
    <div className="h-screen w-screen flex items-center justify-center bg-slate-950">
      <div className="glass-panel p-12 w-full max-w-md space-y-8">
        <h1 className="text-4xl font-black text-center text-white">ADMIN LOGIN</h1>
        <div className="space-y-4">
          <div className="flex items-center bg-white/5 p-4 rounded-2xl border border-white/10">
            <User className="text-orange-500 mr-3" />
            <input type="text" placeholder="Admin ID" className="bg-transparent outline-none w-full text-white" />
          </div>
          <div className="flex items-center bg-white/5 p-4 rounded-2xl border border-white/10">
            <Lock className="text-orange-500 mr-3" />
            <input type="password" placeholder="Password" className="bg-transparent outline-none w-full text-white" />
          </div>
        </div>
        <button onClick={() => onLogin(true)} className="w-full bg-orange-600 py-4 rounded-3xl font-black text-lg hover:bg-orange-700 transition">
          ENTER COMMAND CENTER
        </button>
      </div>
    </div>
  );
};
export default LoginPage;