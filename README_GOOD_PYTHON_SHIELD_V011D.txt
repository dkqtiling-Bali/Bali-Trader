BALI ROCKET CRYPTO COMMAND V011D - GOOD PYTHON SHIELD PATCH

Why this patch exists:
Your startup report showed the launcher selected:
C:\Users\CB\AppData\Local\Programs\Python\Python313\python.exe
Then the app exited with code -1073741521.

That points to a bad/unstable Python 3.13 install or image/DLL problem, not a trading safety issue and not an API-key issue.

What this patch changes:
- Replaces ROCKET_CRYPTO_COMMAND_START.bat
- Replaces ROCKET_CRYPTO_COMMAND_START_PHONE_LAN_EXPERIMENTAL.bat
- Replaces BALI_PYTHON_DOCTOR.bat
- Skips Python 3.13 completely
- Prefers Python 3.10, then 3.11, then 3.12
- Cleans old __pycache__ before starting
- Writes clearer reports to logs\BALI_GOOD_PYTHON_STARTUP_REPORT_V011D.txt and logs\LAST_STARTUP_REPORT.txt

Safety:
- Live orders remain OFF
- Champion lock remains LOCKED
- No API keys are added or touched
- No .env, env, venv, tokens, passwords, ledgers, learner state, or growth data are included in this patch

How to use:
1. Extract this ZIP.
2. Copy these replacement files into your existing folder:
   C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\bali_rocket_crypto_command_v011b
3. Choose Replace when Windows asks.
4. Run ROCKET_CRYPTO_COMMAND_START.bat again.

Expected good report line:
Python selected: C:\Users\CB\AppData\Local\Programs\Python\Python310\python.exe
or Python311 / Python312.

If it says GOOD PYTHON NOT FOUND:
Install or repair Python 3.10, 3.11, or 3.12. Do not use Python 3.13 for this Bali build.
