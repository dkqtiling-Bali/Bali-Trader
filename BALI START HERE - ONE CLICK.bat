@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if exist "%~dp0START_BALI_ROCKET_SAFE.cmd" (
  call "%~dp0START_BALI_ROCKET_SAFE.cmd"
  exit /b %ERRORLEVEL%
)
if exist "%~dp0tools\BALI_ONE_CLICK_AUTOMATIC.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_ONE_CLICK_AUTOMATIC.ps1" -Root "%CD%" -Port 9061
  exit /b %ERRORLEVEL%
)
setlocal EnableExtensions EnableDelayedExpansion

title BALI START HERE - ONE CLICK

rem ==========================================================
rem  BALI START HERE - ONE CLICK
rem  No Python. No Update Dock. No live trading. No API keys.
rem  Applies one valid autopatch ZIP, starts Bali, opens report.
rem ==========================================================

set "SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS"
set "VERSION=V040_BALI_START_HERE_ONE_CLICK"
set "BASE=%USERPROFILE%\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
if not exist "%BASE%" (
  for /d %%D in ("%USERPROFILE%\Desktop\BALI_ROCKET_CRYPTO_COMMAND*") do (
    if exist "%%~fD\bali_rocket_crypto_command_v011b" set "BASE=%%~fD"
  )
)

set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "UPDATES=%BASE%\updates"
set "REPORTS=%APP%\shared_data\reports"
set "TOOLS=%APP%\tools\BALI_ONE_CLICK_START"
set "DESKTOP_REPORT=%USERPROFILE%\Desktop\BALI_ONE_CLICK_START_LATEST_REPORT.txt"
set "REPORT=%REPORTS%\BALI_ONE_CLICK_START_LATEST_REPORT.txt"
set "PATCH_RESULT=NO_PATCH_WAITING"
set "PATCH_FOUND="
set "PATCH_STATUS=NO_PATCH_WAITING"
set "PATCH_PAYLOAD_RESULT=NOT_RUN"
set "STARTER="

if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
if not exist "%UPDATES%" mkdir "%UPDATES%" >nul 2>nul
if not exist "%UPDATES%\APPLIED" mkdir "%UPDATES%\APPLIED" >nul 2>nul
if not exist "%UPDATES%\QUARANTINE" mkdir "%UPDATES%\QUARANTINE" >nul 2>nul
if not exist "%TOOLS%" mkdir "%TOOLS%" >nul 2>nul

call :write_header

if not exist "%BASE%" (
  call :log "BASE_EXISTS=NO"
  call :log "RESULT=FAIL_BASE_NOT_FOUND"
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  start "" notepad "%DESKTOP_REPORT%"
  exit /b 1
)
if not exist "%APP%" (
  call :log "APP_EXISTS=NO"
  call :log "RESULT=FAIL_APP_NOT_FOUND"
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  start "" notepad "%DESKTOP_REPORT%"
  exit /b 1
)

call :log "BASE=%BASE%"
call :log "APP=%APP%"
call :log "UPDATES=%UPDATES%"
call :log "REPORTS=%REPORTS%"
call :log "PATCH_SEARCH=UPDATES_FOLDER_THEN_THIS_FOLDER"

rem Find exactly one valid autopatch ZIP. Valid means it contains both:
rem   BALI_AUTO_PATCH_MANIFEST.txt
rem   AUTO_PATCH_INSTALL.bat
for %%Z in ("%UPDATES%\*.zip" "%~dp0*.zip") do (
  if not defined PATCH_FOUND (
    if exist "%%~fZ" (
      set "ZIP=%%~fZ"
      powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; try { $z=[IO.Compression.ZipFile]::OpenRead($env:ZIP); $names=$z.Entries | %% { $_.FullName }; $z.Dispose(); if (($names -contains 'BALI_AUTO_PATCH_MANIFEST.txt') -and ($names -contains 'AUTO_PATCH_INSTALL.bat')) { exit 0 } else { exit 2 } } catch { exit 3 }" >nul 2>nul
      if !errorlevel! EQU 0 (
        set "PATCH_FOUND=%%~fZ"
      ) else (
        call :log "SKIP_NOT_VALID_AUTOPATCH=%%~fZ"
      )
    )
  )
)

if defined PATCH_FOUND (
  call :log "PATCH_FOUND=%PATCH_FOUND%"
  call :apply_patch
) else (
  call :log "PATCH_FOUND=NONE"
  set "PATCH_STATUS=NO_PATCH_WAITING"
  set "PATCH_RESULT=NO_PATCH_WAITING"
)

