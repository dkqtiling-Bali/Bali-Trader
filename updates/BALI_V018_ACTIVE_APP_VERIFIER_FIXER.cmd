@echo off
setlocal EnableExtensions
title Bali V018 Active App Verifier/Fixer

echo.
echo ============================================================
echo  BALI V018 - ACTIVE APP VERIFIER/FIXER
echo ============================================================
echo.
echo This tiny fixer installs the missing V018 dashboard button/route

echo into the Bali app.py that your dashboard is most likely using.
echo.
echo It does NOT enable live orders, add API keys, unlock Champion,
echo use private endpoints, process update ZIPs, or change trading logic.
echo.
set "BALI_V018_SELF=%~f0"
set "BALI_V018_TEMPPS=%TEMP%\bali_v018_active_fix_%RANDOM%_%RANDOM%.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$lines=[IO.File]::ReadAllLines($env:BALI_V018_SELF); $idx=-1; for($j=0;$j -lt $lines.Length;$j++){ if($lines[$j].Trim() -eq '###BALI_V018_ACTIVE_FIX_PS_PAYLOAD###'){ $idx=$j; break } }; if($idx -lt 0){Write-Host 'Payload marker missing'; exit 9}; $payload=($lines[($idx+1)..($lines.Length-1)] -join [Environment]::NewLine); [IO.File]::WriteAllText($env:BALI_V018_TEMPPS,$payload,[Text.UTF8Encoding]::new($false))"
if errorlevel 1 goto fail
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BALI_V018_TEMPPS%"
if errorlevel 1 goto fail
del "%BALI_V018_TEMPPS%" >nul 2>nul
echo.
echo DONE. Restart from the desktop icon: Bali Rocket Forever Safe
echo Then open Reports and click Generate Risk Filter Tuner Report.
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

###BALI_V018_ACTIVE_FIX_PS_PAYLOAD###

$ErrorActionPreference = "Stop"
$PatchId = "V018_RISK_FILTER_TUNER_ACTIVE_FIX"
$PatchTitle = "Risk Filter Tuner Active App Verifier/Fixer"

function Fail($Message) {
    Write-Host ""
    Write-Host "PATCH FAILED: $Message" -ForegroundColor Red
    Write-Host "Nothing live-trading related was enabled." -ForegroundColor Yellow
    exit 1
}
function Info($Message) { Write-Host $Message -ForegroundColor Cyan }
function Warn($Message) { Write-Host $Message -ForegroundColor Yellow }

function Add-Candidate([System.Collections.ArrayList]$List, [string]$Path, [int]$Bonus, [string]$Why) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    try {
        $full = [IO.Path]::GetFullPath($Path.Trim('"'))
        if (-not (Test-Path -LiteralPath $full)) { return }
        $item = Get-Item -LiteralPath $full -ErrorAction Stop
        if ($item.PSIsContainer -or $item.Name -ine "app.py") { return }
        [void]$List.Add([pscustomobject]@{ Path=$item.FullName; Bonus=$Bonus; Why=$Why; LastWriteTime=$item.LastWriteTime })
    } catch {}
}

function Get-RunningAppCandidates() {
    $c = New-Object System.Collections.ArrayList
    try {
        $procs = Get-CimInstance Win32_Process | Where-Object {
            ($_.CommandLine -match '(?i)bali|rocket|crypto|app\.py|python') -and ($_.CommandLine -match '(?i)app\.py')
        }
        foreach ($p in $procs) {
            $cmd = [string]$p.CommandLine
            foreach ($m in [regex]::Matches($cmd, '"([A-Za-z]:\\[^"<>|]*?app\.py)"')) {
                Add-Candidate $c $m.Groups[1].Value 1000 "running process quoted path"
            }
            foreach ($m in [regex]::Matches($cmd, '([A-Za-z]:\\[^\s"<>|]*?app\.py)')) {
                Add-Candidate $c $m.Groups[1].Value 950 "running process path"
            }
        }
    } catch {}
    return $c
}

