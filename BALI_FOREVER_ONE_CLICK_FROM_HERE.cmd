@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  BALI ROCKET FOREVER - ONE CLICK REPAIR FIXED
rem  Pure CMD repair: no hidden PowerShell payload, no ZIP parser,
rem  no update ZIP processing, no Champion unlock, no live orders.
rem ============================================================

title Bali Rocket Forever - One Click Repair Fixed
color 0A

echo.
echo ============================================================
echo  BALI ROCKET FOREVER - ONE CLICK REPAIR FIXED
echo ============================================================
echo.
echo This will auto-find the Bali project, install one safe launcher,
echo create/refresh one Forever desktop icon, and start Bali safely.
echo.
echo It will NOT enable live orders, add API keys, unlock Champion,
echo use private endpoints, or process update ZIPs.
echo.

set "ROOT="
set "APPROOT="
set "SCRIPT=%~f0"
set "SCRIPT_DIR=%~dp0"

call :find_root
if not defined ROOT (
  call :fail "Could not auto-find the Bali project folder. Put this CMD inside the Bali project folder and run it again."
  exit /b 1
)

set "REC=%ROOT%\_BALI_FOREVER_RECOVERY"
set "BACKUP=%REC%\legacy_launcher_backups"
if not exist "%REC%" mkdir "%REC%" >nul 2>nul
if not exist "%BACKUP%" mkdir "%BACKUP%" >nul 2>nul
set "LOG=%REC%\FOREVER_ONE_CLICK_REPAIR_LAST_RUN.txt"

> "%LOG%" echo BALI ROCKET FOREVER ONE CLICK REPAIR FIXED
>>"%LOG%" echo Generated: %DATE% %TIME%
>>"%LOG%" echo Source repair file: %SCRIPT%
>>"%LOG%" echo Project root: %ROOT%
>>"%LOG%" echo App root: %APPROOT%
>>"%LOG%" echo Safety: live orders OFF, Champion locked, no API keys, public data only.
>>"%LOG%" echo.

echo Project found:
echo   %ROOT%
echo.

call :install_safe_files
if errorlevel 1 (
  call :fail "Could not install the safe launcher files. See %LOG%"
  exit /b 1
)

call :redirect_legacy_launchers
if errorlevel 1 (
  call :fail "Could not redirect legacy launchers. See %LOG%"
  exit /b 1
)

call :create_shortcut
if errorlevel 1 (
  call :fail "Could not create the desktop shortcut. See %LOG%"
  exit /b 1
)

call :write_readme
if errorlevel 1 (
  call :fail "Could not write README_START_HERE_FOREVER.txt. See %LOG%"
  exit /b 1
)

call :launch_bali
if errorlevel 1 (
  call :fail "Bali could not be started. See %LOG%"
  exit /b 1
)

echo.
echo ============================================================
echo  DONE
echo ============================================================
echo.
echo From now on, use the desktop icon:
echo   Bali Rocket Forever Safe
echo.
echo Log saved to:
echo   %LOG%
echo.
timeout /t 4 /nobreak >nul 2>nul
exit /b 0

:find_root
call :maybe_root "%CD%"
call :maybe_root "%SCRIPT_DIR%"
for %%P in ("%SCRIPT_DIR%.." "%CD%\..") do call :maybe_root "%%~fP"
if defined ROOT exit /b 0

for %%B in ("%USERPROFILE%\Desktop" "%USERPROFILE%\Documents" "%USERPROFILE%\Downloads" "%OneDrive%\Desktop" "%OneDrive%\Documents") do (
  if not defined ROOT call :scan_base "%%~fB"
)
if defined ROOT exit /b 0

rem Final common hard-coded fallback from the earlier Bali builds.
call :maybe_root "%USERPROFILE%\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
exit /b 0

:scan_base
set "BASE=%~1"
if not defined BASE exit /b 0
if not exist "%BASE%\" exit /b 0
call :maybe_root "%BASE%"
if defined ROOT exit /b 0
for /f "delims=" %%D in ('dir /ad /b /s "%BASE%\*BALI*" 2^>nul') do (
  if not defined ROOT call :maybe_root "%%~fD"
)
if defined ROOT exit /b 0
for /f "delims=" %%D in ('dir /ad /b /s "%BASE%\*ROCKET*" 2^>nul') do (
  if not defined ROOT call :maybe_root "%%~fD"
)
exit /b 0

:maybe_root
if defined ROOT exit /b 0
set "CAND=%~1"
if not defined CAND exit /b 0
if not exist "%CAND%\" exit /b 0

if exist "%CAND%\bali_rocket_crypto_command_v011b\app.py" (
  set "ROOT=%CAND%"
  set "APPROOT=%CAND%\bali_rocket_crypto_command_v011b"
  exit /b 0
)

