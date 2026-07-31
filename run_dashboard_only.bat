@echo off
title FleetGuard AI - Dashboard Launcher
echo ========================================================
echo   FleetGuard AI - Starting React Admin HUD
echo ========================================================
echo.

cd dashboard
if not exist node_modules (
    echo Installing npm dependencies for dashboard...
    call npm install
)
echo Starting React Admin Dashboard...
npm run dev

pause
