@echo off
title Smart Driving Behaviour & Risk Monitoring System - Restart Services

echo ================================================================
echo   Restarting All Services
echo ================================================================

cd /d "%~dp0"

echo [1/4] Starting Node.js Backend Gateway (port 3000)...
cd backend
start "SmartDrive-Backend" cmd /k "set "NODE_OPTIONS=--max-old-space-size=4096" && npm run dev"
cd ..
ping 127.0.0.1 -n 3 > nul

echo [2/4] Starting Python FastAPI AI Service (port 5000)...
cd backend
start "SmartDrive-AI-Service" cmd /k "call venv\Scripts\activate.bat && venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"
cd ..
ping 127.0.0.1 -n 3 > nul

echo [3/4] Starting React Admin Dashboard (port 5173)...
cd dashboard
start "SmartDrive-Admin-Dashboard" cmd /k "npm run dev"
cd ..
ping 127.0.0.1 -n 3 > nul

echo [4/4] Starting Driver Dashboard (port 5174)...
cd web\driver-dashboard
start "SmartDrive-Driver-Dashboard" cmd /k "npm run dev"
cd ..\..

echo ================================================================
echo   Services successfully spawned in separate console windows!
echo ================================================================
