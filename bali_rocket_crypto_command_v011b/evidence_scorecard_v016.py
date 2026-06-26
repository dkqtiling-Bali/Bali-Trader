"""
V016 Evidence Scorecard + Champion Council Gate
Bali Rocket Crypto Command

Safety contract:
- Public data research only.
- No API keys.
- No live orders.
- No champion claim from this module.
- No fake/offline/demo evidence can pass the gate.

This module can be run against the compact ChatGPT status report or imported by
an existing report generator / dashboard. It deliberately blocks champion
nomination unless repeated real-live-data backtest/walk-forward evidence and
paper-shadow evidence are present.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

VERSION = "V016_EVIDENCE_SCORECARD_CHAMPION_COUNCIL_GATE"
REAL_LIVE_SOURCE = "https://data-api.binance.vision"

PASS_RECENT_REAL_LIVE_DATA = "PASS_RECENT_REAL_LIVE_DATA"
ENFORCED_PASS_REAL_LIVE_DATA_ONLY = "ENFORCED_PASS_REAL_LIVE_DATA_ONLY"

STATUS_PASS = "PASS"
STATUS_BLOCK = "BLOCK"
STATUS_WARN = "WARN"

NOMINATION_BLOCKED = "CHAMPION_NOMINATION_BLOCKED"
NOMINATION_ELIGIBLE_REVIEW_ONLY = "CHAMPION_NOMINATION_ELIGIBLE_HUMAN_REVIEW_ONLY"


@dataclass(frozen=True)
class EvidenceThresholds:
    """Default thresholds are intentionally conservative and configurable."""

    max_live_data_stale_seconds: int = 120
    min_market_ticks: int = 500
    min_live_data_guard_rows: int = 20
    min_learning_cycles: int = 100
    min_paper_shadow_rows: int = 50
    min_paper_closed_trades: int = 10
    min_candle_rows_total: int = 250
    min_candle_proof_rows: int = 20
    min_universe_scan_ledger_rows: int = 500
    min_universe_latest_batch_rows: int = 25
    min_backtest_walk_forward_rows: int = 12
    min_backtest_rows_with_positive_wf_avg: int = 8
    max_allowed_wf_drawdown_pct: float = 2.50
    min_distinct_backtest_ids: int = 12
    required_human_approvals_for_claim: int = 3


@dataclass
class EvidenceCheck:
    name: str
    status: str
    observed: Any
    required: Any
    detail: str


@dataclass
class EvidenceScorecard:
    version: str
    generated_utc: str
    nomination_allowed: bool
    champion_claim_allowed: bool
    gate: str
    overall_status: str
    checks: List[EvidenceCheck]
    summary: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        return data

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2, sort_keys=True)

    def to_markdown(self) -> str:
        lines = [
            f"# {self.version}",
            "",
            f"Generated UTC: {self.generated_utc}",
            f"Overall status: {self.overall_status}",
            f"Gate: {self.gate}",
            f"Nomination allowed: {self.nomination_allowed}",
            f"Champion claim allowed: {self.champion_claim_allowed}",
            "",
            "## Checks",
            "",
            "| Check | Status | Observed | Required | Detail |",
            "|---|---:|---:|---:|---|",
        ]
        for check in self.checks:
            lines.append(
                "| {name} | {status} | {observed} | {required} | {detail} |".format(
                    name=_md(check.name),
                    status=_md(check.status),
                    observed=_md(str(check.observed)),
                    required=_md(str(check.required)),
                    detail=_md(check.detail),
                )
            )
        lines.extend(["", "## Summary", "", "```json", json.dumps(self.summary, indent=2, sort_keys=True), "```", ""])
        return "\n".join(lines)


def _md(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def _now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_bool(value: Any) -> Optional[bool]:
    if value is None:
        return None
    text = str(value).strip().lower()
    if text in {"true", "yes", "1", "allowed"}:
        return True
    if text in {"false", "no", "0", "blocked", "not_allowed"}:
        return False
    return None


def _to_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    text = str(value).strip()
    if text == "" or text.lower() in {"none", "nan", "null"}:
        return None
    try:
        result = float(text)
    except ValueError:
        return None
    if math.isnan(result) or math.isinf(result):
        return None
    return result


def _to_int(value: Any) -> Optional[int]:
    number = _to_float(value)
    if number is None:
        return None
    return int(number)


def _find_line_value(text: str, label: str) -> Optional[str]:
    pattern = re.compile(rf"^{re.escape(label)}:\s*(.*?)\s*$", re.MULTILINE)
    match = pattern.search(text)
    return match.group(1).strip() if match else None


def _parse_counts(text: str) -> Dict[str, Any]:
    counts: Dict[str, Any] = {}
    in_counts = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line == "COUNTS":
            in_counts = True
            continue
        if in_counts and not line:
            break
        if in_counts and ":" in line:
            key, value = line.split(":", 1)
            key_norm = key.strip().lower().replace(" ", "_").replace("/", "_").replace("-", "_")
            value = value.strip()
            number = _to_float(value)
            counts[key_norm] = number if number is not None else value
    return counts


def _section_lines(text: str, header: str) -> List[str]:
    lines = text.splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.strip() == header:
            start = index + 1
            break
    if start is None:
        return []
    output: List[str] = []
    for line in lines[start:]:
        stripped = line.strip()
        if stripped and stripped.upper() == stripped and not stripped.startswith("-"):
            break
        if stripped.startswith("-"):
            output.append(stripped)
    return output


def parse_status_report(text: str) -> Dict[str, Any]:
    """Parse the compact Bali status report into a normalized dict."""

    counts = _parse_counts(text)
    generated_utc = _find_line_value(text, "Generated UTC")
    live_orders = _find_line_value(text, "Live orders")
    champion_lock = _find_line_value(text, "Champion lock")
    api_keys = _find_line_value(text, "API keys")
    mode = _find_line_value(text, "Mode")
    real_gate = _find_line_value(text, "Gate")
    raw_data_gate = _find_line_value(text, "Raw data gate")
    warning = _find_line_value(text, "Warning")
    stale_seconds = _to_int(_find_line_value(text, "Stale seconds"))
    feed_source = _find_line_value(text, "Feed source")
    feed_status = _find_line_value(text, "Feed status")
    ignored_demo = _to_int(_find_line_value(text, "Ignored recent offline_demo rows"))

    paper_status = _find_line_value(text, "Paper Shadow")
    candle_status = _find_line_value(text, "Candle Harvester")
    universe_status = _find_line_value(text, "Universe Scanner")
    backtest_status = _find_line_value(text, "Backtest Gate")
    champion_proof_gate = _find_line_value(text, "Champion proof gate")
    risk_police = _find_line_value(text, "Risk Police")
    no_trade_score = _to_float(_find_line_value(text, "No-trade score"))
    doctor_status = _find_line_value(text, "Doctor status")

    champion_claim_allowed = None
    claim_match = re.search(r"champion_claim_allowed\s*=\s*(True|False)", text)
    if claim_match:
        champion_claim_allowed = _parse_bool(claim_match.group(1))

    approvals = None
    approval_match = re.search(r"approved\s+(\d+)\s*/\s*(\d+)", champion_lock or "")
    if approval_match:
        approvals = {
            "approved": int(approval_match.group(1)),
            "required": int(approval_match.group(2)),
        }

    latest_backtests = []
    for line in _section_lines(text, "LATEST BACKTEST / WALK-FORWARD GATE RECORDS"):
        latest_backtests.append(_parse_backtest_line(line))

    latest_paper = []
    for line in _section_lines(text, "LATEST PAPER SHADOW RECORDS"):
        latest_paper.append(_parse_paper_line(line))

    return {
        "generated_utc": generated_utc,
        "version": _find_line_value(text, "Version"),
        "safety": {
            "live_orders": live_orders,
            "champion_lock": champion_lock,
            "approvals": approvals,
            "api_keys": api_keys,
            "mode": mode,
        },
        "real_live_data_gate": {
            "gate": real_gate,
            "raw_data_gate": raw_data_gate,
            "warning": warning,
            "stale_seconds": stale_seconds,
            "feed_source": feed_source,
            "feed_status": feed_status,
            "ignored_recent_offline_demo_rows": ignored_demo,
        },
        "counts": counts,
        "layers": {
            "paper_shadow": paper_status,
            "candle_harvester": candle_status,
            "universe_scanner": universe_status,
            "backtest_gate": backtest_status,
            "champion_proof_gate": champion_proof_gate,
            "risk_police": risk_police,
            "no_trade_score": no_trade_score,
            "doctor_status": doctor_status,
        },
        "champion_claim_allowed": champion_claim_allowed,
        "latest_backtests": latest_backtests,
        "latest_paper": latest_paper,
    }


def _parse_backtest_line(line: str) -> Dict[str, Any]:
    item: Dict[str, Any] = {"raw": line}
    parts = [p.strip() for p in line.lstrip("- ").split("|")]
    if len(parts) >= 3:
        item["timestamp"] = parts[0]
        item["backtest_id"] = parts[1]
        item["symbol_interval"] = parts[2]
    joined = " | ".join(parts)
    for key in ["gate", "candles", "in_trades", "avg", "dd", "wf_trades", "champion_allowed"]:
        match = re.search(rf"\b{key}\s*=\s*([^\s|]+)", joined)
        if match:
            raw_value = match.group(1)
            if key == "champion_allowed":
                item[key] = _parse_bool(raw_value)
            elif key in {"candles", "in_trades", "wf_trades"}:
                item[key] = _to_int(raw_value)
            elif key in {"avg", "dd"}:
                # avg/dd appear for in-sample first; wf values are parsed below.
                item.setdefault(key, _to_float(raw_value))
            else:
                item[key] = raw_value
    wf_match = re.search(r"wf_trades\s*=\s*([^\s|]+)\s+avg\s*=\s*([^\s|]+)\s+dd\s*=\s*([^\s|]+)", joined)
    if wf_match:
        item["wf_trades"] = _to_int(wf_match.group(1))
        item["wf_avg"] = _to_float(wf_match.group(2))
        item["wf_drawdown"] = _to_float(wf_match.group(3))
    in_match = re.search(r"in_trades\s*=\s*([^\s|]+)\s+avg\s*=\s*([^\s|]+)\s+dd\s*=\s*([^\s|]+)", joined)
    if in_match:
        item["in_trades"] = _to_int(in_match.group(1))
        item["in_avg"] = _to_float(in_match.group(2))
        item["in_drawdown"] = _to_float(in_match.group(3))
    return item


def _parse_paper_line(line: str) -> Dict[str, Any]:
    item: Dict[str, Any] = {"raw": line}
    parts = [p.strip() for p in line.lstrip("- ").split("|")]
    if len(parts) >= 4:
        item["timestamp"] = parts[0]
        item["action"] = parts[1]
        item["symbol"] = parts[2]
        item["mode"] = parts[3]
    joined = " | ".join(parts)
    net_match = re.search(r"net_pct\s*=\s*([^\s|]+)", joined)
    if net_match:
        item["net_pct"] = _to_float(net_match.group(1))
    return item


def read_csv_rows(path: Path) -> List[Dict[str, Any]]:
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def _csv_count(rows: Sequence[Dict[str, Any]]) -> int:
    return len(rows)


def _real_live_rows(rows: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    real_rows = []
    for row in rows:
        joined = " ".join(str(value) for value in row.values()).lower()
        source_fields = " ".join(str(row.get(key, "")) for key in ("source", "feed_source", "data_source", "url"))
        source_ok = REAL_LIVE_SOURCE in source_fields or REAL_LIVE_SOURCE in joined
        demo_bad = any(token in joined for token in ("offline_demo", "fake", "synthetic", "demo_scoring"))
        if source_ok and not demo_bad:
            real_rows.append(row)
    return real_rows


def evaluate_status_report(parsed: Dict[str, Any], thresholds: EvidenceThresholds = EvidenceThresholds()) -> EvidenceScorecard:
    checks: List[EvidenceCheck] = []
    counts = parsed.get("counts", {})
    safety = parsed.get("safety", {})
    gate_data = parsed.get("real_live_data_gate", {})
    layers = parsed.get("layers", {})
    latest_backtests = parsed.get("latest_backtests", [])
    latest_paper = parsed.get("latest_paper", [])

    def check(name: str, passed: bool, observed: Any, required: Any, detail: str, warn: bool = False) -> None:
        status = STATUS_PASS if passed else (STATUS_WARN if warn else STATUS_BLOCK)
        checks.append(EvidenceCheck(name=name, status=status, observed=observed, required=required, detail=detail))

    live_orders = str(safety.get("live_orders", "")).upper()
    check("Live orders disabled", "OFF" in live_orders, safety.get("live_orders"), "OFF", "V016 must never enable live orders.")

    api_keys = str(safety.get("api_keys", "")).upper()
    check("No API keys", "NONE" in api_keys and "PRIVATE" in api_keys, safety.get("api_keys"), "NONE / no private endpoints", "Public data research mode only.")

    mode = str(safety.get("mode", "")).upper()
    check("Public data research mode", "PUBLIC_DATA_RESEARCH_ONLY" in mode, safety.get("mode"), "PUBLIC_DATA_RESEARCH_ONLY", "Blocks private exchange endpoints.")

    champion_lock = str(safety.get("champion_lock", "")).upper()
    check("Champion lock remains locked", "LOCKED" in champion_lock, safety.get("champion_lock"), "LOCKED", "V016 permits nomination review only, not champion claim.")

    gate = gate_data.get("gate")
    raw_gate = gate_data.get("raw_data_gate")
    warning = gate_data.get("warning")
    stale_seconds = gate_data.get("stale_seconds")
    feed_source = gate_data.get("feed_source")
    ignored_demo = gate_data.get("ignored_recent_offline_demo_rows")

    check("Recent real-live-data gate", gate == PASS_RECENT_REAL_LIVE_DATA, gate, PASS_RECENT_REAL_LIVE_DATA, "Must be current real public data.")
    check("Raw data gate enforced", raw_gate == ENFORCED_PASS_REAL_LIVE_DATA_ONLY, raw_gate, ENFORCED_PASS_REAL_LIVE_DATA_ONLY, "No offline/demo rows can score.")
    check("Live-data warning clean", str(warning).upper() in {"OK", "NONE"}, warning, "OK", "Warnings block nomination.")
    check("Live-data freshness", stale_seconds is not None and stale_seconds <= thresholds.max_live_data_stale_seconds, stale_seconds, f"<= {thresholds.max_live_data_stale_seconds}", "Stale data cannot nominate champions.")
    check("Approved public feed source", feed_source == REAL_LIVE_SOURCE, feed_source, REAL_LIVE_SOURCE, "Only Binance public data mirror is accepted here.")
    check("Offline/demo rows ignored", ignored_demo == 0, ignored_demo, 0, "Fake/offline/demo scoring is not evidence.")

    check("Market tick evidence count", (_to_int(counts.get("market_ticks")) or 0) >= thresholds.min_market_ticks, counts.get("market_ticks"), f">= {thresholds.min_market_ticks}", "Enough real ticks to prove collection health.")
    check("Live guard evidence count", (_to_int(counts.get("live_data_guard")) or 0) >= thresholds.min_live_data_guard_rows, counts.get("live_data_guard"), f">= {thresholds.min_live_data_guard_rows}", "Guard must have repeated passes.")
    check("Learning cycles recorded", (_to_int(counts.get("learning_cycles")) or 0) >= thresholds.min_learning_cycles, counts.get("learning_cycles"), f">= {thresholds.min_learning_cycles}", "Learning is collection-only, not edge proof.")

    paper_rows = _to_int(counts.get("paper_shadow_rows")) or 0
    closed_paper_rows = sum(1 for row in latest_paper if row.get("net_pct") is not None)
    check("Paper Shadow online", "PAPER_SHADOW_ONLINE" in str(layers.get("paper_shadow", "")), layers.get("paper_shadow"), "PAPER_SHADOW_ONLINE", "Paper-only simulator remains safe.")
    check("Paper Shadow repeated rows", paper_rows >= thresholds.min_paper_shadow_rows, paper_rows, f">= {thresholds.min_paper_shadow_rows}", "Need repeated paper observations before nomination.")
    check("Paper Shadow closed trade evidence", closed_paper_rows >= thresholds.min_paper_closed_trades, closed_paper_rows, f">= {thresholds.min_paper_closed_trades}", "Stand-aside rows prove risk discipline but not trade edge.")

    candle_rows = _to_int(counts.get("candle_rows_total")) or 0
    candle_proof = _to_int(counts.get("candle_proof_rows")) or 0
    check("Candle Harvester online", "CANDLE_HARVESTER_ONLINE" in str(layers.get("candle_harvester", "")), layers.get("candle_harvester"), "CANDLE_HARVESTER_ONLINE", "Candle layer is allowed as evidence input.")
    check("Candle row count", candle_rows >= thresholds.min_candle_rows_total, candle_rows, f">= {thresholds.min_candle_rows_total}", "Enough candles for the current V016 baseline.")
    check("Candle proof count", candle_proof >= thresholds.min_candle_proof_rows, candle_proof, f">= {thresholds.min_candle_proof_rows}", "Proof rows must exist, not just derived rows.")

    universe_rows = _to_int(counts.get("universe_scan_ledger_rows")) or 0
    universe_batch = _to_int(counts.get("universe_latest_batch_visible_rows")) or 0
    check("Universe Scanner online", "UNIVERSE_SCANNER_ONLINE" in str(layers.get("universe_scanner", "")), layers.get("universe_scanner"), "UNIVERSE_SCANNER_ONLINE", "Scanner may rank candidates; it cannot nominate alone.")
    check("Universe scan ledger depth", universe_rows >= thresholds.min_universe_scan_ledger_rows, universe_rows, f">= {thresholds.min_universe_scan_ledger_rows}", "Universe ranking needs repeated batches.")
    check("Universe latest batch depth", universe_batch >= thresholds.min_universe_latest_batch_rows, universe_batch, f">= {thresholds.min_universe_latest_batch_rows}", "Latest visible batch must be broad enough.")

    bt_rows = _to_int(counts.get("backtest_walk_forward_rows")) or 0
    wf_positive = sum(1 for row in latest_backtests if (_to_float(row.get("wf_avg")) or -999999) > 0)
    wf_low_dd = sum(1 for row in latest_backtests if (row.get("wf_drawdown") is not None and row.get("wf_drawdown") <= thresholds.max_allowed_wf_drawdown_pct))
    distinct_bt_ids = len({row.get("backtest_id") for row in latest_backtests if row.get("backtest_id")})
    bt_gate_text = str(layers.get("backtest_gate", ""))
    edge_not_proven = "EDGE_NOT_PROVEN" in bt_gate_text

    check("Backtest/WF gate recorded", "BACKTEST_WALK_FORWARD_RECORDED" in bt_gate_text, layers.get("backtest_gate"), "BACKTEST_WALK_FORWARD_RECORDED", "Gate exists and records evidence.")
    check("Backtest/WF repeated rows", bt_rows >= thresholds.min_backtest_walk_forward_rows, bt_rows, f">= {thresholds.min_backtest_walk_forward_rows}", "Need repeated runs before nomination.")
    check("Backtest/WF positive repeated edge", wf_positive >= thresholds.min_backtest_rows_with_positive_wf_avg, wf_positive, f">= {thresholds.min_backtest_rows_with_positive_wf_avg}", "Latest walk-forward averages must repeatedly be positive.")
    check("Backtest/WF drawdown containment", wf_low_dd >= thresholds.min_backtest_rows_with_positive_wf_avg, wf_low_dd, f">= {thresholds.min_backtest_rows_with_positive_wf_avg} rows with dd <= {thresholds.max_allowed_wf_drawdown_pct}", "Drawdown must stay within configured limits.")
    check("Distinct backtest IDs", distinct_bt_ids >= thresholds.min_distinct_backtest_ids, distinct_bt_ids, f">= {thresholds.min_distinct_backtest_ids}", "Repeated evidence cannot be one recycled run.")
    check("Backtest edge not proven flag cleared", not edge_not_proven, bt_gate_text, "No EDGE_NOT_PROVEN flag", "Existing gate must stop reporting unproven edge.")

    risk_police = str(layers.get("risk_police", "")).upper()
    check("Risk Police armed", "ARMED" in risk_police, layers.get("risk_police"), "ARMED", "Risk Police must stay armed.")

    existing_claim_allowed = parsed.get("champion_claim_allowed")
    approvals = safety.get("approvals") or {}
    approved_count = approvals.get("approved", 0)
    approval_required = max(approvals.get("required", 0), thresholds.required_human_approvals_for_claim)
    check("Champion claim remains false", existing_claim_allowed is False, existing_claim_allowed, False, "V016 does not unlock champion claims.")
    check("Human approvals for claim", approved_count >= approval_required, f"{approved_count}/{approval_required}", f">= {approval_required}/{approval_required}", "Even nomination eligibility is review-only; claim still requires humans.", warn=True)

    blocking = [c for c in checks if c.status == STATUS_BLOCK]
    nomination_allowed = len(blocking) == 0
    champion_claim_allowed = False
    if nomination_allowed:
        gate_out = NOMINATION_ELIGIBLE_REVIEW_ONLY
        overall = STATUS_PASS
    else:
        gate_out = NOMINATION_BLOCKED
        overall = STATUS_BLOCK

    summary = {
        "source_version": parsed.get("version"),
        "real_live_gate": gate,
        "raw_data_gate": raw_gate,
        "paper_shadow_rows": paper_rows,
        "paper_closed_trade_rows_visible": closed_paper_rows,
        "backtest_walk_forward_rows": bt_rows,
        "wf_positive_rows_visible": wf_positive,
        "distinct_backtest_ids_visible": distinct_bt_ids,
        "edge_not_proven_flag_present": edge_not_proven,
        "risk_police": layers.get("risk_police"),
        "blocking_checks": [c.name for c in blocking],
    }

    return EvidenceScorecard(
        version=VERSION,
        generated_utc=_now_utc(),
        nomination_allowed=nomination_allowed,
        champion_claim_allowed=champion_claim_allowed,
        gate=gate_out,
        overall_status=overall,
        checks=checks,
        summary=summary,
    )


def evaluate_ledgers(
    live_data_guard_rows: Sequence[Dict[str, Any]],
    paper_shadow_rows: Sequence[Dict[str, Any]],
    backtest_rows: Sequence[Dict[str, Any]],
    thresholds: EvidenceThresholds = EvidenceThresholds(),
) -> EvidenceScorecard:
    """Optional CSV-ledger evaluator for integration in the real app.

    Use this only with public real-live-data ledgers. It rejects rows containing
    offline_demo/fake/synthetic markers.
    """

    checks: List[EvidenceCheck] = []

    def check(name: str, passed: bool, observed: Any, required: Any, detail: str) -> None:
        checks.append(EvidenceCheck(name=name, status=STATUS_PASS if passed else STATUS_BLOCK, observed=observed, required=required, detail=detail))

    real_guard = _real_live_rows(live_data_guard_rows)
    real_paper = _real_live_rows(paper_shadow_rows)
    real_backtests = _real_live_rows(backtest_rows)

    check("Real live guard rows only", len(real_guard) == len(live_data_guard_rows) and len(real_guard) >= thresholds.min_live_data_guard_rows, f"{len(real_guard)}/{len(live_data_guard_rows)}", f">= {thresholds.min_live_data_guard_rows} and no fake/demo rows", "All guard evidence must be real public data.")
    check("Paper rows are real-source rows", len(real_paper) == len(paper_shadow_rows) and len(real_paper) >= thresholds.min_paper_shadow_rows, f"{len(real_paper)}/{len(paper_shadow_rows)}", f">= {thresholds.min_paper_shadow_rows} and no fake/demo rows", "Paper evidence must be linked to real public data.")
    paper_closed = [r for r in real_paper if _to_float(r.get("net_pct")) is not None or str(r.get("action", "")).upper() in {"EXIT_SIMULATED", "CLOSE_SIMULATED", "CLOSED_SIMULATED"}]
    check("Paper closed trade count", len(paper_closed) >= thresholds.min_paper_closed_trades, len(paper_closed), f">= {thresholds.min_paper_closed_trades}", "Stand-aside alone is not edge proof.")

    check("Backtest rows are real-source rows", len(real_backtests) == len(backtest_rows) and len(real_backtests) >= thresholds.min_backtest_walk_forward_rows, f"{len(real_backtests)}/{len(backtest_rows)}", f">= {thresholds.min_backtest_walk_forward_rows} and no fake/demo rows", "Backtest evidence must trace to public real data.")
    positive_wf = [r for r in real_backtests if (_to_float(r.get("wf_avg")) or -999999) > 0]
    check("Positive walk-forward rows", len(positive_wf) >= thresholds.min_backtest_rows_with_positive_wf_avg, len(positive_wf), f">= {thresholds.min_backtest_rows_with_positive_wf_avg}", "Walk-forward edge must repeat.")
    distinct_ids = {str(r.get("backtest_id") or r.get("batch") or r.get("run_id")) for r in real_backtests if r.get("backtest_id") or r.get("batch") or r.get("run_id")}
    check("Distinct backtest run IDs", len(distinct_ids) >= thresholds.min_distinct_backtest_ids, len(distinct_ids), f">= {thresholds.min_distinct_backtest_ids}", "Avoid recycled evidence.")

    blocking = [c for c in checks if c.status == STATUS_BLOCK]
    nomination_allowed = len(blocking) == 0
    return EvidenceScorecard(
        version=VERSION,
        generated_utc=_now_utc(),
        nomination_allowed=nomination_allowed,
        champion_claim_allowed=False,
        gate=NOMINATION_ELIGIBLE_REVIEW_ONLY if nomination_allowed else NOMINATION_BLOCKED,
        overall_status=STATUS_PASS if nomination_allowed else STATUS_BLOCK,
        checks=checks,
        summary={
            "live_data_guard_rows": len(live_data_guard_rows),
            "paper_shadow_rows": len(paper_shadow_rows),
            "paper_closed_trade_rows": len(paper_closed),
            "backtest_rows": len(backtest_rows),
            "positive_wf_rows": len(positive_wf),
            "distinct_backtest_ids": len(distinct_ids),
            "blocking_checks": [c.name for c in blocking],
        },
    )


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Run V016 Evidence Scorecard + Champion Council Gate.")
    parser.add_argument("--status-report", type=Path, help="Path to compact Bali status report text.")
    parser.add_argument("--live-data-guard-csv", type=Path, help="Optional live data guard CSV.")
    parser.add_argument("--paper-shadow-csv", type=Path, help="Optional paper shadow CSV.")
    parser.add_argument("--backtest-csv", type=Path, help="Optional backtest/walk-forward CSV.")
    parser.add_argument("--out-json", type=Path, help="Write scorecard JSON here.")
    parser.add_argument("--out-md", type=Path, help="Write scorecard markdown here.")
    args = parser.parse_args(argv)

    if args.status_report:
        parsed = parse_status_report(args.status_report.read_text(encoding="utf-8"))
        scorecard = evaluate_status_report(parsed)
    elif args.live_data_guard_csv and args.paper_shadow_csv and args.backtest_csv:
        scorecard = evaluate_ledgers(
            read_csv_rows(args.live_data_guard_csv),
            read_csv_rows(args.paper_shadow_csv),
            read_csv_rows(args.backtest_csv),
        )
    else:
        parser.error("Provide --status-report or all three CSV ledger paths.")
        return 2

    if args.out_json:
        args.out_json.parent.mkdir(parents=True, exist_ok=True)
        args.out_json.write_text(scorecard.to_json() + "\n", encoding="utf-8")
    if args.out_md:
        args.out_md.parent.mkdir(parents=True, exist_ok=True)
        args.out_md.write_text(scorecard.to_markdown(), encoding="utf-8")

    print(scorecard.to_json())
    return 0 if scorecard.overall_status == STATUS_PASS else 1


if __name__ == "__main__":
    raise SystemExit(main())