if exist "%CAND%\payload\app.py" (
  set "ROOT=%CAND%"
  set "APPROOT=%CAND%\payload"
  exit /b 0
)

if exist "%CAND%\app.py" (
  set "ROOT=%CAND%"
  set "APPROOT=%CAND%"
  exit /b 0
)

for /d %%A in ("%CAND%\bali_rocket_crypto_command*") do (
  if not defined ROOT if exist "%%~fA\app.py" (
    set "ROOT=%CAND%"
    set "APPROOT=%%~fA"
  )
)
exit /b 0

:install_safe_files
echo Installing one canonical safe launcher...
set "TARGET_SAFE=%ROOT%\START_BALI_ROCKET_SAFE.cmd"
set "TARGET_ONE=%ROOT%\BALI_FOREVER_ONE_CLICK_FROM_HERE.cmd"
if /I not "%SCRIPT%"=="%TARGET_SAFE%" (
  copy /y "%SCRIPT%" "%TARGET_SAFE%" >>"%LOG%" 2>&1
  if errorlevel 1 exit /b 1
) else (
  >>"%LOG%" echo START_BALI_ROCKET_SAFE.cmd already running in place.
)
if /I not "%SCRIPT%"=="%TARGET_ONE%" (
  copy /y "%SCRIPT%" "%TARGET_ONE%" >>"%LOG%" 2>&1
  if errorlevel 1 exit /b 1
) else (
  >>"%LOG%" echo BALI_FOREVER_ONE_CLICK_FROM_HERE.cmd already running in place.
)
>>"%LOG%" echo Installed: START_BALI_ROCKET_SAFE.cmd
>>"%LOG%" echo Installed: BALI_FOREVER_ONE_CLICK_FROM_HERE.cmd
exit /b 0

:redirect_legacy_launchers
echo Redirecting messy old launchers to the one safe launcher...
call :make_shim "BALI START HERE - ONE CLICK.bat"
if errorlevel 1 exit /b 1
call :make_shim "BALI_THEMED_FOREVER_STARTER.bat"
if errorlevel 1 exit /b 1
call :make_shim "BALI_ROCKET_FOREVER_STARTER.bat"
if errorlevel 1 exit /b 1
call :make_shim "Bali Supervisor Mission Control.bat"
if errorlevel 1 exit /b 1
call :make_shim "BALI_CREATE_FOREVER_DESKTOP_ICON.bat"
if errorlevel 1 exit /b 1
exit /b 0

:make_shim
set "SHIM=%ROOT%\%~1"
if exist "%SHIM%" (
  copy /y "%SHIM%" "%BACKUP%\%~n1_PRE_FOREVER_SAFE_%RANDOM%%~x1" >>"%LOG%" 2>&1
)
> "%SHIM%" echo @echo off
>>"%SHIM%" echo rem Redirected by Bali Rocket Forever One Click Repair Fixed
>>"%SHIM%" echo call "%%~dp0START_BALI_ROCKET_SAFE.cmd" %%*
>>"%SHIM%" echo exit /b %%ERRORLEVEL%%
if errorlevel 1 exit /b 1
>>"%LOG%" echo Redirected launcher: %SHIM%
exit /b 0

:create_shortcut
echo Creating Forever desktop icon...
set "DESKTOP=%USERPROFILE%\Desktop"
if not exist "%DESKTOP%\" mkdir "%DESKTOP%" >nul 2>nul
set "LNK=%DESKTOP%\Bali Rocket Forever Safe.lnk"
set "ICON=%SystemRoot%\System32\shell32.dll,13"
if exist "%ROOT%\assets\" (
  for /f "delims=" %%I in ('dir /b /s "%ROOT%\assets\*FOREVER*.ico" 2^>nul') do (
    if "!ICON!"=="%SystemRoot%\System32\shell32.dll,13" set "ICON=%%~fI"
  )
)
set "VBS=%TEMP%\bali_forever_shortcut_%RANDOM%.vbs"
> "%VBS%" echo Set WshShell = WScript.CreateObject("WScript.Shell")
>>"%VBS%" echo Set Lnk = WshShell.CreateShortcut(WScript.Arguments(0))
>>"%VBS%" echo Lnk.TargetPath = WScript.Arguments(1)
>>"%VBS%" echo Lnk.WorkingDirectory = WScript.Arguments(2)
>>"%VBS%" echo Lnk.IconLocation = WScript.Arguments(3)
>>"%VBS%" echo Lnk.Description = "Bali Rocket Forever Safe - safe public-data startup"
>>"%VBS%" echo Lnk.Save
cscript //nologo "%VBS%" "%LNK%" "%ROOT%\START_BALI_ROCKET_SAFE.cmd" "%ROOT%" "%ICON%" >>"%LOG%" 2>&1
set "CSERR=%ERRORLEVEL%"
del "%VBS%" >nul 2>nul
if not "%CSERR%"=="0" exit /b 1
>>"%LOG%" echo Desktop shortcut: %LNK%
>>"%LOG%" echo Desktop icon: %ICON%
exit /b 0

