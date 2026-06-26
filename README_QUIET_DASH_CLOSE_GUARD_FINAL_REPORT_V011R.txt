BALI ROCKET CRYPTO COMMAND - V011R QUIET DASH CLOSE GUARD FINAL REPORT

Purpose
- Fix the V011Q close-dashboard false pass where port 9061 could show STILL_ACTIVE because ESTABLISHED browser connections were counted.
- Close only the actual LISTENING dashboard server process before update/restart.
- Treat browser/client ESTABLISHED rows as OK, not as an old dashboard still running.
- Keep the one-final-report flow unless an error happens.

How to apply
1. Put this ZIP in the root updates folder.
2. Open dashboard Updates tab.
3. Click Dashboard Update + Auto Restart.

Expected final report
- LISTENER_STATUS_AFTER_CLOSE=CLEAR or LISTENER_STATUS=CLEAR
- RESULT: DASH UPDATE FINAL PASS

Safety
- Live orders OFF
- Champion lock LOCKED
- No API keys touched
- Trading logic unchanged
