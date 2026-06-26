BALI ROCKET CRYPTO COMMAND V011I - UPDATER RESCUE + HEALTH CHECK

Why this exists
- V011F found good Python and launched the dashboard, but its one-click updater could continue with a blank ZIP selection.
- The bad report line was: Selected patch zip: [blank]
- V011I repairs the picker and refuses blank/non-file ZIP paths before extraction.

What this patch includes
- Fixed BALI_ONE_CLICK_UPDATE.bat.
- New tools/BALI_ONE_CLICK_UPDATE_ENGINE_V011I.ps1.
- Health check layer from V011G, versioned forward to V011I.
- Startup reports versioned to V011I.
- Manifest selection by highest Bali patch version, not just random/latest file.

How to apply if V011F one-click is broken
Option A - easiest rescue:
1. Extract the V011I rescue kit into the Bali root folder.
2. Double-click BALI_ONE_CLICK_UPDATE_RESCUE_V011I.bat.
3. It will apply the V011I patch zip from the same folder.

Option B - manual fallback:
1. Open this V011I patch zip.
2. Copy all files and folders into the Bali root folder.
3. Choose Replace.
4. Run BALI_ROCKET_HEALTH_CHECK.bat.
5. Run ROCKET_CRYPTO_COMMAND_START.bat.

Expected results
- Update report: RESULT: UPDATE APPLIED
- Health report: RESULT: HEALTH PASS
- Startup report: BALI ROCKET V011I READY

Safety
- Live orders remain OFF.
- Champion lock remains LOCKED.
- No API keys are touched.
- app.py and trading logic are not changed.
- Python 3.13 remains blocked.

Mission marker
- STARGATE RIVAL MODE remains visible in reports.
