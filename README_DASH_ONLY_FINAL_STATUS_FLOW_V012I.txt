BALI ROCKET CRYPTO COMMAND V012I - DASH ONLY FINAL STATUS FLOW

Purpose:
- Normal updates should be done from the dashboard Updates tab only.
- The user should not need to search for report files or run BALI_FAST_STATUS_PACK manually.
- Dashboard Update + Auto Restart closes the old dashboard listener, applies the latest safe patch, runs health/cleanup/status, restarts through Bali Forever Starter, and opens one final report.
- The dashboard also includes Show / Copy Last Final Status for a paste-back report without browsing folders.

Safety unchanged:
- live orders OFF
- champion lock LOCKED
- no API keys touched
- trading logic unchanged
- app.py changed only for dashboard update bridge text/status API

Dashboard upload added:
- Updates tab includes Upload Patch ZIP + Auto Restart.
- The ZIP is saved to the real root updates folder automatically.
- The old apply button remains as a fallback for ZIPs already placed in updates.
