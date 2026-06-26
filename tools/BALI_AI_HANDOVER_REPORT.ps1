# Bali AI Handover Report Generator
# Safe report only. Does not change trading logic.

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = "AI_HANDOVER_REPORTS"
$outFile = Join-Path $outDir "BALI_AI_HANDOVER_$stamp.txt"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$files = @(
    "MISSION.md",
    "LEDGER.md",
    "NEXT_PATCH.md",
    "AI_RULES.md",
    "README.md",
    "update_manifest.json",
    "logs\LAST_FINAL_REPORT.txt",
    "logs\LAST_DASH_UPDATE_RESTART_REPORT.txt"
)

" BALI TRADER AI HANDOVER REPORT" | Set-Content $outFile
"Generated: $(Get-Date)" | Add-Content $outFile
"Path: $(Get-Location)" | Add-Content $outFile
"" | Add-Content $outFile

foreach ($f in $files) {
    "============================================================" | Add-Content $outFile
    "FILE: $f" | Add-Content $outFile
    "============================================================" | Add-Content $outFile

    if (Test-Path $f) {
        Get-Content $f -ErrorAction SilentlyContinue | Add-Content $outFile
    } else {
        "MISSING: $f" | Add-Content $outFile
    }

    "" | Add-Content $outFile
}

"============================================================" | Add-Content $outFile
"GIT STATUS" | Add-Content $outFile
"============================================================" | Add-Content $outFile
git status | Add-Content $outFile

Write-Host ""
Write-Host "BALI AI HANDOVER REPORT CREATED:"
Write-Host $outFile
Write-Host ""
