param([string]$RootPath,[string]$SharedPath)
$ErrorActionPreference='Continue'
if([string]::IsNullOrWhiteSpace($RootPath)){ $RootPath=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
if([string]::IsNullOrWhiteSpace($SharedPath)){ $SharedPath=Join-Path $RootPath 'game_arena\bridge\shared_drop\from_stargate' }
$logs=Join-Path $RootPath 'logs'; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$report=Join-Path $logs 'BALI_BRIDGE_IMPORT_STARGATE_REPORT_V012F.txt'
function Add($s){ Add-Content -LiteralPath $report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $report -Value @('BALI BRIDGE IMPORT STARGATE REPORT V012F',('Generated: '+(Get-Date)),'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS') -Encoding ASCII
if(-not(Test-Path -LiteralPath $SharedPath)){ Add ('RESULT=WAITING'); Add ('MISSING_SHARED_PATH='+$SharedPath); exit 1 }
$files=Get-ChildItem -LiteralPath $SharedPath -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $files){ Add 'RESULT=WAITING'; Add 'NO_STARGATE_JSON_FOUND'; exit 1 }
$f=$files[0]
try{ $j=Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json } catch { Add 'RESULT=FAIL'; Add ('ERROR=BAD_JSON '+$f.FullName); exit 2 }
if($j.mode -ne 'SIM_ONLY'){ Add 'RESULT=FAIL'; Add 'ERROR=NON_SIM_MODE_REJECTED'; exit 3 }
if($j.orders_live -eq $true -or $j.api_keys_present -eq $true -or [int]$j.safety_violations -gt 0){ Add 'RESULT=FAIL'; Add 'ERROR=SAFETY_REJECTED'; exit 4 }
$inbox=Join-Path $RootPath 'game_arena\bridge\inbox'; New-Item -ItemType Directory -Force -Path $inbox | Out-Null
$dest=Join-Path $inbox $f.Name
Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
Add ('STARGATE_CHECKIN_IMPORTED='+$dest)
Add 'STARGATE_CHECKIN=VALID_SIM_ONLY'
Add 'BRIDGE=SHARED_FOLDER_JSON_ONLY'
Add 'RESULT=PASS'
Copy-Item -LiteralPath $report -Destination (Join-Path $logs 'LAST_BRIDGE_IMPORT_STARGATE_REPORT.txt') -Force
exit 0
