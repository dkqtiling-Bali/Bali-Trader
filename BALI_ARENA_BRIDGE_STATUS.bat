@echo off
setlocal
set ROOT=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\BALI_ARENA_BRIDGE_STATUS_V012J.ps1" -RootPath "%ROOT%"
if exist "%ROOT%logs\BALI_ARENA_BRIDGE_STATUS_V012J.txt" start notepad "%ROOT%logs\BALI_ARENA_BRIDGE_STATUS_V012J.txt"
endlocal
