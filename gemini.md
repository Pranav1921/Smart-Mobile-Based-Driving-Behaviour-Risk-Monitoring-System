# 🚗 Smart Mobile-Based Driving Behaviour & Risk Monitoring System
> **Comprehensive System Context Document for AI Reasoning & Analysis**  
> *Repository: `Major_project` (Smart Mobile-Based Driving Behaviour and Risk Monitoring System)*  
> *Target Frameworks: ESP32 C++ (Embedded), Flutter 3.x (Dart), Node.js v20+ / Express / TypeScript (Gateway), Python 3.10+ / FastAPI (AI Engine), React 18 / Vite / TailwindCSS (Web Portals), Docker / PostgreSQL 15 / Redis 7 (Infrastructure).*

---

## 📑 Table of Contents
1. [Project Overview & Architectural Vision](#1-project-overview--architectural-vision)
2. [Monorepo Directory & File Structure](#2-monorepo-directory--file-structure)
3. [Key Configuration Parameters & Environment Variables](#3-key-configuration-parameters--environment-variables)
4. [Complete Codebase Endpoints Catalog (REST APIs)](#4-complete-codebase-endpoints-catalog-rest-apis)
5. [Real-Time WebSocket / Socket.IO Telemetry & Event Engine](#5-real-time-websocket--socketio-telemetry--event-engine)
6. [Database Schema & Data Pipeline (Prisma ORM & PostgreSQL)](#6-database-schema--data-pipeline-prisma-orm--postgresql)
7. [Frontend Applications & Client Portals](#7-frontend-applications--client-portals)
8. [Mobile Application Architecture (Flutter)](#8-mobile-application-architecture-flutter)
9. [Embedded Hardware Node & Firmware Architecture (ESP32 C++)](#9-embedded-hardware-node--firmware-architecture-esp32-c)
10. [Operational Runbook & Launcher Scripts](#10-operational-runbook--launcher-scripts)

---

## 1. Project Overview & Architectural Vision

### 1.1 Academic & Technical Identity
* **Project Title**: Smart Mobile-Based Driving Behaviour and Risk Monitoring System (FleetGuard / SmartDrive).
* **Degree / Discipline**: Bachelor of Engineering in Computer Science & Engineering (Data Science).
* **Institution**: Vivekananda College of Engineering & Technology (VCET), Puttur, Karnataka, India.
* **Faculty Guide**: Prof. Roopa G K, Department of CSE (Data Science).
* **Engineering Objective**: Deliver an affordable, enterprise-grade telematics, collision forensics, and driver safety ecosystem using low-cost hardware ($6 ESP32 + MPU-6050) coupled with commodity smartphones, eliminating the need for expensive CAN-bus or OBD-II dongles ($300–$800).

### 1.2 The 3-Tier Distributed Synergy
```text
+-----------------------------------+
|      TIER 1: THE EDGE SENSOR      |  --> ESP32 + MPU-6050 Hardware Node
|     (Inertial Physics Engine)     |      Deterministic 20 Hz C++ sampling, +/-16g collision shockwave capture,
+-----------------------------------+      auto-zero tilt baseline leveling, and road deadband filtering.
                  |
                  | BLE GATT Notify (20 Hz, 50ms) or Wi-Fi SoftAP Fallback
                  v
+-----------------------------------+
|     TIER 2: THE MOBILE CLIENT     |  --> Flutter Mobile Application (Android / iOS)
|     (Context & Communications)    |      Acquires GPS coordinates, queries OpenStreetMap road speed limits,
+-----------------------------------+      provides voice TTS & haptic warnings, and acts as 4G/5G cloud relay.
                  |
                  | HTTPS REST (State/Auth) & WebSockets (Sub-50ms Telemetry Stream)
                  v
+-----------------------------------+
|      TIER 3: THE CLOUD BACKEND    |  --> Node.js / TypeScript Gateway + Python FastAPI AI Microservice
|      (Forensics & Fleet Control)  |      PostgreSQL 15 (14 tables), Redis 7 (BullMQ), React 18 Admin HUD,
+-----------------------------------+      and React Operator Self-Service Dashboard.
```

### 1.3 Smartphone-Only vs. ESP32 Hybrid Rationale
1. **Mechanical Coupling**: Phones shift, tumble across seats, or rattle on air-vent clips. Picking up the phone produces spurious $2.5g–3.5g$ lateral surges, resulting in high false-positive rates for harsh braking and swerving. The ESP32 node is rigidly fixed to the vehicle chassis.
2. **Dynamic Range & Shockwave Saturation**: Smartphone accelerometers are configured to $\pm 2g$ or $\pm 4g$ for human activity (steps, screen orientation). High-velocity vehicle crashes reach $10g–16g+$ in under 30 milliseconds; phone sensors clip/saturate, losing peak kinetic deformation data. The ESP32 registers are set to Full Scale Range $\pm 16g$ ($2048.0\text{ LSB}/g$).
3. **OS Doze Mode & Background Throttling**: Android Doze and iOS background execution limits throttle high-frequency sensor callbacks from 50 Hz to 1 Hz or suspend them entirely when the screen turns off. The ESP32 runs a deterministic, unthrottled 20 Hz (50 ms) edge loop.
4. **Thermal Stability & Battery**: Running continuous high-frequency IMU reads alongside GPS, screen rendering, and 4G streaming induces severe phone overheating and thermal shutdown on sunny dashboards. Offloading kinematic math to the ESP32 preserves phone battery and prevents overheating.
5. **Vehicle Fleet Permanence**: In logistics and shared fleets, multiple drivers rotate shifts. The ESP32 sensor remains permanently mapped to the vehicle chassis (persistent ID `SD-ESP32-001`), recording vehicle crash history independent of individual driver phones.

---

## 2. Monorepo Directory & File Structure

```text
Major_project/
├── backend/                                   # Backend Monorepo Services
│   ├── app/                                   # Python FastAPI AI Microservice (Port 5000)
│   │   ├── api/routes/ai.py                   # AI Endpoints (/evaluate-trip, /generate-crash-summary)
│   │   ├── core/config.py                     # Microservice Settings & Environment Configuration
│   │   ├── services/
│   │   │   ├── score_service.py               # Safety Score (0-100), Risk Index, Gamification XP
│   │   │   └── crash_service.py               # Delta-V Forensics & Crush Deformation Index Math
│   │   ├── schemas/                           # Pydantic Request/Response Models
│   │   └── main.py                            # FastAPI ASGI Application Bootstrap
│   ├── src/                                   # Node.js / Express / TypeScript Gateway (Port 3000)
│   │   ├── config/                            # Environment config, Winston logger, Redis options
│   │   ├── controllers/                       # Auth, Driver, Vehicle, Trip, Event, Crash, Report, Order, Alert
│   │   ├── database/client.ts                 # Prisma Client Singleton Instance
│   │   ├── docs/swagger.ts                    # OpenAPI / Swagger Specification Configuration
│   │   ├── jobs/                              # BullMQ Background Task Queues & Workers (Redis)
│   │   ├── middleware/                        # Dual-JWT Auth, Role-Based Access Control, Validation, Auditing
│   │   ├── prisma/
│   │   │   ├── schema.prisma                  # 14-Table Relational PostgreSQL Schema & Enums
│   │   │   └── seed.ts                        # Database Seeding Script (Admin, Drivers, Vehicles)
│   │   ├── repositories/                      # Encapsulated Database Query Repositories
│   │   ├── routes/                            # Centralized Express Route Declarations
│   │   │   ├── auth.routes.ts                 # Registration, login, driver application & verification
│   │   │   ├── driver.routes.ts               # Driver profiles, license approval, leaderboards
│   │   │   ├── vehicle.routes.ts              # Vehicle registry, assignments, maintenance status
│   │   │   ├── trip.routes.ts                 # Trip lifecycle (start, location point, complete)
│   │   │   ├── event.routes.ts                # Harsh event logging & historical queries
│   │   │   ├── crash.routes.ts                # Collision intake, status transitions, media uploads
│   │   │   ├── report.routes.ts               # PDFKit/ExcelJS exports, municipal pothole data
│   │   │   ├── order.routes.ts                # Logistics delivery order creation & driver dispatch
│   │   │   ├── alert.routes.ts                # Vibration alerts, emergency simulations
│   │   │   ├── anomaly.routes.ts              # Spatial pothole clustering, high-frequency evidence
│   │   │   └── index.ts                       # Top-level API router mounting
│   │   ├── services/                          # Business Logic Services (Auth, Trip, Discovery, etc.)
│   │   ├── sockets/
│   │   │   └── socket.manager.ts              # Real-Time Socket.IO Telemetry Engine & In-Memory Store
│   │   ├── app.ts                             # Express App Initialization, Middleware & Static Mounts
│   │   └── server.ts                          # HTTP Server Bootstrap, Sockets Binding & UDP Discovery
│   ├── docker/                                # Dockerfile configurations for container deployment
│   ├── docker-compose.yml                     # PostgreSQL 15 & Redis 7 Container Orchestration
│   ├── orders.json                            # Local Persistent Logistics Orders Database
│   ├── package.json                           # Gateway Node.js Dependencies & NPM Scripts
│   ├── requirements.txt                       # Python FastAPI Dependencies
│   └── tsconfig.json                          # TypeScript Compiler Configuration
│
├── dashboard/                                 # React 18 Admin Fleet Command Center (Port 5173)
│   ├── src/
│   │   ├── components/                        # UI Components (Sidebar, Modals, Tables, Cards)
│   │   │   ├── layout/AppShell.tsx            # Navigation Shell & Header Bar
│   │   │   ├── drivers/                       # Driver Detail Modal, Candidate Onboarding Dossier
│   │   │   └── fleet/                         # Fleet Map with Leaflet GIS Markers & Rotating Bearings
│   │   ├── hooks/
│   │   │   ├── SocketContext.tsx              # Centralized Socket.IO Provider with Incident Banners
│   │   │   └── useSocketDrivers.ts            # Live Driver Telemetry State Hook
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx                  # Executive Fleet Overview & KPI Stats
│   │   │   ├── LiveMap.tsx                    # Real-Time GIS Fleet Tracking Map & Geofence Visualizer
│   │   │   ├── Drivers.tsx                    # Driver Management, Safety Leaderboard & XP Leveling
│   │   │   ├── Requests.tsx                   # Driver Onboarding Applications Review & Parivahan DL Verification
│   │   │   ├── Orders.tsx                     # Mission Logistics Dispatch & Driver Job Assignment
│   │   │   ├── Events.tsx                     # Telemetry Infractions Log (Braking, Accel, Turn, Speed)
│   │   │   ├── Reports.tsx                    # Analytics Visualizations & PDF/Excel Export Center
│   │   │   ├── CrashInvestigation.tsx         # Emergency Forensic Center (Delta-V, Crush Index, Black Box)
│   │   │   ├── Profile.tsx                    # Organization Profile & Settings
│   │   │   ├── LoginPage.tsx                  # Admin Portal Authentication
│   │   │   └── PublicLiveTrack.tsx            # Standalone Public Tracking URL for Shared Shipments
│   │   ├── types/index.ts                     # TypeScript Interfaces for Fleet, Telemetry & Incidents
│   │   ├── App.tsx                            # Root React Component, Route Registry & Global Emergency HUD
│   │   └── main.tsx                           # React DOM Entrypoint
│   ├── package.json                           # Dashboard Dependencies (Vite 6, TailwindCSS 4, Leaflet)
│   └── vite.config.ts                         # Vite Build & Dev Server Configuration
│
├── web/
│   ├── driver-dashboard/                      # React Driver Self-Service Web Portal (Port 5174)
│   │   ├── src/
│   │   │   ├── pages/DashboardHome.jsx        # Operator Trip Summaries, Eco-Driving Scores & Leaderboard
│   │   │   ├── pages/DriversPage.jsx          # Operator Colleagues & Ranking
│   │   │   ├── pages/TripsPage.jsx            # Personal Historic Trip Polylines & Statistics
│   │   │   ├── pages/EventsPage.jsx           # Individual Driving Infraction Review
│   │   │   ├── pages/HeatmapPage.jsx          # Regional Road Hazard & Pothole Heatmap
│   │   │   └── pages/ReportsPage.jsx          # Monthly Safety Summaries
│   │   └── package.json                       # Driver Portal Dependencies (Vite, TailwindCSS)
│   ├── order-dispatch/                        # Dispatcher Quick Portal (`/dispatch`)
│   │   └── index.html                         # Standalone Logistics Dispatch Utility for Generating Consignments
│   └── orders-client/                         # Public Customer Orders & Live Status Client (`/orders-client`)
│       └── index.html                         # Indian Swadeshi Delivery Tracking Interface
│
├── MobileApp/                                 # Flutter Mobile Client (Android & iOS)
│   ├── lib/
│   │   ├── core/constants/app_urls.dart       # IP Fallbacks (Tailscale Mesh, Wi-Fi, ADB Loopback)
│   │   ├── models/                            # Dart Models (DriverProfile, TripModel, DeliveryOrder, Esp32Status)
│   │   ├── providers/                         # State Management Providers (TripProvider, LocationProvider)
│   │   ├── screens/
│   │   │   ├── splash_screen.dart             # Animated Launch & Initialization Screen
│   │   │   ├── login_screen.dart              # Driver Authentication with Server Validation
│   │   │   ├── register_screen.dart           # Comprehensive Driver Onboarding & Vehicle Application Form
│   │   │   ├── main_navigation_screen.dart    # Bottom Navigation Bar Shell (Google Nav Bar)
│   │   │   ├── home_screen.dart               # Driver Dashboard HUD (Speed Dial, Safety Score, Active Shift)
│   │   │   ├── trip_screen.dart               # Active Navigation HUD with Live Telemetry & Speed Limits
│   │   │   ├── map_screen.dart                # GIS Navigation Map with Road Hazard & Geofence Overlays
│   │   │   ├── alerts_screen.dart             # Infraction Notifications & Audio Warnings Review
│   │   │   ├── crash_screen.dart              # Collision Detection Countdown & Black Box SOS Trigger
│   │   │   ├── orders_screen.dart             # Assigned Logistics Missions & Delivery Confirmation
│   │   │   ├── history_screen.dart            # Historical Trip Polylines, Detailed G-Force Graphs & Analytics
│   │   │   ├── earnings_screen.dart           # Driver Earnings, Payouts & 30%/70% Relay Commissions
│   │   │   ├── rules_rewards_screen.dart      # Gamified XP Points, Badges Unlocked & Level Status
│   │   │   └── profile_screen.dart            # Personal Profile, Emergency Kin Contacts, Photo Upload
│   │   ├── services/
│   │   │   ├── api_service.dart               # HTTP Client with Parallel Subnet Fallback & Re-discovery
│   │   │   ├── socket_service.dart            # WebSocket Client, 20Hz Telemetry, Ghat Offline Buffer
│   │   │   ├── esp32_service.dart             # BLE Radar Scanner & 20Hz Telemetry Packet Parser
│   │   │   ├── sensor_service.dart            # Device Accelerometer/Gyroscope & Vibration Haptics
│   │   │   ├── road_rules_service.dart        # Speed Limit Evaluator vs OpenStreetMap
│   │   │   ├── overpass_service.dart          # Overpass API GIS Road Attributes Engine
│   │   │   ├── voice_service.dart             # Text-to-Speech (TTS) In-Cabin Spoken Driving Alerts
│   │   │   ├── discovery_service.dart         # UDP Zero-Config Auto-Discovery Broadcast Listener
│   │   │   └── media_service.dart             # Camera, Dashcam Audio/Video Evidence Recorder
│   │   └── main.dart                          # Flutter App Entrypoint & Provider Tree Initialization
│   └── pubspec.yaml                           # Flutter Dependencies & Asset Registrations
│
├── hardware_esp32/                            # IoT Firmware & Hardware Documentation
│   ├── smartdrive_esp32_sensor/
│   │   └── smartdrive_esp32_sensor.ino        # Production C++ Firmware (v3.7.0, BLE GATT + SoftAP Web Server)
│   └── WIRING_AND_SETUP_GUIDE.md              # Electrical Pinouts, Noise Suppression & Schematics
│
├── hardware/
│   └── SmartDrive_ESP32_Node/
│       └── SmartDrive_ESP32_Node.ino          # Standalone C++ Firmware Alternative
│
├── simulator.js                               # Node.js WebSocket Vehicle Movement & Crash Simulator
├── test_sensors.js                            # Script to Simulate Sensor Streams, Crashes, and Safety Pings
├── test_fleet.ps1                             # PowerShell Batch Telemetry Test Script
├── run_system.bat                             # Master 1-Click Launcher for All Distributed Microservices
├── run_backend_only.bat                       # Standalone Node.js + FastAPI Microservices Launcher
├── run_dashboard_only.bat                     # Standalone React Admin Dashboard Launcher
├── run_driver_dashboard_only.bat              # Standalone React Operator Portal Launcher
├── run_mobile_only.bat                        # Standalone Flutter Mobile Launcher (with ADB Reverse)
└── PROJECT_DETAILS.md                         # Deep Technical Architecture & Theoretical Documentation
```

---

## 3. Key Configuration Parameters & Environment Variables

### 3.1 Backend Gateway (`backend/.env`)
| Key | Default / Example Value | Description |
| :--- | :--- | :--- |
| `PORT` | `3000` | Port on which Express and Socket.IO listen |
| `NODE_ENV` | `development` / `production` | Runtimes: enables Swagger, pretty logs, or production guards |
| `DATABASE_URL` | `postgresql://postgres:postgres@localhost:5432/fleetguard_db?schema=public` | PostgreSQL connection string for Prisma ORM |
| `REDIS_URL` | `redis://127.0.0.1:6379` | Redis instance for BullMQ queues and session caching |
| `JWT_ACCESS_SECRET` | `super-secret-access-key-fleetguard-ai-2026` | Secret key for signing 15-minute access JWTs |
| `JWT_REFRESH_SECRET` | `super-secret-refresh-key-fleetguard-ai-2026` | Secret key for signing 7-day refresh tokens |
| `JWT_ACCESS_EXPIRY` | `15m` | Lifetime of short-lived access tokens |
| `JWT_REFRESH_EXPIRY`| `7d` | Lifetime of persistent refresh tokens |
| `LOCAL_STORAGE_DIR` | `./uploads` | Local disk folder for dashcam video, audio & license photos |
| `AI_SERVICE_URL` | `http://localhost:5000` | URL of the internal Python FastAPI AI microservice |
| `SMTP_HOST` | `smtp.gmail.com` | Outgoing SMTP host for official onboarding credential emails |
| `SMTP_PORT` | `465` | SSL SMTP port |
| `SMTP_USER` | `your-email@gmail.com` | SMTP account email |
| `SMTP_PASS` | `your-google-app-password` | SMTP App password |
| `EMAIL_FROM` | `SmartDrive Onboarding Hub <your-email@gmail.com>` | Sender header on issued credential letters |

### 3.2 Python FastAPI AI Microservice (`backend/app/core/config.py`)
| Key | Value | Description |
| :--- | :--- | :--- |
| `PROJECT_NAME` | `SmartDrive AI Engine` | Service title in OpenAPI/Swagger documentation |
| `API_V1_STR` | `/api/v1` | URL prefix for AI routes |
| Host & Port | `0.0.0.0:5000` | Uvicorn ASGI server binding address |
| CORS Policy | `*` | Allows cross-origin calls from Gateway and local dev ports |

### 3.3 ESP32 Firmware Telematics & Kinematics Settings
Defined in [`smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino):

```cpp
#define DEVICE_NAME             "SmartDrive-Sensor-Node"
#define DEVICE_ID               "SD-ESP32-001"
#define FIRMWARE_VERSION        "3.7.0-TUNED"
#define LED_PIN                 2        // Status LED on GPIO 2
#define I2C_SDA_PIN             21       // Hardware I2C SDA
#define I2C_SCL_PIN             22       // Hardware I2C SCL (40 kHz)

// BLE GATT Service & Characteristics UUIDs
#define SERVICE_UUID            "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_TX  "beb5483e-36e1-4688-b7f5-ea07361b26a8" // Telemetry Notify (20 Hz)
#define CHARACTERISTIC_UUID_RX  "beb5483e-36e1-4688-b7f5-ea07361b26a9" // Commands Inbound (LED, Calib)

// Wi-Fi SoftAP Fallback Settings
const char* AP_SSID           = "SmartDrive-Sensor-Node";
const char* AP_PASS           = "SmartDrive2026!";
// Static Gateway IP: http://192.168.4.1

// Kinematic Thresholds (Calibrated in SI Units: m/s^2 and rad/s)
const float DEADBAND_DELTA_ACCEL  = 8.0;   // Discard road micro-vibrations < 8.0 m/s^2 (~0.8G)
const float THRESHOLD_HARSH_BRAKE = 10.5;  // Forward deceleration surge > 10.5 m/s^2 (>1.0G)
const float THRESHOLD_RAPID_ACCEL = 9.8;   // Forward acceleration launch > 9.8 m/s^2 (>1.0G)
const float THRESHOLD_SHARP_TURN  = 3.20;  // Angular yaw velocity > 3.20 rad/s (~183 deg/s)
const float THRESHOLD_CRASH_G     = 5.0;   // Severe collision shockwave >= 5.0G
const float THRESHOLD_CRASH_DELTA = 38.0;  // Catastrophic acceleration delta >= 38.0 m/s^2
const float THRESHOLD_POTHOLE_DELTA_Z = 14.0; // Vertical road shockwave delta > 1.4G
```

### 3.4 Mobile App Network Fallbacks (`MobileApp/lib/core/constants/app_urls.dart`)
| Host Address | Description |
| :--- | :--- |
| `100.116.115.5` | Permanent Tailscale Encrypted Mesh IP (Direct connection from any 4G/5G carrier) |
| `10.21.242.144` | Local Wi-Fi subnet IP |
| `127.0.0.1` | ADB reverse loopback (via USB cable: `adb reverse tcp:3000 tcp:3000`) |
| `10.0.2.2` | Standard Android Emulator host gateway |
| `UDP Port 41234`| Zero-Config dynamic discovery beacon port queried by mobile upon network switch |

### 3.5 Docker Infrastructure (`backend/docker-compose.yml`)
* **`db` service**: `postgres:15-alpine` on port `5432:5432`, volume `pgdata:/var/lib/postgresql/data`.
* **`redis` service**: `redis:7-alpine` on port `6379:6379`, volume `redisdata:/data`.
* **`app` service**: Node.js Alpine container on port `3000:3000`, volume `uploads-data:/app/uploads`.
* **Bridge Network**: `smartdrive-network`.

---

## 4. Complete Codebase Endpoints Catalog (REST APIs)

All Gateway endpoints are mounted under both `/api/v1` and `/api` (e.g., `http://localhost:3000/api/v1/...`).

### 4.1 Authentication & Driver Onboarding (`/auth`)
| Method | Endpoint | Auth Required | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/driver-apply` | Public | Submits a new driver onboarding application with license, zone, vehicle, and family kin details. Returns tracking ID (`REQ-2026-XXXX`). |
| `GET` | `/auth/application-status` | Public | Checks onboarding application review status via query parameters (`email`, `trackingId`, or `licenseNumber`). |
| `POST` | `/auth/change-initial-password` | Public | Allows newly approved drivers to replace their temporary system-generated password with a permanent password. |
| `POST` | `/auth/register` | Public | Registers a new user account (Admin, Fleet Manager, or Driver) with validation schema. |
| `POST` | `/auth/login` | Public | Authenticates credentials; returns `accessToken` (15m), `refreshToken` (7d), and full user profile with assigned vehicle data. |
| `POST` | `/auth/refresh` | Public | Exchanges a valid `refreshToken` for a fresh access token (with token rotation). |
| `PUT` | `/auth/profile` | Bearer Token | Updates current authenticated user details (name, phone, settings). |

### 4.2 Driver Management & Governance (`/drivers`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/drivers` | Admin / Manager | Retrieves paginated list of all organization drivers with current safety scores and assigned vehicles. |
| `GET` | `/drivers/leaderboard` | All Authenticated | Returns regional eco-driving and safety rankings sorted by XP, safety score, and clean driving streaks. |
| `GET` | `/drivers/pending` | Admin / Manager | Retrieves all pending driver onboarding applications filtered by geographical operating zone (`puttur_taluk`, etc.). |
| `POST` | `/drivers/verify-license` | Admin / Manager | Simulates Parivahan National Register driving license verification (validates license class, expiry date, and RTO status). |
| `POST` | `/drivers/:id/approve` | Admin / Manager | Approves applicant, creates database credentials, generates temporary password, assigns vehicle, and dispatches credential email. |
| `POST` | `/drivers/:id/reject` | Admin / Manager | Rejects applicant with recorded feedback reason and audit trail. |
| `GET` | `/drivers/:id` | Authenticated | Retrieves comprehensive driver profile, vehicle assignments, earned badges, and historical safety metrics. |
| `PUT` | `/drivers/:id` | Authenticated | Updates driver profile fields (emergency kin contact, phone number, vehicle attributes). |
| `POST` | `/drivers/:id/assign` | Admin / Manager | Assigns a vehicle to a driver (creates `VehicleAssignment` record). |
| `POST` | `/drivers/:id/unassign` | Admin / Manager | Releases the active vehicle assignment for a driver. |
| `GET` | `/drivers/:id/scores-trend` | Authenticated | Retrieves chronological safety score evaluations over time for graphing trends. |
| `DELETE`| `/drivers/:id` | Admin / Manager | Deletes driver record and revokes system access. |

### 4.3 Vehicle Fleet Management (`/vehicles`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/vehicles` | Admin / Manager | Registers a new vehicle into fleet (make, model, year, license plate, VIN, vehicle type). |
| `GET` | `/vehicles` | Authenticated | Lists all vehicles in the organization with maintenance health indicators. |
| `GET` | `/vehicles/:id` | Authenticated | Retrieves specific vehicle details and active assignment history. |
| `PUT` | `/vehicles/:id` | Admin / Manager | Modifies vehicle parameters or updates maintenance status (`HEALTHY`, `NEEDS_SERVICE`, `UNDER_MAINTENANCE`). |
| `DELETE`| `/vehicles/:id` | Super Admin | Removes vehicle from active registry. |

### 4.4 Trip Lifecycle & Tracking (`/trips`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/trips/start` | Driver | Starts an active trip session. Body: `vehicleId`, optional `deliveryFrom`, `deliveryTo`, `orderItems`, `orderId`. Returns `tripId`. |
| `POST` | `/trips/:id/end` | Authenticated | Concludes an active trip session; triggers polyline compression and sends trip data to Python AI service for scoring. |
| `POST` | `/trips/:id/location` | Driver | Ingests a single GPS breadcrumb: `latitude`, `longitude`, `speed`, `heading`, `altitude`, `timestamp`. |
| `GET` | `/trips` | Authenticated | Retrieves trip logs with summary statistics (distance, duration, average speed, safety score). |
| `GET` | `/trips/:id` | Authenticated | Retrieves complete trip details including all indexed GPS breadcrumbs and registered infractions. |

### 4.5 Telemetry Events (`/events`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/events` | Driver | Logs a discrete driving infraction event: `tripId`, `eventType` (`HARSH_BRAKING`, `RAPID_ACCELERATION`, `OVERSPEED`, `SHARP_TURN`, `PHONE_USAGE`), `severity`, `latitude`, `longitude`, `sensorValues`. |
| `GET` | `/events` | Authenticated | Retrieves historical events with filtering by driver, trip, or event type. |

### 4.6 Crash Forensics & Emergency Intake (`/crashes`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/crashes` | Driver | Ingests emergency collision telemetry payload: `tripId`, `latitude`, `longitude`, `sensorValues` (`accelX/Y/Z`, `speedBefore`, `speedAfter`, `gForce`), `severity`. Broadcasts alarm to all connected dashboards. |
| `GET` | `/crashes` | Authenticated | Lists all logged crash incidents with triage status (`PENDING`, `DISPATCHED`, `RESOLVED`, `FALSE_ALARM`). |
| `GET` | `/crashes/:id` | Authenticated | Retrieves comprehensive crash record, AI forensic summary, and associated evidence media links. |
| `PUT` | `/crashes/:id/status`| Admin / Support | Updates incident investigation state. |
| `POST` | `/crashes/:id/media` | Authenticated | Multi-part form-data upload for in-cabin video recordings (30s pre-crash) or audio logs. |

### 4.7 Reports & Analytical Exports (`/reports`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/reports/monthly-drivers` | Public / Auth | Aggregated monthly driver safety ratings, total distance, and fleet infraction breakdown. |
| `GET` | `/reports/potholes/export` | Public / Auth | Exports geo-located road surface anomalies as downloadable CSV or GeoJSON for municipal road maintenance authorities. |
| `POST` | `/reports/export` | Authenticated | Triggers asynchronous generation of official PDF or Excel inspection reports via BullMQ queues. |
| `GET` | `/reports/notifications` | Authenticated | Fetches system notifications and safety alerts for the logged-in user. |

### 4.8 Logistics Orders & Job Dispatch (`/orders`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/orders` | Public / Auth | Retrieves all logistics orders stored in `orders.json`. |
| `GET` | `/orders/pending` | Public / Auth | Retrieves all orders awaiting driver assignment (`status === 'PENDING'`). |
| `POST` | `/orders` | Public / Auth | Creates a new customer delivery order: `customerName`, `items`, `amount`, `deliveryLocation`, `deliveryFrom`. |
| `POST` | `/orders/:id/assign` | Public / Auth | Assigns order to a specific `driverId`, updates order state to `ASSIGNED`, pushes `job_assigned` event to driver's private socket room, and notifies dashboards. |

### 4.9 Real-Time Simulation & Alerts (`/alerts`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/alerts/vibrate/:driverId` | Admin | Triggers an immediate hardware vibration buzz on the specified driver's smartphone. |
| `POST` | `/alerts/simulate-sos` | Public / Demo | Injects an artificial high-priority SOS emergency incident for system integration demonstration. |
| `POST` | `/alerts/simulate-nearest-driver`| Public / Demo | Simulates multi-vehicle proximity alerts for emergency rescue coordination. |
| `POST` | `/alerts/simulate-cross-delivery`| Public / Demo | Triggers an automated 30%/70% consignment handover simulation. |

### 4.10 Road Anomalies & Evidence Buffers (`/anomalies`)
| Method | Endpoint | Permissions | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/anomalies` | Public / Auth | Returns road anomalies (potholes, bumps) sorted by detection count for map overlay. |
| `POST` | `/anomalies` | Public / Auth | Ingests new road anomaly. Automatically clusters reports occurring within a 25-meter spatial threshold using the Haversine formula. |
| `GET` | `/anomalies/hotspots` | Public / Auth | Returns recurring traffic hazard hotspots (zones with multiple infractions where penalty discounts apply). |
| `POST` | `/anomalies/evidence` | Public / Auth | Uploads synchronized high-frequency ($\pm 5\text{s}$) 20 Hz sensor series (`EventEvidence`) around a critical driving infraction. |

### 4.11 Python FastAPI AI Microservice (Port 5000)
| Method | Endpoint | Request Body | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | None | Service heartbeat check. |
| `POST` | `/api/v1/ai/evaluate-trip` | `TripEvaluationRequest` | Ingests GPS breadcrumbs and event logs. Computes dynamic Safety Score (0–100), Risk Score (0–100), driver behavioral category (`CONSERVATIVE`, `BALANCED`, `AGGRESSIVE`), XP points, and unlocked achievement badges. |
| `POST` | `/api/v1/ai/generate-crash-summary` | `CrashSummaryRequest` | Analyzes impact shockwave values. Computes speed differential ($\Delta V$), impact vector axis (Longitudinal vs Lateral), and Crush Deformation Index ($I_{\text{crush}} = \frac{\Delta V \times G_{\text{max}}}{10.0}$). |

### 4.12 ESP32 Onboard SoftAP Web Server (Port 80 / `192.168.4.1`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/device/status` | Reports hardware health: uptime, free heap memory, BLE client link status, MPU connection state, and blue LED state. |
| `GET` | `/api/v1/telemetry/latest` | Returns latest real-time SI telemetry snapshot: acceleration ($a_x, a_y, a_z$), angular rate ($g_x, g_y, g_z$), temperature, G-magnitude, and event counters. |
| `POST` | `/api/v1/device/led` | Toggles the onboard blue GPIO 2 status LED for diagnostic verification. |
| `POST` | `/api/v1/device/ota/upload` | Multipart binary firmware upload handler for Over-the-Air ESP32 re-flashing. |

---

## 5. Real-Time WebSocket / Socket.IO Telemetry & Event Engine

* **Engine Location**: [`backend/src/sockets/socket.manager.ts`](file:///c:/projects/Major_project/backend/src/sockets/socket.manager.ts)
* **Port**: `3000` (attached directly to HTTP server instance)
* **Authentication**: Handshake JWT token verified against `JWT_ACCESS_SECRET`; supports fallback demo role.
* **Rooms Architecture**:
  * `user:<userId>`: Private driver channel (receives dispatches, vibration triggers, personal pings).
  * `org:<organizationId>`: Enterprise tenant channel.
  * `dashboards`: Shared broadcast channel for all connected administrative monitoring HUDs.

### 5.1 Inbound Events (Driver / Client → Gateway)
| Event Name | Key Payload Fields | Description & Engine Processing |
| :--- | :--- | :--- |
| `gps_update` | `driverId`, `latitude`, `longitude`, `speed`, `heading`, `accelX/Y/Z`, `vibrationRate`, `isDeadZone`, `safetyScore`, `deliveryFrom`, `deliveryTo`, `orderItems` | High-frequency telemetry stream. Evaluates dead zone geofences, updates in-memory live driver store, persists coordinates to PostgreSQL, and broadcasts update to dashboards. |
| `shift_status` | `driverId`, `driverName`, `status` (`'online'` \| `'offline'`), `latitude`, `longitude`, `regionId` | Toggles driver shift state (GO LIVE / END LIVE). Emits `driver_online` or `driver_offline` across fleet rooms. |
| `crash_event` / `crash_detected` | `tripId`, `driverId`, `latitude`, `longitude`, `severity`, `speedBefore`, `speedAfter`, `accelX/Y/Z`, `noMotionSeconds` | Critical collision trigger. Marks driver as `emergency`, logs crash to database, emits `crash_alert`, and activates nearby driver proximity search. |
| `driver_sos_alert` / `sos_alert` | `driverId`, `driverName`, `latitude`, `longitude`, `phone`, `vehiclePlate`, `reason` | Manual panic SOS beacon. Sets status to `emergency`, emits siren to dashboard, generates Google Maps distress link, and searches for nearest rescue drivers. |
| `safety_response` / `driver_safety_confirmed` / `driver_safe` | `driverId`, `driverName`, `status` (`'safe'`), `reason` | Driver acknowledges safety ping or taps "I AM SAFE". Clears emergency flags in in-memory store and updates dashboards. |
| `pothole_detected` | `latitude`, `longitude`, `intensity`, `vibrationRate`, `roadName` | Ingests vertical road shockwave ($Z > 14\text{ m/s}^2$). Dedupes against entries within 35 meters, stores in live buffer, and emits warnings to other active drivers. |
| `rule_violation_alert` | `driverId`, `ruleType`, `ruleTitle`, `speed`, `speedLimit`, `roadName` | Triggered when mobile road rules engine detects vehicle exceeding OpenStreetMap speed limit. |
| `roadside_breakdown_alert`| `driverId`, `issueType` (`'Mechanical Stall'`, `'Flat Tyre'`, etc.), `latitude`, `longitude`, `vehiclePlate` | Driver requests roadside tow assistance. Marks vehicle emergency and broadcasts alert. |
| `batch_offline_telemetry` | `driverId`, `count`, `points: Array<Point>`, `syncedAt` | **Ghat Offline Sync**: Ingests FIFO telemetry points buffered during cellular dead zone transit, updating driver's latest position. |
| `deadzone_impact_sync` | `driverId`, `impacts: Array<Impact>` | Synchronizes critical shocks or collisions that occurred while offline. |
| `driver_toggle_deadzone` | `driverId`, `isDeadZone: boolean`, `reason` | Manually toggles Ghat / Dead Zone Mode. Triggers buffer flush when deactivated. |
| `job_accepted` / `job_rejected` | `orderId`, `driverName`, `reason` | Response to a logistics job assignment. Notifies dispatcher and updates order state. |
| `live_frame` | `driverId`, `frame: string` (Base64 JPEG) | Transmits real-time in-cabin dashcam video frames for remote monitoring. |
| `trip_telemetry_analysis` | `driverId`, `distanceKm`, `safetyScore`, `pointsEarned`, `payout` | Final trip audit payload; updates driver XP, level, and cumulative wallet earnings. |
| `initiate_cross_delivery_handover` | `orderId`, `troubledDriverId`, `dropAddress`, `dropLat`, `dropLng`, `totalAmount` | Initiates 30%/70% consignment handover split when a vehicle breaks down. |
| `accept_cross_delivery_handover` | `orderId`, `relayDriverId`, `troubledDriverId`, `relayDriverSplit`, `troubledDriverSplit` | A healthy nearby driver accepts the consignment relay, locking in payouts. |

### 5.2 Outbound Broadcast Events (Gateway → Clients)
| Event Name | Recipient Scope | Description |
| :--- | :--- | :--- |
| `driver_location_update` | `dashboards` & `org:<orgId>` | Broadcasts updated vehicle coordinates, heading, speed, and status. |
| `driver_online` / `driver_offline` | `dashboards` & `org:<orgId>` | Notifies command center when a driver starts or ends their shift. |
| `crash_alert` / `sos_alert` | `dashboards` | Triggers emergency audio/visual siren, displaying driver details, coordinates, and contact links. |
| `v2v_proximity_message` | `user:<driver1>`, `user:<driver2>` | Directional cooperative proximity alert sent when two fleet vehicles converge within 500 meters. |
| `blind_curve_warning` | `user:<driver1>`, `user:<driver2>` | Oncoming blind-curve collision warning for approaching vehicles. |
| `same_direction_drivers` | `user:<driverId>` | Sends list of convoy peer vehicles traveling in the same corridor within 5 km. |
| `emergency_nearby_driver_alert` | `user:<nearbyDriver>` | Alerts healthy nearby drivers within 25 km of an emergency to standby for rescue or consignment handover. |
| `nearby_rescue_candidates` | `dashboards` | Full list of nearby drivers with distances and ETAs for emergency dispatch visualization. |
| `pothole_broadcast` | All active drivers | Warns active drivers in real time of upcoming road hazards reported by peers. |
| `geofences_sync` / `geofence_updated` | All drivers & dashboards | Synchronizes school zones, market sectors, hairpin curves, and cellular dead zones. |
| `admin_voice_broadcast` | All drivers | Dispatches administrative voice announcement to drivers, spoken aloud via mobile TTS. |
| `driver_check_ping` | `user:<driverId>` | Admin safety check request; mobile displays "ARE YOU SAFE?" modal with 30s timer. |
| `job_assigned` | `user:<driverId>` | Pushes new delivery order consignment details directly to assigned driver. |
| `request_live_cam` | `user:<driverId>` | Commands mobile app to activate or terminate live camera dashcam streaming. |
| `cross_delivery_credited_30` | `user:<troubledDriverId>` | Confirms 30% base compensation credited to troubled driver's account. |
| `cross_delivery_assigned_70` | `user:<relayDriverId>` | Assigns rescue delivery mission with 70% payout bonus. |

### 5.3 Automated Background Engines
1. **Cooperative V2V Proximity Engine (Every 3 seconds)**:
   * Compares all active online drivers using Haversine distance and heading trigonometry.
   * Identifies convoys traveling in the same direction within 5 km and converging vehicles within 500 meters.
   * Determines relative position (`AHEAD` vs `BEHIND`) using forward bearing angles and dispatches tailored warnings.
2. **Dead Zone Lifecycle & Inactivity Pruner**:
   * Evaluates time elapsed since `lastSeen`. If no updates for $> 25\text{s}$ but $\le 15\text{ minutes}$, marks driver as `isDeadZone = true` (preserving last known position).
   * After 15 minutes of inactivity, purges stale in-memory records.

---

## 6. Database Schema & Data Pipeline (Prisma ORM & PostgreSQL)

* **Schema Location**: [`backend/src/prisma/schema.prisma`](file:///c:/projects/Major_project/backend/src/prisma/schema.prisma)
* **Total Tables**: 14 Relational Models + 9 Enumerations

### 6.1 Enumerations
* `Role`: `SUPER_ADMIN`, `FLEET_ADMIN`, `FLEET_MANAGER`, `DRIVER`, `SUPPORT`
* `VehicleType`: `SCOOTER`, `MOTORCYCLE`, `CAR`, `PICKUP`, `VAN`, `TRUCK`
* `MaintenanceStatus`: `HEALTHY`, `NEEDS_SERVICE`, `UNDER_MAINTENANCE`
* `TripStatus`: `ONGOING`, `COMPLETED`, `CANCELLED`
* `EventType`: `HARSH_BRAKING`, `RAPID_ACCELERATION`, `OVERSPEED`, `SHARP_TURN`, `PHONE_USAGE`, `CRASH`, `LOW_BATTERY`, `LOW_NETWORK`, `GPS_LOST`
* `Severity`: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`
* `EmergencyStatus`: `PENDING`, `DISPATCHED`, `RESOLVED`, `FALSE_ALARM`
* `FileType`: `IMAGE`, `VIDEO`, `AUDIO`, `DOCUMENT`
* `NotificationType`: `CRASH`, `OVERSPEED`, `BLE_LOST`, `BATTERY_LOW`, `GPS_LOST`, `EMERGENCY`, `SYSTEM`
* `DriverType`: `TACTICAL`, `STANDARD`

### 6.2 Relational Models Summary
```text
[ Organization ]
    ├── (1:N) User ────────── (1:1) Driver ───── (1:N) DriverScore
    │                           ├── (1:N) VehicleAssignment ── (N:1) Vehicle
    │                           ├── (1:N) Trip
    │                           │     ├── (1:N) TripPoint [Index: tripId, timestamp]
    │                           │     ├── (1:N) Event
    │                           │     └── (1:N) CrashReport ── (1:N) Media
    ├── (1:N) Vehicle
    ├── (1:N) Notification
    ├── (1:1) Settings
    └── (1:N) AuditLog

Standalone Spatial Tables:
    ├── RoadAnomaly  [Index: latitude, longitude] (Pothole clusters)
    ├── RiskHotspot  [Index: latitude, longitude] (Traffic hazard zones)
    └── EventEvidence (20 Hz -5s to +5s sensor windows)
```

1. **`Organization`**: Multi-tenant isolation boundary (`id`, `name`, timestamps).
2. **`User`**: Authentication identities (`email`, `passwordHash`, `firstName`, `lastName`, `role`, `zone`).
3. **`Driver`**: Telematics profile (`licenseNumber`, `emergencyContactName`, `emergencyContactPhone`, `status`, `safetyScore`, `riskScore`, `xp`, `level`, `streak`, `badges`, `latitude`, `longitude`, `lastSeen`).
4. **`Vehicle`**: Fleet vehicles (`make`, `model`, `year`, `vehicleType`, `licensePlate`, `insuranceNumber`, `maintenanceStatus`).
5. **`VehicleAssignment`**: Driver-to-vehicle mapping with assignment history (`assignedAt`, `unassignedAt`).
6. **`Trip`**: Driving sessions (`distance`, `duration`, `avgSpeed`, `maxSpeed`, `polyline`, `deliveryFrom`, `deliveryTo`, `orderItems`, `orderId`).
7. **`TripPoint`**: High-frequency GPS coordinates (`latitude`, `longitude`, `speed`, `heading`, `altitude`, `timestamp`). B-Tree indexed on `[tripId, timestamp]`.
8. **`Event`**: Infraction occurrences (`eventType`, `severity`, `latitude`, `longitude`, `sensorValues`).
9. **`CrashReport`**: Emergency collision entries (`sensorValues`, `severity`, `emergencyStatus`, `aiSummary`, `crashProbability`).
10. **`Media`**: Uploaded evidence links (`url`, `fileType`, `purpose`: `"CRASH_VIDEO"`, `"DRIVER_LICENSE"`).
11. **`Notification`**: In-app alert messages.
12. **`DriverScore`**: Aggregated safety scores across time.
13. **`Settings`**: Configurable organization thresholds (`overspeedThreshold`, `harshBrakingThreshold`, etc.).
14. **`AuditLog`**: System actions audit trail.
15. **`RoadAnomaly`**: Spatial road hazards with Haversine clustering (`zShockG`, `detectionCount`).
16. **`RiskHotspot`**: Recurring hazard zones with penalty score discounts.
17. **`EventEvidence`**: Synchronized 20 Hz pre- and post-incident sensor window data.

---

## 7. Frontend Applications & Client Portals

### 7.1 React Admin Fleet Command Center (`dashboard/`)
* **Tech Stack**: React 19 / Vite 6 / TypeScript / TailwindCSS 4 / Leaflet / Socket.IO Client.
* **Dev Server**: `http://localhost:5173`
* **Route Structure**:
  * `/`: `Dashboard.tsx` — Executive overview, active vehicle count, fleet safety score, speed compliance gauges.
  * `/map`: `LiveMap.tsx` — Real-time interactive GIS map rendering animated vehicle markers with bearing rotation, speed indicators, breadcrumb trails, geofence zones, and road hazard overlays.
  * `/drivers`: `Drivers.tsx` — Driver list, safety scores, earned XP, assigned vehicles, and safety check trigger buttons.
  * `/requests`: `Requests.tsx` — Driver onboarding review center. Parivahan license verification, candidate dossier inspection, and 1-click approve/reject actions with automated email dispatch.
  * `/orders`: `Orders.tsx` — Logistics dispatch desk. Displays pending customer orders, distance calculations, and 1-click driver assignment.
  * `/events`: `Events.tsx` — Filterable table of all logged infractions (harsh brakes, launches, swerves, overspeeding).
  * `/reports`: `Reports.tsx` — Analytics dashboard with score trend charts, monthly reports, and PDF/Excel export controls.
  * `/investigation`: `CrashInvestigation.tsx` — Emergency incident forensics center. Renders Delta-V, impact vector axes, structural crush deformation indices, 30s pre-crash dashcam videos, and 2-minute in-cabin audio recordings.
  * `/profile`: `Profile.tsx` — Fleet management settings, threshold overrides, and organization details.
  * `/track/:driverId`: `PublicLiveTrack.tsx` — Standalone tracking view accessible to end-customers to watch real-time consignment delivery progress.
* **Global Emergency Banner**: Real-time modal and audio sirens triggered across all pages upon receiving `sos_alert` or `crash_alert`, providing 1-click WhatsApp SOS dispatch, direct phone dialer links, live dashcam activation, and cross-delivery handover assignment.

### 7.2 React Driver Self-Service Web Portal (`web/driver-dashboard/`)
* **Tech Stack**: React 18 / Vite / Lucide-React / TailwindCSS.
* **Dev Server**: `http://localhost:5174`
* **Pages**:
  * `DashboardHome.jsx`: Operator trip summaries, live safety score, eco-driving tips, and streak indicators.
  * `DriversPage.jsx`: Colleague leaderboard and peer rankings.
  * `TripsPage.jsx`: Personal trip history with mapped polylines and duration stats.
  * `EventsPage.jsx`: Personal infraction breakdown with feedback.
  * `HeatmapPage.jsx`: Localized road roughness and pothole hazard heatmap.
  * `ReportsPage.jsx`: Monthly driving performance report cards.

### 7.3 Supporting Static Web Utilities
* **Mission Dispatch Control (`web/order-dispatch/index.html`)**: Simple web form to generate orders via `POST /api/v1/orders`. Hosted by Gateway at `/dispatch`.
* **Swadeshi Delivery Client (`web/orders-client/index.html`)**: Consumer-facing delivery tracking interface. Hosted by Gateway at `/orders-client`.

---

## 8. Mobile Application Architecture (Flutter)

* **Directory**: [`MobileApp/`](file:///c:/projects/Major_project/MobileApp)
* **Framework**: Flutter 3.x (Dart SDK `>=3.11.0 <4.0.0`)
* **Package Name**: `mobile_app` (FleetGuard)

### 8.1 Key Packages & Capabilities
* **Hardware Sensors & BLE**: `flutter_blue_plus` (BLE GATT scanning & characteristic subscriptions), `sensors_plus` (internal accelerometer/gyroscope fallback), `vibration` (haptic pulses).
* **Location & GIS**: `geolocator`, `geocoding`, `flutter_map`, `latlong2`.
* **Networking & Sockets**: `socket_io_client`, `connectivity_plus`, UDP unicast sockets.
* **Media & Audio**: `camera`, `record` (audio capture), `video_player`, `audioplayers`, `flutter_tts` (spoken in-cabin driving alerts).
* **Storage & Security**: `shared_preferences`, `flutter_secure_storage`.
* **Visuals & Charts**: `fl_chart`, `syncfusion_flutter_gauges`, `confetti`, `google_fonts`.

### 8.2 Screen Flow & Navigation
```text
splash_screen.dart
      ↓
[Authentication Check]
   ├── Not Logged In ──> login_screen.dart ──> register_screen.dart (Onboarding application)
   └── Logged In ──────> main_navigation_screen.dart (Google Nav Bar)
                                ├── Tab 0: home_screen.dart (Speed dial, safety score, GO LIVE toggle)
                                ├── Tab 1: trip_screen.dart (Active navigation HUD, OSM speed limits)
                                ├── Tab 2: map_screen.dart (GIS map, ESP32 BLE Radar Scanner)
                                ├── Tab 3: orders_screen.dart (Assigned logistics deliveries)
                                └── Tab 4: profile_screen.dart (Emergency kin, earnings, badges)
```

* **`home_screen.dart`**: Primary driver cockpit. Start/end trip controls, active shift status toggle (`shift_status`), safety score meter, emergency SOS button, and single-click manual **Ghat Mode / Dead Zone Mode** toggle.
* **`trip_screen.dart`**: Active driving screen. Real-time speedometer, OpenStreetMap speed compliance indicators, road type tags, and live G-force dials.
* **`map_screen.dart`**: OpenStreetMap Leaflet layer displaying current location, geofences (school zones, hospitals, hairpin bends), reported potholes, and an embedded **ESP32 BLE Radar Scanner** with live RSSI signal strength meter.
* **`crash_screen.dart`**: Activates automatically upon severe deceleration or high-G shock. Renders a 30-second countdown with audible alarm; if not cancelled, automatically triggers emergency SOS, packages black box sensor data, and begins audio/video evidence recording.
* **`rules_rewards_screen.dart`**: Driver gamification center showing XP progress, driver level, clean driving streaks, and unlocked achievement badges.
* **`earnings_screen.dart`**: Tracks delivery earnings and credits from the **30%/70% Cross-Delivery Relay System**.

### 8.3 Core Mobile Services
1. **`api_service.dart`**: HTTP service with parallel subnet fallback, token persistence, and automatic self-healing server discovery.
2. **`socket_service.dart`**: Socket.IO client managing real-time telemetry streaming (20 Hz), in-cabin TTS announcements, audio warnings, and the **Offline Ghat Mode FIFO Buffer** (stores up to 15 minutes of coordinates during cellular blackouts and burst-syncs upon reconnection).
3. **`esp32_service.dart`**: Scans for peripherals advertising `SmartDrive-Sensor-Node`, handles BLE GATT pairing, bookmarks sensor MAC addresses, and decodes incoming 20 Hz JSON/binary packets from Characteristic `beb5483e-36e1-4688-b7f5-ea07361b26a8`.
4. **`road_rules_service.dart`**: Compares current vehicle speed against OpenStreetMap speed limits (via Overpass API) and triggers infraction alerts when speed exceeds the limit by $> 10\text{ km/h}$.
5. **`voice_service.dart`**: Speaks driving advisories aloud ("Harsh Braking Detected", "Approaching School Zone — Limit 25", "Maintain Safe Distance").

---

## 9. Embedded Hardware Node & Firmware Architecture (ESP32 C++)

* **Source File**: [`hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino)
* **BOM Cost**: Under $6 (ESP32 Dev Board + GY-521 MPU-6050 + TP4056 charge board).

### 9.1 Electrical Wiring & Pinout
| MPU-6050 Pin | ESP32 GPIO | Description |
| :--- | :--- | :--- |
| **VCC** | **VIN (5V) or 3V3** | Sensor power supply (GY-521 has onboard 3.3V LDO regulator) |
| **GND** | **GND** | Common system ground |
| **SCL** | **GPIO 22** | Hardware I2C Clock (configured to 40 kHz for automotive noise immunity) |
| **SDA** | **GPIO 21** | Hardware I2C Data line with software bus recovery |
| **AD0** | **GND** | Hardware address select; pulled to GND hardcodes slave address to `0x68` |
| **INT** | **GPIO 19** | Optional hardware motion interrupt pin |
| **Status LED** | **GPIO 2** | Built-in blue LED for heartbeat pulses and BLE diagnostic toggle |

### 9.2 Firmware DSP Math & Signal Pipeline
1. **Hardware I2C Bus Recovery**: Before initializing the `Wire` library, firmware toggles SCL 9 times to clear stuck SDA lines caused by vehicle voltage fluctuations:
   ```cpp
   void recoverI2CBus() {
     pinMode(I2C_SDA_PIN, INPUT_PULLUP);
     pinMode(I2C_SCL_PIN, OUTPUT);
     digitalWrite(I2C_SCL_PIN, HIGH);
     for (int i = 0; i < 9; i++) {
       digitalWrite(I2C_SCL_PIN, LOW);  delayMicroseconds(10);
       digitalWrite(I2C_SCL_PIN, HIGH); delayMicroseconds(10);
       if (digitalRead(I2C_SDA_PIN) == HIGH) break;
     }
     // Generate explicit STOP condition
     pinMode(I2C_SDA_PIN, OUTPUT);
     digitalWrite(I2C_SDA_PIN, LOW); delayMicroseconds(10);
     digitalWrite(I2C_SCL_PIN, HIGH); delayMicroseconds(10);
     digitalWrite(I2C_SDA_PIN, HIGH);
   }
   ```
2. **Direct Register Configuration**:
   * `0x6B` (PWR_MGMT_1) $\rightarrow$ `0x01`: Wake up and clock source locked to PLL with X-Axis Gyroscope reference (eliminates internal oscillator drift).
   * `0x1B` (GYRO_CONFIG) $\rightarrow$ `0x00`: Full-Scale Range $\pm 250^\circ/\text{s}$ ($131.0\text{ LSB}/(^\circ/\text{s})$).
   * `0x1C` (ACCEL_CONFIG) $\rightarrow$ `0x18`: Full-Scale Range $\pm 16g$ ($2048.0\text{ LSB}/g$, High-Impact Crash Mode).
   * `0x1A` (CONFIG DLPF) $\rightarrow$ `0x03`: Digital Low Pass Filter 21 Hz cutoff (filters mechanical chassis vibrations).
3. **Burst Read**: 14-byte repeated-start transaction reads $a_x, a_y, a_z, \text{temp}, g_x, g_y, g_z$ simultaneously in a single I2C operation.
4. **Dynamic Auto-Zero Baseline Tracking**: Automatically adapts to arbitrary mounting tilt (windshield, dashboard, center console) using an Exponential Moving Average (EMA):
   $$\text{base}_i(t) = 0.98 \cdot \text{base}_i(t-1) + 0.02 \cdot a_i(t)$$
   $$\Delta a_i(t) = a_i(t) - \text{base}_i(t)$$
5. **Deadband Filter**: Discards road micro-vibrations ($|\Delta a_i| < 8.0\text{ m/s}^2$).
6. **Telemetry Emission**: Dispatches 20 Hz JSON payloads via BLE GATT Characteristic Notify:
   ```json
   {"ax":0.12,"ay":-0.05,"az":9.81,"gx":0.01,"gy":-0.02,"gz":0.00,"gMag":1.00,"temp":27.2,"imp":0,"hb":2,"ra":1,"st":0,"sc":1}
   ```

---

## 10. Operational Runbook & Launcher Scripts

### 10.1 Master 1-Click Launcher (Windows)
From repository root, execute:
```cmd
.\run_system.bat
```
This launcher automatically coordinates the entire distributed stack across separate terminal windows:
1. Verifies Docker and boots `db` (Postgres) and `redis` containers via `docker-compose`.
2. Generates the Prisma database client (`npx prisma generate`).
3. Starts the Node.js API Gateway on port `3000` (`npm run dev`).
4. Creates a Python virtual environment, installs dependencies, and boots the FastAPI AI microservice on port `5000` via Uvicorn.
5. Launches the React Admin Command Center on port `5173` via Vite.
6. Launches the React Driver Web Portal on port `5174` via Vite.
7. Executes `adb reverse tcp:3000 tcp:3000` and launches the Flutter mobile client.

### 10.2 Individual Service Launch Commands

#### Database & Infrastructure
```bash
cd backend
docker-compose up -d db redis
npx prisma migrate dev --schema=src/prisma/schema.prisma
npm run db:seed
```

#### Node.js Express Gateway (Port 3000)
```bash
cd backend
npm install
npm run dev
# Swagger documentation: http://localhost:3000/api-docs
# Health check: http://localhost:3000/health
```

#### Python FastAPI AI Microservice (Port 5000)
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate       # Linux/macOS: source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
# Interactive Swagger docs: http://localhost:5000/docs
# Health check: http://localhost:5000/health
```

#### React Admin Fleet Dashboard (Port 5173)
```bash
cd dashboard
npm install
npm run dev
# Access HUD: http://localhost:5173
```

#### React Driver Self-Service Portal (Port 5174)
```bash
cd web/driver-dashboard
npm install --legacy-peer-deps
npm run dev
# Access Portal: http://localhost:5174
```

#### Flutter Mobile Client
```bash
cd MobileApp
adb reverse tcp:3000 tcp:3000
adb reverse tcp:5000 tcp:5000
flutter pub get
flutter run
```

### 10.3 Test & Simulation Scripts
* **`node simulator.js`**: Connects via WebSockets and moves a simulated vehicle through coordinates, streaming GPS and occasionally injecting simulated collision events.
* **`node test_sensors.js crash`**: Simulates a vehicle cruising at 60 km/h followed by sudden deceleration to 0 km/h with 4.5G force impact to verify emergency siren workflows.
* **`node test_sensors.js ping-timeout`**: Connects as a driver, waits for an Admin Safety Ping from the dashboard, and allows the 30-second response window to lapse to test automated emergency escalation.
* **`node test_sensors.js ping-safe`**: Receives an Admin Safety Ping and immediately confirms safe.
* **`node test_sensors.js stream`**: Continuously streams synthetic telemetry and GPS coordinates to the backend.
* **`powershell .\test_fleet.ps1`**: Automated test suite executing REST API checks and WebSocket telemetry injection.
