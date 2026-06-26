@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Rocket Crypto Command - V011J Rescue Apply
set "ROOT=%CD%"
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=manual_%RANDOM%"
set "REPORT=%LOGDIR%\BALI_ONE_CLICK_UPDATE_RESCUE_REPORT_V011J.txt"
set "ENGINE=%ROOT%\tools\BALI_ONE_CLICK_UPDATE_ENGINE_V011J.ps1"

if not exist "%ENGINE%" goto :missing_engine
powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%" -Stamp "%STAMP%"
set "RC=%ERRORLEVEL%"

echo.
if exist "%REPORT%" (
  type "%REPORT%"
  start "" notepad "%REPORT%"
) else (
  echo V011J rescue update finished but no report file was found.
)
pause
exit /b %RC%

:missing_engine
(
  echo BALI ROCKET CRYPTO COMMAND - V011J RESCUE REPORT
  echo Generated: %DATE% %TIME%
  echo Root folder: %ROOT%
  echo RESULT: RESCUE ENGINE MISSING
  echo Expected engine: %ENGINE%
  echo Fix: extract ALL contents of BALI_ROCKET_CRYPTO_COMMAND_V011J_RESCUE_KIT.zip into the Bali root folder, then run this file again.
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
) > "%REPORT%"
type "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 9
