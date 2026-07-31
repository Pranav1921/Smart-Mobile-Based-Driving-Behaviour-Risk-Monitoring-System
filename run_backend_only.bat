@echo off
title FleetGuard AI - Backend Services Launcher
echo ========================================================
echo   FleetGuard AI - Setup and Launch Backend Services Only
echo ========================================================
echo.

:: 1. Database and Cache Check / Launch
echo [1/3] Checking Docker containers for PostgreSQL and Redis...
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
echo [2/3] Setting up and starting Node.js Backend Gateway...
cd backend
if not exist node_modules (
    echo Installing npm dependencies for backend...
    call npm install
)
echo Generating Prisma client...
call npx prisma generate --schema=src/prisma/schema.prisma
start "FleetGuard-Backend" cmd /k "npm run dev"
cd ..
timeout /t 3 >nul

:: 3. Python FastAPI AI Service Setup & Launch
echo [3/3] Setting up and starting FastAPI AI Service...
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

echo.
echo ========================================================
echo   Backend services (Docker DB/Redis, Node.js API, Python FastAPI) launched!
echo   Please check individual terminal windows for logs.
echo ========================================================
pause
