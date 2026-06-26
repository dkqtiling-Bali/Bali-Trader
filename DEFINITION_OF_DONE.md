# DEFINITION OF DONE

A Bali patch is done only when all of this is true:

- mission alignment is stated
- safety locks are preserved
- no live trading is enabled
- no API keys are added
- champion remains locked
- trading logic is unchanged unless explicitly approved with evidence
- report is generated
- ledger is updated
- next patch recommendation is updated
- project still launches
- Git status is reviewed
- safe commit/push is completed or deliberately deferred

## Patch classes

Allowed by default:

- `SAFE_DOCS_ONLY`
- `SAFE_TOOLING_ONLY`
- `REPORTING_ONLY`
- `PROOF_ENGINE_ONLY`
- `SIM_ONLY_TESTING`

Blocked by default:

- `LIVE_TRADING`
- `API_KEYS`
- `CHAMPION_UNLOCK`
- `PROFIT_CLAIM_WITHOUT_PROOF`
- `TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE`
