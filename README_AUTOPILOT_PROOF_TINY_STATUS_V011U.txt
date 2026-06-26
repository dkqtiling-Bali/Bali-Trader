BALI ROCKET CRYPTO COMMAND - V011U AUTOPILOT PROOF + TINY STATUS

Purpose:
- Test the V011T local autopilot update system with a low-risk proof patch.
- Keep the final chat/report output tiny.
- Add an AUTOPILOT_PROOF=V011U_READY marker after restart.

Expected test:
1. Install V011T first if it is not already installed.
2. Leave the dashboard open with autopilot armed.
3. Put this V011U ZIP into the updates folder or upload it from the Updates tab.
4. Autopilot should apply it, restart the dash, and show one tiny final report.

Expected tiny report lines:
VERSION=V011U
HEALTH=PASS
RESTART=LAUNCHED
AUTOPILOT=ARMED_LOCAL_ONLY
AUTOPILOT_PROOF=V011U_READY
RESULT: PASS

Safety unchanged: live orders OFF, champion lock LOCKED, no API keys touched, trading logic unchanged.
