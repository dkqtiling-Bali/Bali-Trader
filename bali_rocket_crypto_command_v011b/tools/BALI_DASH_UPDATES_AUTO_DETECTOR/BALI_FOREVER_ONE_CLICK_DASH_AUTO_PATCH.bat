@echo off
setlocal EnableExtensions
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "RUNTIME=%ROOT%\shared_data\runtime"
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
set "LOCKDIR=%RUNTIME%\BALI_FOREVER_ONE_CLICK_MAIN.lock"
mkdir "%LOCKDIR%" >nul 2>nul
if errorlevel 1 (
  start "" "http://127.0.0.1:9061"
  exit /b 0
)

start "Bali Updates Watcher" /min cmd /c call "%~dp0BALI_DASH_UPDATES_WATCHER_LOOP.bat"
call "%~dp0BALI_UPDATES_DETECTOR_ONCE.bat" LAUNCH
if errorlevel 10 (
  call "%~dp0BALI_RESTART_DASH_AFTER_PATCH.bat"
) else (
  call "%~dp0BALI_START_DASH_ONLY.bat"
)

rmdir "%LOCKDIR%" >nul 2>nul
exit /b 0
