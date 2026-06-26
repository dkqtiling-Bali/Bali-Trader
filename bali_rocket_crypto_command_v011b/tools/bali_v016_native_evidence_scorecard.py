#!/usr/bin/env python3
"""
Bali Rocket Crypto Command - V016 Native Evidence Scorecard Panel
Additive, research-only, local-file scorecard.

Safety contract:
- Does not enable live orders.
- Does not read or write API keys.
- Does not call private exchange endpoints.
- Does not unlock Champion Council.
- Does not score offline/demo rows as live proof.
"""
from __future__ import annotations
import argparse
import datetime as _dt
import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

VERSION = "V016_NATIVE_EVIDENCE_SCORECARD_PANEL"
UTC_NOW = lambda: _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat()

THRESHOLDS = {
    "paper_shadow_rows_min": 50,
    "paper_closed_trade_rows_min": 10,
    "backtest_walk_forward_rows_min": 12,
    "positive_walk_forward_rows_min": 8,
    "distinct_backtest_ids_min": 12,
    "candle_rows_min": 100,
    "universe_ledger_rows_min": 200,
    "real_live_data_gate_required": "PASS_RECENT_REAL_LIVE_DATA",
}

DANGEROUS_WORDS = (
    "LIVE_ORDERS_ON",
    "API_KEY_PRESENT",
    "PRIVATE_ENDPOINT_ENABLED",
    "CHAMPION_UNLOCKED",
)

def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return ""

def find_latest_status_report(root: Path, explicit: Optional[str] = None) -> Optional[Path]:
    if explicit:
        p = Path(explicit)
        if p.exists() and p.is_file():
            return p
    reports = root / "shared_data" / "reports"
    candidates: List[Path] = []
    if reports.exists():
        for pat in ("*.txt", "*.md", "*.log"):
            candidates.extend(reports.glob(pat))
    # Prefer compact ChatGPT reports but allow any status output.
    scored: List[Tuple[int, float, Path]] = []
    for p in candidates:
        text = read_text(p)[:12000]
        score = 0
        if "BALI CHATGPT STATUS REPORT" in text: score += 100
        if "REAL LIVE DATA GATE" in text: score += 50
        if "Backtest" in text or "BACKTEST" in text: score += 25
        if "Live orders" in text or "LIVE_ORDERS" in text: score += 15
        if "Version:" in text or "VERSION=" in text: score += 10
        try:
            mtime = p.stat().st_mtime
        except Exception:
            mtime = 0.0
        if score > 0:
            scored.append((score, mtime, p))
    if scored:
        scored.sort(key=lambda x: (x[0], x[1]), reverse=True)
        return scored[0][2]
    return None

def first_match(text: str, patterns: List[str], default: Any = None, flags: int = re.I) -> Any:
    for pat in patterns:
        m = re.search(pat, text, flags)
        if m:
            return m.group(1).strip()
    return default

def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(float(str(value).replace(",", "").strip()))
    except Exception:
        return default

def as_float(value: Any, default: Optional[float] = None) -> Optional[float]:
    try:
        return float(str(value).replace(",", "").strip())
    except Exception:
        return default

