@echo off
cd /d "%~dp0"

echo [1/4] Starting Node.js Backend Gateway (port 3000)...
start "SmartDrive-Backend" cmd /k "cd /d %~dp0backend && set "NODE_OPTIONS=--max-old-space-size=4096" && npm run dev"

ping 127.0.0.1 -n 3 > nul

echo [2/4] Starting Python FastAPI AI Service (port 5000)...
start "SmartDrive-AI-Service" cmd /k "cd /d %~dp0backend && call venv\Scripts\activate.bat && venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"

ping 127.0.0.1 -n 3 > nul

echo [3/4] Starting React Admin Dashboard (port 5173)...
start "SmartDrive-Admin-Dashboard" cmd /k "cd /d %~dp0dashboard && set NODE_OPTIONS=--max-old-space-size=2048 && npm run dev"

ping 127.0.0.1 -n 3 > nul

echo [4/4] Starting Driver Dashboard (port 5174)...
start "SmartDrive-Driver-Dashboard" cmd /k "cd /d %~dp0web\driver-dashboard && npm run dev"

echo All services launched successfully!
