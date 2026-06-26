@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Bali Forever Mission Control - V031 AutoPatch Preflight

set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "ORIGINAL=%BASE%\BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat"
set "UPDATE_FOLDER=%BASE%\updates"
set "APPLIED=%UPDATE_FOLDER%\APPLIED"
set "QUARANTINE=%UPDATE_FOLDER%\QUARANTINE"
set "LEGACY=%UPDATE_FOLDER%\LEGACY_SKIPPED"
set "REPORTS=%APP%\shared_data\reports"
set "REPORT=%REPORTS%\BALI_V031_AUTOPATCH_RUN_REPORT.txt"
set "PROOF=%BASE%\BALI_V031_PRELAUNCH_PROOF.txt"

if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
if not exist "%UPDATE_FOLDER%" mkdir "%UPDATE_FOLDER%" >nul 2>nul
if not exist "%APPLIED%" mkdir "%APPLIED%" >nul 2>nul
if not exist "%QUARANTINE%" mkdir "%QUARANTINE%" >nul 2>nul
if not exist "%LEGACY%" mkdir "%LEGACY%" >nul 2>nul

(
  echo BALI V031 AUTOPATCH RUN REPORT
  echo Generated: %DATE% %TIME%
  echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  echo VERSION=V031_AUTOPATCH_SELECTOR_AND_CALL_FIX
  echo BASE=%BASE%
  echo APP=%APP%
  echo UPDATE_FOLDER=%UPDATE_FOLDER%
  echo PYTHON_USED=NO
  echo UPDATE_DOCK_USED=NO
  echo SELECTOR=ONLY_BALI_AUTO_PATCH_MANIFEST_TXT
) > "%REPORT%"

(
  echo BALI V031 PRELAUNCH PROOF
  echo Generated: %DATE% %TIME%
  echo VERSION=V031_AUTOPATCH_SELECTOR_AND_CALL_FIX
  echo RESULT=PRELAUNCH_PROOF_WRITTEN_BEFORE_BALI_START
) > "%PROOF%"

set "SELECTED="
set "TEMP_DIR="

for %%Z in ("%UPDATE_FOLDER%\*.zip") do (
  if not defined SELECTED (
    set "ZIP=%%~fZ"
    set "CAND=%TEMP%\BALI_V031_PATCH_!RANDOM!_!RANDOM!"
    mkdir "!CAND!" >nul 2>nul
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -LiteralPath '!ZIP!' -DestinationPath '!CAND!' -Force; exit 0 } catch { exit 7 }" >nul 2>nul
    if errorlevel 1 (
      echo ZIP_UNREADABLE=!ZIP!>>"%REPORT%"
      move /Y "!ZIP!" "%QUARANTINE%\%%~nxZ" >nul 2>nul
      rmdir /S /Q "!CAND!" >nul 2>nul
    ) else (
      if exist "!CAND!\BALI_AUTO_PATCH_MANIFEST.txt" (
        if exist "!CAND!\AUTO_PATCH_INSTALL.bat" (
          set "SELECTED=!ZIP!"
          set "TEMP_DIR=!CAND!"
        ) else (
          echo PATCH_MISSING_INSTALLER=!ZIP!>>"%REPORT%"
          move /Y "!ZIP!" "%QUARANTINE%\%%~nxZ" >nul 2>nul
          rmdir /S /Q "!CAND!" >nul 2>nul
        )
      ) else (
        echo SKIP_LEGACY_NO_V031_MANIFEST=!ZIP!>>"%REPORT%"
        move /Y "!ZIP!" "%LEGACY%\%%~nxZ" >nul 2>nul
        rmdir /S /Q "!CAND!" >nul 2>nul
      )
    )
  )
)

if not defined SELECTED (
  echo PATCH_FOUND=NONE_VALID_V031_FORMAT>>"%REPORT%"
  echo RESULT=NO_VALID_PATCH_STARTING_ORIGINAL>>"%REPORT%"
  start "" notepad "%REPORT%"
  if exist "%ORIGINAL%" start "Bali Forever Original" /min "%ORIGINAL%"
  exit /b 0
)

set "PATCH_INSTALLER=%TEMP_DIR%\AUTO_PATCH_INSTALL.bat"
echo PATCH_FOUND=%SELECTED%>>"%REPORT%"
echo PATCH_INSTALLER=%PATCH_INSTALLER%>>"%REPORT%"

call "%PATCH_INSTALLER%" "%APP%" "%BASE%" "%REPORTS%" >>"%REPORT%" 2>&1
set "PATCH_EXIT_CODE=%ERRORLEVEL%"
echo PATCH_EXIT_CODE=%PATCH_EXIT_CODE%>>"%REPORT%"

if not "%PATCH_EXIT_CODE%"=="0" (
  echo PATCH_STATUS=QUARANTINE_INSTALLER_FAILED>>"%REPORT%"
  move /Y "%SELECTED%" "%QUARANTINE%\" >nul 2>nul
  rmdir /S /Q "%TEMP_DIR%" >nul 2>nul
  echo RESULT=FAIL_PATCH_QUARANTINED_INSTALLER_FAILED>>"%REPORT%"
  start "" notepad "%REPORT%"
  if exist "%ORIGINAL%" start "Bali Forever Original" /min "%ORIGINAL%"
  exit /b 1
)

echo PATCH_STATUS=APPLIED>>"%REPORT%"
move /Y "%SELECTED%" "%APPLIED%\" >nul 2>nul
rmdir /S /Q "%TEMP_DIR%" >nul 2>nul
echo RESULT=PASS_PATCH_APPLIED_BEFORE_BALI_START>>"%REPORT%"
start "" notepad "%REPORT%"
if exist "%ORIGINAL%" start "Bali Forever Original" /min "%ORIGINAL%"
exit /b 0
