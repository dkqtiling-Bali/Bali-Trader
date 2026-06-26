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




title Bali Python Doctor V012J




set "ROOT=%CD%"




set "LOGDIR=%ROOT%\logs"




if not exist "%LOGDIR%" mkdir "%LOGDIR%"




set "REPORT=%LOGDIR%\BALI_PYTHON_DOCTOR_REPORT_V012J.txt"




(




  echo BALI ROCKET CRYPTO COMMAND - PYTHON DOCTOR REPORT V012J




  echo Generated: %DATE% %TIME%




  echo Folder: %ROOT%




  echo Mission: STARGATE RIVAL MODE - keep the challenger machine bootable and safe.




  echo Purpose: show detected Python versions and confirm app.py location.




  echo Safety: live orders OFF, champion lock LOCKED, no API keys.




  echo.




) > "%REPORT%"









call :find_app_root




if defined APP_ROOT (




  echo App root found: %APP_ROOT% >> "%REPORT%"




) else (




  echo App root NOT found from: %ROOT% >> "%REPORT%"




)









echo. >> "%REPORT%"




echo === Python candidates === >> "%REPORT%"




call :probe "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" "direct local Python 3.10"




call :probe "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" "direct local Python 3.11"




call :probe "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" "direct local Python 3.12"




call :probe "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" "bad Python 3.13 - should be skipped"




call :probe "%ProgramFiles%\Python310\python.exe" "Program Files Python 3.10"




call :probe "%ProgramFiles%\Python311\python.exe" "Program Files Python 3.11"




call :probe "%ProgramFiles%\Python312\python.exe" "Program Files Python 3.12"




call :probe "%ProgramFiles%\Python313\python.exe" "bad Program Files Python 3.13 - should be skipped"









echo. >> "%REPORT%"




echo === PATH python === >> "%REPORT%"




where python >> "%REPORT%" 2>&1




where python3 >> "%REPORT%" 2>&1




where py >> "%REPORT%" 2>&1









echo. >> "%REPORT%"




echo RESULT: DOCTOR COMPLETE >> "%REPORT%"




echo Good target: Python 3.10, 3.11, or 3.12. Python 3.13 remains blocked by the launcher. >> "%REPORT%"




echo V012J note: run BALI_ROCKET_HEALTH_CHECK.bat for no-launch readiness testing. >> "%REPORT%"




echo Report: %REPORT%




echo.




type "%REPORT%"




start "" notepad "%REPORT%"




pause




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









:probe




set "P=%~1"




set "L=%~2"




echo. >> "%REPORT%"




echo Checking: %L% >> "%REPORT%"




echo Path: %P% >> "%REPORT%"




if not exist "%P%" (




  echo Status: missing >> "%REPORT%"




  exit /b 0




)




"%P%" -c "import sys; print('version=' + sys.version.split()[0]); print('executable=' + sys.executable); raise SystemExit(0 if sys.version_info >= (3,10) and sys.version_info < (3,13) else 8)" >> "%REPORT%" 2>&1




if errorlevel 1 (




  echo Status: not accepted by Bali launcher rules >> "%REPORT%"




) else (




  echo Status: accepted by Bali launcher rules >> "%REPORT%"




)




exit /b 0




