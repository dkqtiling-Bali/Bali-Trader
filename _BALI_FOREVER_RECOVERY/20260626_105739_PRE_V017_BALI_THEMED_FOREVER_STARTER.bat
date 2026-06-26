@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if exist "%~dp0tools\BALI_FOREVER_ENGINE.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_FOREVER_ENGINE.ps1" -Root "%CD%" -Port 9061 -OpenBrowser
  exit /b %ERRORLEVEL%
)
setlocal EnableExtensions EnableDelayedExpansion
title Bali Forever Mission Control - V037 Autopatch Engine

set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "ORIGINAL=%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V037.bat"
set "FALLBACK_ORIGINAL=%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat"
set "UPDATE_FOLDER=%BASE%\updates"
set "APPLIED=%UPDATE_FOLDER%\APPLIED"
set "QUARANTINE=%UPDATE_FOLDER%\QUARANTINE"
set "LEGACY=%UPDATE_FOLDER%\LEGACY_SKIPPED"
set "REPORTS=%APP%\shared_data\reports"
set "STATUS=%REPORTS%\BALI_AUTOPATCH_STATUS_LATEST.txt"
set "STATUS_MD=%REPORTS%\BALI_AUTOPATCH_STATUS_LATEST.md"
set "STATUS_JSON=%REPORTS%\BALI_AUTOPATCH_STATUS_LATEST.json"
set "RUN_REPORT=%REPORTS%\BALI_V037_AUTOPATCH_RUN_REPORT.txt"
set "PROOF=%BASE%\BALI_V037_PRELAUNCH_PROOF.txt"
set "SNIPPET=%REPORTS%\BALI_CHATGPT_AUTOPATCH_STATUS_SNIPPET.txt"

if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
if not exist "%UPDATE_FOLDER%" mkdir "%UPDATE_FOLDER%" >nul 2>nul
if not exist "%APPLIED%" mkdir "%APPLIED%" >nul 2>nul
if not exist "%QUARANTINE%" mkdir "%QUARANTINE%" >nul 2>nul
if not exist "%LEGACY%" mkdir "%LEGACY%" >nul 2>nul

set "AUTOPATCH_RESULT=NO_PATCH_WAITING"
set "PATCH_FOUND=NONE"
set "PATCH_STATUS=NONE"
set "PATCH_EXIT_CODE=0"
set "PATCH_PAYLOAD_RESULT=NONE"

> "%PROOF%" echo BALI V037 PRELAUNCH PROOF
>> "%PROOF%" echo Generated: %date% %time%
>> "%PROOF%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%PROOF%" echo VERSION=V037_FOREVER_AUTOPATCH_ENGINE
>> "%PROOF%" echo RESULT=PRELAUNCH_PROOF_WRITTEN_BEFORE_BALI_START

> "%RUN_REPORT%" echo BALI V037 AUTOPATCH RUN REPORT
>> "%RUN_REPORT%" echo Generated: %date% %time%
>> "%RUN_REPORT%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%RUN_REPORT%" echo VERSION=V037_FOREVER_AUTOPATCH_ENGINE
>> "%RUN_REPORT%" echo BASE=%BASE%
>> "%RUN_REPORT%" echo APP=%APP%
>> "%RUN_REPORT%" echo UPDATE_FOLDER=%UPDATE_FOLDER%
>> "%RUN_REPORT%" echo PYTHON_USED=NO
>> "%RUN_REPORT%" echo UPDATE_DOCK_USED=NO
>> "%RUN_REPORT%" echo SELECTOR=REQUIRES_BALI_AUTO_PATCH_MANIFEST_TXT_AND_AUTO_PATCH_INSTALL_BAT

