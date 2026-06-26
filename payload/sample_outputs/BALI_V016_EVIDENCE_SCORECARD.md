# Bali V016 Native Evidence Scorecard

Generated UTC: 2026-06-25T10:40:47+00:00
Version: V016_NATIVE_EVIDENCE_SCORECARD_PANEL
Source version: V015A_BACKTEST_WALK_FORWARD_GATE
Source report: /mnt/data/v016_native_evidence_scorecard_panel/sample_test_root/shared_data/reports/BALI_CHATGPT_STATUS_REPORT_SAMPLE.txt

## Result
- Overall status: **BLOCK**
- Gate: **CHAMPION_NOMINATION_BLOCKED**
- Champion nomination allowed: **False**
- Champion claim allowed: **False**
- Live orders allowed: **False**
- Council status: **LOCKED_0_OF_3_UNCHANGED**
- Reason: Repeated evidence is not strong enough to nominate a champion.

## Summary
- paper_shadow_rows: 71
- paper_closed_trade_rows_visible: 0
- candle_rows_total: 666
- universe_ledger_rows: 2520
- backtest_walk_forward_rows: 44
- positive_walk_forward_rows_visible: 0
- latest_walk_forward_avg_visible: -0.3017
- backtest_gate: WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN
- real_live_data_gate: PASS_RECENT_REAL_LIVE_DATA

## Blockers
- paper_closed_trade_rows: observed=0 required=10 | Visible status report currently shows stand-aside rows, not enough closed simulated trades.
- distinct_backtest_ids_visible: observed=5 required=12
- positive_walk_forward_rows_visible: observed=0 required=8
- backtest_gate_not_edge_not_proven: observed=WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN required=not EDGE_NOT_PROVEN
- latest_walk_forward_avg_positive: observed=-0.3017 required=>0

## Safety Checks
- PASS live_orders_off: observed=OFF required=OFF
- PASS api_keys_none: observed=NONE / private exchange endpoints not used required=NONE
- PASS champion_lock_locked: observed=LOCKED / approved 0/3 required=LOCKED
- PASS risk_police_armed: observed=ARMED required=ARMED
- PASS no_danger_flags: observed=[] required=[]

## Evidence Checks
- PASS real_live_data_gate: observed=PASS_RECENT_REAL_LIVE_DATA required=PASS_RECENT_REAL_LIVE_DATA
- PASS fresh_live_data: observed=0 required=<=60 seconds
- PASS offline_demo_rows_ignored: observed=0 required=0
- PASS paper_shadow_rows: observed=71 required=50
- BLOCK paper_closed_trade_rows: observed=0 required=10 | Visible status report currently shows stand-aside rows, not enough closed simulated trades.
- PASS candle_rows: observed=666 required=100
- PASS universe_ledger_rows: observed=2520 required=200
- PASS backtest_walk_forward_rows: observed=44 required=12
- BLOCK distinct_backtest_ids_visible: observed=5 required=12
- BLOCK positive_walk_forward_rows_visible: observed=0 required=8
- BLOCK backtest_gate_not_edge_not_proven: observed=WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN required=not EDGE_NOT_PROVEN
- BLOCK latest_walk_forward_avg_positive: observed=-0.3017 required=>0
- PASS champion_claim_already_false_until_gate_pass: observed=False required=False until V016 passes

## Safety Contract
- Live orders remain OFF.
- API keys remain NONE.
- Champion Council remains locked at 0/3 unless a separate human approval process exists.
- This scorecard uses local reports/ledgers only and does not call private exchange endpoints.
- No fake/offline/demo rows are allowed as real evidence.
