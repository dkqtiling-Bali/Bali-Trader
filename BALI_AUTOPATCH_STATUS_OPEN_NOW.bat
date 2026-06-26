@echo off
setlocal EnableExtensions
set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "REPORTS=%APP%\shared_data\reports"
set "STATUS=%REPORTS%\BALI_AUTOPATCH_STATUS_LATEST.txt"
if exist "%STATUS%" (
  start "" notepad "%STATUS%"
) else (
  echo BALI AUTOPATCH STATUS NOT FOUND > "%BASE%\BALI_AUTOPATCH_STATUS_NOT_FOUND.txt"
  echo Expected: %STATUS% >> "%BASE%\BALI_AUTOPATCH_STATUS_NOT_FOUND.txt"
  start "" notepad "%BASE%\BALI_AUTOPATCH_STATUS_NOT_FOUND.txt"
)
exit /b 0
