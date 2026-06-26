@echo off
setlocal EnableExtensions
title Bali V017 Always-Working Report Center - No Py Installer
echo.
echo ============================================================
echo  BALI V017 - DASHBOARD REPORT BUTTON FIXED
echo ============================================================
echo.
echo This fixed installer does NOT call py or python to patch files.
echo It uses Windows PowerShell only, backs up app.py, adds the report
echo button, keeps live orders OFF, Champion LOCKED, API keys NONE,
echo and public-data / paper-only mode.
echo.
set "BALI_V017_SELF=%~f0"
set "BALI_V017_TEMPPS=%TEMP%\bali_v017_no_py_%RANDOM%_%RANDOM%.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw=[IO.File]::ReadAllText($env:BALI_V017_SELF); $marker='### BALI_V017_POWERSHELL_PAYLOAD ###'; $i=$raw.LastIndexOf($marker); if($i -lt 0){Write-Host 'Payload marker missing'; exit 9}; $payload=$raw.Substring($i+$marker.Length); Set-Content -LiteralPath $env:BALI_V017_TEMPPS -Value $payload -Encoding UTF8"
if errorlevel 1 goto fail
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BALI_V017_TEMPPS%"
if errorlevel 1 goto fail
del "%BALI_V017_TEMPPS%" >nul 2>nul
echo.
echo DONE. Restart from the desktop icon: Bali Rocket Forever Safe
echo Then open Reports and click Generate Always-Working Bot Stats Report.
echo.
pause
exit /b 0
:fail
echo.
echo PATCH FAILED. Nothing live-trading related was enabled.
echo Send the full visible error back to ChatGPT.
echo.
pause
exit /b 1
### BALI_V017_POWERSHELL_PAYLOAD ###
$ErrorActionPreference = "Stop"
$PatchId = "V017_ALWAYS_WORKING_REPORT_CENTER"
$PatchTitle = "Always-Working Report Center: Last Patch + Bot Stats + Deltas"

function Fail($Message) {
    Write-Host ""
    Write-Host "PATCH FAILED: $Message" -ForegroundColor Red
    Write-Host "Nothing live-trading related was enabled." -ForegroundColor Yellow
    exit 1
}

function Info($Message) { Write-Host $Message -ForegroundColor Cyan }

function Get-BaliAppScore($File) {
    $score = 0
    $p = [string]$File.FullName
    $low = $p.ToLowerInvariant()
    if ($File.Name -ieq "app.py") { $score += 20 }
    if ($low.Contains("bali_rocket_crypto_command_v011b")) { $score += 60 }
    if ($low.Contains("bali_rocket")) { $score += 25 }
    if ($low.Contains("backup") -or $low.Contains("backups") -or $low.Contains("_staging") -or $low.Contains("payload") -or $low.Contains("updates") -or $low.Contains("releases")) { $score -= 100 }
    try {
        $txt = [IO.File]::ReadAllText($File.FullName)
        if ($txt.Contains("Bali Rocket Crypto Command")) { $score += 100 }
        if ($txt.Contains("ThreadingHTTPServer")) { $score += 20 }
        if ($txt.Contains("def compute_dashboard_state")) { $score += 25 }
        if ($txt.Contains("/api/report/chatgpt")) { $score += 20 }
    } catch { $score -= 1000 }
    return $score
}

