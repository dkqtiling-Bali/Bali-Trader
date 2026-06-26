param(
  [string]$Action = "Session",
  [string]$Base = "C:\Bali\Bali-Trader"
)

$ErrorActionPreference = "Stop"
$Base = (Resolve-Path -LiteralPath $Base).Path
Set-Location -LiteralPath $Base

function Ensure-Dirs {
  $dirs = @(
    "AI_HANDOVER_REPORTS", "STATUS_DASHBOARDS", "NEXT_PATCH_REPORTS", "PROJECT_MAPS", "EVIDENCE_INDEX",
    "SAFETY_REPORTS", "SESSION_REPORTS", "RUN_REGISTRY", "APPROVAL_QUEUE", "PATCH_QUEUE", "TEST_REPORTS", "INSTALL_REPORTS"
  )
  foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $Base $d) | Out-Null }
}

function Read-ShortFile($rel, $maxLines = 80) {
  $p = Join-Path $Base $rel
  if (-not (Test-Path -LiteralPath $p)) { return @("MISSING: $rel") }
  return @(Get-Content -LiteralPath $p -TotalCount $maxLines -ErrorAction SilentlyContinue)
}

function Get-LatestFile($dirRel, $filter = "*") {
  $dir = Join-Path $Base $dirRel
  if (-not (Test-Path -LiteralPath $dir)) { return $null }
  return Get-ChildItem -LiteralPath $dir -File -Filter $filter -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Get-GitSummary {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) { return [pscustomobject]@{ Available=$false; Branch="UNKNOWN"; Short="GIT_NOT_FOUND"; Clean=$false } }
  $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
  $status = @(git status --short 2>$null)
  $clean = ($status.Count -eq 0)
  $short = if ($clean) { "CLEAN" } else { "DIRTY " + $status.Count + " item(s)" }
  return [pscustomobject]@{ Available=$true; Branch=$branch; Short=$short; Clean=$clean; Status=$status }
}

function Get-VersionSummary {
  $manifest = Join-Path $Base "update_manifest.json"
  if (Test-Path -LiteralPath $manifest) {
    try {
      $m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
      return ($m.version + " / " + $m.name)
    } catch { return "manifest unreadable" }
  }
  return "unknown"
}

function Get-SafetyFlags {
  $texts = @()
  foreach ($rel in @("CONSTITUTION.md", "AI_RULES.md", "MISSION.md", "LEDGER.md", "NEXT_PATCH.md")) {
    $p = Join-Path $Base $rel
    if (Test-Path -LiteralPath $p) { $texts += Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue }
  }
  $blob = ($texts -join "`n")
  return [pscustomobject]@{
    LiveOrdersOff = ($blob -match "LIVE_ORDERS_OFF|NO live trading|NO_LIVE_TRADING")
    NoApiKeys = ($blob -match "NO_API_KEYS|NO API keys")
    PublicDataOnly = ($blob -match "PUBLIC_DATA_ONLY|PUBLIC DATA ONLY")
    ChampionLocked = ($blob -match "CHAMPION_LOCKED|Champion Lock")
    PaperFirst = ($blob -match "PAPER/SIM FIRST|paper/sim")
  }
}

function New-StatusDashboard {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $git = Get-GitSummary
  $flags = Get-SafetyFlags
  $latestSafety = Get-LatestFile "SAFETY_REPORTS" "*.txt"
  $latestReport = Get-LatestFile "AI_HANDOVER_REPORTS" "*.txt"
  $version = Get-VersionSummary
  $ready = 100
  if (-not $git.Clean) { $ready -= 10 }
  if (-not $flags.LiveOrdersOff) { $ready -= 20 }
  if (-not $flags.NoApiKeys) { $ready -= 20 }
  if (-not $flags.ChampionLocked) { $ready -= 10 }
  if (-not $flags.PaperFirst) { $ready -= 10 }
  if ($ready -lt 0) { $ready = 0 }
  $safetyText = if (($flags.LiveOrdersOff -and $flags.NoApiKeys -and $flags.ChampionLocked -and $flags.PaperFirst)) { "PASS" } else { "REVIEW" }
  $latestSafetyText = if ($latestSafety) { $latestSafety.Name } else { "none" }
  $latestReportText = if ($latestReport) { $latestReport.Name } else { "none" }
  $path = Join-Path $Base ("STATUS_DASHBOARDS\BALI_STATUS_V5_" + $stamp + ".txt")
  $lines = @(
    "BALI STATUS DASHBOARD V5",
    "Generated: " + (Get-Date),
    "Base: " + $Base,
    "",
    "BALI STATUS",
    "Version: " + $version,
    "Git: " + $git.Short,
    "Branch: " + $git.Branch,
    "Safety: " + $safetyText,
    "LIVE_ORDERS_OFF: " + $flags.LiveOrdersOff,
    "NO_API_KEYS: " + $flags.NoApiKeys,
    "PUBLIC_DATA_ONLY: " + $flags.PublicDataOnly,
    "CHAMPION_LOCKED: " + $flags.ChampionLocked,
    "PAPER_SIM_FIRST: " + $flags.PaperFirst,
    "Latest Safety Report: " + $latestSafetyText,
    "Latest Handover: " + $latestReportText,
    "Overall Readiness: " + $ready + "%",
    "",
    "NEXT OPERATOR STEP",
    "Run BALI_MASTER_CONTROL option 4 to review recommended task, or option 8 to safe-save generated reports."
  )
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "BALI_STATUS_LATEST.txt") -Force
  Write-Host "Status dashboard created: $path"
  return $path
}

