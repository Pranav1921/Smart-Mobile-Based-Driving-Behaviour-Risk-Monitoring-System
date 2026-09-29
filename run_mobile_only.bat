@echo off
title Smart Driving Behaviour & Risk Monitoring System - Flutter Mobile App Launcher
echo ========================================================
echo   Smart Driving Behaviour & Risk Monitoring System
echo   Setup and Launch Flutter Mobile App Only
echo ========================================================
echo.

cd MobileApp

:: 1. ADB setup for Android Emulator
echo [1/3] Checking for connected Android devices/emulators...
adb devices

echo.
echo [2/3] Setting up ADB port forwarding (reverse tcp:3000)...
echo This allows the app to communicate with the local Node.js backend on port 3000.
adb reverse tcp:3000 tcp:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo [NOTE] adb reverse failed. This is normal if you are running on iOS simulator or physical devices.
)

:: 2. Fetch packages
echo.
echo [3/3] Getting Flutter dependencies...
call flutter pub get

:: 3. Launch App
echo.
start "SmartDrive-Mobile-App" cmd /k "set "ANDROID_PREFS_ROOT=" && set "ANDROID_USER_HOME=" && set "ANDROID_SDK_HOME=" && set "JAVA_HOME=C:\Program Files\Java\jdk-17" && flutter run"

cd ..
echo ========================================================
echo   Flutter launch process started in a separate window!
echo ========================================================
pause
