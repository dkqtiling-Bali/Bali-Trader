@echo off
setlocal
set "BASE=C:\Bali\Bali-Trader"
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=auto"
cd /d "%BASE%"
echo ==========================================
echo        BALI DASHBOARD SAFE RUN V7C
echo ==========================================
echo Action: %ACTION%
echo Base: %BASE%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%\tools\BALI_OS_ENGINE_V7C.ps1" -Action "%ACTION%"
echo.
echo Finished action: %ACTION%
echo Check DASHBOARD_LOGS or latest report if anything did not open clearly.
pause
