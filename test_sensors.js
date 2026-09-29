/**
 * SmartDrive Sensor & Crash Simulator
 * 
 * Usage:
 *   node test_sensors.js [mode]
 * 
 * Modes:
 *   node test_sensors.js crash     -> Simulates 60 km/h driving followed by sudden deceleration (0 km/h) & 4.5G force impact.
 *   node test_sensors.js ping-timeout -> Connects as driver and waits for Admin Safety Ping, then lets 30s expire to test NO RESPONSE alert.
 *   node test_sensors.js ping-safe -> Connects as driver, receives Admin Safety Ping, and immediately confirms safe.
 *   node test_sensors.js stream    -> Continuously streams real-time sensor & GPS updates.
 */

let io;
try {
  io = require('socket.io-client').io;
} catch {
  io = require('./backend/node_modules/socket.io-client').io;
}

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';
const DRIVER_ID = process.env.DRIVER_ID || 'mobile-driver';
const DRIVER_NAME = process.env.DRIVER_NAME || 'Suresh Nayak (Field Operator)';

console.log('====================================================');
console.log('   SMARTDRIVE TACTICAL SENSOR & SOS SIMULATOR       ');
console.log('====================================================');
console.log(`Connecting to Backend: ${BACKEND_URL}`);
console.log(`Driver Profile: ${DRIVER_NAME} [ID: ${DRIVER_ID}]`);

const socket = io(BACKEND_URL, {
  transports: ['websocket'],
  autoConnect: true,
  auth: { token: 'mock-driver-token' }
});

const mode = process.argv[2] || 'crash';

socket.on('connect', () => {
  console.log(`\n✅ LINK ESTABLISHED (Socket ID: ${socket.id})`);
  
  // Register shift online
  socket.emit('shift_status', {
    driverId: DRIVER_ID,
    driverName: DRIVER_NAME,
    status: 'online',
    latitude: 12.7749,
    longitude: 75.2023,
    regionId: 'puttur_taluk',
    region: 'Puttur Sector',
    timestamp: new Date().toISOString()
  });
  console.log('📡 Operator Shift Status: ONLINE');

  if (mode === 'crash') {
    runCrashSimulation();
  } else if (mode === 'stream') {
    runTelemetryStream();
  } else if (mode === 'ping-timeout') {
    console.log('\n⏳ Listening for Admin Safety Ping from Dashboard...');
    console.log('   (When admin sends Step 1 Ping, timer will count down 30s without responding to trigger NO RESPONSE alert)');
  } else if (mode === 'ping-safe') {
    console.log('\n⏳ Listening for Admin Safety Ping from Dashboard...');
    console.log('   (When admin sends Step 1 Ping, will reply SAFE after 2 seconds)');
  }
});

socket.on('driver_check_ping', (data) => {
  console.log('\n📩 [ADMIN SAFETY PING RECEIVED]:', data.message || 'Are you safe?');
  
  if (mode === 'ping-safe') {
    console.log('⚡ Responding "I AM SAFE" in 2 seconds...');
    setTimeout(() => {
      socket.emit('safety_response');
      console.log('✅ Emitted safety_response. Admin dashboard will show "✓ Operator Confirmed Safe".');
    }, 2000);
  } else if (mode === 'ping-timeout') {
    console.log('⏱️ Starting 30s countdown without driver response...');
    let remaining = 30;
    const interval = setInterval(() => {
      remaining--;
      process.stdout.write(`\r   Countdown: ${remaining}s remaining... `);
      if (remaining <= 0) {
        clearInterval(interval);
        console.log('\n🚨 30s TIMEOUT EXPIRED: Emitting driver_no_response to Admin Dashboard!');
        socket.emit('driver_no_response', {
          driverId: DRIVER_ID,
          reason: 'Admin Safety Ping Expired: No Response from Driver (30s elapsed)'
        });
      }
    }, 1000);
  }
});

