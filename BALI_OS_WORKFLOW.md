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
