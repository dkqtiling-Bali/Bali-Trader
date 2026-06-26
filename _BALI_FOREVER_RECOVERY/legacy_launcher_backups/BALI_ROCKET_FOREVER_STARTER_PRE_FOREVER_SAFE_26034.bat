@echo off



setlocal EnableExtensions EnableDelayedExpansion



cd /d "%~dp0"



rem Compatibility wrapper only. The visible desktop shortcut is Bali Forever Starter.



if exist "%~dp0BALI_THEMED_FOREVER_STARTER.bat" (



  call "%~dp0BALI_THEMED_FOREVER_STARTER.bat"



  exit /b %ERRORLEVEL%



)



call "%~dp0ROCKET_CRYPTO_COMMAND_START.bat"



exit /b %ERRORLEVEL%



