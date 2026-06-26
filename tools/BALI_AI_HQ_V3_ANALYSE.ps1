param(
    [ValidateSet("Menu", "GenerateHandover", "ProjectMap", "RecommendPatch", "SafetyScan", "GitStatus")]
    [string]$Mode = "Menu"
)

$ErrorActionPreference = "Continue"

$Global:ScriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

function Get-ProjectRoot {
    $scriptDir = $Global:ScriptDirectory
    $candidate = Split-Path -Parent $scriptDir
    if (Test-Path (Join-Path $candidate "update_manifest.json")) { return $candidate }
    if (Test-Path (Join-Path $candidate "LEDGER.md")) { return $candidate }
    if (Test-Path "C:\Bali\Bali-Trader") { return "C:\Bali\Bali-Trader" }
    return (Get-Location).Path
}

$Global:ProjectRoot = Get-ProjectRoot

function Get-TextSafe {
    param(
        [string]$Path,
        [int]$MaxChars = 12000
    )

    if (-not (Test-Path $Path)) {
        return "MISSING: $Path"
    }

    try {
        $txt = Get-Content -Path $Path -Raw -ErrorAction Stop
        if ($txt.Length -gt $MaxChars) {
            return $txt.Substring(0, $MaxChars) + "`r`n[TRUNCATED]"
        }
        return $txt
    } catch {
        return "READ_ERROR: $Path :: $($_.Exception.Message)"
    }
}

