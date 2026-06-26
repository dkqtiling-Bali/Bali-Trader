# PATCH APPROVAL RULES

## Default decision order

1. Does it preserve safety locks?
2. Does it move Bali toward the mission?
3. Does it improve proof, testing, reporting, strategy discovery, automation, or maintainability?
4. Can it be made one-click?
5. Is it small enough to test safely?
6. Does it update the ledger and next patch recommendation?

## Auto-approved categories for recommendation

Bali OS may recommend these as safe next patches:

- documentation improvements
- reporting improvements
- project map improvements
- evidence indexing
- safety visibility
- duplicate detection
- archive recommendations without deletion
- safe Git backup tooling
- sim-only test automation

## Blocked categories

Bali OS must block:

- live trading enablement
- API key storage
- private exchange endpoints
- champion unlock
- strategy logic changes without evidence
- profitability claims without proof
- destructive cleanup without backup and human approval
