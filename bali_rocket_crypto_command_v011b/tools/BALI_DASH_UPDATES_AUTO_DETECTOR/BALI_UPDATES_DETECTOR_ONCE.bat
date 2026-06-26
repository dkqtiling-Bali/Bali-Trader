@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%ROOT%\..") do set "BUILD_ROOT=%%~fI"
set "UPDATES=%BUILD_ROOT%\updates"
set "TOOLS=%ROOT%\tools\BALI_DASH_UPDATES_AUTO_DETECTOR"
set "REPORTS=%ROOT%\shared_data\reports"
set "RUNTIME=%ROOT%\shared_data\runtime"
set "WORKBASE=%ROOT%\shared_data\auto_patch_work"
set "REPORT=%REPORTS%\BALI_DASH_UPDATES_AUTO_DETECTOR_REPORT.txt"
set "DESKTOP=%USERPROFILE%\Desktop"
set "DESKTOP_REPORT=%DESKTOP%\BALI_DASH_UPDATES_AUTO_DETECTOR_REPORT.txt"

if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
if not exist "%WORKBASE%" mkdir "%WORKBASE%" >nul 2>nul
if not exist "%UPDATES%" mkdir "%UPDATES%" >nul 2>nul
if not exist "%UPDATES%\APPLIED" mkdir "%UPDATES%\APPLIED" >nul 2>nul
if not exist "%UPDATES%\QUARANTINE" mkdir "%UPDATES%\QUARANTINE" >nul 2>nul
if not exist "%UPDATES%\PROCESSING" mkdir "%UPDATES%\PROCESSING" >nul 2>nul

set "LOCKDIR=%RUNTIME%\BALI_DASH_UPDATES_APPLY.lock"
mkdir "%LOCKDIR%" >nul 2>nul
if errorlevel 1 (
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo RESULT=SKIP_ALREADY_APPLYING
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  exit /b 0
)

set "FIRST_ZIP="
set /a ZIP_COUNT=0
for /f "delims=" %%Z in ('dir /b /a-d /o-d "%UPDATES%\*.zip" 2^>nul') do (
  set /a ZIP_COUNT+=1
  if not defined FIRST_ZIP set "FIRST_ZIP=%%Z"
)

if "%ZIP_COUNT%"=="0" (
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  >>"%REPORT%" echo PYTHON_USED=NO
  >>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
  >>"%REPORT%" echo ZIP_COUNT=0
  >>"%REPORT%" echo RESULT=NO_PATCH_WAITING
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  rmdir "%LOCKDIR%" >nul 2>nul
  exit /b 0
)

set "STAMP=%DATE%_%TIME%_%RANDOM%"
set "STAMP=%STAMP:/=-%"
set "STAMP=%STAMP::=-%"
set "STAMP=%STAMP:.=-%"
set "STAMP=%STAMP: =_%"
set "PROCESS_DIR=%UPDATES%\PROCESSING\%STAMP%"
set "EXTRACT_DIR=%WORKBASE%\%STAMP%"
mkdir "%PROCESS_DIR%" >nul 2>nul
mkdir "%EXTRACT_DIR%" >nul 2>nul

