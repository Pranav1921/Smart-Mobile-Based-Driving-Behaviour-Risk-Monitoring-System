@echo off
title Smart Driving Behaviour & Risk Monitoring System - Start All Services

echo ================================================================
echo   Smart Driving Behaviour & Risk Monitoring System
echo   Launching All Services
echo ================================================================
echo.

cd /d "%~dp0"

echo [1/4] Starting Node.js Backend Gateway (port 3000)...
cd backend
if not exist node_modules (
    call npm install
)
call npx prisma generate --schema=src/prisma/schema.prisma
start "SmartDrive-Backend" cmd /k "npm run dev"
cd ..
timeout /t 3 /nobreak > nul

echo [2/4] Starting Python FastAPI AI Service (port 5000)...
cd backend
if not exist venv\Scripts\python.exe (
    echo Creating virtual environment for AI microservice...
    python -m venv venv
)
if not exist venv\Scripts\uvicorn.exe (
    echo Installing pip dependencies for FastAPI...
    call venv\Scripts\pip.exe install -r requirements.txt
)
start "SmartDrive-AI-Service" cmd /k "call venv\Scripts\activate.bat && venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"
cd ..
timeout /t 3 /nobreak > nul

echo [3/4] Starting React Admin Dashboard (port 5173)...
cd dashboard
if not exist node_modules (
    call npm install
)
start "SmartDrive-Admin-Dashboard" cmd /k "npm run dev"
cd ..
timeout /t 2 /nobreak > nul

echo [4/4] Starting Driver Dashboard (port 5174)...
cd web\driver-dashboard
if not exist node_modules (
    call npm install
)
start "SmartDrive-Driver-Dashboard" cmd /k "npm run dev"
cd ..\..

echo.
echo ================================================================
echo  All services launched in separate windows!
echo.
echo  Backend API (Node.js):   http://localhost:3000
echo  AI Engine (FastAPI):     http://localhost:5000
echo  Admin Dashboard (React): http://localhost:5173
echo  Driver Dashboard:        http://localhost:5174
echo ================================================================
pause
