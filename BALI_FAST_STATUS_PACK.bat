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


title Bali Fast Status Pack V012J


set "ROOT=%CD%"


set "LOGDIR=%ROOT%\logs"


if not exist "%LOGDIR%" mkdir "%LOGDIR%"


set "REPORT=%LOGDIR%\BALI_FAST_STATUS_PACK_V012J.txt"


set "ENGINE=%ROOT%\tools\BALI_FAST_STATUS_PACK_V012J.ps1"





if not exist "%ENGINE%" goto :missing_engine


powershell -NoProfile -ExecutionPolicy Bypass -File "%ENGINE%" -Root "%ROOT%" -Report "%REPORT%"


set "RC=%ERRORLEVEL%"


echo.


type "%REPORT%"


start "" notepad "%REPORT%"


echo.


echo This is the compact report to paste back when asking for the next patch.


pause


exit /b %RC%





:missing_engine


(


  echo BALI FAST STATUS PACK V012J


  echo Generated: %DATE% %TIME%


  echo Root folder: %ROOT%


  echo RESULT: FAST STATUS ENGINE MISSING


  echo Expected engine: %ENGINE%


) > "%REPORT%"


type "%REPORT%"


start "" notepad "%REPORT%"


pause


exit /b 9


