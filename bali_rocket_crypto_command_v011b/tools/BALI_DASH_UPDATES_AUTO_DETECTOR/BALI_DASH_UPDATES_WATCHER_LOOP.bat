@echo off
setlocal EnableExtensions
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "RUNTIME=%ROOT%\shared_data\runtime"
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul
set "LOCKDIR=%RUNTIME%\BALI_DASH_UPDATES_WATCHER_LOOP.lock"
mkdir "%LOCKDIR%" >nul 2>nul
if errorlevel 1 exit /b 0

:loop
call "%~dp0BALI_UPDATES_DETECTOR_ONCE.bat" WATCHER
if errorlevel 10 call "%~dp0BALI_RESTART_DASH_AFTER_PATCH.bat"
timeout /t 15 /nobreak >nul
goto loop