function Get-BaliAppScore($Path, $Bonus, $Why) {
    $score = [int]$Bonus
    $low = ([string]$Path).ToLowerInvariant()
    if ($low.EndsWith("app.py")) { $score += 20 }
    if ($low.Contains("bali_rocket_crypto_command_v011b")) { $score += 60 }
    if ($low.Contains("bali_rocket")) { $score += 25 }
    if ($low.Contains("backup") -or $low.Contains("backups") -or $low.Contains("_staging") -or $low.Contains("payload") -or $low.Contains("updates") -or $low.Contains("releases") -or $low.Contains("__pycache__") -or $low.Contains(".git")) { $score -= 200 }
    try {
        $txt = [IO.File]::ReadAllText($Path)
        if ($txt.Contains("Bali Rocket Crypto Command")) { $score += 100 }
        if ($txt.Contains("def compute_dashboard_state")) { $score += 40 }
        if ($txt.Contains("/api/report/always-working")) { $score += 80 }
        if ($txt.Contains("V017_ALWAYS_WORKING_REPORT_CENTER")) { $score += 100 }
        if ($txt.Contains("Generate Always-Working Bot Stats Report")) { $score += 60 }
        if ($txt.Contains('elif path == "/api/report/risk-filter"')) { $score += 30 }
    } catch { $score -= 1000 }
    try {
        $dir = Split-Path -Parent $Path
        $reports = Join-Path $dir "shared_data\reports"
        if (Test-Path -LiteralPath $reports) {
            $latestV17 = Get-ChildItem -LiteralPath $reports -Filter "BALI_ALWAYS_WORKING_BOT_STATS_REPORT_*.txt" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestV17) {
                $score += 200
                if ($latestV17.LastWriteTime -gt (Get-Date).AddHours(-4)) { $score += 300 }
            }
            $latestChat = Get-ChildItem -LiteralPath $reports -Filter "BALI_CHATGPT_STATUS_REPORT_*.txt" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestChat -and $latestChat.LastWriteTime -gt (Get-Date).AddHours(-4)) { $score += 150 }
        }
    } catch {}
    return $score
}

function Find-BaliApp($StartDir) {
    $candidates = New-Object System.Collections.ArrayList
    foreach ($x in Get-RunningAppCandidates) { [void]$candidates.Add($x) }

    $roots = New-Object System.Collections.Generic.List[string]
    function AddRoot($r) {
        if ([string]::IsNullOrWhiteSpace($r)) { return }
        try { $full = [IO.Path]::GetFullPath($r); if ((Test-Path -LiteralPath $full) -and (-not $roots.Contains($full))) { [void]$roots.Add($full) } } catch {}
    }
    AddRoot $StartDir
    AddRoot (Get-Location).Path
    AddRoot ([Environment]::GetFolderPath("Desktop"))
    AddRoot ([Environment]::GetFolderPath("MyDocuments"))
    AddRoot ([IO.Path]::Combine($env:USERPROFILE,"Downloads"))

    foreach ($root in $roots) {
        foreach ($direct in @((Join-Path $root "app.py"), (Join-Path $root "bali_rocket_crypto_command_v011b\app.py"))) { Add-Candidate $candidates $direct 0 "direct/root search" }
        try {
            Get-ChildItem -LiteralPath $root -Filter "app.py" -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "\\(backups|backup|updates|releases|__pycache__|\.git)\\" } |
                Select-Object -First 160 |
                ForEach-Object { Add-Candidate $candidates $_.FullName 0 "recursive search" }
        } catch {}
    }

    $scored = @()
    foreach ($group in ($candidates | Group-Object Path)) {
        $first = $group.Group[0]
        $bonus = ($group.Group | Measure-Object -Property Bonus -Maximum).Maximum
        $why = (($group.Group | Sort-Object Bonus -Descending | Select-Object -First 1).Why)
        $score = Get-BaliAppScore $first.Path $bonus $why
        if ($score -gt 100) { $scored += [pscustomobject]@{ Path=$first.Path; Score=$score; Why=$why; LastWriteTime=$first.LastWriteTime } }
    }
    if (-not $scored -or $scored.Count -lt 1) { return $null }
    Write-Host "Top Bali app candidates:" -ForegroundColor Cyan
    $scored | Sort-Object -Property @{Expression="Score";Descending=$true}, @{Expression="LastWriteTime";Descending=$true} | Select-Object -First 5 | ForEach-Object {
        Write-Host ("  score={0} | {1} | {2}" -f $_.Score, $_.Why, $_.Path)
    }
    $best = $scored | Sort-Object -Property @{Expression="Score";Descending=$true}, @{Expression="LastWriteTime";Descending=$true} | Select-Object -First 1
    return $best.Path
}

