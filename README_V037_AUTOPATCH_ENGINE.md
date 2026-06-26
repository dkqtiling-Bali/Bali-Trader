# V037 Forever Autopatch Engine

Purpose: replace the V031/V036 launcher behavior with a single self-reporting autopatch engine.

This is NO PYTHON and does not use Update Dock.

The real start point remains:
C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\BALI_THEMED_FOREVER_STARTER.bat

Every launch writes:
- BALI_AUTOPATCH_STATUS_LATEST.txt
- BALI_AUTOPATCH_STATUS_LATEST.md
- BALI_AUTOPATCH_STATUS_LATEST.json
- BALI_V037_PRELAUNCH_PROOF.txt
- BALI_V037_AUTOPATCH_RUN_REPORT.txt

This fixes the silent launch problem. Even if no patch is waiting, the report says that clearly.

Future patches must be dropped into:
C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\updates

A valid patch ZIP must contain:
- BALI_AUTO_PATCH_MANIFEST.txt
- AUTO_PATCH_INSTALL.bat

Safety:
- Live orders stay OFF
- Champion lock stays LOCKED
- No API keys
- No private exchange endpoints
