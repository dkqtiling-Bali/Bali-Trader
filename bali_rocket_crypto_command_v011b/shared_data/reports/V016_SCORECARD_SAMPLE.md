# V016_EVIDENCE_SCORECARD_CHAMPION_COUNCIL_GATE

Generated UTC: 2026-06-25T09:46:35+00:00
Overall status: BLOCK
Gate: CHAMPION_NOMINATION_BLOCKED
Nomination allowed: False
Champion claim allowed: False

## Checks

| Check | Status | Observed | Required | Detail |
|---|---:|---:|---:|---|
| Live orders disabled | PASS | OFF | OFF | V016 must never enable live orders. |
| No API keys | PASS | NONE / private exchange endpoints not used | NONE / no private endpoints | Public data research mode only. |
| Public data research mode | PASS | PUBLIC_DATA_RESEARCH_ONLY | PUBLIC_DATA_RESEARCH_ONLY | Blocks private exchange endpoints. |
| Champion lock remains locked | PASS | LOCKED / approved 0/3 | LOCKED | V016 permits nomination review only, not champion claim. |
| Recent real-live-data gate | PASS | PASS_RECENT_REAL_LIVE_DATA | PASS_RECENT_REAL_LIVE_DATA | Must be current real public data. |
| Raw data gate enforced | PASS | ENFORCED_PASS_REAL_LIVE_DATA_ONLY | ENFORCED_PASS_REAL_LIVE_DATA_ONLY | No offline/demo rows can score. |
| Live-data warning clean | PASS | OK | OK | Warnings block nomination. |
| Live-data freshness | PASS | 0 | <= 120 | Stale data cannot nominate champions. |
| Approved public feed source | PASS | https://data-api.binance.vision | https://data-api.binance.vision | Only Binance public data mirror is accepted here. |
| Offline/demo rows ignored | PASS | 0 | 0 | Fake/offline/demo scoring is not evidence. |
| Market tick evidence count | PASS | 2916.0 | >= 500 | Enough real ticks to prove collection health. |
| Live guard evidence count | PASS | 88.0 | >= 20 | Guard must have repeated passes. |
| Learning cycles recorded | PASS | 486.0 | >= 100 | Learning is collection-only, not edge proof. |
| Paper Shadow online | PASS | PAPER_SHADOW_ONLINE \| last_action=STAND_ASIDE_SIMULATED \| open_position=NONE | PAPER_SHADOW_ONLINE | Paper-only simulator remains safe. |
| Paper Shadow repeated rows | BLOCK | 31 | >= 50 | Need repeated paper observations before nomination. |
| Paper Shadow closed trade evidence | BLOCK | 0 | >= 10 | Stand-aside rows prove risk discipline but not trade edge. |
| Candle Harvester online | PASS | CANDLE_HARVESTER_ONLINE \| last_new_rows=12 \| total_rows=258 \| last_at=2026-06-25T09:40:33+00:00 | CANDLE_HARVESTER_ONLINE | Candle layer is allowed as evidence input. |
| Candle row count | PASS | 258 | >= 250 | Enough candles for the current V016 baseline. |
| Candle proof count | PASS | 23 | >= 20 | Proof rows must exist, not just derived rows. |
| Universe Scanner online | PASS | UNIVERSE_SCANNER_ONLINE \| latest_batch_rows=40 \| ledger_rows=920 \| top=AAVEUSDT \| top_score=60.876 | UNIVERSE_SCANNER_ONLINE | Scanner may rank candidates; it cannot nominate alone. |
| Universe scan ledger depth | PASS | 920 | >= 500 | Universe ranking needs repeated batches. |
| Universe latest batch depth | PASS | 40 | >= 25 | Latest visible batch must be broad enough. |
| Backtest/WF gate recorded | PASS | BACKTEST_WALK_FORWARD_RECORDED \| gate=WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN \| symbol=BTCUSDT \| interval=1m | BACKTEST_WALK_FORWARD_RECORDED | Gate exists and records evidence. |
| Backtest/WF repeated rows | BLOCK | 4 | >= 12 | Need repeated runs before nomination. |
| Backtest/WF positive repeated edge | BLOCK | 0 | >= 8 | Latest walk-forward averages must repeatedly be positive. |
| Backtest/WF drawdown containment | BLOCK | 4 | >= 8 rows with dd <= 2.5 | Drawdown must stay within configured limits. |
| Distinct backtest IDs | BLOCK | 4 | >= 12 | Repeated evidence cannot be one recycled run. |
| Backtest edge not proven flag cleared | BLOCK | BACKTEST_WALK_FORWARD_RECORDED \| gate=WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN \| symbol=BTCUSDT \| interval=1m | No EDGE_NOT_PROVEN flag | Existing gate must stop reporting unproven edge. |
| Risk Police armed | PASS | ARMED | ARMED | Risk Police must stay armed. |
| Champion claim remains false | PASS | False | False | V016 does not unlock champion claims. |
| Human approvals for claim | WARN | 0/3 | >= 3/3 | Even nomination eligibility is review-only; claim still requires humans. |

## Summary

```json
{
  "backtest_walk_forward_rows": 4,
  "blocking_checks": [
    "Paper Shadow repeated rows",
    "Paper Shadow closed trade evidence",
    "Backtest/WF repeated rows",
    "Backtest/WF positive repeated edge",
    "Backtest/WF drawdown containment",
    "Distinct backtest IDs",
    "Backtest edge not proven flag cleared"
  ],
  "distinct_backtest_ids_visible": 4,
  "edge_not_proven_flag_present": true,
  "paper_closed_trade_rows_visible": 0,
  "paper_shadow_rows": 31,
  "raw_data_gate": "ENFORCED_PASS_REAL_LIVE_DATA_ONLY",
  "real_live_gate": "PASS_RECENT_REAL_LIVE_DATA",
  "risk_police": "ARMED",
  "source_version": "V015A_BACKTEST_WALK_FORWARD_GATE",
  "wf_positive_rows_visible": 0
}
```
