Bali V014B Candle + Universe Report Accuracy Repair

This is a stabilizer patch after V014A.

It fixes confusing reporting only:
- Candle Harvester now reports last_new_rows separately from total candle rows.
- A harvest with 0 new rows no longer looks like the candle system has 0 rows.
- Universe Scanner report now shows the top of the latest scan batch sorted by universe_score.
- The headline top symbol now matches the visible latest-ranks table.
- Doctor and ChatGPT reports use the same corrected summaries.

Safety unchanged:
- live orders OFF
- no API keys
- no private exchange endpoints
- champion lock LOCKED
- no trade signal/champion claim from universe ranking
