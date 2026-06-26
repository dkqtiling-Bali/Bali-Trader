BALI V012M - LIVE GATE ACCEPT OK STATUS REPAIR

Purpose:
- Keep the V012K/V012L real-live-only safety gate intact.
- Fix the gate-state bug where Binance returned OK_MULTI_SYMBOLS_6 but Bali still marked FAIL_NO_RECENT_REAL_LIVE_DATA.
- Hide old offline_demo rows from the dashboard Latest Ticks table so they are not mistaken for verified live ticks.

What changed:
1. Version changed to V012M_LIVE_GATE_ACCEPT_OK_STATUS_REPAIR.
2. Real-live verifier now accepts Binance statuses that start with OK:
   OK_MULTI_SYMBOLS_6
   OK_SINGLE_SYMBOL_REPAIR_6_OF_6
3. It still rejects:
   offline_demo
   LIVE_DATA_FAIL
   NO_REAL_LIVE_DATA
   synthetic
   mock
   any feed status containing OFFLINE, DEMO, FAKE, or LIVE_DATA_FAIL.
4. Latest Ticks now displays verified live public tick rows only.
   Old offline_demo rows remain in historical files for audit but are ignored by the dashboard live table.

Safety:
- No live orders.
- No API keys.
- No broker/exchange private endpoints.
- No fake data scoring.
- No remote commands.

Install:
Use Bali dashboard > Update Dock > Upload Patch ZIP + Auto Restart.

After install:
Click Fetch Market Pulse and check Gate.
Good pass:
  PASS_RECENT_REAL_LIVE_DATA
  source https://data-api.binance.vision or https://api.binance.com
  status OK_MULTI_SYMBOLS_* or OK_SINGLE_SYMBOL_REPAIR_*

If Binance fails:
  FAIL_NO_RECENT_REAL_LIVE_DATA
  SCORING_BLOCKED_NO_REAL_LIVE_DATA
That is still a good safety block.
