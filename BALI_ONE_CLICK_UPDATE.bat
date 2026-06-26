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




title Bali Rocket Crypto Command - One Click Update V012J




set "ROOT=%CD%"




set "LOGDIR=%ROOT%\logs"




if not exist "%LOGDIR%" mkdir "%LOGDIR%"




for /f "delims=" %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"




if not defined STAMP set "STAMP=manual_%RANDOM%"




set "REPORT=%LOGDIR%\BALI_ONE_CLICK_UPDATE_REPORT_V012J.txt"




set "ENGINE=%ROOT%\tools\BALI_ONE_CLICK_UPDATE_ENGINE_V012J.ps1"









if not exist "%ENGINE%" goto :missing_engine




powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%" -Stamp "%STAMP%"




set "RC=%ERRORLEVEL%"









echo.




if exist "%REPORT%" (




  type "%REPORT%"




  start "" notepad "%REPORT%"




) else (




  echo One-click update finished but no report file was found.




)




pause




exit /b %RC%









:missing_engine




(




  echo BALI ROCKET CRYPTO COMMAND - ONE CLICK UPDATE REPORT V012J




  echo Generated: %DATE% %TIME%




  echo Root folder: %ROOT%




  echo RESULT: UPDATE ENGINE MISSING




  echo Expected engine: %ENGINE%




  echo Fix: extract the V012J rescue kit into this Bali root folder, then run BALI_ONE_CLICK_UPDATE_RESCUE_V012J.bat.




  echo Safety: live orders OFF, champion lock LOCKED, no API keys.




) > "%REPORT%"




type "%REPORT%"




start "" notepad "%REPORT%"




pause




exit /b 9




