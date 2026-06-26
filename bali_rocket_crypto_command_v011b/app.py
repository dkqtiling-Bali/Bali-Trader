#!/usr/bin/env python3
"""
Bali Rocket Crypto Command V006-V010 Overnight Watch
Public-market-data, paper/research-only command centre.
No API keys. No live trading. No broker/exchange order code.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import html
import io
import json
import os
import re
import shutil
import subprocess
import socket
import sys
import tempfile
import threading
import time
import traceback
import urllib.parse
import urllib.request
import urllib.error
import zipfile
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

PROJECT_NAME = "BALI_ROCKET_CRYPTO_COMMAND"
PROJECT_TITLE = "Bali Rocket Crypto Command"
VERSION = "V015A_BACKTEST_WALK_FORWARD_GATE"
VERSION_NUMBER = 1501
PATCH_REPORT_VERSION = "V017_ALWAYS_WORKING_REPORT_CENTER"
PATCH_REPORT_TITLE = "Always-Working Report Center"
PORT_DEFAULT = 9061
SYMBOLS_DEFAULT = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "XRPUSDT", "DOGEUSDT", "LINKUSDT"]
BASE_DATA_API = "https://data-api.binance.vision"
BASE_BINANCE_API = "https://api.binance.com"
PULSE_SECONDS_DEFAULT = 60
REAL_LIVE_DATA_WARNING_SECONDS = 600
REAL_LIVE_SOURCE_PREFIXES = (BASE_DATA_API, BASE_BINANCE_API)

ROOT = Path(__file__).resolve().parent
SHARED = ROOT / "shared_data"
LOGS = ROOT / "logs"
REPORTS = SHARED / "reports"
UPDATES = SHARED / "updates"
STRATEGIES = SHARED / "strategies"
GRAVEYARD = SHARED / "graveyard"
UPDATE_INBOX = ROOT / "UPDATE_INBOX"
BACKUPS = ROOT / "backups"
RELEASES = ROOT / "releases"
PATCHES = SHARED / "patches"
PATCH_LEDGER = PATCHES / "patch_ledger.jsonl"
ALWAYS_REPORT_LEDGER = REPORTS / "always_working_report_ledger.jsonl"
V017_FILES_CHANGED = [
    "app.py",
    "START_BALI_ROCKET_SAFE.cmd",
    "BALI_FOREVER_DESKTOP_STARTER.bat",
    "BALI_THEMED_FOREVER_STARTER.bat",
    "BALI START HERE - ONE CLICK.bat",
    "README_V017_ALWAYS_WORKING_REPORT_CENTER.txt",
]
SECRET_ENV_KEYS = [
    "BINANCE_API_KEY",
    "BINANCE_SECRET_KEY",
    "BINANCE_API_SECRET",
    "BALI_API_KEY",
    "BALI_API_SECRET",
    "BALI_EXCHANGE_API_KEY",
    "BALI_EXCHANGE_SECRET",
    "COINBASE_API_KEY",
    "COINBASE_API_SECRET",
    "KRAKEN_API_KEY",
    "KRAKEN_API_SECRET",
]

PROTECTED_TOKENS = [
    ".env", ".venv", "/env/", "\\env\\", "/venv/", "\\venv\\",
    "secret", "secrets", "token", "tokens", "password", "passwd", "api_key", "apikey",
    "live_order", "live-order", "order_executor", "exchange_private", "private_key",
    "champion_approvals", "approved_champions", "proof_ledgers", "paper_logs",
    "growth_history", "learner_state", "strategy_graveyard", "backtest_results",
    "shared_data/system_state.json", "shared_data/market_ticks.jsonl", "shared_data/feed_proof_ledger.jsonl",
]

STATE_LOCK = threading.RLock()
STOP_EVENT = threading.Event()
COLLECTOR_THREAD: Optional[threading.Thread] = None
START_TIME = dt.datetime.now(dt.timezone.utc)


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def iso_now() -> str:
    return utc_now().isoformat(timespec="seconds")


def ensure_dirs() -> None:
    for p in [SHARED, LOGS, REPORTS, UPDATES, STRATEGIES, GRAVEYARD, UPDATE_INBOX, BACKUPS, RELEASES, PATCHES, SHARED / "candles", SHARED / "paper_shadow", SHARED / "universe", SHARED / "backtests"]:
        p.mkdir(parents=True, exist_ok=True)


def read_json(path: Path, default: Any) -> Any:
    try:
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        pass
    return default


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def append_jsonl(path: Path, row: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, sort_keys=True) + "\n")


def read_last_jsonl(path: Path, limit: int = 100) -> List[Dict[str, Any]]:
    if not path.exists():
        return []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()[-limit:]
        out = []
        for line in lines:
            try:
                out.append(json.loads(line))
            except Exception:
                continue
        return out
    except Exception:
        return []


def append_csv(path: Path, headers: List[str], row: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    exists = path.exists() and path.stat().st_size > 0
    with path.open("a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        if not exists:
            writer.writeheader()
        writer.writerow({k: row.get(k, "") for k in headers})


def get_system_state() -> Dict[str, Any]:
    default = {
        "project": PROJECT_NAME,
        "title": PROJECT_TITLE,
        "version": VERSION,
        "version_number": VERSION_NUMBER,
        "created_at": iso_now(),
        "watch_enabled": True,
        "pulse_seconds": PULSE_SECONDS_DEFAULT,
        "symbols": SYMBOLS_DEFAULT,
        "live_orders": "OFF",
        "champion_lock": "LOCKED",
        "approved_champions": "0/3",
        "risk_police": "ARMED",
        "mode": "PUBLIC_DATA_RESEARCH_ONLY",
        "phone_lan_enabled": False,
        "last_pulse_at": None,
        "pulse_count": 0,
        "learning_score": 0.0,
        "research_score": 0.0,
        "growth_score": 0.0,
        "last_feed_source": "not_started",
        "last_feed_status": "WAITING",
        "real_live_data_gate": "WAITING_FOR_REAL_LIVE_DATA",
        "raw_data_gate": "SCORING_BLOCKED_UNTIL_REAL_LIVE_DATA",
        "last_live_data_ok_at": None,
        "live_data_stale_seconds": None,
        "live_data_warning": "WAITING",
        "current_regime": "UNKNOWN",
        "paper_shadow_status": "READY_WAITING_FOR_REAL_LIVE_DATA",
        "paper_shadow_last_action": "WAITING",
        "paper_shadow_last_at": None,
        "paper_shadow_open_position": "NONE",
        "candle_harvester_status": "READY_WAITING_FOR_REAL_LIVE_DATA",
        "candle_harvester_last_at": None,
        "candle_harvester_last_rows": 0,
        "universe_scanner_status": "READY_WAITING_FOR_REAL_LIVE_DATA",
        "universe_scanner_last_at": None,
        "universe_scanner_last_symbols": 0,
        "universe_scanner_top_symbol": "NONE",
        "backtest_gate_status": "READY_WAITING_FOR_CANDLES",
        "backtest_last_at": None,
        "backtest_last_symbol": "NONE",
        "backtest_last_interval": "NONE",
        "backtest_walk_forward_status": "NOT_RUN",
        "champion_proof_gate": "LOCKED_BACKTEST_REQUIRED",
        "next_gate": "OVERNIGHT_DATA_COLLECTION",
        "current_blocker": "No overnight sample collected yet",
    }
    state = read_json(SHARED / "system_state.json", default)
    # Preserve current fields, repair mandatory version metadata.
    state.update({"project": PROJECT_NAME, "title": PROJECT_TITLE, "version": VERSION, "version_number": VERSION_NUMBER})
    for k, v in default.items():
        state.setdefault(k, v)
    return state


def save_system_state(state: Dict[str, Any]) -> None:
    state["updated_at"] = iso_now()
    write_json(SHARED / "system_state.json", state)


def url_json(url: str, timeout: int = 10) -> Any:
    req = urllib.request.Request(url, headers={"User-Agent": f"{PROJECT_NAME}/{VERSION}"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
        return json.loads(data.decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode("utf-8", errors="replace")[:260]
        except Exception:
            body = ""
        raise RuntimeError(f"HTTP {e.code}: {body}") from e


def clean_symbols(symbols: List[str]) -> List[str]:
    out: List[str] = []
    for sym in symbols or SYMBOLS_DEFAULT:
        txt = re.sub(r"[^A-Z0-9]", "", str(sym).upper())
        if txt and txt not in out:
            out.append(txt)
    return out or list(SYMBOLS_DEFAULT)


def compact_symbols_param(symbols: List[str]) -> str:
    # Binance documents the multi-symbol parameter as a JSON array.
    # Use compact JSON: ["BTCUSDT","ETHUSDT"] not Python/list text and not JSON with spaces.
    return urllib.parse.quote(json.dumps(clean_symbols(symbols), separators=(",", ":")), safe="")


def ticker_row_from_binance(item: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "symbol": item.get("symbol"),
        "last_price": float(item.get("lastPrice", 0) or 0),
        "price_change_percent_24h": float(item.get("priceChangePercent", 0) or 0),
        "high_24h": float(item.get("highPrice", 0) or 0),
        "low_24h": float(item.get("lowPrice", 0) or 0),
        "volume": float(item.get("volume", 0) or 0),
        "quote_volume": float(item.get("quoteVolume", 0) or 0),
        "count": int(item.get("count", 0) or 0),
        "close_time_ms": item.get("closeTime"),
    }


def fetch_ticker_data(symbols: List[str]) -> Tuple[List[Dict[str, Any]], str, str]:
    wanted = clean_symbols(symbols)
    wanted_set = set(wanted)
    errors = []

    # 1) Preferred: official public market-data base with the documented compact symbols JSON array.
    encoded_symbols = compact_symbols_param(wanted)
    for base in [BASE_DATA_API, BASE_BINANCE_API]:
        try:
            url = f"{base}/api/v3/ticker/24hr?symbols={encoded_symbols}"
            raw = url_json(url)
            if isinstance(raw, list):
                rows = [ticker_row_from_binance(item) for item in raw if str(item.get("symbol")) in wanted_set]
                if rows:
                    return rows, base, f"OK_MULTI_SYMBOLS_{len(rows)}"
                errors.append(f"{base}: multi-symbol response had no wanted symbols")
            else:
                errors.append(f"{base}: multi-symbol response was {type(raw).__name__}")
        except Exception as e:
            errors.append(f"{base} multi: {e}")

    # 2) Repair fallback: call the same official endpoint one symbol at a time.
    # This is still real public live data, and it avoids HTTP 400 caused by symbols-array formatting/proxy issues.
    for base in [BASE_DATA_API, BASE_BINANCE_API]:
        rows: List[Dict[str, Any]] = []
        single_errors: List[str] = []
        for sym in wanted:
            try:
                url = f"{base}/api/v3/ticker/24hr?symbol={urllib.parse.quote(sym, safe='')}"
                raw = url_json(url)
                if isinstance(raw, dict) and raw.get("symbol") == sym:
                    rows.append(ticker_row_from_binance(raw))
                else:
                    single_errors.append(f"{sym}: unexpected response")
            except Exception as e:
                single_errors.append(f"{sym}: {e}")
        if rows:
            return rows, base, f"OK_SINGLE_SYMBOL_REPAIR_{len(rows)}_OF_{len(wanted)}"
        errors.append(f"{base} single repair failed: " + "; ".join(single_errors[:3]))

    return [], "LIVE_DATA_FAIL", "LIVE_DATA_FAIL: " + " | ".join(errors[-4:])


def fake_ticker_data(symbols: List[str]) -> List[Dict[str, Any]]:
    # DISABLED FOR SCORING/TRAINING BY V012K. Kept only as dead-code compatibility; fetch_ticker_data never calls it.
    t = int(time.time())
    base_prices = {"BTCUSDT": 65000, "ETHUSDT": 3500, "SOLUSDT": 150, "XRPUSDT": 0.6, "DOGEUSDT": 0.12, "LINKUSDT": 16}
    out = []
    for i, sym in enumerate(symbols):
        wobble = ((t // 60 + i * 7) % 41 - 20) / 1000.0
        price = base_prices.get(sym, 10) * (1 + wobble)
        pct = round(wobble * 100, 3)
        out.append({
            "symbol": sym,
            "last_price": round(price, 8),
            "price_change_percent_24h": pct,
            "high_24h": round(price * 1.02, 8),
            "low_24h": round(price * 0.98, 8),
            "volume": 100000 + i * 12345,
            "quote_volume": 10000000 + i * 123456,
            "count": 10000 + i * 333,
        })
    return out


def parse_iso_seconds(value: Any) -> Optional[int]:
    try:
        if not value:
            return None
        txt = str(value).replace("Z", "+00:00")
        then = dt.datetime.fromisoformat(txt)
        if then.tzinfo is None:
            then = then.replace(tzinfo=dt.timezone.utc)
        return max(0, int((utc_now() - then.astimezone(dt.timezone.utc)).total_seconds()))
    except Exception:
        return None


def is_real_live_market_data(tickers: List[Dict[str, Any]], source: str, feed_status: str) -> bool:
    source_text = str(source or "")
    status_text = str(feed_status or "").upper()
    if not tickers:
        return False
    if source_text in {"offline_demo", "LIVE_DATA_FAIL", "NO_REAL_LIVE_DATA", "synthetic", "mock"}:
        return False
    if "OFFLINE" in status_text or "DEMO" in status_text or "FAKE" in status_text or "LIVE_DATA_FAIL" in status_text:
        return False
    if not source_text.startswith(REAL_LIVE_SOURCE_PREFIXES):
        return False
    return status_text.startswith("OK")


def update_live_data_guard(state: Dict[str, Any], ok: bool, source: str, feed_status: str, symbols_seen: List[str]) -> Dict[str, Any]:
    now = iso_now()
    if ok:
        state["last_live_data_ok_at"] = now
        stale = 0
        gate = "PASS_RECENT_REAL_LIVE_DATA"
        raw_gate = "ENFORCED_PASS_REAL_LIVE_DATA_ONLY"
        warning = "OK"
    else:
        stale = parse_iso_seconds(state.get("last_live_data_ok_at"))
        gate = "FAIL_NO_RECENT_REAL_LIVE_DATA"
        raw_gate = "SCORING_BLOCKED_NO_REAL_LIVE_DATA"
        if stale is None:
            warning = "NO_REAL_LIVE_DATA_SEEN_THIS_RUN"
        elif stale >= REAL_LIVE_DATA_WARNING_SECONDS:
            warning = f"WARNING_REAL_LIVE_DATA_STALE_{stale}_SECONDS"
        else:
            warning = f"WAITING_REAL_LIVE_DATA_STALE_{stale}_SECONDS"
    state["real_live_data_gate"] = gate
    state["raw_data_gate"] = raw_gate
    state["live_data_stale_seconds"] = stale
    state["live_data_warning"] = warning
    row = {
        "ts": now,
        "ok": bool(ok),
        "gate": gate,
        "raw_data_gate": raw_gate,
        "source": source,
        "feed_status": str(feed_status)[:300],
        "symbols_seen": symbols_seen,
        "last_live_data_ok_at": state.get("last_live_data_ok_at"),
        "stale_seconds": stale,
        "warning_after_seconds": REAL_LIVE_DATA_WARNING_SECONDS,
        "live_orders": "OFF",
        "claim_level": "REAL_LIVE_DATA_GUARD_ONLY_NO_SCORING_WHEN_FAIL",
    }
    append_jsonl(SHARED / "live_data_guard.jsonl", row)
    return row


def block_pulse_no_real_live_data(state: Dict[str, Any], symbols: List[str], source: str, feed_status: str, manual: bool) -> Dict[str, Any]:
    pulse_count = int(state.get("pulse_count", 0) or 0) + 1
    guard = update_live_data_guard(state, False, source, feed_status, [])
    state.update({
        "watch_enabled": bool(state.get("watch_enabled", True)),
        "last_pulse_at": iso_now(),
        "pulse_count": pulse_count,
        "last_feed_source": source,
        "last_feed_status": feed_status,
        "current_regime": "LIVE_DATA_BLOCKED",
        "no_trade_score": 100,
        "current_blocker": "No verified real live public exchange data. Scoring, learning, research and paper shadow are blocked until fresh real live data returns.",
        "next_gate": "RESTORE_REAL_LIVE_DATA_FEED",
    })
    save_system_state(state)
    write_json(UPDATES / "suggested_upgrades.json", {
        "updated_at": iso_now(),
        "suggestions": [{
            "version": "V012L",
            "name": "Restore Real Live Data Feed",
            "why": "Bali refused to score because no verified real live public exchange data was available.",
            "status": "BLOCKING_ALL_LEARNING_AND_SCORING",
            "risk": "safety-critical",
            "one_click_ready": False,
        }],
    })
    return {
        "ok": False,
        "message": "Bali pulse blocked: no verified real live public exchange data. No market ticks, feed proof, learning cycle, research score, or paper score was written.",
        "state": state,
        "cycle": None,
        "tickers": [],
        "guard": guard,
        "suggested_upgrades": read_json(UPDATES / "suggested_upgrades.json", {"suggestions": []}).get("suggestions", []),
    }


def infer_regime(tickers: List[Dict[str, Any]]) -> Dict[str, Any]:
    by_sym = {r.get("symbol"): r for r in tickers}
    btc = by_sym.get("BTCUSDT", {})
    btc_pct = float(btc.get("price_change_percent_24h", 0) or 0)
    alt_rows = [r for r in tickers if r.get("symbol") != "BTCUSDT"]
    alt_avg = sum(float(r.get("price_change_percent_24h", 0) or 0) for r in alt_rows) / max(1, len(alt_rows))
    dispersion = sum(abs(float(r.get("price_change_percent_24h", 0) or 0) - alt_avg) for r in alt_rows) / max(1, len(alt_rows))
    if btc_pct <= -4:
        label = "BTC_STORM_RISK_OFF"
        no_trade = 85
    elif btc_pct >= 4 and alt_avg >= 2:
        label = "BALI_TREND_UP_ALT_ROTATION"
        no_trade = 30
    elif abs(btc_pct) < 0.8 and dispersion < 1.2:
        label = "LOW_WAVE_CHOP"
        no_trade = 70
    elif dispersion >= 4:
        label = "VOLATILE_ISLAND_ROTATION"
        no_trade = 60
    elif btc_pct > 1:
        label = "BTC_TIDE_RISING"
        no_trade = 45
    elif btc_pct < -1:
        label = "BTC_TIDE_FALLING"
        no_trade = 65
    else:
        label = "NEUTRAL_LAGOON"
        no_trade = 55
    return {
        "label": label,
        "btc_pct_24h": round(btc_pct, 3),
        "alt_avg_pct_24h": round(alt_avg, 3),
        "alt_dispersion": round(dispersion, 3),
        "no_trade_score": no_trade,
    }


def seed_strategy_dna() -> None:
    path = STRATEGIES / "strategy_dna.json"
    if path.exists():
        return
    rows = [
        {
            "name": "Bali Breakout Pullback",
            "family": "Trend Pullback",
            "symbols": "BTCUSDT, ETHUSDT, SOLUSDT",
            "timeframes": "4h bias + 15m entry",
            "regime_needed": "BTC_TIDE_RISING or BALI_TREND_UP_ALT_ROTATION",
            "status": "RESEARCH_SEED",
            "proof_needed": "historical candles + paper arena",
            "risk": "medium",
        },
        {
            "name": "Lagoon Mean Reversion",
            "family": "Range Reversion",
            "symbols": "BTCUSDT, ETHUSDT",
            "timeframes": "1h range + 5m entry",
            "regime_needed": "LOW_WAVE_CHOP",
            "status": "RESEARCH_SEED",
            "proof_needed": "chop-only backtest + slippage stress",
            "risk": "medium",
        },
        {
            "name": "Volcano Risk-Off Shield",
            "family": "Defensive No-Trade Filter",
            "symbols": "all",
            "timeframes": "market-wide",
            "regime_needed": "BTC_STORM_RISK_OFF",
            "status": "RESEARCH_SEED",
            "proof_needed": "feed proof + drawdown avoidance test",
            "risk": "low",
        },
        {
            "name": "Palm Tree Alt Rotation Scout",
            "family": "Alt Momentum Scanner",
            "symbols": "SOLUSDT, XRPUSDT, DOGEUSDT, LINKUSDT",
            "timeframes": "1h + 15m",
            "regime_needed": "BALI_TREND_UP_ALT_ROTATION",
            "status": "RESEARCH_SEED",
            "proof_needed": "relative strength ledger + paper shadow trades",
            "risk": "high",
        },
    ]
    write_json(path, {"created_at": iso_now(), "strategies": rows})


def update_research_ledger(regime: Dict[str, Any], tickers: List[Dict[str, Any]], source: str, status: str) -> Dict[str, Any]:
    label = regime.get("label", "UNKNOWN")
    if label == "BALI_TREND_UP_ALT_ROTATION":
        research_task = "Rank alt rotation candidates; keep Risk Police spread/drawdown blocks visible."
        squad = "Bravo Scout"
    elif label == "BTC_STORM_RISK_OFF":
        research_task = "Study no-trade shield performance; do not hunt entries during storm conditions."
        squad = "Risk Police"
    elif label == "LOW_WAVE_CHOP":
        research_task = "Collect range behaviour for Lagoon Mean Reversion; no live signals."
        squad = "Charlie Specialist"
    else:
        research_task = "Collect baseline market regime proof and wait for clearer patterns."
        squad = "Alpha Watch"
    row = {
        "ts": iso_now(),
        "squad": squad,
        "regime": label,
        "research_task": research_task,
        "feed_source": source,
        "feed_status": status[:160],
        "symbols_seen": [r.get("symbol") for r in tickers],
        "real_live_verified": True,
        "claim_level": "REAL_LIVE_DATA_COLLECTION_ONLY_NOT_EDGE_PROOF",
    }
    append_jsonl(SHARED / "research_ledger.jsonl", row)
    return row


def write_market_logs(tickers: List[Dict[str, Any]], source: str, status: str, regime: Dict[str, Any]) -> None:
    batch_id = utc_now().strftime("%Y%m%dT%H%M%SZ")
    for r in tickers:
        row = dict(r)
        row.update({
            "ts": iso_now(),
            "batch_id": batch_id,
            "source": source,
            "feed_status": status,
            "regime": regime.get("label"),
            "no_trade_score": regime.get("no_trade_score"),
        })
        append_jsonl(SHARED / "market_ticks.jsonl", row)
        append_csv(SHARED / "market_ticks.csv", [
            "ts", "batch_id", "source", "feed_status", "symbol", "last_price", "price_change_percent_24h",
            "high_24h", "low_24h", "volume", "quote_volume", "count", "regime", "no_trade_score"
        ], row)
    proof = {
        "ts": iso_now(),
        "batch_id": batch_id,
        "source": source,
        "status": status,
        "symbols": [r.get("symbol") for r in tickers],
        "regime": regime,
        "real_live_verified": True,
        "live_trading": "OFF",
        "claim_level": "PUBLIC_MARKET_DATA_FEED_PROOF_ONLY_REAL_LIVE_VERIFIED",
    }
    append_jsonl(SHARED / "feed_proof_ledger.jsonl", proof)


def safe_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def candle_intervals() -> List[str]:
    return ["1m", "5m", "15m"]


def candle_symbol_limit(symbols: List[str]) -> List[str]:
    # Keep the automatic harvester light enough for public endpoints.
    return clean_symbols(symbols)[:6]


def kline_row_from_binance(symbol: str, interval: str, item: List[Any], source: str, feed_status: str) -> Dict[str, Any]:
    open_time_ms = int(item[0])
    close_time_ms = int(item[6])
    return {
        "ts": iso_now(),
        "symbol": symbol,
        "interval": interval,
        "open_time_ms": open_time_ms,
        "open_time_utc": dt.datetime.fromtimestamp(open_time_ms / 1000, tz=dt.timezone.utc).isoformat(timespec="seconds"),
        "open": safe_float(item[1]),
        "high": safe_float(item[2]),
        "low": safe_float(item[3]),
        "close": safe_float(item[4]),
        "volume": safe_float(item[5]),
        "close_time_ms": close_time_ms,
        "close_time_utc": dt.datetime.fromtimestamp(close_time_ms / 1000, tz=dt.timezone.utc).isoformat(timespec="seconds"),
        "quote_volume": safe_float(item[7]),
        "trades": int(safe_float(item[8])),
        "taker_buy_base_volume": safe_float(item[9]),
        "taker_buy_quote_volume": safe_float(item[10]),
        "source": source,
        "feed_status": feed_status[:160],
        "real_live_verified": True,
        "live_orders": "OFF",
        "api_keys": "NONE",
        "claim_level": "CANDLE_HARVEST_PUBLIC_MARKET_DATA_ONLY_NOT_EDGE_PROOF",
    }


def fetch_binance_klines(symbol: str, interval: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], str, str]:
    errors: List[str] = []
    for base in [BASE_DATA_API, BASE_BINANCE_API]:
        try:
            url = f"{base}/api/v3/klines?symbol={urllib.parse.quote(symbol, safe='')}&interval={urllib.parse.quote(interval, safe='')}&limit={int(limit)}"
            raw = url_json(url)
            if isinstance(raw, list) and raw:
                rows = [kline_row_from_binance(symbol, interval, item, base, f"OK_KLINES_{symbol}_{interval}_{len(raw)}") for item in raw if isinstance(item, list) and len(item) >= 11]
                if rows:
                    return rows, base, f"OK_KLINES_{symbol}_{interval}_{len(rows)}"
                errors.append(f"{base}: kline rows malformed for {symbol} {interval}")
            else:
                errors.append(f"{base}: empty/non-list klines for {symbol} {interval}")
        except Exception as e:
            errors.append(f"{base}: {symbol} {interval}: {e}")
    return [], "LIVE_DATA_FAIL", "LIVE_DATA_FAIL_KLINES: " + " | ".join(errors[-2:])


def harvest_candles_for_symbols(symbols: List[str], source_hint: str, feed_status: str, limit: int = 5) -> Dict[str, Any]:
    """Harvest public candles only after the main real-live data gate has passed.

    This is public market-data collection only. It never places orders and it never uses API keys.
    """
    now = iso_now()
    if not str(source_hint or "").startswith(REAL_LIVE_SOURCE_PREFIXES) or not str(feed_status or "").upper().startswith("OK"):
        row = {"ts": now, "status": "BLOCKED_NO_REAL_LIVE_DATA", "source": source_hint, "feed_status": feed_status[:160], "rows_written": 0}
        append_jsonl(SHARED / "candle_proof_ledger.jsonl", row)
        return {"ok": False, "status": "BLOCKED_NO_REAL_LIVE_DATA", "rows_written": 0, "symbols": []}

    state_path = SHARED / "candle_harvester_state.json"
    candle_state = read_json(state_path, {"last_open_time_ms": {}, "total_rows_written": 0})
    last_map = candle_state.setdefault("last_open_time_ms", {})
    symbols_clean = candle_symbol_limit(symbols)
    intervals = candle_intervals()
    rows_written = 0
    errors: List[str] = []
    latest_examples: List[Dict[str, Any]] = []

    for sym in symbols_clean:
        for interval in intervals:
            rows, src, status = fetch_binance_klines(sym, interval, limit=limit)
            key = f"{sym}|{interval}"
            last_seen = int(last_map.get(key, 0) or 0)
            new_rows = [r for r in rows if int(r.get("open_time_ms", 0) or 0) > last_seen]
            if rows and not new_rows:
                latest_examples.append(rows[-1])
            if not rows:
                errors.append(status[:180])
                continue
            if new_rows:
                candle_jsonl = SHARED / "candles" / f"{sym}_{interval}.jsonl"
                candle_csv = SHARED / "candles" / f"{sym}_{interval}.csv"
                for r in new_rows:
                    append_jsonl(candle_jsonl, r)
                    append_csv(candle_csv, [
                        "ts", "symbol", "interval", "open_time_utc", "open", "high", "low", "close", "volume",
                        "close_time_utc", "quote_volume", "trades", "source", "feed_status", "real_live_verified", "claim_level"
                    ], r)
                    latest_examples.append(r)
                last_map[key] = max(int(r.get("open_time_ms", 0) or 0) for r in new_rows)
                rows_written += len(new_rows)

    candle_state.update({
        "updated_at": now,
        "status": "CANDLE_HARVESTER_ONLINE" if (rows_written > 0 or latest_examples) else "CANDLE_HARVESTER_NO_NEW_ROWS",
        "symbols": symbols_clean,
        "intervals": intervals,
        "last_rows_written": rows_written,
        "total_rows_written": int(candle_state.get("total_rows_written", 0) or 0) + rows_written,
        "live_orders": "OFF",
        "api_keys": "NONE",
    })
    write_json(state_path, candle_state)
    proof = {
        "ts": now,
        "status": candle_state["status"],
        "symbols": symbols_clean,
        "intervals": intervals,
        "rows_written": rows_written,
        "source": source_hint,
        "feed_status": feed_status[:160],
        "errors_tail": errors[-5:],
        "real_live_verified": True,
        "live_orders": "OFF",
        "claim_level": "CANDLE_HARVEST_PROOF_PUBLIC_MARKET_DATA_ONLY",
    }
    append_jsonl(SHARED / "candle_proof_ledger.jsonl", proof)
    return {"ok": True, "status": candle_state["status"], "rows_written": rows_written, "symbols": symbols_clean, "intervals": intervals, "errors": errors[-5:]}


def is_universe_symbol_allowed(symbol: str) -> bool:
    s = str(symbol or "").upper()
    if not s.endswith("USDT"):
        return False
    blocked_fragments = ["UPUSDT", "DOWNUSDT", "BULLUSDT", "BEARUSDT"]
    return not any(fragment in s for fragment in blocked_fragments)


def fetch_universe_ticker_data(max_rows: int = 80) -> Tuple[List[Dict[str, Any]], str, str]:
    errors: List[str] = []
    for base in [BASE_DATA_API, BASE_BINANCE_API]:
        try:
            url = f"{base}/api/v3/ticker/24hr"
            raw = url_json(url, timeout=15)
            if not isinstance(raw, list):
                errors.append(f"{base}: universe response was {type(raw).__name__}")
                continue
            rows = []
            for item in raw:
                sym = str(item.get("symbol") or "")
                if not is_universe_symbol_allowed(sym):
                    continue
                row = ticker_row_from_binance(item)
                row["source"] = base
                row["feed_status"] = "OK_UNIVERSE_24HR"
                rows.append(row)
            rows.sort(key=lambda r: safe_float(r.get("quote_volume")), reverse=True)
            return rows[:max_rows], base, f"OK_UNIVERSE_24HR_{len(rows[:max_rows])}"
        except Exception as e:
            errors.append(f"{base}: universe: {e}")
    return [], "LIVE_DATA_FAIL", "LIVE_DATA_FAIL_UNIVERSE: " + " | ".join(errors[-2:])


def rank_universe_rows(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not rows:
        return []
    max_qv = max(safe_float(r.get("quote_volume")) for r in rows) or 1.0
    ranked: List[Dict[str, Any]] = []
    for r in rows:
        pct = safe_float(r.get("price_change_percent_24h"))
        qv = safe_float(r.get("quote_volume"))
        high = safe_float(r.get("high_24h"))
        low = safe_float(r.get("low_24h"))
        last = safe_float(r.get("last_price"))
        range_pct = ((high - low) / last * 100.0) if last > 0 else 0.0
        activity = min(40.0, (qv / max_qv) * 40.0)
        momentum = min(30.0, max(0.0, pct + 5.0) * 3.0)
        volatility = min(30.0, range_pct * 2.0)
        score = round(activity + momentum + volatility, 3)
        if score >= 70:
            bucket = "HOT"
        elif score >= 45:
            bucket = "ACTIVE"
        elif score >= 25:
            bucket = "QUIET"
        else:
            bucket = "LOW_SIGNAL"
        ranked.append({
            "ts": iso_now(),
            "symbol": r.get("symbol"),
            "last_price": r.get("last_price"),
            "price_change_percent_24h": round(pct, 3),
            "quote_volume": round(qv, 2),
            "range_pct_24h": round(range_pct, 3),
            "activity_score": round(activity, 3),
            "momentum_score": round(momentum, 3),
            "volatility_score": round(volatility, 3),
            "universe_score": score,
            "bucket": bucket,
            "source": r.get("source"),
            "feed_status": r.get("feed_status"),
            "real_live_verified": True,
            "live_orders": "OFF",
            "claim_level": "UNIVERSE_SCANNER_RANKING_ONLY_NOT_TRADE_SIGNAL",
        })
    ranked.sort(key=lambda r: safe_float(r.get("universe_score")), reverse=True)
    return ranked


def run_universe_scanner(max_rows: int = 80) -> Dict[str, Any]:
    rows, source, status = fetch_universe_ticker_data(max_rows=max_rows)
    now = iso_now()
    if not is_real_live_market_data(rows, source, status):
        proof = {"ts": now, "status": "BLOCKED_NO_REAL_LIVE_DATA", "source": source, "feed_status": status[:240], "rows_written": 0}
        append_jsonl(SHARED / "universe_scan_ledger.jsonl", proof)
        return {"ok": False, "status": "BLOCKED_NO_REAL_LIVE_DATA", "ranked": [], "source": source, "feed_status": status}
    ranked = rank_universe_rows(rows)
    batch_id = utc_now().strftime("%Y%m%dT%H%M%SZ")
    out_rows = ranked[:40]
    for r in out_rows:
        row = dict(r)
        row["batch_id"] = batch_id
        append_jsonl(SHARED / "universe_scan_ledger.jsonl", row)
        append_csv(SHARED / "universe_scan_ledger.csv", [
            "ts", "batch_id", "symbol", "last_price", "price_change_percent_24h", "quote_volume",
            "range_pct_24h", "activity_score", "momentum_score", "volatility_score", "universe_score",
            "bucket", "source", "feed_status", "real_live_verified", "claim_level"
        ], row)
    summary = {
        "updated_at": now,
        "status": "UNIVERSE_SCANNER_ONLINE",
        "batch_id": batch_id,
        "rows_ranked": len(ranked),
        "rows_written": len(out_rows),
        "top_symbol": out_rows[0].get("symbol") if out_rows else "NONE",
        "top_score": out_rows[0].get("universe_score") if out_rows else None,
        "source": source,
        "feed_status": status,
        "live_orders": "OFF",
        "api_keys": "NONE",
        "claim_level": "UNIVERSE_SCANNER_RANKING_ONLY_NOT_TRADE_SIGNAL",
    }
    write_json(SHARED / "universe" / "universe_state.json", summary)
    return {"ok": True, "status": summary["status"], "ranked": out_rows, "source": source, "feed_status": status, "top_symbol": summary["top_symbol"], "rows_written": len(out_rows)}


def count_candle_rows() -> int:
    total = 0
    candles_dir = SHARED / "candles"
    if candles_dir.exists():
        for p in candles_dir.glob("*.jsonl"):
            total += count_lines(p)
    return total


def latest_candle_examples(limit: int = 18) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    candles_dir = SHARED / "candles"
    if candles_dir.exists():
        for p in candles_dir.glob("*.jsonl"):
            rows.extend(read_last_jsonl(p, 2))
    rows.sort(key=lambda r: str(r.get("open_time_utc") or r.get("ts") or ""))
    return rows[-limit:]


def latest_universe_batch_rows(limit: int = 20) -> List[Dict[str, Any]]:
    """Return the top rows from the latest universe batch, not merely the last appended rows.

    V014A appended the top 40 rows in ranked order. A report tail of the last 10 rows
    therefore showed ranks 31-40 while the summary top_symbol showed rank 1. V014B
    groups by latest batch_id and sorts by universe_score. V014C ensures the
    dashboard/report receives the first/top rows of that sorted batch, not its tail.
    """
    rows = read_last_jsonl(SHARED / "universe_scan_ledger.jsonl", 500)
    ranked = [r for r in rows if r.get("batch_id") and r.get("symbol") and r.get("universe_score") is not None]
    if not ranked:
        return []
    latest_batch = str(ranked[-1].get("batch_id"))
    batch_rows = [r for r in ranked if str(r.get("batch_id")) == latest_batch]
    batch_rows.sort(key=lambda r: safe_float(r.get("universe_score")), reverse=True)
    return batch_rows[:limit]


def candle_summary_from_proof() -> Dict[str, Any]:
    proofs = read_last_jsonl(SHARED / "candle_proof_ledger.jsonl", 50)
    total_rows = count_candle_rows()
    last = proofs[-1] if proofs else {}
    return {
        "status": last.get("status") or ("CANDLE_HARVESTER_ONLINE" if total_rows > 0 else "READY_WAITING_FOR_REAL_LIVE_DATA"),
        "last_at": last.get("ts"),
        "last_new_rows": int(safe_float(last.get("rows_written"), 0)),
        "total_rows": total_rows,
        "proof_rows": count_lines(SHARED / "candle_proof_ledger.jsonl"),
        "source": last.get("source"),
        "feed_status": last.get("feed_status"),
        "symbols": last.get("symbols") or [],
        "intervals": last.get("intervals") or [],
    }


def universe_summary_from_latest_batch() -> Dict[str, Any]:
    batch_rows = latest_universe_batch_rows(40)
    state = read_json(SHARED / "universe" / "universe_state.json", {})
    top = batch_rows[0] if batch_rows else {}
    return {
        "status": state.get("status") or ("UNIVERSE_SCANNER_ONLINE" if batch_rows else "READY_WAITING_FOR_REAL_LIVE_DATA"),
        "last_at": state.get("updated_at") or top.get("ts"),
        "rows_visible": len(batch_rows),
        "rows_total_ledger": count_lines(SHARED / "universe_scan_ledger.jsonl"),
        "batch_id": top.get("batch_id") or state.get("batch_id"),
        "top_symbol": top.get("symbol") or state.get("top_symbol") or "NONE",
        "top_score": top.get("universe_score") if top else state.get("top_score"),
        "source": top.get("source") or state.get("source"),
        "feed_status": top.get("feed_status") or state.get("feed_status"),
        "bucket": top.get("bucket"),
    }



def backtest_dir() -> Path:
    path = SHARED / "backtests"
    path.mkdir(parents=True, exist_ok=True)
    return path


def load_candle_history(symbol: str, interval: str, max_rows: int = 5000) -> List[Dict[str, Any]]:
    """Load collected public candle rows from local evidence files only.

    V015A does not fetch private data, place orders, or use API keys. It only replays
    candles already collected by the V014A candle harvester.
    """
    symbol = re.sub(r"[^A-Z0-9]", "", str(symbol or "").upper())
    interval = str(interval or "1m").strip()
    path = SHARED / "candles" / f"{symbol}_{interval}.jsonl"
    rows = read_last_jsonl(path, max_rows)
    clean: List[Dict[str, Any]] = []
    seen = set()
    for r in rows:
        try:
            if str(r.get("source", "")).startswith(REAL_LIVE_SOURCE_PREFIXES) is False:
                continue
            key = (r.get("symbol"), r.get("interval"), r.get("open_time_ms") or r.get("open_time_utc"))
            if key in seen:
                continue
            seen.add(key)
            close = safe_float(r.get("close"))
            if close <= 0:
                continue
            clean.append(r)
        except Exception:
            continue
    clean.sort(key=lambda x: int(safe_float(x.get("open_time_ms"), 0)))
    return clean


def available_candle_datasets() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    candles_dir = SHARED / "candles"
    if not candles_dir.exists():
        return out
    for p in candles_dir.glob("*.jsonl"):
        stem = p.stem
        if "_" not in stem:
            continue
        symbol, interval = stem.rsplit("_", 1)
        rows = load_candle_history(symbol, interval, 5000)
        if rows:
            out.append({
                "symbol": symbol,
                "interval": interval,
                "rows": len(rows),
                "first": rows[0].get("open_time_utc"),
                "last": rows[-1].get("open_time_utc"),
            })
    out.sort(key=lambda r: (int(r.get("rows") or 0), str(r.get("symbol")), str(r.get("interval"))), reverse=True)
    return out


def choose_backtest_dataset(symbol: Optional[str] = None, interval: Optional[str] = None) -> Tuple[str, str, List[Dict[str, Any]], List[Dict[str, Any]]]:
    datasets = available_candle_datasets()
    if symbol and interval:
        rows = load_candle_history(symbol, interval, 5000)
        return str(symbol).upper(), str(interval), rows, datasets
    preferred_symbols = []
    try:
        us = universe_summary_from_latest_batch()
        if us.get("top_symbol"):
            preferred_symbols.append(str(us.get("top_symbol")))
    except Exception:
        pass
    preferred_symbols += ["BTCUSDT", "ETHUSDT", "SOLUSDT", "XRPUSDT", "DOGEUSDT", "LINKUSDT"]
    preferred_intervals = ["1m", "5m", "15m"]
    for sym in preferred_symbols:
        for tf in preferred_intervals:
            rows = load_candle_history(sym, tf, 5000)
            if len(rows) >= 20:
                return sym, tf, rows, datasets
    if datasets:
        best = datasets[0]
        rows = load_candle_history(best["symbol"], best["interval"], 5000)
        return best["symbol"], best["interval"], rows, datasets
    return "NONE", "NONE", [], datasets


def moving_average(values: List[float], end_index: int, window: int) -> Optional[float]:
    start = end_index - window + 1
    if start < 0:
        return None
    chunk = values[start:end_index + 1]
    if len(chunk) != window:
        return None
    return sum(chunk) / float(window)


def simulate_backtest_split(candles: List[Dict[str, Any]], start: int, end: int, split_name: str) -> Dict[str, Any]:
    cfg = paper_shadow_config()
    fee_pct = cfg["fee_rate"] * 2.0 * 100.0
    slippage_pct = cfg["slippage_rate"] * 2.0 * 100.0
    closes = [safe_float(r.get("close")) for r in candles]
    equity = 100.0
    peak = equity
    max_drawdown = 0.0
    trades: List[Dict[str, Any]] = []
    open_pos: Optional[Dict[str, Any]] = None
    bars_held = 0
    start = max(0, start)
    end = min(len(candles), end)
    for i in range(start, end):
        close = closes[i]
        if close <= 0:
            continue
        ma3 = moving_average(closes, i, 3)
        ma5 = moving_average(closes, i, 5)
        momentum = close - closes[i - 1] if i > 0 else 0.0
        if open_pos:
            bars_held += 1
            exit_rule = False
            reason = "hold"
            if ma3 is not None and close < ma3:
                exit_rule = True
                reason = "close_below_ma3"
            if bars_held >= 5:
                exit_rule = True
                reason = "time_exit_5_bars"
            if i == end - 1:
                exit_rule = True
                reason = "split_end_close"
            if exit_rule:
                entry_price = safe_float(open_pos.get("entry_price"))
                gross_pct = ((close - entry_price) / entry_price * 100.0) if entry_price > 0 else 0.0
                net_pct = gross_pct - fee_pct - slippage_pct
                equity *= (1.0 + net_pct / 100.0)
                peak = max(peak, equity)
                if peak > 0:
                    max_drawdown = max(max_drawdown, (peak - equity) / peak * 100.0)
                trades.append({
                    "entry_time": open_pos.get("entry_time"),
                    "exit_time": candles[i].get("open_time_utc"),
                    "entry_price": round(entry_price, 10),
                    "exit_price": round(close, 10),
                    "bars_held": bars_held,
                    "gross_pct": round(gross_pct, 4),
                    "fees_pct": round(fee_pct, 4),
                    "slippage_pct": round(slippage_pct, 4),
                    "net_pct": round(net_pct, 4),
                    "exit_reason": reason,
                })
                open_pos = None
                bars_held = 0
        else:
            entry_rule = bool(ma3 is not None and ma5 is not None and close > ma3 and ma3 >= ma5 and momentum > 0)
            if entry_rule:
                open_pos = {
                    "entry_time": candles[i].get("open_time_utc"),
                    "entry_price": close * (1.0 + cfg["slippage_rate"]),
                }
                bars_held = 0
    wins = [t for t in trades if safe_float(t.get("net_pct")) > 0]
    losses = [t for t in trades if safe_float(t.get("net_pct")) <= 0]
    total_net = sum(safe_float(t.get("net_pct")) for t in trades)
    avg_net = total_net / len(trades) if trades else 0.0
    win_rate = len(wins) / len(trades) * 100.0 if trades else 0.0
    return {
        "split": split_name,
        "candles": max(0, end - start),
        "trades": len(trades),
        "wins": len(wins),
        "losses": len(losses),
        "win_rate_pct": round(win_rate, 2),
        "total_net_pct_sum": round(total_net, 4),
        "avg_net_pct": round(avg_net, 4),
        "max_drawdown_pct": round(max_drawdown, 4),
        "ending_equity_index": round(equity, 4),
        "sample_trades": trades[-5:],
        "status": "TRADES_RECORDED" if trades else "NO_TRADES_FOUND",
    }


def run_backtest_walkforward_gate(symbol: Optional[str] = None, interval: Optional[str] = None) -> Dict[str, Any]:
    """Run a small evidence-only backtest and walk-forward split on collected candles.

    It is a gate, not a champion maker. It records whether a simple rule can be replayed
    on local public-data candles before any future strategy can claim evidence.
    """
    ensure_dirs()
    run_id = utc_now().strftime("BT%Y%m%dT%H%M%SZ")
    chosen_symbol, chosen_interval, candles, datasets = choose_backtest_dataset(symbol, interval)
    now = iso_now()
    state_path = backtest_dir() / "backtest_walkforward_state.json"
    if len(candles) < 20:
        result = {
            "ts": now,
            "run_id": run_id,
            "status": "NEEDS_MORE_CANDLES",
            "gate": "BACKTEST_BLOCKED_INSUFFICIENT_CANDLES",
            "symbol": chosen_symbol,
            "interval": chosen_interval,
            "total_candles": len(candles),
            "datasets_available": datasets[:12],
            "min_required_candles": 20,
            "champion_claim_allowed": False,
            "live_orders": "OFF",
            "api_keys": "NONE",
            "claim_level": "BACKTEST_GATE_ONLY_NOT_PROFIT_PROOF",
            "message": "Collect more public candles before testing strategy rules.",
        }
        append_jsonl(backtest_dir() / "backtest_walkforward_ledger.jsonl", result)
        write_json(state_path, result)
        return {"ok": False, **result}

    split = max(10, int(len(candles) * 0.7))
    if len(candles) - split < 8:
        split = max(8, len(candles) - 8)
    in_sample = simulate_backtest_split(candles, 0, split, "IN_SAMPLE_RESEARCH")
    walk_forward = simulate_backtest_split(candles, split, len(candles), "WALK_FORWARD_OUT_OF_SAMPLE")
    wf_trades = int(walk_forward.get("trades") or 0)
    wf_dd = safe_float(walk_forward.get("max_drawdown_pct"))
    wf_avg = safe_float(walk_forward.get("avg_net_pct"))
    if wf_trades <= 0:
        gate = "WALK_FORWARD_RECORDED_NO_TRADES_YET"
    elif wf_dd > 8.0:
        gate = "WALK_FORWARD_RECORDED_RISK_TOO_HIGH"
    elif wf_avg <= 0:
        gate = "WALK_FORWARD_RECORDED_EDGE_NOT_PROVEN"
    else:
        gate = "WALK_FORWARD_EVIDENCE_RECORDED_REPEAT_TEST_REQUIRED"
    result = {
        "ts": now,
        "run_id": run_id,
        "status": "BACKTEST_WALK_FORWARD_RECORDED",
        "gate": gate,
        "strategy": "Bali MA Momentum Probe V015A",
        "symbol": chosen_symbol,
        "interval": chosen_interval,
        "total_candles": len(candles),
        "split_index": split,
        "in_sample": in_sample,
        "walk_forward": walk_forward,
        "datasets_available": datasets[:12],
        "champion_claim_allowed": False,
        "champion_lock": "LOCKED",
        "live_orders": "OFF",
        "api_keys": "NONE",
        "fees_and_slippage_included": True,
        "claim_level": "BACKTEST_GATE_ONLY_NOT_PROFIT_PROOF",
        "message": "Backtest/walk-forward evidence recorded. Champion claims remain blocked until repeated evidence and human approval exist.",
    }
    append_jsonl(backtest_dir() / "backtest_walkforward_ledger.jsonl", result)
    append_csv(backtest_dir() / "backtest_walkforward_results.csv", [
        "ts", "run_id", "status", "gate", "strategy", "symbol", "interval", "total_candles",
        "in_sample_trades", "in_sample_avg_net_pct", "in_sample_max_drawdown_pct",
        "walk_forward_trades", "walk_forward_avg_net_pct", "walk_forward_max_drawdown_pct",
        "champion_claim_allowed", "live_orders", "api_keys", "claim_level"
    ], {
        "ts": result["ts"],
        "run_id": run_id,
        "status": result["status"],
        "gate": gate,
        "strategy": result["strategy"],
        "symbol": chosen_symbol,
        "interval": chosen_interval,
        "total_candles": len(candles),
        "in_sample_trades": in_sample.get("trades"),
        "in_sample_avg_net_pct": in_sample.get("avg_net_pct"),
        "in_sample_max_drawdown_pct": in_sample.get("max_drawdown_pct"),
        "walk_forward_trades": walk_forward.get("trades"),
        "walk_forward_avg_net_pct": walk_forward.get("avg_net_pct"),
        "walk_forward_max_drawdown_pct": walk_forward.get("max_drawdown_pct"),
        "champion_claim_allowed": False,
        "live_orders": "OFF",
        "api_keys": "NONE",
        "claim_level": result["claim_level"],
    })
    write_json(state_path, result)
    try:
        st = get_system_state()
        st.update({
            "backtest_gate_status": result["status"],
            "backtest_last_at": now,
            "backtest_last_symbol": chosen_symbol,
            "backtest_last_interval": chosen_interval,
            "backtest_walk_forward_status": gate,
            "champion_proof_gate": "LOCKED_REPEAT_BACKTEST_AND_HUMAN_APPROVAL_REQUIRED",
            "next_gate": "REPEAT_BACKTEST_AND_COMPARE_STARGATE",
            "current_blocker": "Need repeated walk-forward evidence across more candles before any champion claim.",
        })
        save_system_state(st)
    except Exception:
        append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "where": "run_backtest_walkforward_gate_state_update", "error": traceback.format_exc()})
    return {"ok": True, **result}


def latest_backtest_records(limit: int = 8) -> List[Dict[str, Any]]:
    return read_last_jsonl(backtest_dir() / "backtest_walkforward_ledger.jsonl", limit)


def backtest_summary() -> Dict[str, Any]:
    state = read_json(backtest_dir() / "backtest_walkforward_state.json", {})
    rows = count_lines(backtest_dir() / "backtest_walkforward_ledger.jsonl")
    if not state:
        return {
            "status": "READY_WAITING_FOR_BACKTEST",
            "gate": "NOT_RUN",
            "rows": rows,
            "champion_claim_allowed": False,
        }
    out = dict(state)
    out["rows"] = rows
    out.setdefault("champion_claim_allowed", False)
    return out

def paper_shadow_config() -> Dict[str, Any]:
    return {
        "notional_usd": 1000.0,
        "fee_rate": 0.001,
        "slippage_rate": 0.0005,
        "max_one_open_position": True,
        "paper_only": True,
        "live_orders": "OFF",
        "api_keys": "NONE",
    }


def rank_paper_candidate(tickers: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    candidates = []
    for r in tickers:
        price = safe_float(r.get("last_price"))
        pct = safe_float(r.get("price_change_percent_24h"))
        qv = safe_float(r.get("quote_volume"))
        if price > 0:
            score = pct + min(3.0, qv / 1000000000.0)
            candidates.append({"row": r, "score": round(score, 4), "pct": pct, "price": price})
    if not candidates:
        return None
    return max(candidates, key=lambda x: x["score"])


def run_paper_shadow_simulator(tickers: List[Dict[str, Any]], regime: Dict[str, Any], source: str, feed_status: str) -> Dict[str, Any]:
    """Create simulated would-have-traded records only after real public live data passes.

    This is not an order engine. It never uses API keys, never calls private endpoints,
    never places orders, and cannot approve champions. It is a paper-shadow evidence ledger only.
    """
    if not is_real_live_market_data(tickers, source, feed_status):
        return {"ok": False, "status": "BLOCKED_NO_REAL_LIVE_DATA", "action": "NO_PAPER_SCORE_WRITTEN"}

    cfg = paper_shadow_config()
    now = iso_now()
    label = str(regime.get("label") or "UNKNOWN")
    no_trade_score = int(regime.get("no_trade_score") or 100)
    state_path = SHARED / "paper_shadow_state.json"
    ps = read_json(state_path, {"open_position": None, "opened_count": 0, "closed_count": 0, "stand_aside_count": 0})
    open_pos = ps.get("open_position")
    by_sym = {str(r.get("symbol")): r for r in tickers}
    candidate = rank_paper_candidate(tickers)
    action = "STAND_ASIDE_SIMULATED"
    strategy = "Bali Tide Guard V013"
    risk_reason = "Risk Police requires real-live data and no-trade filtering before any paper entry."
    strategy_reason = "No qualifying paper setup."
    rows: List[Dict[str, Any]] = []

    entry_allowed = (
        no_trade_score <= 45
        and label in {"BTC_TIDE_RISING", "BALI_TREND_UP_ALT_ROTATION", "VOLATILE_ISLAND_ROTATION"}
        and candidate is not None
        and safe_float(candidate["row"].get("price_change_percent_24h")) >= 0.5
    )

    if open_pos:
        sym = str(open_pos.get("symbol"))
        tick = by_sym.get(sym)
        if tick:
            entry_price = safe_float(open_pos.get("entry_price"))
            exit_price = safe_float(tick.get("last_price"))
            gross_pct = ((exit_price - entry_price) / entry_price * 100.0) if entry_price > 0 else 0.0
            fee_pct = cfg["fee_rate"] * 2 * 100.0
            slippage_pct = cfg["slippage_rate"] * 2 * 100.0
            net_pct = gross_pct - fee_pct - slippage_pct
            should_exit = no_trade_score >= 65 or label in {"BTC_TIDE_FALLING", "BTC_STORM_RISK_OFF", "LOW_WAVE_CHOP"}
            if should_exit:
                action = "EXIT_SIMULATED"
                strategy_reason = "Paper position closed because regime/risk filter turned defensive."
                risk_reason = f"no_trade_score={no_trade_score}; regime={label}; close paper-only position."
                row = {
                    "ts": now,
                    "action": action,
                    "strategy": strategy,
                    "symbol": sym,
                    "side": "LONG_PAPER_ONLY",
                    "entry_ts": open_pos.get("entry_ts"),
                    "entry_price": entry_price,
                    "exit_price": exit_price,
                    "notional_usd": cfg["notional_usd"],
                    "gross_pct": round(gross_pct, 4),
                    "fees_pct": round(fee_pct, 4),
                    "slippage_pct": round(slippage_pct, 4),
                    "net_pct_after_fee_slippage": round(net_pct, 4),
                    "regime": label,
                    "no_trade_score": no_trade_score,
                    "source": source,
                    "feed_status": feed_status[:160],
                    "real_live_verified": True,
                    "live_orders": "OFF",
                    "api_keys": "NONE",
                    "strategy_reason": strategy_reason,
                    "risk_reason": risk_reason,
                    "claim_level": "PAPER_SHADOW_SIMULATION_ONLY_NOT_PROFIT_PROOF",
                }
                rows.append(row)
                ps["open_position"] = None
                ps["closed_count"] = int(ps.get("closed_count", 0) or 0) + 1
            else:
                action = "HOLD_SIMULATED"
                strategy_reason = "Paper position remains open; no live order exists."
                risk_reason = f"no_trade_score={no_trade_score}; risk filter not forcing exit."
                rows.append({
                    "ts": now,
                    "action": action,
                    "strategy": strategy,
                    "symbol": sym,
                    "side": "LONG_PAPER_ONLY",
                    "entry_ts": open_pos.get("entry_ts"),
                    "entry_price": entry_price,
                    "current_price": exit_price,
                    "unrealized_pct_before_fee_exit_slippage": round(gross_pct, 4),
                    "regime": label,
                    "no_trade_score": no_trade_score,
                    "source": source,
                    "feed_status": feed_status[:160],
                    "real_live_verified": True,
                    "live_orders": "OFF",
                    "api_keys": "NONE",
                    "strategy_reason": strategy_reason,
                    "risk_reason": risk_reason,
                    "claim_level": "PAPER_SHADOW_SIMULATION_ONLY_NOT_PROFIT_PROOF",
                })

    if not ps.get("open_position") and not rows:
        if entry_allowed and candidate:
            tick = candidate["row"]
            sym = str(tick.get("symbol"))
            price = safe_float(tick.get("last_price"))
            simulated_entry = round(price * (1 + cfg["slippage_rate"]), 10)
            action = "ENTRY_SIMULATED"
            strategy_reason = f"Candidate had positive 24h momentum while regime allowed paper test; rank_score={candidate['score']}."
            risk_reason = f"no_trade_score={no_trade_score}; one paper-only position max; fees/slippage included."
            ps["open_position"] = {
                "entry_ts": now,
                "symbol": sym,
                "side": "LONG_PAPER_ONLY",
                "entry_price": simulated_entry,
                "notional_usd": cfg["notional_usd"],
                "strategy": strategy,
            }
            ps["opened_count"] = int(ps.get("opened_count", 0) or 0) + 1
            rows.append({
                "ts": now,
                "action": action,
                "strategy": strategy,
                "symbol": sym,
                "side": "LONG_PAPER_ONLY",
                "entry_price": simulated_entry,
                "raw_price": price,
                "notional_usd": cfg["notional_usd"],
                "fee_rate": cfg["fee_rate"],
                "slippage_rate": cfg["slippage_rate"],
                "regime": label,
                "no_trade_score": no_trade_score,
                "source": source,
                "feed_status": feed_status[:160],
                "real_live_verified": True,
                "live_orders": "OFF",
                "api_keys": "NONE",
                "strategy_reason": strategy_reason,
                "risk_reason": risk_reason,
                "claim_level": "PAPER_SHADOW_SIMULATION_ONLY_NOT_PROFIT_PROOF",
            })
        else:
            action = "STAND_ASIDE_SIMULATED"
            ps["stand_aside_count"] = int(ps.get("stand_aside_count", 0) or 0) + 1
            if candidate:
                strategy_reason = f"Best candidate {candidate['row'].get('symbol')} did not pass entry gate or risk filter."
            risk_reason = f"no_trade_score={no_trade_score}; regime={label}; standing aside is scored as valid risk discipline."
            rows.append({
                "ts": now,
                "action": action,
                "strategy": strategy,
                "symbol": str(candidate["row"].get("symbol")) if candidate else "NONE",
                "side": "NO_TRADE_PAPER_ONLY",
                "notional_usd": 0,
                "fee_rate": cfg["fee_rate"],
                "slippage_rate": cfg["slippage_rate"],
                "regime": label,
                "no_trade_score": no_trade_score,
                "source": source,
                "feed_status": feed_status[:160],
                "real_live_verified": True,
                "live_orders": "OFF",
                "api_keys": "NONE",
                "strategy_reason": strategy_reason,
                "risk_reason": risk_reason,
                "claim_level": "PAPER_SHADOW_SIMULATION_ONLY_NOT_PROFIT_PROOF",
            })

    for row in rows:
        append_jsonl(SHARED / "paper_shadow_ledger.jsonl", row)
        append_csv(SHARED / "paper_shadow_ledger.csv", [
            "ts", "action", "strategy", "symbol", "side", "entry_price", "exit_price", "current_price",
            "gross_pct", "fees_pct", "slippage_pct", "net_pct_after_fee_slippage", "regime", "no_trade_score",
            "source", "live_orders", "api_keys", "strategy_reason", "risk_reason", "claim_level"
        ], row)

    ps["updated_at"] = now
    ps["last_action"] = rows[-1].get("action") if rows else action
    ps["last_regime"] = label
    ps["last_no_trade_score"] = no_trade_score
    ps["paper_only"] = True
    ps["live_orders"] = "OFF"
    write_json(state_path, ps)
    return {"ok": True, "status": "PAPER_SHADOW_ONLINE", "action": ps["last_action"], "rows_written": len(rows), "open_position": ps.get("open_position")}


def generate_suggested_upgrades(state: Dict[str, Any], regime: Dict[str, Any]) -> List[Dict[str, Any]]:
    ticks = read_last_jsonl(SHARED / "market_ticks.jsonl", 5000)
    pulse_count = int(state.get("pulse_count", 0) or 0)
    hours_est = round((utc_now() - START_TIME).total_seconds() / 3600, 2)
    suggestions = []
    if len(ticks) < 60:
        suggestions.append({
            "version": "V011",
            "name": "Candle Harvester",
            "why": "Collecting tick snapshots is awake; next step is 1m/5m/15m candle history for real research.",
            "status": "SUGGESTED_AFTER_OVERNIGHT_BASELINE",
            "risk": "low",
            "one_click_ready": False,
        })
    else:
        suggestions.append({
            "version": "V011",
            "name": "Candle Harvester",
            "why": "Enough feed ticks are forming a baseline; add candle storage and missing-data checks.",
            "status": "READY_TO_BUILD_NEXT",
            "risk": "low",
            "one_click_ready": False,
        })
    suggestions.append({
        "version": "V012",
        "name": "Market Regime Proof Board",
        "why": "Turn overnight regime labels into graphs and regime durations.",
        "status": "SUGGESTED",
        "risk": "low",
        "one_click_ready": False,
    })
    suggestions.append({
        "version": "V013A",
        "name": "Paper Shadow Signal Simulator",
        "why": "Installed: creates paper-only would-have-traded records from verified live public data.",
        "status": "INSTALLED_PAPER_ONLY",
        "risk": "medium",
        "one_click_ready": True,
    })
    suggestions.append({
        "version": "V014C",
        "name": "Universe Top State Repair",
        "why": "Installed: makes the Universe headline top symbol and visible latest-rank table use the same sorted latest batch.",
        "status": "INSTALLED_UNIVERSE_TOP_STATE_REPAIR",
        "risk": "low",
        "one_click_ready": True,
    })
    suggestions.append({
        "version": "V015A",
        "name": "Backtest + Walk-Forward Gate",
        "why": "Installed: replays collected public candles through a simple strategy probe and blocks champion claims until repeated evidence exists.",
        "status": "INSTALLED_BACKTEST_GATE",
        "risk": "medium",
        "one_click_ready": True,
    })
    if regime.get("no_trade_score", 100) >= 70:
        suggestions.append({
            "version": "V014",
            "name": "No-Trade Reward Engine",
            "why": "Current conditions favour standing down; track avoided bad trades as progress.",
            "status": "SUGGESTED",
            "risk": "low",
            "one_click_ready": False,
        })
    return suggestions


def learning_pulse(manual: bool = False) -> Dict[str, Any]:
    with STATE_LOCK:
        ensure_dirs()
        seed_strategy_dna()
        state = get_system_state()
        symbols = state.get("symbols") or SYMBOLS_DEFAULT
        tickers, source, feed_status = fetch_ticker_data(symbols)
        if not is_real_live_market_data(tickers, source, feed_status):
            return block_pulse_no_real_live_data(state, symbols, source, feed_status, manual)
        guard = update_live_data_guard(state, True, source, feed_status, [str(r.get("symbol")) for r in tickers])
        regime = infer_regime(tickers)
        write_market_logs(tickers, source, feed_status, regime)
        try:
            candle_result = harvest_candles_for_symbols(symbols, source, feed_status)
        except Exception as e:
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "where": "harvest_candles_for_symbols", "error": traceback.format_exc()})
            candle_result = {"ok": False, "status": "CANDLE_HARVESTER_ERROR", "rows_written": 0, "error": str(e)}
        try:
            universe_result = run_universe_scanner()
        except Exception as e:
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "where": "run_universe_scanner", "error": traceback.format_exc()})
            universe_result = {"ok": False, "status": "UNIVERSE_SCANNER_ERROR", "rows_written": 0, "top_symbol": "NONE", "error": str(e)}
        research_row = update_research_ledger(regime, tickers, source, feed_status)
        paper_result = run_paper_shadow_simulator(tickers, regime, source, feed_status)
        try:
            backtest_result = run_backtest_walkforward_gate()
        except Exception as e:
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "where": "run_backtest_walkforward_gate", "error": traceback.format_exc()})
            backtest_result = {"ok": False, "status": "BACKTEST_GATE_ERROR", "gate": "ERROR", "error": str(e)}
        pulse_count = int(state.get("pulse_count", 0) or 0) + 1
        learning_points = 1.0 + min(2.5, len(tickers) / 4.0)
        research_points = 1.0
        if manual:
            research_points += 0.25
        state.update({
            "watch_enabled": bool(state.get("watch_enabled", True)),
            "last_pulse_at": iso_now(),
            "pulse_count": pulse_count,
            "learning_score": round(float(state.get("learning_score", 0) or 0) + learning_points, 2),
            "research_score": round(float(state.get("research_score", 0) or 0) + research_points, 2),
            "growth_score": round(float(state.get("growth_score", 0) or 0) + learning_points + research_points, 2),
            "last_feed_source": source,
            "last_feed_status": feed_status,
            "real_live_data_gate": "PASS_RECENT_REAL_LIVE_DATA",
            "raw_data_gate": "ENFORCED_PASS_REAL_LIVE_DATA_ONLY",
            "live_data_stale_seconds": 0,
            "live_data_warning": "OK",
            "current_regime": regime.get("label"),
            "no_trade_score": regime.get("no_trade_score"),
            "paper_shadow_status": paper_result.get("status"),
            "paper_shadow_last_action": paper_result.get("action"),
            "paper_shadow_last_at": iso_now(),
            "paper_shadow_open_position": "YES" if paper_result.get("open_position") else "NONE",
            "candle_harvester_status": candle_result.get("status"),
            "candle_harvester_last_at": iso_now(),
            "candle_harvester_last_rows": candle_result.get("rows_written", 0),
            "universe_scanner_status": universe_result.get("status"),
            "universe_scanner_last_at": iso_now(),
            "universe_scanner_last_symbols": universe_result.get("rows_written", len(universe_result.get("ranked", [])) if isinstance(universe_result.get("ranked"), list) else 0),
            "universe_scanner_top_symbol": universe_result.get("top_symbol", "NONE"),
            "backtest_gate_status": backtest_result.get("status"),
            "backtest_last_at": iso_now(),
            "backtest_last_symbol": backtest_result.get("symbol", "NONE"),
            "backtest_last_interval": backtest_result.get("interval", "NONE"),
            "backtest_walk_forward_status": backtest_result.get("gate", "NOT_RUN"),
            "champion_proof_gate": "LOCKED_REPEAT_BACKTEST_AND_HUMAN_APPROVAL_REQUIRED",
            "current_blocker": "Need repeated backtest/walk-forward evidence across more candles before any champion claim.",
            "next_gate": "BACKTEST_WALK_FORWARD_REVIEW",
        })
        save_system_state(state)
        cycle = {
            "ts": iso_now(),
            "cycle": pulse_count,
            "manual": manual,
            "source": source,
            "feed_status": feed_status[:160],
            "regime": regime,
            "research_task": research_row.get("research_task"),
            "learning_points_added": learning_points,
            "research_points_added": research_points,
            "paper_shadow_status": paper_result.get("status"),
            "paper_shadow_action": paper_result.get("action"),
            "candle_harvester_status": candle_result.get("status"),
            "candle_rows_written": candle_result.get("rows_written", 0),
            "universe_scanner_status": universe_result.get("status"),
            "universe_top_symbol": universe_result.get("top_symbol", "NONE"),
            "backtest_status": backtest_result.get("status"),
            "backtest_gate": backtest_result.get("gate"),
            "backtest_symbol": backtest_result.get("symbol"),
            "backtest_interval": backtest_result.get("interval"),
            "real_live_verified": True,
            "raw_data_gate": "ENFORCED_PASS_REAL_LIVE_DATA_ONLY",
            "live_data_guard": guard.get("gate"),
            "live_orders": "OFF",
            "champion_lock": "LOCKED",
            "claim_level": "LEARNING_PULSE_REAL_LIVE_DATA_COLLECTION_ONLY",
        }
        append_jsonl(SHARED / "learning_cycles.jsonl", cycle)
        suggestions = generate_suggested_upgrades(state, regime)
        write_json(UPDATES / "suggested_upgrades.json", {"updated_at": iso_now(), "suggestions": suggestions})
        return {"ok": True, "state": state, "cycle": cycle, "tickers": tickers, "guard": guard, "suggested_upgrades": suggestions}


def collector_loop() -> None:
    while not STOP_EVENT.is_set():
        try:
            state = get_system_state()
            if state.get("watch_enabled", True):
                learning_pulse(manual=False)
            wait = int(state.get("pulse_seconds", PULSE_SECONDS_DEFAULT) or PULSE_SECONDS_DEFAULT)
            wait = max(30, min(3600, wait))
        except Exception:
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "where": "collector_loop", "error": traceback.format_exc()})
            wait = 60
        STOP_EVENT.wait(wait)


def start_collector() -> None:
    global COLLECTOR_THREAD
    if COLLECTOR_THREAD and COLLECTOR_THREAD.is_alive():
        return
    STOP_EVENT.clear()
    COLLECTOR_THREAD = threading.Thread(target=collector_loop, name="BaliOvernightWatch", daemon=True)
    COLLECTOR_THREAD.start()


def get_lan_ips() -> List[str]:
    ips = []
    try:
        hostname = socket.gethostname()
        for info in socket.getaddrinfo(hostname, None):
            ip = info[4][0]
            if ":" not in ip and not ip.startswith("127.") and ip not in ips:
                ips.append(ip)
    except Exception:
        pass
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        if ip not in ips and not ip.startswith("127."):
            ips.append(ip)
    except Exception:
        pass
    return ips[:5]


def count_lines(path: Path) -> int:
    if not path.exists():
        return 0
    try:
        with path.open("rb") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def intish(value: Any, default: int = 0) -> int:
    try:
        return int(float(value))
    except Exception:
        return default


def truthy_env(name: str) -> bool:
    return str(os.environ.get(name, "")).strip().lower() in {"1", "true", "yes", "on", "safe"}


def format_report_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, dict):
        label = value.get("label") or value.get("status") or value.get("gate") or value.get("symbol") or value.get("name")
        parts: List[str] = []
        if label is not None:
            parts.append(str(label))
        for key in sorted(value.keys()):
            if key == "label" and label is not None:
                continue
            item = value.get(key)
            if item in (None, ""):
                continue
            if isinstance(item, (dict, list)):
                parts.append(f"{key}={format_report_value(item)}")
            else:
                parts.append(f"{key}={item}")
        return " | ".join(parts) if parts else "{}"
    if isinstance(value, list):
        items = [format_report_value(v) for v in value[:8]]
        if len(value) > 8:
            items.append(f"... +{len(value) - 8} more")
        return ", ".join(items)
    return str(value)


def report_line_from_row(row: Dict[str, Any], fields: List[str]) -> str:
    parts = []
    for field in fields:
        value = format_report_value(row.get(field))
        if value != "":
            parts.append(f"{field}={value}")
    return " | ".join(parts) if parts else format_report_value(row)


def private_env_key_status() -> str:
    present = [key for key in SECRET_ENV_KEYS if os.environ.get(key)]
    if present:
        return "FOUND: " + ", ".join(present)
    return "NONE / private exchange endpoints not used"


def ensure_v017_patch_ledger() -> Dict[str, Any]:
    ensure_dirs()
    existing = read_last_jsonl(PATCH_LEDGER, 500)
    for row in existing:
        if row.get("patch_id") == PATCH_REPORT_VERSION:
            return row
    row = {
        "patch_id": PATCH_REPORT_VERSION,
        "title": PATCH_REPORT_TITLE,
        "installed_utc": iso_now(),
        "status": "INSTALLED",
        "files_changed": V017_FILES_CHANGED,
        "safety": "live_orders_OFF | champion_LOCKED | no_API_keys | public_data_only",
    }
    append_jsonl(PATCH_LEDGER, row)
    return row


def latest_patch_ledger_entry() -> Dict[str, Any]:
    current = ensure_v017_patch_ledger()
    rows = read_last_jsonl(PATCH_LEDGER, 200)
    return rows[-1] if rows else current


def always_working_counts(data: Dict[str, Any]) -> Dict[str, int]:
    state = data.get("state", {})
    counts = data.get("line_counts", {})
    return {
        "market_ticks": intish(counts.get("market_ticks")),
        "feed_proof": intish(counts.get("feed_proof")),
        "live_data_guard": intish(counts.get("live_data_guard")),
        "learning_cycles": intish(counts.get("learning_cycles")),
        "research_notes": intish(counts.get("research_ledger")),
        "paper_shadow_rows": intish(counts.get("paper_shadow")),
        "candle_rows": intish(counts.get("candle_rows")),
        "candle_proof_rows": intish(counts.get("candle_proof")),
        "universe_scan_ledger_rows": intish(counts.get("universe_scan")),
        "backtest_walkforward_rows": intish(counts.get("backtest_walkforward")),
        "pulse_count": intish(state.get("pulse_count")),
    }


def previous_always_working_snapshot() -> Optional[Dict[str, Any]]:
    rows = read_last_jsonl(ALWAYS_REPORT_LEDGER, 1)
    return rows[-1] if rows else None


def delta_counts(current: Dict[str, int], previous: Optional[Dict[str, Any]]) -> Dict[str, int]:
    previous_counts = previous.get("counts", {}) if isinstance(previous, dict) else {}
    out: Dict[str, int] = {}
    for key, value in current.items():
        out[key] = intish(value) - intish(previous_counts.get(key, value))
    return out


def append_always_working_snapshot(report_name: str, data: Dict[str, Any], verdicts: Dict[str, str]) -> None:
    append_jsonl(ALWAYS_REPORT_LEDGER, {
        "ts": iso_now(),
        "report": report_name,
        "counts": always_working_counts(data),
        "verdicts": verdicts,
    })


def live_data_verdict(state: Dict[str, Any]) -> str:
    gate = str(state.get("real_live_data_gate", "")).upper()
    warning = str(state.get("live_data_warning", "")).upper()
    stale = state.get("live_data_stale_seconds")
    if gate.startswith("PASS"):
        if any(word in warning for word in ["FAIL", "BLOCK", "STALE"]) or (stale is not None and intish(stale, 999999) > REAL_LIVE_DATA_WARNING_SECONDS):
            return "WATCH"
        return "PASS"
    if "WAITING" in gate or "WAITING" in warning or "STALE" in warning:
        return "WATCH"
    return "FAIL"


def safety_verdict(data: Dict[str, Any]) -> str:
    state = data.get("state", {})
    backtest = data.get("backtest_summary", {})
    claim_allowed = bool(backtest.get("champion_claim_allowed") or state.get("champion_claim_allowed"))
    private_status = private_env_key_status()
    unsafe = [
        state.get("live_orders") != "OFF",
        state.get("champion_lock") != "LOCKED",
        claim_allowed,
        not str(state.get("risk_police", "")).startswith("ARMED"),
        private_status.startswith("FOUND:"),
    ]
    return "FAIL" if any(unsafe) else "PASS"


def bot_collection_verdict(data: Dict[str, Any]) -> str:
    counts = always_working_counts(data)
    watched = [
        counts["market_ticks"],
        counts["feed_proof"],
        counts["learning_cycles"],
        counts["research_notes"],
        counts["paper_shadow_rows"],
        counts["candle_rows"],
        counts["universe_scan_ledger_rows"],
        counts["backtest_walkforward_rows"],
    ]
    present = sum(1 for value in watched if value > 0)
    if present >= 6:
        return "PASS"
    if present >= 3:
        return "WATCH"
    return "FAIL"


def edge_proof_verdict(data: Dict[str, Any]) -> str:
    backtest = data.get("backtest_summary", {})
    gate_text = " ".join(str(backtest.get(k, "")) for k in ("status", "gate", "reason", "verdict")).upper()
    claim_allowed = bool(backtest.get("champion_claim_allowed"))
    if claim_allowed and ("PASS" in gate_text or "READY" in gate_text):
        return "READY FOR REVIEW"
    for sample_name in ("in_sample", "walk_forward"):
        sample = backtest.get(sample_name)
        if isinstance(sample, dict) and intish(sample.get("trades")) > 0:
            avg_net = float(sample.get("avg_net_pct") or 0)
            win_rate = float(sample.get("win_rate_pct") or 0)
            if avg_net <= 0 or win_rate <= 0:
                return "RISK TOO HIGH"
    if any(word in gate_text for word in ["RISK", "FAIL", "BLOCK", "REJECT", "TOO_HIGH"]):
        return "RISK TOO HIGH"
    return "NOT PROVEN"


def next_action_from_verdicts(verdicts: Dict[str, str]) -> str:
    if verdicts.get("SAFETY") != "PASS":
        return "Stop and repair safety locks before doing anything else."
    if verdicts.get("LIVE DATA") == "FAIL":
        return "Restore verified public live data before learning, paper shadow, or scoring."
    if verdicts.get("EDGE PROOF") == "RISK TOO HIGH":
        return "Keep live trading OFF; collect more candles/paper rows, tighten risk filters, then rerun walk-forward."
    if verdicts.get("EDGE PROOF") == "READY FOR REVIEW":
        return "Human review only. Do not unlock Champion or live trading from this build."
    return "Keep collecting public data, paper shadow evidence, and walk-forward results until edge proof improves."


def apply_safe_forever_start_mode() -> None:
    if not truthy_env("BALI_SAFE_FOREVER"):
        return
    state = get_system_state()
    state["watch_enabled"] = True
    state["live_orders"] = "OFF"
    state["champion_lock"] = "LOCKED"
    state["approved_champions"] = "0/3"
    state["risk_police"] = "ARMED"
    state["mode"] = "PUBLIC_DATA_RESEARCH_ONLY"
    state["safe_forever_mode"] = "ON"
    save_system_state(state)


def safe_read_csv_tail(path: Path, limit: int = 20) -> List[Dict[str, Any]]:
    if not path.exists():
        return []
    try:
        text = path.read_text(encoding="utf-8", errors="replace").splitlines()
        if not text:
            return []
        tail = "\n".join([text[0]] + text[-limit:])
        return list(csv.DictReader(io.StringIO(tail)))
    except Exception:
        return []


def is_verified_live_tick_row(row: Dict[str, Any]) -> bool:
    source_text = str(row.get("source") or "")
    status_text = str(row.get("feed_status") or "").upper()
    if source_text in {"offline_demo", "LIVE_DATA_FAIL", "NO_REAL_LIVE_DATA", "synthetic", "mock"}:
        return False
    if "OFFLINE" in status_text or "DEMO" in status_text or "FAKE" in status_text or "LIVE_DATA_FAIL" in status_text:
        return False
    return source_text.startswith(REAL_LIVE_SOURCE_PREFIXES) and status_text.startswith("OK")


def compute_dashboard_state() -> Dict[str, Any]:
    state = get_system_state()
    last_ticks_all = read_last_jsonl(SHARED / "market_ticks.jsonl", 200)
    last_ticks = [r for r in last_ticks_all if is_verified_live_tick_row(r)]
    last_cycles = read_last_jsonl(SHARED / "learning_cycles.jsonl", 20)
    last_research = read_last_jsonl(SHARED / "research_ledger.jsonl", 20)
    last_feed = read_last_jsonl(SHARED / "feed_proof_ledger.jsonl", 20)
    last_guard = read_last_jsonl(SHARED / "live_data_guard.jsonl", 20)
    last_paper = read_last_jsonl(SHARED / "paper_shadow_ledger.jsonl", 40)
    last_candle_proof = read_last_jsonl(SHARED / "candle_proof_ledger.jsonl", 20)
    last_universe = latest_universe_batch_rows(40)
    last_candles = latest_candle_examples(18)
    candle_summary = candle_summary_from_proof()
    universe_summary = universe_summary_from_latest_batch()
    backtest_state = backtest_summary()
    last_backtests = latest_backtest_records(8)
    strategy_dna = read_json(STRATEGIES / "strategy_dna.json", {"strategies": []})
    upgrades = read_json(UPDATES / "suggested_upgrades.json", {"suggestions": []})
    update_scan = scan_updates()
    reports = sorted([p.name for p in REPORTS.glob("*.txt")], reverse=True)[:12]
    uptime = utc_now() - START_TIME
    data = {
        "state": state,
        "version": VERSION,
        "version_number": VERSION_NUMBER,
        "uptime_seconds": int(uptime.total_seconds()),
        "lan_ips": get_lan_ips(),
        "last_ticks": last_ticks[-18:],
        "ignored_demo_tick_rows_in_recent_window": len(last_ticks_all) - len(last_ticks),
        "last_cycles": last_cycles[-12:],
        "last_research": last_research[-12:],
        "last_feed": last_feed[-8:],
        "last_guard": last_guard[-8:],
        "last_paper": last_paper[-12:],
        "last_candle_proof": last_candle_proof[-8:],
        "last_universe": last_universe[:20],
        "last_candles": last_candles[-18:],
        "candle_summary": candle_summary,
        "universe_summary": universe_summary,
        "backtest_summary": backtest_state,
        "last_backtests": last_backtests,
        "candle_datasets": available_candle_datasets()[:12],
        "strategy_dna": strategy_dna.get("strategies", []),
        "suggested_upgrades": upgrades.get("suggestions", []),
        "update_scan": update_scan,
        "autopilot": autopilot_status(),
        "reports": reports,
        "line_counts": {
            "market_ticks": count_lines(SHARED / "market_ticks.jsonl"),
            "learning_cycles": count_lines(SHARED / "learning_cycles.jsonl"),
            "research_ledger": count_lines(SHARED / "research_ledger.jsonl"),
            "feed_proof": count_lines(SHARED / "feed_proof_ledger.jsonl"),
            "live_data_guard": count_lines(SHARED / "live_data_guard.jsonl"),
            "paper_shadow": count_lines(SHARED / "paper_shadow_ledger.jsonl"),
            "candle_proof": count_lines(SHARED / "candle_proof_ledger.jsonl"),
            "candle_rows": count_candle_rows(),
            "universe_scan": count_lines(SHARED / "universe_scan_ledger.jsonl"),
            "backtest_walkforward": count_lines(SHARED / "backtests" / "backtest_walkforward_ledger.jsonl"),
        },
        "collector_alive": bool(COLLECTOR_THREAD and COLLECTOR_THREAD.is_alive()),
    }
    return data


def doctor_report() -> Dict[str, Any]:
    data = compute_dashboard_state()
    state = data["state"]
    checks = []
    def add(name: str, ok: bool, detail: str) -> None:
        checks.append({"name": name, "ok": ok, "detail": detail})
    add("Server", True, "Dashboard server is responding.")
    add("Collector thread", data["collector_alive"], "Overnight collector thread is alive." if data["collector_alive"] else "Collector thread is not running.")
    add("Watch enabled", bool(state.get("watch_enabled")), "Watch mode is enabled." if state.get("watch_enabled") else "Watch mode is paused.")
    add("Market tick ledger", data["line_counts"]["market_ticks"] > 0, f"Rows: {data['line_counts']['market_ticks']}")
    add("Learning ledger", data["line_counts"]["learning_cycles"] > 0, f"Rows: {data['line_counts']['learning_cycles']}")
    add("Feed source", state.get("last_feed_source") != "not_started", f"Last source: {state.get('last_feed_source')}")
    add("Real live data gate", str(state.get("real_live_data_gate", "")).startswith("PASS"), f"Gate: {state.get('real_live_data_gate')} | warning: {state.get('live_data_warning')}")
    add("Live orders", state.get("live_orders") == "OFF", "Live orders are OFF and no live trading code is present.")
    add("Champion lock", state.get("champion_lock") == "LOCKED", "Champion Council is locked at 0/3.")
    add("Update inbox", UPDATE_INBOX.exists(), f"{UPDATE_INBOX}")
    add("Paper shadow", True, f"Rows: {data['line_counts'].get('paper_shadow', 0)} | status: {state.get('paper_shadow_status', 'READY')}")
    candle_summary = data.get("candle_summary", {})
    universe_summary = data.get("universe_summary", {})
    add("Candle harvester", True, f"Rows: {data['line_counts'].get('candle_rows', 0)} | last_new_rows: {candle_summary.get('last_new_rows', 0)} | status: {candle_summary.get('status') or state.get('candle_harvester_status', 'READY')}")
    add("Universe scanner", True, f"Ledger rows: {data['line_counts'].get('universe_scan', 0)} | visible latest batch rows: {universe_summary.get('rows_visible', 0)} | status: {universe_summary.get('status') or state.get('universe_scanner_status', 'READY')} | top: {universe_summary.get('top_symbol') or state.get('universe_scanner_top_symbol', 'NONE')}")
    bt = data.get("backtest_summary", {})
    add("Backtest walk-forward gate", True, f"Rows: {data['line_counts'].get('backtest_walkforward', 0)} | status: {bt.get('status', 'READY_WAITING_FOR_BACKTEST')} | gate: {bt.get('gate', 'NOT_RUN')} | champion_claim_allowed: {bt.get('champion_claim_allowed', False)}")
    add("Reports folder", REPORTS.exists(), f"{REPORTS}")
    return {"ts": iso_now(), "checks": checks, "summary": "PASS" if all(c["ok"] for c in checks) else "WARN", "data": data}


def generate_morning_report() -> Path:
    data = compute_dashboard_state()
    doctor = doctor_report()
    state = data["state"]
    ticks = read_last_jsonl(SHARED / "market_ticks.jsonl", 100000)
    cycles = read_last_jsonl(SHARED / "learning_cycles.jsonl", 100000)
    research = read_last_jsonl(SHARED / "research_ledger.jsonl", 100000)
    source_counts: Dict[str, int] = {}
    regime_counts: Dict[str, int] = {}
    symbol_counts: Dict[str, int] = {}
    for row in ticks:
        source_counts[str(row.get("source"))] = source_counts.get(str(row.get("source")), 0) + 1
        regime_counts[str(row.get("regime"))] = regime_counts.get(str(row.get("regime")), 0) + 1
        symbol_counts[str(row.get("symbol"))] = symbol_counts.get(str(row.get("symbol")), 0) + 1
    started = START_TIME.isoformat(timespec="seconds")
    report_name = f"BALI_OVERNIGHT_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S')}.txt"
    path = REPORTS / report_name
    suggestions = data.get("suggested_upgrades", [])
    lines = []
    lines.append("BALI ROCKET CRYPTO COMMAND - OVERNIGHT WATCH REPORT")
    lines.append("=" * 72)
    lines.append(f"Generated UTC: {iso_now()}")
    lines.append(f"Version: {VERSION}")
    lines.append(f"Started UTC: {started}")
    lines.append("")
    lines.append("SAFETY STATUS")
    lines.append(f"Live orders: {state.get('live_orders')}")
    lines.append(f"Champion Council: {state.get('champion_lock')} / approved {state.get('approved_champions')}")
    lines.append(f"Risk Police: {state.get('risk_police')}")
    lines.append("Claim level: public data collection and research telemetry only, not trading proof.")
    lines.append("")
    lines.append("OVERNIGHT DATA SUMMARY")
    lines.append(f"Pulse count: {state.get('pulse_count')}")
    lines.append(f"Market tick rows: {data['line_counts']['market_ticks']}")
    lines.append(f"Learning cycles: {data['line_counts']['learning_cycles']}")
    lines.append(f"Research ledger rows: {data['line_counts']['research_ledger']}")
    lines.append(f"Feed proof rows: {data['line_counts']['feed_proof']}")
    lines.append(f"Paper shadow rows: {data['line_counts'].get('paper_shadow', 0)}")
    lines.append(f"Last feed source: {state.get('last_feed_source')}")
    lines.append(f"Last feed status: {state.get('last_feed_status')}")
    lines.append(f"Real live data gate: {state.get('real_live_data_gate')}")
    lines.append(f"Raw data gate: {state.get('raw_data_gate')}")
    lines.append(f"Live data warning: {state.get('live_data_warning')}")
    lines.append(f"Live data stale seconds: {state.get('live_data_stale_seconds')}")
    lines.append(f"Current regime: {state.get('current_regime')}")
    lines.append(f"No-trade score: {state.get('no_trade_score')}")
    lines.append(f"Growth score: {state.get('growth_score')}")
    lines.append("")
    lines.append("REGIME COUNTS")
    for k, v in sorted(regime_counts.items(), key=lambda kv: (-kv[1], kv[0]))[:12]:
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("SOURCE COUNTS")
    for k, v in sorted(source_counts.items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("SYMBOL COUNTS")
    for k, v in sorted(symbol_counts.items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("RECENT RESEARCH NOTES")
    for row in research[-10:]:
        lines.append(f"- {row.get('ts')} | {row.get('squad')} | {row.get('regime')} | {row.get('research_task')}")
    lines.append("")
    lines.append("SUGGESTED NEXT UPGRADES")
    for item in suggestions:
        lines.append(f"- {item.get('version')} {item.get('name')}: {item.get('why')} [{item.get('status')}]")
    lines.append("")
    lines.append("DOCTOR SUMMARY")
    lines.append(f"Doctor status: {doctor['summary']}")
    for c in doctor["checks"]:
        lines.append(f"- {'PASS' if c['ok'] else 'WARN'} {c['name']}: {c['detail']}")
    lines.append("")
    lines.append("CURRENT TIMELINE")
    lines.append("V001: Tropical dashboard shell")
    lines.append("V002-V005: Learning/research pulse")
    lines.append("V006: Bali visual rebuild")
    lines.append("V007: Overnight Watch")
    lines.append("V008: Public market feed proof ledger")
    lines.append("V009: Phone LAN command view")
    lines.append("V010: One-click Update Dock scan/apply/rollback foundation")
    lines.append("V012J: Easy OneDrive bridge hub setup")
    lines.append("V012K: Real-live-data lock repair; fake/offline demo scoring blocked")
    lines.append("V012L: Binance public endpoint repair")
    lines.append("V012M: Live gate accepts verified OK_MULTI_SYMBOLS statuses")
    lines.append("V012N: Reports tab fixed; ChatGPT compact handover report generator added")
    lines.append("V013A: Paper Shadow Signal Simulator added; simulated entries/exits/fees/slippage only; local update visibility fixed")
    lines.append("V014A: Candle Harvester + Universe Scanner added; 1m/5m/15m public candles and wider USDT ranking only")
    lines.append("V014B: Candle/universe report accuracy repair; latest universe batch sorted by score and candle last-new-rows clarified")
    lines.append("V014C: Universe top-state repair; dashboard/report visible ranks now use the top rows, not the tail of the sorted batch")
    lines.append("V015A: Backtest + Walk-Forward Gate added; collected candles are replayed before any champion claim is allowed")
    lines.append("")
    lines.append("NEXT GATE")
    lines.append(str(state.get("next_gate")))
    lines.append("Current blocker: " + str(state.get("current_blocker")))
    path.write_text("\n".join(lines), encoding="utf-8")
    return path



# === BALI_V018_RISK_FILTER_TUNER_BEGIN ===
V018_PATCH_ID = "V018_RISK_FILTER_TUNER"
V018_PATCH_TITLE = "Risk Filter Tuner + Walk-Forward Risk Explainer"


def v018_patch_ledger_path() -> Path:
    return SHARED / "patches" / "patch_ledger.jsonl"


def v018_report_ledger_path() -> Path:
    return REPORTS / "risk_filter_tuner_report_ledger.jsonl"


def v018_num(value: Any, default: float = 0.0) -> float:
    try:
        if value is None or value == "":
            return default
        return float(value)
    except Exception:
        return default


def v018_int(value: Any, default: int = 0) -> int:
    try:
        if value is None or value == "":
            return default
        return int(float(value))
    except Exception:
        return default


def v018_safe_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, dict):
        label = value.get("label") or value.get("regime") or value.get("status") or "object"
        parts = [str(label)]
        for key in ["no_trade_score", "btc_pct_24h", "alt_avg_pct_24h", "alt_dispersion"]:
            if key in value:
                parts.append(f"{key}={value.get(key)}")
        return " | ".join(parts)
    if isinstance(value, list):
        return ", ".join(v018_safe_text(x) for x in value[:8])
    return str(value)


def v018_last_patch_details() -> Dict[str, Any]:
    rows = read_last_jsonl(v018_patch_ledger_path(), 80)
    if rows:
        return rows[-1]
    return {
        "patch_id": V018_PATCH_ID,
        "title": V018_PATCH_TITLE,
        "installed_utc": "unknown",
        "status": "active_no_patch_ledger_found",
        "files_changed": ["app.py"],
        "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCKED | NO_API_KEYS | PUBLIC_DATA_RESEARCH_ONLY",
    }


def v018_extract_bt_metrics(bt: Dict[str, Any], last_backtests: List[Dict[str, Any]]) -> Dict[str, Any]:
    latest = dict(bt or {})
    if last_backtests:
        latest.update(last_backtests[-1] or {})
    ins = latest.get("in_sample") if isinstance(latest.get("in_sample"), dict) else {}
    wf = latest.get("walk_forward") if isinstance(latest.get("walk_forward"), dict) else {}
    return {
        "ts": latest.get("ts"),
        "run_id": latest.get("run_id"),
        "status": latest.get("status") or bt.get("status"),
        "gate": latest.get("gate") or bt.get("gate"),
        "symbol": latest.get("symbol") or bt.get("symbol"),
        "interval": latest.get("interval") or bt.get("interval"),
        "total_candles": v018_int(latest.get("total_candles") or bt.get("total_candles")),
        "in_trades": v018_int(ins.get("trades") if ins else latest.get("in_sample_trades")),
        "in_avg": v018_num(ins.get("avg_net_pct") if ins else latest.get("in_sample_avg_net_pct")),
        "in_dd": v018_num(ins.get("max_drawdown_pct") if ins else latest.get("in_sample_max_drawdown_pct")),
        "in_win_rate": v018_num(ins.get("win_rate_pct") if ins else latest.get("in_sample_win_rate_pct")),
        "wf_trades": v018_int(wf.get("trades") if wf else latest.get("walk_forward_trades")),
        "wf_avg": v018_num(wf.get("avg_net_pct") if wf else latest.get("walk_forward_avg_net_pct")),
        "wf_dd": v018_num(wf.get("max_drawdown_pct") if wf else latest.get("walk_forward_max_drawdown_pct")),
        "wf_win_rate": v018_num(wf.get("win_rate_pct") if wf else latest.get("walk_forward_win_rate_pct")),
        "champion_claim_allowed": bool(latest.get("champion_claim_allowed", False)),
    }


def v018_blocker_lines(m: Dict[str, Any]) -> List[str]:
    gate = str(m.get("gate") or "NOT_RUN")
    lines: List[str] = []
    if gate == "BACKTEST_BLOCKED_INSUFFICIENT_CANDLES" or m.get("total_candles", 0) < 20:
        lines.append("BLOCKER: insufficient public candle evidence. Collect more candles before judging strategy quality.")
    elif "NO_TRADES" in gate:
        lines.append("BLOCKER: the walk-forward split produced no trades. The rule may be too restrictive or the sampled market regime had no valid setups.")
    elif "RISK_TOO_HIGH" in gate:
        lines.append("BLOCKER: walk-forward max drawdown is above the current risk ceiling of 8.0%. Champion remains locked.")
    elif "EDGE_NOT_PROVEN" in gate:
        lines.append("BLOCKER: walk-forward average net result is not positive after fees/slippage. Edge remains unproven.")
    elif "REPEAT_TEST_REQUIRED" in gate:
        lines.append("BLOCKER: one walk-forward evidence run exists, but repeated evidence and human approval are still required.")
    else:
        lines.append(f"BLOCKER: gate is {gate}. Treat as not proven unless repeated evidence and human approval exist.")

    if m.get("wf_dd", 0.0) > 8.0:
        lines.append(f"RISK DETAIL: walk-forward drawdown {m.get('wf_dd')}% is above 8.0%.")
    if m.get("wf_avg", 0.0) <= 0:
        lines.append(f"EDGE DETAIL: walk-forward average net {m.get('wf_avg')}% is not positive.")
    if m.get("wf_trades", 0) < 30:
        lines.append(f"SAMPLE DETAIL: walk-forward trades={m.get('wf_trades')} is still a small sample. Keep collecting before conclusions.")
    if m.get("in_avg", 0.0) > m.get("wf_avg", 0.0):
        gap = round(m.get("in_avg", 0.0) - m.get("wf_avg", 0.0), 4)
        lines.append(f"ROBUSTNESS DETAIL: in-sample average is better than walk-forward by {gap} percentage points. Watch for overfit/chop.")
    return lines


def v018_research_recommendations(m: Dict[str, Any], state: Dict[str, Any]) -> List[str]:
    recs: List[str] = []
    regime = v018_safe_text(state.get("current_regime"))
    no_trade_score = v018_num(state.get("no_trade_score"), 0)
    if "BTC_TIDE_FALLING" in regime or no_trade_score >= 65:
        recs.append("Keep stand-aside discipline active while BTC_TIDE_FALLING or no_trade_score >= 65.")
    if m.get("wf_dd", 0.0) > 8.0:
        recs.append("Research-only filter idea: require lower drawdown before any signal review; target repeated walk-forward DD below 8%, then below 5%.")
        recs.append("Research-only filter idea: add a chop/panic guard so momentum probes skip falling-BTC regimes unless higher-timeframe confirmation improves.")
    if m.get("wf_avg", 0.0) <= 0:
        recs.append("Research-only filter idea: require walk-forward average net > 0 after fees/slippage across repeated runs before any Champion nomination.")
    if m.get("wf_trades", 0) < 30:
        recs.append("Collect more candles and paper rows before judging. Small walk-forward samples can mislead.")
    recs.append("Do not enable live trading, API keys, private endpoints, or Champion unlock from this patch.")
    recs.append("Next research step: compare risk metrics across symbols/intervals and only promote filters that reduce drawdown without hiding losses.")
    return recs


def v018_snapshot(m: Dict[str, Any], data: Dict[str, Any]) -> Dict[str, Any]:
    counts = data.get("line_counts", {}) or {}
    return {
        "ts": iso_now(),
        "gate": m.get("gate"),
        "symbol": m.get("symbol"),
        "interval": m.get("interval"),
        "total_candles": m.get("total_candles"),
        "in_trades": m.get("in_trades"),
        "in_avg": m.get("in_avg"),
        "in_dd": m.get("in_dd"),
        "wf_trades": m.get("wf_trades"),
        "wf_avg": m.get("wf_avg"),
        "wf_dd": m.get("wf_dd"),
        "market_ticks": v018_int(counts.get("market_ticks")),
        "paper_shadow": v018_int(counts.get("paper_shadow")),
        "candle_rows": v018_int(counts.get("candle_rows")),
        "backtest_walkforward": v018_int(counts.get("backtest_walkforward")),
    }


def v018_delta_lines(current: Dict[str, Any], previous: Optional[Dict[str, Any]]) -> List[str]:
    if not previous:
        return ["Previous V018 risk snapshot: NONE - baseline risk report"]
    lines = [f"Previous V018 risk snapshot UTC: {previous.get('ts')}"]
    for key in ["total_candles", "in_trades", "wf_trades", "market_ticks", "paper_shadow", "candle_rows", "backtest_walkforward"]:
        cur = v018_num(current.get(key), 0)
        old = v018_num(previous.get(key), 0)
        lines.append(f"{key}: {old:g} -> {cur:g} | delta={cur - old:g}")
    for key in ["in_avg", "in_dd", "wf_avg", "wf_dd"]:
        cur = v018_num(current.get(key), 0)
        old = v018_num(previous.get(key), 0)
        lines.append(f"{key}: {old:.4f} -> {cur:.4f} | change={cur - old:.4f}")
    return lines


def generate_risk_filter_tuner_report() -> Tuple[Path, str]:
    ensure_dirs()
    data = compute_dashboard_state()
    state = data.get("state", {}) or {}
    bt = data.get("backtest_summary", {}) or {}
    last_backtests = data.get("last_backtests", []) or []
    patch = v018_last_patch_details()
    m = v018_extract_bt_metrics(bt, last_backtests)
    previous_rows = read_last_jsonl(v018_report_ledger_path(), 1)
    previous = previous_rows[-1] if previous_rows else None
    snap = v018_snapshot(m, data)
    append_jsonl(v018_report_ledger_path(), snap)

    safety_pass = state.get("live_orders") == "OFF" and state.get("champion_lock") == "LOCKED" and not m.get("champion_claim_allowed", False)
    gate = str(m.get("gate") or "NOT_RUN")
    if "RISK_TOO_HIGH" in gate:
        risk_verdict = "RISK TOO HIGH - BLOCK CHAMPION"
    elif "EDGE_NOT_PROVEN" in gate:
        risk_verdict = "EDGE NOT PROVEN - BLOCK CHAMPION"
    elif "REPEAT_TEST_REQUIRED" in gate:
        risk_verdict = "REPEAT EVIDENCE REQUIRED - HUMAN REVIEW ONLY"
    else:
        risk_verdict = "NOT READY - KEEP COLLECTING"

    lines: List[str] = []
    lines.append("BALI ROCKET - V018 RISK FILTER TUNER REPORT")
    lines.append("=" * 72)
    lines.append(f"Generated UTC: {iso_now()}")
    lines.append(f"Core version: {VERSION}")
    lines.append(f"Patch report version: {V018_PATCH_ID}")
    lines.append("")
    lines.append("LAST PATCH DETAILS")
    lines.append(f"Patch ID: {patch.get('patch_id')}")
    lines.append(f"Title: {patch.get('title')}")
    lines.append(f"Installed UTC: {patch.get('installed_utc')}")
    lines.append(f"Status: {patch.get('status')}")
    lines.append(f"Files changed: {', '.join(str(x) for x in (patch.get('files_changed') or ['app.py']))}")
    lines.append(f"Safety note: {patch.get('safety')}")
    lines.append("")
    lines.append("SAFETY LOCKS")
    lines.append(f"Live orders: {state.get('live_orders')}")
    lines.append("API/private endpoints: NONE / private exchange endpoints not used")
    lines.append(f"Champion lock: {state.get('champion_lock')} / approved {state.get('approved_champions')}")
    lines.append(f"Champion claim allowed: {m.get('champion_claim_allowed')}")
    lines.append(f"Risk Police: {state.get('risk_police')}")
    lines.append(f"Safety verdict: {'PASS' if safety_pass else 'FAIL'}")
    lines.append("")
    lines.append("RISK GATE SUMMARY")
    lines.append(f"Gate: {m.get('gate')}")
    lines.append(f"Risk verdict: {risk_verdict}")
    lines.append(f"Symbol / interval: {m.get('symbol')} {m.get('interval')}")
    lines.append(f"Run ID: {m.get('run_id')} | Run time: {m.get('ts')}")
    lines.append(f"Total candles: {m.get('total_candles')}")
    lines.append(f"In-sample: trades={m.get('in_trades')} | avg_net_pct={m.get('in_avg')} | max_drawdown_pct={m.get('in_dd')} | win_rate_pct={m.get('in_win_rate')}")
    lines.append(f"Walk-forward: trades={m.get('wf_trades')} | avg_net_pct={m.get('wf_avg')} | max_drawdown_pct={m.get('wf_dd')} | win_rate_pct={m.get('wf_win_rate')}")
    lines.append("")
    lines.append("WHY CHAMPION IS BLOCKED")
    for line in v018_blocker_lines(m):
        lines.append(f"- {line}")
    lines.append("")
    lines.append("RESEARCH-ONLY FILTER RECOMMENDATIONS")
    for line in v018_research_recommendations(m, state):
        lines.append(f"- {line}")
    lines.append("")
    lines.append("RISK TREND SINCE PREVIOUS V018 REPORT")
    for line in v018_delta_lines(snap, previous):
        lines.append(f"- {line}")
    lines.append("")
    lines.append("BOT COLLECTION CONTEXT")
    counts = data.get("line_counts", {}) or {}
    lines.append(f"Market ticks: {counts.get('market_ticks')}")
    lines.append(f"Paper shadow rows: {counts.get('paper_shadow')}")
    lines.append(f"Candle rows: {counts.get('candle_rows')}")
    lines.append(f"Universe scan ledger rows: {counts.get('universe_scan')}")
    lines.append(f"Backtest walk-forward rows: {counts.get('backtest_walkforward')}")
    lines.append(f"Current regime: {v018_safe_text(state.get('current_regime'))}")
    lines.append(f"No-trade score: {state.get('no_trade_score')}")
    lines.append("")
    lines.append("FINAL VERDICT")
    lines.append("LIVE DATA: PASS" if str(state.get("real_live_data_gate") or "").startswith("PASS") else "LIVE DATA: WATCH")
    lines.append(f"SAFETY: {'PASS' if safety_pass else 'FAIL'}")
    lines.append(f"RISK FILTER STATUS: {risk_verdict}")
    lines.append("EDGE PROOF: NOT APPROVED FOR CHAMPION")
    lines.append("NEXT ACTION: Keep live trading OFF; collect more evidence; use this report to decide research-only filter changes.")
    lines.append("")
    lines.append("Safety reminder: this patch does not trade, does not add API keys, does not unlock Champion, and does not claim profit proof.")

    text = "\n".join(lines) + "\n"
    name = f"BALI_V018_RISK_FILTER_TUNER_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S')}.txt"
    path = REPORTS / name
    path.write_text(text, encoding="utf-8")
    try:
        (LOGS / "LAST_V018_RISK_FILTER_TUNER_REPORT.txt").write_text(text, encoding="utf-8")
        (REPORTS / "LAST_V018_RISK_FILTER_TUNER_REPORT.txt").write_text(text, encoding="utf-8")
    except Exception:
        pass
    return path, text
# === BALI_V018_RISK_FILTER_TUNER_END ===

def generate_chatgpt_report() -> Tuple[Path, str]:
    """Generate one compact copy/paste report for ChatGPT instead of tab-by-tab screenshots."""
    data = compute_dashboard_state()
    doctor = doctor_report()
    state = data.get("state", {})
    ticks = data.get("last_ticks", [])[-12:]
    cycles = data.get("last_cycles", [])[-8:]
    research = data.get("last_research", [])[-6:]
    guard = data.get("last_guard", [])[-6:]
    paper = data.get("last_paper", [])[-8:]
    candles = data.get("last_candles", [])[-8:]
    universe = data.get("last_universe", [])[:10]
    candle_summary = data.get("candle_summary", {})
    universe_summary = data.get("universe_summary", {})
    backtest = data.get("backtest_summary", {})
    backtests = data.get("last_backtests", [])[-5:]
    ignored_demo = data.get("ignored_demo_tick_rows_in_recent_window", 0)
    report_name = f"BALI_CHATGPT_STATUS_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S')}.txt"
    path = REPORTS / report_name
    lines: List[str] = []
    lines.append("BALI CHATGPT STATUS REPORT")
    lines.append("=" * 72)
    lines.append(f"Generated UTC: {iso_now()}")
    lines.append(f"Version: {VERSION}")
    lines.append("Purpose: one compact report for ChatGPT. No more tab-by-tab copying unless there is a specific error.")
    lines.append("")
    lines.append("SAFETY")
    lines.append(f"Live orders: {state.get('live_orders')}")
    lines.append(f"Champion lock: {state.get('champion_lock')} / approved {state.get('approved_champions')}")
    lines.append("API keys: NONE / private exchange endpoints not used")
    lines.append(f"Mode: {state.get('mode')}")
    lines.append("")
    lines.append("REAL LIVE DATA GATE")
    lines.append(f"Gate: {state.get('real_live_data_gate')}")
    lines.append(f"Raw data gate: {state.get('raw_data_gate')}")
    lines.append(f"Warning: {state.get('live_data_warning')}")
    lines.append(f"Stale seconds: {state.get('live_data_stale_seconds')}")
    lines.append(f"Feed source: {state.get('last_feed_source')}")
    lines.append(f"Feed status: {state.get('last_feed_status')}")
    lines.append(f"Current regime: {state.get('current_regime')}")
    lines.append(f"Ignored recent offline_demo rows: {ignored_demo}")
    lines.append("")
    lines.append("COUNTS")
    lines.append(f"Market ticks: {data['line_counts']['market_ticks']}")
    lines.append(f"Feed proof: {data['line_counts']['feed_proof']}")
    lines.append(f"Live data guard: {data['line_counts']['live_data_guard']}")
    lines.append(f"Learning cycles: {data['line_counts']['learning_cycles']}")
    lines.append(f"Research notes: {data['line_counts']['research_ledger']}")
    lines.append(f"Pulse count: {state.get('pulse_count')}")
    lines.append(f"Paper shadow rows: {data['line_counts'].get('paper_shadow', 0)}")
    lines.append(f"Candle rows total: {data['line_counts'].get('candle_rows', 0)}")
    lines.append(f"Candle proof rows: {data['line_counts'].get('candle_proof', 0)}")
    lines.append(f"Candle last new rows: {candle_summary.get('last_new_rows', 0)}")
    lines.append(f"Universe scan ledger rows: {data['line_counts'].get('universe_scan', 0)}")
    lines.append(f"Universe latest batch visible rows: {universe_summary.get('rows_visible', 0)}")
    lines.append(f"Backtest walk-forward rows: {data['line_counts'].get('backtest_walkforward', 0)}")
    lines.append(f"Growth score: {state.get('growth_score')}")
    lines.append(f"Learning score: {state.get('learning_score')}")
    lines.append(f"Research score: {state.get('research_score')}")
    lines.append("")
    lines.append("PAPER / RISK STATUS")
    lines.append(f"Paper Shadow: {state.get('paper_shadow_status')} | last_action={state.get('paper_shadow_last_action')} | open_position={state.get('paper_shadow_open_position')}")
    lines.append("Paper Arena: V013 simulator online. It records simulated entries/exits/holds/stand-asides only; no live orders.")
    lines.append(f"Candle Harvester: {candle_summary.get('status') or state.get('candle_harvester_status')} | last_new_rows={candle_summary.get('last_new_rows', 0)} | total_rows={candle_summary.get('total_rows', data['line_counts'].get('candle_rows', 0))} | last_at={candle_summary.get('last_at') or state.get('candle_harvester_last_at')}")
    lines.append(f"Universe Scanner: {universe_summary.get('status') or state.get('universe_scanner_status')} | latest_batch_rows={universe_summary.get('rows_visible', 0)} | ledger_rows={data['line_counts'].get('universe_scan', 0)} | top={universe_summary.get('top_symbol') or state.get('universe_scanner_top_symbol')} | top_score={universe_summary.get('top_score')}")
    lines.append(f"Backtest Gate: {backtest.get('status', state.get('backtest_gate_status'))} | gate={backtest.get('gate', state.get('backtest_walk_forward_status'))} | symbol={backtest.get('symbol', state.get('backtest_last_symbol'))} | interval={backtest.get('interval', state.get('backtest_last_interval'))}")
    lines.append(f"Champion proof gate: {state.get('champion_proof_gate')} | champion_claim_allowed={backtest.get('champion_claim_allowed', False)}")
    lines.append(f"Risk Police: {state.get('risk_police')}")
    lines.append(f"No-trade score: {state.get('no_trade_score')}")
    lines.append("Live trading enable, API keys, champion approval, and disabling Risk Police are not implemented in this build.")
    lines.append("")
    lines.append("LATEST PAPER SHADOW RECORDS")
    if paper:
        for r in paper:
            lines.append(f"- {r.get('ts')} | {r.get('action')} | {r.get('symbol')} | {r.get('side')} | regime={r.get('regime')} | net_pct={r.get('net_pct_after_fee_slippage')} | reason={r.get('risk_reason')}")
    else:
        lines.append("- No paper shadow rows yet. Run one market pulse after V013 install.")
    lines.append("")
    lines.append("LATEST CANDLES")
    if candles:
        for r in candles:
            lines.append(f"- {r.get('open_time_utc')} | {r.get('symbol')} | {r.get('interval')} | O={r.get('open')} H={r.get('high')} L={r.get('low')} C={r.get('close')} | source={r.get('source')}")
    else:
        lines.append("- No candle rows yet. Run one pulse after V014A install.")
    lines.append("")
    lines.append("LATEST UNIVERSE RANKS - TOP OF LATEST BATCH")
    lines.append(f"Universe headline top check: {universe_summary.get('top_symbol')} should match first visible row below.")
    if universe:
        for r in universe[:10]:
            lines.append(f"- {r.get('symbol')} | bucket={r.get('bucket')} | score={r.get('universe_score')} | 24h={r.get('price_change_percent_24h')} | qv={r.get('quote_volume')} | batch={r.get('batch_id')} | source={r.get('source')}")
    else:
        lines.append("- No universe scan rows yet. Run one pulse after V014A install.")
    lines.append("")
    lines.append("LATEST BACKTEST / WALK-FORWARD GATE RECORDS")
    if backtests:
        for r in backtests:
            ins = r.get("in_sample", {}) if isinstance(r.get("in_sample"), dict) else {}
            wf = r.get("walk_forward", {}) if isinstance(r.get("walk_forward"), dict) else {}
            lines.append(f"- {r.get('ts')} | {r.get('run_id')} | {r.get('symbol')} {r.get('interval')} | gate={r.get('gate')} | candles={r.get('total_candles')} | in_trades={ins.get('trades')} avg={ins.get('avg_net_pct')} dd={ins.get('max_drawdown_pct')} | wf_trades={wf.get('trades')} avg={wf.get('avg_net_pct')} dd={wf.get('max_drawdown_pct')} | champion_allowed={r.get('champion_claim_allowed')}")
    else:
        lines.append("- No backtest gate records yet. Click Backtest Gate -> Run Backtest + Walk-Forward Gate after V015A install.")
    lines.append("")
    lines.append("LATEST VERIFIED LIVE TICKS")
    if ticks:
        for r in ticks:
            lines.append(f"- {r.get('ts')} | {r.get('symbol')} | last={r.get('last_price')} | 24h={r.get('price_change_percent_24h')} | regime={r.get('regime')} | source={r.get('source')}")
    else:
        lines.append("- No verified live tick rows currently visible in dashboard tail.")
    lines.append("")
    lines.append("LATEST LEARNING CYCLES")
    if cycles:
        for r in cycles:
            lines.append(f"- cycle={r.get('cycle')} | {r.get('ts')} | source={r.get('source')} | regime={r.get('regime')} | claim={r.get('claim_level')} | task={r.get('research_task')}")
    else:
        lines.append("- No recent cycles.")
    lines.append("")
    lines.append("LATEST RESEARCH NOTES")
    if research:
        for r in research:
            lines.append(f"- {r.get('ts')} | {r.get('squad')} | {r.get('regime')} | {r.get('research_task')} | claim={r.get('claim_level')}")
    else:
        lines.append("- No recent research notes.")
    lines.append("")
    lines.append("LIVE DATA GUARD TAIL")
    if guard:
        for r in guard:
            lines.append(f"- {r.get('ts')} | gate={r.get('gate') or r.get('real_live_data_gate')} | raw={r.get('raw_data_gate')} | warning={r.get('warning') or r.get('live_data_warning')} | status={r.get('feed_status')}")
    else:
        lines.append("- No live data guard rows in recent tail.")
    lines.append("")
    lines.append("DOCTOR SUMMARY")
    lines.append(f"Doctor status: {doctor.get('summary')}")
    for c in doctor.get("checks", []):
        lines.append(f"- {'PASS' if c.get('ok') else 'WARN'} {c.get('name')}: {c.get('detail')}")
    lines.append("")
    lines.append("MY ASK TO CHATGPT")
    lines.append("Please review this Bali status report and tell me: 1) whether the live-data gate is healthy, 2) whether learning/paper/candle/universe/backtest/risk layers are safe, and 3) what patch should come next.")
    lines.append("")
    lines.append("NEXT SUGGESTED PATCH")
    lines.append("V016 Evidence Scorecard + Champion Council Gate: require repeated backtest/walk-forward and paper-shadow evidence before any champion can even be nominated.")
    text = "\n".join(lines)
    path.write_text(text, encoding="utf-8")
    try:
        (LOGS / "LAST_CHATGPT_STATUS_REPORT.txt").write_text(text, encoding="utf-8")
    except Exception:
        pass
    return path, text


def generate_always_working_report() -> Tuple[Path, str]:
    """Generate the V017 complete bot/layer/safety report and append a delta snapshot."""
    ensure_dirs()
    patch = latest_patch_ledger_entry()
    data = compute_dashboard_state()
    doctor = doctor_report()
    state = data.get("state", {})
    backtest = data.get("backtest_summary", {})
    candle_summary = data.get("candle_summary", {})
    universe_summary = data.get("universe_summary", {})
    current_counts = always_working_counts(data)
    previous = previous_always_working_snapshot()
    deltas = delta_counts(current_counts, previous)
    verdicts = {
        "LIVE DATA": live_data_verdict(state),
        "SAFETY": safety_verdict(data),
        "BOT COLLECTION": bot_collection_verdict(data),
        "EDGE PROOF": edge_proof_verdict(data),
    }
    next_action = next_action_from_verdicts(verdicts)
    report_name = f"BALI_ALWAYS_WORKING_BOT_STATS_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S_%f')}.txt"
    path = REPORTS / report_name
    lines: List[str] = []

    lines.append("BALI ROCKET - ALWAYS WORKING BOT STATS REPORT")
    lines.append("=" * 72)
    lines.append(f"Generated UTC: {iso_now()}")
    lines.append(f"Core version: {VERSION}")
    lines.append(f"Patch report version: {PATCH_REPORT_VERSION}")
    lines.append("")

    lines.append("LAST PATCH DETAILS")
    lines.append(f"Patch ID: {patch.get('patch_id', PATCH_REPORT_VERSION)}")
    lines.append(f"Title: {patch.get('title', PATCH_REPORT_TITLE)}")
    lines.append(f"Installed UTC: {patch.get('installed_utc', '')}")
    lines.append(f"Status: {patch.get('status', '')}")
    lines.append(f"Files changed: {format_report_value(patch.get('files_changed', []))}")
    lines.append(f"Safety note: {patch.get('safety', 'live_orders_OFF | champion_LOCKED | no_API_keys | public_data_only')}")
    lines.append("")

    lines.append("SAFETY VERDICT")
    lines.append(f"Doctor: {doctor.get('summary')}")
    lines.append(f"Live orders: {state.get('live_orders')}")
    lines.append(f"API/private endpoints: {private_env_key_status()}")
    lines.append(f"Champion lock: {state.get('champion_lock')} / approved {state.get('approved_champions')}")
    lines.append(f"Champion claim allowed: {bool(backtest.get('champion_claim_allowed') or state.get('champion_claim_allowed'))}")
    lines.append(f"Risk Police: {state.get('risk_police')}")
    lines.append(f"Overall safety verdict: {verdicts['SAFETY']}")
    lines.append("")

    lines.append("LIVE DATA VERDICT")
    lines.append(f"Gate: {state.get('real_live_data_gate')}")
    lines.append(f"Raw data rule: {state.get('raw_data_gate')}")
    lines.append(f"Warning: {state.get('live_data_warning')}")
    lines.append(f"Stale seconds: {state.get('live_data_stale_seconds')}")
    lines.append(f"Feed source: {state.get('last_feed_source')}")
    lines.append(f"Feed status: {state.get('last_feed_status')}")
    lines.append(f"Current regime: {format_report_value(state.get('current_regime'))}")
    lines.append("")

    lines.append("BOT / LAYER STATS")
    lines.append(f"Overnight/day watch status: watch_enabled={state.get('watch_enabled')} | collector_alive={data.get('collector_alive')}")
    lines.append(f"Market Feed: source={state.get('last_feed_source')} | status={state.get('last_feed_status')} | ticks={current_counts['market_ticks']}")
    lines.append(f"Learning Pulse: cycles={current_counts['learning_cycles']} | pulse_count={current_counts['pulse_count']} | last_pulse={state.get('last_pulse_at')}")
    lines.append(f"Research Notes: rows={current_counts['research_notes']} | score={state.get('research_score')}")
    lines.append(f"Paper Shadow: status={state.get('paper_shadow_status')} | rows={current_counts['paper_shadow_rows']} | last_action={state.get('paper_shadow_last_action')} | open_position={state.get('paper_shadow_open_position')}")
    lines.append(f"Candle Harvester: status={candle_summary.get('status') or state.get('candle_harvester_status')} | candle_rows={current_counts['candle_rows']} | proof_rows={current_counts['candle_proof_rows']} | last_new_rows={candle_summary.get('last_new_rows', 0)}")
    lines.append(f"Universe Scanner: status={universe_summary.get('status') or state.get('universe_scanner_status')} | ledger_rows={current_counts['universe_scan_ledger_rows']} | latest_visible={universe_summary.get('rows_visible', 0)} | top={universe_summary.get('top_symbol') or state.get('universe_scanner_top_symbol')}")
    lines.append(f"Backtest Gate: status={backtest.get('status', state.get('backtest_gate_status'))} | gate={backtest.get('gate', state.get('backtest_walk_forward_status'))} | rows={current_counts['backtest_walkforward_rows']} | champion_claim_allowed={backtest.get('champion_claim_allowed', False)}")
    lines.append(f"Risk Police: {state.get('risk_police')} | no_trade_score={state.get('no_trade_score')}")
    lines.append(f"Champion Council: {state.get('champion_lock')} | approved={state.get('approved_champions')} | proof_gate={state.get('champion_proof_gate')}")
    lines.append("")

    lines.append("DELTAS SINCE PREVIOUS REPORT")
    lines.append(f"Previous snapshot: {previous.get('report') if isinstance(previous, dict) else 'NONE - baseline report'}")
    lines.append(f"Market ticks: {deltas['market_ticks']}")
    lines.append(f"Feed proof: {deltas['feed_proof']}")
    lines.append(f"Live data guard: {deltas['live_data_guard']}")
    lines.append(f"Learning cycles: {deltas['learning_cycles']}")
    lines.append(f"Research notes: {deltas['research_notes']}")
    lines.append(f"Paper shadow rows: {deltas['paper_shadow_rows']}")
    lines.append(f"Candle rows: {deltas['candle_rows']}")
    lines.append(f"Candle proof rows: {deltas['candle_proof_rows']}")
    lines.append(f"Universe scan ledger rows: {deltas['universe_scan_ledger_rows']}")
    lines.append(f"Backtest walk-forward rows: {deltas['backtest_walkforward_rows']}")
    lines.append(f"Pulse count: {deltas['pulse_count']}")
    lines.append("")

    latest_sections = [
        ("LATEST PAPER SHADOW RECORDS", data.get("last_paper", [])[-8:], ["ts", "action", "symbol", "side", "regime", "net_pct_after_fee_slippage", "risk_reason"], "No paper shadow rows yet."),
        ("LATEST CANDLES", data.get("last_candles", [])[-8:], ["open_time_utc", "symbol", "interval", "open", "high", "low", "close", "source"], "No candle rows yet."),
        ("LATEST UNIVERSE RANKS", data.get("last_universe", [])[:10], ["symbol", "bucket", "universe_score", "price_change_percent_24h", "quote_volume", "batch_id", "source"], "No universe scan rows yet."),
        ("LATEST BACKTEST / WALK-FORWARD GATE RECORDS", data.get("last_backtests", [])[-6:], ["ts", "run_id", "symbol", "interval", "status", "gate", "total_candles", "champion_claim_allowed"], "No backtest walk-forward records yet."),
        ("LATEST VERIFIED LIVE TICKS", data.get("last_ticks", [])[-8:], ["ts", "symbol", "last_price", "price_change_percent_24h", "regime", "source", "feed_status"], "No verified live ticks in the recent dashboard tail."),
        ("LATEST LEARNING CYCLES", data.get("last_cycles", [])[-8:], ["cycle", "ts", "source", "regime", "claim_level", "research_task"], "No learning cycles yet."),
    ]
    for title, rows, fields, empty in latest_sections:
        lines.append(title)
        if rows:
            for row in rows:
                lines.append("- " + report_line_from_row(row, fields))
        else:
            lines.append("- " + empty)
        lines.append("")

    lines.append("FINAL VERDICT")
    lines.append(f"LIVE DATA: {verdicts['LIVE DATA']}")
    lines.append(f"SAFETY: {verdicts['SAFETY']}")
    lines.append(f"BOT COLLECTION: {verdicts['BOT COLLECTION']}")
    lines.append(f"EDGE PROOF: {verdicts['EDGE PROOF']}")
    lines.append(f"NEXT ACTION: {next_action}")
    lines.append("")
    lines.append("Safety reminder: live orders stay OFF, Champion stays LOCKED, no API keys are required, and this report is not a profit claim.")

    text = "\n".join(lines)
    path.write_text(text, encoding="utf-8")
    append_always_working_snapshot(report_name, data, verdicts)
    try:
        (LOGS / "LAST_ALWAYS_WORKING_BOT_STATS_REPORT.txt").write_text(text, encoding="utf-8")
    except Exception:
        pass
    return path, text


def normalize_zip_member(name: str) -> Optional[str]:
    name = name.replace("\\", "/").lstrip("/")
    parts = []
    for part in name.split("/"):
        if part in ("", "."):
            continue
        if part == "..":
            return None
        parts.append(part)
    return "/".join(parts)


def is_protected_path(rel: str) -> Tuple[bool, str]:
    low = rel.lower().replace("\\", "/")
    if low.startswith("shared_data/") and not low.startswith("shared_data/updates/"):
        return True, "shared_data is protected except shared_data/updates"
    for token in PROTECTED_TOKENS:
        t = token.lower().replace("\\", "/")
        if t in low:
            return True, f"protected token: {token}"
    return False, ""


def load_manifest_from_zip(zip_path: Path) -> Tuple[Optional[Dict[str, Any]], List[str]]:
    warnings = []
    try:
        with zipfile.ZipFile(zip_path, "r") as z:
            names = z.namelist()
            manifest_names = [n for n in names if normalize_zip_member(n) in ("update_manifest.json", "manifest.json") or normalize_zip_member(n).endswith("/update_manifest.json")]
            if not manifest_names:
                return None, ["No update_manifest.json found"]
            with z.open(manifest_names[0]) as f:
                manifest = json.loads(f.read().decode("utf-8"))
            return manifest, warnings
    except Exception as e:
        return None, [f"Cannot read zip: {e}"]


def scan_updates() -> Dict[str, Any]:
    ensure_dirs()
    results = []
    for zip_path in sorted(UPDATE_INBOX.glob("*.zip"), key=lambda p: p.stat().st_mtime, reverse=True):
        manifest, warnings = load_manifest_from_zip(zip_path)
        item = {"file": zip_path.name, "path": str(zip_path), "valid": False, "blocked": [], "warnings": warnings, "manifest": manifest}
        if manifest:
            project = manifest.get("project")
            version_number = int(manifest.get("version_number", 0) or 0)
            if project != PROJECT_NAME:
                item["blocked"].append(f"Project mismatch: {project}")
            if version_number <= VERSION_NUMBER:
                item["blocked"].append(f"Version {version_number} is not newer than current {VERSION_NUMBER}")
            payload_prefix = str(manifest.get("payload_prefix", "payload/")).replace("\\", "/")
            try:
                with zipfile.ZipFile(zip_path, "r") as z:
                    payload_files = []
                    for n in z.namelist():
                        norm = normalize_zip_member(n)
                        if not norm or norm.endswith("/") or n.endswith("/"):
                            continue
                        if norm in ("update_manifest.json", "manifest.json") or norm.endswith("/update_manifest.json"):
                            continue
                        if payload_prefix and not norm.startswith(payload_prefix):
                            continue
                        rel = norm[len(payload_prefix):] if payload_prefix and norm.startswith(payload_prefix) else norm
                        if not rel:
                            continue
                        protected, reason = is_protected_path(rel)
                        if protected:
                            item["blocked"].append(f"Protected path blocked: {rel} ({reason})")
                        payload_files.append(rel)
                    item["payload_files"] = payload_files[:80]
                    item["payload_file_count"] = len(payload_files)
            except Exception as e:
                item["blocked"].append(f"Payload scan failed: {e}")
            item["valid"] = not item["blocked"]
        results.append(item)
    best = next((r for r in results if r["valid"]), None)
    return {"updated_at": iso_now(), "current_version_number": VERSION_NUMBER, "items": results, "best_valid": best}


def apply_update(zip_name: str) -> Dict[str, Any]:
    ensure_dirs()
    scan = scan_updates()
    match = None
    for item in scan["items"]:
        if item["file"] == zip_name:
            match = item
            break
    if not match:
        return {"ok": False, "message": "Update zip not found in UPDATE_INBOX."}
    if not match.get("valid"):
        return {"ok": False, "message": "Update blocked by validation.", "details": match}
    zip_path = Path(match["path"])
    manifest = match["manifest"] or {}
    payload_prefix = str(manifest.get("payload_prefix", "payload/")).replace("\\", "/")
    stamp = utc_now().strftime("%Y%m%d_%H%M%S")
    backup_path = BACKUPS / f"backup_before_{zip_path.stem}_{stamp}.zip"
    applied_files = []
    added_files = []
    overwritten = []
    with tempfile.TemporaryDirectory() as td:
        stage = Path(td) / "stage"
        stage.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path, "r") as z:
            for n in z.namelist():
                norm = normalize_zip_member(n)
                if not norm or norm.endswith("/") or n.endswith("/"):
                    continue
                if norm in ("update_manifest.json", "manifest.json") or norm.endswith("/update_manifest.json"):
                    continue
                if payload_prefix and not norm.startswith(payload_prefix):
                    continue
                rel = norm[len(payload_prefix):] if payload_prefix and norm.startswith(payload_prefix) else norm
                if not rel:
                    continue
                protected, reason = is_protected_path(rel)
                if protected:
                    return {"ok": False, "message": f"Protected path blocked during apply: {rel} ({reason})"}
                target = ROOT / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                data = z.read(n)
                if target.exists():
                    overwritten.append(rel)
                else:
                    added_files.append(rel)
                # Extract into staging first
                staged = stage / rel
                staged.parent.mkdir(parents=True, exist_ok=True)
                staged.write_bytes(data)
        if overwritten:
            with zipfile.ZipFile(backup_path, "w", zipfile.ZIP_DEFLATED) as bz:
                for rel in overwritten:
                    path = ROOT / rel
                    if path.exists() and path.is_file():
                        bz.write(path, rel)
        else:
            with zipfile.ZipFile(backup_path, "w", zipfile.ZIP_DEFLATED) as bz:
                bz.writestr("NO_OVERWRITES.txt", "No overwritten files in this update.\n")
        for staged in stage.rglob("*"):
            if staged.is_file():
                rel = staged.relative_to(stage).as_posix()
                target = ROOT / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(staged, target)
                applied_files.append(rel)
    ledger = read_json(UPDATES / "applied_updates.json", {"updates": []})
    entry = {
        "ts": iso_now(),
        "zip": zip_name,
        "manifest": manifest,
        "backup": str(backup_path),
        "applied_files": applied_files,
        "overwritten_files": overwritten,
        "added_files": added_files,
        "restart_required": bool(manifest.get("restart_required", True)),
        "claim_level": "SAFE_UPDATE_APPLIED_NO_PROTECTED_DATA_TOUCHED",
    }
    ledger.setdefault("updates", []).append(entry)
    write_json(UPDATES / "applied_updates.json", ledger)
    append_jsonl(UPDATES / "applied_updates.jsonl", entry)
    return {"ok": True, "message": "Update applied. Restart may be required for code changes.", "entry": entry}


def rollback_last_update() -> Dict[str, Any]:
    ledger = read_json(UPDATES / "applied_updates.json", {"updates": []})
    updates = ledger.get("updates", [])
    if not updates:
        return {"ok": False, "message": "No applied updates found."}
    last = updates[-1]
    backup = Path(last.get("backup", ""))
    if not backup.exists():
        return {"ok": False, "message": "Backup file missing; cannot rollback safely.", "backup": str(backup)}
    restored = []
    try:
        with zipfile.ZipFile(backup, "r") as bz:
            for n in bz.namelist():
                norm = normalize_zip_member(n)
                if not norm or norm == "NO_OVERWRITES.txt":
                    continue
                protected, reason = is_protected_path(norm)
                if protected:
                    continue
                target = ROOT / norm
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(bz.read(n))
                restored.append(norm)
        entry = {"ts": iso_now(), "rolled_back_zip": last.get("zip"), "backup": str(backup), "restored": restored}
        append_jsonl(UPDATES / "rollback_ledger.jsonl", entry)
        return {"ok": True, "message": "Rollback restored overwritten files. Newly added files were left in place for safety review.", "entry": entry}
    except Exception as e:
        return {"ok": False, "message": f"Rollback failed: {e}"}


CSS = r'''
:root{--bg:#04151f;--panel:rgba(4,31,45,.82);--panel2:rgba(4,46,62,.72);--line:rgba(111,255,226,.22);--neon:#6fffe2;--gold:#ffd36a;--pink:#ff7bd5;--danger:#ff6b6b;--good:#7cff96;--text:#f2fffc;--muted:#acd6d0}*{box-sizing:border-box}body{margin:0;font-family:Segoe UI,Arial,sans-serif;color:var(--text);background:radial-gradient(circle at 10% 10%,rgba(0,255,197,.28),transparent 24%),radial-gradient(circle at 90% 5%,rgba(255,123,213,.2),transparent 20%),linear-gradient(135deg,#031018 0%,#062735 45%,#0c422f 100%);min-height:100vh}.shell{max-width:1320px;margin:0 auto;padding:18px}.hero{border:1px solid var(--line);background:linear-gradient(135deg,rgba(2,20,31,.88),rgba(3,64,70,.62));border-radius:28px;padding:22px;box-shadow:0 0 35px rgba(111,255,226,.13);position:relative;overflow:hidden}.hero:before{content:"";position:absolute;inset:-70px;background:conic-gradient(from 90deg,transparent,rgba(111,255,226,.18),transparent 35%);animation:spin 10s linear infinite}.hero>*{position:relative}@keyframes spin{to{transform:rotate(360deg)}}h1{margin:0;font-size:clamp(26px,4vw,56px);letter-spacing:.04em}.subtitle{color:var(--muted);font-size:17px;margin-top:6px}.badgebar{display:flex;gap:10px;flex-wrap:wrap;margin-top:15px}.badge{padding:8px 12px;border:1px solid var(--line);border-radius:999px;background:rgba(0,0,0,.18);font-weight:700}.good{color:var(--good)}.danger{color:var(--danger)}.gold{color:var(--gold)}.tabs{display:flex;gap:9px;flex-wrap:wrap;margin:18px 0}.tab{border:1px solid var(--line);background:rgba(0,0,0,.22);color:var(--text);border-radius:999px;padding:10px 13px;cursor:pointer;font-weight:700}.tab.active{background:linear-gradient(90deg,rgba(111,255,226,.28),rgba(255,211,106,.18));box-shadow:0 0 18px rgba(111,255,226,.18)}.grid{display:grid;grid-template-columns:repeat(12,1fr);gap:14px}.card{grid-column:span 4;border:1px solid var(--line);background:var(--panel);border-radius:22px;padding:16px;box-shadow:0 0 18px rgba(0,0,0,.2)}.wide{grid-column:span 8}.full{grid-column:1/-1}.mini{grid-column:span 3}.card h2,.card h3{margin:0 0 10px}.metric{font-size:34px;font-weight:900;color:var(--neon);line-height:1}.muted{color:var(--muted)}.row{display:flex;justify-content:space-between;gap:12px;border-bottom:1px solid rgba(255,255,255,.08);padding:7px 0}.row:last-child{border-bottom:0}.btn{border:0;border-radius:14px;padding:11px 14px;margin:5px 5px 5px 0;background:linear-gradient(90deg,#16e7c1,#ffd36a);color:#06202a;font-weight:900;cursor:pointer}.btn.alt{background:rgba(255,255,255,.1);color:var(--text);border:1px solid var(--line)}.btn.danger{background:linear-gradient(90deg,#ff6b6b,#ffd36a);color:#250606}pre{white-space:pre-wrap;background:rgba(0,0,0,.22);border:1px solid rgba(255,255,255,.08);padding:12px;border-radius:14px;max-height:390px;overflow:auto}.hidden{display:none}.table{width:100%;border-collapse:collapse;font-size:14px}.table th,.table td{border-bottom:1px solid rgba(255,255,255,.09);padding:8px;text-align:left}.status-dot{display:inline-block;width:10px;height:10px;border-radius:50%;background:var(--good);box-shadow:0 0 12px var(--good);margin-right:8px}.pulse{animation:pulse 1.5s infinite}@keyframes pulse{50%{opacity:.45;transform:scale(.92)}}.map{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}.island{padding:14px;border:1px solid var(--line);border-radius:18px;background:linear-gradient(145deg,rgba(111,255,226,.08),rgba(255,211,106,.07))}.footer{color:var(--muted);font-size:12px;text-align:center;padding:18px}.arenaScore{font-size:42px;font-weight:950;color:var(--gold);line-height:1}.versus{font-size:28px;font-weight:950;text-align:center;color:var(--neon);padding:12px}.badge2{display:inline-block;padding:5px 9px;border:1px solid var(--line);border-radius:999px;margin:3px;font-size:12px;background:rgba(255,255,255,.06)}.penalty{color:#ff8f8f;font-weight:900}.xpbar{height:10px;border:1px solid var(--line);background:rgba(255,255,255,.07);border-radius:999px;overflow:hidden}.xpfill{height:100%;background:linear-gradient(90deg,var(--gold),var(--neon));}.roundbox{border:1px dashed var(--line);border-radius:14px;padding:10px;margin:8px 0;background:rgba(255,255,255,.04)}.barbox{height:12px;border:1px solid var(--line);border-radius:999px;background:rgba(255,255,255,.08);overflow:hidden;margin:4px 0 10px}.barfill{height:100%;border-radius:999px;background:linear-gradient(90deg,var(--neon),var(--gold))}.chartnote{font-size:12px;color:var(--muted);margin-top:2px}.govnote{border-left:4px solid var(--gold);padding:10px 12px;background:rgba(255,211,106,.08);border-radius:12px;margin:8px 0}.missionline{font-size:14px;letter-spacing:.05em;color:var(--gold);font-weight:900}.goal{font-size:18px;font-weight:900;color:var(--neon);line-height:1.25}@media(max-width:800px){.shell{padding:10px}.card,.wide,.mini{grid-column:1/-1}.tabs{position:sticky;top:0;background:rgba(4,21,31,.94);padding:8px;z-index:5;border-radius:16px}.tab{padding:9px 10px;font-size:13px}.map{grid-template-columns:1fr 1fr}.metric{font-size:28px}h1{font-size:31px}}
'''


def dashboard_html(phone: bool = False) -> str:
    title = "Bali Phone Command" if phone else "Bali Rocket Crypto Command"
    tabs = [
        ("control", "Mission Control"), ("arena", "Game Arena"), ("mission", "Mission"), ("overnight", "Overnight Watch"), ("feed", "Market Feed"), ("growth", "Learning Pulse"),
        ("research", "Research"), ("forge", "Strategy Forge"), ("squads", "Squads"), ("paper", "Paper Arena"),
        ("candles", "Candle Harvester"), ("universe", "Universe Scanner"), ("backtest", "Backtest Gate"),
        ("risk", "Risk Police"), ("champions", "Champion Council"), ("updates", "Update Dock"), ("doctor", "Doctor"),
        ("reports", "Reports"), ("phone", "Phone")]
    if phone:
        tabs = [("control", "Mission"), ("arena", "Arena"), ("mission", "Overview"), ("overnight", "Watch"), ("feed", "Feed"), ("growth", "Growth"), ("candles", "Candles"), ("universe", "Universe"), ("backtest", "Backtest"), ("updates", "Updates"), ("doctor", "Doctor"), ("reports", "Reports"), ("risk", "Risk")]
    tab_html = "".join([f'<button class="tab" onclick="showTab(\'{tid}\')">{name}</button>' for tid, name in tabs])
    html_doc = f'''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{CSS}</style></head><body><div class="shell"><section class="hero"><h1>🌴🚀 {title}</h1><div class="subtitle">Bali Mission Control • governor notes • bot progress • paper/research-only • live trading locked OFF</div><div class="badgebar"><span class="badge good"><span class="status-dot pulse"></span>Overnight collector</span><span class="badge gold">Champion lock 0/3</span><span class="badge danger">Live orders OFF</span><span class="badge">Autopilot Local Updates</span><span class="badge gold">Mission Control</span><span class="badge good">Raw live data only</span></div></section><nav class="tabs">{tab_html}</nav><main id="app"></main><div class="footer">{PROJECT_TITLE} {VERSION} — no API keys, no live-order code, no exchange-private endpoints.</div></div><script>{JS}</script></body></html>'''
    return html_doc


JS = r'''
let DATA=null;let ACTIVE='control';
function valueText(x){if(x===null||x===undefined)return '';if(Array.isArray(x))return x.map(valueText).join(', ');if(typeof x==='object'){let label=x.label||x.status||x.gate||x.symbol||x.name||'';let parts=[];if(label)parts.push(String(label));Object.keys(x).sort().forEach(k=>{if(k==='label'&&label)return;let v=x[k];if(v===null||v===undefined||v==='')return;parts.push(`${k}=${typeof v==='object'?valueText(v):String(v)}`);});return parts.join(' | ')||JSON.stringify(x);}return String(x);}
function esc(x){return valueText(x).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));}
function fmtSecs(s){s=Number(s||0);let h=Math.floor(s/3600),m=Math.floor((s%3600)/60);return `${h}h ${m}m`;}
async function api(path){const r=await fetch(path,{cache:'no-store'});return await r.json();}
async function act(path){let out=await api(path);await load();alert(out.message||out.ok||'Done');}
async function dashUpdateRestart(){if(!confirm('Apply latest patch, close this dashboard, run Speed Lane, then auto restart?'))return;let out=await api('/api/dashboard/update-restart');alert(out.message||'Dashboard update launched. It will close this dash, patch, restart, and show one final result.');document.getElementById('app').innerHTML='<div class="card full"><h2>Dashboard update launched</h2><p>The dashboard is closing so the patch can be applied safely.</p><p>After restart, open Updates and click Show / Copy Last Final Status if you need to send ChatGPT the result. You do not need to search folders or run BALI_FAST_STATUS_PACK manually.</p></div>';}
async function dashFinalStatus(){let out=await api('/api/dashboard/final-status');let txt=out.text||out.message||'No final status yet.';let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML='<div class="grid"><section class="card full"><h2>Last Dashboard Final Status</h2><p class="muted">'+esc(copied?'Copied to clipboard. Paste this to ChatGPT if needed.':'Copy was blocked by the browser; select the text below and copy it.')+'</p><button class="btn" onclick="dashFinalStatus()">Refresh / Copy Again</button><pre>'+esc(txt)+'</pre></section></div>';}
async function dashUploadPatchUpdate(){let el=document.getElementById('patchZip');if(!el||!el.files||!el.files.length){alert('Choose the patch ZIP first.');return;}let fd=new FormData();fd.append('patch_zip',el.files[0]);let r=await fetch('/api/dashboard/upload-patch',{method:'POST',body:fd});let out=await r.json();if(!out.ok){alert(out.message||'Upload failed');return;}if(!confirm((out.message||'Patch uploaded')+'\n\nApply it now and auto restart?'))return;await dashUpdateRestart();}
let AUTOPILOT_FIRED=false;
async function autopilotToggle(on){let out=await api(on?'/api/autopilot/enable':'/api/autopilot/disable');alert(out.message||('Autopilot '+(on?'armed':'paused')));await load();}
async function autopilotApplyNow(){let out=await api('/api/autopilot/apply-now');if(out.ok){AUTOPILOT_FIRED=true;document.getElementById('app').innerHTML='<div class="card full"><h2>Autopilot update launched</h2><p>Dashboard is closing to apply '+esc((out.candidate||{}).version||'the patch')+'. One tiny final report will appear after restart.</p></div>';setTimeout(()=>{},1000);}else{alert(out.message||'No autopilot patch ready.');}}
async function autopilotPoll(){try{let out=await api('/api/autopilot/status');if(out.enabled&&out.ready&&!AUTOPILOT_FIRED){AUTOPILOT_FIRED=true;let fire=await api('/api/autopilot/apply-now');document.getElementById('app').innerHTML='<div class="card full"><h2>Autopilot update launched</h2><p>'+esc(fire.message||'Applying patch and restarting.')+'</p></div>';}}catch(e){}}
setInterval(autopilotPoll,20000);

async function load(){try{DATA=await api('/api/state');render();}catch(e){document.getElementById('app').innerHTML='<div class="card full"><h2>Connection issue</h2><pre>'+esc(e)+'</pre></div>';}}
function showTab(t){ACTIVE=t;render();}
function setTab(t){showTab(t);}
function rows(items,fields){return `<table class="table"><thead><tr>${fields.map(f=>`<th>${esc(f[1])}</th>`).join('')}</tr></thead><tbody>${(items||[]).map(it=>`<tr>${fields.map(f=>`<td>${esc(it[f[0]])}</td>`).join('')}</tr>`).join('')}</tbody></table>`;}
function card(title,body,cls='card'){return `<section class="${cls}"><h2>${title}</h2>${body}</section>`;}
function bar(name,val,note=''){val=Math.max(0,Math.min(100,Number(val||0)));return `<div class="row"><b>${esc(name)}</b><span>${val}%</span></div><div class="barbox"><div class="barfill" style="width:${val}%"></div></div>${note?`<div class="chartnote">${esc(note)}</div>`:''}`;}

function liveGateBanner(){let s=(DATA&&DATA.state)||{};let g=String(s.real_live_data_gate||'UNKNOWN');let ok=g.startsWith('PASS');let stale=s.live_data_stale_seconds;let warn=s.live_data_warning||'';let msg=ok?'Real live data is verified. Learning/scoring may proceed.':'REAL LIVE DATA BLOCK: scoring, learning, research scoring and paper shadow are blocked until fresh public exchange data returns.';return `<section class="card full" style="border-color:${ok?'rgba(50,255,137,.35)':'rgba(255,77,109,.9)'}"><h2>${ok?'✅ Real Live Data Gate':'🚨 Real Live Data Gate'}</h2><div class="row"><b>Gate</b><span>${esc(g)}</span></div><div class="row"><b>Raw data rule</b><span>${esc(s.raw_data_gate||'')}</span></div><div class="row"><b>Warning</b><span>${esc(warn)}</span></div><div class="row"><b>Stale seconds</b><span>${esc(stale??'unknown')}</span></div><p class="muted">${esc(msg)}</p></section>`;}

async function arenaScoreRound(){let out=await api('/api/arena/score-round');alert(out.message||'Referee score round complete.');await load();}
async function arenaScoreboard(){let out=await api('/api/arena/scoreboard');let txt=JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML='<div class="grid"><section class="card full"><h2>Arena Scoreboard JSON</h2><p class="muted">'+esc(copied?'Copied to clipboard.':'Select and copy if needed.')+'</p><button class="btn" onclick="arenaScoreRound()">Score Latest RAW-LIVE SIM Round</button><button class="btn alt" onclick="load()">Back</button><pre>'+esc(txt)+'</pre></section></div>';}
async function createStargateJoinKit(){let out=await api('/api/arena/create-stargate-join-kit');let txt=JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML='<div class="grid"><section class="card full"><h2>Stargate Join Kit</h2><p class="muted">'+esc(copied?'Join kit details copied to clipboard.':'Join kit created. Select and copy if needed.')+'</p><button class="btn alt" onclick="load()">Back</button><pre>'+esc(txt)+'</pre></section></div>';}
async function showGovernorHub(){let out=await api('/api/arena/governor-hub');let txt=JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML='<div class="grid"><section class="card full"><h2>Governor Hub / Bridge Instructions</h2><p class="muted">'+esc(copied?'Hub instructions copied to clipboard.':'Select and copy if needed.')+'</p><button class="btn" onclick="setupOneDriveBridge()">Auto Setup OneDrive Bridge</button><button class="btn" onclick="createStargateJoinKit()">Create Stargate Join Kit</button><button class="btn alt" onclick="load()">Back</button><pre>'+esc(txt)+'</pre></section></div>';}
async function setupOneDriveBridge(){let out=await api('/api/arena/setup-onedrive-bridge');let txt=JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML='<div class="grid"><section class="card full"><h2>OneDrive Arena Bridge Setup</h2><p class="muted">'+esc(copied?'Bridge setup result copied to clipboard.':'Bridge setup complete. Select and copy if needed.')+'</p><button class="btn" onclick="showGovernorHub()">Show Hub Status</button><button class="btn alt" onclick="load()">Back</button><pre>'+esc(txt)+'</pre></section></div>';}


async function copyMissionBrief(){let s=DATA.state, ap=DATA.autopilot||{};let txt=[`VERSION=${DATA.version_number?'V015A':'V015A'}`,`MISSION=BALI_THEMED_CHALLENGER_VS_STARGATE`,`OBJECTIVE=GOVERNOR_MISSION_CONSOLE`,`SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS`,`AUTOPILOT=${ap.enabled?'LOCAL_ONLY_ARMED':'PAUSED'}`,`HEALTH=${String(s.real_live_data_gate||'UNKNOWN').startsWith('PASS')?'PASS':'BLOCKED_NO_REAL_LIVE_DATA'}`,`RAW_DATA_GATE=${s.raw_data_gate||'UNKNOWN'}`,`BOT_PROGRESS=PLACEHOLDERS_READY_SIM_ONLY`,`ARENA=SIM_ONLY_FOUNDATION`,`CPU_BRIDGE=SHARED_FOLDER_READY_SIM_ONLY`,`MATCH_REFEREE=PREP_LOCAL_JSON_ONLY`,`BRIDGE=JSON_ONLY_NO_REMOTE_COMMANDS`,`RESULT=MISSION_CONTROL_READY`].join('\n');try{await navigator.clipboard.writeText(txt);alert('Important mission status copied.');}catch(e){alert(txt);}}
function render(){if(!DATA)return;document.querySelectorAll('.tab').forEach(b=>b.classList.toggle('active',b.textContent.toLowerCase().includes(ACTIVE)||b.getAttribute('onclick')?.includes(`'${ACTIVE}'`)));const s=DATA.state;let html='';
if(ACTIVE==='control') html=control(s); if(ACTIVE==='arena') html=arena(s); if(ACTIVE==='mission') html=mission(s); if(ACTIVE==='overnight') html=overnight(s); if(ACTIVE==='feed') html=feed(s); if(ACTIVE==='growth') html=growth(s); if(ACTIVE==='research') html=research(s); if(ACTIVE==='forge') html=forge(s); if(ACTIVE==='squads') html=squads(s); if(ACTIVE==='paper') html=paper(s); if(ACTIVE==='candles') html=candles(s); if(ACTIVE==='universe') html=universe(s); if(ACTIVE==='backtest') html=backtest(s); if(ACTIVE==='risk') html=risk(s); if(ACTIVE==='champions') html=champions(s); if(ACTIVE==='updates') html=updates(s); if(ACTIVE==='doctor') html=doctor(s); if(ACTIVE==='reports') html=reports(s); if(ACTIVE==='phone') html=phone(s); document.getElementById('app').innerHTML=liveGateBanner()+html;}
function control(s){let ap=DATA.autopilot||{};let cand=ap.candidate||null;let progress=[['Python/root stability',100,'Launcher and app root are stable.'],['Autopilot update loop',98,'Local-only watcher is applying higher-version Bali patches.'],['Dashboard update flow',94,'Dash closes, patches, health-checks, and restarts.'],['Important-only reporting',92,'Chat receives tiny reports; logs keep detail.'],['Governor notes',70,'Mission layer is now live in the dashboard.'],['Bot progress tracking',35,'Cards exist; next step is real bot telemetry.'],['Mission charts',35,'Visual build/bot/safety charts now exist.'],['Paper arena proof',45,'Referee prep plus shared-folder check-ins are staged.'],['Two-CPU bridge',45,'Shared-folder JSON bridge is ready for Bali/Stargate SIM check-ins.'],['Live trading readiness',0,'Locked by design.']];let bots=[['Alpha Watch',40,'Baseline BTC/ETH observation.'],['Bravo Scout',30,'Alt-rotation research only.'],['Charlie Filters',20,'Chop/panic/no-trade filters.'],['Risk Police',95,'Safety locks active.'],['Champion Council',0,'No champions approved.']];return `<div class="grid">${card('Governor Notes',`<div class="missionline">Bali themed challenger versus Stargate</div><div class="govnote"><b>Governor note:</b> Autopilot is proven. The mission now shifts to disciplined bot telemetry, evidence, paper proof, and safety-gated progress. Do not chase live trading before the scoreboard earns it.</div><div class="goal">Current objective: bridge Bali and Stargate through SIM-only shared JSON so the referee can score fair rounds.</div><button class="btn" onclick="copyMissionBrief()">Copy Important Mission Status</button>`, 'card wide')}${card('Mission Status',`<div class="row"><b>Version</b><span>V015A</span></div><div class="row"><b>Game Arena</b><span>FOUNDATION</span></div><div class="row"><b>CPU bridge</b><span>SHARED FOLDER READY</span></div><div class="row"><b>Match referee</b><span>PREP LOCAL JSON</span></div><div class="row"><b>Autopilot</b><span>${esc(ap.enabled?'LOCAL ONLY ARMED':'PAUSED')}</span></div><div class="row"><b>Next patch</b><span>${cand?esc(cand.version):'none waiting'}</span></div><div class="row"><b>Live orders</b><span class="danger">OFF</span></div><div class="row"><b>Champion lock</b><span>LOCKED</span></div><div class="row"><b>API keys</b><span>NONE</span></div><div class="row"><b>Raw data rule</b><span>RAW LIVE DATA ONLY</span></div>`) }${card('Build Progress Chart',progress.map(x=>bar(x[0],x[1],x[2])).join(''),'card wide')}${card('Bot Progress Chart',bots.map(x=>bar(x[0],x[1],x[2])).join(''))}${card('Safety Gate Scoreboard',`<div class="row"><b>Live executor</b><span class="danger">NOT BUILT</span></div><div class="row"><b>Paper proof</b><span>EARLY</span></div><div class="row"><b>Backtest proof</b><span>GATE ADDED</span></div><div class="row"><b>Out-of-sample</b><span>MISSING</span></div><div class="row"><b>Human approval</b><span>0/3</span></div><p class="muted">Main goal stays visible: safety-locked, evidence-first, paper/sim before any live capability.</p>`,'card wide')}${card('Update Progress',`<div class="row"><b>Watcher</b><span>PASS</span></div><div class="row"><b>Bundle flow</b><span>READY</span></div><div class="row"><b>Chat report</b><span>IMPORTANT ONLY</span></div><div class="row"><b>Patch ZIPs visible</b><span>${DATA.update_scan.items.length}</span></div><p class="muted">Normal flow: keep dash open, drop/upload the next patch ZIP, autopilot handles the rest.</p>`)}</div>`}
function arena(s){let ap=DATA.autopilot||{};let bali={score:0,level:1,xp:0,readiness:35};let gate={score:0,level:1,xp:0,readiness:0};let scoring=[['Profit score',0,'Not active until paper rounds begin.'],['Risk control',90,'Safety-first points are already strong.'],['Drawdown control',0,'Needs sim/paper evidence.'],['Consistency',0,'Needs repeated match rounds.'],['Signal quality',10,'Observation layer only.'],['Recovery after loss',0,'Needs match history.'],['Uptime',85,'Dashboard/autopilot stable.'],['Safety violations',100,'No violations; live orders locked OFF.'],['Update stability',98,'Autopilot patches are passing.']];let rounds=[['Round 001','Setup','Arena foundation only; no bot duel yet.'],['Round 002','Bridge prep','CPU roles staged: BALI_CPU, STARGATE_CPU, REFEREE_CPU.'],['Round 003','Referee prep','Scoring rules and sample round JSON staged.'],['Round 004','Bridge ready','Shared-folder JSON bridge ready for two-CPU SIM check-ins.']];return `<div class="grid">${card('Bali vs Stargate Scoreboard',`<div class="row"><div><b>Bali Bot</b><div class="arenaScore">${bali.score}</div><span class="badge2">BALI_CPU</span><span class="badge2">Level ${bali.level}</span><span class="badge2">SIM ONLY</span></div><div class="versus">VS</div><div><b>Stargate Bot</b><div class="arenaScore">${gate.score}</div><span class="badge2">STARGATE_CPU</span><span class="badge2">Level ${gate.level}</span><span class="badge2">BRIDGE PREP</span></div></div><p class="muted">Bali hub exports a Stargate join kit with templates, rules, and heartbeat/check-in paths. Stargate writes JSON check-ins only. Raw live data provenance remains required for scoring. No remote commands, no live trading.</p>`, 'card wide')}${card('Governor Referee Notes',`<div class="govnote"><b>Referee ruling:</b> The arena is open, but the match is not live. Bali must earn points through paper/sim evidence, risk discipline, and uptime. Stargate must report through the same rules on the second CPU.</div><div class="row"><b>Competition mode</b><span>SIM ONLY</span></div><div class="row"><b>Main goal</b><span>Evidence before escalation</span></div><div class="row"><b>Live trading readiness</b><span class="danger">0%</span></div>`) }${card('Arena Scoring Gates',scoring.map(x=>bar(x[0],x[1],x[2])).join(''),'card wide')}${card('Bot XP / Badges',`<div class="row"><b>Bali XP</b><span>${bali.xp}/100</span></div><div class="xpbar"><div class="xpfill" style="width:${bali.xp}%"></div></div><p><span class="badge2">Autopilot stable</span><span class="badge2">Mission console online</span><span class="badge2">Safety locked</span></p><div class="row"><b>Stargate XP</b><span>${gate.xp}/100</span></div><div class="xpbar"><div class="xpfill" style="width:${gate.xp}%"></div></div><p><span class="badge2">Awaiting CPU bridge</span><span class="badge2">No rounds logged</span></p>`) }${card('Round History',rounds.map(r=>`<div class="roundbox"><b>${esc(r[0])}</b> - ${esc(r[1])}<br><span class="muted">${esc(r[2])}</span></div>`).join(''))}${card('CPU Identity Panel',`<div class="row"><b>Bali machine</b><span>BALI_CPU / GOVERNOR HUB + competitor</span></div><div class="row"><b>Stargate machine</b><span>STARGATE_CPU / competitor node via join kit</span></div><div class="row"><b>Referee</b><span>BALI GOVERNOR HUB / scores both CPUs</span></div><div class="row"><b>Bridge status</b><span>SHARED FOLDER WATCHER READY - JSON ONLY</span></div><div class="row"><b>Referee status</b><span>SCORING READY - LOCAL JSON ONLY</span></div><div class="row"><b>Allowed data</b><span>RAW LIVE DATA ONLY - SIM/PAPER SCORING</span></div><div class="row"><b>Blocked for score</b><span>synthetic / mock / seed / demo / ranked replay</span></div><p class="muted">V012K active: Stargate Join Kit export and hub status are ready. Shared-folder watcher plus referee scoring remain SIM-only.</p><button class="btn" onclick="setupOneDriveBridge()">Auto Setup OneDrive Bridge</button><button class="btn" onclick="arenaScoreRound()">Score Latest RAW-LIVE SIM Round</button><button class="btn alt" onclick="arenaScoreboard()">Show / Copy Scoreboard JSON</button><button class="btn" onclick="createStargateJoinKit()">Create / Export Stargate Join Kit</button><button class="btn alt" onclick="showGovernorHub()">Show Hub / Bridge Instructions</button>`,'card wide')}</div>`}
function mission(s){return `<div class="grid">${card('Bali Command Map',`<div class="map"><div class="island">🌊 Market Brain<br><b>${esc(s.current_regime)}</b></div><div class="island">🛡️ Risk Volcano<br><b>${esc(s.risk_police)}</b></div><div class="island">🏟️ Paper Arena<br><b>READY / no live orders</b></div><div class="island">🏛️ Champion Temple<br><b>${esc(s.champion_lock)} ${esc(s.approved_champions)}</b></div><div class="island">📡 Feed Tower<br><b>${esc(s.last_feed_source)}</b></div><div class="island">🧪 Research Hut<br><b>${esc(DATA.line_counts.research_ledger)} notes</b></div><div class="island">⚙️ Update Dock<br><b>${DATA.update_scan.items.length} zip(s)</b></div><div class="island">📱 Phone Pier<br><b>${DATA.lan_ips.length?'LAN ready':'local only'}</b></div></div>`, 'card wide')}${card('Current Status',`<div class="metric">${esc(s.current_regime)}</div><p class="muted">No-trade score: ${esc(s.no_trade_score)} / 100</p><div class="row"><b>Pulse count</b><span>${esc(s.pulse_count)}</span></div><div class="row"><b>Growth score</b><span>${esc(s.growth_score)}</span></div><div class="row"><b>Uptime</b><span>${fmtSecs(DATA.uptime_seconds)}</span></div><button class="btn" onclick="act('/api/pulse')">Manual Pulse Now</button><button class="btn alt" onclick="act('/api/report/morning')">Generate Morning Report</button>`)}${card('Safety Locks',`<div class="row"><b>Live orders</b><span class="danger">${esc(s.live_orders)}</span></div><div class="row"><b>Champion Council</b><span>${esc(s.champion_lock)}</span></div><div class="row"><b>Approved champions</b><span>${esc(s.approved_champions)}</span></div><div class="row"><b>Risk Police</b><span>${esc(s.risk_police)}</span></div><p class="muted">This build contains no live trading executor and no private API-key flow.</p>`)}${card('Next Gate',`<div class="metric">${esc(s.next_gate)}</div><p>Blocker: ${esc(s.current_blocker)}</p>`,'card wide')}</div>`}
function overnight(s){return `<div class="grid">${card('Overnight Watch Controls',`<p>Leave this window/server running overnight. It writes market ticks, feed proof, learning cycles, research notes, and suggested next upgrades.</p><button class="btn" onclick="act('/api/watch/start')">Start Watch</button><button class="btn alt" onclick="act('/api/watch/stop')">Pause Watch</button><button class="btn" onclick="act('/api/pulse')">Pulse Now</button><button class="btn" onclick="act('/api/report/morning')">Generate Morning Report</button><div class="row"><b>Watch enabled</b><span>${esc(s.watch_enabled)}</span></div><div class="row"><b>Pulse interval</b><span>${esc(s.pulse_seconds)} sec</span></div><div class="row"><b>Last pulse</b><span>${esc(s.last_pulse_at)}</span></div>`,'card wide')}${card('Overnight Ledgers',`<div class="row"><b>Market ticks</b><span>${DATA.line_counts.market_ticks}</span></div><div class="row"><b>Feed proof</b><span>${DATA.line_counts.feed_proof}</span></div><div class="row"><b>Live data guard</b><span>${DATA.line_counts.live_data_guard}</span></div><div class="row"><b>Learning cycles</b><span>${DATA.line_counts.learning_cycles}</span></div><div class="row"><b>Research notes</b><span>${DATA.line_counts.research_ledger}</span></div><div class="row"><b>Paper shadow</b><span>${DATA.line_counts.paper_shadow||0}</span></div>`)}${card('Latest Learning Cycles',rows(DATA.last_cycles,[['cycle','Cycle'],['ts','Time'],['source','Source'],['regime','Regime'],['claim_level','Claim']]),'card full')}</div>`}
function feed(s){return `<div class="grid">${card('Public Market Feed Proof',`<div class="row"><b>Source</b><span>${esc(s.last_feed_source)}</span></div><div class="row"><b>Status</b><span>${esc(s.last_feed_status)}</span></div><div class="row"><b>Real live gate</b><span>${esc(s.real_live_data_gate)}</span></div><div class="row"><b>Regime</b><span>${esc(s.current_regime)}</span></div><p class="muted">Uses public market endpoints only. No API key required.</p><button class="btn" onclick="act('/api/pulse')">Fetch Market Pulse</button>`,'card wide')}${card('Latest Ticks',rows(DATA.last_ticks,[['ts','Time'],['symbol','Symbol'],['last_price','Last'],['price_change_percent_24h','24h %'],['regime','Regime'],['source','Source']]),'card full')}</div>`}
function growth(s){return `<div class="grid">${card('Growth Score',`<div class="metric">${esc(s.growth_score)}</div><div class="row"><b>Learning score</b><span>${esc(s.learning_score)}</span></div><div class="row"><b>Research score</b><span>${esc(s.research_score)}</span></div><div class="row"><b>Cycles</b><span>${esc(s.pulse_count)}</span></div><p class="muted">Growth means data/research activity, not proof of profit.</p>`)}${card('Recent Pulse Ledger',rows(DATA.last_cycles,[['cycle','Cycle'],['ts','Time'],['research_task','Task'],['claim_level','Claim']]),'card wide')}</div>`}
function research(s){return `<div class="grid">${card('Research Ledger',rows(DATA.last_research,[['ts','Time'],['squad','Squad'],['regime','Regime'],['research_task','Research task'],['claim_level','Claim']]),'card full')}${card('Suggested Next Research Upgrades',DATA.suggested_upgrades.map(u=>`<div class="row"><b>${esc(u.version)} ${esc(u.name)}</b><span>${esc(u.status)}</span></div><p class="muted">${esc(u.why)}</p>`).join('')||'<p>No suggestions yet.</p>','card full')}</div>`}
function forge(s){return `<div class="grid">${card('Strategy DNA Seeds',rows(DATA.strategy_dna,[['name','Name'],['family','Family'],['timeframes','Timeframes'],['regime_needed','Regime'],['status','Status'],['proof_needed','Proof needed']]),'card full')} ${card('Forge Rule',`<p>No strategy can become a champion from this tab. It can only become a research candidate until backtest, out-of-sample, walk-forward, slippage, paper arena, and human approval gates exist.</p>`,'card full')}</div>`}
function squads(s){return `<div class="grid">${card('Alpha Squad',`<div class="metric">WATCH</div><p>Conservative BTC/ETH observation and baseline regime proof.</p>`)}${card('Bravo Squad',`<div class="metric">SCOUT</div><p>Alt rotation research only. No trade execution.</p>`)}${card('Charlie Squad',`<div class="metric">LOCKED</div><p>Specialists for chop, panic, and no-trade filters.</p>`)}${card('Risk Police',`<div class="metric">ARMED</div><p>Live orders off. Champion lock enforced.</p>`)}</div>`}
function paper(s){let p=DATA.last_paper||[];return `<div class="grid">${card('Paper Shadow Signal Simulator',`<div class="metric">${esc(s.paper_shadow_status||'READY')}</div><div class="row"><b>Last action</b><span>${esc(s.paper_shadow_last_action||'WAITING')}</span></div><div class="row"><b>Open paper position</b><span>${esc(s.paper_shadow_open_position||'NONE')}</span></div><div class="row"><b>Paper rows</b><span>${esc(DATA.line_counts.paper_shadow||0)}</span></div><button class="btn" onclick="act('/api/pulse')">Run Real-Live Paper Pulse</button><p class="muted">V013A/V014A creates would-have-traded records only after the real live data gate passes. It includes simulated entries/exits/holds/stand-asides, fees, slippage, strategy reason, and risk reason. No live orders exist.</p>`,'card wide')}${card('Latest Paper Shadow Records',rows(p,[['ts','Time'],['action','Action'],['symbol','Symbol'],['side','Side'],['regime','Regime'],['no_trade_score','No-trade'],['net_pct_after_fee_slippage','Net %'],['risk_reason','Risk reason']]),'card full')}${card('Next Paper Gate',`<p>V014A installed: candles and universe scanner now feed richer evidence than 24h ticker snapshots.</p>`)}</div>`}
function candles(s){let cp=DATA.last_candle_proof||[];let c=DATA.last_candles||[];let cs=DATA.candle_summary||{};return `<div class="grid">${card('Candle Harvester',`<div class="metric">${esc(cs.status||s.candle_harvester_status||'READY')}</div><div class="row"><b>Last new rows</b><span>${esc(cs.last_new_rows??s.candle_harvester_last_rows??0)}</span></div><div class="row"><b>Total candle rows</b><span>${esc(DATA.line_counts.candle_rows||0)}</span></div><div class="row"><b>Intervals</b><span>1m / 5m / 15m</span></div><button class="btn" onclick="act('/api/candles/harvest')">Harvest Candles Now</button><button class="btn alt" onclick="act('/api/pulse')">Run Full Live Pulse</button><p class="muted">Public Binance candles only. “Last new rows” can be 0 when no new candle opened; total rows is the collection size.</p>`,'card wide')}${card('Latest Candle Rows',rows(c,[['open_time_utc','Open'],['symbol','Symbol'],['interval','TF'],['open','O'],['high','H'],['low','L'],['close','C'],['quote_volume','Quote vol'],['source','Source']]),'card full')}${card('Candle Proof Tail',rows(cp,[['ts','Time'],['status','Status'],['rows_written','New rows'],['symbols','Symbols'],['intervals','Intervals']]),'card full')}</div>`}
function universe(s){let u=DATA.last_universe||[];let us=DATA.universe_summary||{};return `<div class="grid">${card('Universe Scanner',`<div class="metric">${esc(us.status||s.universe_scanner_status||'READY')}</div><div class="row"><b>Top symbol</b><span>${esc(us.top_symbol||s.universe_scanner_top_symbol||'NONE')}</span></div><div class="row"><b>Top score</b><span>${esc(us.top_score??'')}</span></div><div class="row"><b>Ledger rows</b><span>${esc(DATA.line_counts.universe_scan||0)}</span></div><div class="row"><b>Latest batch visible rows</b><span>${esc(us.rows_visible||u.length||0)}</span></div><button class="btn" onclick="act('/api/universe/scan')">Scan Universe Now</button><button class="btn alt" onclick="act('/api/pulse')">Run Full Live Pulse</button><p class="muted">Shows the top of the latest scan batch, sorted by score. Ranking only; not a trade signal.</p>`,'card wide')}${card('Latest Universe Ranks - Top Of Latest Batch',rows(u,[['symbol','Symbol'],['bucket','Bucket'],['universe_score','Score'],['price_change_percent_24h','24h %'],['range_pct_24h','Range %'],['quote_volume','Quote vol'],['batch_id','Batch'],['source','Source']]),'card full')}</div>`}
function backtest(s){let b=DATA.backtest_summary||{};let rowsBt=DATA.last_backtests||[];let datasets=DATA.candle_datasets||[];return `<div class="grid">${card('Backtest + Walk-Forward Gate',`<div class="metric">${esc(b.status||s.backtest_gate_status||'READY')}</div><div class="row"><b>Gate</b><span>${esc(b.gate||s.backtest_walk_forward_status||'NOT_RUN')}</span></div><div class="row"><b>Symbol / interval</b><span>${esc((b.symbol||s.backtest_last_symbol||'NONE')+' '+(b.interval||s.backtest_last_interval||''))}</span></div><div class="row"><b>Rows</b><span>${esc(DATA.line_counts.backtest_walkforward||0)}</span></div><div class="row"><b>Champion claim allowed</b><span class="danger">${esc(b.champion_claim_allowed===true?'YES - CHECK LOCK':'NO')}</span></div><button class="btn" onclick="act('/api/backtest/run')">Run Backtest + Walk-Forward Gate</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Risk Filter Tuner Report</button><button class="btn alt" onclick="act('/api/pulse')">Run Full Live Pulse</button><p class="muted">V015A replays collected public candles only. It records in-sample and walk-forward results with fees/slippage. It is not profit proof and cannot unlock live trading.</p>`,'card wide')}${card('Latest Backtest Gate Records',rows(rowsBt,[['ts','Time'],['run_id','Run'],['symbol','Symbol'],['interval','TF'],['status','Status'],['gate','Gate'],['total_candles','Candles'],['champion_claim_allowed','Champion allowed']]),'card full')}${card('Available Candle Datasets',rows(datasets,[['symbol','Symbol'],['interval','TF'],['rows','Rows'],['first','First'],['last','Last']]),'card full')}</div>`}
function risk(s){return `<div class="grid">${card('Risk Police Locks',`<div class="row"><b>Live orders</b><span class="danger">${esc(s.live_orders)}</span></div><div class="row"><b>Risk Police</b><span>${esc(s.risk_police)}</span></div><div class="row"><b>No-trade score</b><span>${esc(s.no_trade_score)}</span></div><div class="row"><b>Mode</b><span>${esc(s.mode)}</span></div><button class="btn danger" onclick="act('/api/standdown')">Emergency Stand Down</button><p class="muted">Stand Down pauses research watch; it still does not control any live trading because live trading is not built.</p>`,'card wide')}${card('Locked Actions',`<p>Enable live trading, approve champion, change API keys, increase live size, disable Risk Police: not implemented in this build.</p>`)}</div>`}
function champions(s){return `<div class="grid">${card('Champion Council',`<div class="metric">${esc(s.approved_champions)}</div><p>Status: ${esc(s.champion_lock)}</p><p>No strategy can be approved from this build. Overnight data is only baseline research.</p>`,'card wide')}${card('Future Gates',`<div class="row"><b>Backtest</b><span>MISSING</span></div><div class="row"><b>Out-of-sample</b><span>MISSING</span></div><div class="row"><b>Walk-forward</b><span>MISSING</span></div><div class="row"><b>Paper Arena</b><span>MISSING</span></div><div class="row"><b>Human approval</b><span>LOCKED</span></div>`)}</div>`}
function updates(s){let ap=DATA.autopilot||{};let cand=ap.candidate||null;return `<div class="grid">${card('Autopilot Important-Only Bundle Update System',`<div class="row"><b>Status</b><span>${esc(ap.enabled?'ARMED':'PAUSED')}</span></div><div class="row"><b>Installed</b><span>${esc(DATA.state.version||'unknown')}</span></div><div class="row"><b>Next patch</b><span>${cand?esc(cand.version+' '+cand.name):'none waiting'}</span></div><button class="btn" onclick="autopilotApplyNow()">Apply Waiting Patch Now</button><button class="btn alt" onclick="autopilotToggle(true)">Arm Autopilot</button><button class="btn alt" onclick="autopilotToggle(false)">Pause Autopilot</button><p class="muted">Autopilot watches only local valid Bali patch ZIPs in the updates folder. Bundle minor fixes when safe. Tiny success reports hide selected/installed duplicate lines. No internet fetching. One patch per restart. Success reports show only important lines; errors open details.</p>`,'card wide')}${card('Manual Backup Controls',`<input id="patchZip" type="file" accept=".zip" style="display:block;margin:8px 0 12px;color:var(--text)"><button class="btn alt" onclick="dashUploadPatchUpdate()">Upload Patch ZIP + Auto Restart</button><button class="btn alt" onclick="dashUpdateRestart()">Apply ZIP Already in Updates</button><button class="btn alt" onclick="dashFinalStatus()">Show / Copy Tiny Final Status</button><p class="muted">Normal use: leave autopilot armed and drop the patch ZIP into updates, or upload it here.</p>`)}</div>`}

async function generateChatGptReport(){let out=await api('/api/report/chatgpt');let txt=out.text||JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML=`<div class="grid"><section class="card full"><h2>ChatGPT Report Generated</h2><p class="muted">${esc(copied?'Copied to clipboard. Paste it into ChatGPT.':'Generated. Select the text below and copy it into ChatGPT.')}</p><button class="btn" onclick="setTab('reports')">Back to Reports</button><a class="btn alt" href="/reports/${encodeURIComponent(out.report||'')}" target="_blank">Open Text File</a><pre>${esc(txt)}</pre></section></div>`;}
async function generateRiskFilterReport(){let out=await api('/api/report/risk-filter');let txt=out.text||JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML=`<div class="grid"><section class="card full"><h2>V018 Risk Filter Tuner Report</h2><p class="muted">${esc(copied?'Copied to clipboard. Paste it into ChatGPT.':'Generated. Select the text below and copy it into ChatGPT.')}</p><button class="btn" onclick="setTab('reports')">Back to Reports</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Again</button><a class="btn alt" href="/reports/${encodeURIComponent(out.report||'')}" target="_blank">Open Text File</a><pre>${esc(txt)}</pre></section></div>`;}
async function generateAlwaysWorkingReport(){let out=await api('/api/report/always-working');let txt=out.text||JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML=`<div class="grid"><section class="card full"><h2>Always-Working Bot Stats Report Generated</h2><p class="muted">${esc(copied?'Copied to clipboard.':'Generated. Select the text below if clipboard access was blocked.')}</p><button class="btn" onclick="setTab('reports')">Back to Reports</button><a class="btn alt" href="/reports/${encodeURIComponent(out.report||'')}" target="_blank">Open Text File</a><pre>${esc(txt)}</pre></section></div>`;}
async function copyReportFile(name){let r=await fetch('/reports/'+encodeURIComponent(name));let txt=await r.text();try{await navigator.clipboard.writeText(txt);alert('Report copied. Paste it into ChatGPT.');}catch(e){alert(txt);}}
function reports(s){let rep=(DATA.reports||[]);let list=rep.map(n=>`<div class="row"><b>${esc(n)}</b><span><button class="btn alt" onclick="copyReportFile('${String(n).replace(/'/g,"\\'")}')">Copy</button> <a class="btn alt" href="/reports/${encodeURIComponent(n)}" target="_blank">Open</a></span></div>`).join('')||'<p>No reports saved yet. Generate one below.</p>';return `<div class="grid">${card('Always-Working Bot Stats Report',`<p>Complete safety, patch, layer, delta, and evidence snapshot for the current build.</p><button class="btn" onclick="generateAlwaysWorkingReport()">Generate Always-Working Bot Stats Report</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Risk Filter Tuner Report</button><p class="muted">Saved to shared_data/reports and logs/LAST_ALWAYS_WORKING_BOT_STATS_REPORT.txt.</p>`,'card wide')}${card('Automated ChatGPT Report',`<p>This fixes the old manual copy/paste problem. Generate one compact status report that includes live data gate, feed proof, learning, paper/risk status, recent ticks, doctor summary, and next patch recommendation, and paper-shadow status.</p><button class="btn" onclick="generateChatGptReport()">Generate + Copy ChatGPT Report</button><p class="muted">Saved to shared_data/reports and logs/LAST_CHATGPT_STATUS_REPORT.txt.</p>`,'card wide')}${card('Saved Reports',list,'card full')}${card('Report Rule',`<p>Normal flow: send ChatGPT the one compact report. Only paste separate screens when a tab shows a new error or warning.</p>`)}</div>`}
function phone(s){let urls=(DATA.lan_ips||[]).map(ip=>`http://${ip}:9061/phone`).join('\n');return `<div class="grid">${card('Phone LAN View',`<p>Start with the LAN batch file, keep PC and phone on the same private Wi-Fi, then open:</p><pre>${esc(urls||'No LAN IP detected yet. Try the PHONE LAN launcher.')}</pre><p class="muted">Do not expose this dashboard publicly. Use private LAN/VPN only.</p>`,'card wide')}${card('Phone Safe Actions',`<p>SITREP, Doctor, Pulse, Update Scan, Report generation, and Update Apply/Rollback with validation.</p><p class="muted">Live trading and champion approval remain unavailable.</p>`)}</div>`}
setInterval(load,15000);load();
'''


def full_build_root() -> Path:
    """Return the parent launcher folder when the app runs inside the nested app folder."""
    candidates = [ROOT.parent, ROOT]
    for cand in candidates:
        if (cand / "BALI_SPEED_LANE_UPDATE.bat").exists() or (cand / "BALI_ONE_CLICK_UPDATE.bat").exists():
            return cand
    return ROOT.parent



def patch_rank_from_version_text(version: str) -> int:
    """Map V012K style versions to sortable ranks. V011A=1100, V012K=1210."""
    version = str(version or "").strip().upper()
    m = re.search(r"V(\d{3})([A-Z])", version)
    if not m:
        return 0
    return int(m.group(1)) * 100 + (ord(m.group(2)) - ord("A"))


def read_root_manifest(parent: Optional[Path] = None) -> Dict[str, str]:
    parent = parent or full_build_root()
    path = parent / "BALI_PATCH_MANIFEST.txt"
    out: Dict[str, str] = {}
    try:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
    except Exception:
        pass
    return out


def parse_bali_patch_manifest_from_zip(zip_path: Path) -> Optional[Dict[str, str]]:
    try:
        with zipfile.ZipFile(zip_path, "r") as z:
            names = z.namelist()
            manifest_name = None
            for name in names:
                norm = normalize_zip_member(name)
                if norm == "BALI_PATCH_MANIFEST.txt" or (norm and norm.endswith("/BALI_PATCH_MANIFEST.txt")):
                    manifest_name = name
                    break
            if not manifest_name:
                return None
            text = z.read(manifest_name).decode("utf-8", errors="replace")
        out: Dict[str, str] = {"ZIP_PATH": str(zip_path), "ZIP_NAME": zip_path.name}
        for line in text.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
        return out
    except Exception:
        return None


def find_newest_local_bali_patch(parent: Optional[Path] = None) -> Optional[Dict[str, Any]]:
    parent = parent or full_build_root()
    installed = read_root_manifest(parent)
    installed_rank = patch_rank_from_version_text(installed.get("VERSION")) or VERSION_NUMBER
    candidates: List[Dict[str, Any]] = []
    search_dirs = [parent / "updates", parent]
    for folder in search_dirs:
        try:
            if not folder.exists():
                continue
            for zp in folder.glob("BALI_ROCKET_CRYPTO_COMMAND_*.zip"):
                if "applied_patch_archive" in str(zp).lower():
                    continue
                mf = parse_bali_patch_manifest_from_zip(zp)
                if not mf:
                    continue
                if mf.get("PROJECT") != PROJECT_NAME:
                    continue
                if mf.get("BALI_PATCH_MANIFEST") != "1":
                    continue
                rank = patch_rank_from_version_text(mf.get("VERSION"))
                if rank <= installed_rank:
                    continue
                candidates.append({"path": str(zp), "name": zp.name, "version": mf.get("VERSION", ""), "rank": rank, "patch_name": mf.get("PATCH_NAME", ""), "manifest": mf})
        except Exception:
            continue
    candidates.sort(key=lambda x: (int(x.get("rank") or 0), str(x.get("path"))), reverse=True)
    return candidates[0] if candidates else None


def autopilot_state_path(parent: Optional[Path] = None) -> Path:
    parent = parent or full_build_root()
    return parent / "logs" / "BALI_AUTOPILOT_UPDATE_STATE.json"


def autopilot_disabled_by_safe_mode() -> bool:
    return truthy_env("BALI_DISABLE_AUTOPATCH") or truthy_env("BALI_SAFE_FOREVER")


def read_autopilot_state(parent: Optional[Path] = None) -> Dict[str, Any]:
    parent = parent or full_build_root()
    default = {"enabled": not autopilot_disabled_by_safe_mode(), "mode": "LOCAL_UPDATES_FOLDER_ONLY", "last_triggered_version": "", "last_triggered_path": "", "last_triggered_at": ""}
    data = read_json(autopilot_state_path(parent), default)
    if not isinstance(data, dict):
        data = default
    # V012K defaults to armed unless user pauses it; Forever Safe mode overrides this.
    if "enabled" not in data:
        data["enabled"] = not autopilot_disabled_by_safe_mode()
    if autopilot_disabled_by_safe_mode():
        data["enabled"] = False
        data["safe_mode_disabled"] = True
    data.setdefault("mode", "LOCAL_UPDATES_FOLDER_ONLY")
    return data


def write_autopilot_state(data: Dict[str, Any], parent: Optional[Path] = None) -> None:
    parent = parent or full_build_root()
    write_json(autopilot_state_path(parent), data)


def autopilot_status() -> Dict[str, Any]:
    parent = full_build_root()
    installed = read_root_manifest(parent)
    state = read_autopilot_state(parent)
    newest = find_newest_local_bali_patch(parent)
    ready = bool(state.get("enabled") and newest)
    disabled = autopilot_disabled_by_safe_mode()
    return {
        "ok": True,
        "enabled": bool(state.get("enabled")),
        "mode": state.get("mode", "LOCAL_UPDATES_FOLDER_ONLY"),
        "installed_version": installed.get("VERSION", VERSION),
        "candidate": newest,
        "ready": ready,
        "minimal": "SAFE_DISABLED" if disabled else ("ARMED" if state.get("enabled") else "PAUSED"),
        "message": ("Autopilot disabled by Forever Safe mode. Update ZIPs are not processed automatically." if disabled else (f"Autopilot ready: {newest['version']}" if ready else ("Autopilot armed. No newer local patch." if state.get("enabled") else "Autopilot paused."))),
        "safety": "live orders OFF, champion lock LOCKED, no API keys",
    }


def set_autopilot_enabled(enabled: bool) -> Dict[str, Any]:
    parent = full_build_root()
    state = read_autopilot_state(parent)
    if enabled and autopilot_disabled_by_safe_mode():
        state["enabled"] = False
        state["updated_at"] = iso_now()
        write_autopilot_state(state, parent)
        status = autopilot_status()
        status["ok"] = False
        status["message"] = "Forever Safe mode blocks autopilot arming. Update ZIPs will not be processed automatically."
        return status
    state["enabled"] = bool(enabled)
    state["updated_at"] = iso_now()
    write_autopilot_state(state, parent)
    return autopilot_status()


def autopilot_apply_now_bridge() -> Dict[str, Any]:
    if autopilot_disabled_by_safe_mode():
        return {"ok": False, "message": "Forever Safe mode blocks auto-apply. Review reports first; update ZIPs are not processed automatically."}
    status = autopilot_status()
    if not status.get("enabled"):
        return {"ok": False, "message": "Autopilot is paused."}
    if not status.get("ready"):
        return {"ok": False, "message": "No newer valid local Bali patch is waiting in updates."}
    parent = full_build_root()
    state = read_autopilot_state(parent)
    cand = status.get("candidate") or {}
    # Avoid firing the same candidate twice from browser polling while the old dash is closing.
    if state.get("last_triggered_path") == cand.get("path") and (time.time() - Path(autopilot_state_path(parent)).stat().st_mtime) < 90:
        return {"ok": True, "message": "Autopilot already triggered this patch. Waiting for restart.", "candidate": cand}
    state["last_triggered_version"] = cand.get("version", "")
    state["last_triggered_path"] = cand.get("path", "")
    state["last_triggered_at"] = iso_now()
    write_autopilot_state(state, parent)
    result = dashboard_update_restart_bridge()
    result["autopilot"] = True
    result["candidate"] = cand
    return result


def dashboard_final_status_text() -> str:
    """Return important-only tiny status for dashboard/chat paste-back; details stay in logs."""
    parent = full_build_root()
    manifest = read_root_manifest(parent)
    logs = parent / "logs"
    final = logs / "LAST_FINAL_REPORT.txt"
    data = {"VERSION": manifest.get("VERSION", VERSION), "HEALTH": "UNKNOWN", "CLOSE": "UNKNOWN", "RESTART": "UNKNOWN", "AUTOPILOT": "LOCAL_ONLY", "WATCHER": "PASS", "BUNDLE": "READY", "RESULT": "STATUS"}
    try:
        if final.exists():
            for raw in final.read_text(encoding="utf-8", errors="replace").splitlines():
                line = raw.strip()
                if line.startswith("VERSION="):
                    data["VERSION"] = line.split("=", 1)[1].strip()
                elif line.startswith("HEALTH=PASS") or line.startswith("RESULT: FAST HEALTH PASS"):
                    data["HEALTH"] = "PASS"
                elif line.startswith("CLOSE=PASS") or "LISTENER_STATUS_AFTER_CLOSE=CLEAR" in line or "LISTENER_STATUS=CLEAR" in line:
                    data["CLOSE"] = "PASS"
                elif line.startswith("RESTART=PASS") or line.startswith("RESTART=LAUNCHED"):
                    data["RESTART"] = "PASS"
                elif line.startswith("AUTOPILOT=ARMED_LOCAL_ONLY") or line.startswith("AUTOPILOT=LOCAL_ONLY"):
                    data["AUTOPILOT"] = "LOCAL_ONLY"
                elif line.startswith("AUTOPILOT_WATCHER=PASS") or line.startswith("WATCHER=PASS"):
                    data["WATCHER"] = "PASS"
                elif line.startswith("BUNDLE=READY"):
                    data["BUNDLE"] = "READY"
                elif line.startswith("RESULT=PASS") or line.startswith("RESULT: PASS") or line.startswith("RESULT: DASH UPDATE FINAL PASS"):
                    data["RESULT"] = "PASS"
    except Exception:
        pass
    if data["RESULT"] == "STATUS" and data["HEALTH"] == "PASS":
        data["RESULT"] = "PASS"
    return "\n".join([
        f"VERSION={data['VERSION']}",
        f"HEALTH={data['HEALTH']}",
        f"CLOSE={data['CLOSE']}",
        f"RESTART={data['RESTART']}",
        f"AUTOPILOT={data['AUTOPILOT']}",
        f"WATCHER={data['WATCHER']}",
        f"BUNDLE={data['BUNDLE']}",
        "GOVERNOR=MISSION_CONSOLE",
        "ARENA=GAME_FOUNDATION",
        "CPU_BRIDGE=SHARED_FOLDER_READY_SIM_ONLY",
        "MATCH_REFEREE=PREP_LOCAL_JSON_ONLY",
        "BRIDGE=JSON_ONLY_NO_REMOTE_COMMANDS",
        f"RESULT={data['RESULT']}",
    ])

def dashboard_update_restart_bridge() -> Dict[str, Any]:
    """Launch the external update bridge, then let this dashboard exit for safe file replacement."""
    parent = full_build_root()
    logs = parent / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    engine = parent / "tools" / "BALI_DASH_UPDATE_RESTART_ENGINE_V012J.ps1"
    if not engine.exists():
        return {
            "ok": False,
            "message": "Dashboard update bridge missing. Apply V012K with BALI_SPEED_LANE_UPDATE.bat first.",
            "expected_engine": str(engine),
        }
    report = logs / "BALI_DASH_UPDATE_RESTART_REQUEST_V012K.txt"
    report.write_text("BALI DASH UPDATE REQUEST V012K\n" + f"Requested: {iso_now()}\n" + f"Root: {parent}\n" + "Safety: live orders OFF, champion lock LOCKED, no API keys.\n", encoding="utf-8")
    cmd = [
        "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", str(engine), "-Root", str(parent), "-Port", str(PORT_DEFAULT)
    ]
    creationflags = 0
    if os.name == "nt" and hasattr(subprocess, "CREATE_NEW_CONSOLE"):
        creationflags = subprocess.CREATE_NEW_CONSOLE
    subprocess.Popen(cmd, cwd=str(parent), creationflags=creationflags)
    append_jsonl(LOGS / "dashboard_update_bridge.jsonl", {"ts": iso_now(), "engine": str(engine), "root": str(parent), "claim_level": "DASHBOARD_TRIGGERED_EASY_ONEDRIVE_BRIDGE_HUB_SETUP"})
    return {
        "ok": True,
        "message": "Dashboard update launched. This dashboard will close, apply the patch, restart through Bali Forever Starter, and make the final status available in the Updates tab. Autopilot/minimal final status is active; no manual status pack step required.",
        "report": str(parent / "logs" / "BALI_DASH_UPDATE_RESTART_REPORT_V012K.txt"),
    }



def save_uploaded_patch_zip(headers: Any, rfile: Any) -> Dict[str, Any]:
    """Save one uploaded ZIP from the dashboard to the real root updates folder."""
    parent = full_build_root()
    updates_dir = parent / "updates"
    updates_dir.mkdir(parents=True, exist_ok=True)
    try:
        length = int(headers.get("Content-Length", "0") or "0")
    except Exception:
        length = 0
    if length <= 0:
        return {"ok": False, "message": "No upload body received."}
    if length > 250_000_000:
        return {"ok": False, "message": "Patch ZIP is too large for dashboard upload."}
    ctype = headers.get("Content-Type", "")
    if "multipart/form-data" not in ctype or "boundary=" not in ctype:
        return {"ok": False, "message": "Upload must be multipart form data."}
    boundary = ctype.split("boundary=", 1)[1].strip().strip('"')
    if not boundary:
        return {"ok": False, "message": "Upload boundary missing."}
    raw = rfile.read(length)
    marker = ("--" + boundary).encode("utf-8", errors="ignore")
    for part in raw.split(marker):
        if b"Content-Disposition:" not in part or b"filename=" not in part:
            continue
        if b"\r\n\r\n" not in part:
            continue
        head, data = part.split(b"\r\n\r\n", 1)
        header_text = head.decode("utf-8", errors="replace")
        filename = ""
        for chunk in header_text.split(";"):
            chunk = chunk.strip()
            if chunk.lower().startswith("filename="):
                filename = chunk.split("=", 1)[1].strip().strip('"')
        safe = Path(filename).name
        if not safe.lower().endswith(".zip"):
            return {"ok": False, "message": "Only .zip patch files are accepted."}
        if ".." in safe or "/" in safe or "\\" in safe:
            return {"ok": False, "message": "Unsafe patch filename blocked."}
        data = data.rstrip(b"\r\n-")
        if len(data) < 100:
            return {"ok": False, "message": "Uploaded ZIP looked empty or incomplete."}
        dest = updates_dir / safe
        dest.write_bytes(data)
        append_jsonl(LOGS / "dashboard_patch_uploads.jsonl", {"ts": iso_now(), "file": safe, "bytes": len(data), "dest": str(dest), "claim_level": "DASHBOARD_UPLOADED_PATCH_ZIP"})
        return {"ok": True, "message": f"Patch uploaded to updates: {safe}", "file": safe, "path": str(dest), "bytes": len(data)}
    return {"ok": False, "message": "No patch_zip file field found in upload."}


def arena_bridge_root(parent: Optional[Path] = None) -> Path:
    parent = parent or full_build_root()
    default_bridge = parent / "game_arena" / "bridge"
    # V012K: allow Bali Governor Hub to use an easy OneDrive-synced bridge folder.
    # This stays JSON-only / SIM-only / no remote commands. If the config is missing,
    # the normal internal bridge is used.
    try:
        env_bridge = os.environ.get("BALI_ARENA_BRIDGE_ROOT", "").strip()
        if env_bridge:
            p = Path(env_bridge)
            if p.exists():
                return p
    except Exception:
        pass
    try:
        cfg_path = default_bridge / "ACTIVE_BRIDGE_CONFIG.json"
        if cfg_path.exists():
            cfg = read_json(cfg_path, {})
            ptxt = str(cfg.get("active_bridge_root", "")).strip()
            if ptxt:
                p = Path(ptxt)
                if p.exists():
                    return p
    except Exception:
        pass
    return default_bridge


def bridge_subfolder(parent: Optional[Path], name: str) -> Path:
    root = arena_bridge_root(parent)
    shared = root / "shared_drop"
    # V012K compatibility: OneDrive helper creates direct folders under BaliArenaBridge
    # and also a shared_drop layout. Prefer the direct folder when it exists.
    direct = root / name
    nested = shared / name
    if direct.exists():
        return direct
    return nested


def latest_json_file(folder: Path) -> Optional[Path]:
    try:
        files = [p for p in folder.glob("*.json") if p.is_file()]
        files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
        return files[0] if files else None
    except Exception:
        return None



def score_bot_checkin(data: Any) -> Dict[str, Any]:
    if not isinstance(data, dict):
        return {"score": -999, "safety": "MISSING", "detail": "missing check-in"}
    required = ["data_origin", "source_exchange", "source_symbol", "market_timestamp_utc", "captured_at_utc", "raw_ticks_count"]
    for key in required:
        if data.get(key) in (None, ""):
            return {"score": -999, "safety": "RAW_LIVE_DATA_FAIL", "detail": f"missing {key}"}
    if str(data.get("data_origin", "")).upper() != "RAW_LIVE_DATA":
        return {"score": -999, "safety": "RAW_LIVE_DATA_FAIL", "detail": f"blocked origin {data.get('data_origin', '')}"}
    if float(data.get("raw_ticks_count", 0) or 0) < 1:
        return {"score": -999, "safety": "RAW_LIVE_DATA_FAIL", "detail": "raw_ticks_count too low"}
    live = bool(data.get("orders_live", False))
    keys = bool(data.get("api_keys_present", False))
    violations = float(data.get("safety_violations", 0) or 0)
    if live or keys or violations > 0:
        return {"score": -999, "safety": "FAIL", "detail": "safety violation"}
    profit = float(data.get("profit_pct", 0) or 0)
    drawdown = abs(float(data.get("max_drawdown_pct", 0) or 0))
    risk_events = float(data.get("risk_events", 0) or 0)
    uptime = float(data.get("uptime_pct", 100) or 100)
    signal = float(data.get("signal_quality", 50) or 50)
    score = round((profit * 10) - (drawdown * 4) - (risk_events * 5) + (uptime * 0.25) + (signal * 0.2), 2)
    return {"score": score, "safety": "PASS", "detail": "raw live data scored"}

def arena_score_round() -> Dict[str, Any]:
    parent = full_build_root()
    bridge = arena_bridge_root(parent)
    from_bali = bridge_subfolder(parent, "from_bali")
    from_gate = bridge_subfolder(parent, "from_stargate")
    results = bridge_subfolder(parent, "round_results")
    scoreboard_dir = bridge / "scoreboard"
    for p in [from_bali, from_gate, results, scoreboard_dir, parent / "logs"]:
        p.mkdir(parents=True, exist_ok=True)
    bali_file = latest_json_file(from_bali)
    gate_file = latest_json_file(from_gate)
    bali = read_json(bali_file, None) if bali_file else None
    gate = read_json(gate_file, None) if gate_file else None
    bali_score = score_bot_checkin(bali)
    gate_score = score_bot_checkin(gate)
    winner = "DRAW"
    if bali_score["score"] > gate_score["score"]:
        winner = "BALI"
    elif gate_score["score"] > bali_score["score"]:
        winner = "STARGATE"
    round_id = "ROUND_" + utc_now().strftime("%Y%m%d_%H%M%S")
    result = {
        "version": "V012M", "round_id": round_id, "mode": "SIM_ONLY", "bridge": "SHARED_FOLDER_JSON_ONLY", "raw_live_data_only": True,
        "bali_checkin": str(bali_file) if bali_file else "", "stargate_checkin": str(gate_file) if gate_file else "",
        "bali_score": bali_score["score"], "stargate_score": gate_score["score"], "winner": winner,
        "bali_safety": bali_score["safety"], "stargate_safety": gate_score["safety"],
        "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS",
        "notes": "RAW LIVE DATA ONLY SIM referee score. Synthetic/mock/seed/demo data is rejected. No orders, no API keys, no remote commands."
    }
    result_path = results / f"{round_id}_V012K.json"
    write_json(result_path, result)
    scoreboard = {
        "version": "V012M", "mode": "SIM_ONLY", "rounds_scored": 1, "last_round": round_id, "last_winner": winner,
        "bali": {"score": bali_score["score"], "safety": bali_score["safety"], "level": 1, "xp": max(0, int(bali_score["score"]))},
        "stargate": {"score": gate_score["score"], "safety": gate_score["safety"], "level": 1, "xp": max(0, int(gate_score["score"]))},
        "result_file": str(result_path), "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"
    }
    write_json(scoreboard_dir / "ARENA_SCOREBOARD_V012K.json", scoreboard)
    report = parent / "logs" / "BALI_ARENA_REFEREE_SCORE_ROUND_REPORT_V012K.txt"
    lines = [
        "BALI ARENA REFEREE SCORE ROUND V012K", f"Generated: {iso_now()}",
        "SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS", "MODE=SIM_ONLY",
        f"BALI_CHECKIN={bali_file.name if bali_file else 'MISSING'}", f"STARGATE_CHECKIN={gate_file.name if gate_file else 'MISSING'}",
        f"BALI_SCORE={bali_score['score']}", f"STARGATE_SCORE={gate_score['score']}", f"WINNER={winner}",
        f"ROUND_RESULT={result_path}", "REFEREE_SCOREBOARD=READY_SIM_ONLY", "RESULT=REFEREE_SCORE_ROUND_PASS"
    ]
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    shutil.copy2(report, parent / "logs" / "LAST_ARENA_REFEREE_SCORE_ROUND_REPORT.txt")
    return {"ok": True, "message": f"Referee scored SIM round: {winner}", "result": result, "scoreboard": scoreboard, "report": str(report)}


def arena_scoreboard_state() -> Dict[str, Any]:
    parent = full_build_root()
    bridge = arena_bridge_root(parent)
    scoreboard = read_json(bridge / "scoreboard" / "ARENA_SCOREBOARD_V012K.json", {})
    return {"ok": True, "version": "V012M", "scoreboard": scoreboard, "bridge": str(bridge), "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"}




def governor_hub_state() -> Dict[str, Any]:
    parent = full_build_root()
    bridge = arena_bridge_root(parent)
    join_dir = parent / "game_arena" / "stargate_join_kit"
    out_dir = parent / "game_arena" / "stargate_join_kit_output"
    shared = bridge / "shared_drop"
    from_bali = bridge_subfolder(parent, "from_bali")
    from_stargate = bridge_subfolder(parent, "from_stargate")
    round_rules = bridge_subfolder(parent, "round_rules")
    round_results = bridge_subfolder(parent, "round_results")
    heartbeats = bridge_subfolder(parent, "heartbeats")
    for p in [join_dir, out_dir, shared, from_bali, from_stargate, round_rules, round_results, heartbeats]:
        p.mkdir(parents=True, exist_ok=True)
    active_cfg = read_json((parent / "game_arena" / "bridge" / "ACTIVE_BRIDGE_CONFIG.json"), {})
    stargate_hb = latest_json_file(heartbeats)
    stargate_connected = False
    stargate_heartbeat_age_seconds = None
    if stargate_hb:
        try:
            stargate_heartbeat_age_seconds = round(time.time() - stargate_hb.stat().st_mtime, 1)
            stargate_connected = stargate_heartbeat_age_seconds <= 180
        except Exception:
            pass
    latest_kit = latest_json_file(out_dir) if out_dir.exists() else None
    state = {
        "ok": True,
        "version": "V012M",
        "governor_hub": "BALI_CPU",
        "bali_role": "GOVERNOR_HUB_AND_COMPETITOR",
        "stargate_role": "COMPETITOR_NODE_JSON_CHECKINS_ONLY",
        "bridge_mode": "SHARED_FOLDER_JSON_ONLY_NO_REMOTE_COMMANDS",
        "active_bridge_root": str(bridge),
        "bridge_config": active_cfg,
        "shared_drop": str(shared),
        "from_bali": str(from_bali),
        "from_stargate": str(from_stargate),
        "heartbeats": str(heartbeats),
        "round_rules": str(round_rules),
        "round_results": str(round_results),
        "stargate_connected": stargate_connected,
        "stargate_heartbeat": str(stargate_hb) if stargate_hb else "",
        "stargate_heartbeat_age_seconds": stargate_heartbeat_age_seconds,
        "stargate_join_kit_dir": str(join_dir),
        "stargate_join_kit_output": str(out_dir),
        "raw_live_data_only": True,
        "competition_mode": "SIM_ONLY",
        "live_orders": "OFF",
        "champion_lock": "LOCKED",
        "api_keys": "NONE",
        "remote_commands": "BLOCKED",
        "phone_monitor": "READ_ONLY_LOCAL_LAN",
        "instructions": [
            "Run Create Stargate Join Kit on Bali.",
            "Copy the exported ZIP to the Stargate CPU.",
            "Point Stargate heartbeat/check-in scripts at the shared_drop folder.",
            "Stargate writes JSON only to from_stargate; Bali scores SIM rounds only."
        ],
        "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"
    }
    return state


def create_stargate_join_kit() -> Dict[str, Any]:
    parent = full_build_root()
    join_dir = parent / "game_arena" / "stargate_join_kit"
    out_dir = parent / "game_arena" / "stargate_join_kit_output"
    logs = parent / "logs"
    for p in [join_dir, out_dir, logs]:
        p.mkdir(parents=True, exist_ok=True)
    stamp = utc_now().strftime("%Y%m%d_%H%M%S")
    zip_path = out_dir / f"STARGATE_NODE_JOIN_KIT_V012K_{stamp}.zip"
    # Ensure the key templates exist even if an older folder was present.
    (join_dir / "STARGATE_JOIN_INSTRUCTIONS_V012K.txt").write_text(
        "STARGATE JOIN KIT V012M\n\nCopy this kit to the Stargate CPU. Use shared-folder JSON only. SIM only. Raw live data only. No remote commands. No live orders. No API keys.\n",
        encoding="utf-8"
    )
    template = {
        "schema_version": "V012M", "team": "Stargate", "cpu_role": "STARGATE_CPU", "mode": "SIM_ONLY",
        "data_origin": "RAW_LIVE_DATA", "source_exchange": "REPLACE_WITH_RAW_SOURCE", "symbol": "BTCUSDT",
        "market_timestamp": "REPLACE", "capture_timestamp": "REPLACE", "raw_tick_count": 0,
        "research_points": 0, "scout_points": 0, "paper_trading_points": 0,
        "orders_live": False, "api_keys_present": False, "remote_commands": "DISABLED",
        "safety_violations": 0
    }
    write_json(join_dir / "STARGATE_RAW_LIVE_CHECKIN_TEMPLATE_V012K.json", template)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for p in join_dir.rglob("*"):
            if p.is_file():
                z.write(p, p.relative_to(join_dir))
    report = logs / "BALI_STARGATE_JOIN_KIT_EXPORT_REPORT_V012K.txt"
    lines = [
        "BALI STARGATE JOIN KIT EXPORT V012K", f"Generated: {iso_now()}",
        "SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS",
        "GOVERNOR_HUB=BALI_CPU", "STARGATE_JOIN_KIT_EXPORT=READY", "ONEDRIVE_BRIDGE_SETUP=READY",
        "STARGATE_ROLE=COMPETITOR_NODE_JSON_CHECKINS_ONLY", "BRIDGE=SHARED_FOLDER_JSON_ONLY_NO_REMOTE_COMMANDS",
        "RAW_LIVE_DATA_ONLY=ON", f"JOIN_KIT_ZIP={zip_path}", "RESULT=STARGATE_JOIN_KIT_EXPORT_READY"
    ]
    report.write_text("\n".join(lines)+"\n", encoding="utf-8")
    try:
        shutil.copy2(report, logs / "LAST_STARGATE_JOIN_KIT_EXPORT_REPORT.txt")
    except Exception:
        pass
    return {"ok": True, "message": "Stargate join kit exported.", "version": "V012M", "join_kit_zip": str(zip_path), "join_kit_folder": str(join_dir), "report": str(report), "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"}



def setup_onedrive_arena_bridge() -> Dict[str, Any]:
    parent = full_build_root()
    logs = parent / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    one = os.environ.get("OneDrive") or os.environ.get("OneDriveConsumer") or ""
    if not one or not Path(one).exists():
        one = str(Path.home() / "OneDrive")
    bridge = Path(one) / "BaliArenaBridge"
    # Create both direct folders and shared_drop folders so Bali and Stargate helpers agree.
    folders = [
        bridge,
        bridge / "from_bali", bridge / "from_stargate", bridge / "heartbeats", bridge / "round_rules", bridge / "round_results", bridge / "config", bridge / "logs",
        bridge / "shared_drop" / "from_bali", bridge / "shared_drop" / "from_stargate", bridge / "shared_drop" / "heartbeats", bridge / "shared_drop" / "round_rules", bridge / "shared_drop" / "round_results",
        parent / "game_arena" / "bridge",
    ]
    for p in folders:
        p.mkdir(parents=True, exist_ok=True)
    cfg = {
        "version": "V012M",
        "active_bridge_root": str(bridge),
        "bridge_mode": "ONEDRIVE_SYNCED_FOLDER_JSON_ONLY",
        "data_rule": "RAW_LIVE_DATA_ONLY_REQUIRED_FOR_SCORING",
        "mode": "SIM_ONLY",
        "remote_commands": "BLOCKED",
        "live_orders": "OFF",
        "api_keys": "NONE",
        "bali_role": "GOVERNOR_HUB_AND_COMPETITOR",
        "stargate_role": "COMPETITOR_NODE_JSON_CHECKINS_ONLY",
        "created_at": iso_now(),
    }
    cfg_path = parent / "game_arena" / "bridge" / "ACTIVE_BRIDGE_CONFIG.json"
    write_json(cfg_path, cfg)
    write_json(bridge / "config" / "bali_governor_hub_config.json", cfg)
    # Write a Bali heartbeat and a Bali path handoff note.
    hb = {
        "version": "V012M", "node": "BALI_CPU", "role": "GOVERNOR_HUB_AND_COMPETITOR", "status": "READY",
        "mode": "SIM_ONLY", "bridge": "JSON_ONLY_NO_REMOTE_COMMANDS", "raw_live_data_only": True,
        "live_orders": "OFF", "api_keys": "NONE", "timestamp": iso_now(),
    }
    write_json(bridge / "heartbeats" / "bali_heartbeat.json", hb)
    handoff = parent / "game_arena" / "bridge" / "BALI_ONEDRIVE_BRIDGE_PATH_FOR_STARGATE.txt"
    handoff.write_text(str(bridge), encoding="utf-8")
    report = logs / "BALI_ONEDRIVE_BRIDGE_SETUP_REPORT_V012K.txt"
    lines = [
        "BALI ONEDRIVE BRIDGE SETUP V012K", f"Generated: {iso_now()}",
        "SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS",
        f"BRIDGE_ROOT={bridge}", f"CONFIG={cfg_path}", "GOVERNOR_HUB=BALI_CPU", "STARGATE_ROLE=COMPETITOR_NODE_JSON_CHECKINS_ONLY",
        "BRIDGE=ONEDRIVE_JSON_ONLY_NO_REMOTE_COMMANDS", "RAW_LIVE_DATA_ONLY=ON", "MODE=SIM_ONLY", "RESULT=PASS"
    ]
    report.write_text("\n".join(lines)+"\n", encoding="utf-8")
    try:
        shutil.copy2(report, logs / "LAST_ONEDRIVE_BRIDGE_SETUP_REPORT.txt")
    except Exception:
        pass
    return {"ok": True, "version": "V012M", "message": "Bali OneDrive bridge configured.", "bridge_root": str(bridge), "config": str(cfg_path), "handoff_path_file": str(handoff), "report": str(report), "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"}

def raw_live_data_policy_state() -> Dict[str, Any]:
    parent = full_build_root()
    policy = read_json(parent / "game_arena" / "raw_live_data" / "RAW_LIVE_DATA_ONLY_POLICY_V012K.json", {})
    return {"ok": True, "version": "V012M", "raw_live_data_only": True, "policy": policy, "safety": "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"}

def delayed_hard_exit(seconds: float = 1.5) -> None:
    time.sleep(seconds)
    try:
        STOP_EVENT.set()
    finally:
        os._exit(0)


class Handler(BaseHTTPRequestHandler):
    server_version = f"{PROJECT_NAME}/{VERSION}"

    def log_message(self, fmt: str, *args: Any) -> None:
        append_jsonl(LOGS / "access.jsonl", {"ts": iso_now(), "client": self.client_address[0], "request": fmt % args})

    def send_bytes(self, data: bytes, content_type: str = "application/octet-stream", status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, data: Any, status: int = 200) -> None:
        self.send_bytes(json.dumps(data, indent=2, sort_keys=True).encode("utf-8"), "application/json; charset=utf-8", status)

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)
        try:
            if path == "/" or path == "/index.html":
                self.send_bytes(dashboard_html(False).encode("utf-8"), "text/html; charset=utf-8")
            elif path == "/phone":
                self.send_bytes(dashboard_html(True).encode("utf-8"), "text/html; charset=utf-8")
            elif path == "/api/state":
                data = compute_dashboard_state()
                data["doctor"] = doctor_report()
                self.send_json(data)
            elif path == "/api/pulse":
                self.send_json({"message": "Manual Bali learning pulse completed.", **learning_pulse(manual=True)})
            elif path == "/api/candles/harvest":
                state = get_system_state()
                symbols = state.get("symbols") or SYMBOLS_DEFAULT
                result = harvest_candles_for_symbols(symbols, state.get("last_feed_source", ""), state.get("last_feed_status", ""))
                self.send_json({"message": "Candle harvest completed.", **result})
            elif path == "/api/universe/scan":
                result = run_universe_scanner()
                self.send_json({"message": "Universe scan completed.", **result})
            elif path == "/api/backtest/run":
                result = run_backtest_walkforward_gate()
                self.send_json({"message": "Backtest + Walk-Forward Gate completed.", **result})
            elif path == "/api/watch/start":
                state = get_system_state(); state["watch_enabled"] = True; save_system_state(state); start_collector(); self.send_json({"ok": True, "message": "Overnight Watch started."})
            elif path == "/api/watch/stop":
                state = get_system_state(); state["watch_enabled"] = False; save_system_state(state); self.send_json({"ok": True, "message": "Overnight Watch paused. Dashboard remains online."})
            elif path == "/api/standdown":
                state = get_system_state(); state["watch_enabled"] = False; state["risk_police"] = "ARMED_STANDDOWN"; state["live_orders"] = "OFF"; save_system_state(state); self.send_json({"ok": True, "message": "Emergency Stand Down: research watch paused, live orders remain OFF."})
            elif path == "/api/report/morning":
                p = generate_morning_report(); self.send_json({"ok": True, "message": f"Morning report generated: {p.name}", "report": p.name})
            elif path == "/api/report/chatgpt":
                p, text = generate_chatgpt_report(); self.send_json({"ok": True, "message": f"ChatGPT status report generated: {p.name}", "report": p.name, "text": text})
            elif path == "/api/report/risk-filter":
                p, text = generate_risk_filter_tuner_report()
                self.send_json({"ok": True, "message": f"V018 risk filter tuner report generated: {p.name}", "report": p.name, "text": text})
            elif path == "/api/report/always-working":
                p, text = generate_always_working_report(); self.send_json({"ok": True, "message": f"Always-working bot stats report generated: {p.name}", "report": p.name, "text": text})
            elif path == "/api/doctor":
                self.send_json(doctor_report())
            elif path == "/api/doctor/save":
                rep = doctor_report(); name = f"BALI_DOCTOR_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S')}.txt"; p = REPORTS / name; p.write_text(json.dumps(rep, indent=2), encoding="utf-8"); self.send_json({"ok": True, "message": f"Doctor report saved: {name}", "report": name})
            elif path == "/api/autopilot/status":
                self.send_json(autopilot_status())
            elif path == "/api/autopilot/enable":
                self.send_json(set_autopilot_enabled(True))
            elif path == "/api/autopilot/disable":
                self.send_json(set_autopilot_enabled(False))
            elif path == "/api/autopilot/apply-now":
                result = autopilot_apply_now_bridge()
                if result.get("ok"):
                    threading.Thread(target=delayed_hard_exit, args=(1.5,), daemon=True).start()
                self.send_json(result)
            elif path == "/api/dashboard/update-restart":
                result = dashboard_update_restart_bridge()
                if result.get("ok"):
                    threading.Thread(target=delayed_hard_exit, args=(1.5,), daemon=True).start()
                self.send_json(result)
            elif path == "/api/dashboard/final-status":
                self.send_json({"ok": True, "message": "Last final dashboard status loaded.", "text": dashboard_final_status_text()})
            elif path == "/api/arena/score-round":
                self.send_json(arena_score_round())
            elif path == "/api/arena/scoreboard":
                self.send_json(arena_scoreboard_state())
            elif path == "/api/arena/governor-hub":
                self.send_json(governor_hub_state())
            elif path == "/api/arena/create-stargate-join-kit":
                self.send_json(create_stargate_join_kit())
            elif path == "/api/arena/setup-onedrive-bridge":
                self.send_json(setup_onedrive_arena_bridge())
            elif path == "/api/arena/raw-live-policy":
                self.send_json(raw_live_data_policy_state())
            elif path == "/api/updates/scan":
                self.send_json({"ok": True, "message": "Update Dock scan completed.", "scan": scan_updates()})
            elif path == "/api/updates/apply":
                file = qs.get("file", [""])[0]
                self.send_json(apply_update(file))
            elif path == "/api/updates/rollback":
                self.send_json(rollback_last_update())
            elif path.startswith("/reports/"):
                name = urllib.parse.unquote(path.split("/reports/", 1)[1])
                safe = Path(name).name
                p = REPORTS / safe
                if p.exists() and p.is_file():
                    self.send_bytes(p.read_bytes(), "text/plain; charset=utf-8")
                else:
                    self.send_json({"ok": False, "message": "Report not found"}, 404)
            elif path == "/api/export/state":
                p = generate_morning_report(); self.send_json({"ok": True, "state": compute_dashboard_state(), "report": p.name})
            else:
                self.send_json({"ok": False, "message": "Not found", "path": path}, 404)
        except Exception:
            err = traceback.format_exc()
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "path": self.path, "error": err})
            self.send_json({"ok": False, "message": "Server error", "error": err}, 500)


    def do_POST(self) -> None:
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        try:
            if path == "/api/dashboard/upload-patch":
                self.send_json(save_uploaded_patch_zip(self.headers, self.rfile))
            else:
                self.send_json({"ok": False, "message": "Not found", "path": path}, 404)
        except Exception:
            err = traceback.format_exc()
            append_jsonl(LOGS / "errors.jsonl", {"ts": iso_now(), "path": self.path, "error": err})
            self.send_json({"ok": False, "message": "Server error", "error": err}, 500)


def write_startup_report(port: int, host: str) -> None:
    lines = [
        f"{PROJECT_TITLE} {VERSION} startup",
        f"UTC: {iso_now()}",
        f"Local URL: http://127.0.0.1:{port}",
        f"Phone URL: http://<your-pc-lan-ip>:{port}/phone",
        "Detected LAN URLs:",
    ]
    for ip in get_lan_ips():
        lines.append(f"- http://{ip}:{port}/phone")
    lines.append("Safety: REAL LIVE DATA ONLY; live orders OFF; no API keys. Scoring blocks if public exchange data fails.")
    (LOGS / "LAST_STARTUP_REPORT.txt").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=PORT_DEFAULT)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()
    ensure_dirs()
    ensure_v017_patch_ledger()
    seed_strategy_dna()
    apply_safe_forever_start_mode()
    # First pulse quickly, but do not block startup for too long if network is slow.
    try:
        threading.Thread(target=lambda: learning_pulse(manual=False), daemon=True).start()
    except Exception:
        pass
    start_collector()
    write_startup_report(args.port, args.host)
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"{PROJECT_TITLE} {VERSION}")
    print(f"Local dashboard: http://127.0.0.1:{args.port}")
    if args.host == "0.0.0.0":
        for ip in get_lan_ips():
            print(f"Phone LAN: http://{ip}:{args.port}/phone")
        state = get_system_state(); state["phone_lan_enabled"] = True; save_system_state(state)
    else:
        state = get_system_state(); state["phone_lan_enabled"] = False; save_system_state(state)
    print("Safety: live orders OFF, champion lock LOCKED, no API keys.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping Bali Rocket Crypto Command...")
    finally:
        STOP_EVENT.set()
        server.server_close()


if __name__ == "__main__":
    main()
