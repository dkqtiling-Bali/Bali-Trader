@echo off
setlocal
cd /d "%~dp0"
echo BALI ONEDRIVE ARENA BRIDGE SETUP V012J
echo Safety: LIVE_ORDERS_OFF ^| CHAMPION_LOCK_LOCKED ^| NO_API_KEYS ^| SIM_ONLY
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\BALI_SETUP_ONEDRIVE_ARENA_BRIDGE_V012J.ps1"
pause
