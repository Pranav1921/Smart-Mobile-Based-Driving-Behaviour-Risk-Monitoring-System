@echo off
title Smart Driving Behaviour & Risk Monitoring System - Backend Services Launcher
echo ========================================================
echo   Smart Driving Behaviour & Risk Monitoring System
echo   Setup and Launch Backend Services Only
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
    start "SmartDrive-Docker" cmd /k "docker-compose up db redis"
    cd ..
    timeout /t 5 >nul
)

:: 2. Node.js Backend Gateway Setup & Launch
echo [2/3] Setting up and starting Node.js Backend Gateway...
cd backend
if not exist node_modules\ts-node\dist\index.js (
    echo Incomplete backend packages detected. Reinstalling cleanly...
    if exist node_modules rd /s /q node_modules
    call npm install
)
echo Generating Prisma client...
call npx prisma generate --schema=src/prisma/schema.prisma
start "SmartDrive-Backend" cmd /k "npm run dev"
cd ..
timeout /t 3 >nul

:: 3. Python FastAPI AI Service Setup & Launch
echo [3/3] Setting up and starting FastAPI AI Service...
cd backend
if not exist venv\Scripts\python.exe (
    echo Creating virtual environment for AI microservice...
    python -m venv venv
)
if not exist venv\Scripts\uvicorn.exe (
    echo Installing pip dependencies for FastAPI...
    call venv\Scripts\pip install -r requirements.txt
)
start "SmartDrive-AI-Service" cmd /k "call venv\Scripts\activate.bat && venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"
cd ..
timeout /t 3 >nul

echo.
echo ========================================================
echo   Backend services (Docker DB/Redis, Node.js API, Python FastAPI) launched!
echo   Please check individual terminal windows for logs.
echo ========================================================
pause
