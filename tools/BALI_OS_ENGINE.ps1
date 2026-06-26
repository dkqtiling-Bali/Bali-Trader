param(
    [ValidateSet("FullAuto","ConciseHandover","FullHandover","RecommendNextPatch","SafetyScan","ProjectMap","EvidenceIndex","GitSafeSave","OpenConstitution","OpenLatestReport","OpenLedger","OpenNextPatch")]
    [string]$Action = "FullAuto"
)

$ErrorActionPreference = "SilentlyContinue"
$Script:Base = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Script:Base

function Ensure-Dir($Name) {
    $path = Join-Path $Script:Base $Name
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    return $path
}

function Read-Text($Rel, $Max = 20000) {
    $path = Join-Path $Script:Base $Rel
    if (Test-Path $path) {
        $txt = Get-Content -Path $path -Raw
        if ($txt.Length -gt $Max) { return $txt.Substring(0, $Max) + "`n...[TRUNCATED]..." }
        return $txt
    }
    return "MISSING: $Rel"
}

function Get-VersionSummary {
    $manifest = Join-Path $Script:Base "update_manifest.json"
    if (Test-Path $manifest) {
        try {
            $json = Get-Content $manifest -Raw | ConvertFrom-Json
            return "$($json.version) $($json.name)"
        } catch { return "Manifest unreadable" }
    }
    return "Unknown"
}

function Get-GitSummary {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { return "Git unavailable" }
    $status = git status --short 2>$null
    if (-not $status) { return "Clean" }
    return "DIRTY: " + (($status | Select-Object -First 12) -join "; ")
}

function Get-LatestFile($Dirs, $Patterns) {
    $items = @()
    foreach ($d in $Dirs) {
        $dir = Join-Path $Script:Base $d
        if (Test-Path $dir) {
            foreach ($p in $Patterns) {
                $items += Get-ChildItem -Path $dir -Filter $p -File -Recurse -ErrorAction SilentlyContinue
            }
        }
    }
    if ($items.Count -eq 0) { return $null }
    return ($items | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
}

function Test-SafetyLocks {
    $result = [ordered]@{
        LiveOrdersOff = "UNKNOWN"
        NoApiKeys = "UNKNOWN"
        PublicDataOnly = "UNKNOWN"
        ChampionLocked = "UNKNOWN"
        PaperSimFirst = "UNKNOWN"
        Verdict = "WARN"
        Notes = @()
    }

    $safeText = ""
    foreach ($rel in @("MISSION.md","AI_RULES.md","CONSTITUTION.md","LEDGER.md","NEXT_PATCH.md")) {
        $path = Join-Path $Script:Base $rel
        if (Test-Path $path) { $safeText += "`n" + (Get-Content $path -Raw) }
    }

    if ($safeText -match "LIVE_ORDERS_OFF") { $result.LiveOrdersOff = "PASS" }
    if ($safeText -match "NO_API_KEYS") { $result.NoApiKeys = "PASS" }
    if ($safeText -match "PUBLIC_DATA_ONLY") { $result.PublicDataOnly = "PASS" }
    if ($safeText -match "CHAMPION_LOCKED|CHAMPION_LOCK_LOCKED") { $result.ChampionLocked = "PASS" }
    if ($safeText -match "PAPER/SIM FIRST|PAPER/SIM|simulation-first") { $result.PaperSimFirst = "PASS" }

    $dangerHits = @()
    $scanFiles = Get-ChildItem -Path $Script:Base -Include *.py,*.ps1,*.bat,*.md,*.json -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notmatch "\\.git\\" -and $_.FullName -notmatch "INSTALL_BACKUPS"
    }
    foreach ($f in $scanFiles) {
        $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "LIVE_ORDERS_ON|enable_live|live_trading\s*=\s*true|api_secret|private_key|CHAMPION_UNLOCKED") {
            $dangerHits += $f.FullName.Replace($Script:Base + "\", "")
        }
    }

    if ($dangerHits.Count -gt 0) {
        $result.Verdict = "BLOCKED"
        $result.Notes += "Danger keywords found: " + ($dangerHits -join ", ")
    } elseif ($result.LiveOrdersOff -eq "PASS" -and $result.NoApiKeys -eq "PASS" -and $result.ChampionLocked -eq "PASS") {
        $result.Verdict = "PASS"
        $result.Notes += "Core safety locks visible."
    } else {
        $result.Verdict = "WARN"
        $result.Notes += "Some safety locks were not found in scanned docs."
    }
    return $result
}

