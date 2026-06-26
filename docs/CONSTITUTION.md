# BALI TRADER CONSTITUTION

## Mission

Build Bali Trader into a safe, proof-driven crypto strategy research machine that competes against Stargate and searches for evidence-backed strategies that may help generate profit in the market.

Bali does not chase guesses. Bali builds proof.

## Permanent safety rules

Always preserve:

- `LIVE_ORDERS_OFF`
- `NO_API_KEYS`
- `PUBLIC_DATA_ONLY`
- `PAPER/SIM FIRST`
- `CHAMPION_LOCKED`

Never:

- enable live trading
- add API keys
- add private exchange endpoints
- unlock champion mode without proof gates
- claim profitability without evidence
- patch blindly without a report
- break launcher/startup flow
- change trading logic without evidence and approval

## Mission alignment rule

Every update, patch, report, tool, dashboard, cleanup, or strategy change must clearly move Bali Trader closer to the mission goal: safely discovering evidence-backed crypto strategies that may help generate profit in the market.

If a patch does not improve proof, safety, testing, reporting, strategy discovery, automation, or maintainability, it should not be done.

## Bali OS workflow

1. Open VS Code.
2. Run `BALI_MASTER_CONTROL.bat`.
3. Analyse project.
4. Read status dashboard.
5. Read highest-value next patch recommendation.
6. Approve or reject.
7. Generate safe patch.
8. Test.
9. Commit.
10. Push to GitHub.

## Evidence standard

A strategy is not considered promising because it looks profitable in one backtest.

A candidate must survive:

- data quality checks
- realistic fees
- realistic slippage
- in-sample test
- walk-forward test
- out-of-sample test
- stress test
- drawdown review
- sufficient trade count
- paper/simulation forward monitoring

## Project law

Bali OS is the control layer. Trading features do not come before the development platform, safety visibility, evidence registry, and reporting workflow are stable.
