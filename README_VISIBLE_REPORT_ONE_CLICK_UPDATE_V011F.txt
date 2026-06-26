BALI ROCKET CRYPTO COMMAND V011F
VISIBLE REPORT + ONE-CLICK UPDATE BOOTSTRAP

Purpose
- Fixes the missing end-report problem by showing the startup report BEFORE the dashboard begins.
- Keeps the V011E app-root finder so the launcher can run from the full-build parent folder or the inner app folder.
- Keeps the good-Python shield: Python 3.13 is skipped; Python 3.10, 3.11, and 3.12 are accepted.
- Adds the first safe one-click updater for future Bali Rocket patches.

Install
1. Copy all files in this patch into the full-build parent folder:
   C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD
2. Choose Replace when Windows asks.
3. Run ROCKET_CRYPTO_COMMAND_START.bat.

What should happen
- A report appears in the command window.
- Notepad opens with BALI_VISIBLE_STARTUP_REPORT_V011F.txt.
- Then the dashboard opens at http://127.0.0.1:9061.

One-click updates
- This patch installs BALI_ONE_CLICK_UPDATE.bat.
- Future patch zips must include BALI_PATCH_MANIFEST.txt.
- Put a future patch zip in the updates folder, Downloads, Desktop, or the Bali root folder.
- Double-click BALI_ONE_CLICK_UPDATE.bat.
- It backs up launcher/update files first, extracts the patch, applies it, and opens a report.

Safety
- Live orders remain OFF.
- Champion lock remains LOCKED.
- API keys are not touched.
- This patch does not add trading credentials or unlock live trading.

Mission marker
- STARGATE RIVAL MODE remains visible in reports and ledgers.