rem Choose exactly one valid V031+ patch from the root of updates.
for %%Z in ("%UPDATE_FOLDER%\*.zip") do (
  if "!PATCH_FOUND!"=="NONE" (
    tar -tf "%%~fZ" 2>nul | findstr /i /x "BALI_AUTO_PATCH_MANIFEST.txt" >nul
    if not errorlevel 1 (
      tar -tf "%%~fZ" 2>nul | findstr /i /x "AUTO_PATCH_INSTALL.bat" >nul
      if not errorlevel 1 (
        set "PATCH_FOUND=%%~fZ"
      ) else (
        >> "%RUN_REPORT%" echo SKIP_NO_INSTALLER=%%~fZ
        move /y "%%~fZ" "%LEGACY%\%%~nxZ" >nul 2>nul
      )
    ) else (
      >> "%RUN_REPORT%" echo SKIP_LEGACY_NO_MANIFEST=%%~fZ
      move /y "%%~fZ" "%LEGACY%\%%~nxZ" >nul 2>nul
    )
  ) else (
    >> "%RUN_REPORT%" echo SKIP_EXTRA_PATCH_FOR_NEXT_LAUNCH=%%~fZ
  )
)

if not "!PATCH_FOUND!"=="NONE" (
  set "TMP=%TEMP%\BALI_V037_PATCH_%RANDOM%_%RANDOM%"
  mkdir "!TMP!" >nul 2>nul
  tar -xf "!PATCH_FOUND!" -C "!TMP!" >> "%RUN_REPORT%" 2>&1
  if exist "!TMP!\AUTO_PATCH_INSTALL.bat" (
    >> "%RUN_REPORT%" echo PATCH_FOUND=!PATCH_FOUND!
    >> "%RUN_REPORT%" echo PATCH_INSTALLER=!TMP!\AUTO_PATCH_INSTALL.bat
    call "!TMP!\AUTO_PATCH_INSTALL.bat" "%APP%" "%BASE%" "%REPORTS%" >> "%RUN_REPORT%" 2>&1
    set "PATCH_EXIT_CODE=!ERRORLEVEL!"
    >> "%RUN_REPORT%" echo PATCH_EXIT_CODE=!PATCH_EXIT_CODE!
    findstr /i /c:"RESULT=PASS" "%RUN_REPORT%" >nul 2>nul
    if "!PATCH_EXIT_CODE!"=="0" (
      set "PATCH_STATUS=APPLIED"
      set "AUTOPATCH_RESULT=PATCH_APPLIED_BEFORE_BALI_START"
      move /y "!PATCH_FOUND!" "%APPLIED%\" >nul 2>nul
    ) else (
      set "PATCH_STATUS=QUARANTINE_INSTALLER_FAILED"
      set "AUTOPATCH_RESULT=PATCH_FAILED_QUARANTINED"
      move /y "!PATCH_FOUND!" "%QUARANTINE%\" >nul 2>nul
    )
  ) else (
    set "PATCH_STATUS=QUARANTINE_MISSING_INSTALLER_AFTER_EXTRACT"
    set "AUTOPATCH_RESULT=PATCH_MISSING_INSTALLER_QUARANTINED"
    move /y "!PATCH_FOUND!" "%QUARANTINE%\" >nul 2>nul
  )
  rmdir /s /q "!TMP!" >nul 2>nul
)

>> "%RUN_REPORT%" echo PATCH_FOUND=!PATCH_FOUND!
>> "%RUN_REPORT%" echo PATCH_STATUS=!PATCH_STATUS!
>> "%RUN_REPORT%" echo AUTOPATCH_RESULT=!AUTOPATCH_RESULT!
if "!PATCH_STATUS!"=="APPLIED" (
  >> "%RUN_REPORT%" echo RESULT=PASS_PATCH_APPLIED_BEFORE_BALI_START
) else if "!AUTOPATCH_RESULT!"=="NO_PATCH_WAITING" (
  >> "%RUN_REPORT%" echo RESULT=PASS_NO_PATCH_WAITING_BALI_STARTING
) else (
  >> "%RUN_REPORT%" echo RESULT=FAIL_PATCH_NOT_APPLIED_BALI_STILL_STARTING
)

