@echo off
setlocal EnableExtensions EnableDelayedExpansion

title BALI ONE CLICK PATCH TEMPLATE

echo ==========================================================
echo  BALI ONE CLICK PATCH TEMPLATE
echo ==========================================================
echo Safety: live orders stay OFF; no API keys; no private endpoints.
echo.

set "SCRIPT_DIR=%~dp0"
set "DESKTOP=%USERPROFILE%\Desktop"
set "REPORT_DESKTOP=%DESKTOP%\BALI_PATCH_TEMPLATE_INSTALL_REPORT.txt"
set "KNOWN_ROOT=%USERPROFILE%\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\bali_rocket_crypto_command_v011b"

> "%REPORT_DESKTOP%" echo BALI PATCH TEMPLATE INSTALL REPORT
>> "%REPORT_DESKTOP%" echo Generated: %DATE% %TIME%
>> "%REPORT_DESKTOP%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%REPORT_DESKTOP%" echo PYTHON_USED=NO
>> "%REPORT_DESKTOP%" echo UPDATE_DOCK_USED=NO

if exist "%KNOWN_ROOT%\shared_data\reports" (
  set "BALI_ROOT=%KNOWN_ROOT%"
) else (
  for /d %%D in ("%USERPROFILE%\Desktop\BALI_ROCKET_CRYPTO_COMMAND*" "%USERPROFILE%\Desktop\*BALI*") do (
    if exist "%%~fD\shared_data\reports" set "BALI_ROOT=%%~fD"
    if exist "%%~fD\bali_rocket_crypto_command_v011b\shared_data\reports" set "BALI_ROOT=%%~fD\bali_rocket_crypto_command_v011b"
  )
)

if not defined BALI_ROOT (
  >> "%REPORT_DESKTOP%" echo RESULT=FAIL_BALI_ROOT_NOT_FOUND
  notepad "%REPORT_DESKTOP%"
  exit /b 1
)

set "REPORTS=%BALI_ROOT%\shared_data\reports"
set "TOOLS=%BALI_ROOT%\tools"
if not exist "%REPORTS%" mkdir "%REPORTS%"
if not exist "%TOOLS%" mkdir "%TOOLS%"

>> "%REPORT_DESKTOP%" echo ROOT=%BALI_ROOT%
>> "%REPORT_DESKTOP%" echo REPORTS=%REPORTS%

REM Replace FEATURE_NAME and VERSION_TAG for each new patch.
set "FEATURE_NAME=PATCH_TEMPLATE"
set "VERSION_TAG=V000_PATCH_TEMPLATE_NO_PYTHON"

> "%TOOLS%\%VERSION_TAG%_MARKER.txt" echo %VERSION_TAG% INSTALLED %DATE% %TIME%
> "%REPORTS%\BALI_CAPABILITY_STATUS_%VERSION_TAG%.txt" echo VERSION=%VERSION_TAG%
>> "%REPORTS%\BALI_CAPABILITY_STATUS_%VERSION_TAG%.txt" echo FEATURE=%FEATURE_NAME%
>> "%REPORTS%\BALI_CAPABILITY_STATUS_%VERSION_TAG%.txt" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%REPORTS%\BALI_CAPABILITY_STATUS_%VERSION_TAG%.txt" echo RESULT=PASS_TEMPLATE_WRITTEN_NO_PYTHON

>> "%REPORT_DESKTOP%" echo WRITTEN_MARKER=%TOOLS%\%VERSION_TAG%_MARKER.txt
>> "%REPORT_DESKTOP%" echo WRITTEN_STATUS=%REPORTS%\BALI_CAPABILITY_STATUS_%VERSION_TAG%.txt
>> "%REPORT_DESKTOP%" echo RESULT=PASS_TEMPLATE_INSTALLED_NO_PYTHON

copy /y "%REPORT_DESKTOP%" "%REPORTS%\BALI_PATCH_TEMPLATE_INSTALL_REPORT.txt" >nul 2>nul
notepad "%REPORT_DESKTOP%"
exit /b 0
