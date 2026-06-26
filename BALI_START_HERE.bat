@echo off
setlocal
cd /d C:\Bali\Bali-Trader
:menu
cls
echo ==========================================
echo          BALI OS V6E START HERE
echo ==========================================
echo Base: C:\Bali\Bali-Trader
echo.
echo 1. Open Local URL Dashboard V6E
echo 2. Start Day / Auto Session V6E
echo 3. Safety Scan V6E
echo 4. Git Safe Save / Backup V6E
echo 5. Open Terminal Master Control V6E
echo 6. Open Latest Recommendation
echo 7. Open Latest Safety Report
echo 8. Exit
echo.
set /p choice=Choose option: 
if "%choice%"=="1" goto url
if "%choice%"=="2" goto auto
if "%choice%"=="3" goto safety
if "%choice%"=="4" goto git
if "%choice%"=="5" goto master
if "%choice%"=="6" goto rec
if "%choice%"=="7" goto safetyreport
if "%choice%"=="8" exit /b 0
goto menu
:url
call C:\Bali\Bali-Trader\BALI_URL_DASHBOARD.bat
goto menu
:auto
call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat auto
goto menu
:safety
call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat safety
goto menu
:git
call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat git
goto menu
:master
call C:\Bali\Bali-Trader\BALI_MASTER_CONTROL.bat
goto menu
:rec
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\NEXT_PATCH_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No recommendation found'; pause}"
goto menu
:safetyreport
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\SAFETY_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No safety report found'; pause}"
goto menu
