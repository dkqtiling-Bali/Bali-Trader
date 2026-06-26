STARGATE NODE JOIN KIT V012J

Role:
- Stargate CPU is a competitor node.
- Bali CPU is Governor Hub and referee.
- The bridge is shared-folder JSON only.
- Phone monitor is read-only.

Allowed:
- Write heartbeat JSON files.
- Write SIM-only check-in JSON files using RAW_LIVE_DATA provenance.
- Read shared round rules.

Blocked:
- Remote command execution.
- Live orders.
- API keys.
- Public internet exposure.
- Synthetic/mock/demo data for ranked scoring.

Setup idea:
1. Copy this join kit to the Stargate CPU.
2. Point STARGATE_WRITE_HEARTBEAT_V012J.bat at the shared_drop folder on Bali or a Windows shared folder.
3. Make Stargate write check-ins to shared_drop/from_stargate.
4. Bali Governor Hub scores rounds from raw-live SIM JSON only.
