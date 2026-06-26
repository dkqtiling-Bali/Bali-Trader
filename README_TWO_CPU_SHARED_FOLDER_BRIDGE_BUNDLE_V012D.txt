BALI ROCKET CRYPTO COMMAND - V012D TWO-CPU SHARED-FOLDER BRIDGE BUNDLE

Goal: make Bali and Stargate fun to compete on separate CPUs using a safe shared-folder JSON bridge.

What it does:
- stages a shared_drop folder for JSON-only check-ins
- exports Bali SIM-only check-ins
- imports Stargate SIM-only check-ins
- rejects non-SIM, live-order, API-key, or safety-violation check-ins
- adds bridge status tooling and dashboard markers

What it does not do:
- no socket/network command bridge
- no internet fetching
- no remote code execution
- no live orders
- no API keys
- no trading logic changes

Suggested setup:
1. On Bali CPU, keep dashboard open.
2. Share a Windows folder later, or start by copying JSON manually.
3. Stargate writes SIM-only JSON check-ins into from_stargate.
4. Bali/referee imports and scores later.
