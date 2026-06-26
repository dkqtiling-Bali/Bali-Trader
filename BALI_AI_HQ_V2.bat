@echo off
title BALI AI HQ V2
cd /d "%~dp0"

:MENU
cls
echo ==========================================
echo              BALI AI HQ V2
echo ==========================================
echo.
echo 1. Generate AI Handover V2
echo 2. Recommend Next Patch
echo 3. Safety Lock Scan
echo 4. Git Status
echo 5. Backup to GitHub
echo 6. Open Project Brain
echo 7. Exit
echo.
set /p choice=Choose option: 

if "%choice%"=="1" goto HANDOVER
if "%choice%"=="2" goto RECOMMEND
if "%choice%"=="3" goto SAFETY
if "%choice%"=="4" goto STATUS
if "%choice%"=="5" goto PUSH
if "%choice%"=="6" goto BRAIN
if "%choice%"=="7" exit
goto MENU

:HANDOVER
powershell -ExecutionPolicy Bypass -File "tools\BALI_AI_HQ_V2_ANALYSE.ps1" HANDOVER
pause
goto MENU

:RECOMMEND
powershell -ExecutionPolicy Bypass -File "tools\BALI_AI_HQ_V2_ANALYSE.ps1" RECOMMEND
pause
goto MENU

:SAFETY
powershell -ExecutionPolicy Bypass -File "tools\BALI_AI_HQ_V2_ANALYSE.ps1" SAFETY
pause
goto MENU

:STATUS
git status
pause
goto MENU

:PUSH
git add .
git commit -m "Bali AI HQ V2 backup update"
git push
pause
goto MENU

:BRAIN
code MISSION.md LEDGER.md NEXT_PATCH.md AI_RULES.md
pause
goto MENU
