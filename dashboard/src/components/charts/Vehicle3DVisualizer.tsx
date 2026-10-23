import React, { useRef, useEffect, useState } from 'react';
import { RotateCcw, Eye, ShieldAlert, Sparkles, Compass, Car } from 'lucide-react';

interface Vehicle3DVisualizerProps {
  pitch?: number; // degrees
  roll?: number;  // degrees
  yaw?: number;   // degrees
  impactLocation?: 'front' | 'rear' | 'left' | 'right' | 'none';
  impactGForce?: number;
  interactive?: boolean;
  className?: string;
}

export const Vehicle3DVisualizer: React.FC<Vehicle3DVisualizerProps> = ({
  pitch = -2.5,
  roll = 1.2,
  yaw = 35,
  impactLocation = 'front',
  impactGForce = 3.85,
  interactive = true,
  className = '',
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [rotX, setRotX] = useState<number>(20);
  const [rotY, setRotY] = useState<number>(yaw);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [lastMouse, setLastMouse] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [selectedImpact, setSelectedImpact] = useState<'front' | 'rear' | 'left' | 'right' | 'none'>(impactLocation);
  const [autoRotate, setAutoRotate] = useState<boolean>(true);

  // Synchronize initial prop
  useEffect(() => {
    setSelectedImpact(impactLocation);
  }, [impactLocation]);

  useEffect(() => {
    setRotY(yaw);
  }, [yaw]);

  // Handle Mouse Drag for 3D rotation
  const handleMouseDown = (e: React.MouseEvent) => {
    if (!interactive) return;
    setIsDragging(true);
    setAutoRotate(false);
    setLastMouse({ x: e.clientX, y: e.clientY });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    const dx = e.clientX - lastMouse.x;
    const dy = e.clientY - lastMouse.y;
    setRotY((prev) => prev + dx * 0.8);
    setRotX((prev) => Math.max(-60, Math.min(80, prev - dy * 0.8)));
    setLastMouse({ x: e.clientX, y: e.clientY });
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  // Render 3D Model onto Canvas
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animId: number;

    // Define 3D vehicle mesh vertices [x, y, z] (centered around 0,0,0)
    // Scale: x = width, y = height, z = length
    const vertices: [number, number, number][] = [
      // Chassis lower body (0-7)
      [-40, 15, -90], [40, 15, -90], [42, 15, 90], [-42, 15, 90],
      [-40, -10, -90], [40, -10, -90], [42, -10, 90], [-42, -10, 90],

      // Cabin / Hood transition (8-11)
      [-38, -12, -35], [38, -12, -35], [40, -12, 45], [-40, -12, 45],

      // Cabin Roof (12-15)
      [-32, -38, -25], [32, -38, -25], [34, -38, 35], [-34, -38, 35],

      // Windshield & Rear glass corners
      [-35, -15, -35], [35, -15, -35],
      [-36, -15, 45], [36, -15, 45],

      // Front Bumper / Grill (20-23)
      [-38, 12, -92], [38, 12, -92], [38, -5, -92], [-38, -5, -92],

      // Rear Bumper (24-27)
      [-40, 12, 92], [40, 12, 92], [40, -5, 92], [-40, -5, 92],

      // Wheels [center locations] (28-31)
      [-44, 20, -55], [44, 20, -55], [-44, 20, 55], [44, 20, 55]
    ];

    // Polygonal faces [indices, baseColor, type]
    const faces = [
      // Front Bumper / Grill (Impact Zone Front)
      { v: [20, 21, 22, 23], color: selectedImpact === 'front' ? 'rgba(239, 68, 68, 0.9)' : 'rgba(30, 41, 59, 0.85)', stroke: '#06B6D4' },
      // Hood
      { v: [4, 5, 9, 8], color: selectedImpact === 'front' ? 'rgba(239, 68, 68, 0.6)' : 'rgba(15, 23, 42, 0.9)', stroke: '#38BDF8' },
      // Windshield
      { v: [8, 9, 13, 12], color: 'rgba(56, 189, 248, 0.35)', stroke: '#38BDF8' },
      // Roof
      { v: [12, 13, 14, 15], color: 'rgba(30, 41, 59, 0.95)', stroke: '#06B6D4' },
      // Rear Window
      { v: [15, 14, 10, 11], color: 'rgba(56, 189, 248, 0.3)', stroke: '#38BDF8' },
      // Trunk
      { v: [11, 10, 6, 7], color: selectedImpact === 'rear' ? 'rgba(239, 68, 68, 0.7)' : 'rgba(15, 23, 42, 0.9)', stroke: '#38BDF8' },
      // Rear Bumper
      { v: [24, 25, 26, 27], color: selectedImpact === 'rear' ? 'rgba(239, 68, 68, 0.9)' : 'rgba(30, 41, 59, 0.85)', stroke: '#06B6D4' },
      // Left Flank (Impact Zone Left)
      { v: [0, 4, 8, 12, 15, 11, 7, 3], color: selectedImpact === 'left' ? 'rgba(239, 68, 68, 0.7)' : 'rgba(15, 23, 42, 0.85)', stroke: '#06B6D4' },
      // Right Flank (Impact Zone Right)
      { v: [1, 5, 9, 13, 14, 10, 6, 2], color: selectedImpact === 'right' ? 'rgba(239, 68, 68, 0.7)' : 'rgba(15, 23, 42, 0.85)', stroke: '#06B6D4' },
      // Underbody floor
      { v: [0, 1, 2, 3], color: 'rgba(2, 6, 23, 0.95)', stroke: '#1E293B' }
    ];

    let pulsePhase = 0;

    const render = () => {
      pulsePhase += 0.05;
      const width = canvas.width;
      const height = canvas.height;
      const centerX = width / 2;
      const centerY = height / 2 + 10;
      const fov = 380;

      ctx.clearRect(0, 0, width, height);

      // Soft tactical grid background on canvas floor
      ctx.save();
      ctx.strokeStyle = 'rgba(6, 182, 212, 0.07)';
      ctx.lineWidth = 1;
      const gridSize = 30;
      for (let x = -150; x <= 150; x += gridSize) {
        ctx.beginPath();
        ctx.moveTo(centerX + x, centerY - 60);
        ctx.lineTo(centerX + x * 1.5, centerY + 120);
        ctx.stroke();
      }
      ctx.restore();

      // Convert Rotation angles to Radians
      const radX = (rotX * Math.PI) / 180;
      const radY = (rotY * Math.PI) / 180;
      const radZ = (roll * Math.PI) / 180;

      // Rotate vertex around X, Y, Z
      const project = (x: number, y: number, z: number) => {
        // Yaw (around Y axis)
        let x1 = x * Math.cos(radY) + z * Math.sin(radY);
        let y1 = y;
        let z1 = -x * Math.sin(radY) + z * Math.cos(radY);

        // Pitch (around X axis)
        let x2 = x1;
        let y2 = y1 * Math.cos(radX) - z1 * Math.sin(radX);
        let z2 = y1 * Math.sin(radX) + z1 * Math.cos(radX);

        // Roll (around Z axis)
        let x3 = x2 * Math.cos(radZ) - y2 * Math.sin(radZ);
        let y3 = x2 * Math.sin(radZ) + y2 * Math.cos(radZ);
        let z3 = z2;

        const distance = 280;
        const scale = fov / (distance + z3);
        const px = centerX + x3 * scale;
        const py = centerY + y3 * scale;

        return { px, py, zDepth: z3 };
      };

      // Project all vertices
      const projected = vertices.map(([x, y, z]) => project(x, y, z));

      // Calculate face depth and sort back-to-front
      const sortedFaces = faces.map((face) => {
        const avgZ = face.v.reduce((sum, idx) => sum + projected[idx].zDepth, 0) / face.v.length;
        return { ...face, avgZ };
      }).sort((a, b) => b.avgZ - a.avgZ);

      // Draw shadow beneath vehicle
      ctx.save();
      ctx.beginPath();
      ctx.ellipse(centerX, centerY + 45, 90, 40, 0, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
      ctx.filter = 'blur(10px)';
      ctx.fill();
      ctx.restore();

      // Draw faces
      sortedFaces.forEach((face) => {
        ctx.beginPath();
        const start = projected[face.v[0]];
        ctx.moveTo(start.px, start.py);
        for (let i = 1; i < face.v.length; i++) {
          const pt = projected[face.v[i]];
          ctx.lineTo(pt.px, pt.py);
        }
        ctx.closePath();

        // Fill Face
        ctx.fillStyle = face.color;
        ctx.fill();

        // Stroke wireframe
        ctx.strokeStyle = face.stroke;
        ctx.lineWidth = 1.2;
        ctx.stroke();
      });

      // Draw 3D Wheels
      const wheels = [
        projected[28], projected[29], projected[30], projected[31]
      ];
      wheels.forEach((w) => {
        ctx.save();
        ctx.beginPath();
        ctx.arc(w.px, w.py, 11, 0, Math.PI * 2);
        ctx.fillStyle = '#0F172A';
        ctx.fill();
        ctx.strokeStyle = '#06B6D4';
        ctx.lineWidth = 2.5;
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(w.px, w.py, 5, 0, Math.PI * 2);
        ctx.fillStyle = '#38BDF8';
        ctx.fill();
        ctx.restore();
      });

      // Draw Impact Shockwave Visualizer Ring at designated point
      if (selectedImpact !== 'none') {
        let impactAnchor = projected[21]; // Front default
        if (selectedImpact === 'rear') impactAnchor = projected[25];
        if (selectedImpact === 'left') impactAnchor = projected[0];
        if (selectedImpact === 'right') impactAnchor = projected[1];

        const pulseSize = 18 + Math.sin(pulsePhase * 3) * 8;
        const pulseAlpha = 0.5 + Math.sin(pulsePhase * 3) * 0.4;

        ctx.save();
        // Outer shockwave ring
        ctx.beginPath();
        ctx.arc(impactAnchor.px, impactAnchor.py, pulseSize * 1.6, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(239, 68, 68, ${pulseAlpha * 0.5})`;
        ctx.lineWidth = 3;
        ctx.stroke();

        // Core impact explosion circle
        ctx.beginPath();
        ctx.arc(impactAnchor.px, impactAnchor.py, pulseSize, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(239, 68, 68, ${pulseAlpha * 0.8})`;
        ctx.shadowColor = '#EF4444';
        ctx.shadowBlur = 20;
        ctx.fill();

        // Vector arrow pointing to impact
        ctx.beginPath();
        ctx.moveTo(impactAnchor.px, impactAnchor.py - 30);
        ctx.lineTo(impactAnchor.px, impactAnchor.py - 5);
        ctx.strokeStyle = '#F43F5E';
        ctx.lineWidth = 3;
        ctx.stroke();

        // G-Force Vector Tag
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 9px monospace';
        ctx.fillText(`💥 IMPACT: ${impactGForce}G`, impactAnchor.px - 38, impactAnchor.py - 35);
        ctx.restore();
      }

      // Auto-rotation idle loop
      if (autoRotate && !isDragging) {
        setRotY((prev) => (prev + 0.35) % 360);
      }

      animId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animId);
    };
  }, [rotX, rotY, roll, selectedImpact, impactGForce, autoRotate, isDragging]);

  return (
    <div className={`relative bg-gradient-to-b from-[#0A0E1A] via-[#050811] to-[#020617] rounded-3xl border border-slate-800 overflow-hidden p-5 shadow-2xl ${className}`}>
      {/* Top Header & Telemetry Coordinates */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <div className="h-2 w-2 rounded-full bg-cyan-400 animate-ping" />
          <h3 className="text-xs font-black uppercase tracking-widest text-cyan-300 flex items-center gap-1.5 font-mono">
            <Car size={14} /> 3D Vehicle Impact & Attitude Visualizer
          </h3>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[10px] font-mono text-slate-400">
            PITCH: <strong className="text-cyan-400">{pitch.toFixed(1)}°</strong> | ROLL: <strong className="text-cyan-400">{roll.toFixed(1)}°</strong> | YAW: <strong className="text-cyan-400">{Math.round(rotY % 360)}°</strong>
          </span>
          <button
            onClick={() => {
              setRotX(20);
              setRotY(yaw);
              setAutoRotate(true);
            }}
            title="Reset 3D Viewpoint"
            className="p-1 rounded-lg bg-slate-900 border border-slate-700 text-slate-400 hover:text-white transition"
          >
            <RotateCcw size={12} />
          </button>
        </div>
      </div>

      {/* 3D Canvas */}
      <div
        className="relative h-[250px] w-full flex items-center justify-center cursor-grab active:cursor-grabbing select-none"
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        <canvas
          ref={canvasRef}
          width={540}
          height={250}
          className="w-full h-full block"
        />

        {/* Orbit hint overlay */}
        <div className="absolute bottom-2 left-3 text-[9px] font-mono text-slate-500 uppercase tracking-wider flex items-center gap-1 pointer-events-none">
          <Compass size={11} className="text-cyan-500 animate-spin" />
          <span>Click & Drag to Rotate 360° Perspective</span>
        </div>

        {/* Impact Severity Badge */}
        {selectedImpact !== 'none' && (
          <div className="absolute top-2 right-3 px-2.5 py-1 rounded-xl bg-rose-500/20 border border-rose-500/40 text-rose-300 text-[10px] font-mono font-black uppercase tracking-wider animate-pulse flex items-center gap-1.5">
            <ShieldAlert size={12} className="text-rose-400" />
            <span>CRITICAL INTRUSION ZONE ({selectedImpact.toUpperCase()})</span>
          </div>
        )}
      </div>

      {/* Interactive Controls & Zone Toggles */}
      <div className="mt-3 pt-3 border-t border-slate-800/80 flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
          <span>Deformation Vectors:</span>
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          {(['front', 'left', 'right', 'rear', 'none'] as const).map((loc) => (
            <button
              key={loc}
              onClick={() => setSelectedImpact(loc)}
              className={`px-2.5 py-1 rounded-lg text-[10px] font-mono font-bold uppercase tracking-wider transition-all cursor-pointer ${
                selectedImpact === loc
                  ? 'bg-rose-600 text-white shadow-md shadow-rose-600/30'
                  : 'bg-slate-900 border border-slate-800 text-slate-400 hover:text-white'
              }`}
            >
              {loc === 'none' ? 'Normal (Intact)' : `${loc} (${impactGForce}G)`}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Vehicle3DVisualizer;
