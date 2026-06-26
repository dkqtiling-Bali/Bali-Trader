@echo off
setlocal
cd /d "%~dp0"
echo Bali Rocket Forever Auto Recovery Setup v2
echo.
echo This will scan for the Bali project, create START_BALI_ROCKET_SAFE.cmd, and add one desktop shortcut.
echo It will not enable live orders, add API keys, unlock Champion, or patch old launchers.
echo.
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0BaliForever_AutoRecovery_Setup.ps1"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0BaliForever_AutoRecovery_Setup.ps1" -ProjectRoot "%~1"
)
set "SETUP_EXIT=%ERRORLEVEL%"
echo.
if not "%SETUP_EXIT%"=="0" (
  echo SETUP FAILED with code %SETUP_EXIT%.
  echo Nothing was patched, no keys were added, live orders remain off, and Champion was not unlocked.
  echo.
  echo If auto-locate failed, drag the Bali project folder onto this RUN_BALI_FOREVER_SETUP.cmd file.
  pause
  exit /b %SETUP_EXIT%
)
echo Setup completed successfully.
echo Start Bali only from the desktop icon named Bali Rocket Forever Safe.
pause
exit /b 0
