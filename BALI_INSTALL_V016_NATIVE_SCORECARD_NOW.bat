@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Bali V016 Native Evidence Scorecard Installer

echo ==========================================================
echo  BALI V016 NATIVE EVIDENCE SCORECARD INSTALLER
echo ==========================================================
echo Safety: live orders stay OFF; no API keys; no private endpoints.
echo This installs an additive scorecard/report sidecar only.
echo.

set "HELPER=%~dp0"
set "PAYLOAD=%HELPER%payload"
set "KNOWN=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\bali_rocket_crypto_command_v011b"
set "ROOT="

if exist "%CD%\shared_data" set "ROOT=%CD%"
if not defined ROOT if exist "%HELPER%shared_data" set "ROOT=%HELPER:~0,-1%"
if not defined ROOT if exist "%KNOWN%\shared_data" set "ROOT=%KNOWN%"
if not defined ROOT (
  echo ERROR: Could not find Bali root.
  echo Put this unzipped folder on the Desktop, or inside the Bali app folder, then run again.
  pause
  exit /b 2
)

echo Bali root: %ROOT%
echo Payload: %PAYLOAD%
if not exist "%PAYLOAD%\tools\bali_v016_native_evidence_scorecard.py" (
  echo ERROR: Payload missing. Did you run this inside the ZIP instead of the unzipped folder?
  pause
  exit /b 3
)

if not exist "%ROOT%\tools" mkdir "%ROOT%\tools"
if not exist "%ROOT%\dashboard_snippets" mkdir "%ROOT%\dashboard_snippets"
if not exist "%ROOT%\shared_data\reports" mkdir "%ROOT%\shared_data\reports"
if not exist "%ROOT%\shared_data\dashboard" mkdir "%ROOT%\shared_data\dashboard"

copy /Y "%PAYLOAD%\tools\bali_v016_native_evidence_scorecard.py" "%ROOT%\tools\bali_v016_native_evidence_scorecard.py" >nul
copy /Y "%PAYLOAD%\V016_NATIVE_PATCH_MANIFEST.json" "%ROOT%\V016_NATIVE_PATCH_MANIFEST.json" >nul
copy /Y "%PAYLOAD%\dashboard_snippets\v016_native_evidence_scorecard_panel.html" "%ROOT%\dashboard_snippets\v016_native_evidence_scorecard_panel.html" >nul
copy /Y "%HELPER%RUN_V016_EVIDENCE_SCORECARD_NOW.bat" "%ROOT%\RUN_V016_EVIDENCE_SCORECARD_NOW.bat" >nul

echo Installed files copied.
echo Running scorecard once now...
py -3 "%ROOT%\tools\bali_v016_native_evidence_scorecard.py" --root "%ROOT%" --print > "%ROOT%\shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt" 2> "%ROOT%\shared_data\reports\BALI_V016_SCORECARD_INSTALL_ERROR.txt"
if errorlevel 1 (
  python "%ROOT%\tools\bali_v016_native_evidence_scorecard.py" --root "%ROOT%" --print > "%ROOT%\shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt" 2>> "%ROOT%\shared_data\reports\BALI_V016_SCORECARD_INSTALL_ERROR.txt"
)

if exist "%ROOT%\shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt" (
  echo.
  type "%ROOT%\shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt"
  echo.
  echo RESULT: V016_NATIVE_SCORECARD_INSTALLED_AND_RAN
  start notepad "%ROOT%\shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt"
) else (
  echo RESULT: INSTALLED_BUT_SCORECARD_RUN_FAILED
  echo Check: %ROOT%\shared_data\reports\BALI_V016_SCORECARD_INSTALL_ERROR.txt
  if exist "%ROOT%\shared_data\reports\BALI_V016_SCORECARD_INSTALL_ERROR.txt" start notepad "%ROOT%\shared_data\reports\BALI_V016_SCORECARD_INSTALL_ERROR.txt"
)

echo.
echo NEXT: Start Bali normally. Open Reports or run RUN_V016_EVIDENCE_SCORECARD_NOW.bat from the Bali folder.
pause
exit /b 0
