param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$Report
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$healthM = Join-Path $rootPath 'tools\BALI_FAST_HEALTH_ENGINE_V012J.ps1'
$cleanupM = Join-Path $rootPath 'tools\BALI_LAUNCH_BAY_CLEANUP_V012J.ps1'
$statusM = Join-Path $rootPath 'tools\BALI_FAST_STATUS_PACK_V012J.ps1'
$cleanupReport = Join-Path $logs 'BALI_LAUNCH_BAY_CLEANUP_REPORT_V012J.txt'
$statusReport = Join-Path $logs 'BALI_FAST_STATUS_PACK_V012J.txt'
if(Test-Path -LiteralPath $healthM -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $healthM -Root $rootPath -Report $Report | Out-Null
  $code = $LASTEXITCODE
} else {
  Set-Content -LiteralPath $Report -Value @(
    'BALI FAST HEALTH REPORT V011L COMPAT',
    ('Generated: ' + (Get-Date)),
    ('Root folder: ' + $rootPath),
    'RESULT: FAST HEALTH FAIL - V012J HEALTH ENGINE MISSING'
  ) -Encoding ASCII
  $code = 8
}
# First-run compatibility: when V012J is applied by the older V011L speed lane, still run cleanup/status once.
if(Test-Path -LiteralPath $cleanupM -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $cleanupM -Root $rootPath -Report $cleanupReport | Out-Null
}
if(Test-Path -LiteralPath $statusM -PathType Leaf) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $statusM -Root $rootPath -Report $statusReport | Out-Null
}
exit $code
