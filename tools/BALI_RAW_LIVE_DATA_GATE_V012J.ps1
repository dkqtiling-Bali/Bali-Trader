
param([string]$RootPath,[string]$CheckinPath)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($RootPath)){ $RootPath=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$logs=Join-Path $RootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_RAW_LIVE_DATA_GATE_REPORT_V012J.txt'
function Add([string]$line){ Add-Content -LiteralPath $report -Value $line -Encoding ASCII }
Set-Content -LiteralPath $report -Value @('BALI RAW LIVE DATA GATE V012J',('Generated: '+(Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS','RAW_LIVE_DATA_ONLY=ON') -Encoding ASCII
if([string]::IsNullOrWhiteSpace($CheckinPath) -or -not (Test-Path -LiteralPath $CheckinPath -PathType Leaf)){ Add 'CHECKIN=MISSING'; Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 2 }
try { $j=Get-Content -LiteralPath $CheckinPath -Raw | ConvertFrom-Json } catch { Add 'CHECKIN_JSON=INVALID'; Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 3 }
$required=@('data_origin','source_exchange','source_symbol','market_timestamp_utc','captured_at_utc','raw_ticks_count','orders_live','api_keys_present','safety_violations')
$missing=@()
foreach($k in $required){ if($null -eq $j.$k -or [string]::IsNullOrWhiteSpace([string]$j.$k)){ $missing += $k } }
if($missing.Count -gt 0){ Add ('MISSING_FIELDS=' + ($missing -join ',')); Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 4 }
if(([string]$j.data_origin).ToUpperInvariant() -ne 'RAW_LIVE_DATA'){ Add ('DATA_ORIGIN_BLOCKED=' + $j.data_origin); Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 5 }
if([bool]$j.orders_live -or [bool]$j.api_keys_present -or [double]$j.safety_violations -gt 0){ Add 'SAFETY_GATE=FAIL'; Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 6 }
if([double]$j.raw_ticks_count -lt 1){ Add 'RAW_TICKS_COUNT=TOO_LOW'; Add 'RESULT=RAW_LIVE_DATA_GATE_FAIL'; exit 7 }
Add ('CHECKIN=' + $CheckinPath)
Add ('SOURCE=' + $j.source_exchange + ':' + $j.source_symbol)
Add ('MARKET_TIMESTAMP_UTC=' + $j.market_timestamp_utc)
Add 'RESULT=RAW_LIVE_DATA_GATE_PASS'
exit 0
