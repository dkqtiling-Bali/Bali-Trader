param(
    [string]$Mode = "HANDOVER"
)

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = "AI_HANDOVER_REPORTS"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outFile = Join-Path $outDir "BALI_AI_HQ_V2_$stamp.txt"

$mission = if (Test-Path "MISSION.md") { Get-Content "MISSION.md" -Raw } else { "MISSING" }
$ledger = if (Test-Path "LEDGER.md") { Get-Content "LEDGER.md" -Raw } else { "MISSING" }
$next = if (Test-Path "NEXT_PATCH.md") { Get-Content "NEXT_PATCH.md" -Raw } else { "MISSING" }
$rules = if (Test-Path "AI_RULES.md") { Get-Content "AI_RULES.md" -Raw } else { "MISSING" }
$finalReport = if (Test-Path "logs\LAST_FINAL_REPORT.txt") { Get-Content "logs\LAST_FINAL_REPORT.txt" -Raw } else { "MISSING" }
$manifest = if (Test-Path "update_manifest.json") { Get-Content "update_manifest.json" -Raw } else { "MISSING" }

$gitStatus = git status --short
if ([string]::IsNullOrWhiteSpace($gitStatus)) { $gitClean = "PASS" } else { $gitClean = "DIRTY" }

$safetyText = "$mission
$rules
$finalReport"
$safetyPass = (
    $safetyText -match "LIVE_ORDERS_OFF" -and
    $safetyText -match "NO_API_KEYS" -and
    $safetyText -match "CHAMPION_LOCK" -and
    $safetyText -match "PAPER|SIM"
)

if ($safetyPass) { $safetyScore = 100; $safetyVerdict = "PASS" } else { $safetyScore = 60; $safetyVerdict = "CHECK REQUIRED" }

$missionAligned = ($mission -match "MISSION ALIGNMENT RULE" -and $rules -match "MISSION ALIGNMENT RULE")
if ($missionAligned) { $missionVerdict = "PASS" } else { $missionVerdict = "CHECK REQUIRED" }

$healthPass = ($finalReport -match "RESULT=PASS" -or $finalReport -match "HEALTH=PASS")
if ($healthPass) { $healthVerdict = "PASS" } else { $healthVerdict = "CHECK REQUIRED" }

$score = 0
if ($safetyVerdict -eq "PASS") { $score += 30 }
if ($missionVerdict -eq "PASS") { $score += 25 }
if ($healthVerdict -eq "PASS") { $score += 25 }
if ($gitClean -eq "PASS") { $score += 20 }

$recommendedPatch = "AI HQ V3 Project Map + Smarter Recommendation Engine"
$why = "Improves maintainability, reduces chat dependence, and helps Bali identify the safest highest-value next patch before changing trading logic."
$missionFit = "Supports the mission by improving proof, reporting, safety visibility, and AI-assisted strategy discovery workflow."

if ($Mode -eq "SAFETY") {
    "BALI SAFETY LOCK SCAN" | Set-Content $outFile
    "Generated: $(Get-Date)" | Add-Content $outFile
    "" | Add-Content $outFile
    "Safety verdict: $safetyVerdict" | Add-Content $outFile
    "Mission alignment: $missionVerdict" | Add-Content $outFile
    "Health verdict: $healthVerdict" | Add-Content $outFile
    "Git clean: $gitClean" | Add-Content $outFile
}
elseif ($Mode -eq "RECOMMEND") {
    "BALI NEXT PATCH RECOMMENDATION" | Set-Content $outFile
    "Generated: $(Get-Date)" | Add-Content $outFile
    "" | Add-Content $outFile
    "Recommended next patch: $recommendedPatch" | Add-Content $outFile
    "Why: $why" | Add-Content $outFile
    "Mission alignment: $missionFit" | Add-Content $outFile
    "Risk: LOW" | Add-Content $outFile
    "Safety: $safetyVerdict" | Add-Content $outFile
    "Project score: $score / 100" | Add-Content $outFile
}
else {
    "BALI AI HQ V2 HANDOVER REPORT" | Set-Content $outFile
    "Generated: $(Get-Date)" | Add-Content $outFile
    "Path: $(Get-Location)" | Add-Content $outFile
    "" | Add-Content $outFile
    "==================== SUMMARY ====================" | Add-Content $outFile
    "Version source: update_manifest.json" | Add-Content $outFile
    "Safety: $safetyVerdict" | Add-Content $outFile
    "Mission alignment: $missionVerdict" | Add-Content $outFile
    "Latest health: $healthVerdict" | Add-Content $outFile
    "Git clean: $gitClean" | Add-Content $outFile
    "Project score: $score / 100" | Add-Content $outFile
    "Recommended next patch: $recommendedPatch" | Add-Content $outFile
    "" | Add-Content $outFile
    "Why this patch matters: $why" | Add-Content $outFile
    "Mission fit: $missionFit" | Add-Content $outFile
    "" | Add-Content $outFile
    "==================== MISSION ====================" | Add-Content $outFile
    $mission | Add-Content $outFile
    "==================== LEDGER ====================" | Add-Content $outFile
    $ledger | Add-Content $outFile
    "==================== NEXT PATCH ====================" | Add-Content $outFile
    $next | Add-Content $outFile
    "==================== AI RULES ====================" | Add-Content $outFile
    $rules | Add-Content $outFile
    "==================== UPDATE MANIFEST ====================" | Add-Content $outFile
    $manifest | Add-Content $outFile
    "==================== LATEST FINAL REPORT ====================" | Add-Content $outFile
    $finalReport | Add-Content $outFile
    "==================== GIT STATUS ====================" | Add-Content $outFile
    git status | Add-Content $outFile
}

Write-Host ""
Write-Host "BALI AI HQ V2 OUTPUT CREATED:"
Write-Host $outFile
Write-Host ""
Get-Content $outFile
