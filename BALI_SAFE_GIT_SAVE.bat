@echo off
setlocal EnableExtensions
title BALI SAFE GIT SAVE V4E
color 0B
cd /d "C:\Bali\Bali-Trader"
echo Running Bali Safe Git Save V4E...
if not exist "C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1" (
  echo Missing C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_SAFE_GIT_SAVE_V4E.ps1" -Base "C:\Bali\Bali-Trader"
echo.
pause
