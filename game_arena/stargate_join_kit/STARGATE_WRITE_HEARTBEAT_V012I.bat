@echo off
setlocal
set BRIDGE_ROOT=%~1
if "%BRIDGE_ROOT%"=="" (
  echo Usage: STARGATE_WRITE_HEARTBEAT_V012I.bat C:\path\to\shared_drop
  echo This writes a heartbeat JSON only. It does not trade.
  pause
  exit /b 2
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0STARGATE_WRITE_HEARTBEAT_V012I.ps1" -BridgeRoot "%BRIDGE_ROOT%"
endlocal
