@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
echo BALI ONE-CLICK SYSTEM READY CHECK
if exist "%ROOT%shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt" (
  echo PASS: V016 native scorecard tiny report exists.
  type "%ROOT%shared_data\reports\BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt"
) else (
  echo BLOCK: V016 native scorecard tiny report not found.
)
if exist "%ROOT%tools\bali_v016_native_evidence_scorecard.py" (echo PASS: scorecard tool installed) else (echo BLOCK: scorecard tool missing)
if exist "%ROOT%V016_NATIVE_PATCH_MANIFEST.json" (echo PASS: manifest installed) else (echo BLOCK: manifest missing)
echo.
pause
