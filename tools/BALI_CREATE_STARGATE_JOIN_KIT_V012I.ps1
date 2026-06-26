
param([string]$Root)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($Root)){ $Root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$rootPath=(Resolve-Path $Root).Path
$logs=Join-Path $rootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$src=Join-Path $rootPath 'game_arena\stargate_join_kit'
$outDir=Join-Path $rootPath 'game_arena\stargate_join_kit_output'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$zip=Join-Path $outDir ('STARGATE_JOIN_KIT_V012I_'+$stamp+'.zip')
if(Test-Path -LiteralPath $src){
  if(Test-Path -LiteralPath $zip){ Remove-Item -LiteralPath $zip -Force }
  Compress-Archive -Path (Join-Path $src '*') -DestinationPath $zip -Force
}
$report=Join-Path $logs 'BALI_STARGATE_JOIN_KIT_REPORT_V012I.txt'
Set-Content -LiteralPath $report -Encoding ASCII -Value @(
  'BALI STARGATE JOIN KIT V012I',
  ('Generated: '+(Get-Date)),
  'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS',
  'GOVERNOR_HUB=BALI_CPU',
  'STARGATE_ROLE=COMPETITOR_NODE_JSON_CHECKINS_ONLY',
  'STARGATE_JOIN_KIT_EXPORT=READY',
  'BRIDGE=SHARED_FOLDER_JSON_ONLY_NO_REMOTE_COMMANDS',
  ('JOIN_KIT_ZIP='+$zip),
  'RESULT=STARGATE_JOIN_KIT_READY'
)
try { Start-Process notepad $report | Out-Null } catch {}
exit 0
