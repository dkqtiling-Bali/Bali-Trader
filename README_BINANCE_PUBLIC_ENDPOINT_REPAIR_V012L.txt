BALI V012L - BINANCE PUBLIC ENDPOINT REPAIR

Purpose:
- Keep the V012K real-live-only safety gate intact.
- Repair the public Binance ticker request that was returning HTTP 400.
- Do not restore fake/offline/demo fallback scoring.

What changed:
1. Version changed to V012L_BINANCE_PUBLIC_ENDPOINT_REPAIR.
2. Multi-symbol Binance request now uses compact JSON:
   ["BTCUSDT","ETHUSDT"]
   instead of JSON with spaces.
3. If multi-symbol request fails, Bali tries official one-symbol public requests:
   /api/v3/ticker/24hr?symbol=BTCUSDT
4. If all real public requests fail, Bali remains blocked:
   FAIL_NO_RECENT_REAL_LIVE_DATA
   SCORING_BLOCKED_NO_REAL_LIVE_DATA

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
Good safety block:
  FAIL_NO_RECENT_REAL_LIVE_DATA
  SCORING_BLOCKED_NO_REAL_LIVE_DATA
