@echo off
setlocal
set "BASE=C:\Bali\Bali-Trader"
cd /d "%BASE%"
echo Starting Bali phone/LAN dashboard V7C...
start "BALI PHONE DASHBOARD V7C" powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%BASE%\tools\BALI_LOCAL_URL_DASHBOARD_V7C.ps1" -Mode lan -Port 8787
pause