def parse_report(text: str) -> Dict[str, Any]:
    data: Dict[str, Any] = {}
    data["source_version"] = first_match(text, [r"^Version:\s*(.+)$", r"^VERSION=(.+)$"], "UNKNOWN", re.I | re.M)
    data["live_orders"] = first_match(text, [r"Live orders:\s*(OFF|ON)", r"LIVE_ORDERS_(OFF|ON)", r"Live orders\s*\n\s*(OFF|ON)"], "UNKNOWN")
    data["champion_lock"] = first_match(text, [r"Champion lock:\s*([^\n]+)", r"CHAMPION_LOCK_([A-Z_]+)", r"Champion lock\s*\n\s*([A-Z0-9_/ ]+)"], "UNKNOWN")
    data["api_keys"] = first_match(text, [r"API keys:\s*([^\n]+)", r"NO_API_KEYS", r"API keys\s*\n\s*([A-Z]+)"], "UNKNOWN")
    if data["api_keys"] == "NO_API_KEYS":
        data["api_keys"] = "NONE"
    data["mode"] = first_match(text, [r"Mode:\s*([^\n]+)"], "UNKNOWN")
    data["real_live_data_gate"] = first_match(text, [r"Gate:\s*(PASS_RECENT_REAL_LIVE_DATA|[^\n]+)", r"RAW_DATA_GATE=([^\n]+)"], "UNKNOWN")
    data["raw_data_rule"] = first_match(text, [r"Raw data gate:\s*([^\n]+)", r"Raw data rule\s*\n\s*([^\n]+)", r"RAW_LIVE_DATA_ONLY=([^\n]+)"], "UNKNOWN")
    data["warning"] = first_match(text, [r"Warning:\s*([^\n]+)", r"Warning\s*\n\s*([^\n]+)"], "UNKNOWN")
    data["stale_seconds"] = as_int(first_match(text, [r"Stale seconds:\s*([0-9]+)", r"Stale seconds\s*\n\s*([0-9]+)"], 999999), 999999)
    data["feed_source"] = first_match(text, [r"Feed source:\s*([^\n]+)", r"source=(https?://[^\s|]+)"], "UNKNOWN")
    data["ignored_offline_demo_rows"] = as_int(first_match(text, [r"Ignored recent offline_demo rows:\s*([0-9]+)"], 0), 0)
    data["paper_shadow_rows"] = as_int(first_match(text, [r"Paper shadow rows:\s*([0-9]+)", r"Paper shadow:\s*Rows:\s*([0-9]+)"], 0), 0)
    data["candle_rows_total"] = as_int(first_match(text, [r"Candle rows total:\s*([0-9]+)", r"Candle harvester:\s*Rows:\s*([0-9]+)"], 0), 0)
    data["universe_ledger_rows"] = as_int(first_match(text, [r"Universe scan ledger rows:\s*([0-9]+)", r"Universe scanner:\s*Ledger rows:\s*([0-9]+)"], 0), 0)
    data["universe_latest_rows"] = as_int(first_match(text, [r"Universe latest batch visible rows:\s*([0-9]+)", r"visible latest batch rows:\s*([0-9]+)"], 0), 0)
    data["backtest_walk_forward_rows"] = as_int(first_match(text, [r"Backtest walk-forward rows:\s*([0-9]+)", r"Backtest walk-forward gate:\s*Rows:\s*([0-9]+)"], 0), 0)
    data["backtest_gate"] = first_match(text, [r"Backtest Gate:\s*[^|\n]*\|\s*gate=([^|\n]+)", r"gate=(WALK_FORWARD_[A-Z0-9_]+)", r"Backtest walk-forward gate:.*?gate:\s*([^|\n]+)"], "UNKNOWN", re.I | re.S)
    data["champion_claim_allowed"] = first_match(text, [r"champion_claim_allowed[:=]\s*(True|False)", r"Champion claim allowed:\s*(True|False)"], "False")
    data["risk_police"] = first_match(text, [r"Risk Police:\s*([^\n]+)", r"Risk Police\s*\n\s*([A-Z]+)"], "UNKNOWN")
    # Closed paper-trade rows: count records that have a numeric net_pct, excluding None.
    net_values = re.findall(r"net_pct=([-+]?[0-9]+(?:\.[0-9]+)?)", text, re.I)
    data["paper_closed_trade_rows_visible"] = len(net_values)
    data["paper_closed_trade_net_values_visible"] = [as_float(v) for v in net_values]
    # Backtest IDs and walk-forward averages.
    data["distinct_backtest_ids_visible"] = len(set(re.findall(r"\bBT[0-9TZ]+\b", text)))
    wf_avgs = [as_float(v) for v in re.findall(r"wf_trades=\d+\s+avg=([-+]?[0-9]+(?:\.[0-9]+)?)", text, re.I)]
    wf_avgs = [v for v in wf_avgs if v is not None]
    data["walk_forward_avgs_visible"] = wf_avgs
    data["positive_walk_forward_rows_visible"] = sum(1 for v in wf_avgs if v is not None and v > 0)
    data["latest_walk_forward_avg_visible"] = wf_avgs[-1] if wf_avgs else None
    data["danger_flags"] = [w for w in DANGEROUS_WORDS if w in text]
    return data

