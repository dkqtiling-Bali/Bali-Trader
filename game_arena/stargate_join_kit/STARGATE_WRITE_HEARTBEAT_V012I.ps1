param([Parameter(Mandatory=$true)][string]$BridgeRoot)
$ErrorActionPreference='Continue'
$root=(Resolve-Path $BridgeRoot).Path
$heart=Join-Path $root 'heartbeats'
New-Item -ItemType Directory -Force -Path $heart | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$obj=[ordered]@{
  version='V012I'
  team='Stargate'
  cpu_role='STARGATE_CPU'
  heartbeat='ALIVE'
  mode='SIM_ONLY'
  live_orders='OFF'
  api_keys='NONE'
  remote_commands='DISABLED'
  bridge='JSON_ONLY_NO_REMOTE_COMMANDS'
  timestamp=(Get-Date).ToString('o')
}
$path=Join-Path $heart ('stargate_heartbeat_'+$stamp+'_V012I.json')
$obj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding ASCII
Write-Host ('STARGATE_HEARTBEAT_WRITTEN='+$path)
exit 0