function Find-BaliApp($StartDir) {
    $roots = New-Object System.Collections.Generic.List[string]
    function AddRoot($r) {
        if ([string]::IsNullOrWhiteSpace($r)) { return }
        try {
            $full = [IO.Path]::GetFullPath($r)
            if ((Test-Path -LiteralPath $full) -and (-not $roots.Contains($full))) { [void]$roots.Add($full) }
        } catch {}
    }
    AddRoot $StartDir
    AddRoot (Get-Location).Path
    AddRoot ([Environment]::GetFolderPath("Desktop"))
    AddRoot ([Environment]::GetFolderPath("MyDocuments"))
    AddRoot ([IO.Path]::Combine($env:USERPROFILE,"Downloads"))

    $found = @()
    foreach ($root in $roots) {
        foreach ($direct in @((Join-Path $root "app.py"), (Join-Path $root "bali_rocket_crypto_command_v011b\app.py"))) {
            if (Test-Path -LiteralPath $direct) { $found += Get-Item -LiteralPath $direct }
        }
        try {
            $found += Get-ChildItem -LiteralPath $root -Filter "app.py" -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "\(backups|backup|updates|releases|__pycache__|\.git)\" } |
                Select-Object -First 80
        } catch {}
    }
    $scored = @()
    foreach ($f in ($found | Sort-Object -Property FullName -Unique)) {
        $score = Get-BaliAppScore $f
        if ($score -gt 80) { $scored += [pscustomobject]@{ Path=$f.FullName; Score=$score; LastWriteTime=$f.LastWriteTime } }
    }
    if (-not $scored -or $scored.Count -lt 1) { return $null }
    $best = $scored | Sort-Object -Property @{Expression="Score";Descending=$true}, @{Expression="LastWriteTime";Descending=$true} | Select-Object -First 1
    return $best.Path
}

$Here = Split-Path -Parent $env:BALI_V017_SELF
$AppPath = Find-BaliApp $Here
if (-not $AppPath) { Fail "Could not find the Bali app.py. Put this file inside the Bali project folder and run again." }
$AppDir = Split-Path -Parent $AppPath
$OuterRoot = Split-Path -Parent $AppDir
if ((Split-Path -Leaf $AppDir) -ne "bali_rocket_crypto_command_v011b") { $OuterRoot = $AppDir }
Info "Found Bali app: $AppPath"

$text = [IO.File]::ReadAllText($AppPath)
$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
$recovery = Join-Path $OuterRoot "_BALI_FOREVER_RECOVERY"
$backupDir = Join-Path $recovery "v017_backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backup = Join-Path $backupDir ("app.py.before_V017_" + $stamp + ".bak")
Copy-Item -LiteralPath $AppPath -Destination $backup -Force
Info "Backup written: $backup"