def check(name: str, passed: bool, observed: Any, required: Any, block: bool = True, note: str = "") -> Dict[str, Any]:
    return {"name": name, "pass": bool(passed), "observed": observed, "required": required, "blocks_nomination": bool(block and not passed), "note": note}

def build_scorecard(data: Dict[str, Any], source_path: Optional[Path]) -> Dict[str, Any]:
    live_gate_ok = data.get("real_live_data_gate") == THRESHOLDS["real_live_data_gate_required"]
    safety_checks = [
        check("live_orders_off", data.get("live_orders") == "OFF", data.get("live_orders"), "OFF"),
        check("api_keys_none", str(data.get("api_keys", "")).upper().startswith("NONE") or data.get("api_keys") == "NO_API_KEYS", data.get("api_keys"), "NONE"),
        check("champion_lock_locked", "LOCK" in str(data.get("champion_lock", "")).upper(), data.get("champion_lock"), "LOCKED"),
        check("risk_police_armed", "ARMED" in str(data.get("risk_police", "")).upper(), data.get("risk_police"), "ARMED"),
        check("no_danger_flags", len(data.get("danger_flags", [])) == 0, data.get("danger_flags", []), []),
    ]
    evidence_checks = [
        check("real_live_data_gate", live_gate_ok, data.get("real_live_data_gate"), THRESHOLDS["real_live_data_gate_required"]),
        check("fresh_live_data", data.get("stale_seconds", 999999) <= 60, data.get("stale_seconds"), "<=60 seconds"),
        check("offline_demo_rows_ignored", data.get("ignored_offline_demo_rows", 0) == 0, data.get("ignored_offline_demo_rows"), 0),
        check("paper_shadow_rows", data.get("paper_shadow_rows", 0) >= THRESHOLDS["paper_shadow_rows_min"], data.get("paper_shadow_rows"), THRESHOLDS["paper_shadow_rows_min"]),
        check("paper_closed_trade_rows", data.get("paper_closed_trade_rows_visible", 0) >= THRESHOLDS["paper_closed_trade_rows_min"], data.get("paper_closed_trade_rows_visible"), THRESHOLDS["paper_closed_trade_rows_min"], note="Visible status report currently shows stand-aside rows, not enough closed simulated trades."),
        check("candle_rows", data.get("candle_rows_total", 0) >= THRESHOLDS["candle_rows_min"], data.get("candle_rows_total"), THRESHOLDS["candle_rows_min"]),
        check("universe_ledger_rows", data.get("universe_ledger_rows", 0) >= THRESHOLDS["universe_ledger_rows_min"], data.get("universe_ledger_rows"), THRESHOLDS["universe_ledger_rows_min"]),
        check("backtest_walk_forward_rows", data.get("backtest_walk_forward_rows", 0) >= THRESHOLDS["backtest_walk_forward_rows_min"], data.get("backtest_walk_forward_rows"), THRESHOLDS["backtest_walk_forward_rows_min"]),
        check("distinct_backtest_ids_visible", data.get("distinct_backtest_ids_visible", 0) >= THRESHOLDS["distinct_backtest_ids_min"], data.get("distinct_backtest_ids_visible"), THRESHOLDS["distinct_backtest_ids_min"]),
        check("positive_walk_forward_rows_visible", data.get("positive_walk_forward_rows_visible", 0) >= THRESHOLDS["positive_walk_forward_rows_min"], data.get("positive_walk_forward_rows_visible"), THRESHOLDS["positive_walk_forward_rows_min"]),
        check("backtest_gate_not_edge_not_proven", "EDGE_NOT_PROVEN" not in str(data.get("backtest_gate", "")), data.get("backtest_gate"), "not EDGE_NOT_PROVEN"),
        check("latest_walk_forward_avg_positive", (data.get("latest_walk_forward_avg_visible") is not None and data.get("latest_walk_forward_avg_visible") > 0), data.get("latest_walk_forward_avg_visible"), ">0"),
        check("champion_claim_already_false_until_gate_pass", str(data.get("champion_claim_allowed", "False")) == "False", data.get("champion_claim_allowed"), "False until V016 passes", block=False),
    ]
    all_checks = safety_checks + evidence_checks
    blockers = [c for c in all_checks if c.get("blocks_nomination")]
    nomination_allowed = len(blockers) == 0
    card = {
        "version": VERSION,
        "generated_utc": UTC_NOW(),
        "source_report": str(source_path) if source_path else None,
        "source_version": data.get("source_version"),
        "overall_status": "PASS" if nomination_allowed else "BLOCK",
        "gate": "CHAMPION_NOMINATION_ALLOWED_FOR_COUNCIL_REVIEW" if nomination_allowed else "CHAMPION_NOMINATION_BLOCKED",
        "nomination_allowed": nomination_allowed,
        "champion_claim_allowed": False,
        "live_orders_allowed": False,
        "council_status": "LOCKED_0_OF_3_UNCHANGED",
        "reason": "Evidence passed minimum scorecard; still requires human Champion Council review." if nomination_allowed else "Repeated evidence is not strong enough to nominate a champion.",
        "thresholds": THRESHOLDS,
        "summary": {
            "paper_shadow_rows": data.get("paper_shadow_rows"),
            "paper_closed_trade_rows_visible": data.get("paper_closed_trade_rows_visible"),
            "candle_rows_total": data.get("candle_rows_total"),
            "universe_ledger_rows": data.get("universe_ledger_rows"),
            "backtest_walk_forward_rows": data.get("backtest_walk_forward_rows"),
            "positive_walk_forward_rows_visible": data.get("positive_walk_forward_rows_visible"),
            "latest_walk_forward_avg_visible": data.get("latest_walk_forward_avg_visible"),
            "backtest_gate": data.get("backtest_gate"),
            "real_live_data_gate": data.get("real_live_data_gate"),
        },
        "safety_checks": safety_checks,
        "evidence_checks": evidence_checks,
        "blockers": blockers,
        "raw_parsed": data,
    }
    return card

