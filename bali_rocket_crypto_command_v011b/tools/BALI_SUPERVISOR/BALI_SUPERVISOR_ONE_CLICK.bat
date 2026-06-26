@echo off
setlocal EnableExtensions
set "BASE=C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
set "APP=%BASE%\bali_rocket_crypto_command_v011b"
set "PS1=%APP%\tools\BALI_SUPERVISOR\BALI_SUPERVISOR.ps1"
if not exist "%PS1%" (
  echo BALI_SUPERVISOR_ERROR=Missing %PS1%
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
