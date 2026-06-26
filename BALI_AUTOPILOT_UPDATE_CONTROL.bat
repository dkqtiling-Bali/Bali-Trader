@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Autopilot Update Control V012J
set "ROOT=%CD%"
set "STATE=%ROOT%\logs\BALI_AUTOPILOT_UPDATE_STATE.json"
if /I "%~1"=="pause" goto pause
if /I "%~1"=="off" goto pause
if /I "%~1"=="arm" goto arm
if /I "%~1"=="on" goto arm
:status
echo Bali Autopilot Update Control V012J
echo State file: %STATE%
if exist "%STATE%" type "%STATE%" else echo Autopilot defaults to ARMED when V012J dashboard is open.
echo.
echo Use: BALI_AUTOPILOT_UPDATE_CONTROL.bat arm
echo Use: BALI_AUTOPILOT_UPDATE_CONTROL.bat pause
pause
exit /b 0
:arm
if not exist "%ROOT%\logs" mkdir "%ROOT%\logs"
>"%STATE%" echo {"enabled":true,"mode":"LOCAL_UPDATES_FOLDER_ONLY","updated_by":"BALI_AUTOPILOT_UPDATE_CONTROL.bat"}
echo AUTOPILOT=ARMED
pause
exit /b 0
:pause
if not exist "%ROOT%\logs" mkdir "%ROOT%\logs"
>"%STATE%" echo {"enabled":false,"mode":"LOCAL_UPDATES_FOLDER_ONLY","updated_by":"BALI_AUTOPILOT_UPDATE_CONTROL.bat"}
echo AUTOPILOT=PAUSED
pause
exit /b 0
