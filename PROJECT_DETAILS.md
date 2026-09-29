# 🚗 Smart Mobile-Based Driving Behaviour & Risk Monitoring System
> **An End-to-End AIoT Telematics Platform**: Embedded ESP32 C++ Sensor Fusion, Python FastAPI AI Microservice, Node.js/TypeScript Express Gateway, React 18 Fleet Command Center, Flutter Mobile Client, and Containerized PostgreSQL/Redis.

[![System Status](https://img.shields.io/badge/System-Operational-emerald?style=flat-square)](#)
[![Embedded C++](https://img.shields.io/badge/Firmware-ESP32_C%2B%2B_v3.7.0-blue?style=flat-square)](#pillar-1-embedded-c-esp32--mpu-6050-iot-node)
[![Python AI](https://img.shields.io/badge/AI_Engine-FastAPI_Python_3.10+-yellow?style=flat-square)](#pillar-2-python-fastapi-ai-microservice)
[![Backend Gateway](https://img.shields.io/badge/Gateway-Node.js_v20+_TypeScript-green?style=flat-square)](#pillar-3-nodejs-express--typescript-api-gateway--data-pipeline)
[![Frontend HUD](https://img.shields.io/badge/Dashboard-React_18_Vite-purple?style=flat-square)](#pillar-4-frontend-architecture-react-18-dashboard--flutter-mobile)
[![Docker](https://img.shields.io/badge/Infrastructure-Docker_PostgreSQL_Redis-2496ED?style=flat-square)](#pillar-5-docker--infrastructure-postgresql-15--redis-7)

---

## 📑 Master Architecture Navigation

1. [Executive Summary & Vision](#-executive-summary--vision)
2. [The Fundamental Engineering Question: Why Not ONLY the Mobile Phone?](#-the-fundamental-engineering-question-why-not-only-the-mobile-phone)
   - [The 5 Critical Limitations of Smartphone-Only Telematics](#the-5-critical-limitations-of-smartphone-only-telematics)
   - [Smartphone-Only vs. ESP32 Hybrid Comparison Table](#smartphone-only-vs-esp32-hybrid-comparison-table)
   - [The 3-Tier Distributed Synergy](#the-3-tier-distributed-synergy)
3. [End-to-End System Interaction Architecture](#-end-to-end-system-interaction-architecture)
4. [Pillar 1: Embedded C++ (ESP32 & MPU-6050 IoT Node)](#-pillar-1-embedded-c-esp32--mpu-6050-iot-node)
   - [🎯 WHY C++ for Edge Telematics?](#-why-c-for-edge-telematics)
   - [📦 WHAT the C++ Node Does](#-what-the-c-node-does)
   - [⚙️ HOW it Works: Low-Level Register Config, DSP Math & Stacks](#️-how-it-works-low-level-register-config-dsp-math--stacks)
     - [1. Hardware Pinout & Circuit Schematic](#1-hardware-pinout--circuit-schematic)
     - [2. Electrical Noise Immunity & I2C Bus Recovery Protocol](#2-electrical-noise-immunity--i2c-bus-recovery-protocol)
     - [3. Direct Hardware Register Configuration](#3-direct-hardware-register-configuration)
     - [4. High-Speed 14-Byte Repeated-Start Burst Read](#4-high-speed-14-byte-repeated-start-burst-read)
     - [5. Mathematical Signal Processing & Baseline Calibration](#5-mathematical-signal-processing--baseline-calibration)
     - [6. Edge Anomaly & Crash Detection Thresholds](#6-edge-anomaly--crash-detection-thresholds)
     - [7. Wireless Telemetry Engine: BLE GATT & Wi-Fi SoftAP](#7-wireless-telemetry-engine-ble-gatt--wi-fi-softap)
5. [Pillar 2: Python (FastAPI AI Microservice)](#-pillar-2-python-fastapi-ai-microservice)
   - [🎯 WHY Python & FastAPI?](#-why-python--fastapi)
   - [📦 WHAT the Python AI Engine Does](#-what-the-python-ai-engine-does)
   - [⚙️ HOW it Works: Scoring Math, Delta-V & Crash Forensics](#️-how-it-works-scoring-math-delta-v--crash-forensics)
6. [Pillar 3: Node.js, Express & TypeScript (API Gateway & Data Pipeline)](#-pillar-3-nodejs-express--typescript-api-gateway--data-pipeline)
   - [🎯 WHY Node.js & TypeScript?](#-why-nodejs--typescript)
   - [📦 WHAT the API Gateway Does](#-what-the-api-gateway-does)
   - [⚙️ HOW it Works: Clean Architecture, Sockets, BullMQ & Prisma](#️-how-it-works-clean-architecture-sockets-bullmq--prisma)
7. [Pillar 4: Frontend Architecture (React 18 Dashboard & Flutter Mobile)](#-pillar-4-frontend-architecture-react-18-dashboard--flutter-mobile)
   - [🎯 WHY React 18 & Flutter?](#-why-react-18--flutter)
   - [📦 WHAT the Client Portals Do](#-what-the-client-portals-do)
   - [⚙️ HOW it Works: State Management, GIS Maps & Radar Scanner](#️-how-it-works-state-management-gis-maps--radar-scanner)
8. [Pillar 5: Docker & Infrastructure (PostgreSQL 15 & Redis 7)](#-pillar-5-docker--infrastructure-postgresql-15--redis-7)
   - [🎯 WHY Docker Containerization?](#-why-docker-containerization)
   - [📦 WHAT the Container Stack Orchestrates](#-what-the-container-stack-orchestrates)
   - [⚙️ HOW it Works: compose Services, Networks & Volumes](#️-how-it-works-compose-services-networks--volumes)
9. [Monorepo Directory Structure & File Map](#-monorepo-directory-structure--file-map)
10. [Step-by-Step Installation, Flashing & Operational Runbook](#-step-by-step-installation-flashing--operational-runbook)
11. [Environment Variables Reference](#-environment-variables-reference)
12. [Academic Project Credits](#-academic-project-credits)

---

## 📌 Executive Summary & Vision

Human behavioral factors—such as **panic braking, aggressive acceleration, high-speed turning, and continuous overspeeding**—are responsible for over **90% of vehicular accidents**. Conventional commercial telematics systems require expensive OBD-II dongles or hardwired CAN-bus taps costing $300–$800 per vehicle.

This platform introduces an **accessible, enterprise-grade AIoT Telematics Ecosystem**:
* **Sub-$6 Hardware Node**: ESP32 + MPU-6050 processing kinematic dynamics at 20 Hz directly on the edge.
* **Intelligent Edge Mobile App**: Flutter client with Bluetooth Low Energy (BLE) radar scanning and OpenStreetMap GIS context.
* **Real-Time Node.js Gateway**: Sub-50ms WebSocket telemetry broadcast engine backed by PostgreSQL and Redis.
* **Forensic Python AI Service**: Evaluates trip safety scores (0–100), risk percentages, and crash kinetic crush deformation indices.
* **Command & Control HUD**: React 18 dashboard rendering real-time vehicle coordinates, breadcrumb routes, and emergency alarms.

---

## 🔬 The Fundamental Engineering Question: Why Not ONLY the Mobile Phone?

At first glance, a modern smartphone already contains an accelerometer, a gyroscope, and a GPS chip. Why did we build and integrate a separate **ESP32 + MPU-6050 Embedded C++ hardware node**? Why not rely entirely on the phone?

The answer lies in the **physical, mechanical, and operating-system realities of automotive environments**:

```text
       SMARTPHONE ONLY (Inherently Flawed)                HYBRID: PHONE + ESP32 HARDWARE NODE (Robust)
+-------------------------------------------------+     +-------------------------------------------------------+
| • Driver picks up phone -> 3g false harsh brake |     | • ESP32 Node rigidly fixed to vehicle chassis         |
| • Phone slides across passenger seat on turn    |     |   -> 100% Pure, Uncontaminated Vehicle Dynamics       |
| • Phone rattles in loose air-vent plastic mount |     |                                                       |
| • OS Doze Mode throttles sensor polling to 1 Hz |     | • Smartphone focuses on GPS, 4G Cloud Sync, & HUD     |
| • Smartphone sensor saturates at +/-2g or +/-4g |     | • ESP32 captures up to +/-16g crash shockwaves at 20Hz|
| • Phone battery dies & overheats on dashboard   |     | • Zero false alarms caused by driver phone handling   |
+-------------------------------------------------+     +-------------------------------------------------------+
```

### The 5 Critical Limitations of Smartphone-Only Telematics

#### 1. Mechanical Decoupling & Spurious Handheld Forces
A phone inside a vehicle is **mechanically decoupled from the chassis**. 
* Drivers interact with their phones: they answer calls, adjust navigation, tap the screen, or pick the device up from the cup holder.
* A phone resting on a seat slides and tumbles during a turn. A phone mounted to an air vent oscillates whenever the car hits a seam in the pavement.
* Every time a driver picks up the phone or it slides, the phone's internal accelerometer experiences a **$2.0g - 3.5g$ lateral or longitudinal surge**. In a phone-only application, these movements trigger false **"Harsh Braking"**, **"Aggressive Swerve"**, or **"Accident Detected"** infractions, unfairly destroying driver safety scores.
* **The Hardware Solution**: The ESP32 node is **fixed to the vehicle chassis or dashboard**. It has zero handheld interference, guaranteeing that every registered force is a **pure vehicle dynamic event**.

#### 2. Dynamic Range & Sensor Saturation in High-G Collisions
Smartphone MEMS accelerometers are designed for low-G everyday human activities (counting footsteps, detecting screen orientation, gentle UI gestures). Consequently, consumer mobile operating systems set their hardware range to **$\pm 2g$, $\pm 4g$, or $\pm 8g$**.
* In a real vehicular collision, the initial metal-deformation impact shockwave reaches **$10g$ to $16g+$ within 30 milliseconds**.
* When a high-impact crash occurs, a phone sensor **flatlines / clips at its maximum threshold ($\pm 2g$ or $\pm 4g$)**, losing the true peak shockwave amplitude.
* **The Hardware Solution**: In our embedded C++ firmware, register `0x1C` is explicitly programmed to **Full Scale Range $\pm 16g$** ($2048.0 \text{ LSB}/g$). This allows the node to log massive collision shockwaves and kinetic crush energies without sensor saturation.

#### 3. Operating System Background Throttling & Doze Mode
Mobile operating systems (Android and iOS) enforce ruthless power-management policies:
* When the smartphone screen turns off or another application is active, Android's **Doze Mode** and iOS's **Background Execution Limits** throttle background sensor callbacks.
* A required 50 Hz or 20 Hz sensor stream is throttled down to **1 Hz or suspended entirely**, creating blind spots where sudden harsh braking or swerving goes completely undetected.
* **The Hardware Solution**: The ESP32 is a dedicated bare-metal microcontroller. It runs a deterministic, unthrottled **20 Hz (50 ms)** sampling loop that never sleeps, throttles, or drops packets.

#### 4. Smartphone Thermal Overheating & Battery Drain
Running continuous high-frequency accelerometer and gyroscope polling while concurrently maintaining high-accuracy GPS tracking, rendering a 60 FPS navigation screen, and streaming data over 4G/5G causes extreme smartphone power dissipation.
* In automotive setups, smartphones are frequently mounted on windshields or dashboards under direct sunlight.
* The combination of direct solar radiant heat and heavy CPU load triggers **thermal throttling and emergency shutdowns** on smartphones.
* **The Hardware Solution**: Offloading all motion math, baseline calibration, and deadband filtering to the sub-$6 ESP32 hardware node leaves the phone's CPU idle, extending battery life and eliminating thermal shutdown.

#### 5. Vehicle Fleet Permanence & Multi-Driver Identity
In commercial fleets (taxis, couriers, logistics trucks), vehicles are shared among multiple drivers across different shifts.
* If tracking relies solely on the driver's phone, vehicle monitoring terminates when a driver's battery dies or when drivers swap seats without logging into an app.
* **The Hardware Solution**: The ESP32 node stays permanently with the vehicle. It maintains a persistent vehicle identifier (`SD-ESP32-001`), fixed chassis orientation calibrations, cumulative trip counters, and hardware crash history independent of who is driving.

---

### Smartphone-Only vs. ESP32 Hybrid Comparison Table

| Evaluation Criterion | Smartphone-Only System | ESP32 + Mobile Hybrid System |
| :--- | :--- | :--- |
| **Mechanical Coupling** | Decoupled (loose phone, pocket, mount rattle) | **Rigidly bonded to vehicle body/chassis** |
| **Handheld False Positives** | High (phone pickup, texting, dropping = false alarms) | **Zero (immune to handheld movement)** |
| **Accelerometer Dynamic Range** | $\pm 2g$ to $\pm 4g$ (Saturates during crashes) | **$\pm 16g$ (Captures catastrophic shockwaves)** |
| **Sampling Determinism** | Variable (throttled by Android Doze/iOS limits) | **Deterministic 20 Hz (50 ms) edge loop** |
| **Impact of Thermal Sun Load** | Phone shuts down due to combined CPU + Solar heat | **ESP32 automotive operating range ($-40^\circ\text{C}$ to $+85^\circ\text{C}$)** |
| **Phone Battery Impact** | Heavy (rapid drain from continuous IMU polling) | **Minimal (receives pre-filtered BLE packets)** |
| **Offline Telemetry Buffer** | Lost if phone app crashes | **Continuously computed and emitted over BLE** |
| **Deployment Cost** | Free (uses existing phone) | **Sub-$6 BOM (ESP32 + MPU-6050 + TP4056)** |

---

### The 3-Tier Distributed Synergy

Our platform does not replace the smartphone—it forms an **intelligent 3-tier distributed pipeline**:

```text
+-----------------------------------+
|      TIER 1: THE EDGE SENSOR      |  --> ESP32 + MPU-6050 Hardware Node
|     (Inertial Physics Engine)     |      Handles high-G physics, baseline leveling, & vibration filtering.
+-----------------------------------+
                  |
                  | BLE GATT Notify (20 Hz, 50ms)
                  v
+-----------------------------------+
|     TIER 2: THE MOBILE CLIENT     |  --> Flutter Mobile Application
|     (Context & Communications)    |      Provides GPS position, OSM road speed limits, voice HUD, & 4G sync.
+-----------------------------------+
                  |
                  | HTTPS REST & WebSockets (1 Hz updates)
                  v
+-----------------------------------+
|      TIER 3: THE CLOUD BACKEND    |  --> Node.js + Python FastAPI + PostgreSQL + React
|      (Forensics & Fleet Control)  |      Computes AI risk scores, crash forensics, & live GIS maps.
+-----------------------------------+
```

---

## 🧩 End-to-End System Interaction Architecture

```text
[ VEHICLE CABIN ]
  +-----------------------+              I2C (40 kHz)
  |  MPU-6050 6-Axis IMU  | ------------------------------------+
  |  Acc: +/-16g, Gyro:250|                                     |
  +-----------------------+                                     v
                                                    +-----------------------+
  +-----------------------+                         | ESP32 Hardware Node   |
  | Smartphone Sensors    |                         |  - Direct Reg Control |
  | GPS, Linear Accel     |                         |  - Auto-Zero Baseline |
  +-----------+-----------+                         |  - Deadband Filter    |
              |                                     |  - Crash Shockwave Det|
              |                                     +-----------+-----------+
              |                                                 |
              |                                  BLE GATT Notify| (20 Hz) or
              |                                  Wi-Fi SoftAP   | (192.168.4.1)
              |                                                 v
              |               +-------------------------------------------------+
              +-------------> | Flutter Mobile Client (Driver HUD & Radar)      |
                              |  - Sensor Fusion & Noise Debounce               |
                              |  - OSM Overpass GIS Speed Limit Queries         |
                              |  - Voice TTS & Haptic Collision Alerts          |
                              +------------------------+------------------------+
                                                       |
                                                       | HTTPS REST & WebSocket
                                                       v
[ CLOUD & ON-PREMISE BACKEND ]
+-------------------------------------------------------------------------------+
| Node.js / Express / TypeScript API Gateway (Port 3000)                        |
|                                                                               |
|  [Security: Helmet / CORS / RateLimiting]                                     |
|         ↓                                                                     |
|  [Auth Middleware: Dual JWT (Access 15m / Refresh 7d) & RBAC Guard]           |
|         ↓                                                                     |
|  [Zod Request Validation]                                                     |
|         ↓                                                                     |
|  [Controllers & Services] ---> [Prisma ORM] --------------> [PostgreSQL 15]   |
|         |                            |                      (14 Relational    |
|         |                            v                       GIS Tables)      |
|         |                     [BullMQ Queues] ------------> [Redis 7 Cache]   |
|         |                            |                      (Session & Jobs)  |
|         |                            v                                        |
|         |                 [Python FastAPI AI Microservice]                    |
|         |                 (Port 5000 - ASGI Uvicorn)                          |
|         |                  - ScoreService: 0-100 Safety Score & Badges        |
|         |                  - CrashService: Delta-V & Crush Index Forensics    |
|         v                                                                     |
|  [Socket.IO Gateway Broadcaster]                                              |
|    - Room: join_fleet_room                                                    |
|    - Events: gps_update, event_detected, crash_alert                          |
+--------------------------------------+----------------------------------------+
                                       |
                                       | Real-Time WebSocket & REST
                                       v
[ PRESENTATION INTERFACES ]
+--------------------------------------+----------------------------------------+
| React 18 Fleet Command Center        | React Driver Web Portal                |
| (Port 5173 - Vite / TailwindCSS)     | (Port 5174)                            |
|  - Live Leaflet GIS Vehicle Map      |  - Personal Trip History Logs          |
|  - Real-Time Speed Compliance Badges |  - Safety Score Trends & Badges        |
|  - Driver Leaderboard & Analytics    |  - Eco-Driving Educational Tips        |
|  - Emergency Crash Investigation HUD |  - Profile & Identity Self-Service     |
+--------------------------------------+----------------------------------------+
```

---

## ⚡ Pillar 1: Embedded C++ (ESP32 & MPU-6050 IoT Node)

* **Firmware Location**: [`hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino)
* **Standalone Firmware**: [`hardware/SmartDrive_ESP32_Node/SmartDrive_ESP32_Node.ino`](file:///c:/projects/Major_project/hardware/SmartDrive_ESP32_Node/SmartDrive_ESP32_Node.ino)
* **Wiring Documentation**: [`hardware_esp32/WIRING_AND_SETUP_GUIDE.md`](file:///c:/projects/Major_project/hardware_esp32/WIRING_AND_SETUP_GUIDE.md)

### 🎯 WHY C++ for Edge Telematics?
1. **Microsecond Determinism (Zero Garbage Collection)**: Detecting a vehicular collision shockwave requires microsecond timing. In high-level languages (Java, JavaScript, Python), garbage collection pauses the CPU for 10ms to 100ms. In a high-speed crash occurring over 30ms, a GC pause means the peak crash shockwave is completely lost. C++ executes bare-metal instructions with **zero latency jitter**.
2. **Direct Hardware Register Access**: C++ allows direct I2C byte communication with internal sensor registers (`0x6B`, `0x1B`, `0x1C`, `0x1A`), bypassing heavy third-party libraries.
3. **Memory & Binary Footprint**: The compiled C++ firmware fits inside **~950 KB**, fitting comfortably within the standard 1.2 MB ESP32 application flash partition while maintaining over 200 KB of free SRAM for dynamic buffers.
4. **Dual Wireless Hardware Stacks**: C++ natively drives the ESP-IDF **Bluedroid Bluetooth stack** and **lwIP TCP/IP stack**, enabling concurrent BLE GATT streaming and local SoftAP routing.

---

### 📦 WHAT the C++ Node Does
* **High-Frequency Kinematic Sampling**: Samples linear acceleration ($a_x, a_y, a_z$) and angular velocity ($g_x, g_y, g_z$) at **20 Hz (every 50ms)**.
* **I2C Bus Recovery**: Executes a 9-cycle clock toggle on boot to release hung SDA lines caused by vehicle voltage fluctuations.
* **Dynamic Auto-Zero Baseline**: Continuously adapts to any mounting tilt (windshield, flat dash, center console) using an Exponential Moving Average (EMA).
* **Deadband Filtering**: Discards road surface micro-vibrations ($< 8.0 \text{ m/s}^2$).
* **Edge Anomaly Detection**: Locally evaluates harsh braking, rapid acceleration, sharp turns, and collision shockwaves with hardware debouncing.
* **Dual Wireless Telemetry Delivery**: Emits compressed JSON packets via **BLE GATT Notify** and serves an onboard **HTTP REST Web Server**.

---

### ⚙️ HOW it Works: Low-Level Register Config, DSP Math & Stacks

#### 1. Hardware Pinout & Circuit Schematic
| Sensor Pin | ESP32 GPIO | Electrical Connection | Functional Purpose |
| :--- | :--- | :--- | :--- |
| **VCC** | **3V3 / VIN** | Regulated 3.3V or 5V | Sensor power (GY-521 has onboard XC6206 3.3V LDO) |
| **GND** | **GND** | Common Ground | Reference voltage ground |
| **SCL** | **GPIO 22** | Hardware I2C Clock | Clock synchronization line (40 kHz) |
| **SDA** | **GPIO 21** | Hardware I2C Data | Bi-directional data transfer |
| **AD0** | **GND** | Pulled Low | Hardcodes I2C slave address to `0x68` |
| **INT** | **GPIO 19** | Optional Hardware Interrupt | Instantaneous collision interrupt trigger |
| **Status LED**| **GPIO 2** | Built-in Blue LED | 2-second heartbeat pulse & remote BLE command toggle |

#### 2. Electrical Noise Immunity & I2C Bus Recovery Protocol
Automotive electrical systems produce severe inductive noise (alternator ripple, ignition coils). If the microcontroller resets mid-read, the MPU-6050 can hold the `SDA` line low indefinitely, locking the I2C bus permanently. 

We implemented a hardware clock-pulsing **bus recovery sequence** in C++ before initializing `Wire`:
```cpp
void recoverI2CBus() {
  pinMode(I2C_SDA_PIN, INPUT_PULLUP);
  pinMode(I2C_SCL_PIN, OUTPUT);
  digitalWrite(I2C_SCL_PIN, HIGH);

  // Send up to 9 clock pulses on SCL until the stuck slave releases SDA
  for (int i = 0; i < 9; i++) {
    digitalWrite(I2C_SCL_PIN, LOW);
    delayMicroseconds(10);
    digitalWrite(I2C_SCL_PIN, HIGH);
    delayMicroseconds(10);
    if (digitalRead(I2C_SDA_PIN) == HIGH) break;
  }

  // Generate an explicit I2C STOP condition
  pinMode(I2C_SDA_PIN, OUTPUT);
  digitalWrite(I2C_SDA_PIN, LOW);
  delayMicroseconds(10);
  digitalWrite(I2C_SCL_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(I2C_SDA_PIN, HIGH);
}
```

#### 3. Direct Hardware Register Configuration
Rather than importing heavy generic libraries, the firmware communicates directly with the MPU-6050 over the Wire bus:
```cpp
bool tryInitMPU() {
  // 1. Reset Power Management Register
  Wire.beginTransmission(0x68);
  Wire.write(0x6B); // PWR_MGMT_1 register
  Wire.write(0x80); // Bit 7 = 1 (DEVICE_RESET)
  Wire.endTransmission();
  delay(50);

  // 2. Wake up & Lock Clock Source to PLL with X-Axis Gyroscope
  Wire.beginTransmission(0x68);
  Wire.write(0x6B);
  Wire.write(0x01); // PLL with X gyro reference eliminates internal oscillator drift
  Wire.endTransmission();
  delay(20);

  // 3. Gyroscope Full-Scale Range: +/- 250 deg/sec
  Wire.beginTransmission(0x68);
  Wire.write(0x1B); // GYRO_CONFIG register
  Wire.write(0x00); // FS_SEL = 0 (131.0 LSB per deg/s sensitivity)
  Wire.endTransmission();

  // 4. Accelerometer Full-Scale Range: +/- 16g (High Impact Crash Mode)
  Wire.beginTransmission(0x68);
  Wire.write(0x1C); // ACCEL_CONFIG register
  Wire.write(0x18); // AFS_SEL = 3 (2048.0 LSB per g sensitivity)
  Wire.endTransmission();

  // 5. Digital Low Pass Filter (DLPF): 21 Hz Cutoff
  Wire.beginTransmission(0x68);
  Wire.write(0x1A); // CONFIG register
  Wire.write(0x03); // Bandwidth: Accel 21 Hz, Gyro 20 Hz (Filters road vibration)
  Wire.endTransmission();

  return true;
}
```

#### 4. High-Speed 14-Byte Repeated-Start Burst Read
A single repeated-start I2C transaction reads all 7 sensor dimensions simultaneously:
```cpp
Wire.beginTransmission(0x68);
Wire.write(0x3B);            // ACCEL_XOUT_H register
Wire.endTransmission(false); // Repeated start condition (does NOT release bus)

if (Wire.requestFrom((uint8_t)0x68, (uint8_t)14) == 14) {
    int16_t raw_ax = (Wire.read() << 8) | Wire.read();
    int16_t raw_ay = (Wire.read() << 8) | Wire.read();
    int16_t raw_az = (Wire.read() << 8) | Wire.read();
    int16_t raw_temp = (Wire.read() << 8) | Wire.read();
    int16_t raw_gx = (Wire.read() << 8) | Wire.read();
    int16_t raw_gy = (Wire.read() << 8) | Wire.read();
    int16_t raw_gz = (Wire.read() << 8) | Wire.read();

    // Scale conversion to SI Units (m/s^2 and rad/s)
    ax = (raw_ax / 2048.0) * 9.80665;
    ay = (raw_ay / 2048.0) * 9.80665;
    az = (raw_az / 2048.0) * 9.80665;
    gx = (raw_gx / 131.0) * (PI / 180.0);
    gy = (raw_gy / 131.0) * (PI / 180.0);
    gz = (raw_gz / 131.0) * (PI / 180.0);
    tempC = (raw_temp / 340.0) + 36.53;
}
```

#### 5. Mathematical Signal Processing & Baseline Calibration
1. **Total Acceleration Magnitude**:
   $$G_{\text{mag}} = \frac{\sqrt{a_x^2 + a_y^2 + a_z^2}}{9.80665}$$
2. **Exponential Moving Average (EMA) Baseline Tracking**:
   $$\text{base}_i(t) = 0.98 \cdot \text{base}_i(t-1) + 0.02 \cdot a_i(t), \quad i \in \{x, y, z\}$$
   $$\Delta a_i(t) = a_i(t) - \text{base}_i(t)$$
3. **Deadband Filter**:
   $$\Delta a_i = 0.0 \quad \text{if } |\Delta a_i| < 8.0 \text{ m/s}^2$$

#### 6. Edge Anomaly & Crash Detection Thresholds
```cpp
// 1. Collision Shockwave / Catastrophic Crash (>= 5.0G or Delta >= 38 m/s^2)
if (gMagnitude >= THRESHOLD_CRASH_G || maxDelta >= THRESHOLD_CRASH_DELTA) {
  if (now - lastImpactEvent > 3000) {
    lastImpactEvent = now;
    impactDetected = true;
    Serial.printf("[CRITICAL] 🚨 HUGE COLLISION IMPACT! Magnitude: %.2f G\n", gMagnitude);
  }
}

// 2. Harsh Braking (Forward Dynamic Deceleration > 10.5 m/s^2, 2.0s cooldown)
if ((deltaAy < -THRESHOLD_HARSH_BRAKE || deltaAx < -THRESHOLD_HARSH_BRAKE) && (gMagnitude < THRESHOLD_CRASH_G)) {
  if (now - lastHarshBrakeEvent > 2000) {
    lastHarshBrakeEvent = now;
    harshBrakeCount++;
    Serial.printf("[EVENT] ⚠️ Harsh Braking Detected! Decel: %.2f m/s^2\n", min(deltaAy, deltaAx));
  }
}

// 3. Rapid Acceleration / Launch (Forward Dynamic Surge > 9.8 m/s^2, 2.0s cooldown)
if ((deltaAy > THRESHOLD_RAPID_ACCEL || deltaAx > THRESHOLD_RAPID_ACCEL) && (gMagnitude < THRESHOLD_CRASH_G)) {
  if (now - lastRapidAccelEvent > 2000) {
    lastRapidAccelEvent = now;
    rapidAccelCount++;
    Serial.printf("[EVENT] ⚡ Rapid Launch Detected! Accel: %.2f m/s^2\n", max(deltaAy, deltaAx));
  }
}

// 4. Sharp Cornering Turn (Yaw Angular Velocity > 3.20 rad/s ~ 183 deg/s)
if (abs(gz) > THRESHOLD_SHARP_TURN) {
  if (now - lastSharpTurnEvent > 2000) {
    lastSharpTurnEvent = now;
    sharpTurnCount++;
    Serial.printf("[EVENT] 🔄 Sharp Turn Detected! Yaw Rate: %.2f rad/s\n", gz);
  }
}
```

#### 7. Wireless Telemetry Engine: BLE GATT & Wi-Fi SoftAP
* **BLE GATT Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
* **Telemetry TX Characteristic (Notify)**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
  * Emits 20 Hz compact JSON:
    `{"ax":0.12,"ay":-0.05,"az":9.81,"gx":0.01,"gy":-0.02,"gz":0.00,"gMag":1.00,"temp":27.2,"imp":0,"hb":2,"ra":1,"st":0,"sc":1}`
* **Command RX Characteristic (Write)**: `beb5483e-36e1-4688-b7f5-ea07361b26a9` (Accepts `LED_TOGGLE`).
* **Wi-Fi SoftAP (Fallback)**: SSID `SmartDrive-Sensor-Node`, WPA2 Pass `SmartDrive2026!`, Gateway IP `http://192.168.4.1`.
  * `GET /api/v1/device/status` (Health, uptime, free heap).
  * `GET /api/v1/telemetry/latest` (Live snapshot).
  * `POST /api/v1/device/led` (Remote diagnostic control).

---

## 🐍 Pillar 2: Python (FastAPI AI Microservice)

* **Source Directory**: [`backend/app`](file:///c:/projects/Major_project/backend/app)
* **Scoring Logic**: [`backend/app/services/score_service.py`](file:///c:/projects/Major_project/backend/app/services/score_service.py)
* **Crash Forensics**: [`backend/app/services/crash_service.py`](file:///c:/projects/Major_project/backend/app/services/crash_service.py)

### 🎯 WHY Python & FastAPI?
1. **Mathematical & Data Science Native**: Python is the premier environment for numerical vector algebra, kinematics modelling, and future integration with scikit-learn or PyTorch anomaly detection models.
2. **Asynchronous ASGI Performance**: FastAPI running on **Uvicorn** handles asynchronous request loops with minimal overhead, easily processing thousands of trip evaluation requests concurrently.
3. **Pydantic Validation**: Automatically validates incoming telemetry payload schemas with native Python type hints, preventing malformed data errors.
4. **Self-Documenting API**: Automatically generates interactive OpenAPI/Swagger interfaces at `/docs`.

---

### 📦 WHAT the Python AI Engine Does
* **Multi-Factor Trip Scoring**: Ingests trip event logs and raw GPS point streams, calculating a calibrated **0–100 Driver Safety Score** and **0–100 Risk Index**.
* **Kinetic Crash Forensics**: Decomposes vehicular crash telemetry, computing speed changes ($\Delta V$), impact directionality, and structural **Crush Deformation Indices**.
* **Driver Behavior Classification**: Categorizes drivers into `CONSERVATIVE`, `BALANCED`, or `AGGRESSIVE`.
* **Gamification & Rewards**: Calculates driver XP rewards and unlocks achievement badges (`smooth_operator`, `speed_sentinel`, `focus_champion`).

---

### ⚙️ HOW it Works: Scoring Math, Delta-V & Crash Forensics

#### 1. Dynamic Trip Safety & Risk Scoring
When a trip completes, the backend passes all logged events and GPS breadcrumbs to [`score_service.py`](file:///c:/projects/Major_project/backend/app/services/score_service.py):

$$\text{Safety Score} = \max\left(0.0, \min\left(100.0, 100 - \sum (w_i \cdot c_i)\right)\right)$$
$$\text{Risk Score} = \max\left(0.0, \min\left(100.0, \sum (r_i \cdot c_i)\right)\right)$$

| Violation Type | Safety Deduction ($w_i$) | Risk Addition ($r_i$) | Trigger Criteria |
| :--- | :--- | :--- | :--- |
| **Harsh Braking** | $-3 \text{ pts}$ | $+4 \text{ pts}$ | Forward Decel $> 10.5 \text{ m/s}^2$ or GPS deriv $<-3.0 \text{ m/s}^2$ |
| **Rapid Acceleration**| $-2 \text{ pts}$ | $+3 \text{ pts}$ | Forward Surge $> 9.8 \text{ m/s}^2$ or GPS deriv $>+3.0 \text{ m/s}^2$ |
| **Overspeeding** | $-4 \text{ pts}$ | $+5 \text{ pts}$ | GPS Speed $> \text{Speed Limit} + 10 \text{ km/h}$ |
| **Sharp Turning** | $-3 \text{ pts}$ | $+4 \text{ pts}$ | Angular Yaw Velocity $> 3.20 \text{ rad/s}$ |
| **Phone Usage** | $-8 \text{ pts}$ | $+12 \text{ pts}$ | Mobile screen unlock / interaction while speed $> 15 \text{ km/h}$ |
| **Catastrophic Crash** | $-50 \text{ pts}$ | $+80 \text{ pts}$ | Peak $G \ge 5.0G$ or sudden $\Delta \ge 38 \text{ m/s}^2$ |

* **Fallback GPS Derivative Engine**: If hardware sensor events are missing, the AI engine calculates acceleration between consecutive GPS points:
  $$a = \frac{V_t - V_{t-1}}{\Delta t}$$

#### 2. Collision Dynamics & Crush Deformation Forensics
In [`crash_service.py`](file:///c:/projects/Major_project/backend/app/services/crash_service.py):
1. **Delta-V Calculation**:
   $$\Delta V = \max(0.0, V_{\text{before}} - V_{\text{after}})$$
2. **Crush Deformation Energy Index**:
   $$I_{\text{crush}} = \frac{\Delta V \times G_{\text{max}}}{10.0}$$
3. **Impact Vector Classification**:
   $$\text{Axis} = \begin{cases} \text{Longitudinal (Front/Rear Impact)}, & \text{if } g_x > g_y \\ \text{Lateral (Side-Swipe / Rollover)}, & \text{if } g_y \ge g_x \end{cases}$$
4. **Calibrated Severity & Probability**:
   * **Catastrophic**: $G_{\text{max}} \ge 5.5G \lor (\Delta V \ge 35 \text{ km/h} \land G_{\text{max}} \ge 4.0G) \rightarrow P_{\text{crash}} = 0.98$
   * **High Impact**: $G_{\text{max}} \ge 4.0G \lor (\Delta V \ge 20 \text{ km/h} \land G_{\text{max}} \ge 3.0G) \rightarrow P_{\text{crash}} = 0.88$
   * **Moderate Collision**: $G_{\text{max}} \ge 2.5G \rightarrow P_{\text{crash}} = 0.65$
   * **Filtered Anomaly**: Sub-threshold jolt $\rightarrow P_{\text{crash}} = 0.25$

---

## 🟢 Pillar 3: Node.js, Express & TypeScript (API Gateway & Data Pipeline)

* **Source Directory**: [`backend/src`](file:///c:/projects/Major_project/backend/src)
* **Schema Definition**: [`backend/src/prisma/schema.prisma`](file:///c:/projects/Major_project/backend/src/prisma/schema.prisma)
* **Real-time Sockets**: [`backend/src/sockets/socket.manager.ts`](file:///c:/projects/Major_project/backend/src/sockets/socket.manager.ts)

### 🎯 WHY Node.js & TypeScript?
1. **Event-Driven Non-Blocking I/O**: Designed specifically to handle thousands of concurrent, long-lived WebSocket connections streaming vehicle coordinates without thread exhaustion.
2. **Type-Safe Clean Architecture**: TypeScript eliminates type mismatches between REST controllers, database models, and client payloads at compile time.
3. **Ecosystem Synergy**: Unmatched developer tools including Prisma ORM for database migrations, BullMQ for Redis task queues, Zod for runtime schema validation, and Winston for structured logging.

---

### 📦 WHAT the API Gateway Does
* **Enterprise Identity & Security**: Dual-token JWT authentication (15-min Access Token, 7-day Refresh Token with rotation) and Role-Based Access Control (`SUPER_ADMIN`, `FLEET_ADMIN`, `MANAGER`, `DRIVER`).
* **Relational Fleet Management**: Manages organizations, users, vehicles, drivers, trips, maintenance logs, and emergency reports.
* **Real-Time Telemetry Relay**: Maintains authenticated Socket.IO rooms, broadcasting vehicle GPS updates and emergency crash alerts with sub-50ms latency.
* **Asynchronous BullMQ Task Queue**: Offloads heavy report generation and background AI reviews to Redis worker threads without blocking API responsiveness.
* **Automated Operational Exports**: Generates official PDF inspection reports (PDFKit) and analytics spreadsheets (ExcelJS).

---

### ⚙️ HOW it Works: Clean Architecture, Sockets, BullMQ & Prisma

#### 1. Layered Clean Architecture
```text
HTTP / WebSocket Request
        ↓
[Security Headers (Helmet) & Rate Limiting]
        ↓
[Authentication Middleware: Bearer JWT & Organization Verification]
        ↓
[Validation Middleware: Zod Schema Parsing]
        ↓
[Controller Layer: HTTP Status Codes & Error Formatting]
        ↓
[Service Layer: Core Business Logic & Orchestration]
        ↓
[Repository Layer: Prisma ORM Query Builders]
        ↓
[PostgreSQL Database & Redis Cache]
```

#### 2. PostgreSQL 14-Table Relational Schema
Defined in [`schema.prisma`](file:///c:/projects/Major_project/backend/src/prisma/schema.prisma):
* **`Organization`**: Multi-tenant enterprise tenant isolation.
* **`User` & `Driver`**: User credentials, driving license details, safety ratings, and earned XP.
* **`Vehicle`**: Vehicle fleet records, VIN, and hardware sensor node mappings.
* **`Trip`**: Start/end timestamps, polyline summary, distance, and safety score.
* **`TelemetryPoint`**: High-frequency GIS points `(tripId, latitude, longitude, speed, heading, altitude, timestamp)`.
  * **Optimized B-Tree Index**: `@@index([tripId, timestamp])` guarantees sub-millisecond query execution over millions of location breadcrumbs.
* **`Event`**: Infractions (`HARSH_BRAKING`, `RAPID_ACCELERATION`, `SHARP_TURN`, `OVERSPEED`, `PHONE_USAGE`).
* **`CrashReport`**: Critical collision records with impact force, Delta-V, and investigation summaries.

#### 3. Real-Time Socket.IO Telemetry Engine
In [`socket.manager.ts`](file:///c:/projects/Major_project/backend/src/sockets/socket.manager.ts):
```typescript
// 1. Client joins organization fleet room
socket.on("join_fleet_room", (orgId: string) => {
  socket.join(`org_${orgId}`);
});

// 2. Driver emits real-time location
socket.on("gps_update", (data: TelemetryPayload) => {
  // Broadcast location instantly to all connected admin dashboards
  io.to(`org_${data.organizationId}`).emit("vehicle_location_updated", {
    vehicleId: data.vehicleId,
    driverId: data.driverId,
    lat: data.latitude,
    lng: data.longitude,
    speed: data.speed,
    heading: data.heading,
    timestamp: new Date()
  });
});

// 3. Emergency Collision Shockwave Alert
socket.on("crash_alert", (data: CrashAlertPayload) => {
  io.to(`org_${data.organizationId}`).emit("emergency_crash_broadcast", {
    ...data,
    urgent: true,
    alarmSound: "EMERGENCY_SIREN_LVL_1"
  });
});
```

---

## 💻 Pillar 4: Frontend Architecture (React 18 Dashboard & Flutter Mobile)

* **Admin Dashboard**: [`dashboard/src`](file:///c:/projects/Major_project/dashboard/src)
* **Driver Web Portal**: [`web/driver-dashboard/src`](file:///c:/projects/Major_project/web/driver-dashboard/src)
* **Mobile App**: [`MobileApp/lib`](file:///c:/projects/Major_project/MobileApp/lib)

### 🎯 WHY React 18 & Flutter?
* **React 18 + Vite (Fleet Command HUD)**:
  1. **Instant Hot Module Replacement (HMR)**: Sub-100ms developer build feedback loops.
  2. **High-Performance Canvas Rendering**: Renders dozens of animated vehicle markers on Leaflet GIS maps at 60 FPS without DOM lag.
  3. **Modular State & Hooks**: Custom hooks (`useSocketDrivers`, `SocketContext`) cleanly isolate WebSocket telemetry updates from UI presentation.
* **Flutter 3.x (Mobile Driver Client)**:
  1. **Cross-Platform Native Code**: Single Dart codebase compiling to native ARM machine code on Android and iOS.
  2. **Direct Hardware Access**: Low-level platform channels communicate directly with smartphone Bluetooth LE hardware (`flutter_blue_plus`) and IMU sensors (`sensors_plus`).
  3. **High-FPS HUD**: Hardware-accelerated Skia/Impeller graphics engine renders fluid radar scanner sweeps and real-time G-force dials.

---

### 📦 WHAT the Client Portals Do
1. **Fleet Command Dashboard (`dashboard`)**:
   * **Live GIS Fleet Map**: Animated vehicle markers, vehicle bearing rotation, live speed compliance indicators, and route replays.
   * **Driver Safety Ranking**: Real-time leaderboards sorting drivers by safety score, risk level, and incident counts.
   * **Crash Emergency Center**: Dedicated incident management view with audio/visual sirens, impact severity ratings, and emergency dispatch workflows.
2. **Driver Web Portal (`web/driver-dashboard`)**:
   * Driver self-service portal for reviewing trip histories, route heatmaps, safety scores, and eco-driving tips.
3. **Flutter Mobile Application (`MobileApp`)**:
   * In-cabin driver HUD with start/end trip controls.
   * Interactive **BLE Radar Scanner** discovering and pairing ESP32 sensor nodes.
   * Road Rules Engine checking current vehicle speed against OpenStreetMap speed limits.
   * Collision SOS trigger broadcasting emergency crash packets over WebSockets.

---

### ⚙️ HOW it Works: State Management, GIS Maps & Radar Scanner

#### 1. React Real-Time WebSocket Driver Hook
In [`useSocketDrivers.ts`](file:///c:/projects/Major_project/dashboard/src/hooks/useSocketDrivers.ts):
```typescript
export const useSocketDrivers = () => {
  const [drivers, setDrivers] = useState<Map<string, LiveDriver>>(new Map());
  const { socket } = useSocket();

  useEffect(() => {
    if (!socket) return;

    socket.on("vehicle_location_updated", (data: LiveDriverLocation) => {
      setDrivers((prev) => {
        const next = new Map(prev);
        next.set(data.vehicleId, {
          ...next.get(data.vehicleId),
          ...data,
          lastPing: Date.now()
        });
        return next;
      });
    });

    return () => {
      socket.off("vehicle_location_updated");
    };
  }, [socket]);

  return { activeDrivers: Array.from(drivers.values()) };
};
```

#### 2. Flutter ESP32 Radar Scanner & Telemetry Parser
In [`esp32_service.dart`](file:///c:/projects/Major_project/MobileApp/lib/services/esp32_service.dart):
* **BLE Filtering**: Scans for peripherals advertising `SmartDrive-Sensor-Node`.
* **Signal Strength Meter**: Live RSSI calculation displaying `🟢 -45 to -60 dBm` for nearby sensors.
* **Persistent Bookmarking ("MY SENSOR")**: Drivers pin their specific sensor MAC address to auto-reconnect on trip start.
* **20 Hz Stream Subscription**: Listens to BLE Characteristic `beb5483e-36e1-4688-b7f5-ea07361b26a8`, decoding incoming JSON telemetry into `Esp32DeviceStatus` models:
```dart
_telemetrySub = characteristic.onValueReceived.listen((value) {
  final jsonString = utf8.decode(value);
  final data = json.decode(jsonString);
  final status = Esp32DeviceStatus.fromBleJson(data);
  _telemetryStreamController.add(status);
});
```

---

## 🐳 Pillar 5: Docker & Infrastructure (PostgreSQL 15 & Redis 7)

* **Configuration**: [`backend/docker-compose.yml`](file:///c:/projects/Major_project/backend/docker-compose.yml)

### 🎯 WHY Docker Containerization?
1. **Environment Parity**: Guarantees identical database and cache runtimes across Windows, Linux, and macOS development environments, eliminating *"works on my machine"* anomalies.
2. **Isolated Networking**: Establishes an internal bridge network (`smartdrive-network`) where containers discover each other via DNS service names (`db`, `redis`, `app`).
3. **Data Persistence**: Named Docker volumes prevent database and cache wipeouts across container restarts.

---

### 📦 WHAT the Container Stack Orchestrates
* **`db` (PostgreSQL 15 Alpine)**: Relational database engine on port `5432` with named volume `pgdata`.
* **`redis` (Redis 7 Alpine)**: High-speed in-memory data store on port `6379` powering session states and BullMQ queues with named volume `redisdata`.
* **`app` (SmartDrive Backend)**: Node.js/Express production container on port `3000` connected to `db` and `redis`.

---

### ⚙️ HOW it Works: compose Services, Networks & Volumes

#### `docker-compose.yml` Architecture:
```yaml
services:
  # 1. PostgreSQL 15 Database Container
  db:
    image: postgres:15-alpine
    container_name: smartdrive-postgres
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: smartdrive_db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - smartdrive-network

  # 2. Redis 7 Cache & BullMQ Queue Container
  redis:
    image: redis:7-alpine
    container_name: smartdrive-redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data
    networks:
      - smartdrive-network

  # 3. Node.js Production Backend Container
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: smartdrive-backend
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/smartdrive_db?schema=public
      - REDIS_URL=redis://redis:6379
      - JWT_ACCESS_SECRET=super-secret-access-key-smartdrive-ai-2026
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
      - /app/node_modules
      - uploads-data:/app/uploads
    networks:
      - smartdrive-network

volumes:
  pgdata:
    driver: local
  redisdata:
    driver: local
  uploads-data:
    driver: local

networks:
  smartdrive-network:
    driver: bridge
```

---

## 📂 Monorepo Directory Structure & File Map

```text
Major_project/
├── hardware/
│   └── SmartDrive_ESP32_Node/
│       └── SmartDrive_ESP32_Node.ino         # Standalone C++ ESP32 firmware
├── hardware_esp32/
│   ├── WIRING_AND_SETUP_GUIDE.md             # Complete pinout & electrical guide
│   └── smartdrive_esp32_sensor/
│       └── smartdrive_esp32_sensor.ino       # C++ ESP32 Telematics Firmware (v3.7.0)
├── backend/
│   ├── app/                                  # Python FastAPI AI Microservice (Port 5000)
│   │   ├── api/routes/ai.py                  # AI routes (/evaluate-trip, /crash-summary)
│   │   ├── services/score_service.py         # Multi-factor trip scoring mathematics
│   │   ├── services/crash_service.py         # Crash forensics & crush deformation index
│   │   └── main.py                           # FastAPI ASGI entrypoint
│   ├── src/                                  # Node.js Express Gateway (Port 3000)
│   │   ├── controllers/                      # Auth, Driver, Vehicle, Trip, Event, Crash
│   │   ├── database/client.ts                # Prisma client singleton
│   │   ├── jobs/queue.ts                     # BullMQ Redis task queues
│   │   ├── middleware/auth.middleware.ts     # Dual JWT token & RBAC guards
│   │   ├── prisma/schema.prisma              # 14-table PostgreSQL schema
│   │   ├── prisma/seed.ts                    # Production database seeding script
│   │   ├── routes/index.ts                   # Centralized API route declarations
│   │   ├── sockets/socket.manager.ts         # Real-time Socket.IO room broadcaster
│   │   └── server.ts                         # Server bootstrap & WebSocket bind
│   ├── docker-compose.yml                    # PostgreSQL 15 & Redis 7 container orchestration
│   ├── package.json                          # Node.js dependencies
│   └── requirements.txt                      # Python AI dependencies
├── dashboard/                                # React 18 Fleet Command Center (Port 5173)
│   ├── src/
│   │   ├── components/                       # FleetMap, ScoreChart, EventTable, Sidebar
│   │   ├── hooks/useSocketDrivers.ts         # Live WebSocket driver hook
│   │   ├── pages/LiveMap.tsx                 # Real-time GIS fleet tracking map
│   │   ├── pages/Dashboard.tsx               # Executive KPI dashboard
│   │   └── App.tsx                           # Route declarations & themes
│   └── package.json                          # React dependencies
├── web/driver-dashboard/                     # React Driver Web Portal (Port 5174)
│   └── src/pages/DashboardHome.jsx           # Driver self-service trip summaries & scores
├── MobileApp/                                # Flutter Mobile Client
│   ├── lib/
│   │   ├── providers/trip_provider.dart      # Active trip lifecycle state
│   │   ├── screens/radar_screen.dart         # ESP32 BLE Radar Scanner UI
│   │   ├── services/esp32_service.dart       # BLE GATT & Wi-Fi communication
│   │   └── services/socket_service.dart      # Real-time mobile WebSocket connection
│   └── pubspec.yaml                          # Flutter dependencies
├── run_system.bat                            # Master 1-click launcher for all services
├── run_backend_only.bat                      # Standalone Backend + FastAPI launcher
├── run_dashboard_only.bat                    # Standalone React Dashboard launcher
├── run_mobile_only.bat                       # Standalone Flutter Mobile launcher
├── PROJECT_DETAILS.md                        # Exhaustive Architecture & Tech Guide (This file)
└── README.md                                 # Original Project Overview
```

---

## ⚡ Step-by-Step Installation, Flashing & Operational Runbook

### Prerequisites
* **Node.js**: `v20.x` or `v22.x LTS`
* **Python**: `3.10+` or `3.11+`
* **Docker Desktop**: Running with WSL2 backend
* **Flutter SDK**: `3.22+` with Android Studio / SDK tools
* **Arduino IDE**: `v2.x` with Espressif ESP32 board support

---

### 1. Hardware Assembly & Flashing the ESP32 Node
1. Wire the **MPU-6050** to the **ESP32** according to the [Wiring Table](#1-hardware-pinout--circuit-schematic).
2. Open **Arduino IDE**, navigate to [`hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino).
3. Board Settings:
   * **Board**: `ESP32 Dev Module` (or `DOIT ESP32 DEVKIT V1`)
   * **Upload Speed**: `921600`
   * **Partition Scheme**: `Default 4MB with spiffs` (or `Huge APP 3MB` if using `MODE_DUAL`)
4. Connect the board via USB, select your COM port, and click **Upload**.
5. Open Serial Monitor at **`115200 baud`** to verify initialization.

---

### 2. Full System 1-Click Launch (Windows)
From the project root, run:
```bash
.\run_system.bat
```
*This launches PostgreSQL & Redis via Docker, generates the Prisma client, starts the Node.js API Gateway (port 3000), starts the Python FastAPI AI Microservice (port 5000), starts the React Fleet Command Center (port 5173), starts the React Driver Portal (port 5174), and launches the Flutter mobile app via ADB reverse.*

---

### 3. Manual Step-by-Step Execution

#### Step A: Infrastructure Setup
```bash
cd backend
# 1. Start PostgreSQL and Redis containers
docker-compose up -d db redis

# 2. Run database migrations and seed default data
npx prisma migrate dev --schema=src/prisma/schema.prisma
npm run db:seed
```

#### Step B: Launch Node.js API Gateway (Port 3000)
```bash
cd backend
npm install
npm run dev
# Health check: http://localhost:3000/api/v1/health
# Swagger Docs: http://localhost:3000/api-docs
```

#### Step C: Launch Python FastAPI AI Microservice (Port 5000)
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate       # Linux/macOS: source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
# Health check: http://localhost:5000/health
# Interactive Docs: http://localhost:5000/docs
```

#### Step D: Launch React Fleet Command Dashboard (Port 5173)
```bash
cd dashboard
npm install
npm run dev
# Access HUD: http://localhost:5173
```

#### Step E: Launch Flutter Mobile Application
```bash
cd MobileApp
# Forward host ports to connected Android device / emulator
adb reverse tcp:3000 tcp:3000
adb reverse tcp:5000 tcp:5000

flutter pub get
flutter run
```

---

## 🔐 Environment Variables Reference

### Backend Gateway (`backend/.env`)
```ini
# Application Port & Mode
NODE_ENV=development
PORT=3000

# PostgreSQL Prisma Connection String
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/smartdrive_db?schema=public"

# Redis In-Memory Cache
REDIS_URL="redis://localhost:6379"

# JWT Authentication Secrets
JWT_ACCESS_SECRET="super-secret-access-key-smartdrive-ai-2026"
JWT_REFRESH_SECRET="super-secret-refresh-key-smartdrive-ai-2026"
JWT_ACCESS_EXPIRY="15m"
JWT_REFRESH_EXPIRY="7d"

# Python FastAPI AI Microservice URL
AI_SERVICE_URL="http://127.0.0.1:5000"

# CORS Permitted Origins
CORS_ORIGIN="http://localhost:5173,http://localhost:5174"
```

---

## 👥 Academic Project Credits

Developed as a final year **Major Project** for the degree of **Bachelor of Engineering in Computer Science and Engineering (Data Science)**.

* **Institution**: **Vivekananda College of Engineering & Technology (VCET)**, Puttur, Karnataka, India.
* **Project Guide**: **Prof. Roopa G K**, Assistant Professor, Dept. of CSE (Data Science).
* **Project Team Members**:
  * **Mohammed Afzal** — *Team Lead & Architecture*
  * **Pranav K U** — *Embedded Systems, IoT Telematics & Firmware*
  * **Sujay S G** — *Backend Architecture & Database Pipelines*
  * **Gagan Deep P K** — *Command Dashboard & Mobile Engineering*

---

## 📄 License

Distributed under the **MIT License**. Created for academic demonstration, smart city transportation research, and commercial fleet telematics prototyping.
