@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Bali Rocket Forever Safe

set "ROOT=%CD%"
set "APP=%ROOT%\bali_rocket_crypto_command_v011b"
set "RECOVERY=%ROOT%\_BALI_FOREVER_RECOVERY"
set "APPLOGS=%APP%\logs"
set "REPORT=%RECOVERY%\START_BALI_ROCKET_SAFE_LAST_REPORT.txt"

if not exist "%RECOVERY%" mkdir "%RECOVERY%" >nul 2>nul
if not exist "%APPLOGS%" mkdir "%APPLOGS%" >nul 2>nul

for %%K in (
  BINANCE_API_KEY
  BINANCE_SECRET_KEY
  BINANCE_API_SECRET
  BALI_API_KEY
  BALI_API_SECRET
  BALI_EXCHANGE_API_KEY
  BALI_EXCHANGE_SECRET
  COINBASE_API_KEY
  COINBASE_API_SECRET
  KRAKEN_API_KEY
  KRAKEN_API_SECRET
) do set "%%K="

set "BALI_SAFE_FOREVER=1"
set "BALI_DISABLE_AUTOPATCH=1"
set "BALI_NO_LIVE_ORDERS=1"
set "PYTHONNOUSERSITE=1"
set "PYTHONDONTWRITEBYTECODE=1"

(
  echo BALI ROCKET FOREVER SAFE START REPORT
  echo Generated: %DATE% %TIME%
  echo Root: %ROOT%
  echo App: %APP%
  echo Safety: live orders OFF ^| champion LOCKED ^| no API keys ^| public data only
  echo Autopatch: DISABLED_BY_FOREVER_SAFE
  echo Update ZIPs: NOT processed automatically
  echo.
) > "%REPORT%"

if not exist "%APP%\app.py" goto :missing_app

call :find_python
if not defined PY_EXE goto :no_python

"%PY_EXE%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 7)" >> "%REPORT%" 2>&1
if errorlevel 7 goto :bad_version

cd /d "%APP%"
"%PY_EXE%" -m py_compile app.py >> "%REPORT%" 2>&1
if errorlevel 1 goto :bad_app

(
  echo Python selected: %PY_EXE%
  "%PY_EXE%" --version
  echo Syntax check: PASS
  echo Dashboard: http://127.0.0.1:9061
  echo Report button: Reports tab - Generate Always-Working Bot Stats Report
  echo Watch mode: active by default from Forever Safe
  echo.
) >> "%REPORT%" 2>&1

if /I "%BALI_SAFE_STARTER_DRY_RUN%"=="1" (
  echo DRY_RUN=PASS_STARTER_VALIDATED >> "%REPORT%"
  type "%REPORT%"
  exit /b 0
)

start "" "http://127.0.0.1:9061"
"%PY_EXE%" app.py --host 127.0.0.1 --port 9061
set "RC=%ERRORLEVEL%"
echo App exited with code %RC% >> "%REPORT%"
if not "%RC%"=="0" start "" notepad "%REPORT%"
pause
exit /b %RC%

:find_python
set "PY_EXE="
for %%P in (
  "%ROOT%\runtime\python\python.exe"
  "%ROOT%\python\python.exe"
  "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
  "%ProgramFiles%\Python313\python.exe"
  "%ProgramFiles%\Python312\python.exe"
  "%ProgramFiles%\Python311\python.exe"
  "%ProgramFiles%\Python310\python.exe"
) do (
  if exist "%%~fP" (
    "%%~fP" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>> "%REPORT%"
    if not errorlevel 1 (
      set "PY_EXE=%%~fP"
      echo Found direct Python: %%~fP >> "%REPORT%"
      exit /b 0
    )
  )
)

for /f "delims=" %%P in ('where python 2^>nul') do (
  if not defined PY_EXE (
    "%%~fP" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>> "%REPORT%"
    if not errorlevel 1 (
      set "PY_EXE=%%~fP"
      echo Found PATH Python: %%~fP >> "%REPORT%"
    )
  )
)
if defined PY_EXE exit /b 0

for /f "delims=" %%P in ('where python3 2^>nul') do (
  if not defined PY_EXE (
    "%%~fP" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>> "%REPORT%"
    if not errorlevel 1 (
      set "PY_EXE=%%~fP"
      echo Found PATH python3: %%~fP >> "%REPORT%"
    )
  )
)
if defined PY_EXE exit /b 0
exit /b 1

:missing_app
(
  echo RESULT: FAIL_APP_NOT_FOUND
  echo Expected: %APP%\app.py
) >> "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 1

:no_python
(
  echo RESULT: FAIL_PYTHON_NOT_FOUND
  echo Need Python 3.10 or newer. This V017 safe starter does not use the Windows py launcher.
) >> "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 2

:bad_version
(
  echo RESULT: FAIL_BAD_PYTHON_VERSION
  echo Need Python 3.10 or newer.
) >> "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 3

:bad_app
(
  echo RESULT: FAIL_APP_SYNTAX
  echo app.py did not pass py_compile. Paste this report back into ChatGPT.
) >> "%REPORT%"
start "" notepad "%REPORT%"
pause
exit /b 4
