@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "LOCAL_PATCH_DIR=%CD%"
set "GUARD=%LOCAL_PATCH_DIR%\tools\BALI_ROOT_GUARD_V012H.ps1"
if not exist "%GUARD%" (
  echo BALI V012H EXTRACTED PATCH RESCUE
  echo RESULT: ROOT GUARD MISSING
  echo This rescue must be run from an extracted V012H patch folder.
  pause
  exit /b 9
)
for /f "delims=" %%R in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%GUARD%" -Start "%LOCAL_PATCH_DIR%"') do set "REAL_ROOT=%%R"
if not defined REAL_ROOT set "REAL_ROOT=%CD%"
set "LOGDIR=%REAL_ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "REPORT=%LOGDIR%\BALI_EXTRACTED_PATCH_RESCUE_REPORT_V012H.txt"
(
  echo BALI EXTRACTED PATCH FOLDER RESCUE REPORT V012H
  echo Generated: %DATE% %TIME%
  echo Local extracted patch folder: %LOCAL_PATCH_DIR%
  echo Detected real root: %REAL_ROOT%
  echo Purpose: copy V012H files to the real Bali root if the ZIP was extracted and run from inside updates by mistake.
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
  echo.
) > "%REPORT%"
if /i "%REAL_ROOT%"=="%LOCAL_PATCH_DIR%" (
  echo RESULT: RESCUE REFUSED - could not detect a separate real root. >> "%REPORT%"
  type "%REPORT%"
  start "" notepad "%REPORT%"
  pause
  exit /b 2
)
robocopy "%LOCAL_PATCH_DIR%" "%REAL_ROOT%" /E /XD "__MACOSX" /XF "*.zip" >> "%REPORT%"
set "RC=%ERRORLEVEL%"
if %RC% LEQ 7 (
  echo RESULT: RESCUE APPLIED >> "%REPORT%"
  echo Next step: run "%REAL_ROOT%\BALI_SPEED_LANE_UPDATE.bat" from the REAL ROOT folder. >> "%REPORT%"
  set "RC=0"
) else (
  echo RESULT: RESCUE COPY FAILED >> "%REPORT%"
)
type "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b %RC%
