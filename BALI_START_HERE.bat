@echo off
setlocal
set "BASE=C:\Bali\Bali-Trader"
cd /d "%BASE%"
:menu
cls
echo ==========================================
echo          BALI OS V7C START HERE
echo ==========================================
echo Base: %BASE%
echo.
echo 1. Start Local URL Dashboard V7C
echo 2. Start Phone/LAN Dashboard V7C
echo 3. Safety Scan V7C
echo 4. Terminal Master Control V7C
echo 5. Open Latest Log
echo 6. Exit
echo.
set /p choice=Choose option: 
if "%choice%"=="1" goto local
if "%choice%"=="2" goto phone
if "%choice%"=="3" goto safety
if "%choice%"=="4" goto master
if "%choice%"=="5" goto log
if "%choice%"=="6" exit /b 0
goto menu
:local
echo Starting local dashboard. Keep the PowerShell server window open.
start "BALI URL DASHBOARD V7C" powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%BASE%\tools\BALI_LOCAL_URL_DASHBOARD_V7C.ps1" -Mode local -Port 8787
timeout /t 3 /nobreak >nul
start "" "http://localhost:8787"
pause
goto menu
:phone
echo Starting phone/LAN dashboard. Allow Windows Firewall only on private/home network if prompted.
start "BALI PHONE DASHBOARD V7C" powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%BASE%\tools\BALI_LOCAL_URL_DASHBOARD_V7C.ps1" -Mode lan -Port 8787
pause
goto menu
:safety
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%\tools\BALI_OS_SAFETY_SCAN_V7C.ps1"
pause
goto menu
:master
call "%BASE%\BALI_MASTER_CONTROL.bat"
goto menu
:log
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\DASHBOARD_LOGS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){notepad $f.FullName}else{Write-Host 'No dashboard logs found.'; pause}"
goto menu
