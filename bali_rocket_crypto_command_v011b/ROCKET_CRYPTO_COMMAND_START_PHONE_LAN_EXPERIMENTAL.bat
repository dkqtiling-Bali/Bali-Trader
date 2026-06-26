@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Rocket Crypto Command V010B - Phone LAN Launcher
if not exist logs mkdir logs
set "REPORT=logs\BALI_PHONE_LAN_STARTUP_REPORT.txt"
(
  echo BALI ROCKET CRYPTO COMMAND - PHONE LAN STARTUP REPORT
  echo Generated: %DATE% %TIME%
  echo Folder: %CD%
  echo WARNING: LAN/private Wi-Fi only. Do not port-forward or expose publicly.
  echo.
) > "%REPORT%"

rem Direct Python detection for LAN mode.
set "PY_EXE="
for %%P in (
  "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
) do if exist %%~P set "PY_EXE=%%~P"
if not defined PY_EXE (
  where py >nul 2>nul && for %%V in (3.13 3.12 3.11 3.10 3) do if not defined PY_EXE (py -%%V -c "import sys; print(sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) else 1)" > logs\_py_candidate.txt 2>> "%REPORT%" && set /p PY_EXE=<logs\_py_candidate.txt)
)
if not defined PY_EXE (
  where python >nul 2>nul && (python -c "import sys; print(sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) else 1)" > logs\_py_candidate.txt 2>> "%REPORT%" && set /p PY_EXE=<logs\_py_candidate.txt)
)
if not defined PY_EXE (
  echo RESULT: BAD PYTHON / PYTHON NOT FOUND >> "%REPORT%"
  start notepad "%REPORT%"
  pause
  exit /b 1
)
"%PY_EXE%" -m py_compile app.py >> "%REPORT%" 2>&1
if errorlevel 1 (
  echo RESULT: APP PYTHON SYNTAX CHECK FAILED >> "%REPORT%"
  start notepad "%REPORT%"
  pause
  exit /b 2
)
start "" "http://127.0.0.1:9061/phone"
"%PY_EXE%" app.py --host 0.0.0.0 --port 9061
set "RC=%ERRORLEVEL%"
echo App exited with code %RC% >> "%REPORT%"
if not "%RC%"=="0" start notepad "%REPORT%"
pause
exit /b %RC%