def md_report(card: Dict[str, Any]) -> str:
    lines = []
    lines.append(f"# Bali V016 Native Evidence Scorecard")
    lines.append("")
    lines.append(f"Generated UTC: {card['generated_utc']}")
    lines.append(f"Version: {card['version']}")
    lines.append(f"Source version: {card.get('source_version')}")
    lines.append(f"Source report: {card.get('source_report')}")
    lines.append("")
    lines.append("## Result")
    lines.append(f"- Overall status: **{card['overall_status']}**")
    lines.append(f"- Gate: **{card['gate']}**")
    lines.append(f"- Champion nomination allowed: **{card['nomination_allowed']}**")
    lines.append(f"- Champion claim allowed: **{card['champion_claim_allowed']}**")
    lines.append(f"- Live orders allowed: **{card['live_orders_allowed']}**")
    lines.append(f"- Council status: **{card['council_status']}**")
    lines.append(f"- Reason: {card['reason']}")
    lines.append("")
    lines.append("## Summary")
    for k, v in card["summary"].items():
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("## Blockers")
    if card["blockers"]:
        for b in card["blockers"]:
            note = f" | {b.get('note')}" if b.get("note") else ""
            lines.append(f"- {b['name']}: observed={b['observed']} required={b['required']}{note}")
    else:
        lines.append("- None. Human Champion Council review still required before any claim.")
    lines.append("")
    lines.append("## Safety Checks")
    for c in card["safety_checks"]:
        lines.append(f"- {'PASS' if c['pass'] else 'BLOCK'} {c['name']}: observed={c['observed']} required={c['required']}")
    lines.append("")
    lines.append("## Evidence Checks")
    for c in card["evidence_checks"]:
        note = f" | {c.get('note')}" if c.get("note") else ""
        lines.append(f"- {'PASS' if c['pass'] else 'BLOCK'} {c['name']}: observed={c['observed']} required={c['required']}{note}")
    lines.append("")
    lines.append("## Safety Contract")
    lines.append("- Live orders remain OFF.")
    lines.append("- API keys remain NONE.")
    lines.append("- Champion Council remains locked at 0/3 unless a separate human approval process exists.")
    lines.append("- This scorecard uses local reports/ledgers only and does not call private exchange endpoints.")
    lines.append("- No fake/offline/demo rows are allowed as real evidence.")
    return "\n".join(lines) + "\n"

