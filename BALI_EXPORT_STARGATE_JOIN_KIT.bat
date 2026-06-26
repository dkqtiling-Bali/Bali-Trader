@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_EXPORT_STARGATE_JOIN_KIT_V012J.ps1" -Root "%~dp0"
endlocal