function Write-StatusDashboard {
    $dir = Ensure-Dir "STATUS_DASHBOARDS"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_STATUS_$stamp.txt"
    $safety = Test-SafetyLocks
    $git = Get-GitSummary
    $version = Get-VersionSummary
    $latest = Get-LatestFile @("AI_HANDOVER_REPORTS","INSTALL_REPORTS","SAFETY_REPORTS","PROJECT_MAPS","Reports","reports") @("*.txt","*.md")
    $latestText = if ($latest) { $latest.FullName.Replace($Script:Base + "\", "") } else { "None found" }
    $issues = 0
    if ($git -match "DIRTY") { $issues++ }
    if ($safety.Verdict -ne "PASS") { $issues++ }
    $readiness = 100
    if ($git -match "DIRTY") { $readiness -= 10 }
    if ($safety.Verdict -eq "WARN") { $readiness -= 10 }
    if ($safety.Verdict -eq "BLOCKED") { $readiness -= 50 }
    if (-not $latest) { $readiness -= 5 }
    if ($readiness -lt 0) { $readiness = 0 }

    $next = "V5 Evidence Pack Index + Backtest Run Registry"
    if ($safety.Verdict -ne "PASS") { $next = "Fix safety visibility issue before any new patch" }
    elseif ($git -match "DIRTY") { $next = "Safe Git Save / Backup current V4 install" }

    @"
BALI STATUS

Version: $version
Git: $git
Safety: $($safety.Verdict)
Health: $($safety.Verdict)
Latest Report: $latestText
Mission: Active
Champion Lock: $($safety.ChampionLocked)
Paper/Sim: $($safety.PaperSimFirst)
Outstanding Issues: $issues
Recommended Next Patch: $next
Overall Readiness: $readiness%

Safety Detail:
- LIVE_ORDERS_OFF: $($safety.LiveOrdersOff)
- NO_API_KEYS: $($safety.NoApiKeys)
- PUBLIC_DATA_ONLY: $($safety.PublicDataOnly)
- CHAMPION_LOCKED: $($safety.ChampionLocked)
- PAPER/SIM FIRST: $($safety.PaperSimFirst)

Mission Alignment:
Bali OS improves maintainability, safety visibility, reporting, patch discipline, AI alignment, and future evidence-backed strategy discovery.
"@ | Set-Content -Path $path -Encoding UTF8
    Write-Host "Status dashboard created: $path"
    return $path
}

function Generate-ProjectMap {
    $dir = Ensure-Dir "PROJECT_MAPS"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_PROJECT_MAP_$stamp.md"

    $all = Get-ChildItem -Path $Script:Base -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.FullName -notmatch "\\.git\\" -and $_.FullName -notmatch "INSTALL_BACKUPS"
    }
    $launchers = $all | Where-Object { $_.Extension -eq ".bat" } | Sort-Object FullName
    $tools = $all | Where-Object { $_.FullName -match "\\tools\\" } | Sort-Object FullName
    $reports = $all | Where-Object { $_.FullName -match "REPORT|REPORTS|AI_HANDOVER|PROJECT_MAP|STATUS_DASHBOARD|EVIDENCE" } | Sort-Object LastWriteTime -Descending | Select-Object -First 80
    $py = $all | Where-Object { $_.Extension -eq ".py" } | Sort-Object FullName
    $dupeGroups = $all | Group-Object Name | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending | Select-Object -First 30

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# BALI PROJECT MAP")
    $lines.Add("")
    $lines.Add("Generated: $(Get-Date)")
    $lines.Add("Base: $Script:Base")
    $lines.Add("")
    $lines.Add("## Major Launchers")
    foreach ($f in $launchers) { $lines.Add("- " + $f.FullName.Replace($Script:Base + "\", "")) }
    $lines.Add("")
    $lines.Add("## Tools")
    foreach ($f in $tools | Select-Object -First 120) { $lines.Add("- " + $f.FullName.Replace($Script:Base + "\", "")) }
    $lines.Add("")
    $lines.Add("## Python / App Files")
    foreach ($f in $py | Select-Object -First 120) { $lines.Add("- " + $f.FullName.Replace($Script:Base + "\", "")) }
    $lines.Add("")
    $lines.Add("## Latest Reports / Evidence-Like Files")
    foreach ($f in $reports) { $lines.Add("- " + $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") + " - " + $f.FullName.Replace($Script:Base + "\", "")) }
    $lines.Add("")
    $lines.Add("## Duplicate Filename Candidates")
    if ($dupeGroups.Count -eq 0) { $lines.Add("- None detected by filename.") }
    foreach ($g in $dupeGroups) {
        $lines.Add("- $($g.Name) appears $($g.Count) times")
        foreach ($item in $g.Group | Select-Object -First 6) { $lines.Add("  - " + $item.FullName.Replace($Script:Base + "\", "")) }
    }
    $lines.Add("")
    $lines.Add("## Archive Recommendations")
    $lines.Add("- Do not delete anything automatically.")
    $lines.Add("- Archive only after human approval.")
    $lines.Add("- Prioritise old duplicate launchers, stale reports, and superseded install bundles.")
    $lines.Add("- Never archive LEDGER.md, MISSION.md, NEXT_PATCH.md, CONSTITUTION.md, update_manifest.json, app.py, tools currently used by Master Control, or latest reports.")

    $lines | Set-Content -Path $path -Encoding UTF8
    Copy-Item -Path $path -Destination (Join-Path $Script:Base "PROJECT_MAP.md") -Force
    Write-Host "Project map created: $path"
    return $path
}

function Generate-EvidenceIndex {
    $dir = Ensure-Dir "EVIDENCE_INDEX"
    Ensure-Dir "EVIDENCE_PACKS" | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_EVIDENCE_INDEX_$stamp.md"
    $patterns = @("*backtest*","*walk*forward*","*scoreboard*","*raw*data*","*safety*","*handover*","*report*","*result*","*paper*","*sim*")
    $items = @()
    foreach ($p in $patterns) {
        $items += Get-ChildItem -Path $Script:Base -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -like $p -and $_.FullName -notmatch "\\.git\\" -and $_.FullName -notmatch "INSTALL_BACKUPS"
        }
    }
    $items = $items | Sort-Object FullName -Unique | Sort-Object LastWriteTime -Descending
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# BALI EVIDENCE INDEX")
    $lines.Add("")
    $lines.Add("Generated: $(Get-Date)")
    $lines.Add("Base: $Script:Base")
    $lines.Add("")
    $lines.Add("## Purpose")
    $lines.Add("This index helps Bali find, compare, and prove strategy research evidence before any trading logic or champion decision.")
    $lines.Add("")
    $lines.Add("## Safety")
    $lines.Add("- LIVE_ORDERS_OFF")
    $lines.Add("- NO_API_KEYS")
    $lines.Add("- PUBLIC_DATA_ONLY")
    $lines.Add("- PAPER/SIM FIRST")
    $lines.Add("- CHAMPION_LOCKED")
    $lines.Add("")
    $lines.Add("## Evidence-Like Files Found")
    if ($items.Count -eq 0) { $lines.Add("- No evidence-like files found yet.") }
    foreach ($f in $items | Select-Object -First 300) {
        $rel = $f.FullName.Replace($Script:Base + "\", "")
        $lines.Add("- $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) | $rel | $([math]::Round($f.Length/1KB,2)) KB")
    }
    $lines.Add("")
    $lines.Add("## Next Evidence Upgrade Needed")
    $lines.Add("V5 should create a structured Backtest Run Registry with run IDs, dataset IDs, fees, slippage, in-sample, walk-forward, out-of-sample, drawdown, profit factor, trade count, and pass/fail reason.")
    $lines | Set-Content -Path $path -Encoding UTF8
    Copy-Item -Path $path -Destination (Join-Path $Script:Base "EVIDENCE_INDEX.md") -Force
    Write-Host "Evidence index created: $path"
    return $path
}

function Generate-Recommendation {
    $dir = Ensure-Dir "NEXT_PATCH_REPORTS"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_NEXT_PATCH_RECOMMENDATION_$stamp.txt"
    $safety = Test-SafetyLocks
    $git = Get-GitSummary
    $rec = "V5 Evidence Pack Index + Backtest Run Registry"
    $risk = "LOW"
    $class = "SAFE_TOOLING_ONLY"
    $why = "Before changing strategy logic, Bali must make every backtest, walk-forward result, raw-data gate result, safety scan, scoreboard output, and paper/sim result easy to find, compare, and prove."
    if ($safety.Verdict -ne "PASS") {
        $rec = "Fix safety visibility issue before any new patch"
        $risk = "MEDIUM"
        $class = "SAFETY_FIX_ONLY"
        $why = "Safety locks must be visible and passing before any new project expansion."
    } elseif ($git -match "DIRTY") {
        $rec = "Git Safe Save / Backup current Bali OS install"
        $risk = "LOW"
        $class = "SAFE_TOOLING_ONLY"
        $why = "Preserve the current good state before adding more automation or research modules."
    }
    @"
BALI NEXT PATCH RECOMMENDATION
Generated: $(Get-Date)

Recommended next patch: $rec
Risk: $risk
Patch class: $class
Safety: $($safety.Verdict)
Git: $git

Why:
$why

Mission fit:
This recommendation supports the mission by improving safety, proof, reporting, maintainability, or evidence-backed strategy discovery while preserving paper/simulation-first testing.

Blocked patch types:
- LIVE_TRADING
- API_KEYS
- CHAMPION_UNLOCK
- PROFIT_CLAIM_WITHOUT_PROOF
- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE
"@ | Set-Content -Path $path -Encoding UTF8
    Write-Host "Recommendation created: $path"
    return $path
}

function Generate-SafetyReport {
    $dir = Ensure-Dir "SAFETY_REPORTS"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_SAFETY_SCAN_$stamp.txt"
    $s = Test-SafetyLocks
    @"
BALI SAFETY SCAN
Generated: $(Get-Date)

Verdict: $($s.Verdict)

Locks:
- LIVE_ORDERS_OFF: $($s.LiveOrdersOff)
- NO_API_KEYS: $($s.NoApiKeys)
- PUBLIC_DATA_ONLY: $($s.PublicDataOnly)
- CHAMPION_LOCKED: $($s.ChampionLocked)
- PAPER/SIM FIRST: $($s.PaperSimFirst)

Notes:
$($s.Notes -join "`n")

Result:
No live trading, API key, champion unlock, or strategy-risk patch should proceed unless safety verdict is PASS.
"@ | Set-Content -Path $path -Encoding UTF8
    Write-Host "Safety scan created: $path"
    return $path
}

function Generate-Handover($Full = $false) {
    $dir = Ensure-Dir "AI_HANDOVER_REPORTS"
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $mode = if ($Full) { "FULL" } else { "CONCISE" }
    $path = Join-Path $dir "BALI_OS_V4_${mode}_HANDOVER_$stamp.txt"
    $status = Write-StatusDashboard
    $safety = Test-SafetyLocks
    $rec = Generate-Recommendation
    $map = Generate-ProjectMap
    $evidence = Generate-EvidenceIndex
    $git = Get-GitSummary

    $content = @"
BALI OS V4 $mode AI HANDOVER
Generated: $(Get-Date)
Path: $Script:Base

==================== FIRST PAGE DASHBOARD ====================
$(Get-Content $status -Raw)

==================== RECOMMENDED NEXT ACTION ====================
$(Get-Content $rec -Raw)

==================== OPERATING WORKFLOW ====================
Open VS Code
Run BALI_MASTER_CONTROL.bat
Analyse Project
AI recommends highest-value next task
Approve or reject
Generate safe patch
Test
Commit
Push to GitHub

==================== SAFETY RULES ====================
- LIVE_ORDERS_OFF
- NO_API_KEYS
- PUBLIC_DATA_ONLY
- PAPER/SIM FIRST
- CHAMPION_LOCKED until proof gates pass
- NO profitability claims without evidence
- Every patch must improve proof, safety, testing, reporting, strategy discovery, or maintainability.

==================== MISSION ====================
$(Read-Text "CONSTITUTION.md" 12000)
"@
    if ($Full) {
        $content += @"

==================== LEDGER ====================
$(Read-Text "LEDGER.md" 20000)

==================== NEXT PATCH ====================
$(Read-Text "NEXT_PATCH.md" 16000)

==================== PROJECT MAP SUMMARY ====================
Project map file: $map

$(Get-Content $map -Raw)

==================== EVIDENCE INDEX SUMMARY ====================
Evidence index file: $evidence

$(Get-Content $evidence -Raw)

==================== GIT STATUS ====================
$git

==================== DEFINITION OF DONE ====================
$(Read-Text "DEFINITION_OF_DONE.md" 12000)

==================== PATCH APPROVAL RULES ====================
$(Read-Text "PATCH_APPROVAL_RULES.md" 12000)
"@
    }
    $content | Set-Content -Path $path -Encoding UTF8
    Copy-Item -Path $path -Destination (Join-Path $Script:Base "LATEST_CHAT_HANDOVER.txt") -Force
    try { Get-Content (Join-Path $Script:Base "LATEST_CHAT_HANDOVER.txt") -Raw | clip.exe } catch {}
    Write-Host "Handover created: $path"
    Write-Host "Latest handover copied to: LATEST_CHAT_HANDOVER.txt"
    Write-Host "Clipboard copy attempted."
    return $path
}

function Git-SafeSave {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { Write-Host "Git not found. Cannot save."; return }
    $safety = Test-SafetyLocks
    if ($safety.Verdict -eq "BLOCKED") {
        Write-Host "BLOCKED: Safety scan found danger keywords. Review SAFETY_REPORTS first."
        Generate-SafetyReport | Out-Null
        return
    }
    Write-Host "Current git status:"
    git status --short
    Write-Host ""
    Write-Host "This save stages safe docs/tooling/report files only. It avoids app.py and common secret/key files."
    $changed = git status --short
    $blocked = $changed | Where-Object { $_ -match "app.py|secret|key|credential|\.env|token" }
    if ($blocked) {
        Write-Host "WARNING: Potentially sensitive or trading-logic files are changed and will NOT be staged automatically:"
        $blocked | ForEach-Object { Write-Host $_ }
    }
    $approval = Read-Host "Type SAVE to stage safe files, commit, and push"
    if ($approval -ne "SAVE") { Write-Host "Git save cancelled."; return }

    $safePaths = @(
        "LEDGER.md", "NEXT_PATCH.md", "MISSION.md", "AI_RULES.md", "CONSTITUTION.md", "BALI_OS_WORKFLOW.md", "DEFINITION_OF_DONE.md", "EVIDENCE_STANDARDS.md", "PATCH_APPROVAL_RULES.md", "AI_ENGINEER_QUEUE.md", "PROJECT_MAP.md", "EVIDENCE_INDEX.md", "LATEST_CHAT_HANDOVER.txt",
        "BALI_MASTER_CONTROL.bat", "BALI_SAFE_GIT_SAVE.bat", "BALI_AI_HQ_V1.bat", "BALI_AI_HQ_V2.bat", "BALI_AI_HQ_V3.bat",
        "tools", "docs", "AI_HANDOVER_REPORTS", "INSTALL_REPORTS", "PROJECT_MAPS", "SAFETY_REPORTS", "STATUS_DASHBOARDS", "NEXT_PATCH_REPORTS", "EVIDENCE_INDEX", "EVIDENCE_PACKS"
    )
    foreach ($p in $safePaths) {
        if (Test-Path (Join-Path $Script:Base $p)) { git add -- $p }
    }
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "Bali OS safe tooling snapshot $stamp"
    if ($LASTEXITCODE -ne 0) { Write-Host "Nothing committed or commit failed. Check git output above."; return }
    git push
    Write-Host "Git safe save complete."
}

function Open-LatestReport {
    $latest = Get-LatestFile @("AI_HANDOVER_REPORTS","STATUS_DASHBOARDS","NEXT_PATCH_REPORTS","SAFETY_REPORTS","PROJECT_MAPS","EVIDENCE_INDEX","INSTALL_REPORTS") @("*.txt","*.md")
    if ($latest) { Start-Process notepad.exe $latest.FullName; Write-Host "Opened: $($latest.FullName)" } else { Write-Host "No report found." }
}

function Open-FileIfExists($Rel) {
    $path = Join-Path $Script:Base $Rel
    if (Test-Path $path) { Start-Process notepad.exe $path; Write-Host "Opened: $path" } else { Write-Host "Missing: $path" }
}

switch ($Action) {
    "FullAuto" {
        Write-Host "Running full auto Bali OS analysis..."
        Generate-SafetyReport | Out-Null
        Generate-Handover -Full $true | Out-Null
        Write-Host "Full auto analysis complete. Use option 8 to safe-save when ready."
    }
    "ConciseHandover" { Generate-Handover -Full $false | Out-Null }
    "FullHandover" { Generate-Handover -Full $true | Out-Null }
    "RecommendNextPatch" { Generate-Recommendation | Out-Null }
    "SafetyScan" { Generate-SafetyReport | Out-Null }
    "ProjectMap" { Generate-ProjectMap | Out-Null }
    "EvidenceIndex" { Generate-EvidenceIndex | Out-Null }
    "GitSafeSave" { Git-SafeSave }
    "OpenConstitution" { Open-FileIfExists "CONSTITUTION.md" }
    "OpenLatestReport" { Open-LatestReport }
    "OpenLedger" { Open-FileIfExists "LEDGER.md" }
    "OpenNextPatch" { Open-FileIfExists "NEXT_PATCH.md" }
}
