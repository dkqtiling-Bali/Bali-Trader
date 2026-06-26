@echo off
setlocal EnableExtensions

set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "TOOLS=%APP%\tools\BALI_SUPERVISOR"
set "REPORTS=%APP%\shared_data\reports"
set "DESKTOP=%USERPROFILE%\Desktop"
set "REPORT=%REPORTS%\BALI_V039_SUPERVISOR_INSTALL_REPORT.txt"

mkdir "%TOOLS%" >nul 2>nul
mkdir "%REPORTS%" >nul 2>nul
mkdir "%BASE%\updates" >nul 2>nul
mkdir "%BASE%\updates\APPLIED" >nul 2>nul
mkdir "%BASE%\updates\QUARANTINE" >nul 2>nul

copy /Y "%~dp0supervisor\BALI_SUPERVISOR.ps1" "%TOOLS%\BALI_SUPERVISOR.ps1" >nul
copy /Y "%~dp0supervisor\BALI_SUPERVISOR_ONE_CLICK.bat" "%TOOLS%\BALI_SUPERVISOR_ONE_CLICK.bat" >nul

(
  echo @echo off
  echo call "%TOOLS%\BALI_SUPERVISOR_ONE_CLICK.bat"
) > "%DESKTOP%\Bali Supervisor Mission Control.bat"

(
  echo BALI V039 SUPERVISOR INSTALL REPORT
  echo Generated: %date% %time%
  echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
  echo VERSION=V039_BALI_SUPERVISOR_ONE_CLICK
  echo PYTHON_USED=NO
  echo UPDATE_DOCK_USED=NO
  echo MODE=EXTERNAL_SUPERVISOR_DO_NOT_PATCH_FOREVER_STARTER
  echo BASE=%BASE%
  echo APP=%APP%
  echo TOOLS=%TOOLS%
  echo DESKTOP_LAUNCHER=%DESKTOP%\Bali Supervisor Mission Control.bat
  echo REPORTS=%REPORTS%
  echo RESULT=PASS_V039_SUPERVISOR_INSTALLED
) > "%REPORT%"

start "" notepad "%REPORT%"
echo.
echo V039 Bali Supervisor installed.
echo Use Desktop launcher: Bali Supervisor Mission Control.bat
echo.
pause
