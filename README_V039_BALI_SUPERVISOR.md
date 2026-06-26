# V039 Bali Supervisor One-Click

Purpose: replace fragile starter patching with one stable external supervisor.

Use this instead of repeatedly modifying `BALI_THEMED_FOREVER_STARTER.bat`.

Behavior:
- No Python.
- No Update Dock.
- Does not enable live orders.
- Does not add API keys.
- Does not unlock Champion Council.
- Reads patch ZIPs from the outer `updates` folder.
- Applies exactly one valid patch ZIP containing:
  - `BALI_AUTO_PATCH_MANIFEST.txt`
  - `AUTO_PATCH_INSTALL.bat`
- Moves applied patches to `updates\APPLIED`.
- Moves failed/invalid patches to `updates\QUARANTINE`.
- Writes a clear supervisor report every run.
- Starts the original Bali Forever starter after the preflight.

Install:
1. Double-click `INSTALL_V039_BALI_SUPERVISOR_NOW.bat`.
2. Use the new Desktop launcher: `Bali Supervisor Mission Control.bat`.

Optional test:
1. Copy `V039_SUPERVISOR_TEST_PATCH_DROP_IN_UPDATES.zip` into the outer `updates` folder.
2. Run `Bali Supervisor Mission Control.bat`.
3. Read `shared_data\reports\BALI_SUPERVISOR_LATEST_REPORT.txt`.
