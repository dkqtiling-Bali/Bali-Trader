@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "LOCAL_LAUNCH_DIR=%CD%"
set "ROOT=%CD%"
set "ROOT_GUARD=%LOCAL_LAUNCH_DIR%\tools\BALI_ROOT_GUARD_V012J.ps1"
if exist "%ROOT_GUARD%" (
  for /f "delims=" %%R in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_GUARD%" -Start "%LOCAL_LAUNCH_DIR%"') do set "ROOT=%%R"
  cd /d "%ROOT%"
)
title Bali Speed Lane Update V012J - Dashboard-Only Final Status
set "ROOT=%CD%"
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=speed_%RANDOM%"
set "REPORT=%LOGDIR%\BALI_SPEED_LANE_UPDATE_REPORT_V012J.txt"
set "ENGINE=%ROOT%\tools\BALI_SPEED_LANE_ENGINE_V012J.ps1"
if not exist "%ENGINE%" goto :missing_engine
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%" -Stamp "%STAMP%" -Quiet 0
set "RC=%ERRORLEVEL%"
echo.
if exist "%REPORT%" (
  echo Bali Speed Lane final report:
  echo %REPORT%
  findstr /C:"RESULT:" /C:"Selected version" /C:"Installed version" /C:"Highest available patch" "%REPORT%"
)
findstr /I "FAIL WARNING" "%REPORT%" >nul 2>nul
if "%RC%"=="0" if errorlevel 1 goto :success_quiet
if exist "%REPORT%" start "" notepad "%REPORT%"
:success_quiet
echo.
echo Use BALI_FAST_STATUS_PACK.bat for the compact paste-back report.
pause
exit /b %RC%
:missing_engine
(
  echo BALI SPEED LANE UPDATE REPORT V012J
  echo Generated: %DATE% %TIME%
  echo Root folder: %ROOT%
  echo RESULT: SPEED LANE ENGINE MISSING
  echo Expected engine: %ENGINE%
  echo Fix: apply the V012J patch, then run this again.
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
) > "%REPORT%"
type "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 9