call :choose_starter
if not defined STARTER (
  call :log "STARTER_FOUND=NO"
  call :log "RESULT=FAIL_NO_BALI_STARTER_FOUND"
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  start "" notepad "%DESKTOP_REPORT%"
  exit /b 1
)

call :log "STARTER=%STARTER%"
call :log "DASHBOARD_URL=http://127.0.0.1:9061"
call :log "STARTING_BALI=YES"

rem Start Bali in the background. The final visible windows should be dashboard + this report.
start "Bali Forever Starter" /min cmd /c call "%STARTER%"
timeout /t 3 /nobreak >nul
start "" "http://127.0.0.1:9061"

call :log "PATCH_STATUS=%PATCH_STATUS%"
call :log "PATCH_PAYLOAD_RESULT=%PATCH_PAYLOAD_RESULT%"
call :log "RESULT=PASS_ONE_CLICK_STARTED_BALI"
copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
start "" notepad "%DESKTOP_REPORT%"
exit /b 0

:write_header
>"%REPORT%" echo BALI ONE CLICK START REPORT
>>"%REPORT%" echo Generated: %date% %time%
>>"%REPORT%" echo SAFETY=%SAFETY%
>>"%REPORT%" echo VERSION=%VERSION%
>>"%REPORT%" echo PYTHON_USED=NO
>>"%REPORT%" echo UPDATE_DOCK_USED=NO
>>"%REPORT%" echo MODE=ONE_FILE_STARTER_APPLY_PATCH_START_BALI_OPEN_REPORT
exit /b 0

:log
>>"%REPORT%" echo %~1
exit /b 0

:apply_patch
set "TMP=%TEMP%\BALI_ONE_CLICK_PATCH_%RANDOM%_%RANDOM%"
if exist "%TMP%" rmdir /s /q "%TMP%" >nul 2>nul
mkdir "%TMP%" >nul 2>nul
set "ZIP=%PATCH_FOUND%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath $env:ZIP -DestinationPath $env:TMP -Force" >nul 2>nul
if errorlevel 1 (
  call :log "PATCH_EXTRACT=FAIL"
  set "PATCH_STATUS=QUARANTINE_EXTRACT_FAILED"
  set "PATCH_PAYLOAD_RESULT=NOT_RUN"
  move /y "%PATCH_FOUND%" "%UPDATES%\QUARANTINE\" >nul 2>nul
  exit /b 0
)
if not exist "%TMP%\AUTO_PATCH_INSTALL.bat" (
  call :log "PATCH_INSTALLER=MISS"
  set "PATCH_STATUS=QUARANTINE_INSTALLER_MISSING"
  set "PATCH_PAYLOAD_RESULT=NOT_RUN"
  move /y "%PATCH_FOUND%" "%UPDATES%\QUARANTINE\" >nul 2>nul
  exit /b 0
)
call :log "PATCH_INSTALLER=%TMP%\AUTO_PATCH_INSTALL.bat"
call "%TMP%\AUTO_PATCH_INSTALL.bat" "%APP%" "%BASE%" "%REPORTS%"
set "PATCH_EXIT_CODE=%errorlevel%"
call :log "PATCH_EXIT_CODE=%PATCH_EXIT_CODE%"
if "%PATCH_EXIT_CODE%"=="0" (
  set "PATCH_STATUS=APPLIED"
  set "PATCH_PAYLOAD_RESULT=PASS"
  move /y "%PATCH_FOUND%" "%UPDATES%\APPLIED\" >nul 2>nul
) else (
  set "PATCH_STATUS=QUARANTINE_INSTALLER_FAILED"
  set "PATCH_PAYLOAD_RESULT=FAIL"
  move /y "%PATCH_FOUND%" "%UPDATES%\QUARANTINE\" >nul 2>nul
)
rmdir /s /q "%TMP%" >nul 2>nul
exit /b 0

:choose_starter
if exist "%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat" set "STARTER=%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat"
if not defined STARTER if exist "%BASE%\BALI_THEMED_FOREVER_STARTER_PRE_V031_BACKUP.bat" set "STARTER=%BASE%\BALI_THEMED_FOREVER_STARTER_PRE_V031_BACKUP.bat"
if not defined STARTER if exist "%BASE%\BALI_THEMED_FOREVER_STARTER_BACKUP_BEFORE_V030_15860.bat" set "STARTER=%BASE%\BALI_THEMED_FOREVER_STARTER_BACKUP_BEFORE_V030_15860.bat"
if not defined STARTER if exist "%BASE%\BALI_THEMED_FOREVER_STARTER.bat" set "STARTER=%BASE%\BALI_THEMED_FOREVER_STARTER.bat"
exit /b 0
