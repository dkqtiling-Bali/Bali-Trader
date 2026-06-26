@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_ARENA_REFEREE_SCORE_ROUND_V012J.ps1" -RootPath "%~dp0"
if exist "%~dp0logs\BALI_ARENA_REFEREE_SCORE_ROUND_REPORT_V012J.txt" start "" notepad "%~dp0logs\BALI_ARENA_REFEREE_SCORE_ROUND_REPORT_V012J.txt"
endlocal
