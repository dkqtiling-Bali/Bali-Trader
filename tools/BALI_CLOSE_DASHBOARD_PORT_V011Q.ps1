param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$Report = '',
  [int]$Port = 9061,
  [int]$Force = 1
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
if([string]::IsNullOrWhiteSpace($Report)) { $Report = Join-Path $logs 'BALI_CLOSE_DASHBOARD_PORT_REPORT_V011Q.txt' }
function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }
Set-Content -LiteralPath $Report -Value @(
  'BALI CLOSE PREVIOUS DASHBOARD REPORT V011Q',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  ('Port: ' + $Port),
  'Purpose: close previous Bali dashboard before update/restart so only one dash remains.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII
$pids = @()
try {
  $rows = netstat -ano | Select-String (':' + $Port)
  foreach($r in $rows) {
    $parts = ($r.Line.Trim() -split '\s+')
    if($parts.Count -ge 5 -and $parts[1] -match (':' + $Port + '$') -and $parts[3] -match 'LISTENING|ESTABLISHED') {
      $pidVal = 0
      if([int]::TryParse($parts[-1], [ref]$pidVal) -and $pidVal -gt 0) { $pids += $pidVal }
    }
  }
} catch { Add ('PORT_SCAN_WARNING=' + $_.Exception.Message) }
$pids = $pids | Sort-Object -Unique
if(-not $pids -or $pids.Count -eq 0) { Add 'PORT_STATUS=CLEAR'; Add 'RESULT: CLOSE DASHBOARD PASS'; exit 0 }
Add ('PORT_STATUS=ACTIVE :: PIDs ' + (($pids | ForEach-Object { [string]$_ }) -join ','))
$closed = 0
$skipped = 0
foreach($pid in $pids) {
  try { $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue } catch { $proc = $null }
  $cmd = if($proc) { [string]$proc.CommandLine } else { '' }
  $name = if($proc) { [string]$proc.Name } else { '' }
  Add ('PID_DETAIL=' + $pid + ' :: ' + $name + ' :: ' + $cmd)
  $looksBali = ($cmd -match 'app\.py' -or $cmd -match 'bali_rocket_crypto_command' -or $cmd -match [regex]::Escape($rootPath))
  if($looksBali -or $Force -eq 1) {
    try {
      Stop-Process -Id $pid -Force -ErrorAction Stop
      Add ('CLOSED_DASHBOARD_PID=' + $pid)
      $closed++
    } catch {
      Add ('CLOSE_WARNING_PID_' + $pid + '=' + $_.Exception.Message)
      $skipped++
    }
  } else {
    Add ('SKIPPED_NON_BALI_PID=' + $pid)
    $skipped++
  }
}
Start-Sleep -Seconds 2
try {
  $still = netstat -ano | Select-String (':' + $Port)
  if($still) { Add 'PORT_STATUS_AFTER_CLOSE=STILL_ACTIVE' } else { Add 'PORT_STATUS_AFTER_CLOSE=CLEAR' }
} catch {}
Add ('Closed count: ' + $closed)
Add ('Skipped/warning count: ' + $skipped)
if($skipped -gt 0) { Add 'RESULT: CLOSE DASHBOARD WARNING'; exit 1 }
Add 'RESULT: CLOSE DASHBOARD PASS'
exit 0