set "SOURCE_ZIP=%UPDATES%\%FIRST_ZIP%"
set "PROCESS_ZIP=%PROCESS_DIR%\%FIRST_ZIP%"
move /y "%SOURCE_ZIP%" "%PROCESS_ZIP%" >nul 2>nul
if errorlevel 1 (
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  >>"%REPORT%" echo PYTHON_USED=NO
  >>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
  >>"%REPORT%" echo SELECTED_ZIP=%FIRST_ZIP%
  >>"%REPORT%" echo RESULT=FAIL_COULD_NOT_MOVE_ZIP_TO_PROCESSING
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  rmdir "%LOCKDIR%" >nul 2>nul
  exit /b 20
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%PROCESS_ZIP%' -DestinationPath '%EXTRACT_DIR%' -Force" >nul 2>nul
if errorlevel 1 (
  move /y "%PROCESS_ZIP%" "%UPDATES%\QUARANTINE\%FIRST_ZIP%" >nul 2>nul
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  >>"%REPORT%" echo PYTHON_USED=NO
  >>"%REPORT%" echo POWERSHELL_USED=YES_FOR_ZIP_ONLY
  >>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
  >>"%REPORT%" echo SELECTED_ZIP=%FIRST_ZIP%
  >>"%REPORT%" echo RESULT=QUARANTINED_BAD_ZIP_EXTRACT_FAILED
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  rmdir "%LOCKDIR%" >nul 2>nul
  exit /b 21
)

set "AUTORUN="
for /r "%EXTRACT_DIR%" %%F in (BALI_PATCH_AUTORUN_NO_PYTHON.bat BALI_PATCH_AUTORUN.bat) do (
  if not defined AUTORUN set "AUTORUN=%%F"
)
if not defined AUTORUN (
  for /r "%EXTRACT_DIR%" %%F in (BALI_ONE_CLICK*.bat BALI_INSTALL*.bat FIX_*.bat AUTO_INSTALL*.bat) do (
    if not defined AUTORUN set "AUTORUN=%%F"
  )
)

if not defined AUTORUN (
  move /y "%PROCESS_ZIP%" "%UPDATES%\QUARANTINE\%FIRST_ZIP%" >nul 2>nul
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  >>"%REPORT%" echo PYTHON_USED=NO
  >>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
  >>"%REPORT%" echo SELECTED_ZIP=%FIRST_ZIP%
  >>"%REPORT%" echo EXTRACT_DIR=%EXTRACT_DIR%
  >>"%REPORT%" echo RESULT=QUARANTINED_NO_AUTORUN_BAT_FOUND
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  rmdir "%LOCKDIR%" >nul 2>nul
  exit /b 22
)

set "PATCH_LOG=%REPORTS%\BALI_LAST_AUTO_PATCH_AUTORUN_LOG.txt"
start "Bali Patch Autorun" /wait /min cmd /c call "%AUTORUN%" >"%PATCH_LOG%" 2>&1
set "PATCH_EXIT=%ERRORLEVEL%"

if not "%PATCH_EXIT%"=="0" (
  move /y "%PROCESS_ZIP%" "%UPDATES%\QUARANTINE\%FIRST_ZIP%" >nul 2>nul
  >"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
  >>"%REPORT%" echo Generated: %DATE% %TIME%
  >>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  >>"%REPORT%" echo PYTHON_USED=NO
  >>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
  >>"%REPORT%" echo SELECTED_ZIP=%FIRST_ZIP%
  >>"%REPORT%" echo AUTORUN=%AUTORUN%
  >>"%REPORT%" echo AUTORUN_EXIT=%PATCH_EXIT%
  >>"%REPORT%" echo AUTORUN_LOG=%PATCH_LOG%
  >>"%REPORT%" echo RESULT=QUARANTINED_AUTORUN_FAILED
  copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul
  rmdir "%LOCKDIR%" >nul 2>nul
  exit /b 23
)

move /y "%PROCESS_ZIP%" "%UPDATES%\APPLIED\%FIRST_ZIP%" >nul 2>nul

>"%REPORT%" echo BALI DASH UPDATES AUTO DETECTOR REPORT
>>"%REPORT%" echo Generated: %DATE% %TIME%
>>"%REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>>"%REPORT%" echo PYTHON_USED=NO
>>"%REPORT%" echo POWERSHELL_USED=YES_FOR_ZIP_ONLY
>>"%REPORT%" echo UPDATE_DOCK_USED=NO
>>"%REPORT%" echo UPDATE_FOLDER=%UPDATES%
>>"%REPORT%" echo ZIP_COUNT_AT_START=%ZIP_COUNT%
>>"%REPORT%" echo SELECTED_ZIP=%FIRST_ZIP%
>>"%REPORT%" echo AUTORUN=%AUTORUN%
>>"%REPORT%" echo AUTORUN_EXIT=%PATCH_EXIT%
>>"%REPORT%" echo MOVED_TO=%UPDATES%\APPLIED\%FIRST_ZIP%
>>"%REPORT%" echo AUTORUN_LOG=%PATCH_LOG%
>>"%REPORT%" echo RESULT=PASS_PATCH_APPLIED_RESTART_DASH_REQUIRED
copy /y "%REPORT%" "%DESKTOP_REPORT%" >nul 2>nul

rmdir "%LOCKDIR%" >nul 2>nul
exit /b 10
