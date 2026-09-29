# SmartDrive AI Backend

Production-ready backend for **SmartDrive AI** — an AI-powered Smart Mobile-Based Driving Behaviour & Risk Monitoring System.

This backend coordinates authentication, fleet/driver profiles, live GPS tracking, telemetry event logging, AI safety score audits, crash reports, and operational PDF/Excel reports. Built on a modular **Clean Architecture** utilizing TypeScript, Node.js, Prisma ORM, and Socket.IO.

---

## Tech Stack

- **Runtime**: Node.js LTS (v24+)
- **Language**: TypeScript (strict-mode)
- **Framework**: Express.js
- **Database**: PostgreSQL (Prisma ORM)
- **Real-Time Communication**: Socket.IO
- **Background Jobs Queue**: BullMQ (powered by Redis)
- **Logging**: Winston Logger (split into app, requests, and error log targets)
- **Validation**: Zod Schemas
- **Security**: Helmet headers, CORS policies, Express rate limiting, Bcrypt hashing, JWT tokens
- **Exports**: PDFKit (PDFs), ExcelJS (Excel/XLSX), CSV

---

## Workspace Layout

```text
backend/
├── src/
│   ├── config/             # App configs (logger, etc.)
│   ├── database/           # Prisma client singleton & seed scripts
│   ├── prisma/             # Prisma DB schema definitions
│   ├── middleware/         # Auth, RBAC guards, rate limiters, global error handles, audit logs
│   ├── routes/             # REST endpoints mapped under /api/v1
│   ├── controllers/        # Request controllers executing Zod checks & calling services
│   ├── services/           # Business logic (Auth, Driver, Vehicle, Trip, Event, Crash, Report)
│   ├── repositories/       # Prisma query abstraction classes (Repository Pattern)
│   ├── sockets/            # Socket.IO handshake filters & gps_update rooms logic
│   ├── jobs/               # BullMQ connection configs & background task workers
│   ├── ai/                 # Telemetry analytics scoring & LLM summaries
│   ├── storage/            # Media uploading (Cloudinary with local failover)
│   ├── validators/         # Zod schemas matching REST paths
│   ├── docs/               # Swagger specs configurations
│   ├── tests/              # Jest integration testing suites
│   ├── app.ts              # Express configuration
│   └── server.ts           # Server start, Socket.IO bind, and DB connections check
├── docker/                 # Container deployment files (Dockerfile)
├── ecosystem.config.js     # PM2 cluster configuration
├── docker-compose.yml      # DB, Redis, and Application orchestrations
├── jest.config.ts          # Jest settings
├── package.json
└── tsconfig.json
```

---

## Setup & Running Locally

### Prerequisites
- Node.js LTS (v20+)
- PostgreSQL Database
- Redis Server (for BullMQ queues)

### 1. Installation
Install project packages:
```bash
npm install
```

### 2. Environment Configurations
Create `.env` using `.env.example` as a template and adjust connection URLs:
```bash
cp .env.example .env
```

### 3. Database Migrations & Seeds
Run Prisma migrations to set up the database schema:
```bash
npx prisma migrate dev --schema=src/prisma/schema.prisma
```
Generate Prisma client types:
```bash
npx prisma generate --schema=src/prisma/schema.prisma
```
Seed default logistics companies, fleet managers, settings, drivers, and vehicles:
```bash
npm run db:seed
```

### 4. Running the App
Start in development mode (with hot-reloading):
```bash
npm run dev
```
For production deployment, compile and run the built files:
```bash
npm run build
npm start
```

---

## Testing & Documentation

- **Running Tests**: Run automated Jest integration suites using:
  ```bash
  npm test
  ```
- **API Swagger Documentation**: Access interactive documentation via Swagger UI at:
  ```text
  http://localhost:3000/api-docs
  ```

---

## Production Deployments

### 1. Docker Compose
Spin up the entire stack (PostgreSQL, Redis, and Express application) in containers:
```bash
docker-compose up --build -d
```

### 2. PM2 (Process Manager)
Run clustered Node.js instances scaling across multiple CPU cores:
```bash
pm2 start ecosystem.config.js
```