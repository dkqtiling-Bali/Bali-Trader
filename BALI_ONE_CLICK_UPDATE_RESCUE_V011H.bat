@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Rocket Crypto Command - V011H Rescue Updater
set "ROOT=%CD%"
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=rescue_%RANDOM%"
set "REPORT=%LOGDIR%\BALI_ONE_CLICK_UPDATE_RESCUE_REPORT_V011H.txt"
set "ENGINE=%ROOT%\tools\BALI_ONE_CLICK_UPDATE_ENGINE_V011H.ps1"

if not exist "%ENGINE%" goto :missing_engine
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%" -Stamp "%STAMP%"
set "RC=%ERRORLEVEL%"

echo.
if exist "%REPORT%" (
  type "%REPORT%"
  start "" notepad "%REPORT%"
) else (
  echo Rescue update finished but no report file was found.
)
pause
exit /b %RC%

:missing_engine
(
  echo BALI ROCKET CRYPTO COMMAND - V011H RESCUE UPDATE REPORT
  echo Generated: %DATE% %TIME%
  echo Root folder: %ROOT%
  echo RESULT: RESCUE ENGINE MISSING
  echo Expected engine: %ENGINE%
  echo Extract the full V011H rescue kit into the Bali root folder, not just this BAT file.
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
) > "%REPORT%"
type "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 9
