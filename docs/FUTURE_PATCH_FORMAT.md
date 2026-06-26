# Future Patch Format

Future automatic patches must be ZIP files placed directly in:
C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD\updates

They must contain exactly these root-level files:
- BALI_AUTO_PATCH_MANIFEST.txt
- AUTO_PATCH_INSTALL.bat

AUTO_PATCH_INSTALL.bat is called as:
AUTO_PATCH_INSTALL.bat "APP" "BASE" "REPORTS"

It must return exit code 0 on success and write a RESULT=PASS... line to a report.