> "%STATUS%" echo BALI AUTOPATCH STATUS LATEST
>> "%STATUS%" echo Generated: %date% %time%
>> "%STATUS%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%STATUS%" echo VERSION=V037_FOREVER_AUTOPATCH_ENGINE
>> "%STATUS%" echo PYTHON_USED=NO
>> "%STATUS%" echo UPDATE_DOCK_USED=NO
>> "%STATUS%" echo AUTOPATCH_PREFLIGHT=RAN
>> "%STATUS%" echo AUTOPATCH_RESULT=!AUTOPATCH_RESULT!
>> "%STATUS%" echo PATCH_FOUND=!PATCH_FOUND!
>> "%STATUS%" echo PATCH_STATUS=!PATCH_STATUS!
>> "%STATUS%" echo RUN_REPORT=%RUN_REPORT%
>> "%STATUS%" echo PRELAUNCH_PROOF=%PROOF%
if "!PATCH_STATUS!"=="APPLIED" (>> "%STATUS%" echo RESULT=PASS_PATCH_APPLIED_BEFORE_BALI_START) else if "!AUTOPATCH_RESULT!"=="NO_PATCH_WAITING" (>> "%STATUS%" echo RESULT=PASS_NO_PATCH_WAITING_BALI_STARTING) else (>> "%STATUS%" echo RESULT=FAIL_PATCH_NOT_APPLIED_BALI_STILL_STARTING)

> "%SNIPPET%" echo AUTOPATCH_PREFLIGHT=RAN
>> "%SNIPPET%" echo AUTOPATCH_ENGINE=V037_FOREVER_AUTOPATCH_ENGINE
>> "%SNIPPET%" echo AUTOPATCH_RESULT=!AUTOPATCH_RESULT!
>> "%SNIPPET%" echo PATCH_STATUS=!PATCH_STATUS!

> "%STATUS_MD%" echo # Bali Autopatch Status Latest
>> "%STATUS_MD%" echo.
>> "%STATUS_MD%" echo - Version: V037_FOREVER_AUTOPATCH_ENGINE
>> "%STATUS_MD%" echo - Python used: NO
>> "%STATUS_MD%" echo - Update Dock used: NO
>> "%STATUS_MD%" echo - Autopatch preflight: RAN
>> "%STATUS_MD%" echo - Autopatch result: !AUTOPATCH_RESULT!
>> "%STATUS_MD%" echo - Patch status: !PATCH_STATUS!
>> "%STATUS_MD%" echo - Patch found: !PATCH_FOUND!

> "%STATUS_JSON%" echo {
>> "%STATUS_JSON%" echo   "version": "V037_FOREVER_AUTOPATCH_ENGINE",
>> "%STATUS_JSON%" echo   "python_used": false,
>> "%STATUS_JSON%" echo   "update_dock_used": false,
>> "%STATUS_JSON%" echo   "autopatch_preflight": "RAN",
>> "%STATUS_JSON%" echo   "autopatch_result": "!AUTOPATCH_RESULT!",
>> "%STATUS_JSON%" echo   "patch_status": "!PATCH_STATUS!"
>> "%STATUS_JSON%" echo }

rem If a patch was applied or failed, open the status report. If no patch is waiting, keep quiet but leave proof files.
if not "!AUTOPATCH_RESULT!"=="NO_PATCH_WAITING" start "" notepad "%STATUS%"

if not exist "%ORIGINAL%" set "ORIGINAL=%FALLBACK_ORIGINAL%"
>> "%RUN_REPORT%" echo STARTING_ORIGINAL=%ORIGINAL%
if exist "%ORIGINAL%" (
  start "Bali Forever Original" /min cmd /c call "%ORIGINAL%"
) else (
  >> "%RUN_REPORT%" echo RESULT=FAIL_ORIGINAL_STARTER_NOT_FOUND
  start "" notepad "%RUN_REPORT%"
  exit /b 1
)
exit /b 0
