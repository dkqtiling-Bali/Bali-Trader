
param([string]$Root)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($Root)){ $Root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs=Join-Path $Root 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$status=Join-Path $Root 'game_arena\phone_monitor\PHONE_MONITOR_STATUS_V012G.json'
$report=Join-Path $logs 'BALI_PHONE_ARENA_MONITOR_STATUS_V012G.txt'
$ip='YOUR-PC-LAN-IP'
try {
  $cand = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' } | Select-Object -First 1
  if($cand){ $ip=$cand.IPAddress }
} catch {}
Set-Content -LiteralPath $report -Encoding ASCII -Value @(
  'BALI PHONE ARENA MONITOR STATUS V012G',
  ('Generated: '+(Get-Date)),
  'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS',
  'PHONE_MONITOR=READY_READ_ONLY_LAN',
  'PHONE_CONTROL=OFF_VIEW_ONLY',
  'PHONE_TRADING_CONTROLS=BLOCKED',
  'PUBLIC_INTERNET_EXPOSURE=OFF',
  ('PHONE_LAN_URL=http://'+$ip+':9061'),
  'SHOWS=scoreboard,bot heartbeats,research/scout/paper points,governor notes,raw data gate',
  'RESULT=PHONE_MONITOR_READY'
)
try { Start-Process notepad $report | Out-Null } catch {}
exit 0