:write_readme
> "%ROOT%\README_START_HERE_FOREVER.txt" echo BALI ROCKET FOREVER SAFE STARTUP
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo.
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Use only this desktop icon from now on:
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   Bali Rocket Forever Safe
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo.
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Canonical launcher in this folder:
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   START_BALI_ROCKET_SAFE.cmd
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo.
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Safety rules enforced by the launcher process:
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   LIVE_ORDERS=OFF
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   Champion locked / claim disabled
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   API and secret env vars cleared
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   Public-data mode only
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo   No update ZIP processing in startup path
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo.
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Backtest/walk-forward evidence is still NOT proven.
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Champion claim allowed: False
>>"%ROOT%\README_START_HERE_FOREVER.txt" echo Live trading: OFF
if errorlevel 1 exit /b 1
>>"%LOG%" echo README written: %ROOT%\README_START_HERE_FOREVER.txt
exit /b 0

:launch_bali
echo Starting Bali safely...

rem Safety environment inherited by the launched dashboard process.
set "LIVE_ORDERS=OFF"
set "BALI_LIVE_ORDERS=OFF"
set "ENABLE_LIVE_ORDERS=0"
set "CHAMPION_CLAIM_ALLOWED=false"
set "BALI_CHAMPION_UNLOCK=0"
set "BALI_PUBLIC_DATA_ONLY=1"
set "API_KEY="
set "SECRET_KEY="
set "BINANCE_API_KEY="
set "BINANCE_SECRET_KEY="
set "BYBIT_API_KEY="
set "BYBIT_SECRET_KEY="
set "OPENAI_API_KEY="
set "PRIVATE_ENDPOINT="
set "PYTHONNOUSERSITE=1"
set "PYTHONDONTWRITEBYTECODE=1"

>>"%LOG%" echo Launch safety env applied.

if exist "%ROOT%\ROCKET_CRYPTO_COMMAND_START.bat" (
  >>"%LOG%" echo Launch method: ROCKET_CRYPTO_COMMAND_START.bat
  start "Bali Rocket Forever Safe" /D "%ROOT%" cmd /k call "%ROOT%\ROCKET_CRYPTO_COMMAND_START.bat"
  timeout /t 3 /nobreak >nul 2>nul
  start "" "http://127.0.0.1:9061" >nul 2>nul
  exit /b 0
)

if not exist "%APPROOT%\app.py" exit /b 1
call :find_python
if not defined PYEXE exit /b 1

>>"%LOG%" echo Launch method: direct app.py
>>"%LOG%" echo Python: %PYEXE%
start "Bali Rocket Forever Safe" /D "%APPROOT%" cmd /k ""%PYEXE%" "%APPROOT%\app.py" --host 127.0.0.1 --port 9061"
timeout /t 3 /nobreak >nul 2>nul
start "" "http://127.0.0.1:9061" >nul 2>nul
exit /b 0

:find_python
set "PYEXE="
call :try_python "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
if defined PYEXE exit /b 0
call :try_python "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if defined PYEXE exit /b 0
call :try_python "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if defined PYEXE exit /b 0
call :try_python "%ProgramFiles%\Python310\python.exe"
if defined PYEXE exit /b 0
call :try_python "%ProgramFiles%\Python311\python.exe"
if defined PYEXE exit /b 0
call :try_python "%ProgramFiles%\Python312\python.exe"
if defined PYEXE exit /b 0
where python >nul 2>nul
if not errorlevel 1 (
  for /f "delims=" %%P in ('where python') do (
    if not defined PYEXE call :try_python "%%~fP"
  )
)
exit /b 0

:try_python
set "PYCAND=%~1"
if not defined PYCAND exit /b 0
if not exist "%PYCAND%" exit /b 0
echo %PYCAND% | findstr /I "Python313" >nul 2>nul
if not errorlevel 1 (
  >>"%LOG%" echo Skipped Python 3.13 candidate: %PYCAND%
  exit /b 0
)
"%PYCAND%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) and sys.version_info < (3,13) else 1)" >>"%LOG%" 2>&1
if errorlevel 1 exit /b 0
set "PYEXE=%PYCAND%"
exit /b 0

:fail
echo.
echo ============================================================
echo  REPAIR FAILED
echo ============================================================
echo.
echo %~1
echo.
if defined LOG echo Log: %LOG%
echo.
echo Nothing was live-enabled. No API keys were added. Champion remains locked.
echo.
pause
exit /b 1
