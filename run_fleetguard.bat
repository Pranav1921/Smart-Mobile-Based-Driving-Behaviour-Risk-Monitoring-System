@echo off
title FleetGuard AI - Complete Services Launcher
echo ========================================================
echo   FleetGuard AI - Setup and Launch Services
echo ========================================================
echo.

:: 1. Database and Cache Check / Launch
echo [1/6] Checking Docker containers for PostgreSQL and Redis...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Docker is not installed or not in PATH. Make sure local PostgreSQL and Redis are running.
) else (
    echo Starting PostgreSQL and Redis containers...
    cd backend
    start "FleetGuard-Docker" cmd /k "docker-compose up db redis"
    cd ..
    timeout /t 5 >nul
)

:: 2. Node.js Backend Gateway Setup & Launch
echo [2/6] Setting up and starting Node.js Backend Gateway...
cd backend
if not exist node_modules (
    echo Installing npm dependencies for backend...
    call npm install
)
:: Generate Prisma client
echo Generating Prisma client...
call npx prisma generate --schema=src/prisma/schema.prisma
start "FleetGuard-Backend" cmd /k "npm run dev"
cd ..
timeout /t 3 >nul

:: 3. Python FastAPI AI Service Setup & Launch
echo [3/6] Setting up and starting FastAPI AI Service...
cd backend
if not exist venv (
    echo Creating virtual environment for AI microservice...
    python -m venv venv
    call venv\Scripts\activate.bat
    echo Installing pip dependencies...
    pip install -r requirements.txt
)
start "FleetGuard-AI-Service" cmd /k "call venv\Scripts\activate.bat && python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"
cd ..
timeout /t 3 >nul

:: 4. React Admin Dashboard Setup & Launch
echo [4/6] Setting up and starting React Admin HUD...
cd dashboard
if not exist node_modules (
    echo Installing npm dependencies for dashboard...
    call npm install
)
start "FleetGuard-Dashboard" cmd /k "npm run dev"
cd ..
timeout /t 3 >nul

:: 5. React Driver Dashboard Setup & Launch
echo [5/6] Setting up and starting React Driver Dashboard...
cd web\driver-dashboard
if not exist node_modules (
    echo Installing npm dependencies for driver dashboard...
    call npm install
)
start "FleetGuard-Driver-Dashboard" cmd /k "npm run dev"
cd ..\..
timeout /t 3 >nul

:: 6. Flutter Mobile Client Setup & Launch
echo [6/6] Setting up and starting Flutter Mobile Client...
cd MobileApp
echo Running adb reverse tcp:3000 tcp:3000 for Android emulation...
adb reverse tcp:3000 tcp:3000 >nul 2>&1
echo Running flutter pub get...
call flutter pub get
start "FleetGuard-Mobile-App" cmd /k "flutter run"
cd ..

echo.
echo ========================================================
echo   Setup triggered and all processes launched in separate windows!
echo   Please check individual terminal windows for logs.
echo ========================================================
pause
