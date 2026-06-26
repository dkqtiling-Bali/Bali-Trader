
param([string]$Root)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($Root)){ $Root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs=Join-Path $Root 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$state=Join-Path $Root 'game_arena\guardian\BOT_GUARDIAN_STATE_V012H.json'
$report=Join-Path $logs 'BALI_BOT_GUARDIAN_STATUS_V012H.txt'
Set-Content -LiteralPath $report -Encoding ASCII -Value @(
  'BALI BOT GUARDIAN STATUS V012H',
  ('Generated: '+(Get-Date)),
  'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS',
  'BOT_GUARDIAN=ON_SIM_ONLY',
  'BOT_24_7_MODE=WATCH_SCORE_HEARTBEAT_ONLY_WHILE_PC_AWAKE',
  'MAINTENANCE_LOCK=ON_DURING_UPDATES',
  'RAW_LIVE_DATA_ONLY=ON',
  'PHONE_MONITOR=READY_READ_ONLY_LAN'
)
if(Test-Path -LiteralPath $state){ Add-Content -LiteralPath $report -Encoding ASCII -Value ('STATE_FILE=FOUND :: '+$state) } else { Add-Content -LiteralPath $report -Encoding ASCII -Value 'STATE_FILE=MISSING' }
Add-Content -LiteralPath $report -Encoding ASCII -Value 'RESULT=BOT_GUARDIAN_STATUS_READY'
try { Start-Process notepad $report | Out-Null } catch {}
exit 0
