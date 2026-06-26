# Future Patch Checklist

Before shipping any Bali patch:

[ ] No live orders added.
[ ] No API keys added.
[ ] No private exchange endpoints added.
[ ] Champion lock remains locked unless evidence + human approval rules pass.
[ ] Python is not required for install, unless clearly checked first.
[ ] Root-level BAT installer exists.
[ ] Desktop report is written first.
[ ] Bali root is printed in report.
[ ] Reports folder is printed in report.
[ ] Marker file is written into tools.
[ ] TXT/MD/JSON report files are written into shared_data/reports.
[ ] Result line is explicit: RESULT=PASS_... or RESULT=FAIL_...
[ ] Dashboard footer version is not treated as the only proof.
[ ] Update Dock test, if any, is optional and separate.
