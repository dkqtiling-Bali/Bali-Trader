# V016_NATIVE_EVIDENCE_SCORECARD_PANEL

Additive native Bali Evidence Scorecard panel/report kit.

This is the safer next step after V015A because the local updater is healthy but did not accept external ZIP payloads as a higher-version app patch. This kit installs as a local sidecar and report generator instead of changing the launcher or whole app version.

## Safety contract

- Live orders stay OFF.
- No API keys are created or requested.
- Champion Council stays locked.
- No private exchange endpoints are used.
- Raw-live-data gate is required for scoring.
- Fake/offline/demo rows are not allowed as proof.

## Install

1. Close Bali.
2. Unzip this package.
3. Double-click `BALI_INSTALL_V016_NATIVE_SCORECARD_NOW.bat`.
4. Notepad should open `BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt`.
5. Start Bali normally.

## Run again any time

From the Bali app folder, double-click:

`RUN_V016_EVIDENCE_SCORECARD_NOW.bat`

Reports are written to:

- `shared_data/reports/BALI_V016_EVIDENCE_SCORECARD.md`
- `shared_data/reports/BALI_V016_EVIDENCE_SCORECARD.json`
- `shared_data/reports/BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt`
- `shared_data/dashboard/v016_evidence_scorecard_panel.json`

## Expected current result from latest status report

Current V015A data has enough raw collection rows for paper/backtest count thresholds, but the champion nomination must stay blocked because the visible paper rows are stand-aside records, the closed simulated trade evidence is missing, and the latest visible walk-forward averages are negative/edge-not-proven.

Expected gate: `CHAMPION_NOMINATION_BLOCKED`.
