param([string]$RootPath)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs = Join-Path $RootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report = Join-Path $logs 'BALI_ARENA_REFEREE_PREP_REPORT_V012G.txt'
function Add($x){ Add-Content -LiteralPath $report -Value $x -Encoding ASCII }
Set-Content -LiteralPath $report -Value @('BALI ARENA REFEREE PREP REPORT V012G',('Generated: ' + (Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS','') -Encoding ASCII
$rules = Join-Path $RootPath 'game_arena\referee\REFEREE_SCORING_RULES_V012G.json'
$bali = Join-Path $RootPath 'game_arena\bridge\outbox\BALI_CPU_CHECKIN_SAMPLE_V012G.json'
$gate = Join-Path $RootPath 'game_arena\bridge\inbox\STARGATE_CPU_CHECKIN_SAMPLE_V012G.json'
foreach($f in @($rules,$bali,$gate)){
  if(Test-Path -LiteralPath $f){ Add ('FOUND=' + $f) } else { Add ('MISSING=' + $f); Add 'RESULT=FAIL'; exit 1 }
}
$r = Get-Content -LiteralPath $rules -Raw | ConvertFrom-Json
$b = Get-Content -LiteralPath $bali -Raw | ConvertFrom-Json
$s = Get-Content -LiteralPath $gate -Raw | ConvertFrom-Json
if($r.competition_mode -ne 'SIM_ONLY' -or $b.mode -ne 'SIM_ONLY' -or $s.mode -ne 'SIM_ONLY') { Add 'RESULT=FAIL'; Add 'ERROR=NON_SIM_MODE_DETECTED'; exit 2 }
if($b.safety_violations -ne 0 -or $s.safety_violations -ne 0) { Add 'RESULT=FAIL'; Add 'ERROR=SAFETY_VIOLATION_IN_SAMPLE_CHECKIN'; exit 3 }
Add 'REFEREE_RULES=FOUND'
Add 'BALI_CHECKIN=VALID_SAMPLE'
Add 'STARGATE_CHECKIN=VALID_SAMPLE'
Add 'MATCH_REFEREE=PREP_LOCAL_JSON_ONLY'
Add 'RESULT=PASS'
Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_ARENA_REFEREE_PREP_REPORT.txt') -Force
exit 0