function runCrashSimulation() {
  console.log('\n🚗 PHASE 1: Vehicle cruising at 62 km/h...');
  
  let lat = 12.7749;
  let lng = 75.2023;
  let speed = 62.4;

  // Stream normal high-speed telemetry for 3 seconds
  let step = 0;
  const driveInterval = setInterval(() => {
    step++;
    lat += 0.0003;
    lng += 0.0002;
    
    socket.emit('gps_update', {
      driverId: DRIVER_ID,
      driverName: DRIVER_NAME,
      latitude: lat,
      longitude: lng,
      speed: speed,
      heading: 42,
      accelX: 0.12,
      accelY: 0.35,
      accelZ: 9.81,
      gyroX: 0.2,
      gyroY: -0.1,
      gyroZ: 0.4,
      magX: 24,
      magY: -12,
      magZ: 44,
      status: 'safe',
      safetyScore: 98
    });
    console.log(`   [Telemetry] Speed: ${speed.toFixed(1)} km/h | Lat: ${lat.toFixed(5)}, Lng: ${lng.toFixed(5)}`);

    if (step >= 3) {
      clearInterval(driveInterval);
      
      console.log('\n💥 PHASE 2: IMPACT OCCURRED! High G-Force (4.6G) & Sudden Speed Drop (62 -> 0 km/h)!');
      
      const crashPayload = {
        driverId: DRIVER_ID,
        driverName: DRIVER_NAME,
        reason: 'High-Speed Sudden Deceleration (62 → 0 km/h) & 4.6G Force Impact',
        latitude: lat,
        longitude: lng,
        severity: 'CRITICAL',
        speedBefore: 62.4,
        speedAfter: 0.0,
        gForce: 4.6,
        accelX: 2.8,
        accelY: 3.9,
        accelZ: 4.6,
        timestamp: new Date().toISOString()
      };

      socket.emit('crash_detected', crashPayload);
      socket.emit('crash_event', crashPayload);
      
      // Update vehicle to stationary
      socket.emit('gps_update', {
        driverId: DRIVER_ID,
        driverName: DRIVER_NAME,
        latitude: lat,
        longitude: lng,
        speed: 0.0,
        heading: 42,
        accelX: 0.02,
        accelY: 0.01,
        accelZ: 9.81,
        status: 'emergency',
        safetyScore: 42
      });

      console.log('🚨 CRASH ALERT BROADCASTED TO ALL ADMIN DASHBOARDS & LIVE MAP!');
      console.log('   Coordinates: Lat ' + lat.toFixed(5) + ', Lng ' + lng.toFixed(5));
      console.log('   Check your Admin Dashboard for the Emergency Alert & auto-focused Tactical Map!\n');
    }
  }, 1000);
}

function runTelemetryStream() {
  console.log('\n📡 Streaming live sensor & GPS telemetry (Press Ctrl+C to stop)...');
  let lat = 12.7749;
  let lng = 75.2023;
  let speed = 35.0;

  setInterval(() => {
    lat += (Math.random() - 0.5) * 0.0005;
    lng += (Math.random() - 0.5) * 0.0005;
    speed = Math.max(15, Math.min(65, speed + (Math.random() - 0.5) * 6));
    const accelX = (Math.random() - 0.5) * 1.5;
    const accelY = (Math.random() - 0.5) * 1.5;
    const gForce = Math.sqrt(accelX*accelX + accelY*accelY + 9.81*9.81) / 9.81;

    socket.emit('gps_update', {
      driverId: DRIVER_ID,
      driverName: DRIVER_NAME,
      latitude: lat,
      longitude: lng,
      speed: speed,
      heading: Math.floor(Math.random() * 360),
      accelX: accelX,
      accelY: accelY,
      accelZ: 9.81,
      gyroX: (Math.random() - 0.5) * 2.0,
      gyroY: (Math.random() - 0.5) * 2.0,
      gyroZ: (Math.random() - 0.5) * 2.0,
      magX: 20 + Math.random() * 5,
      magY: -10 + Math.random() * 5,
      magZ: 40 + Math.random() * 5,
      vibrationRate: gForce,
      status: 'safe',
      safetyScore: 95
    });

    console.log(`[Stream] Speed: ${speed.toFixed(1)} km/h | G-Force: ${gForce.toFixed(2)}g | Lat: ${lat.toFixed(5)}, Lng: ${lng.toFixed(5)}`);
  }, 1000);
}
