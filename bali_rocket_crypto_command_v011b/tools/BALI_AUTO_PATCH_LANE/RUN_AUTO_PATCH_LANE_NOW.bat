@echo off
setlocal
set "BALI_ROOT=%~dp0..\.."
for %%I in ("%BALI_ROOT%") do set "BALI_ROOT=%%~fI"
call "%BALI_ROOT%\tools\BALI_AUTO_PATCH_LANE\BALI_AUTO_PATCH_RUNNER.bat"
notepad "%USERPROFILE%\Desktop\BALI_AUTO_PATCH_LANE_LAST_REPORT.txt"
exit /b %ERRORLEVEL%