$Here = Split-Path -Parent $env:BALI_V018_SELF
$AppPath = Find-BaliApp $Here
if (-not $AppPath) { Fail "Could not find the active Bali app.py. Put this file inside the running Bali project folder and run again." }
$AppDir = Split-Path -Parent $AppPath
$OuterRoot = Split-Path -Parent $AppDir
if ((Split-Path -Leaf $AppDir) -ne "bali_rocket_crypto_command_v011b") { $OuterRoot = $AppDir }
Info "Selected Bali app: $AppPath"

$text = [IO.File]::ReadAllText($AppPath)
if (-not $text.Contains("V017_ALWAYS_WORKING_REPORT_CENTER") -and -not $text.Contains("/api/report/always-working")) {
    Fail "V017 report center was not found in selected app.py. This fixer only adds missing V018 on top of V017."
}

$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
$recovery = Join-Path $OuterRoot "_BALI_FOREVER_RECOVERY"
$backupDir = Join-Path $recovery "v018_active_fix_backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backup = Join-Path $backupDir ("app.py.before_V018_ACTIVE_FIX_" + $stamp + ".bak")
Copy-Item -LiteralPath $AppPath -Destination $backup -Force
Info "Backup written: $backup"

# Replace incomplete V018 Python block, then re-add a complete one.
$text = [regex]::Replace($text, "(?s)\r?\n?# === BALI_V018_RISK_FILTER_TUNER_BEGIN ===.*?# === BALI_V018_RISK_FILTER_TUNER_END ===\r?\n?", "`r`n")
$V018Code = @'
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
'@
if ($text.Contains("# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ===")) {
    $text = $text.Replace("# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ===", "# === BALI_V017_ALWAYS_WORKING_REPORT_CENTER_END ===`r`n`r`n" + $V018Code.Trim())
} elseif ($text.Contains("def generate_chatgpt_report()")) {
    $text = $text.Replace("def generate_chatgpt_report()", $V018Code.Trim() + "`r`n`r`ndef generate_chatgpt_report()")
} else {
    Fail "Could not find a safe Python insertion anchor."
}

# Ensure JS function exists.
$JsFunc = @'
async function generateRiskFilterReport(){let out=await api('/api/report/risk-filter');let txt=out.text||JSON.stringify(out,null,2);let copied=false;try{await navigator.clipboard.writeText(txt);copied=true;}catch(e){}document.getElementById('app').innerHTML=`<div class="grid"><section class="card full"><h2>V018 Risk Filter Tuner Report</h2><p class="muted">${esc(copied?'Copied to clipboard. Paste it into ChatGPT.':'Generated. Select the text below and copy it into ChatGPT.')}</p><button class="btn" onclick="setTab('reports')">Back to Reports</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Again</button><a class="btn alt" href="/reports/${encodeURIComponent(out.report||'')}" target="_blank">Open Text File</a><pre>${esc(txt)}</pre></section></div>`;}
'@
if (-not $text.Contains("async function generateRiskFilterReport()")) {
    if ($text.Contains("async function generateAlwaysWorkingReport()")) {
        $text = $text.Replace("async function generateAlwaysWorkingReport()", $JsFunc.Trim() + "`r`nasync function generateAlwaysWorkingReport()")
    } elseif ($text.Contains("async function generateChatGptReport()")) {
        $text = $text.Replace("async function generateChatGptReport()", $JsFunc.Trim() + "`r`nasync function generateChatGptReport()")
    } else {
        Fail "Could not find a safe JavaScript insertion anchor."
    }
}

# Ensure API route exists. Check for route specifically, not just the JS URL string.
$Route = @'
            elif path == "/api/report/risk-filter":
                p, text = generate_risk_filter_tuner_report()
                self.send_json({"ok": True, "message": f"V018 risk filter tuner report generated: {p.name}", "report": p.name, "text": text})
