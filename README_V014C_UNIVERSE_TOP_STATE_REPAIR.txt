Bali V014C Universe Top State Repair

This is a tiny stabilizer patch after V014B.

It fixes one report/dashboard consistency issue:
- V014B correctly sorted the latest universe batch by score.
- But the dashboard/report was still displaying the tail of that sorted batch.
- That made the headline top symbol differ from the first visible row.
- V014C displays the first/top rows of the sorted latest batch.

Safety unchanged:
- live orders OFF
- no API keys
- no private exchange endpoints
- champion lock LOCKED
- no trade signal/champion claim from universe ranking
- candles and universe ranking remain public-data evidence only

After install, generate a ChatGPT Status Report and confirm:
- Universe Scanner top=... matches the first row under LATEST UNIVERSE RANKS.
