@echo off
setlocal EnableExtensions
title BALI OS MASTER CONTROL
color 0B

:MENU
cls
echo ==========================================
echo             BALI OS MASTER CONTROL
echo ==========================================
echo Base: C:\Bali\Bali-Trader\
echo.
echo 1. Full Auto Analyse + Handover
echo 2. Concise AI Handover Only
echo 3. Full AI Handover Only
echo 4. Recommend Highest-Value Next Patch
echo 5. Safety Scan V4E
echo 6. Generate Project Map
echo 7. Generate Evidence Index
echo 8. Git Safe Save / Backup V4E
echo 9. Open Constitution
echo 10. Open Latest Report
echo 11. Open Ledger
echo 12. Open Next Patch
echo 13. Exit
echo.
set /p choice=Choose option: 

if "%choice%"=="1" goto FULLAUTO
if "%choice%"=="2" goto CONCISE
if "%choice%"=="3" goto FULL
if "%choice%"=="4" goto RECOMMEND
if "%choice%"=="5" goto SAFETY
if "%choice%"=="6" goto MAP
if "%choice%"=="7" goto EVIDENCE
if "%choice%"=="8" goto GITSAFE
if "%choice%"=="9" goto OPENCONSTITUTION
if "%choice%"=="10" goto OPENLATEST
if "%choice%"=="11" goto OPENLEDGER
if "%choice%"=="12" goto OPENNEXT
if "%choice%"=="13" exit /b 0

echo Invalid option.
pause
goto MENU

:FULLAUTO
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action FullAuto
goto AFTER

:CONCISE
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action ConciseHandover
goto AFTER

:FULL
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action FullHandover
goto AFTER

:RECOMMEND
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action RecommendNextPatch
goto AFTER

:SAFETY
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_SAFETY_SCAN_V4E.ps1" -Base "C:\Bali\Bali-Trader" -WriteReport
goto AFTER

:MAP
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action ProjectMap
goto AFTER

:EVIDENCE
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action EvidenceIndex
goto AFTER

:GITSAFE
echo Running Git Safe Save V4E from hard-coded path...
if not exist "C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1" (
  echo Missing C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1
  goto AFTER
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1" -Base "C:\Bali\Bali-Trader"
goto AFTER

:OPENCONSTITUTION
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action OpenConstitution
goto AFTER

:OPENLATEST
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action OpenLatestReport
goto AFTER

:OPENLEDGER
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action OpenLedger
goto AFTER

:OPENNEXT
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE.ps1" -Action OpenNextPatch
goto AFTER

:AFTER
echo.
pause
goto MENU
