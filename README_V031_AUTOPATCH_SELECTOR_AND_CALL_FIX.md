# V031 AutoPatch Selector and Call Fix

Purpose: repair the real Forever starter autopatch lane after V030 proved the preflight runs but selected an old V013 patch and failed on nested quote execution.

## Fixes

- Uses the real Forever starter path as source of truth.
- Applies only ZIPs containing both:
  - `BALI_AUTO_PATCH_MANIFEST.txt`
  - `AUTO_PATCH_INSTALL.bat`
- Moves old/legacy ZIPs without the V031 manifest to `updates\LEGACY_SKIPPED`.
- Moves bad ZIPs to `updates\QUARANTINE`.
- Moves successful ZIPs to `updates\APPLIED`.
- Calls installers safely with:
  - `call "%PATCH_INSTALLER%" "%APP%" "%BASE%" "%REPORTS%"`
- Writes prelaunch proof before Bali starts.

## Safety

Live orders stay OFF. No API keys are added. Champion lock remains locked. No private exchange endpoints are used.
