@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
if not exist logs mkdir logs
set "REPORT=logs\BALI_PYTHON_DOCTOR_REPORT.txt"
(
  echo BALI PYTHON DOCTOR REPORT
  echo Generated: %DATE% %TIME%
  echo Folder: %CD%
  echo.
  echo === PATH CHECKS ===
  where py
  where python
  where python3
  echo.
  echo === VERSION CHECKS ===
  py -3 --version
  python --version
  python3 --version
  echo.
  echo === APP SYNTAX CHECK ===
  py -3 -m py_compile app.py
  python -m py_compile app.py
  echo.
  echo If this report shows errors, paste it back into ChatGPT.
) > "%REPORT%" 2>&1
start notepad "%REPORT%"
exit /b 0
