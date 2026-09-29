@echo off
title Smart Driving AI - Driver Dashboard Reinstall & Fix
echo ========================================================
echo   Smart Driving AI - Fixing Driver Dashboard Dependencies
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Removing stale cache and corrupted node_modules...
if exist node_modules rd /s /q node_modules
if exist package-lock.json del /q package-lock.json
if exist .vite rd /s /q .vite

echo [2/3] Installing fresh dependencies from package.json...
call npm install --legacy-peer-deps

echo [3/3] Starting Driver Dashboard...
call npm run dev

pause
