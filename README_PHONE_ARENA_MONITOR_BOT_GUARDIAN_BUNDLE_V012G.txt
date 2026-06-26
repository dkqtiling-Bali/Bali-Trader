BALI V012G - RAW LIVE DATA ONLY GOVERNOR GATE BUNDLE

This patch promotes raw live data to a hard Governor rule for the arena.

Meaning:
- Bali vs Stargate scores must come from raw live market data captured by each bot.
- Synthetic, mock, seeded, generated, demo-only, or ranked replay data is rejected for scoring.
- Scores remain SIM/PAPER only.
- Live orders stay OFF.
- Champion lock stays LOCKED.
- API keys remain absent.

Required check-in fields for scoring:
- data_origin=RAW_LIVE_DATA
- source_exchange
- source_symbol
- market_timestamp_utc
- captured_at_utc
- raw_ticks_count >= 1
- orders_live=false
- api_keys_present=false
- safety_violations=0
