param([string]$RootPath,[string]$SharedPath)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($RootPath)){ $RootPath=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
if([string]::IsNullOrWhiteSpace($SharedPath)){ $SharedPath=Join-Path $RootPath 'game_arena\bridge\shared_drop\from_bali' }
New-Item -ItemType Directory -Force -Path $SharedPath | Out-Null
$logs=Join-Path $RootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_BRIDGE_EXPORT_REPORT_V012D.txt'
$checkin=[ordered]@{
  version='V012D'; cpu_role='BALI_CPU'; bot='Bali Bot'; mode='SIM_ONLY'; round_id='ROUND_0001_BRIDGE_TEST';
  timestamp=(Get-Date).ToString('s'); profit_pct=0.0; max_drawdown_pct=0.0; risk_events=0; uptime_pct=100;
  safety_violations=0; orders_live=$false; api_keys_present=$false; score=0; xp=0;
  status='BALI_CHECKIN_EXPORTED_SHARED_FOLDER_READY'; safety='LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS'
}
$out=Join-Path $SharedPath ('BALI_CPU_CHECKIN_' + (Get-Date -Format yyyyMMdd_HHmmss) + '_V012D.json')
$checkin | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $out -Encoding ASCII
Set-Content -LiteralPath $report -Value @('BALI BRIDGE EXPORT REPORT V012D',('Generated: '+(Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS',('BALI_CHECKIN_EXPORTED='+$out),'BRIDGE=SHARED_FOLDER_JSON_ONLY','RESULT=PASS') -Encoding ASCII
Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_BRIDGE_EXPORT_REPORT.txt') -Force
exit 0
