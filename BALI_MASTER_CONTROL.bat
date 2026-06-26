@echo off
setlocal
set "BASE=C:\Bali\Bali-Trader"
cd /d "%BASE%"
:menu
cls
echo ==========================================
echo       BALI OS V7C MASTER CONTROL
echo ==========================================
echo Base: %BASE%
echo.
echo 1. Start Automated Session
echo 2. Git Safe Save / Backup
echo 3. Safety Scan
echo 4. Recommend Next Patch
echo 5. Generate Handover
echo 6. Open URL Dashboard
echo 7. Open Latest Recommendation
echo 8. Open Latest Handover
echo 9. Exit
echo.
set /p choice=Choose option: 
if "%choice%"=="1" goto auto
if "%choice%"=="2" goto git
if "%choice%"=="3" goto safety
if "%choice%"=="4" goto recommend
if "%choice%"=="5" goto handover
if "%choice%"=="6" goto dash
if "%choice%"=="7" goto openrec
if "%choice%"=="8" goto openhan
if "%choice%"=="9" exit /b 0
goto menu
:auto
call "%BASE%\tools\BALI_DASHBOARD_SAFE_RUN_V7C.bat" auto
goto menu
:git
call "%BASE%\tools\BALI_DASHBOARD_SAFE_RUN_V7C.bat" git
goto menu
:safety
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%\tools\BALI_OS_SAFETY_SCAN_V7C.ps1"
pause
goto menu
:recommend
call "%BASE%\tools\BALI_DASHBOARD_SAFE_RUN_V7C.bat" recommend
goto menu
:handover
call "%BASE%\tools\BALI_DASHBOARD_SAFE_RUN_V7C.bat" handover
goto menu
:dash
start "BALI URL DASHBOARD V7C" powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%BASE%\tools\BALI_LOCAL_URL_DASHBOARD_V7C.ps1" -Mode local -Port 8787
timeout /t 3 /nobreak >nul
start "" "http://localhost:8787"
goto menu
:openrec
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\NEXT_PATCH_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){notepad $f.FullName}else{Write-Host 'No recommendation found.'; pause}"
goto menu
:openhan
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\AI_HANDOVER_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){notepad $f.FullName}else{Write-Host 'No handover found.'; pause}"
goto menu
