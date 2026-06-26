@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "tools\BALI_AI_HANDOVER_REPORT.ps1"
pause
