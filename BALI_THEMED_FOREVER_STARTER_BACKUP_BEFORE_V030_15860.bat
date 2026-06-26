@echo off



setlocal EnableExtensions EnableDelayedExpansion



cd /d "%~dp0"



title Bali Forever Starter V012J



if not exist "%~dp0ROCKET_CRYPTO_COMMAND_START.bat" (



  echo Bali launcher was not found in this folder.



  echo Expected: %~dp0ROCKET_CRYPTO_COMMAND_START.bat



  pause



  exit /b 2



)



call "%~dp0ROCKET_CRYPTO_COMMAND_START.bat"



exit /b %ERRORLEVEL%



