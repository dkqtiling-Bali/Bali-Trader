@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Dashboard Update Restart Bridge V012J
set "ROOT=%CD%"
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "REPORT=%LOGDIR%\BALI_DASH_UPDATE_FINAL_REPORT_V012J.txt"
set "ENGINE=%ROOT%\tools\BALI_DASH_UPDATE_RESTART_ENGINE_V012J.ps1"
if not exist "%ENGINE%" goto :missing_engine
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Port 9061 -ManualMode 1
set "RC=%ERRORLEVEL%"
echo.
if exist "%REPORT%" (
  echo Tiny final update report:
  echo %REPORT%
  findstr /C:"RESULT:" /C:"Selected version" /C:"Installed version" /C:"VERSION=" /C:"HEALTH=" /C:"RESTART=" /C:"AUTOPILOT=" "%REPORT%"
)
if not "%RC%"=="0" if exist "%REPORT%" start "" notepad "%REPORT%"
if "%RC%"=="0" echo RESULT: DASH UPDATE FINAL PASS
pause
exit /b %RC%
:missing_engine
(
  echo BALI DASH UPDATE FINAL REPORT V012J
  echo Generated: %DATE% %TIME%
  echo Root folder: %ROOT%
  echo RESULT: DASH UPDATE ENGINE MISSING
  echo Expected engine: %ENGINE%
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
) > "%REPORT%"
findstr /C:"RESULT:" /C:"Selected version" /C:"Installed version" /C:"VERSION=" /C:"HEALTH=" /C:"RESTART=" /C:"AUTOPILOT=" "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 9
