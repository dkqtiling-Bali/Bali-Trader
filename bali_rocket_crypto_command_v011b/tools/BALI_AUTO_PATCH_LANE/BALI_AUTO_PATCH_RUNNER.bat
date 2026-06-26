@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==========================================================
rem  BALI AUTO PATCH RUNNER - V023 NO PYTHON
rem ==========================================================
rem  This runner applies one safe local patch from BALI_AUTO_PATCH_INBOX.
rem  It does not enable live trading, add API keys, or call exchanges.

if not defined BALI_ROOT set "BALI_ROOT=%~dp0..\.."
for %%I in ("%BALI_ROOT%") do set "BALI_ROOT=%%~fI"
set "BALI_REPORTS=%BALI_ROOT%\shared_data\reports"
set "LANE=%BALI_ROOT%\tools\BALI_AUTO_PATCH_LANE"
set "INBOX=%BALI_ROOT%\BALI_AUTO_PATCH_INBOX"
set "APPLIED=%BALI_ROOT%\BALI_AUTO_PATCH_APPLIED"
set "QUARANTINE=%BALI_ROOT%\BALI_AUTO_PATCH_QUARANTINE"
set "WORK=%LANE%\work"
set "REPORT=%BALI_REPORTS%\BALI_AUTO_PATCH_LANE_REPORT.txt"
set "DESKTOP_REPORT=%USERPROFILE%\Desktop\BALI_AUTO_PATCH_LANE_LAST_REPORT.txt"

if not exist "%BALI_REPORTS%" mkdir "%BALI_REPORTS%" >nul 2>nul
if not exist "%LANE%" mkdir "%LANE%" >nul 2>nul
if not exist "%INBOX%" mkdir "%INBOX%" >nul 2>nul
if not exist "%APPLIED%" mkdir "%APPLIED%" >nul 2>nul
if not exist "%QUARANTINE%" mkdir "%QUARANTINE%" >nul 2>nul
if not exist "%WORK%" mkdir "%WORK%" >nul 2>nul

call :start_report

set "PATCH_FILE="
for %%F in ("%INBOX%\*.bat") do if not defined PATCH_FILE if exist "%%~fF" set "PATCH_FILE=%%~fF"
if not defined PATCH_FILE (
  for %%F in ("%INBOX%\*.zip") do if not defined PATCH_FILE if exist "%%~fF" set "PATCH_FILE=%%~fF"
)

if not defined PATCH_FILE (
  >>"%REPORT%" echo STATUS=NO_PATCH_WAITING
  >>"%REPORT%" echo RESULT=PASS_NO_PATCH_WAITING
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 0
)

set "BALI_PATCH_NAME=%~nx0"
for %%P in ("%PATCH_FILE%") do set "BALI_PATCH_NAME=%%~nP"& set "PATCH_EXT=%%~xP"
>>"%REPORT%" echo PATCH_FILE=%PATCH_FILE%
>>"%REPORT%" echo PATCH_NAME=%BALI_PATCH_NAME%
>>"%REPORT%" echo PATCH_EXT=%PATCH_EXT%

set "BALI_PATCH_LANE=V023_AUTOMATIC_PATCH_LANE_NO_PYTHON"
set "BALI_REPORTS=%BALI_REPORTS%"
set "BALI_ROOT=%BALI_ROOT%"

if /i "%PATCH_EXT%"==".bat" goto run_bat_patch
if /i "%PATCH_EXT%"==".zip" goto run_zip_patch

>>"%REPORT%" echo STATUS=UNSUPPORTED_PATCH_TYPE
>>"%REPORT%" echo RESULT=FAIL_UNSUPPORTED_PATCH_TYPE
move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
exit /b 2

:run_bat_patch
call :safety_scan_file "%PATCH_FILE%"
if errorlevel 1 goto quarantine_dangerous
>>"%REPORT%" echo STATUS=RUNNING_BAT_PATCH
call "%PATCH_FILE%"
set "RC=%ERRORLEVEL%"
goto finish_patch

