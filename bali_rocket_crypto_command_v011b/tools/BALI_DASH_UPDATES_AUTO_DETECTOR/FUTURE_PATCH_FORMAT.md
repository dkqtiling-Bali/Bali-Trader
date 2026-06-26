# Future patch ZIP format for V026

A patch ZIP should contain one of these autorun files, preferably at the ZIP root:

- `BALI_PATCH_AUTORUN_NO_PYTHON.bat` preferred
- `BALI_PATCH_AUTORUN.bat`

Fallback names accepted:
- `BALI_ONE_CLICK*.bat`
- `BALI_INSTALL*.bat`
- `FIX_*.bat`
- `AUTO_INSTALL*.bat`

The autorun file must:

- use no Python unless explicitly intended
- write a report to `shared_data\reports`
- write a marker to `tools`
- preserve `LIVE_ORDERS_OFF`, `CHAMPION_LOCK_LOCKED`, and `NO_API_KEYS`
- exit with code 0 on success

If no autorun file is found, V026 quarantines the ZIP instead of failing silently.
