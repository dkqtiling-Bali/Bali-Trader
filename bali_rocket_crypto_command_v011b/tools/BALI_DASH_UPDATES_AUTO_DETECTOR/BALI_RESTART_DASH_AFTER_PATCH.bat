@echo off
setlocal EnableExtensions EnableDelayedExpansion
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "REPORTS=%ROOT%\shared_data\reports"
set "RUNTIME=%ROOT%\shared_data\runtime"
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":9061 .*LISTENING"') do (
  taskkill /f /pid %%P >nul 2>nul
)
timeout /t 2 /nobreak >nul
call "%~dp0BALI_START_DASH_ONLY.bat"
timeout /t 2 /nobreak >nul

set "LATEST="
for /f "delims=" %%R in ('dir /b /a-d /o-d "%REPORTS%\*.txt" 2^>nul') do (
  if not defined LATEST set "LATEST=%REPORTS%\%%R"
)
if defined LATEST start "Bali Final Report" notepad "%LATEST%"
start "" "http://127.0.0.1:9061"
exit /b 0
