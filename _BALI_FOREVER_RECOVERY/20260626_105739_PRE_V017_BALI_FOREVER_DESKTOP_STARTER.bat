@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Bali Rocket Forever Starter
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_ONE_CLICK_AUTOMATIC.ps1" -Root "%CD%" -Port 9061
exit /b %ERRORLEVEL%