$markerBegin = "# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_BEGIN ==="
$markerEnd = "# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ==="
$text = [regex]::Replace($text, "(?s)
?
?# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_BEGIN ===.*?# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ===
?
?", "`r`n")

$V017Code = @'
# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_BEGIN ===
V017_PATCH_ID = "V017_ALWAYS_WORKING_REPORT_CENTER"
V017_PATCH_TITLE = "Always-Working Report Center: Last Patch + Bot Stats + Deltas"


def v017_patch_ledger_path() -> Path:
    return SHARED / "patches" / "patch_ledger.jsonl"


def v017_report_ledger_path() -> Path:
    return REPORTS / "always_working_report_ledger.jsonl"


def v017_safe_text(value: Any) -> str:
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
        return ", ".join(v017_safe_text(x) for x in value[:8])
    return str(value)


def v017_last_patch_details() -> Dict[str, Any]:
    rows = read_last_jsonl(v017_patch_ledger_path(), 50)
    if rows:
        return rows[-1]
    return {
        "patch_id": V017_PATCH_ID,
        "title": V017_PATCH_TITLE,
        "installed_utc": "unknown",
        "status": "active_no_patch_ledger_found",
        "files_changed": ["app.py"],
        "safety": "live_orders_OFF | champion_LOCKED | no_API_keys | public_data_only",
    }


def v017_snapshot(data: Dict[str, Any]) -> Dict[str, Any]:
    state = data.get("state", {})
    counts = data.get("line_counts", {})
    bt = data.get("backtest_summary", {}) or {}
    universe = data.get("universe_summary", {}) or {}
    candle = data.get("candle_summary", {}) or {}
    return {
        "ts": iso_now(),
        "market_ticks": int(counts.get("market_ticks") or 0),
        "feed_proof": int(counts.get("feed_proof") or 0),
        "live_data_guard": int(counts.get("live_data_guard") or 0),
        "learning_cycles": int(counts.get("learning_cycles") or 0),
        "research_ledger": int(counts.get("research_ledger") or 0),
        "paper_shadow": int(counts.get("paper_shadow") or 0),
        "candle_rows": int(counts.get("candle_rows") or 0),
        "candle_proof": int(counts.get("candle_proof") or 0),
        "universe_scan": int(counts.get("universe_scan") or 0),
        "backtest_walkforward": int(counts.get("backtest_walkforward") or 0),
        "pulse_count": int(state.get("pulse_count") or 0),
        "gate": state.get("real_live_data_gate"),
        "raw_data_gate": state.get("raw_data_gate"),
        "warning": state.get("live_data_warning"),
        "stale_seconds": state.get("live_data_stale_seconds"),
        "current_regime": state.get("current_regime"),
        "collector_alive": bool(data.get("collector_alive")),
        "watch_enabled": bool(state.get("watch_enabled")),
        "paper_status": state.get("paper_shadow_status"),
        "candle_status": candle.get("status") or state.get("candle_harvester_status"),
        "universe_status": universe.get("status") or state.get("universe_scanner_status"),
        "universe_top": universe.get("top_symbol") or state.get("universe_scanner_top_symbol"),
        "universe_top_score": universe.get("top_score"),
        "backtest_gate": bt.get("gate") or state.get("backtest_walk_forward_status"),
        "backtest_status": bt.get("status") or state.get("backtest_gate_status"),
        "live_orders": state.get("live_orders"),
        "champion_lock": state.get("champion_lock"),
        "approved_champions": state.get("approved_champions"),
        "champion_claim_allowed": bool(bt.get("champion_claim_allowed", False)),
        "risk_police": state.get("risk_police"),
        "no_trade_score": state.get("no_trade_score"),
    }


def v017_delta_lines(current: Dict[str, Any], previous: Optional[Dict[str, Any]]) -> List[str]:
    keys = [
        "market_ticks", "feed_proof", "live_data_guard", "learning_cycles", "research_ledger",
        "paper_shadow", "candle_rows", "candle_proof", "universe_scan", "backtest_walkforward", "pulse_count",
    ]
    if not previous:
        return ["- First V017 snapshot saved. Deltas will appear on the next report."]
    lines = [f"- Previous snapshot UTC: {previous.get('ts')}"]
    for key in keys:
        cur = int(current.get(key) or 0)
        old = int(previous.get(key) or 0)
        lines.append(f"- {key}: {old} -> {cur} | delta={cur - old}")
    return lines


def v017_layer_lines(data: Dict[str, Any]) -> List[str]:
    state = data.get("state", {})
    counts = data.get("line_counts", {})
    candle = data.get("candle_summary", {}) or {}
    universe = data.get("universe_summary", {}) or {}
    bt = data.get("backtest_summary", {}) or {}
    return [
        f"- Overnight / Day Watch: {'WORKING' if state.get('watch_enabled') else 'PAUSED'} | collector_alive={data.get('collector_alive')} | pulse_count={state.get('pulse_count')} | last_pulse={state.get('last_pulse_at')}",
        f"- Market Feed: gate={state.get('real_live_data_gate')} | ticks={counts.get('market_ticks')} | proof={counts.get('feed_proof')} | guard={counts.get('live_data_guard')} | stale={state.get('live_data_stale_seconds')} | source={state.get('last_feed_source')}",
        f"- Learning Pulse: cycles={counts.get('learning_cycles')} | research_notes={counts.get('research_ledger')} | regime={v017_safe_text(state.get('current_regime'))} | growth={state.get('growth_score')} | learning={state.get('learning_score')}",
        f"- Paper Shadow: status={state.get('paper_shadow_status')} | rows={counts.get('paper_shadow')} | last_action={state.get('paper_shadow_last_action')} | open_position={state.get('paper_shadow_open_position')}",
        f"- Candle Harvester: status={candle.get('status') or state.get('candle_harvester_status')} | rows={counts.get('candle_rows')} | proof={counts.get('candle_proof')} | last_new_rows={candle.get('last_new_rows')}",
        f"- Universe Scanner: status={universe.get('status') or state.get('universe_scanner_status')} | rows={counts.get('universe_scan')} | latest_visible={universe.get('rows_visible')} | top={universe.get('top_symbol') or state.get('universe_scanner_top_symbol')} | top_score={universe.get('top_score')}",
        f"- Backtest Gate: status={bt.get('status') or state.get('backtest_gate_status')} | gate={bt.get('gate') or state.get('backtest_walk_forward_status')} | rows={counts.get('backtest_walkforward')} | champion_allowed={bt.get('champion_claim_allowed', False)}",
        f"- Risk Police / Champion: risk={state.get('risk_police')} | no_trade_score={state.get('no_trade_score')} | live_orders={state.get('live_orders')} | champion={state.get('champion_lock')} {state.get('approved_champions')}",
    ]


def generate_always_working_report() -> Tuple[Path, str]:
    ensure_dirs()
    data = compute_dashboard_state()
    state = data.get("state", {})
    counts = data.get("line_counts", {})
    bt = data.get("backtest_summary", {}) or {}
    patch = v017_last_patch_details()
    previous_rows = read_last_jsonl(v017_report_ledger_path(), 1)
    previous = previous_rows[-1] if previous_rows else None
    current = v017_snapshot(data)
    append_jsonl(v017_report_ledger_path(), current)

    gate = str(state.get("real_live_data_gate") or "")
    warning = str(state.get("live_data_warning") or "")
    live_data_verdict = "PASS" if gate.startswith("PASS") and warning in {"OK", "None", "", "null"} else "WATCH"
    safety_verdict = "PASS" if state.get("live_orders") == "OFF" and state.get("champion_lock") == "LOCKED" and not bt.get("champion_claim_allowed", False) else "FAIL"
    collection_verdict = "PASS" if data.get("collector_alive") and state.get("watch_enabled") and int(counts.get("market_ticks") or 0) > 0 else "WATCH"
    backtest_gate = str(bt.get("gate") or state.get("backtest_walk_forward_status") or "NOT_RUN")
    if "RISK_TOO_HIGH" in backtest_gate:
        edge_verdict = "RISK TOO HIGH - NOT PROVEN"
    elif "EDGE_NOT_PROVEN" in backtest_gate or "NOT_RUN" in backtest_gate:
        edge_verdict = "NOT PROVEN"
    elif bt.get("champion_claim_allowed") is True:
        edge_verdict = "READY FOR HUMAN REVIEW ONLY"
    else:
        edge_verdict = "LOCKED / NOT PROVEN"

    latest_paper = data.get("last_paper", [])[-8:]
    latest_universe = data.get("last_universe", [])[:10]
    latest_backtests = data.get("last_backtests", [])[-5:]

    lines: List[str] = []
    lines.append("BALI ALWAYS-WORKING BOT STATS REPORT")
    lines.append("=" * 72)
    lines.append(f"Generated UTC: {iso_now()}")
    lines.append(f"Version: {VERSION}")
    lines.append(f"Patch center: {V017_PATCH_ID}")
    lines.append("")
    lines.append("VERDICTS")
    lines.append(f"LIVE DATA: {live_data_verdict}")
    lines.append(f"SAFETY: {safety_verdict}")
    lines.append(f"BOT COLLECTION: {collection_verdict}")
    lines.append(f"EDGE PROOF: {edge_verdict}")
    lines.append("")
    lines.append("LAST PATCH DETAILS")
    lines.append(f"Patch ID: {patch.get('patch_id')}")
    lines.append(f"Title: {patch.get('title')}")
    lines.append(f"Installed UTC: {patch.get('installed_utc')}")
    lines.append(f"Status: {patch.get('status')}")
    lines.append("Files changed:")
    for item in patch.get("files_changed", []) or ["app.py"]:
        lines.append(f"- {item}")
    lines.append("")
    lines.append("SAFETY STATE")
    lines.append(f"Live orders: {state.get('live_orders')}")
    lines.append(f"Champion lock: {state.get('champion_lock')} / approved {state.get('approved_champions')}")
    lines.append("API keys: NONE / private exchange endpoints not used")
    lines.append(f"Mode: {state.get('mode')}")
    lines.append(f"Risk Police: {state.get('risk_police')}")
    lines.append(f"Champion claim allowed: {bt.get('champion_claim_allowed', False)}")
    lines.append("")
    lines.append("REAL LIVE DATA")
    lines.append(f"Gate: {state.get('real_live_data_gate')}")
    lines.append(f"Raw data rule: {state.get('raw_data_gate')}")
    lines.append(f"Warning: {state.get('live_data_warning')}")
    lines.append(f"Stale seconds: {state.get('live_data_stale_seconds')}")
    lines.append(f"Feed source: {state.get('last_feed_source')}")
    lines.append(f"Feed status: {state.get('last_feed_status')}")
    lines.append(f"Current regime: {v017_safe_text(state.get('current_regime'))}")
    lines.append(f"Ignored recent offline_demo rows: {data.get('ignored_demo_tick_rows_in_recent_window')}")
    lines.append("")
    lines.append("BOT / LAYER STATS")
    lines.extend(v017_layer_lines(data))
    lines.append("")
    lines.append("COUNTS")
    for key in ["market_ticks", "feed_proof", "live_data_guard", "learning_cycles", "research_ledger", "paper_shadow", "candle_rows", "candle_proof", "universe_scan", "backtest_walkforward"]:
        lines.append(f"- {key}: {counts.get(key)}")
    lines.append("")
    lines.append("DELTAS SINCE LAST V017 REPORT")
    lines.extend(v017_delta_lines(current, previous))
    lines.append("")
    lines.append("LATEST PAPER SHADOW")
    if latest_paper:
        for row in latest_paper:
            lines.append(f"- {row.get('ts')} | {row.get('action')} | {row.get('symbol')} | {row.get('verdict')} | regime={v017_safe_text(row.get('regime'))} | reason={row.get('reason')}")
    else:
        lines.append("- none")
    lines.append("")
    lines.append("LATEST UNIVERSE TOP 10")
    if latest_universe:
        for row in latest_universe:
            lines.append(f"- {row.get('symbol')} | bucket={row.get('bucket')} | score={row.get('universe_score')} | 24h={row.get('price_change_percent_24h')} | qv={row.get('quote_volume')} | batch={row.get('batch_id')}")
    else:
        lines.append("- none")
    lines.append("")
    lines.append("LATEST BACKTEST / WALK-FORWARD")
    if latest_backtests:
        for row in latest_backtests:
            lines.append(f"- {row.get('ts')} | {row.get('run_id')} | {row.get('symbol')} {row.get('interval')} | gate={row.get('gate')} | candles={row.get('total_candles')} | in_avg={row.get('in_sample_avg_net_pct')} | wf_avg={row.get('walk_forward_avg_net_pct')} | champion_allowed={row.get('champion_claim_allowed')}")
    else:
        lines.append("- none")
    lines.append("")
    lines.append("NEXT SAFE ACTION")
    if edge_verdict.startswith("RISK TOO HIGH"):
        lines.append("Keep collecting public-data and paper-shadow evidence. Do not unlock Champion. Do not enable live trading.")
    else:
        lines.append("Keep running the always-working collector and generate this report whenever handing status to ChatGPT.")
    lines.append("")
    lines.append("HARD LOCKS")
    lines.append("Live trading enable, API keys, champion approval, private endpoints, and Risk Police disable remain unavailable in this build.")

    text = "\n".join(lines) + "\n"
    name = f"BALI_ALWAYS_WORKING_BOT_STATS_REPORT_{utc_now().strftime('%Y%m%d_%H%M%S')}.txt"
    path = REPORTS / name
    path.write_text(text, encoding="utf-8")
    try:
        (LOGS / "LAST_ALWAYS_WORKING_BOT_STATS_REPORT.txt").write_text(text, encoding="utf-8")
        (REPORTS / "LAST_ALWAYS_WORKING_BOT_STATS_REPORT.txt").write_text(text, encoding="utf-8")
    except Exception:
        pass
    return path, text
# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ===
'@
if (-not $text.Contains($markerBegin)) {
    if (-not $text.Contains("def doctor_report()")) { Fail "Could not find doctor_report anchor in app.py." }
    $text = $text.Replace("def doctor_report()", $V017Code + "`r`n`r`ndef doctor_report()")
}

$OldEsc = @'
function esc(x){return String(x??'').replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));}
'@
$NewEsc = @'
function pretty(x){if(x&&typeof x==='object'){if(x.label)return String(x.label);try{return JSON.stringify(x)}catch(e){return String(x)}}return String(x??'');}
function esc(x){return pretty(x).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));}
'@
if ($text.Contains($OldEsc.Trim()) -and (-not $text.Contains("function pretty(x)"))) {
    $text = $text.Replace($OldEsc.Trim(), $NewEsc.Trim())
}

