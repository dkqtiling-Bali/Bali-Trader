# BALI OS WORKFLOW

## Daily workflow

```text
Open VS Code
Run BALI_MASTER_CONTROL.bat
Analyse Project
AI recommends the highest-value next task
Approve or reject
AI generates the patch
Test
Commit
Push to GitHub
```

## Main launcher

Use:

```text
BALI_MASTER_CONTROL.bat
```

## Recommended normal run

1. Choose `Full Auto Analyse + Handover`.
2. Review the first-page dashboard.
3. If safety is not PASS, fix safety visibility first.
4. If Git is DIRTY, run `Git Safe Save / Backup`.
5. Only then build the next safe patch.

## No more manual searching rule

If a task requires repeatedly finding files, opening folders, copying reports, or pasting long handovers, Bali OS should automate it.

Every new patch should ask:

```text
Can this be made one-click?
```

If yes, build it that way.

## Bali OS V5 Automated Experience

Default session workflow:
1. Open `BALI_START_HERE.bat`.
2. Choose `1. Start Automated Session`.
3. Bali OS creates safety scan, status dashboard, recommendation, project map, evidence index, run registry, session report, and AI handover.
4. Review the recommendation.
5. Build only approved safe/proof-first patches.
6. Test.
7. Choose `8. Git Safe Save / Backup V5`.

Automation rule:
No manual folder hunting, cut-and-paste, or report searching where Bali OS can generate, open, copy, or index the file automatically.