function New-ProjectMap {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $path = Join-Path $Base ("PROJECT_MAPS\BALI_PROJECT_MAP_V5_" + $stamp + ".md")
  $top = Get-ChildItem -LiteralPath $Base -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @(".git", "BACKUPS", "__pycache__") } | Sort-Object PSIsContainer, Name
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("# BALI PROJECT MAP V5")
  $lines.Add("")
  $lines.Add("Generated: " + (Get-Date))
  $lines.Add("Base: " + $Base)
  $lines.Add("")
  $lines.Add("## Top Level")
  foreach ($x in $top) {
    $kind = if ($x.PSIsContainer) { "DIR " } else { "FILE" }
    $lines.Add("- [$kind] " + $x.Name)
  }
  $lines.Add("")
  $lines.Add("## Major Automation Files")
  foreach ($rel in @("BALI_MASTER_CONTROL.bat", "BALI_START_HERE.bat", "BALI_ONE_CLICK_SESSION.bat", "BALI_SAFE_GIT_SAVE.bat", "tools\BALI_OS_ENGINE_V5.ps1", "tools\BALI_SAFE_GIT_SAVE_V5.ps1", "tools\BALI_OS_SAFETY_SCAN_V5.ps1")) {
    $present = if (Test-Path -LiteralPath (Join-Path $Base $rel)) { "PRESENT" } else { "MISSING" }
    $lines.Add("- " + $rel + ": " + $present)
  }
  $lines.Add("")
  $lines.Add("## Report Folders")
  foreach ($rel in @("AI_HANDOVER_REPORTS", "STATUS_DASHBOARDS", "NEXT_PATCH_REPORTS", "PROJECT_MAPS", "EVIDENCE_INDEX", "SAFETY_REPORTS", "SESSION_REPORTS", "RUN_REGISTRY", "APPROVAL_QUEUE", "PATCH_QUEUE", "TEST_REPORTS")) {
    $p = Join-Path $Base $rel
    $count = if (Test-Path -LiteralPath $p) { @(Get-ChildItem -LiteralPath $p -File -ErrorAction SilentlyContinue).Count } else { 0 }
    $lines.Add("- " + $rel + ": " + $count + " file(s)")
  }
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "PROJECT_MAP.md") -Force
  Write-Host "Project map created: $path"
  return $path
}

function New-EvidenceIndex {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $path = Join-Path $Base ("EVIDENCE_INDEX\BALI_EVIDENCE_INDEX_V5_" + $stamp + ".md")
  $watchDirs = @("AI_HANDOVER_REPORTS", "STATUS_DASHBOARDS", "NEXT_PATCH_REPORTS", "PROJECT_MAPS", "SAFETY_REPORTS", "TEST_REPORTS", "RUN_REGISTRY")
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("# BALI EVIDENCE INDEX V5")
  $lines.Add("")
  $lines.Add("Generated: " + (Get-Date))
  $lines.Add("Mission: proof-driven crypto strategy research; no profitability claims without evidence.")
  $lines.Add("")
  foreach ($d in $watchDirs) {
    $dir = Join-Path $Base $d
    $lines.Add("## " + $d)
    if (Test-Path -LiteralPath $dir) {
      $files = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 30
      if ($files.Count -eq 0) { $lines.Add("- none") }
      foreach ($f in $files) { $lines.Add("- " + $f.Name + " | " + $f.LastWriteTime) }
    } else {
      $lines.Add("- folder missing")
    }
    $lines.Add("")
  }
  $lines.Add("## Required Future Evidence Fields")
  foreach ($x in @("run_id", "strategy_id", "dataset", "timeframe", "date_range", "fees", "slippage", "walk_forward_result", "out_of_sample_result", "drawdown", "profit_factor", "trade_count", "pass_fail", "rejection_reason")) {
    $lines.Add("- " + $x)
  }
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "EVIDENCE_INDEX.md") -Force
  Write-Host "Evidence index created: $path"
  return $path
}

