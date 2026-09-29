@echo off
title Smart Driving Behaviour & Risk Monitoring System - Driver Dashboard Launcher
echo ========================================================
echo   Smart Driving AI - Starting React Driver Dashboard
echo ========================================================
echo.

cd web\driver-dashboard
if not exist node_modules\lucide-react\package.json (
    echo Incomplete or corrupted dependencies detected. Reinstalling cleanly...
    if exist node_modules rd /s /q node_modules
    if exist package-lock.json del /q package-lock.json
    call npm install --legacy-peer-deps
)
echo Starting React Driver Dashboard...
npm run dev

pause
