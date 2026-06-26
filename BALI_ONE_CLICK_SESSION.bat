@echo off
cd /d "C:\Bali\Bali-Trader"
echo ==========================================
echo       BALI OS V5 ONE CLICK SESSION
echo ==========================================
echo This runs analysis, status, map, evidence index, handover, and clipboard copy.
echo It does not commit automatically. Use Git Safe Save after review.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Bali\Bali-Trader\tools\BALI_OS_ENGINE_V5.ps1" -Action Session -Base "C:\Bali\Bali-Trader"
pause
