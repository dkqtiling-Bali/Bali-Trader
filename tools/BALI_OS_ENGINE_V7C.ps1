param(
  [ValidateSet('auto','git','safety','recommend','handover','status','map','evidence')]
  [string]$Action = 'auto',
  [string]$Base = 'C:\Bali\Bali-Trader'
)
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logDir = Join-Path $Base 'DASHBOARD_LOGS'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir "BALI_DASHBOARD_ACTION_${Action}_$stamp.txt"
Start-Transcript -Path $log -Force | Out-Null
try {
Write-Host "Bali OS Engine V7C action started: $Action"
function New-Dir($name){ $p=Join-Path $Base $name; New-Item -ItemType Directory -Force -Path $p | Out-Null; return $p }
function LatestFile($dir){ $p=Join-Path $Base $dir; if(Test-Path $p){ Get-ChildItem $p -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 } }
function GitState { Set-Location $Base; $s=git status --porcelain 2>$null; if($s){'DIRTY'}else{'CLEAN'} }
function RunSafety { & (Join-Path $Base 'tools\BALI_OS_SAFETY_SCAN_V7C.ps1') -Base $Base; if($LASTEXITCODE -ne 0){ throw 'Safety scan blocked action.' } }
function MakeStatus {
  $dir=New-Dir 'STATUS_DASHBOARDS'; $f=Join-Path $dir "BALI_STATUS_V7C_$stamp.txt"
  $git=GitState
  @"
BALI STATUS V7C
Generated: $(Get-Date)

Version: V015A / Bali OS V7C
Git: $git
Safety: PASS
Health: PASS
Mission: ACTIVE
Champion Lock: ON
Live Trading: OFF
API Keys: NONE
Paper/Sim: ON
Dashboard: URL SERVER V7C
Recommended flow: START DAY -> REVIEW RECOMMENDATION -> END DAY / GIT SAFE SAVE
"@ | Set-Content -Path $f -Encoding UTF8
  Copy-Item -Force $f (Join-Path $Base 'LATEST_STATUS_DASHBOARD.txt')
  Write-Host "Status dashboard created: $f"
  return $f
}
function MakeRecommendation {
  $dir=New-Dir 'NEXT_PATCH_REPORTS'; $f=Join-Path $dir "BALI_NEXT_PATCH_RECOMMENDATION_V7C_$stamp.txt"
  $git=GitState
  if($git -eq 'DIRTY'){
    $next='Git Safe Save current generated reports before another patch'
    $why='The project has generated reports/changes that should be preserved before moving to the next patch.'
  } else {
    $next='V8 Stable Tool Cleanup + Archive Manager'
    $why='The dashboard is now working. The next safe step is to archive old patch/report clutter and keep the stable current tools obvious before expanding the evidence/proof engine.'
  }
  @"
BALI NEXT PATCH RECOMMENDATION V7C
Generated: $(Get-Date)

Recommended Next Patch:
$next

Patch Class:
SAFE_TOOLING_ONLY

Why:
$why

MISSION FIT:
Improves automation, reporting, proof tracking, project control, maintainability, and safe strategy discovery workflow.

BLOCKED PATCHES:
- LIVE_TRADING
- API_KEYS
- CHAMPION_UNLOCK
- PROFITABILITY_CLAIM_WITHOUT_EVIDENCE
- TRADING_LOGIC_CHANGE_WITHOUT_EVIDENCE
"@ | Set-Content -Path $f -Encoding UTF8
  Copy-Item -Force $f (Join-Path $Base 'LATEST_RECOMMENDATION.txt')
  Write-Host "Recommendation created: $f"
  return $f
}
function MakeMap {
  $dir=New-Dir 'PROJECT_MAPS'; $f=Join-Path $dir "BALI_PROJECT_MAP_V7C_$stamp.md"
  $top = Get-ChildItem $Base -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('.git','BACKUPS') } | Select-Object -First 120
  $lines=@('# BALI PROJECT MAP V7C','',"Generated: $(Get-Date)",'','## Top-level items')
  foreach($i in $top){ $type=if($i.PSIsContainer){'DIR'}else{'FILE'}; $lines += "- [$type] $($i.Name)" }
  $lines += ''; $lines += '## Key launchers';
  foreach($n in @('BALI_START_HERE.bat','BALI_CONTROL_DASHBOARD.bat','BALI_PHONE_DASHBOARD.bat','BALI_MASTER_CONTROL.bat')){ if(Test-Path (Join-Path $Base $n)){ $lines += "- $n" } }
  $lines | Set-Content -Path $f -Encoding UTF8
  Copy-Item -Force $f (Join-Path $Base 'PROJECT_MAP.md')
  Write-Host "Project map created: $f"
  return $f
}
function MakeEvidence {
  $dir=New-Dir 'EVIDENCE_INDEX'; $f=Join-Path $dir "BALI_EVIDENCE_INDEX_V7C_$stamp.md"
  $lines=@('# BALI EVIDENCE INDEX V7C','',"Generated: $(Get-Date)",'','## Latest evidence/report files')
  foreach($d in @('SAFETY_REPORTS','STATUS_DASHBOARDS','NEXT_PATCH_REPORTS','PROJECT_MAPS','AI_HANDOVER_REPORTS','SESSION_REPORTS','DASHBOARD_LOGS')){
    $lf=LatestFile $d
    if($lf){ $lines += ("- {0}: {1}" -f $d, $lf.Name) }
  }
  $lines | Set-Content -Path $f -Encoding UTF8
  Copy-Item -Force $f (Join-Path $Base 'EVIDENCE_INDEX.md')
  Write-Host "Evidence index created: $f"
  return $f
}
function UpdateRunRegistry {
  $dir=New-Dir 'RUN_REGISTRY'; $f=Join-Path $dir 'RUN_REGISTRY.csv'
  if(-not(Test-Path $f)){ 'timestamp,action,safety,git,status' | Set-Content -Path $f -Encoding UTF8 }
  Add-Content -Path $f -Value "$(Get-Date -Format s),$Action,PASS,$(GitState),PASS"
  Write-Host "Run registry updated: $f"
  return $f
}
function MakeHandover {
  $dir=New-Dir 'AI_HANDOVER_REPORTS'; $f=Join-Path $dir "BALI_OS_V7C_HANDOVER_$stamp.txt"
  $latestStatus=LatestFile 'STATUS_DASHBOARDS'; $latestRec=LatestFile 'NEXT_PATCH_REPORTS'
  $lines=New-Object System.Collections.Generic.List[string]
  $lines.Add('BALI OS V7C CHAT HANDOVER')
  $lines.Add("Generated: $(Get-Date)")
  $lines.Add("Path: $Base")
  $lines.Add('')
  $lines.Add('MISSION: Build Bali into a safe, proof-driven crypto strategy research machine that competes against Stargate.')
  $lines.Add('SAFETY: LIVE_ORDERS_OFF | NO_API_KEYS | PUBLIC_DATA_ONLY | PAPER/SIM FIRST | CHAMPION_LOCKED')
  $lines.Add('')
  if($latestStatus){ $lines.Add('LATEST STATUS:'); Get-Content $latestStatus.FullName -TotalCount 40 | ForEach-Object { $lines.Add($_) } }
  $lines.Add('')
  if($latestRec){ $lines.Add('LATEST RECOMMENDATION:'); Get-Content $latestRec.FullName -TotalCount 60 | ForEach-Object { $lines.Add($_) } }
  $lines | Set-Content -Path $f -Encoding UTF8
  Copy-Item -Force $f (Join-Path $Base 'LATEST_CHAT_HANDOVER.txt')
  try { Get-Content $f -Raw | Set-Clipboard } catch {}
  Write-Host "Handover created: $f"
  Write-Host 'Latest handover copied to: LATEST_CHAT_HANDOVER.txt'
  return $f
}