$JsFunc = @'
async function generateAlwaysWorkingReport(){let out=await api('/api/report/always-working');let txt=out.text||JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML=`<div class="grid"><section class="card full"><h2>Always-Working Bot Stats Report</h2><p class="muted">${esc(copied?'Copied to clipboard. Paste it into ChatGPT.':'Generated. Select the text below and copy it into ChatGPT.')}</p><button class="btn" onclick="setTab('reports')">Back to Reports</button><button class="btn alt" onclick="generateAlwaysWorkingReport()">Generate Again</button><a class="btn alt" href="/reports/${encodeURIComponent(out.report||'')}" target="_blank">Open Text File</a><pre>${esc(txt)}</pre></section></div>`;}
'@
if (-not $text.Contains("async function generateAlwaysWorkingReport()")) {
    if (-not $text.Contains("async function generateChatGptReport()")) { Fail "Could not find generateChatGptReport JS anchor." }
    $text = $text.Replace("async function generateChatGptReport()", $JsFunc + "`r`nasync function generateChatGptReport()")
}

$Route = @'
            elif path == "/api/report/always-working":
                p, text = generate_always_working_report()
                self.send_json({"ok": True, "message": f"Always-working bot stats report generated: {p.name}", "report": p.name, "text": text})
'@
if (-not $text.Contains("/api/report/always-working")) {
    if (-not $text.Contains('            elif path == "/api/report/chatgpt":')) { Fail "Could not find report API route anchor." }
    $text = $text.Replace('            elif path == "/api/report/chatgpt":', $Route + "`r`n" + '            elif path == "/api/report/chatgpt":')
}

