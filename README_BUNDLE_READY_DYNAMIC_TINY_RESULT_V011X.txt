BALI ROCKET CRYPTO COMMAND - V011X BUNDLE-READY + DYNAMIC TINY RESULT

Purpose:
- Bundle the small autopilot/reporting polish fixes into one patch.
- Keep autopilot local-only and manifest-only.
- Fix future tiny result headers so the title follows the installed patch version.
- Add a BUNDLE=READY marker for safe future bundled patches.

Expected tiny result for future patches after this one:
VERSION=<installed version>
HEALTH=PASS
CLOSE=PASS
RESTART=PASS
AUTOPILOT=LOCAL_ONLY
WATCHER=PASS
BUNDLE=READY
RESULT=PASS

Safety unchanged: live orders OFF, champion lock LOCKED, no API keys touched, trading logic unchanged.