:run_zip_patch
where powershell >nul 2>nul
if errorlevel 1 (
  >>"%REPORT%" echo STATUS=POWERSHELL_MISSING_FOR_ZIP_EXTRACT
  >>"%REPORT%" echo RESULT=FAIL_CANNOT_EXTRACT_ZIP_NO_POWERSHELL
  move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 3
)
set "THIS_WORK=%WORK%\%BALI_PATCH_NAME%"
if exist "%THIS_WORK%" rmdir /s /q "%THIS_WORK%" >nul 2>nul
mkdir "%THIS_WORK%" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%PATCH_FILE%' -DestinationPath '%THIS_WORK%' -Force" >nul 2>nul
if errorlevel 1 (
  >>"%REPORT%" echo STATUS=ZIP_EXTRACT_FAILED
  >>"%REPORT%" echo RESULT=FAIL_ZIP_EXTRACT_FAILED
  move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 4
)
call :safety_scan_tree "%THIS_WORK%"
if errorlevel 1 goto quarantine_dangerous
set "RUNBAT="
for /f "delims=" %%A in ('dir /b /s "%THIS_WORK%\BALI_PATCH_RUN_NOW.bat" 2^>nul') do if not defined RUNBAT set "RUNBAT=%%A"
if not defined RUNBAT for /f "delims=" %%A in ('dir /b /s "%THIS_WORK%\BALI_ONE_CLICK_INSTALL_NOW.bat" 2^>nul') do if not defined RUNBAT set "RUNBAT=%%A"
if not defined RUNBAT for /f "delims=" %%A in ('dir /b /s "%THIS_WORK%\*INSTALL*NOW*.bat" 2^>nul') do if not defined RUNBAT set "RUNBAT=%%A"
if not defined RUNBAT (
  >>"%REPORT%" echo STATUS=NO_AUTORUN_BAT_FOUND_IN_ZIP
  >>"%REPORT%" echo RESULT=FAIL_NO_AUTORUN_BAT_FOUND_IN_ZIP
  move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 5
)
>>"%REPORT%" echo STATUS=RUNNING_ZIP_PATCH
>>"%REPORT%" echo RUNBAT=%RUNBAT%
call "%RUNBAT%"
set "RC=%ERRORLEVEL%"
goto finish_patch

:finish_patch
>>"%REPORT%" echo PATCH_EXIT_CODE=%RC%
if "%RC%"=="0" (
  >>"%REPORT%" echo STATUS=PATCH_APPLIED
  >>"%REPORT%" echo RESULT=PASS_AUTO_PATCH_APPLIED
  move /y "%PATCH_FILE%" "%APPLIED%\" >nul 2>nul
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 0
) else (
  >>"%REPORT%" echo STATUS=PATCH_RETURNED_ERROR
  >>"%REPORT%" echo RESULT=FAIL_PATCH_RETURNED_ERROR
  move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b %RC%
)

:quarantine_dangerous
>>"%REPORT%" echo STATUS=PATCH_SAFETY_SCAN_FAILED
>>"%REPORT%" echo RESULT=FAIL_PATCH_SAFETY_SCAN_FAILED_QUARANTINED
move /y "%PATCH_FILE%" "%QUARANTINE%\" >nul 2>nul
copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
exit /b 9

:safety_scan_file
set "SCAN_TARGET=%~1"
findstr /i /m /c:"LIVE_ORDERS_ON" /c:"ENABLE_LIVE_TRADING" /c:"API_SECRET" /c:"PRIVATE_ENDPOINT" /c:"CREATE_ORDER" /c:"FAPI" "%SCAN_TARGET%" >nul 2>nul
if errorlevel 1 exit /b 0
exit /b 1

:safety_scan_tree
set "SCAN_TARGET=%~1"
findstr /s /i /m /c:"LIVE_ORDERS_ON" /c:"ENABLE_LIVE_TRADING" /c:"API_SECRET" /c:"PRIVATE_ENDPOINT" /c:"CREATE_ORDER" /c:"FAPI" "%SCAN_TARGET%\*.*" >nul 2>nul
if errorlevel 1 exit /b 0
exit /b 1

:start_report
>"%REPORT%" echo BALI AUTO PATCH LANE REPORT
>>"%REPORT%" echo Generated: %DATE% %TIME%
>>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>>"%REPORT%" echo VERSION=V023_AUTOMATIC_PATCH_LANE_NO_PYTHON
>>"%REPORT%" echo PYTHON_USED=NO
>>"%REPORT%" echo UPDATE_DOCK_USED=NO
>>"%REPORT%" echo ROOT=%BALI_ROOT%
>>"%REPORT%" echo INBOX=%INBOX%
>>"%REPORT%" echo APPLIED=%APPLIED%
>>"%REPORT%" echo QUARANTINE=%QUARANTINE%
exit /b 0
