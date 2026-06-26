# V021 Golden One-Click Patch Standard

Purpose: stop repeated Bali patch install failures by standardising the update path.

## Rule
Use the no-Python one-click runner for all functional patches until the Update Dock validator is repaired and proven.

## Why
The working proof is V019/V020:
- Python used: NO
- Update Dock used: NO
- One-click runner: PASS
- V016 scorecard marker: PRESENT
- Evidence Scorecard: BLOCK
- Champion nomination: BLOCKED

The failing path is the Update Dock ZIP validator/apply flow:
- Bali remains V015A after restart
- Watcher reports PASS
- Bundle reports READY
- Patch ZIP can be visible but not accepted as next waiting patch

## Safety invariant
Every patch must preserve:
- Live orders OFF
- Champion lock LOCKED
- No API keys
- No private exchange endpoints
- Raw live data only for scoring
- Champion claim blocked unless evidence scorecard says pass and human approval rules pass

## Golden path for future patches
1. Build the feature as a no-Python payload when possible.
2. Include a root-level double-click BAT installer.
3. Write a Desktop report first.
4. Write marker/report files into Bali shared_data/reports and tools.
5. Do not depend on dashboard upload or Update Dock validation.
6. Keep the dashboard old footer label separate from capability status.
7. After the direct install passes, optionally create an Update Dock test ZIP.
8. If Update Dock fails, do not rework the feature; fix/update the Update Dock validator separately.

## Naming convention
Functional patch package:
V###_<FEATURE>_ONE_CLICK_NO_PYTHON.zip

Direct installer:
BALI_ONE_CLICK_INSTALL_<FEATURE>_NOW.bat

Desktop report:
BALI_V###_<FEATURE>_INSTALL_REPORT.txt

Capability marker:
tools\V###_<FEATURE>_MARKER.txt

Capability reports:
shared_data\reports\BALI_CAPABILITY_STATUS_V###.txt
shared_data\reports\BALI_CAPABILITY_STATUS_V###.md
shared_data\reports\BALI_CAPABILITY_STATUS_V###.json

## Do not do
- Do not rely on Python for install unless the patch specifically requires Python and first verifies Python availability.
- Do not modify live trading code.
- Do not add API key handling.
- Do not unlock champion approval.
- Do not overwrite unrelated files without a backup.
- Do not treat dashboard footer version as the source of truth.

## Source of truth going forward
Use capability markers and reports, not only the app footer:
- tools\*_MARKER.txt
- shared_data\reports\BALI_CAPABILITY_STATUS_*.txt
- shared_data\reports\BALI_*_INSTALL_REPORT.txt
