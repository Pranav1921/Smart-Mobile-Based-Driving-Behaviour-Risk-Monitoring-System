@echo off
title SmartDrive - Disk Space Quick Cleaner
echo ========================================================
echo   SmartDrive - Quick Disk Space Recovery
echo ========================================================
echo.

echo [1/3] Cleaning Windows Temp and Flutter temp caches...
del /q /s /f "%TEMP%\*.*" >nul 2>&1
del /q /s /f "C:\Windows\Temp\*.*" >nul 2>&1

echo [2/3] Cleaning Flutter build artifacts...
cd MobileApp
call flutter clean >nul 2>&1
if exist build (
    echo Cleaning MobileApp/build directory...
    rd /s /q build
)
if exist .dart_tool (
    echo Cleaning MobileApp/.dart_tool directory...
    rd /s /q .dart_tool
)
cd ..

echo [3/3] Cleaning Gradle temporary caches...
if exist "%USERPROFILE%\.gradle\caches\build-cache-1" (
    rd /s /q "%USERPROFILE%\.gradle\caches\build-cache-1" >nul 2>&1
)

echo.
echo ========================================================
echo   Cleanup completed!
echo   Please also empty your Recycle Bin or free up 1-2 GB
echo   on your C: drive, then relaunch the app.
echo ========================================================
pause
