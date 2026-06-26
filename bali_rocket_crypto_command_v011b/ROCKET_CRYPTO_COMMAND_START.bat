@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Bali Rocket Crypto Command V010B - Safe Python Auto-Fix Launcher
if not exist logs mkdir logs
set "REPORT=logs\BALI_BAD_PYTHON_STARTUP_REPORT.txt"
(
  echo BALI ROCKET CRYPTO COMMAND - STARTUP REPORT
  echo Generated: %DATE% %TIME%
  echo Folder: %CD%
  echo.
) > "%REPORT%"

call :find_python
if not defined PY_EXE goto :no_python

"%PY_EXE%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 7)" >> "%REPORT%" 2>&1
if errorlevel 7 goto :bad_version

"%PY_EXE%" -m py_compile app.py >> "%REPORT%" 2>&1
if errorlevel 1 goto :bad_app

(
  echo Python selected: %PY_EXE%
  "%PY_EXE%" --version
  echo Syntax check: PASS
  echo Dashboard: http://127.0.0.1:9061
  echo Phone mode: use ROCKET_CRYPTO_COMMAND_START_PHONE_LAN_EXPERIMENTAL.bat
  echo Safety: live orders OFF, champion lock LOCKED, no API keys.
) >> "%REPORT%" 2>&1

start "" "http://127.0.0.1:9061"
"%PY_EXE%" app.py --host 127.0.0.1 --port 9061
set "RC=%ERRORLEVEL%"
echo App exited with code %RC% >> "%REPORT%"
if not "%RC%"=="0" start notepad "%REPORT%"
pause
exit /b %RC%

:find_python
set "PY_EXE="
for %%P in (
  "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
  "%ProgramFiles%\Python313\python.exe"
  "%ProgramFiles%\Python312\python.exe"
  "%ProgramFiles%\Python311\python.exe"
  "%ProgramFiles%\Python310\python.exe"
) do (
  if exist %%~P (
    set "PY_EXE=%%~P"
    echo Found direct Python: %%~P >> "%REPORT%"
    exit /b 0
  )
)
where py >nul 2>nul
if not errorlevel 1 (
  for %%V in (3.13 3.12 3.11 3.10 3) do (
    py -%%V -c "import sys; print(sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) else 1)" > logs\_py_candidate.txt 2>> "%REPORT%"
    if not errorlevel 1 (
      set /p PY_EXE=<logs\_py_candidate.txt
      echo Found py launcher Python: !PY_EXE! >> "%REPORT%"
      del logs\_py_candidate.txt >nul 2>nul
      exit /b 0
    )
  )
)
where python >nul 2>nul
if not errorlevel 1 (
  python -c "import sys; print(sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) else 1)" > logs\_py_candidate.txt 2>> "%REPORT%"
  if not errorlevel 1 (
    set /p PY_EXE=<logs\_py_candidate.txt
    echo Found PATH Python: !PY_EXE! >> "%REPORT%"
    del logs\_py_candidate.txt >nul 2>nul
    exit /b 0
  )
)
where python3 >nul 2>nul
if not errorlevel 1 (
  python3 -c "import sys; print(sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) else 1)" > logs\_py_candidate.txt 2>> "%REPORT%"
  if not errorlevel 1 (
    set /p PY_EXE=<logs\_py_candidate.txt
    echo Found PATH python3: !PY_EXE! >> "%REPORT%"
    del logs\_py_candidate.txt >nul 2>nul
    exit /b 0
  )
)
exit /b 1

:no_python
(
  echo RESULT: BAD PYTHON / PYTHON NOT FOUND
  echo Need Python 3.10 or newer.
  echo Install Python from python.org and tick Add Python to PATH, then run this again.
) >> "%REPORT%"
start notepad "%REPORT%"
pause
exit /b 1

:bad_version
(
  echo RESULT: BAD PYTHON VERSION
  echo This build needs Python 3.10 or newer.
  echo The launcher found Python, but it is too old or broken.
) >> "%REPORT%"
start notepad "%REPORT%"
pause
exit /b 2

:bad_app
(
  echo RESULT: APP PYTHON SYNTAX CHECK FAILED
  echo This is a build problem, not your computer.
  echo Paste this report back into ChatGPT.
) >> "%REPORT%"
start notepad "%REPORT%"
pause
exit /b 3
