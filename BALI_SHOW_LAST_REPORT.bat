@echo off




setlocal EnableExtensions EnableDelayedExpansion




cd /d "%~dp0"
set "LOCAL_LAUNCH_DIR=%CD%"
set "ROOT=%CD%"
set "ROOT_GUARD=%LOCAL_LAUNCH_DIR%\tools\BALI_ROOT_GUARD_V012J.ps1"
if exist "%ROOT_GUARD%" (
  for /f "delims=" %%R in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT_GUARD%" -Start "%LOCAL_LAUNCH_DIR%"') do set "ROOT=%%R"
  cd /d "%ROOT%"
)




title Bali Rocket Crypto Command - Show Last Report V012J




set "ROOT=%CD%"




set "FOUND="









call :check "%ROOT%\logs\LAST_STARTUP_REPORT.txt"




if defined FOUND goto :show




call :check "%ROOT%\logs\BALI_ONE_CLICK_UPDATE_REPORT_V012J.txt"




if defined FOUND goto :show




call :check "%ROOT%\logs\LAST_HEALTH_CHECK_REPORT.txt"




if defined FOUND goto :show




call :find_app_root




if defined APP_ROOT call :check "%APP_ROOT%\logs\LAST_STARTUP_REPORT.txt"




if defined FOUND goto :show




if defined APP_ROOT call :check "%APP_ROOT%\logs\LAST_HEALTH_CHECK_REPORT.txt"




if defined FOUND goto :show




call :check "%ROOT%\BALI_VISIBLE_BOOT_REPORT_V012J.txt"




if defined FOUND goto :show




call :check "%ROOT%\BALI_VISIBLE_BOOT_REPORT_V011F.txt"




if defined FOUND goto :show









echo No Bali report was found from this folder yet.




echo Folder checked: %ROOT%




echo Run BALI_ROCKET_HEALTH_CHECK.bat or ROCKET_CRYPTO_COMMAND_START.bat first, then run this again.




pause




exit /b 1









:show




echo Showing report: %FOUND%




echo.




type "%FOUND%"




start "" notepad "%FOUND%"




pause




exit /b 0









:check




if exist "%~1" set "FOUND=%~1"




exit /b 0









:find_app_root




set "APP_ROOT="




if exist "%ROOT%\app.py" (




  set "APP_ROOT=%ROOT%"




  exit /b 0




)




for %%D in ("bali_rocket_crypto_command_v011b" "bali_rocket_crypto_command_v011c" "bali_rocket_crypto_command_v011d" "bali_rocket_crypto_command_v011e" "bali_rocket_crypto_command_v011f" "bali_rocket_crypto_command_v011h" "bali_rocket_crypto_command_v011i" "bali_rocket_crypto_command") do (




  if not defined APP_ROOT if exist "%ROOT%\%%~D\app.py" set "APP_ROOT=%ROOT%\%%~D"




)




if defined APP_ROOT exit /b 0




for /d %%D in ("%ROOT%\bali_rocket_crypto_command*") do (




  if not defined APP_ROOT if exist "%%~fD\app.py" set "APP_ROOT=%%~fD"




)




exit /b 0