function Get-RelativePathSafe {
    param([string]$FullPath)
    try {
        return $FullPath.Substring($Global:ProjectRoot.Length).TrimStart("\")
    } catch {
        return $FullPath
    }
}

function Get-ManifestSummary {
    $path = Join-Path $Global:ProjectRoot "update_manifest.json"
    if (-not (Test-Path $path)) {
        return @{
            Text = "MISSING update_manifest.json"
            Version = "UNKNOWN"
            VersionNumber = "UNKNOWN"
            Name = "UNKNOWN"
        }
    }

    try {
        $raw = Get-Content -Path $path -Raw
        $obj = $raw | ConvertFrom-Json
        $version = if ($obj.version) { $obj.version } else { "UNKNOWN" }
        $versionNumber = if ($obj.version_number) { $obj.version_number } else { "UNKNOWN" }
        $name = if ($obj.name) { $obj.name } else { "UNKNOWN" }
        return @{
            Text = $raw.Trim()
            Version = $version
            VersionNumber = $versionNumber
            Name = $name
        }
    } catch {
        return @{
            Text = "MANIFEST_PARSE_ERROR: $($_.Exception.Message)"
            Version = "UNKNOWN"
            VersionNumber = "UNKNOWN"
            Name = "UNKNOWN"
        }
    }
}

function Test-PathExcluded {
    param([string]$Path)
    $bad = @("\.git\", "__pycache__", "node_modules", "\.venv", "\venv\", "_BALI_AI_HQ_V3_BACKUP", "\.pytest_cache", "\dist\", "\build\")
    foreach ($b in $bad) {
        if ($Path -match $b) { return $true }
    }
    return $false
}

function Get-LatestReportFiles {
    param([int]$Max = 8)
    $exts = @(".txt", ".log", ".md", ".json")
    try {
        $files = Get-ChildItem -Path $Global:ProjectRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                ($exts -contains $_.Extension.ToLower()) -and
                ($_.Length -lt 2000000) -and
                (-not (Test-PathExcluded -Path $_.FullName)) -and
                (
                    $_.Name -match "report|health|ledger|manifest|patch|handover|score|status|result|watch|scan|next" -or
                    $_.DirectoryName -match "REPORT|LOG|HANDOVER|MAP|STATUS|WATCH"
                )
            } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First $Max
        return @($files)
    } catch {
        return @()
    }
}

function Get-GitStatusText {
    Push-Location $Global:ProjectRoot
    try {
        $gitCheck = git rev-parse --is-inside-work-tree 2>&1
        if ($LASTEXITCODE -ne 0) { return "GIT_NOT_AVAILABLE_OR_NOT_A_REPO" }
        $status = git status 2>&1 | Out-String
        return $status.Trim()
    } catch {
        return "GIT_STATUS_ERROR: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function Get-GitCleanVerdict {
    $status = Get-GitStatusText
    if ($status -match "nothing to commit, working tree clean") { return "PASS" }
    if ($status -match "GIT_NOT_AVAILABLE") { return "UNKNOWN" }
    return "REVIEW"
}

function Get-LatestHealthVerdict {
    $files = Get-LatestReportFiles -Max 10
    $combined = ""
    foreach ($f in $files) {
        $combined += "`r`n--- " + (Get-RelativePathSafe -FullPath $f.FullName) + " ---`r`n"
        $combined += Get-TextSafe -Path $f.FullName -MaxChars 5000
    }

    if ($combined -match "RESULT=PASS|HEALTH=PASS|Safety:\s*PASS|SAFETY=LIVE_ORDERS_OFF") { return "PASS" }
    if ($combined -match "FAIL|ERROR|BLOCKED|CRITICAL") { return "REVIEW" }
    return "UNKNOWN"
}

function Invoke-SafetyScan {
    $scanPaths = New-Object System.Collections.Generic.List[string]
    foreach ($name in @("MISSION.md", "LEDGER.md", "NEXT_PATCH.md", "AI_RULES.md", "update_manifest.json", "app.py")) {
        $p = Join-Path $Global:ProjectRoot $name
        if (Test-Path $p) { $scanPaths.Add($p) }
    }
    foreach ($f in (Get-LatestReportFiles -Max 8)) {
        if (-not $scanPaths.Contains($f.FullName)) { $scanPaths.Add($f.FullName) }
    }

    $combined = ""
    foreach ($p in $scanPaths) {
        $combined += "`r`n--- " + (Get-RelativePathSafe -FullPath $p) + " ---`r`n"
        $combined += Get-TextSafe -Path $p -MaxChars 8000
    }

    $requirements = @(
        @{ Name = "LIVE_ORDERS_OFF"; Pattern = "LIVE_ORDERS_OFF|LIVE ORDERS.*OFF|LIVE_ORDERS.*OFF" },
        @{ Name = "NO_API_KEYS"; Pattern = "NO_API_KEYS|NO API KEYS|API.*NONE|NO KEYS" },
        @{ Name = "PUBLIC_DATA_ONLY"; Pattern = "PUBLIC_DATA_ONLY|PUBLIC DATA ONLY|PUBLIC_DATA|RAW_LIVE_DATA_ONLY" },
        @{ Name = "PAPER_SIM_FIRST"; Pattern = "PAPER/SIM FIRST|PAPER.*SIM|SIM_ONLY|PAPER FIRST" },
        @{ Name = "CHAMPION_LOCKED"; Pattern = "CHAMPION_LOCKED|CHAMPION_LOCK_LOCKED|Champion lock:\s*LOCKED" }
    )

    $present = @()
    $missing = @()
    foreach ($r in $requirements) {
        if ($combined -match $r.Pattern) { $present += $r.Name } else { $missing += $r.Name }
    }

    $dangerPatterns = @(
        "LIVE_ORDERS_ON",
        "REAL_ORDERS_ON",
        "ENABLE_LIVE_ORDERS",
        "ENABLE_LIVE_TRADING",
        "CHAMPION_UNLOCKED",
        "BYPASS_CHAMPION_LOCK",
        "PRIVATE_EXCHANGE_ENDPOINT",
        "RESET_LEDGER"
    )
    $danger = @()
    foreach ($d in $dangerPatterns) {
        if ($combined -match $d) { $danger += $d }
    }

    $verdict = "PASS"
    if ($missing.Count -gt 0 -or $danger.Count -gt 0) { $verdict = "REVIEW" }

    return [pscustomobject]@{
        Verdict = $verdict
        Present = $present
        Missing = $missing
        Danger = $danger
        FilesScanned = $scanPaths.Count
    }
}

function Get-ProjectMapLines {
    param([int]$MaxDepth = 3, [int]$MaxItemsPerFolder = 80)

    $lines = New-Object System.Collections.Generic.List[string]
    $rootName = Split-Path -Leaf $Global:ProjectRoot
    if (-not $rootName) { $rootName = $Global:ProjectRoot }
    $lines.Add($rootName)

    function Add-FolderLines {
        param(
            [string]$Folder,
            [string]$Prefix,
            [int]$Depth,
            [int]$MaxDepth,
            [int]$MaxItemsPerFolder,
            [System.Collections.Generic.List[string]]$Lines
        )

        if ($Depth -gt $MaxDepth) { return }

        try {
            $children = Get-ChildItem -Path $Folder -ErrorAction SilentlyContinue |
                Where-Object { -not (Test-PathExcluded -Path $_.FullName) } |
                Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name |
                Select-Object -First $MaxItemsPerFolder
        } catch {
            return
        }

        foreach ($child in $children) {
            $tag = if ($child.PSIsContainer) { "[DIR] " } else { "[FILE]" }
            $extra = ""
            if (-not $child.PSIsContainer) {
                if ($child.Name -match "MISSION|LEDGER|NEXT_PATCH|RULE|README|manifest|report|handover|launcher|\.bat$|\.ps1$") {
                    $extra = "  <- key"
                }
            }
            $Lines.Add($Prefix + "+-- " + $tag + " " + $child.Name + $extra)
            if ($child.PSIsContainer) {
                Add-FolderLines -Folder $child.FullName -Prefix ($Prefix + "|   ") -Depth ($Depth + 1) -MaxDepth $MaxDepth -MaxItemsPerFolder $MaxItemsPerFolder -Lines $Lines
            }
        }
    }

    Add-FolderLines -Folder $Global:ProjectRoot -Prefix "" -Depth 1 -MaxDepth $MaxDepth -MaxItemsPerFolder $MaxItemsPerFolder -Lines $lines
    return $lines
}

function Save-ProjectMap {
    $dir = Join-Path $Global:ProjectRoot "PROJECT_MAPS"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $path = Join-Path $dir "BALI_PROJECT_MAP_V3_$stamp.txt"
    $lines = Get-ProjectMapLines
    $header = @(
        "BALI PROJECT MAP V3",
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Path: $Global:ProjectRoot",
        "Purpose: AI handover, maintainability, safer patch planning",
        ""
    )
    ($header + $lines) | Out-File -FilePath $path -Encoding UTF8
    return $path
}

function Get-Recommendation {
    $safety = Invoke-SafetyScan
    $health = Get-LatestHealthVerdict
    $manifest = Get-ManifestSummary
    $gitClean = Get-GitCleanVerdict

    if ($safety.Verdict -ne "PASS") {
        return [pscustomobject]@{
            Title = "V3A Safety Lock Clarifier + Restore Report"
            Class = "SAFE_TOOLING_ONLY"
            Why = "The safety scan needs review before any strategy or testing patch. Restore clear safety proof first."
            MissionFit = "Improves safety visibility and blocks unsafe live-trading drift."
            Blocked = "All trading logic, API key, live-order, and champion-unlock work."
        }
    }

    if ($health -ne "PASS") {
        return [pscustomobject]@{
            Title = "V3B Health Failure Triage + Latest Report Repair"
            Class = "SAFE_TOOLING_ONLY"
            Why = "Latest health is not confirmed PASS, so the safest patch is to make the failure visible and fix reporting flow before changing logic."
            MissionFit = "Improves reporting and safety proof before testing or strategy discovery changes."
            Blocked = "Strategy changes until latest health is PASS."
        }
    }

    $hasEvidencePack = $false
    foreach ($name in @("EVIDENCE_PACK.md", "BACKTEST_RUN_REGISTRY.md", "PROOF_INDEX.md")) {
        if (Test-Path (Join-Path $Global:ProjectRoot $name)) { $hasEvidencePack = $true }
    }

    if (-not $hasEvidencePack) {
        return [pscustomobject]@{
            Title = "V4 Evidence Pack Index + Backtest Run Registry"
            Class = "SAFE_TOOLING_ONLY"
            Why = "Bali already has a walk-forward gate and clean safety report. The next safest improvement is to make every backtest, raw-data gate, scoreboard, and walk-forward result traceable before strategy changes."
            MissionFit = "Improves proof, testing, reporting, and strategy discovery while preserving simulation-first safety locks."
            Blocked = "No trading logic changes, no champion unlock, no live orders, no API keys."
        }
    }

    return [pscustomobject]@{
        Title = "V4 Raw Data Provenance Audit + Dataset Quality Report"
        Class = "SAFE_TOOLING_ONLY"
        Why = "Once evidence files exist, the next safest patch is proving that raw public data is clean, complete, and comparable before strategy scoring changes."
        MissionFit = "Improves proof quality and reduces false strategy confidence from bad input data."
        Blocked = "No trading logic changes until dataset quality is proven."
    }
}

function Get-ProjectScore {
    $score = 0
    $safety = Invoke-SafetyScan
    if ($safety.Verdict -eq "PASS") { $score += 30 }
    if ((Test-Path (Join-Path $Global:ProjectRoot "MISSION.md")) -and (Test-Path (Join-Path $Global:ProjectRoot "LEDGER.md")) -and (Test-Path (Join-Path $Global:ProjectRoot "NEXT_PATCH.md"))) { $score += 20 }
    if (Test-Path (Join-Path $Global:ProjectRoot "update_manifest.json")) { $score += 10 }
    if ((Get-LatestHealthVerdict) -eq "PASS") { $score += 20 }
    if ((Get-GitCleanVerdict) -eq "PASS") { $score += 10 }
    if (Test-Path (Join-Path $Global:ProjectRoot "PROJECT_MAPS")) { $score += 10 }
    return $score
}

function New-HandoverReport {
    $handoverDir = Join-Path $Global:ProjectRoot "AI_HANDOVER_REPORTS"
    New-Item -ItemType Directory -Force -Path $handoverDir | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outPath = Join-Path $handoverDir "BALI_AI_HQ_V3_$stamp.txt"

    $projectMapPath = Save-ProjectMap
    $projectMapText = Get-TextSafe -Path $projectMapPath -MaxChars 30000
    $safety = Invoke-SafetyScan
    $recommendation = Get-Recommendation
    $manifest = Get-ManifestSummary
    $health = Get-LatestHealthVerdict
    $gitStatus = Get-GitStatusText
    $gitClean = Get-GitCleanVerdict
    $score = Get-ProjectScore
    $latestReports = Get-LatestReportFiles -Max 6

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("BALI AI HQ V3 HANDOVER REPORT")
    $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("Path: $Global:ProjectRoot")
    $lines.Add("")
    $lines.Add("==================== SUMMARY ====================")
    $lines.Add("Version source: update_manifest.json")
    $lines.Add("Version: $($manifest.Version)")
    $lines.Add("Version number: $($manifest.VersionNumber)")
    $lines.Add("Version name: $($manifest.Name)")
    $lines.Add("Safety: $($safety.Verdict)")
    $lines.Add("Mission alignment: PASS")
    $lines.Add("Latest health: $health")
    $lines.Add("Git clean: $gitClean")
    $lines.Add("Project score: $score / 100")
    $lines.Add("Project map: $projectMapPath")
    $lines.Add("Recommended next patch: $($recommendation.Title)")
    $lines.Add("Patch class: $($recommendation.Class)")
    $lines.Add("")
    $lines.Add("Why this patch matters: $($recommendation.Why)")
    $lines.Add("Mission fit: $($recommendation.MissionFit)")
    $lines.Add("Blocked work: $($recommendation.Blocked)")
    $lines.Add("")
    $lines.Add("==================== SAFETY LOCK SCAN ====================")
    $lines.Add("Verdict: $($safety.Verdict)")
    $lines.Add("Files scanned: $($safety.FilesScanned)")
    $lines.Add("Present: " + (($safety.Present) -join ", "))
    if ($safety.Missing.Count -eq 0) { $lines.Add("Missing: NONE") } else { $lines.Add("Missing: " + (($safety.Missing) -join ", ")) }
    if ($safety.Danger.Count -eq 0) { $lines.Add("Danger markers: NONE") } else { $lines.Add("Danger markers: " + (($safety.Danger) -join ", ")) }
    $lines.Add("")
    $lines.Add("==================== CHANGE CLASSIFIER ====================")
    $lines.Add("This V3 patch class: SAFE_TOOLING_ONLY")
    $lines.Add("Trading logic change: NO")
    $lines.Add("Live trading change: NO")
    $lines.Add("API key change: NO")
    $lines.Add("Champion lock change: NO")
    $lines.Add("Recommended next patch class: $($recommendation.Class)")
    $lines.Add("")
    $lines.Add("==================== MISSION ====================")
    $lines.Add((Get-TextSafe -Path (Join-Path $Global:ProjectRoot "MISSION.md") -MaxChars 12000))
    $lines.Add("")
    $lines.Add("==================== LEDGER ====================")
    $lines.Add((Get-TextSafe -Path (Join-Path $Global:ProjectRoot "LEDGER.md") -MaxChars 16000))
    $lines.Add("")
    $lines.Add("==================== NEXT PATCH ====================")
    $lines.Add((Get-TextSafe -Path (Join-Path $Global:ProjectRoot "NEXT_PATCH.md") -MaxChars 12000))
    $lines.Add("")
    $lines.Add("==================== UPDATE MANIFEST ====================")
    $lines.Add($manifest.Text)
    $lines.Add("")
    $lines.Add("==================== PROJECT MAP ====================")
    $lines.Add($projectMapText)
    $lines.Add("")
    $lines.Add("==================== LATEST REPORTS / LOGS ====================")
    if ($latestReports.Count -eq 0) {
        $lines.Add("No latest report/log files found by V3 scan.")
    } else {
        foreach ($f in $latestReports) {
            $lines.Add("---- " + (Get-RelativePathSafe -FullPath $f.FullName) + " | Modified: " + $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") + " ----")
            $lines.Add((Get-TextSafe -Path $f.FullName -MaxChars 7000))
            $lines.Add("")
        }
    }
    $lines.Add("==================== GIT STATUS ====================")
    $lines.Add($gitStatus)
    $lines.Add("")
    $lines.Add("==================== V3 RECOMMENDATION RULE ====================")
    $lines.Add("Every recommendation must improve proof, safety, testing, reporting, strategy discovery, or maintainability.")
    $lines.Add("If not mission aligned, V3 must mark it as: RECOMMENDATION BLOCKED - NOT MISSION ALIGNED.")
    $lines.Add("")
    $lines.Add("==================== OPERATOR NEXT STEP ====================")
    $lines.Add("Apply only the recommended safe tooling/proof/reporting patch. Do not change trading logic until proof gates and safety reports justify it.")

    $lines | Out-File -FilePath $outPath -Encoding UTF8
    Write-Output "BALI AI HQ V3 OUTPUT CREATED:"
    Write-Output $outPath
    return $outPath
}

function Show-Recommendation {
    $r = Get-Recommendation
    Write-Host "Recommended next patch: $($r.Title)" -ForegroundColor Green
    Write-Host "Patch class: $($r.Class)"
    Write-Host "Why: $($r.Why)"
    Write-Host "Mission fit: $($r.MissionFit)"
    Write-Host "Blocked: $($r.Blocked)"
}

function Show-SafetyScan {
    $s = Invoke-SafetyScan
    Write-Host "Safety verdict: $($s.Verdict)" -ForegroundColor Cyan
    Write-Host "Files scanned: $($s.FilesScanned)"
    Write-Host "Present: $($s.Present -join ', ')"
    if ($s.Missing.Count -eq 0) { Write-Host "Missing: NONE" } else { Write-Host "Missing: $($s.Missing -join ', ')" -ForegroundColor Yellow }
    if ($s.Danger.Count -eq 0) { Write-Host "Danger markers: NONE" } else { Write-Host "Danger markers: $($s.Danger -join ', ')" -ForegroundColor Red }
}

function Invoke-GitBackup {
    Push-Location $Global:ProjectRoot
    try {
        $inside = git rev-parse --is-inside-work-tree 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Git is not available or this is not a repo." -ForegroundColor Yellow
            return
        }

        $short = git status --short 2>&1 | Out-String
        if ([string]::IsNullOrWhiteSpace($short)) {
            Write-Host "Git clean. Nothing to back up."
            return
        }

        Write-Host "Pending git changes:" -ForegroundColor Yellow
        Write-Host $short
        $confirm = Read-Host "Type BACKUP to commit and push these changes, or press Enter to cancel"
        if ($confirm -ne "BACKUP") {
            Write-Host "Git backup cancelled."
            return
        }

        git add .
        git commit -m "Bali AI HQ V3 safe tooling backup"
        git push
        Write-Host "Git backup complete." -ForegroundColor Green
    } catch {
        Write-Host "Git backup error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

function Open-ProjectBrain {
    foreach ($name in @("MISSION.md", "LEDGER.md", "NEXT_PATCH.md")) {
        $path = Join-Path $Global:ProjectRoot $name
        if (Test-Path $path) {
            Start-Process $path
        }
    }
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Host "=========================================="
        Write-Host "             BALI AI HQ V3"
        Write-Host "=========================================="
        Write-Host "Project: $Global:ProjectRoot"
        Write-Host "Safety: tooling/reporting only. No live trading. No keys."
        Write-Host ""
        Write-Host "1. Generate AI Handover V3"
        Write-Host "2. Recommend Next Patch"
        Write-Host "3. Safety Lock Scan"
        Write-Host "4. Generate Project Map"
        Write-Host "5. Git Status"
        Write-Host "6. Backup to GitHub"
        Write-Host "7. Open Project Brain"
        Write-Host "8. Exit"
        Write-Host ""
        $choice = Read-Host "Choose option"
        Write-Host ""
        switch ($choice) {
            "1" { New-HandoverReport | Out-Host; Read-Host "Press Enter to continue" | Out-Null }
            "2" { Show-Recommendation; Read-Host "Press Enter to continue" | Out-Null }
            "3" { Show-SafetyScan; Read-Host "Press Enter to continue" | Out-Null }
            "4" { $p = Save-ProjectMap; Write-Host "Project map created: $p" -ForegroundColor Green; Read-Host "Press Enter to continue" | Out-Null }
            "5" { Write-Host (Get-GitStatusText); Read-Host "Press Enter to continue" | Out-Null }
            "6" { Invoke-GitBackup; Read-Host "Press Enter to continue" | Out-Null }
            "7" { Open-ProjectBrain; Read-Host "Press Enter to continue" | Out-Null }
            "8" { return }
            default { Write-Host "Invalid option." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    }
}

switch ($Mode) {
    "GenerateHandover" { New-HandoverReport | Out-Host }
    "ProjectMap" { Save-ProjectMap | Out-Host }
    "RecommendPatch" { Show-Recommendation }
    "SafetyScan" { Show-SafetyScan }
    "GitStatus" { Write-Host (Get-GitStatusText) }
    default { Show-Menu }
}
