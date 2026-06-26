@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_BOT_GUARDIAN_STATUS_V012J.ps1" -Root "%~dp0"
endlocal
