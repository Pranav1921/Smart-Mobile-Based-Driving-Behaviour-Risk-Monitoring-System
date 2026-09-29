@echo off
echo =========================================================
echo   SMARTDRIVE - FIXING CORRUPTED GRADLE CACHE
echo =========================================================
echo.

echo [1/4] Killing running Java / Gradle daemons...
taskkill /F /IM java.exe >nul 2>&1
taskkill /F /IM javaw.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1

echo [2/4] Removing corrupted Gradle journal and transform caches...
rd /s /q "%USERPROFILE%\.gradle\caches\journal-1" >nul 2>&1
rd /s /q "%USERPROFILE%\.gradle\caches\8.13" >nul 2>&1
rd /s /q "%USERPROFILE%\.gradle\caches\transforms-3" >nul 2>&1
rd /s /q "%USERPROFILE%\.gradle\caches\transforms-4" >nul 2>&1
rd /s /q "%USERPROFILE%\.gradle\daemon" >nul 2>&1

echo [3/4] Cleaning local MobileApp android build artifacts...
rd /s /q "%~dp0MobileApp\android\.gradle" >nul 2>&1
rd /s /q "%~dp0MobileApp\android\app\build" >nul 2>&1
rd /s /q "%~dp0MobileApp\build" >nul 2>&1
rd /s /q "%~dp0MobileApp\.dart_tool" >nul 2>&1

echo [4/4] Running flutter clean and flutter pub get...
cd /d "%~dp0MobileApp"
call flutter clean
call flutter pub get

echo.
echo =========================================================
echo   SUCCESS! Corrupted cache has been completely reset.
echo   You can now launch the app: flutter run -d V2149
echo =========================================================
timeout /t 3 >nul
