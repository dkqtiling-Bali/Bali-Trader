# Bali OS V6A Control Dashboard Guide

## What V6A fixes

V6A makes the dashboard easier to trust:

- Buttons open visible console windows.
- Console windows stay open after each action.
- Each action writes a log to `DASHBOARD_LOGS`.
- The dashboard can open the latest handover, status, recommendation, project map, evidence index, session report, and log.
- Terminal Master Control remains available as a fallback.

## Recommended workflow

1. Open `BALI_START_HERE.bat`.
2. Choose `Open Control Dashboard V6A`.
3. Click `START DAY / AUTO SESSION`.
4. Wait for the console window to show PASS or an error.
5. Click `OPEN RECOMMENDATION`.
6. Click `END DAY / GIT SAFE SAVE` when ready.
7. Click `OPEN LATEST LOG` if anything seems unclear.

## Safety

This is a safe tooling-only patch. It must not enable live trading, add API keys, unlock champion mode, or change trading logic.
