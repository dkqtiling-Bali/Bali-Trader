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



title Bali Themed Desktop Starter Icon V012J



set "ROOT=%CD%"



set "LOGDIR=%ROOT%\logs"



if not exist "%LOGDIR%" mkdir "%LOGDIR%"



set "REPORT=%LOGDIR%\BALI_THEMED_DESKTOP_ICON_REPORT_V012J.txt"



set "ENGINE=%ROOT%\tools\BALI_CREATE_FOREVER_DESKTOP_ICON_V012J.ps1"







if not exist "%ENGINE%" goto :missing_engine



powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%"



set "RC=%ERRORLEVEL%"



echo.



if exist "%REPORT%" (



  type "%REPORT%"



  start "" notepad "%REPORT%"



) else (



  echo Bali themed desktop icon creator finished but no report file was found.



)



pause



exit /b %RC%







:missing_engine



(



  echo BALI THEMED DESKTOP STARTER ICON REPORT V012J



  echo Generated: %DATE% %TIME%



  echo Root folder: %ROOT%



  echo RESULT: ICON ENGINE MISSING



  echo Expected engine: %ENGINE%



  echo Fix: apply the V012J patch, then run BALI_CREATE_FOREVER_DESKTOP_ICON.bat again.



  echo Safety: live orders OFF, champion lock LOCKED, no API keys.



) > "%REPORT%"



type "%REPORT%"



start "" notepad "%REPORT%"



pause



exit /b 9



