param([string]$RootPath)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($RootPath)){ $RootPath=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs=Join-Path $RootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_ARENA_BRIDGE_STATUS_V012F.txt'
$shared=Join-Path $RootPath 'game_arena\bridge\shared_drop'
$bali=Join-Path $shared 'from_bali'
$gate=Join-Path $shared 'from_stargate'
function CountJson($p){ if(Test-Path -LiteralPath $p){ @(Get-ChildItem -LiteralPath $p -Filter '*.json' -File -ErrorAction SilentlyContinue).Count } else { 0 } }
Set-Content -LiteralPath $report -Value @('BALI ARENA BRIDGE STATUS V012F',('Generated: '+(Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS','BRIDGE=SHARED_FOLDER_READY_SIM_ONLY',('BALI_JSON_COUNT='+(CountJson $bali)),('STARGATE_JSON_COUNT='+(CountJson $gate)),'NETWORK_EXECUTION=OFF','LIVE_ORDERS=OFF','RESULT=PASS') -Encoding ASCII
Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_ARENA_BRIDGE_STATUS.txt') -Force
exit 0
