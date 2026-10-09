@echo off
title SmartDrive - Cloudflare Public Tunnel (Internet Wireless Access)
echo =============================================================
echo   SmartDrive - Cloudflare Public Internet Tunnel
echo   Exposing local backend (port 3000) to the public Internet
echo =============================================================
echo.
echo Connecting to Cloudflare global edge...
echo Look for the public URL ending with ".trycloudflare.com" below.
echo You can enter that URL into your mobile app from ANY network (4G/5G).
echo.
if exist "C:\Program Files (x86)\cloudflared\cloudflared.exe" (
    "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:3000
) else if exist "C:\Program Files\cloudflared\cloudflared.exe" (
    "C:\Program Files\cloudflared\cloudflared.exe" tunnel --url http://localhost:3000
) else (
    cloudflared tunnel --url http://localhost:3000
)
pause
