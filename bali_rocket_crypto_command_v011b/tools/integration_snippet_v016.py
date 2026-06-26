"""
Safe integration example for V016 Evidence Scorecard.
Paste the relevant pieces into the existing Bali report/dashboard generator.
"""

from pathlib import Path

from evidence_scorecard_v016 import (
    VERSION as V016_VERSION,
    evaluate_status_report,
    parse_status_report,
)


def build_v016_from_compact_report(report_text: str, reports_dir: Path):
    parsed = parse_status_report(report_text)
    scorecard = evaluate_status_report(parsed)

    reports_dir.mkdir(parents=True, exist_ok=True)
    (reports_dir / "v016_evidence_scorecard.json").write_text(scorecard.to_json() + "\n", encoding="utf-8")
    (reports_dir / "v016_evidence_scorecard.md").write_text(scorecard.to_markdown(), encoding="utf-8")

    dashboard_lines = [
        f"Evidence Scorecard: {V016_VERSION} | gate={scorecard.gate} | nomination_allowed={scorecard.nomination_allowed} | champion_claim_allowed={scorecard.champion_claim_allowed}",
        "Champion Council Gate: LOCKED_EVIDENCE_SCORECARD_REQUIRED | live_orders=OFF | risk_police=ARMED",
    ]
    if scorecard.summary.get("blocking_checks"):
        dashboard_lines.append("Evidence blocking checks: " + "; ".join(scorecard.summary["blocking_checks"]))
    return scorecard, dashboard_lines


# Example usage inside the existing report generator:
# compact_report_text = existing_report_text
# reports_dir = Path(shared_data_dir) / "reports"
# scorecard, v016_lines = build_v016_from_compact_report(compact_report_text, reports_dir)
# existing_report_text += "\n\nV016 EVIDENCE SCORECARD\n" + "\n".join(v016_lines) + "\n"
