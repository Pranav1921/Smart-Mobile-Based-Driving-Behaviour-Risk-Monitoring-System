# Smart Driving Behaviour & Risk Monitoring System — System Architecture Summary

### 1. Monorepo Architecture & File Structuring
Architected a modular multi-tier monorepo separating Node.js API Gateway, Python FastAPI AI microservices, React Admin Dashboard, and Flutter Mobile App.
Organized clean domain boundaries across `backend`, `dashboard`, `web/driver-dashboard`, and `MobileApp` with shared schemas and launch scripts.
- **Ref**: [`run_system.bat`](file:///c:/projects/Major_project/run_system.bat), [`run_backend_only.bat`](file:///c:/projects/Major_project/run_backend_only.bat), [`README.md`](file:///c:/projects/Major_project/README.md)
- **Remarks**: Unified repository architecture with automated multi-service batch launchers for local & staging environments.

### 2. PostgreSQL Relational Schema Design
Designed a production PostgreSQL database schema encompassing Organizations, Users, Drivers, Vehicles, Trips, Telemetry Points, Events, and Crash Reports.
Configured compound database indexes on high-throughput GIS tables `(tripId, timestamp)` for sub-millisecond query performance.
- **Ref**: [`schema.prisma`](file:///c:/Users/prana/projects/Major%20project/backend/src/prisma/schema.prisma)
- **Remarks**: Normalized 14-table relational data model supporting multi-tenant fleet isolation.

### 3. Prisma ORM & Migration Pipeline
Implemented Prisma ORM client generator and database schema migration workflows.
Provided strongly-typed database access layer eliminating raw SQL vulnerabilities and ensuring compile-time type safety.
- **Ref**: [`package.json`](file:///c:/Users/prana/projects/Major%20project/backend/package.json), [`client.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/database/client.ts)
- **Remarks**: Automated migration pipeline for rapid schema evolution across development environments.

### 4. Database Seeding & Production Data
Created a production database seeding pipeline populating realistic fleet entities, driver profiles, vehicles, and active trip telemetry.
Replaced static dummy frontend data with real PostgreSQL database records.
- **Ref**: [`seed.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/prisma/seed.ts)
- **Remarks**: Populates verified admin accounts, drivers, vehicles, and safety events on demand.

### 5. Docker Infrastructure & Containerization
Configured `docker-compose.yml` orchestrating isolated PostgreSQL 15 and Redis 7 container instances on dedicated bridge networks.
Enabled seamless local and containerized service discovery for database persistence and cache management.
- **Ref**: [`docker-compose.yml`](file:///c:/Users/prana/projects/Major%20project/backend/docker-compose.yml), [`Dockerfile`](file:///c:/Users/prana/projects/Major%20project/backend/docker/Dockerfile)
- **Remarks**: Isolated container environments with persistent named volume storage mounts.

### 6. Redis Cache & Background Job Queues
Integrated Redis 7 service for caching session state and driving event evaluation job queues via BullMQ.
Processed heavy AI trip reviews asynchronously without blocking API request threads.
- **Ref**: [`queue.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/jobs/queue.ts), [`docker-compose.yml`](file:///c:/Users/prana/projects/Major%20project/backend/docker-compose.yml#L19-L28)
- **Remarks**: Asynchronous job handling for background telemetry analysis and notification dispatches.

### 7. Node.js Express API Gateway
Developed a TypeScript Express REST API gateway providing fleet management CRUD endpoints for drivers, vehicles, trips, and events.
Structured controller-service-repository layered architecture with centralized error handling.
- **Ref**: [`app.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/app.ts), [`server.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/server.ts), [`index.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/routes/index.ts)
- **Remarks**: Layered Express architecture handling HTTP routing, middleware validation, and JSON responses.

### 8. JWT Authentication & Access Control
Implemented dual-token JWT authentication (access and refresh tokens) with bcrypt password hashing and role-based access control.
Enforced Organization-level data isolation across Super Admin, Fleet Admin, Manager, and Driver roles.
- **Ref**: [`auth.service.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/services/auth.service.ts), [`auth.middleware.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/middleware/auth.middleware.ts)
- **Remarks**: Secure authentication pipeline guarding endpoints against unauthorized multi-tenant access.

### 9. Real-Time Socket.IO Gateway Management
Engineered a WebSocket manager (`socket.io`) handling real-time rooms for organization-wide telemetry broadcasts.
Emitted real-time driver position updates, speed alerts, and critical collision notifications directly to dashboards.
- **Ref**: [`socket.manager.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/sockets/socket.manager.ts)
- **Remarks**: Low-latency bi-directional WebSocket communication channel supporting live fleet monitoring.

### 10. Python FastAPI AI Microservice Setup
Implemented an asynchronous FastAPI AI microservice for calculating driver safety scores and risk analytics.
Configured Uvicorn ASGI server executing specialized Python mathematical algorithms for driver behavior modeling.
- **Ref**: [`main.py`](file:///c:/Users/prana/projects/Major%20project/backend/app/main.py), [`requirements.txt`](file:///c:/Users/prana/projects/Major%20project/backend/requirements.txt)
- **Remarks**: Dedicated Python AI service running concurrently on port 5000.

### 11. Safety Score Analytics & Risk Algorithms
Developed mathematical scoring algorithms analyzing driving parameters (overspeed, harsh braking, acceleration, sharp turns).
Computed real-time safety scores (0-100), risk percentages, and crash probabilities for every trip.
- **Ref**: [`score_service.py`](file:///c:/Users/prana/projects/Major%20project/backend/app/services/score_service.py), [`crash_service.py`](file:///c:/Users/prana/projects/Major%20project/backend/app/services/crash_service.py)
- **Remarks**: Dynamic risk scoring models evaluating driver performance trends over 7-day and 30-day windows.

### 12. React Fleet Command Dashboard
Built a high-performance React Admin Dashboard featuring KPI metric cards, safety trends, and dark/light glassmorphism styling.
Connected UI components to REST endpoints and WebSockets for real-time fleet operations control.
- **Ref**: [`App.tsx`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/App.tsx), [`Dashboard.tsx`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/pages/Dashboard.tsx), [`apiClient.ts`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/lib/apiClient.ts)
- **Remarks**: Modern admin HUD displaying live fleet metrics and AI insights without dummy data.

### 13. GIS Live Fleet Tracking & Map Engine
Integrated an interactive GIS live map interface (`FleetMap`) rendering real-time vehicle markers, routes, and heatmaps.
Subscribed to WebSocket location updates to smoothly animate vehicle movements on the map canvas.
- **Ref**: [`LiveMap.tsx`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/pages/LiveMap.tsx), [`useSocketDrivers.ts`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/hooks/useSocketDrivers.ts)
- **Remarks**: Live GPS marker tracking with active route polylines and compliance speed zone checks.

### 14. React Driver Web Dashboard Portal
Constructed a dedicated React Driver Web Portal for drivers to log in, inspect trip histories, and review safety scores.
Rendered personalized performance feedback, driving style classifications, and streak achievements.
- **Ref**: [`App.jsx`](file:///c:/Users/prana/projects/Major%20project/web/driver-dashboard/src/App.jsx), [`DashboardHome.jsx`](file:///c:/Users/prana/projects/Major%20project/web/driver-dashboard/src/pages/DashboardHome.jsx)
- **Remarks**: Driver self-service portal improving safety awareness and eco-driving habits.

### 15. Admin Profile & Identity Management
Added an Admin Profile management section allowing administrators to view account details and update display names.
Connected form submission to `PUT /api/auth/profile` with real-time UI header synchronization.
- **Ref**: [`Profile.tsx`](file:///c:/Users/prana/projects/Major%20project/dashboard/src/pages/Profile.tsx), [`auth.controller.ts`](file:///c:/Users/prana/projects/Major%20project/backend/src/controllers/auth.controller.ts)
- **Remarks**: Admin profile management interface preserving security credential policies.

### 16. Flutter Mobile Application Architecture
Engineered a Flutter mobile application with Provider state management, material themes, and secure local storage.
Configured ADB reverse port forwarding to enable local backend communication during Android emulation.
- **Ref**: [`pubspec.yaml`](file:///c:/Users/prana/projects/Major%20project/MobileApp/pubspec.yaml), [`main.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/main.dart), [`app_urls.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/core/constants/app_urls.dart)
- **Remarks**: Clean Flutter client architecture prepared for Android & iOS deployments.

### 17. Mobile Telemetry & GPS Background Sync
Integrated background location tracking services streaming GPS coordinates, speed, and heading data during active trips.
Transmitted location telemetry over HTTP REST and WebSocket connections to the API gateway.
- **Ref**: [`api_service.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/services/api_service.dart), [`trip_provider.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/providers/trip_provider.dart)
- **Remarks**: Continuous GPS telemetry collection during driver trips.

### 18. Mobile Sensors & Real-Time Collision Detection
Integrated hardware accelerometer and gyroscope sensor streams (`sensors_plus`) to detect extreme G-force spikes.
Emitted instant `crash_alert` WebSocket events triggering emergency banner alerts on the Admin Command Center.
- **Ref**: [`socket_service.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/services/socket_service.dart), [`home_screen.dart`](file:///c:/Users/prana/projects/Major%20project/MobileApp/lib/screens/home_screen.dart)
- **Remarks**: Real-time sensor threshold triggers producing sub-second emergency collision alerts.
