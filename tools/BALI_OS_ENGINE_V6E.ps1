param(
  [ValidateSet('auto','safety','recommend','map','evidence','status','handover','git')]
  [string]$Action = 'auto',
  [string]$Base = 'C:\Bali\Bali-Trader'
)
$ErrorActionPreference = 'Stop'
Set-Location $Base

function Ensure-Dir($name) {
  $p = Join-Path $Base $name
  New-Item -ItemType Directory -Force -Path $p | Out-Null
  return $p
}
function TimeStamp() { Get-Date -Format 'yyyyMMdd_HHmmss' }
function NowText() { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
function LatestFile($dir) {
  $p = Join-Path $Base $dir
  if (-not (Test-Path $p)) { return $null }
  return Get-ChildItem $p -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
function GitStatusShort() {
  try {
    $s = (& git status --short 2>$null)
    if ($LASTEXITCODE -ne 0) { return 'UNKNOWN' }
    if (-not $s) { return 'CLEAN' }
    return 'DIRTY'
  } catch { return 'UNKNOWN' }
}
function Run-Safety() {
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base 'tools\BALI_OS_SAFETY_SCAN_V6E.ps1') -Base $Base
  if ($LASTEXITCODE -ne 0) { throw 'Safety scan blocked action. Open latest SAFETY_REPORTS file for exact blockers.' }
}
function New-StatusDashboard() {
  $dir = Ensure-Dir 'STATUS_DASHBOARDS'
  $file = Join-Path $dir ("BALI_STATUS_V6E_{0}.txt" -f (TimeStamp))
  $git = GitStatusShort
  $lines = @(
    'BALI STATUS V6E',
    "Generated: $(NowText)",
    '',
    "Base: $Base",
    'Version: V015A / Bali OS V6E tooling layer',
    "Git: $git",
    'Safety: PASS (latest V6E scan required before actions)',
    'Live Trading: OFF',
    'API Keys: NONE / BLOCKED',
    'Champion Lock: ON',
    'Paper/Sim First: ON',
    'Dashboard: LOCAL URL + TERMINAL FALLBACK',
    'Phone Controls: LOCAL LAN SAFE ACTIONS ONLY',
    '',
    'Recommended operating flow:',
    '1. Start Day / Auto Session',
    '2. Review recommendation',
    '3. Git Safe Save',
    '4. Install next approved safe patch only'
  )
  $lines | Set-Content -Encoding UTF8 $file
  Copy-Item -Force $file (Join-Path $Base 'LATEST_STATUS_DASHBOARD.txt')
  Write-Host "Status dashboard created: $file"
  return $file
}
function New-Recommendation([switch]$PostSave) {
  $dir = Ensure-Dir 'NEXT_PATCH_REPORTS'
  $file = Join-Path $dir ("BALI_NEXT_PATCH_RECOMMENDATION_V6E_{0}.txt" -f (TimeStamp))
  $git = GitStatusShort
  if (($git -eq 'DIRTY') -and (-not $PostSave)) {
    $next = 'Git Safe Save current generated reports before another patch'
    $why = 'The project has generated reports/changes that should be preserved before moving to the next patch.'
  } else {
    $next = 'V7 Stable Tool Cleanup + Archive Manager'
    $why = 'Bali has accumulated V4/V5/V6 fix scripts and generated reports. Clean stable tooling and archive old clutter before deeper evidence/strategy proof work.'
  }
  $lines = @(
    'BALI NEXT PATCH RECOMMENDATION V6E',
    "Generated: $(NowText)",
    '',
    'Recommended Next Patch:',
    $next,
    'Patch Class:',
    'SAFE_TOOLING_ONLY',
    'Why:',
    $why,
    '',
    'MISSION FIT',
    'Improves automation, reporting, proof tracking, project control, maintainability, and safe strategy discovery workflow.',
    '',
    'BLOCKED PATCHES',
    '- LIVE_TRADING',
    '- API_KEYS',
    '- CHAMPION_UNLOCK',
    '- PROFITABILITY_CLAIM_WITHOUT_EVIDENCE',
    '- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE',
    '',
    'OPERATOR DECISION',
    'Approve only if this keeps Bali paper/sim-first and improves proof, testing, reporting, strategy discovery, or maintainability.'
  )
  $lines | Set-Content -Encoding UTF8 $file
  Copy-Item -Force $file (Join-Path $Base 'LATEST_RECOMMENDATION.txt')
  Write-Host "Recommendation created: $file"
  return $file
}
function New-ProjectMap() {
  $dir = Ensure-Dir 'PROJECT_MAPS'
  $file = Join-Path $dir ("BALI_PROJECT_MAP_V6E_{0}.md" -f (TimeStamp))
  $items = Get-ChildItem $Base -Depth 2 -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\.git(\\|$)' } | Select-Object -First 400
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('# BALI PROJECT MAP V6E') | Out-Null
  $lines.Add('') | Out-Null
  $lines.Add("Generated: $(NowText)") | Out-Null
  $lines.Add('') | Out-Null
  foreach ($i in $items) {
    $rel = $i.FullName.Substring($Base.Length).TrimStart('\')
    if ($i.PSIsContainer) { $lines.Add("- [DIR] $rel") | Out-Null } else { $lines.Add("- $rel") | Out-Null }
  }
  $lines | Set-Content -Encoding UTF8 $file
  Copy-Item -Force $file (Join-Path $Base 'PROJECT_MAP.md')
  Write-Host "Project map created: $file"
  return $file
}
function New-EvidenceIndex() {
  $dir = Ensure-Dir 'EVIDENCE_INDEX'
  $file = Join-Path $dir ("BALI_EVIDENCE_INDEX_V6E_{0}.md" -f (TimeStamp))
  $scanDirs = @('SAFETY_REPORTS','STATUS_DASHBOARDS','NEXT_PATCH_REPORTS','PROJECT_MAPS','AI_HANDOVER_REPORTS','SESSION_REPORTS','TEST_REPORTS','RUN_REGISTRY')
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('# BALI EVIDENCE INDEX V6E') | Out-Null
  $lines.Add('') | Out-Null
  $lines.Add("Generated: $(NowText)") | Out-Null
  $lines.Add('') | Out-Null
  foreach ($d in $scanDirs) {
    $lines.Add("## $d") | Out-Null
    $p = Join-Path $Base $d
    if (Test-Path $p) {
      Get-ChildItem $p -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 25 | ForEach-Object {
        $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
        $lines.Add("- $rel | $($_.LastWriteTime)") | Out-Null
      }
    } else { $lines.Add('- Missing') | Out-Null }
    $lines.Add('') | Out-Null
  }
  $lines | Set-Content -Encoding UTF8 $file
  Copy-Item -Force $file (Join-Path $Base 'EVIDENCE_INDEX.md')
  Write-Host "Evidence index created: $file"
  return $file
}
function Update-RunRegistry() {
  $dir = Ensure-Dir 'RUN_REGISTRY'
  $file = Join-Path $dir 'RUN_REGISTRY.csv'
  if (-not (Test-Path $file)) { 'timestamp,run_type,safety,git,status' | Set-Content -Encoding UTF8 $file }
  $line = '"{0}","{1}","{2}","{3}","{4}"' -f (NowText),'BALI_OS_SESSION_V6E','PASS',(GitStatusShort),'RECORDED'
  Add-Content -Path $file -Value $line
  Write-Host "Run registry updated: $file"
  return $file
}
function New-SessionReport() {
  $dir = Ensure-Dir 'SESSION_REPORTS'
  $file = Join-Path $dir ("BALI_SESSION_REPORT_V6E_{0}.txt" -f (TimeStamp))
  $lines = @(
    'BALI SESSION REPORT V6E',
    "Generated: $(NowText)",
    'Safety: PASS',
    "Git: $(GitStatusShort)",
    'Actions: safety scan, status dashboard, recommendation, project map, evidence index, run registry, handover',
    'Next: review recommendation, then Git Safe Save.'
  )
  $lines | Set-Content -Encoding UTF8 $file
  Write-Host "Session report created: $file"
  return $file
}
function New-Handover() {
  $dir = Ensure-Dir 'AI_HANDOVER_REPORTS'
  $file = Join-Path $dir ("BALI_OS_V6E_HANDOVER_{0}.txt" -f (TimeStamp))
  $status = Get-Content (Join-Path $Base 'LATEST_STATUS_DASHBOARD.txt') -ErrorAction SilentlyContinue
  $rec = Get-Content (Join-Path $Base 'LATEST_RECOMMENDATION.txt') -ErrorAction SilentlyContinue
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('BALI OS V6E CHAT HANDOVER') | Out-Null
  $lines.Add("Generated: $(NowText)") | Out-Null
  $lines.Add("Base: $Base") | Out-Null
  $lines.Add('') | Out-Null
  $lines.Add('MISSION') | Out-Null
  $lines.Add('Build Bali into a safe proof-driven crypto strategy research machine that hunts for evidence-backed strategies, while staying paper/sim-first with live trading locked off.') | Out-Null
  $lines.Add('') | Out-Null
  $lines.Add('SAFETY RULES') | Out-Null
  $lines.Add('- LIVE_ORDERS_OFF') | Out-Null
  $lines.Add('- NO_API_KEYS') | Out-Null
  $lines.Add('- PUBLIC_DATA_ONLY') | Out-Null
  $lines.Add('- PAPER/SIM FIRST') | Out-Null
  $lines.Add('- CHAMPION_LOCKED') | Out-Null
  $lines.Add('- NO profitability claims without evidence') | Out-Null
  $lines.Add('') | Out-Null
  $lines.Add('LATEST STATUS') | Out-Null
  foreach ($l in $status) { $lines.Add([string]$l) | Out-Null }
  $lines.Add('') | Out-Null
  $lines.Add('LATEST RECOMMENDATION') | Out-Null
  foreach ($l in $rec) { $lines.Add([string]$l) | Out-Null }
  $lines.Add('') | Out-Null
  $lines.Add('NEXT CHAT INSTRUCTION') | Out-Null
  $lines.Add('Read this handover, preserve the safety rules, and recommend the safest next mission-aligned patch.') | Out-Null
  $lines | Set-Content -Encoding UTF8 $file
  Copy-Item -Force $file (Join-Path $Base 'LATEST_CHAT_HANDOVER.txt')
  try { Get-Content $file -Raw | Set-Clipboard } catch {}
  Write-Host "Handover created: $file"
  Write-Host 'Latest handover copied to: LATEST_CHAT_HANDOVER.txt'
  return $file
}

$logDir = Ensure-Dir 'DASHBOARD_LOGS'
$log = Join-Path $logDir ("BALI_DASHBOARD_ACTION_${Action}_$(TimeStamp).txt")
Start-Transcript -Path $log -Force | Out-Null
try {
  Write-Host "Bali OS Engine V6E action started: $Action"
  switch ($Action) {
    'safety' { Run-Safety }
    'status' { Run-Safety; New-StatusDashboard | Out-Null }
    'recommend' { Run-Safety; New-Recommendation | Out-Null }
    'map' { Run-Safety; New-ProjectMap | Out-Null }
    'evidence' { Run-Safety; New-EvidenceIndex | Out-Null; Update-RunRegistry | Out-Null }
    'handover' { Run-Safety; New-StatusDashboard | Out-Null; New-Recommendation | Out-Null; New-Handover | Out-Null }
    'git' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base 'tools\BALI_SAFE_GIT_SAVE_V6E.ps1') -Base $Base; if ($LASTEXITCODE -ne 0) { throw 'Git safe save failed or blocked.' } }
    'auto' {
      Run-Safety
      New-StatusDashboard | Out-Null
      New-Recommendation | Out-Null
      New-ProjectMap | Out-Null
      New-EvidenceIndex | Out-Null
      Update-RunRegistry | Out-Null
      New-SessionReport | Out-Null
      New-Handover | Out-Null
      Write-Host ''
      Write-Host 'PASS - Bali OS V6E automated session complete.'
      Write-Host 'NEXT: Review recommendation, then Git Safe Save generated reports.'
    }
  }
} finally {
  Stop-Transcript | Out-Null
  Write-Host "Dashboard log: $log"
}
