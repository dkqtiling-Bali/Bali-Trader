BALI ROCKET CRYPTO COMMAND V012E - SHARED FOLDER WATCHER REFEREE SCOREBOARD BUNDLE

Purpose:
- Make the Bali vs Stargate two-CPU bridge more fun while staying safe.
- Use JSON-only SIM check-ins from both machines.
- Score a round locally with the Governor/Referee.
- Write scoreboard and round-result JSON files.

Safety:
- LIVE_ORDERS=OFF
- CHAMPION_LOCK=LOCKED
- API_KEYS_TOUCHED=NO
- TRADING_LOGIC_CHANGED=NO
- NETWORK EXECUTION=OFF
- REMOTE COMMANDS=OFF

Normal game flow:
1. Bali CPU writes a SIM check-in JSON to game_arena/bridge/shared_drop/from_bali.
2. Stargate CPU writes a SIM check-in JSON to game_arena/bridge/shared_drop/from_stargate.
3. Dashboard Game Arena tab -> Score Latest SIM Round.
4. Referee writes result JSON under game_arena/bridge/shared_drop/round_results.
