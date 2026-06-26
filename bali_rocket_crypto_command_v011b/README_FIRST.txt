BALI ROCKET CRYPTO COMMAND V010 - OVERNIGHT WATCH
==================================================

Goal:
One click starts a Bali-themed command dashboard that can collect public crypto market data overnight, show learning/research/growth activity, produce a morning report, and expose a phone LAN view on your private Wi-Fi.

Safety:
- Public market data only.
- No API keys.
- No private exchange endpoints.
- No live-order executor.
- Live orders are locked OFF.
- Champion Council is locked at 0/3.
- Risk Police stays ARMED.

Fast local start:
1. Unzip this folder.
2. Double-click ROCKET_CRYPTO_COMMAND_START.bat
3. Dashboard opens at http://127.0.0.1:9061
4. Leave it running overnight.
5. Tomorrow press Reports -> Generate Morning Report.
6. Paste the morning report back into ChatGPT to continue the build.

Phone view on private LAN:
1. Use ROCKET_CRYPTO_COMMAND_START_PHONE_LAN_EXPERIMENTAL.bat
2. Keep the PC and phone on the same private Wi-Fi.
3. The command window prints phone URLs like http://192.168.x.x:9061/phone
4. Open that URL on your phone.
5. Do not expose this to the public internet.

What gets logged overnight:
- shared_data/market_ticks.jsonl
- shared_data/market_ticks.csv
- shared_data/feed_proof_ledger.jsonl
- shared_data/learning_cycles.jsonl
- shared_data/research_ledger.jsonl
- shared_data/reports/*.txt
- shared_data/updates/suggested_upgrades.json

Update Dock:
- Drop future safe update ZIPs into UPDATE_INBOX.
- The dashboard scans manifests, checks version, blocks protected paths, backs up overwritten files, applies one update at a time, and can rollback overwritten files.
- A safe demo V011 update is included in UPDATE_INBOX to prove the scan/apply path.

Protected by default:
.env, .venv, env/venv, secrets, tokens, passwords, API keys, live-order settings, champion approvals, proof ledgers, paper logs, growth history, learner state, graveyard data, backtest results, and most shared_data.

Tomorrow's likely next build:
V011-V015 Candle Harvester + Market Regime Proof Board + Paper Shadow Signal Simulator.

V011C HANDOVER LEDGER NOTE
--------------------------
This package includes handover documents in /docs:
- MASTER_LEDGER_HANDOVER_V011C.txt
- REQUIREMENTS_AND_RULES_CHECKLIST_V011C.txt
- NEXT_CHAT_HANDOVER_PROMPT_V011C.txt
Use these when starting a new chat so the build rules, patch system, Bali/Stargate plan, governor, roster, universal exhaustive mode, and safety rules are not lost.