function New-RunRegistry {
  Ensure-Dirs
  $registry = Join-Path $Base "RUN_REGISTRY\RUN_REGISTRY.csv"
  if (-not (Test-Path -LiteralPath $registry)) {
    "run_id,created_utc,type,status,source_file,summary,mission_alignment" | Set-Content -LiteralPath $registry -Encoding UTF8
  }
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $latestStatus = Get-LatestFile "STATUS_DASHBOARDS" "*.txt"
  $latestSafety = Get-LatestFile "SAFETY_REPORTS" "*.txt"
  $rows = @()
  if ($latestStatus) { $rows += ("SESSION_"+$stamp+",$(Get-Date -Format o),status_dashboard,PASS,"+$latestStatus.Name+",Generated automated status dashboard,Reporting and maintainability") }
  if ($latestSafety) { $rows += ("SAFETY_"+$stamp+",$(Get-Date -Format o),safety_scan,PASS,"+$latestSafety.Name+",Generated automated safety scan,Safety visibility") }
  if ($rows.Count -gt 0) { Add-Content -LiteralPath $registry -Value $rows -Encoding UTF8 }
  Write-Host "Run registry updated: $registry"
  return $registry
}

function New-Recommendation {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $git = Get-GitSummary
  $path = Join-Path $Base ("NEXT_PATCH_REPORTS\BALI_NEXT_PATCH_RECOMMENDATION_V5_" + $stamp + ".txt")
  $rec = "V6 Evidence Pack Registry + Backtest Run History Engine"
  $risk = "SAFE_TOOLING_ONLY"
  $why = "Creates a stronger proof database for future backtests, walk-forward tests, strategy scorecards, and rejection reasons before any trading logic changes."
  if (-not $git.Clean) {
    $rec = "Git Safe Save current generated reports before another patch"
    $risk = "SAFE_TOOLING_ONLY"
    $why = "The project has generated reports/changes that should be preserved before moving to the next patch."
  }
  $lines = @(
    "BALI NEXT PATCH RECOMMENDATION V5",
    "Generated: " + (Get-Date),
    "",
    "Recommended Next Patch: " + $rec,
    "Patch Class: " + $risk,
    "Why: " + $why,
    "",
    "MISSION FIT",
    "Improves automation, reporting, proof tracking, project control, and safe strategy discovery workflow.",
    "",
    "BLOCKED PATCHES",
    "- LIVE_TRADING",
    "- API_KEYS",
    "- CHAMPION_UNLOCK",
    "- PROFITABILITY_CLAIM_WITHOUT_EVIDENCE",
    "- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE",
    "",
    "OPERATOR DECISION",
    "Approve only if this keeps Bali paper/sim-first and improves proof, testing, reporting, strategy discovery, or maintainability."
  )
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "NEXT_PATCH_RECOMMENDATION_LATEST.txt") -Force
  Write-Host "Recommendation created: $path"
  return $path
}

function New-SessionReport {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $git = Get-GitSummary
  $latestStatus = Get-LatestFile "STATUS_DASHBOARDS" "*.txt"
  $latestRec = Get-LatestFile "NEXT_PATCH_REPORTS" "*.txt"
  $latestSafety = Get-LatestFile "SAFETY_REPORTS" "*.txt"
  $latestSafetyText = if ($latestSafety) { $latestSafety.Name } else { "none" }
  $latestStatusText = if ($latestStatus) { $latestStatus.Name } else { "none" }
  $latestRecText = if ($latestRec) { $latestRec.Name } else { "none" }
  $path = Join-Path $Base ("SESSION_REPORTS\BALI_SESSION_REPORT_V5_" + $stamp + ".txt")
  $lines = @(
    "BALI OS V5 AUTOMATED SESSION REPORT",
    "Generated: " + (Get-Date),
    "Base: " + $Base,
    "",
    "SESSION DASHBOARD",
    "Git: " + $git.Short,
    "Safety Report: " + $latestSafetyText,
    "Status Dashboard: " + $latestStatusText,
    "Recommendation: " + $latestRecText,
    "",
    "SEAMLESS WORKFLOW",
    "1. Run BALI_START_HERE.bat or BALI_MASTER_CONTROL option 1.",
    "2. Read the top dashboard and recommended next patch.",
    "3. Approve or reject the recommendation.",
    "4. Build only SAFE_TOOLING_ONLY / proof-first patches until evidence supports strategy changes.",
    "5. Test.",
    "6. Run Git Safe Save.",
    "7. Push to GitHub.",
    "",
    "NEXT STEP",
    "Use BALI_MASTER_CONTROL option 4 to view the next recommendation, or option 8 to save this session."
  )
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "BALI_SESSION_LATEST.txt") -Force
  Write-Host "Session report created: $path"
  return $path
}

