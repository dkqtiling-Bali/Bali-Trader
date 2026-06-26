# Bali OS V6B URL / Phone Control Guide

## Purpose

Bali OS V6B adds a browser-style control dashboard for easier operation.

It is designed for safe project control only:

- Start Day / automated session
- Safety scan
- Recommendation generation
- New chat handover
- View latest reports
- Git safe save

It does not enable live trading, API keys, champion unlock, or arbitrary command execution.

## Start from the PC

Open:

```bat
C:\Bali\Bali-Trader\BALI_START_HERE.bat
```

Choose option 1.

The dashboard opens at:

```text
http://localhost:8787
```

Keep the server window open while using the dashboard.

## Phone access

When the dashboard starts, it prints one or more Phone/LAN URLs, for example:

```text
http://192.168.1.25:8787
```

On your phone:

1. Connect to the same Wi-Fi/LAN as the PC.
2. Open the Phone/LAN URL in a browser.
3. If Windows Firewall asks, allow private network access.

## Safety limits

The phone dashboard only exposes approved safe Bali OS actions. It does not provide a command prompt or arbitrary script runner.

Blocked forever by policy:

- LIVE_TRADING
- API_KEYS
- CHAMPION_UNLOCK
- PROFITABILITY_CLAIM_WITHOUT_EVIDENCE
- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE

## Troubleshooting

If the phone cannot connect:

- Confirm the PC and phone are on the same Wi-Fi.
- Confirm the dashboard server window is still open.
- Try http://localhost:8787 on the PC first.
- Allow Windows Firewall private network access if prompted.
- Some routers block device-to-device traffic; use the PC dashboard in that case.