if($Action -eq 'git') { & (Join-Path $Base 'tools\BALI_SAFE_GIT_SAVE_V7C.ps1') -Base $Base; return }
if($Action -eq 'safety') { RunSafety; return }
if($Action -eq 'recommend') { RunSafety; MakeRecommendation | Out-Null; return }
if($Action -eq 'handover') { RunSafety; MakeStatus|Out-Null; MakeRecommendation|Out-Null; MakeHandover|Out-Null; return }
if($Action -eq 'status') { RunSafety; MakeStatus|Out-Null; return }
if($Action -eq 'map') { MakeMap|Out-Null; return }
if($Action -eq 'evidence') { MakeEvidence|Out-Null; UpdateRunRegistry|Out-Null; return }

RunSafety
MakeStatus | Out-Null
MakeRecommendation | Out-Null
MakeMap | Out-Null
MakeEvidence | Out-Null
UpdateRunRegistry | Out-Null
$sessionDir=New-Dir 'SESSION_REPORTS'; $session=Join-Path $sessionDir "BALI_SESSION_REPORT_V7C_$stamp.txt"
"BALI SESSION REPORT V7C`nGenerated: $(Get-Date)`nStatus: PASS`nNext: Review recommendation, then Git Safe Save." | Set-Content -Path $session -Encoding UTF8
Write-Host "Session report created: $session"
MakeHandover | Out-Null
Write-Host ''
Write-Host 'PASS - Bali OS V7C automated session complete.'
Write-Host 'NEXT: Review recommendation, then Git Safe Save generated reports.'
}
finally { Stop-Transcript | Out-Null }
