import { io } from './dashboard/node_modules/socket.io-client/build/esm/index.js';

const BACKEND_URL = 'http://localhost:3000';

console.log('Connecting to SmartDrive backend at', BACKEND_URL);

// Use demo role to bypass strict JWT check for simulation
const socket = io(BACKEND_URL, {
  auth: { role: 'driver', token: 'demo' },
  transports: ['websocket']
});

let lat = 12.9716;
let lng = 77.5946;
let speed = 40;
let heading = 90;

socket.on('connect', () => {
  console.log('✅ Connected to server with socket ID:', socket.id);
  
  // Send GPS update every 2 seconds
  setInterval(() => {
    // Simulate movement
    lat += 0.0005; 
    lng += 0.0005;
    speed = Math.floor(Math.random() * (60 - 30 + 1)) + 30; // Random speed 30-60
    
    const payload = {
      driverName: 'Test Driver (Simulator)',
      latitude: lat,
      longitude: lng,
      speed: speed,
      heading: heading,
      timestamp: new Date().toISOString()
    };
    
    socket.emit('gps_update', payload);
    console.log(`📍 Sent GPS: ${lat.toFixed(4)}, ${lng.toFixed(4)} at ${speed}km/h`);
    
    // Simulate a crash randomly (1% chance per tick)
    if (Math.random() < 0.01) {
      console.log('🚨 SIMULATING CRASH EVENT!');
      socket.emit('crash_event', {
        driverName: 'Test Driver (Simulator)',
        latitude: lat,
        longitude: lng,
        severity: 'CRITICAL',
        speedBefore: speed,
        speedAfter: 0,
        noMotionSeconds: 5
      });
    }
  }, 2000);
});

socket.on('connect_error', (err) => {
  console.error('❌ Connection failed:', err.message);
});

socket.on('disconnect', () => {
  console.log('⚠️ Disconnected from server');
});
