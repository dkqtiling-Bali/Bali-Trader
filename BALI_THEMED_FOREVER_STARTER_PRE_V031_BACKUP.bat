@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==========================================================
rem  BALI THEMED FOREVER STARTER - V030 AUTOPATCH WRAPPER
rem  This file lives in the Bali root folder and is now the
rem  one true start point.
rem  Safety: no live orders, no API keys, no private endpoints.
rem ==========================================================

set "BASE=%~dp0"
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "UPDATES=%BASE%\updates"
set "APPLIED=%UPDATES%\APPLIED"
set "QUARANTINE=%UPDATES%\QUARANTINE"
set "TOOLS=%APP%\tools"
set "REPORTS=%APP%\shared_data\reports"
set "ROOT_REPORT=%BASE%\BALI_V030_PRELAUNCH_PROOF.txt"
set "APP_REPORT=%REPORTS%\BALI_V030_PRELAUNCH_PROOF.txt"
set "RUN_REPORT=%REPORTS%\BALI_V030_AUTOPATCH_RUN_REPORT.txt"
set "LOCK=%TEMP%\BALI_V030_FOREVER_STARTER_LOCK.txt"
set "ORIGINAL=%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat"

if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
if not exist "%UPDATES%" mkdir "%UPDATES%" >nul 2>nul
if not exist "%APPLIED%" mkdir "%APPLIED%" >nul 2>nul
if not exist "%QUARANTINE%" mkdir "%QUARANTINE%" >nul 2>nul
if not exist "%TOOLS%" mkdir "%TOOLS%" >nul 2>nul

rem If a lock exists but the dashboard is not responding, clear stale lock.
if exist "%LOCK%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:9061' -TimeoutSec 1; exit 0 } catch { exit 1 }" >nul 2>nul
  if errorlevel 1 (
    del "%LOCK%" >nul 2>nul
  ) else (
    start "" "http://127.0.0.1:9061" >nul 2>nul
    if exist "%APP_REPORT%" start "" notepad "%APP_REPORT%" >nul 2>nul
    exit /b 0
  )
)

>"%LOCK%" echo V030 launch in progress %DATE% %TIME%

(
  echo BALI V030 TRUE PRELAUNCH PROOF
  echo Generated: %DATE% %TIME%
  echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  echo VERSION=V030_REAL_FOREVER_STARTER_AUTOPATCH_WRAPPER
  echo STARTER=%~f0
  echo BASE=%BASE%
  echo APP=%APP%
  echo UPDATE_FOLDER=%UPDATES%
  echo PYTHON_USED=NO
  echo UPDATE_DOCK_USED=NO
  echo RESULT=PRELAUNCH_PROOF_WRITTEN_BEFORE_BALI_START
) > "%ROOT_REPORT%"
copy /y "%ROOT_REPORT%" "%APP_REPORT%" >nul 2>nul

set "PATCH="
for %%Z in ("%UPDATES%\*.zip") do (
  if not defined PATCH set "PATCH=%%~fZ"
)

(
  echo BALI V030 AUTOPATCH RUN REPORT
  echo Generated: %DATE% %TIME%
  echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  echo VERSION=V030_REAL_FOREVER_STARTER_AUTOPATCH_WRAPPER
  echo BASE=%BASE%
  echo APP=%APP%
  echo UPDATE_FOLDER=%UPDATES%
  echo PYTHON_USED=NO
  echo UPDATE_DOCK_USED=NO
) > "%RUN_REPORT%"

if not defined PATCH (
  >>"%RUN_REPORT%" echo PATCH_STATUS=NO_PATCH_WAITING
  >>"%RUN_REPORT%" echo RESULT=PASS_NO_PATCH_STARTING_BALI
  goto START_BALI
)

>>"%RUN_REPORT%" echo PATCH_FOUND=%PATCH%
set "WORK=%TEMP%\BALI_V030_PATCH_%RANDOM%_%RANDOM%"
if exist "%WORK%" rmdir /s /q "%WORK%" >nul 2>nul
mkdir "%WORK%" >nul 2>nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -LiteralPath '%PATCH%' -DestinationPath '%WORK%' -Force; exit 0 } catch { exit 9 }" >nul 2>nul
if errorlevel 1 (
  >>"%RUN_REPORT%" echo PATCH_STATUS=QUARANTINE_EXPAND_FAILED
  move /y "%PATCH%" "%QUARANTINE%\" >nul 2>nul
  >>"%RUN_REPORT%" echo RESULT=FAIL_PATCH_QUARANTINED_EXPAND_FAILED
  goto START_BALI
)

set "INSTALLER="
for /r "%WORK%" %%I in (AUTO_PATCH_INSTALL.bat) do (
  if not defined INSTALLER set "INSTALLER=%%~fI"
)

if not defined INSTALLER (
  >>"%RUN_REPORT%" echo PATCH_STATUS=QUARANTINE_NO_AUTO_PATCH_INSTALL_BAT
  move /y "%PATCH%" "%QUARANTINE%\" >nul 2>nul
  >>"%RUN_REPORT%" echo RESULT=FAIL_PATCH_QUARANTINED_NO_INSTALLER
  goto START_BALI
)

>>"%RUN_REPORT%" echo PATCH_INSTALLER=%INSTALLER%
call "%INSTALLER%" "%BASE%" "%APP%" "%UPDATES%" "%REPORTS%" >> "%RUN_REPORT%" 2>>&1
set "PATCH_RC=%ERRORLEVEL%"
>>"%RUN_REPORT%" echo PATCH_EXIT_CODE=%PATCH_RC%

if "%PATCH_RC%"=="0" (
  move /y "%PATCH%" "%APPLIED%\" >nul 2>nul
  >>"%RUN_REPORT%" echo PATCH_STATUS=APPLIED_MOVED_TO_APPLIED
  >>"%RUN_REPORT%" echo RESULT=PASS_PATCH_APPLIED_BEFORE_BALI_START
) else (
  move /y "%PATCH%" "%QUARANTINE%\" >nul 2>nul
  >>"%RUN_REPORT%" echo PATCH_STATUS=QUARANTINE_INSTALLER_FAILED
  >>"%RUN_REPORT%" echo RESULT=FAIL_PATCH_QUARANTINED_INSTALLER_FAILED
)

:START_BALI
if not exist "%ORIGINAL%" (
  >>"%RUN_REPORT%" echo ORIGINAL_STARTER_MISSING=%ORIGINAL%
  >>"%RUN_REPORT%" echo RESULT=FAIL_ORIGINAL_STARTER_MISSING
  start "" notepad "%RUN_REPORT%" >nul 2>nul
  del "%LOCK%" >nul 2>nul
  exit /b 1
)

>>"%RUN_REPORT%" echo STARTING_ORIGINAL=%ORIGINAL%
start "Bali Forever Original" /min "%ORIGINAL%"
timeout /t 5 /nobreak >nul 2>nul
start "" "http://127.0.0.1:9061" >nul 2>nul
start "" notepad "%RUN_REPORT%" >nul 2>nul

rem Keep lock while Bali is expected to be running; use Desktop clear-lock file if needed.
endlocal
exit /b 0
