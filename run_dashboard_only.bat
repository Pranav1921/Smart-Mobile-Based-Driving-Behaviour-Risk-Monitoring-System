@echo off
title Smart Driving Behaviour & Risk Monitoring System - Dashboard Launcher
echo ========================================================
echo   Smart Driving Risk Intelligence - Starting React Admin HUD
echo ========================================================
echo.

cd dashboard
if not exist node_modules\rollup\dist\es\parseAst.js (
    echo Incomplete or corrupted packages detected. Reinstalling cleanly...
    if exist node_modules rd /s /q node_modules
    call npm install
)
echo Starting React Admin Dashboard...
npm run dev

pause