def tiny_report(card: Dict[str, Any]) -> str:
    s = card["summary"]
    lines = [
        "BALI TINY UPDATE RESULT V016_NATIVE",
        f"Generated UTC: {card['generated_utc']}",
        "SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS | PUBLIC_DATA_RESEARCH_ONLY",
        f"VERSION={card['version']}",
        f"SOURCE_VERSION={card.get('source_version')}",
        f"REAL_LIVE_DATA_GATE={s.get('real_live_data_gate')}",
        f"PAPER_ROWS={s.get('paper_shadow_rows')}",
        f"PAPER_CLOSED_TRADES_VISIBLE={s.get('paper_closed_trade_rows_visible')}",
        f"CANDLE_ROWS={s.get('candle_rows_total')}",
        f"UNIVERSE_LEDGER_ROWS={s.get('universe_ledger_rows')}",
        f"BACKTEST_WALK_FORWARD_ROWS={s.get('backtest_walk_forward_rows')}",
        f"POSITIVE_WF_ROWS_VISIBLE={s.get('positive_walk_forward_rows_visible')}",
        f"LATEST_WF_AVG_VISIBLE={s.get('latest_walk_forward_avg_visible')}",
        f"BACKTEST_GATE={s.get('backtest_gate')}",
        f"EVIDENCE_SCORECARD={card['overall_status']}",
        f"CHAMPION_NOMINATION={card['gate']}",
        "CHAMPION_CLAIM_ALLOWED=False",
        "LIVE_ORDERS_ALLOWED=False",
        f"BLOCKER_COUNT={len(card['blockers'])}",
        "RESULT=PASS_NATIVE_SCORECARD_WRITTEN",
    ]
    return "\n".join(lines) + "\n"

def write_outputs(root: Path, card: Dict[str, Any]) -> None:
    reports = root / "shared_data" / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    dashboard = root / "shared_data" / "dashboard"
    dashboard.mkdir(parents=True, exist_ok=True)
    (reports / "BALI_V016_EVIDENCE_SCORECARD.json").write_text(json.dumps(card, indent=2), encoding="utf-8")
    (reports / "BALI_V016_EVIDENCE_SCORECARD.md").write_text(md_report(card), encoding="utf-8")
    (reports / "BALI_TINY_UPDATE_RESULT_V016_NATIVE.txt").write_text(tiny_report(card), encoding="utf-8")
    (dashboard / "v016_evidence_scorecard_panel.json").write_text(json.dumps({
        "version": card["version"],
        "generated_utc": card["generated_utc"],
        "overall_status": card["overall_status"],
        "gate": card["gate"],
        "nomination_allowed": card["nomination_allowed"],
        "champion_claim_allowed": card["champion_claim_allowed"],
        "live_orders_allowed": card["live_orders_allowed"],
        "summary": card["summary"],
        "blockers": card["blockers"][:12],
    }, indent=2), encoding="utf-8")

def main() -> int:
    ap = argparse.ArgumentParser(description="Bali V016 native evidence scorecard generator")
    ap.add_argument("--root", default=".", help="Bali app root")
    ap.add_argument("--report", default=None, help="Explicit status report path")
    ap.add_argument("--print", action="store_true", help="Print tiny report")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    source = find_latest_status_report(root, args.report)
    if not source:
        # Still write a safe blocking report so the dashboard gets a visible answer.
        data = {"source_version":"UNKNOWN", "live_orders":"UNKNOWN", "api_keys":"UNKNOWN", "champion_lock":"UNKNOWN", "risk_police":"UNKNOWN", "real_live_data_gate":"UNKNOWN", "stale_seconds":999999, "ignored_offline_demo_rows":0, "paper_shadow_rows":0, "paper_closed_trade_rows_visible":0, "candle_rows_total":0, "universe_ledger_rows":0, "backtest_walk_forward_rows":0, "distinct_backtest_ids_visible":0, "positive_walk_forward_rows_visible":0, "latest_walk_forward_avg_visible":None, "backtest_gate":"UNKNOWN", "champion_claim_allowed":"False", "danger_flags":[]}
    else:
        data = parse_report(read_text(source))
    card = build_scorecard(data, source)
    write_outputs(root, card)
    if args.print:
        print(tiny_report(card))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
