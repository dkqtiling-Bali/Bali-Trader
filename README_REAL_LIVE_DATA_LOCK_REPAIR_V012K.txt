BALI ROCKET CRYPTO COMMAND V012K - REAL LIVE DATA LOCK REPAIR

Purpose:
- Stops Bali from using offline_demo/fake fallback data for scoring, learning, research scoring, or proof ledgers.
- If Binance public data fails, Bali writes only a live_data_guard warning ledger and blocks all scoring/learning rows.
- Adds 10-minute stale-live-data warning state for the dashboard.
- Keeps live orders OFF, champion lock LOCKED, no API keys, no broker execution.

Normal install:
1. Open Bali dashboard.
2. Go to Updates.
3. Use Upload Patch ZIP + Auto Restart with this ZIP.
   Alternative: copy this ZIP into the Bali root updates folder and leave autopilot armed.
4. After restart, the dashboard version should show V012K_REAL_LIVE_DATA_LOCK_REPAIR.
5. Open Feed/Watch tabs and verify Real Live Data Gate:
   PASS_RECENT_REAL_LIVE_DATA = OK
   FAIL_NO_RECENT_REAL_LIVE_DATA = scoring blocked correctly

Expected behavior after patch:
- If public exchange data is live: market_ticks/feed_proof/learning/research ledgers continue.
- If public exchange data fails: market_ticks/feed_proof/learning/research ledgers do NOT grow from fake data.
- The live_data_guard ledger records the failure and stale time.
