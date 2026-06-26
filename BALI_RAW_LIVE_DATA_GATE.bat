@echo off
setlocal
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: BALI_RAW_LIVE_DATA_GATE.bat path_to_checkin_json
  pause
  exit /b 2
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_RAW_LIVE_DATA_GATE_V012J.ps1" -RootPath "%~dp0" -CheckinPath "%~1"
if exist "%~dp0logs\BALI_RAW_LIVE_DATA_GATE_REPORT_V012J.txt" start "" notepad "%~dp0logs\BALI_RAW_LIVE_DATA_GATE_REPORT_V012J.txt"
endlocal
