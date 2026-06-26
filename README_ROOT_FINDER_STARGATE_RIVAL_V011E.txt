BALI ROCKET CRYPTO COMMAND V011E - ROOT FINDER + STARGATE RIVAL PATCH

Why this patch exists:
Your V011D report proved Python 3.10 exists and is usable, but the launcher was sitting in the parent folder and compiling app.py from the wrong place. That is why it said:
[Errno 2] No such file or directory: 'app.py'

What V011E changes:
- Finds the real app.py before compiling or running.
- Works when launched from the full build parent folder OR from the bali_rocket_crypto_command_v011b app folder.
- Keeps skipping Python 3.13 because it caused crash code -1073741521.
- Prefers Python 3.10, then 3.11, then 3.12.
- Adds a startup mission marker that Bali Rocket is the Stargate-rival competitor build.
- Keeps live orders OFF, champion lock LOCKED, and no API keys touched.

How to install:
1. Extract this ZIP into the folder you are currently launching from:
   C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD
   Choose Replace.

2. Run:
   ROCKET_CRYPTO_COMMAND_START.bat

Expected good report lines:
- App folder: ...\bali_rocket_crypto_command_v011b
- Python selected: ...\Python310\python.exe
- Syntax check: PASS
- Dashboard: http://127.0.0.1:9061

If it still fails, run BALI_PYTHON_DOCTOR.bat and paste back the report.
