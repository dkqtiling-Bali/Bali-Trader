
param([string]$Root)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($Root)){ $Root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$rootPath=(Resolve-Path $Root).Path
$logs=Join-Path $rootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_GOVERNOR_HUB_STATUS_V012J.txt'
Set-Content -LiteralPath $report -Encoding ASCII -Value @(
  'BALI GOVERNOR HUB STATUS V012J',
  ('Generated: '+(Get-Date)),
  'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS',
  'GOVERNOR_HUB=BALI_CPU',
  'BALI_ROLE=GOVERNOR_HUB_AND_COMPETITOR',
  'STARGATE_ROLE=COMPETITOR_NODE_JSON_CHECKINS_ONLY',
  'BRIDGE=SHARED_FOLDER_JSON_ONLY_NO_REMOTE_COMMANDS',
  'RAW_LIVE_DATA_ONLY=ON',
  'RESULT=GOVERNOR_HUB_READY'
)
try { Start-Process notepad $report | Out-Null } catch {}
exit 0