if (-not (($text.Split("function reports(s)",2)[1]).Contains("Always-Working Bot Stats Report"))) {
    $Needle = @'
return `<div class="grid">${card('Automated ChatGPT Report',
'@
    $Insert = @'
return `<div class="grid">${card('Always-Working Bot Stats Report',`<p>One button report for last patch details, bot/layer stats, deltas since last report, safety, live-data health, Risk Police, and Champion lock.</p><button class="btn" onclick="generateAlwaysWorkingReport()">Generate Always-Working Bot Stats Report</button><p class="muted">Saved to shared_data/reports and copied when the browser allows it.</p>`,'card wide')}${card('Automated ChatGPT Report',
'@
    if (-not $text.Contains($Needle.Trim())) { Fail "Could not find Reports card anchor." }
    $text = $text.Replace($Needle.Trim(), $Insert.Trim())
}

[IO.File]::WriteAllText($AppPath, $text, [Text.UTF8Encoding]::new($false))
Info "app.py patched."

$Shared = Join-Path $AppDir "shared_data"
$Reports = Join-Path $Shared "reports"
$Patches = Join-Path $Shared "patches"
New-Item -ItemType Directory -Force -Path $Reports, $Patches | Out-Null
$ledger = Join-Path $Patches "patch_ledger.jsonl"
$row = [ordered]@{
    patch_id = $PatchId
    title = $PatchTitle
    installed_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    status = "installed_no_py_launcher"
    files_changed = @("app.py", "README_V017_ALWAYS_WORKING_REPORT_CENTER.md", "START_BALI_ROCKET_SAFE.cmd", "Desktop shortcut: Bali Rocket Forever Safe")
    safety = "LIVE_ORDERS_OFF | CHAMPION_LOCKED | NO_API_KEYS | PUBLIC_DATA_RESEARCH_ONLY"
}
($row | ConvertTo-Json -Compress) | Add-Content -LiteralPath $ledger -Encoding UTF8

$readme = Join-Path $OuterRoot "README_V017_ALWAYS_WORKING_REPORT_CENTER.md"
@"
# V017 Always-Working Report Center

Installed UTC: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))

