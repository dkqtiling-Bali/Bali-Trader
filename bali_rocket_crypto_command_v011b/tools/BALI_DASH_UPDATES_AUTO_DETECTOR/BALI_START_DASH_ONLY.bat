@echo off
setlocal EnableExtensions EnableDelayedExpansion
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "REPORTS=%ROOT%\shared_data\reports"
set "RUNTIME=%ROOT%\shared_data\runtime"
if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>nul

netstat -ano | findstr /r /c:":9061 .*LISTENING" >"%RUNTIME%\port9061.txt" 2>nul
for %%A in ("%RUNTIME%\port9061.txt") do set "SIZE=%%~zA"
if defined SIZE if not "%SIZE%"=="0" (
  start "" "http://127.0.0.1:9061"
  exit /b 0
)

set "STARTER="
for /f "delims=" %%F in ('dir /b /s "%ROOT%\..\*Forever*Starter*.bat" 2^>nul') do (
  if not defined STARTER set "STARTER=%%F"
)
if not defined STARTER (
  for /f "delims=" %%F in ('dir /b /s "%ROOT%\..\*START*BALI*.bat" 2^>nul') do (
    echo %%F | findstr /i "AUTO_PATCH V023 V024 V025 V026" >nul
    if errorlevel 1 if not defined STARTER set "STARTER=%%F"
  )
)

if defined STARTER (
  start "Bali Forever Starter" /min "%STARTER%"
  timeout /t 5 /nobreak >nul
)
start "" "http://127.0.0.1:9061"
exit /b 0