function New-Handover {
  Ensure-Dirs
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $path = Join-Path $Base ("AI_HANDOVER_REPORTS\BALI_OS_V5_HANDOVER_" + $stamp + ".txt")
  $git = Get-GitSummary
  $status = Get-LatestFile "STATUS_DASHBOARDS" "*.txt"
  $rec = Get-LatestFile "NEXT_PATCH_REPORTS" "*.txt"
  $session = Get-LatestFile "SESSION_REPORTS" "*.txt"
  $safety = Get-LatestFile "SAFETY_REPORTS" "*.txt"
  $map = Get-LatestFile "PROJECT_MAPS" "*.md"
  $evidence = Get-LatestFile "EVIDENCE_INDEX" "*.md"
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("BALI OS V5 AI HANDOVER")
  $lines.Add("Generated: " + (Get-Date))
  $lines.Add("Base: " + $Base)
  $lines.Add("")
  $safetyText = if ($safety) { "SEE " + $safety.Name } else { "UNKNOWN" }
  $statusText = if ($status) { $status.Name } else { "none" }
  $recText = if ($rec) { $rec.Name } else { "none" }
  $sessionText = if ($session) { $session.Name } else { "none" }
  $lines.Add("FIRST PAGE DASHBOARD")
  $lines.Add("Version: " + (Get-VersionSummary))
  $lines.Add("Git: " + $git.Short)
  $lines.Add("Safety: " + $safetyText)
  $lines.Add("Latest Status: " + $statusText)
  $lines.Add("Recommended Next Patch: " + $recText)
  $lines.Add("Session Report: " + $sessionText)
  $lines.Add("")
  $lines.Add("MISSION")
  $lines.Add("Build Bali into a safe, proof-driven crypto strategy research machine that can hunt for evidence-backed strategies while preserving LIVE_ORDERS_OFF, NO_API_KEYS, PUBLIC_DATA_ONLY, PAPER/SIM FIRST, and CHAMPION_LOCKED.")
  $lines.Add("")
  $lines.Add("AUTOMATED EXPERIENCE RULE")
  $lines.Add("No manual file hunting or cut-and-paste where Bali OS can generate/open/copy the right report automatically.")
  $lines.Add("")
  $lines.Add("LATEST FILES")
  foreach ($f in @($status,$rec,$session,$safety,$map,$evidence)) { if ($f) { $lines.Add("- " + $f.FullName) } }
  $lines.Add("")
  $lines.Add("CONSTITUTION EXCERPT")
  foreach ($item in @(Read-ShortFile "CONSTITUTION.md" 40)) { $lines.Add([string]$item) }
  $lines.Add("")
  $lines.Add("NEXT PATCH EXCERPT")
  foreach ($item in @(Read-ShortFile "NEXT_PATCH.md" 60)) { $lines.Add([string]$item) }
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
  Copy-Item -LiteralPath $path -Destination (Join-Path $Base "LATEST_CHAT_HANDOVER.txt") -Force
  try { Get-Content -LiteralPath $path -Raw | Set-Clipboard } catch {}
  Write-Host "Handover created: $path"
  Write-Host "Latest handover copied to: LATEST_CHAT_HANDOVER.txt"
  Write-Host "Clipboard copy attempted."
  return $path
}

function Start-Session {
  Ensure-Dirs
  $scanScript = Join-Path $Base "tools\BALI_OS_SAFETY_SCAN_V5.ps1"
  if (Test-Path -LiteralPath $scanScript) { & $scanScript -Base $Base -WriteReport | Out-Null }
  $status = New-StatusDashboard
  $rec = New-Recommendation
  $map = New-ProjectMap
  $evidence = New-EvidenceIndex
  $registry = New-RunRegistry
  $session = New-SessionReport
  $handover = New-Handover
  Write-Host ""
  Write-Host "PASS - Bali OS V5 automated session complete." -ForegroundColor Green
  Write-Host "NEXT: Review recommendation, then use option 8 to safe-save generated reports."
}

Ensure-Dirs
switch ($Action.ToLowerInvariant()) {
  "session" { Start-Session }
  "status" { New-StatusDashboard | Out-Null }
  "recommend" { New-Recommendation | Out-Null }
  "map" { New-ProjectMap | Out-Null }
  "evidence" { New-EvidenceIndex | Out-Null }
  "registry" { New-RunRegistry | Out-Null }
  "handover" { New-Handover | Out-Null }
  default { throw "Unknown action: $Action" }
}

