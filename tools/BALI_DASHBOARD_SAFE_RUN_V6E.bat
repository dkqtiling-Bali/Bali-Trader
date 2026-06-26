@echo off
setlocal
set ACTION=%~1
if "%ACTION%"=="" set ACTION=auto
cd /d C:\Bali\Bali-Trader
cls
echo ==========================================
echo       BALI DASHBOARD SAFE RUN V6E
echo ==========================================
echo Action: %ACTION%
echo Base: C:\Bali\Bali-Trader
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V6E.ps1" -Action "%ACTION%"
echo.
echo Finished action: %ACTION%
echo Check DASHBOARD_LOGS or latest report if anything did not open clearly.
pause
