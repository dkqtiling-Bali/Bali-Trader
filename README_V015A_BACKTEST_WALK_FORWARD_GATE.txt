Bali V015A Backtest + Walk-Forward Gate

This patch adds the first proof gate after V014C.

What it adds:
- Backtest Gate dashboard tab
- API: /api/backtest/run
- local replay of collected public candle rows only
- in-sample vs walk-forward split
- simulated fees and slippage
- summary ledger and CSV in shared_data/backtests
- ChatGPT report section for backtest/walk-forward records
- Doctor check for the backtest gate

What it does NOT add:
- no live orders
- no API keys
- no private exchange endpoints
- no champion unlock
- no profit claim

Champion claims remain blocked. V015A only records evidence for review.
