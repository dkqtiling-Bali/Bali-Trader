@echo off
setlocal
cd /d C:\Bali\Bali-Trader
:menu
cls
echo ==========================================
echo        BALI OS V6E MASTER CONTROL
echo ==========================================
echo Base: C:\Bali\Bali-Trader
echo.
echo 1. Open Local URL Dashboard V6E
echo 2. Start Day / Auto Session V6E
echo 3. Concise AI Handover / Clipboard
echo 4. Recommend Highest-Value Next Patch
echo 5. Safety Scan V6E
echo 6. Generate Project Map
echo 7. Generate Evidence Index + Run Registry
echo 8. Git Safe Save / Backup V6E
echo 9. Open Latest Handover
echo 10. Open Latest Status Dashboard
echo 11. Open Recommendation
echo 12. Open Latest Safety Report
echo 13. Open Constitution
echo 14. Open Ledger
echo 15. Exit
echo.
set /p choice=Choose option: 
if "%choice%"=="1" call C:\Bali\Bali-Trader\BALI_URL_DASHBOARD.bat
if "%choice%"=="2" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat auto
if "%choice%"=="3" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat handover
if "%choice%"=="4" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat recommend
if "%choice%"=="5" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat safety
if "%choice%"=="6" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat map
if "%choice%"=="7" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat evidence
if "%choice%"=="8" call C:\Bali\Bali-Trader\tools\BALI_DASHBOARD_SAFE_RUN_V6E.bat git
if "%choice%"=="9" powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\AI_HANDOVER_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No handover found'; pause}"
if "%choice%"=="10" powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\STATUS_DASHBOARDS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No status found'; pause}"
if "%choice%"=="11" powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\NEXT_PATCH_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No recommendation found'; pause}"
if "%choice%"=="12" powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem 'C:\Bali\Bali-Trader\SAFETY_REPORTS' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($f){Start-Process notepad $f.FullName}else{Write-Host 'No safety report found'; pause}"
if "%choice%"=="13" if exist C:\Bali\Bali-Trader\CONSTITUTION.md start notepad C:\Bali\Bali-Trader\CONSTITUTION.md
if "%choice%"=="14" if exist C:\Bali\Bali-Trader\LEDGER.md start notepad C:\Bali\Bali-Trader\LEDGER.md
if "%choice%"=="15" exit /b 0
goto menu
