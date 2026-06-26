@echo off
setlocal
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "RUNTIME=%ROOT%\shared_data\runtime"
rmdir /s /q "%RUNTIME%\BALI_FOREVER_ONE_CLICK_MAIN.lock" >nul 2>nul
rmdir /s /q "%RUNTIME%\BALI_DASH_UPDATES_WATCHER_LOOP.lock" >nul 2>nul
rmdir /s /q "%RUNTIME%\BALI_DASH_UPDATES_APPLY.lock" >nul 2>nul
echo Bali auto patch launch locks cleared.
pause
exit /b 0
