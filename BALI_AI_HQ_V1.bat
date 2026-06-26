@echo off
title BALI AI HQ V1
cd /d "%~dp0"

:MENU
cls
echo ==========================================
echo              BALI AI HQ V1
echo ==========================================
echo.
echo 1. Generate AI Handover Report
echo 2. Git Status
echo 3. Git Backup Push
echo 4. Open Project Brain Files
echo 5. Exit
echo.
set /p choice=Choose option: 

if "%choice%"=="1" goto HANDOVER
if "%choice%"=="2" goto STATUS
if "%choice%"=="3" goto PUSH
if "%choice%"=="4" goto BRAIN
if "%choice%"=="5" exit
goto MENU

:HANDOVER
powershell -ExecutionPolicy Bypass -File "tools\BALI_AI_HANDOVER_REPORT.ps1"
pause
goto MENU

:STATUS
git status
pause
goto MENU

:PUSH
git add .
git commit -m "Bali AI HQ backup update"
git push
pause
goto MENU

:BRAIN
code MISSION.md LEDGER.md NEXT_PATCH.md AI_RULES.md
pause
goto MENU