What changed:
- Added Reports -> Generate Always-Working Bot Stats Report.
- Report includes last patch details, files changed, bot/layer stats, deltas, safety, live-data health, Risk Police, and Champion lock.
- Fixed dashboard object display so regime objects do not show as [object Object].
- Kept live orders OFF, API keys NONE, Champion LOCKED, and public-data / paper-only mode.

Use:
1. Restart Bali from the desktop icon: Bali Rocket Forever Safe.
2. Open Reports.
3. Click Generate Always-Working Bot Stats Report.

Hard locks remain:
- No live trading.
- No API keys.
- No private endpoints.
- No Champion unlock.
- Edge proof remains blocked until repeated evidence passes.
"@ | Set-Content -LiteralPath $readme -Encoding UTF8

$StartFile = Join-Path $OuterRoot "START_BALI_ROCKET_SAFE.cmd"
@"
@echo off
setlocal EnableExtensions
title Bali Rocket Forever Safe
cd /d "%~dp0"
set LIVE_ORDERS=OFF
set BALI_LIVE_ORDERS=OFF
set CHAMPION_CLAIM_ALLOWED=false
set BALI_PUBLIC_DATA_ONLY=1
set API_KEY=
set API_SECRET=
set BINANCE_API_KEY=
set BINANCE_API_SECRET=
set OPENAI_API_KEY=
set ANTHROPIC_API_KEY=
if exist "BALI_THEMED_FOREVER_STARTER_ORIGINAL_V037.bat" (
  call "%~dp0BALI_THEMED_FOREVER_STARTER_ORIGINAL_V037.bat"
  exit /b %ERRORLEVEL%
)
if exist "BALI_ROCKET_FOREVER_STARTER_ORIGINAL_V037.bat" (
  call "%~dp0BALI_ROCKET_FOREVER_STARTER_ORIGINAL_V037.bat"
  exit /b %ERRORLEVEL%
)
if exist "bali_rocket_crypto_command_v011b\app.py" (
  cd /d "%~dp0bali_rocket_crypto_command_v011b"
) else if exist "app.py" (
  cd /d "%~dp0"
) else (
  echo Could not find app.py near this launcher.
  pause
  exit /b 1
)
where python >nul 2>nul
if errorlevel 1 (
  echo The Windows python command was not found.
  echo This launcher did not call py. Use your original Bali starter if it exists.
  pause
  exit /b 1
)
start "Bali Rocket Dashboard" http://127.0.0.1:9061/
python app.py --host 127.0.0.1 --port 9061
pause
"@ | Set-Content -LiteralPath $StartFile -Encoding ASCII

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Bali Rocket Forever Safe.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnk)
    $sc.TargetPath = $StartFile
    $sc.WorkingDirectory = $OuterRoot
    $sc.Description = "Bali Rocket Forever Safe - public-data and paper-only"
    $sc.Save()
    Info "Desktop shortcut refreshed: $lnk"
} catch {
    Write-Host "Shortcut refresh warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PATCH INSTALLED: V017 Always-Working Report Center" -ForegroundColor Green
Write-Host "Safety kept: live orders OFF, Champion LOCKED, API keys NONE, public-data/paper-only." -ForegroundColor Green
Write-Host "Restart Bali from the desktop icon: Bali Rocket Forever Safe" -ForegroundColor Cyan
Write-Host "Then open Reports -> Generate Always-Working Bot Stats Report." -ForegroundColor Cyan
exit 0
