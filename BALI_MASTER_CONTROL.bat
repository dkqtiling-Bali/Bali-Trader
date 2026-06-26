@echo off
setlocal
set "BASE=C:\Bali\Bali-Trader"
cd /d "%BASE%"
:menu
cls
echo ==========================================
echo        BALI OS V5A MASTER CONTROL
echo ==========================================
echo Base: %BASE%
echo.
echo 1. Start Automated Session V5A
echo 2. Concise AI Handover / Clipboard
echo 3. Recommend Highest-Value Next Patch
echo 4. Safety Scan V5
echo 5. Generate Project Map
echo 6. Generate Evidence Index + Run Registry
echo 7. Generate Status Dashboard
echo 8. Git Safe Save / Backup V5
echo 9. Open Latest Handover
echo 10. Open Latest Status Dashboard
echo 11. Open Recommendation
echo 12. Open Constitution
echo 13. Open Ledger
echo 14. Exit
echo.
set /p choice=Choose option: 
if "%choice%"=="1" goto session
if "%choice%"=="2" goto handover
if "%choice%"=="3" goto recommend
if "%choice%"=="4" goto safety
if "%choice%"=="5" goto map
if "%choice%"=="6" goto evidence
if "%choice%"=="7" goto status
if "%choice%"=="8" goto git
if "%choice%"=="9" goto openhandover
if "%choice%"=="10" goto openstatus
if "%choice%"=="11" goto openrec
if "%choice%"=="12" goto constitution
if "%choice%"=="13" goto ledger
if "%choice%"=="14" goto end
goto menu

:session
echo Running Bali OS V5 automated session...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Session -Base "C:\Bali\Bali-Trader"
pause
goto menu

:handover
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Handover -Base "C:\Bali\Bali-Trader"
pause
goto menu

:recommend
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Recommend -Base "C:\Bali\Bali-Trader"
start "" "C:\Bali\Bali-Trader\NEXT_PATCH_RECOMMENDATION_LATEST.txt"
pause
goto menu

:safety
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_SAFETY_SCAN_V5.ps1" -Base "C:\Bali\Bali-Trader" -WriteReport
pause
goto menu

:map
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Map -Base "C:\Bali\Bali-Trader"
start "" "C:\Bali\Bali-Trader\PROJECT_MAP.md"
pause
goto menu

:evidence
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Evidence -Base "C:\Bali\Bali-Trader"
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Registry -Base "C:\Bali\Bali-Trader"
start "" "C:\Bali\Bali-Trader\EVIDENCE_INDEX.md"
pause
goto menu

:status
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Status -Base "C:\Bali\Bali-Trader"
start "" "C:\Bali\Bali-Trader\BALI_STATUS_LATEST.txt"
pause
goto menu

:git
echo Running Git Safe Save V5...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V5.ps1" -Base "C:\Bali\Bali-Trader"
pause
goto menu

:openhandover
if exist "C:\Bali\Bali-Trader\LATEST_CHAT_HANDOVER.txt" start "" "C:\Bali\Bali-Trader\LATEST_CHAT_HANDOVER.txt"
pause
goto menu

:openstatus
if exist "C:\Bali\Bali-Trader\BALI_STATUS_LATEST.txt" start "" "C:\Bali\Bali-Trader\BALI_STATUS_LATEST.txt"
pause
goto menu

:openrec
if exist "C:\Bali\Bali-Trader\NEXT_PATCH_RECOMMENDATION_LATEST.txt" start "" "C:\Bali\Bali-Trader\NEXT_PATCH_RECOMMENDATION_LATEST.txt"
pause
goto menu

:constitution
if exist "C:\Bali\Bali-Trader\CONSTITUTION.md" start "" "C:\Bali\Bali-Trader\CONSTITUTION.md"
pause
goto menu

:ledger
if exist "C:\Bali\Bali-Trader\LEDGER.md" start "" "C:\Bali\Bali-Trader\LEDGER.md"
pause
goto menu

:end
endlocal
exit /b 0

