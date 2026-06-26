# Bali Rocket Forever Auto Recovery Setup v2

This setup pack creates one safe startup path for Bali Rocket Crypto Command.

## v2 fix

- Fixes the PowerShell `Sort-Object` parser error from v1.
- Makes `RUN_BALI_FOREVER_SETUP.cmd` fail visibly if PowerShell fails.
- Can be launched from the extracted setup folder and will try to auto-locate the Bali project under Desktop, Documents, and Downloads.
- Also supports drag-and-drop: drag the Bali project folder onto `RUN_BALI_FOREVER_SETUP.cmd`.

## What it does

- Scans startup-like `.cmd`, `.bat`, and `.ps1` files read-only.
- Scores candidates and prefers a safe original Forever starter if found.
- Creates one canonical launcher: `START_BALI_ROCKET_SAFE.cmd`.
- Creates one desktop shortcut: `Bali Rocket Forever Safe`.
- Creates a Forever-themed local icon.
- Writes audit files under `_BALI_FOREVER_RECOVERY`.
- Writes `README_STARTUP.md` in the project root.

## What it does not do

- It does not enable live trading.
- It does not add API keys.
- It does not call private endpoints.
- It does not unlock Champion.
- It does not patch old launchers.
- It does not trust old Update Dock ZIP validation as proof.

## How to use

1. Extract this setup pack.
2. Double-click `RUN_BALI_FOREVER_SETUP.cmd`.
3. If auto-locate cannot find the Bali project, drag the Bali project folder onto `RUN_BALI_FOREVER_SETUP.cmd`.
4. After setup, use only the desktop shortcut named `Bali Rocket Forever Safe`.
5. If the shortcut says no safe target was selected, open `_BALI_FOREVER_RECOVERY\audit` and review the audit report.

## Safety baseline

- Live orders: OFF
- Champion lock: LOCKED
- Champion claim allowed: False
- Backtest/walk-forward evidence: not proven yet
