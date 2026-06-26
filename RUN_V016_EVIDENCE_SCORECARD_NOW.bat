@echo off
setlocal EnableExtensions
title Run Bali V016 Evidence Scorecard
set "ROOT=%~dp0"
echo Running Bali V016 Native Evidence Scorecard...
echo Root: %ROOT%
py -3 "%ROOT%tools\bali_v016_native_evidence_scorecard.py" --root "%ROOT%" --print
if errorlevel 1 python "%ROOT%tools\bali_v016_native_evidence_scorecard.py" --root "%ROOT%" --print
echo.
echo Reports written to: %ROOT%shared_data\reports
if exist "%ROOT%shared_data\reports\BALI_V016_EVIDENCE_SCORECARD.md" start notepad "%ROOT%shared_data\reports\BALI_V016_EVIDENCE_SCORECARD.md"
pause
