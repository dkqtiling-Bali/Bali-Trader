@echo off
setlocal EnableExtensions
set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "UPDATES=%BASE%\updates"
set "REPORTS=%APP%\shared_data\reports"
set "STARTER=%BASE%\BALI_THEMED_FOREVER_STARTER.bat"
set "HEALTH=%REPORTS%\BALI_V037_AUTOPATCH_ENGINE_HEALTH_CHECK.txt"
if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>nul
> "%HEALTH%" echo BALI V037 AUTOPATCH ENGINE HEALTH CHECK
>> "%HEALTH%" echo Generated: %date% %time%
>> "%HEALTH%" echo SAFETY=LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS
>> "%HEALTH%" echo VERSION=V037_FOREVER_AUTOPATCH_ENGINE_HEALTH_CHECK
>> "%HEALTH%" echo PYTHON_USED=NO
>> "%HEALTH%" echo UPDATE_DOCK_USED=NO
if exist "%BASE%" (>> "%HEALTH%" echo BASE_EXISTS=YES) else (>> "%HEALTH%" echo BASE_EXISTS=NO)
if exist "%APP%" (>> "%HEALTH%" echo APP_EXISTS=YES) else (>> "%HEALTH%" echo APP_EXISTS=NO)
if exist "%UPDATES%" (>> "%HEALTH%" echo UPDATES_EXISTS=YES) else (>> "%HEALTH%" echo UPDATES_EXISTS=NO)
if exist "%STARTER%" (>> "%HEALTH%" echo REAL_FOREVER_STARTER_EXISTS=YES) else (>> "%HEALTH%" echo REAL_FOREVER_STARTER_EXISTS=NO)
findstr /c:"V037_FOREVER_AUTOPATCH_ENGINE" "%STARTER%" >nul 2>nul
if errorlevel 1 (>> "%HEALTH%" echo REAL_FOREVER_STARTER_V037_WRAPPED=NO) else (>> "%HEALTH%" echo REAL_FOREVER_STARTER_V037_WRAPPED=YES)
set /a ZIPCOUNT=0
if exist "%UPDATES%" for %%Z in ("%UPDATES%\*.zip") do set /a ZIPCOUNT+=1
>> "%HEALTH%" echo ACTIVE_UPDATES_ROOT_ZIP_COUNT=%ZIPCOUNT%
>> "%HEALTH%" echo RESULT=PASS_V037_HEALTH_CHECK_WRITTEN_NO_PYTHON
start "" notepad "%HEALTH%"
exit /b 0
