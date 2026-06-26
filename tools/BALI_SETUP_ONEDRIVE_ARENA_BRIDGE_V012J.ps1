$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
# If run from tools folder, root is parent.
if ((Split-Path -Leaf $Root) -ieq "tools") { $Root = Split-Path -Parent $Root }
$LogDir = Join-Path $Root "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Report = Join-Path $LogDir "BALI_ONEDRIVE_BRIDGE_SETUP_REPORT_V012J.txt"
Remove-Item $Report -Force -ErrorAction SilentlyContinue
function Add-Line($s){ Add-Content -Path $Report -Value $s }
Add-Line "BALI ONEDRIVE BRIDGE SETUP V012J"
Add-Line ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Line "Safety: LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS | SIM_ONLY"
$OneDrive = $env:OneDrive
if ([string]::IsNullOrWhiteSpace($OneDrive)) { $OneDrive = $env:OneDriveConsumer }
if ([string]::IsNullOrWhiteSpace($OneDrive) -or -not (Test-Path -LiteralPath $OneDrive)) { $OneDrive = Join-Path $env:USERPROFILE "OneDrive" }
if (!(Test-Path -LiteralPath $OneDrive)) { New-Item -ItemType Directory -Force -Path $OneDrive | Out-Null }
$BridgeRoot = Join-Path $OneDrive "BaliArenaBridge"
$dirs = @($BridgeRoot, "$BridgeRoot\from_bali", "$BridgeRoot\from_stargate", "$BridgeRoot\heartbeats", "$BridgeRoot\round_rules", "$BridgeRoot\round_results", "$BridgeRoot\config", "$BridgeRoot\logs", "$BridgeRoot\shared_drop\from_bali", "$BridgeRoot\shared_drop\from_stargate", "$BridgeRoot\shared_drop\heartbeats", "$BridgeRoot\shared_drop\round_rules", "$BridgeRoot\shared_drop\round_results", "$Root\game_arena\bridge")
foreach($d in $dirs){ New-Item -ItemType Directory -Force -Path $d | Out-Null }
$config = [ordered]@{ version="V012J"; active_bridge_root=$BridgeRoot; bridge_mode="ONEDRIVE_SYNCED_FOLDER_JSON_ONLY"; data_rule="RAW_LIVE_DATA_ONLY_REQUIRED_FOR_SCORING"; mode="SIM_ONLY"; remote_commands="BLOCKED"; live_orders="OFF"; api_keys="NONE"; bali_role="GOVERNOR_HUB_AND_COMPETITOR"; stargate_role="COMPETITOR_NODE_JSON_CHECKINS_ONLY"; created_at=(Get-Date).ToString("o") }
$CfgPath = Join-Path $Root "game_arena\bridge\ACTIVE_BRIDGE_CONFIG.json"
$config | ConvertTo-Json -Depth 6 | Set-Content -Path $CfgPath -Encoding UTF8
$config | ConvertTo-Json -Depth 6 | Set-Content -Path "$BridgeRoot\config\bali_governor_hub_config.json" -Encoding UTF8
$hb = [ordered]@{ version="V012J"; node="BALI_CPU"; role="GOVERNOR_HUB_AND_COMPETITOR"; status="READY"; mode="SIM_ONLY"; bridge="JSON_ONLY_NO_REMOTE_COMMANDS"; raw_live_data_only=$true; live_orders="OFF"; api_keys="NONE"; timestamp=(Get-Date).ToString("o") }
$hb | ConvertTo-Json -Depth 6 | Set-Content -Path "$BridgeRoot\heartbeats\bali_heartbeat.json" -Encoding UTF8
$PathFile = Join-Path $Root "game_arena\bridge\BALI_ONEDRIVE_BRIDGE_PATH_FOR_STARGATE.txt"
$BridgeRoot | Set-Content -Path $PathFile -Encoding ASCII
Add-Line "BRIDGE_ROOT=$BridgeRoot"
Add-Line "CONFIG=$CfgPath"
Add-Line "PATH_FILE=$PathFile"
Add-Line "GOVERNOR_HUB=BALI_CPU"
Add-Line "STARGATE_ROLE=COMPETITOR_NODE_JSON_CHECKINS_ONLY"
Add-Line "BRIDGE=ONEDRIVE_JSON_ONLY_NO_REMOTE_COMMANDS"
Add-Line "RAW_LIVE_DATA_ONLY=ON"
Add-Line "MODE=SIM_ONLY"
Add-Line "RESULT=PASS"
Write-Host "BALI_ONEDRIVE_BRIDGE=READY"
Write-Host "BRIDGE_ROOT=$BridgeRoot"
Write-Host "RESULT=PASS"
Start-Process notepad.exe $Report
Start-Process notepad.exe $PathFile
