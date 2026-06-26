param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$Report = '',
  [int]$Port = 9061,
  [int]$Force = 1,
  [int]$MaxWaitSeconds = 10
)
$ErrorActionPreference = 'Continue'
$rootPath = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
$logs = Join-Path $rootPath 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
if([string]::IsNullOrWhiteSpace($Report)) { $Report = Join-Path $logs 'BALI_CLOSE_DASHBOARD_PORT_REPORT_V012A.txt' }
function Add([string]$s='') { Add-Content -LiteralPath $Report -Value $s -Encoding ASCII }
function Get-ListenPids {
  param([int]$PortNum)
  $ids = @()
  try {
    $conns = Get-NetTCPConnection -LocalPort $PortNum -State Listen -ErrorAction SilentlyContinue
    foreach($c in $conns) { if($c.OwningProcess -and $c.OwningProcess -gt 0) { $ids += [int]$c.OwningProcess } }
  } catch {}
  if(-not $ids -or $ids.Count -eq 0) {
    try {
      $rows = netstat -ano -p tcp | Select-String (':' + $PortNum)
      foreach($r in $rows) {
        $parts = ($r.Line.Trim() -split '\s+')
        if($parts.Count -ge 5 -and $parts[1] -match (':' + $PortNum + '$') -and $parts[3] -eq 'LISTENING') {
          $pidVal = 0
          if([int]::TryParse($parts[-1], [ref]$pidVal) -and $pidVal -gt 0) { $ids += $pidVal }
        }
      }
    } catch {}
  }
  return @($ids | Sort-Object -Unique)
}
function Get-AnyPortRows {
  param([int]$PortNum)
  try { return @(netstat -ano -p tcp | Select-String (':' + $PortNum) | ForEach-Object { $_.Line.Trim() }) } catch { return @() }
}
Set-Content -LiteralPath $Report -Value @(
  'BALI CLOSE PREVIOUS DASHBOARD REPORT V012A',
  ('Generated: ' + (Get-Date)),
  ('Root folder: ' + $rootPath),
  ('Port: ' + $Port),
  'Purpose: close the previous Bali dashboard listener before update/restart so only one server owns port 9061.',
  'Mode: listener-only close guard. Browser ESTABLISHED rows do not count as dashboard still active.',
  'Safety: live orders OFF, champion lock LOCKED, no API keys.',
  ''
) -Encoding ASCII
$listenerPids = @(Get-ListenPids -PortNum $Port)
$anyRowsBefore = @(Get-AnyPortRows -PortNum $Port)
if(-not $listenerPids -or $listenerPids.Count -eq 0) {
  Add 'LISTENER_STATUS=CLEAR'
  if($anyRowsBefore.Count -gt 0) { Add ('NON_LISTENER_CONNECTIONS_PRESENT=YES_OK :: ' + $anyRowsBefore.Count) } else { Add 'PORT_STATUS=CLEAR' }
  Add 'Closed count: 0'
  Add 'RESULT: CLOSE DASHBOARD PASS'
  exit 0
}
Add ('LISTENER_STATUS=ACTIVE :: PIDs ' + (($listenerPids | ForEach-Object { [string]$_ }) -join ','))
$closed = 0
$warnings = 0
foreach($pid in $listenerPids) {
  try { $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue } catch { $proc = $null }
  $cmd = if($proc) { [string]$proc.CommandLine } else { '' }
  $name = if($proc) { [string]$proc.Name } else { '' }
  Add ('LISTENER_PID_DETAIL=' + $pid + ' :: ' + $name + ' :: ' + $cmd)
  $looksBali = ($cmd -match 'app\.py' -or $cmd -match 'bali_rocket_crypto_command' -or $cmd -match [regex]::Escape($rootPath) -or $name -match 'python')
  if($looksBali -or $Force -eq 1) {
    try {
      Stop-Process -Id $pid -Force -ErrorAction Stop
      Add ('STOP_PROCESS_SENT=' + $pid)
    } catch {
      Add ('STOP_PROCESS_WARNING_PID_' + $pid + '=' + $_.Exception.Message)
      try {
        & taskkill.exe /PID $pid /F /T | Out-Null
        Add ('TASKKILL_SENT=' + $pid)
      } catch {
        Add ('TASKKILL_WARNING_PID_' + $pid + '=' + $_.Exception.Message)
        $warnings++
      }
    }
  } else {
    Add ('SKIPPED_NON_BALI_LISTENER_PID=' + $pid)
    $warnings++
  }
}
$deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
do {
  Start-Sleep -Milliseconds 500
  $remaining = @(Get-ListenPids -PortNum $Port)
} while($remaining.Count -gt 0 -and (Get-Date) -lt $deadline)
$remaining = @(Get-ListenPids -PortNum $Port)
foreach($pid in $listenerPids) { if(-not ($remaining -contains $pid)) { $closed++ } }
if($remaining.Count -eq 0) {
  Add 'LISTENER_STATUS_AFTER_CLOSE=CLEAR'
} else {
  Add ('LISTENER_STATUS_AFTER_CLOSE=STILL_LISTENING :: PIDs ' + (($remaining | ForEach-Object { [string]$_ }) -join ','))
}
$anyRowsAfter = @(Get-AnyPortRows -PortNum $Port)
if($anyRowsAfter.Count -gt 0) { Add ('NON_LISTENER_CONNECTIONS_AFTER_CLOSE=OK_OR_RESTARTED :: ' + $anyRowsAfter.Count) } else { Add 'PORT_STATUS_AFTER_CLOSE=CLEAR' }
Add ('Closed count: ' + $closed)
Add ('Warning count: ' + $warnings)
if($remaining.Count -gt 0) {
  Add 'RESULT: CLOSE DASHBOARD WARNING - LISTENER STILL ACTIVE'
  exit 2
}
Add 'RESULT: CLOSE DASHBOARD PASS'
exit 0