'@
if (-not $text.Contains('elif path == "/api/report/risk-filter"')) {
    if ($text.Contains('            elif path == "/api/report/always-working":')) {
        $text = $text.Replace('            elif path == "/api/report/always-working":', $Route.TrimEnd() + "`r`n" + '            elif path == "/api/report/always-working":')
    } elseif ($text.Contains('            elif path == "/api/report/chatgpt":')) {
        $text = $text.Replace('            elif path == "/api/report/chatgpt":', $Route.TrimEnd() + "`r`n" + '            elif path == "/api/report/chatgpt":')
    } else {
        Fail "Could not find report API route anchor."
    }
}

# Ensure visible button exists in Reports and Backtest areas.
if (-not $text.Contains("Generate Risk Filter Tuner Report")) {
    $before = $text
    $text = $text.Replace('Generate Always-Working Bot Stats Report</button>', 'Generate Always-Working Bot Stats Report</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Risk Filter Tuner Report</button>')
    $text = $text.Replace('Run Backtest + Walk-Forward Gate</button>', 'Run Backtest + Walk-Forward Gate</button><button class="btn alt" onclick="generateRiskFilterReport()">Generate Risk Filter Tuner Report</button>')
    if ($text -eq $before) { Warn "Could not find exact button anchor; route will still work at /api/report/risk-filter." }
}

# Create a small launcher report command too, so the user has a fallback if the browser button does not refresh yet.
$ToolDir = Join-Path $OuterRoot "tools"
New-Item -ItemType Directory -Force -Path $ToolDir | Out-Null
$Fallback = Join-Path $OuterRoot "GENERATE_V018_RISK_REPORT_FROM_HERE.cmd"
@"
@echo off
setlocal
cd /d "%~dp0bali_rocket_crypto_command_v011b" 2>nul || cd /d "%~dp0"
echo Open the dashboard and use Reports -^> Generate Risk Filter Tuner Report.
echo If the dashboard is open already, restart from Bali Rocket Forever Safe first.
echo This fallback exists only as a reminder; the real report is the dashboard button.
pause
"@ | Set-Content -LiteralPath $Fallback -Encoding ASCII

[IO.File]::WriteAllText($AppPath, $text, [Text.UTF8Encoding]::new($false))
Info "app.py patched/verified with V018 risk explainer."

$Shared = Join-Path $AppDir "shared_data"
$Reports = Join-Path $Shared "reports"
$Patches = Join-Path $Shared "patches"
New-Item -ItemType Directory -Force -Path $Reports, $Patches | Out-Null
$ledger = Join-Path $Patches "patch_ledger.jsonl"
$row = [ordered]@{
    patch_id = $PatchId
    title = $PatchTitle
    installed_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    status = "installed_active_app_verified"
    selected_app = $AppPath
    files_changed = @("app.py", "README_V018_RISK_FILTER_TUNER_ACTIVE_FIX.txt", "Reports button: Generate Risk Filter Tuner Report")
    safety = "LIVE_ORDERS_OFF | CHAMPION_LOCKED | NO_API_KEYS | PUBLIC_DATA_RESEARCH_ONLY | NO_STRATEGY_CHANGE"
}
($row | ConvertTo-Json -Compress) | Add-Content -LiteralPath $ledger -Encoding UTF8

$readme = Join-Path $OuterRoot "README_V018_RISK_FILTER_TUNER_ACTIVE_FIX.txt"
@"
V018 Risk Filter Tuner Active App Verifier/Fixer
Installed UTC: $((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
Selected app: $AppPath

What changed:
- Verified/patched the active Bali app.py instead of a stale copied app.py.
- Added the V018 risk filter tuner backend report function.
- Added the /api/report/risk-filter route.
- Added the dashboard button: Generate Risk Filter Tuner Report.

Safety:
- No live trading enabled.
- No API keys added.
- No private endpoints added.
- Champion remains locked.
- Strategy/trading logic was not changed.
"@ | Set-Content -LiteralPath $readme -Encoding UTF8

Write-Host ""
Write-Host "PATCH INSTALLED: V018 Active App Verifier/Fixer" -ForegroundColor Green
Write-Host "Safety kept: live orders OFF, Champion LOCKED, API keys NONE, public-data/paper-only." -ForegroundColor Green
Write-Host "Selected app: $AppPath" -ForegroundColor Green
Write-Host "Restart Bali from: Bali Rocket Forever Safe" -ForegroundColor Cyan
Write-Host "Then open Reports -> Generate Risk Filter Tuner Report." -ForegroundColor Cyan
exit 0
