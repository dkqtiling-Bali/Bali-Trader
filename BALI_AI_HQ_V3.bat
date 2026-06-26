@echo off
setlocal
cd /d "%~dp0"
title BALI AI HQ V3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_AI_HQ_V3_ANALYSE.ps1"
echo.
pause
