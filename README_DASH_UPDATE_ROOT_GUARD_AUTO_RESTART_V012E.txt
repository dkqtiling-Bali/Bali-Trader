BALI V012E - DASH UPDATE ROOT GUARD + AUTO RESTART FIX

This patch fixes the problem where the speed-lane updater can be launched from an extracted patch folder inside updates instead of the real full-build root.

What it adds:
- Wrong-folder root guard for update/status/cleanup tools.
- Extracted patch folder rescue BAT.
- Dashboard update bridge + auto restart from V011N.
- Bali themed desktop starter remains: Bali Forever Starter.

Correct root folder:
C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD

Do not run update BATs from:
...\updates\BALI_ROCKET_CRYPTO_COMMAND_..._PATCH

Safety unchanged: live orders OFF, champion lock LOCKED, no API keys touched.
