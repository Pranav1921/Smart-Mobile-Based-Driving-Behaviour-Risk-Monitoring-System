@echo off
title FleetGuard AI - Driver Dashboard Launcher
echo ========================================================
echo   FleetGuard AI - Starting React Driver Dashboard
echo ========================================================
echo.

cd web\driver-dashboard
if not exist node_modules (
    echo Installing npm dependencies for driver dashboard...
    call npm install
)
echo Starting React Driver Dashboard...
npm run dev

pause
