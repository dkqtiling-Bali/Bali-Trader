BALI V012I - QUIET DASH UPDATE + FINAL REPORT ONLY

Purpose:
- Close any previous dashboard instance on port 9061 before patching/restarting.
- Stop opening the startup report before launch.
- Keep intermediate reports in logs.
- Open one final dashboard-update report at the end, or open immediately if an error happens.

Preferred flow after install:
1. Drop the next patch ZIP into the root updates folder.
2. Launch with Bali Forever Starter.
3. Dashboard > Updates > Dashboard Update + Auto Restart.
4. The old dashboard closes, the patch applies, fast health runs, cleanup/status runs, and the dashboard restarts.
5. Only one final report opens unless an error happens earlier.

Safety unchanged: live orders OFF, champion lock LOCKED, no API keys touched, no trading logic changed.
