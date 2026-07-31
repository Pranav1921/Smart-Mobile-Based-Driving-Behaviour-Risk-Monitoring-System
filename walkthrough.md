# Walkthrough – FleetGuard AI Gamification Complete

We have completed the implementation of the three missing components of **FleetGuard AI** and connected them to form a unified, commercial-grade telematics ecosystem.

---

## 🛠️ Summary of Accomplishments

### 1. Python FastAPI AI Service (`backend/app`)
* **Implemented Microservice Entrypoint**: Added `main.py` configuring uvicorn server binding and CORS middleware.
* **Core Rule-Based Engines**:
  - `score_service.py`: Computes trip safety scores (starting at 100 with event-based deductions) and risk score increments. Performs driver safety behavior classifications (Conservative, Balanced, Aggressive).
  - **Gamification calculations**: Calculates XP rewards (Base 100 XP + Safety Score * 1.5) and awards badges on completion.
  - `crash_service.py`: Analyzes G-force acceleration vectors to predict crash probability and format clear investigation summaries.
* **REST Routing API**: Added `/api/v1/ai/evaluate-trip` and `/api/v1/ai/generate-crash-summary` endpoints.

### 2. Node.js Backend Gateway Link & Database (`backend/src`)
* **Redirected Telemetry Audits**: Refactored `ai.service.ts` to make HTTP calls to the FastAPI engine at `${AI_SERVICE_URL}` instead of performing local scoring.
* **Database Persisted Gamification**: Updated `schema.prisma` and seeds file to persist driver levels, XP totals, streaks, and achievements arrays in PostgreSQL database records.
* **Swadeshi Ordering Site Serving**: Configured express static routing to serve the Swadeshi dispatch portal statically at `/orders-client/` directly on the Node.js API gateway.

### 3. Swadeshi Order Portal (`web/orders-client`)
* **Clean Light Theme Portal**: Developed `index.html` designed with a high-contrast white card grid layout matching the **piSignage** template.
* **Indian Script Typography**: Uses the **Yatra One** Google Font (`स्वदेशी OrderGuard`) for a beautiful Indian calligraphic branding.
* **Monetary Word Translators**: Implemented dynamic text converters displaying order values formatted in Indian Rupees (`₹`) and Lakhs/Crores words.
* **Indian Landmarks Geolocation**: Links checkout coordinates to real hubs (Mumbai, Delhi, Kolkata, Hyderabad, Bengaluru) and posts orders directly to `/api/v1/orders`.

### 4. React Command Center Dashboard (`dashboard`)
* **Light Theme Toggle Enforcement**: Forced the React dashboard theme provider to lock to `light` to match the clean white-card style of piSignage.
* **Indian Branding Title**: Updated brand headers inside `Sidebar.tsx` to `स्वदेशी FleetGuard`.
* **Swadeshi Orders Console**: Created `Orders.tsx` showing gross dispatches, Indian Rupees accounting logs, and parcel telemetry coordinates.

### 5. Connected Flutter Driver Client (`MobileApp`)
* **Forced Light Mode**: Configured `app.dart` to load in `ThemeMode.light` by default.
* **Clean piSignage Theme**: Overhauled `app_colors.dart` and `app_theme.dart` to use light slate backgrounds (`#F8FAFC`), pure white cards (`#FFFFFF`), and **Royal Blue** (`0xFF0038FF`) branding.
* **Maximum Contrast Text & Borders**: Configured core colors to use pure solid black (`#000000`) for primary text and dark slate gray (`#94A3B8`) for card borders to guarantee 100% readability.
* **Flat Minimal Cards**: Removed all `BackdropFilter` blur overlays from `GlassCard` widgets to prevent screen distortion and ensure razor-sharp rendering of texts and inputs.
* **Polished Micro-Animations**:
  - **Light Particle Starfield (No Bubbles)**: Features a clean, delicate, twinkling floating starfield animation with zero background bubbles/radial gradients.
  - **Online Pulse**: Toggles a stateful pulsing green glow shadow around the driver status dot when shift is active.
  - **Elastic Rotation**: Adds a 360-degree elastic spin transition to the active vehicle icon when toggling online telemetry.

---

## 🚀 How to Run the Stack

Follow these steps to launch the entire FleetGuard AI environment:

### Step 1: Initialize Database & Caching
Make sure PostgreSQL and Redis are running. You can run them using Docker:
```bash
cd backend
docker-compose up db redis -d
```
Or use your local service installations. Verify the credentials inside `backend/.env`.

### Step 2: Set Up and Run the Node.js Backend & Ordering Portal
Navigate to the `backend` directory, install packages, compile the database client, run migration, and seed the default accounts:
```bash
cd backend
npm install
npx prisma generate --schema=src/prisma/schema.prisma
npx prisma migrate dev --schema=src/prisma/schema.prisma
npm run db:seed
npm run dev
```
*The backend API runs on `http://localhost:3000`.*
*The Swadeshi Ordering Portal runs statically at `http://localhost:3000/orders-client/`.*

### Step 3: Run the Python FastAPI AI Microservice
Create a virtual environment, install requirements, and start the FastAPI service:
```bash
cd backend
python -m venv venv
venv\Scripts\activate   # On Windows
pip install -r requirements.txt
python app/main.py
```
*The AI microservice starts on `http://localhost:5000`.*

### Step 4: Run the React Enterprise Admin Dashboard
Navigate to the nested dashboard Vite project, install dependencies, and start the local development server:
```bash
cd dashboard
npm install
npm run dev
```
*Open `http://localhost:5173` in your browser to view the Command Center.*

### Step 5: Run the Flutter Mobile App
Launch the Flutter application on your emulator or physical device:
```bash
cd MobileApp
flutter pub get
flutter run
```
