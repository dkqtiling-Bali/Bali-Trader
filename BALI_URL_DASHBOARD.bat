@echo off
setlocal
cd /d C:\Bali\Bali-Trader
cls
echo ==========================================
echo       BALI OS V6E LOCAL URL DASHBOARD
echo ==========================================
echo Safe local dashboard only.
echo URL: http://localhost:8787
echo Phone/LAN may work at http://YOUR-PC-IP:8787 if firewall allows.
echo Keep this window open while using the browser dashboard.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_LOCAL_URL_DASHBOARD_V6E.ps1"
echo.
echo Dashboard stopped.
pause
