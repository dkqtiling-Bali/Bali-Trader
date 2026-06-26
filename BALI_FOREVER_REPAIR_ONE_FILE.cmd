@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Bali Rocket Forever - One File Repair
set "BALI_REPAIR_ROOT=%CD%"
set "BALI_REPAIR_SELF=%~f0"
echo.
echo ============================================================
echo  BALI ROCKET FOREVER - ONE FILE REPAIR
echo ============================================================
echo.
echo This file will auto-find the Bali project if possible, create one
echo safe launcher, create/refresh the Forever desktop icon, and start Bali.
echo.
echo It will NOT enable live orders, add API keys, unlock Champion,
echo use private endpoints, or process update ZIPs.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$src=$env:BALI_REPAIR_SELF; $root=$env:BALI_REPAIR_ROOT; $raw=[IO.File]::ReadAllText($src); $marker='### POWERSHELL_PAYLOAD_BELOW ###'; $i=$raw.IndexOf($marker); if($i -lt 0){Write-Host 'Payload marker missing'; exit 9}; $script=$raw.Substring($i+$marker.Length); $tmp=Join-Path $env:TEMP ('bali_forever_repair_'+[guid]::NewGuid().ToString()+'.ps1'); [IO.File]::WriteAllText($tmp,$script,[Text.UTF8Encoding]::new($false)); & $tmp -Root $root; $rc=$LASTEXITCODE; Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue; exit $rc"
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo DONE. From now on use the desktop icon: Bali Rocket Forever Safe
) else (
  echo FAILED. Check the visible report under _BALI_FOREVER_RECOVERY if a project was found.
)
echo.
pause
exit /b %RC%
### POWERSHELL_PAYLOAD_BELOW ###
param([string]$Root)
$ErrorActionPreference = 'Stop'

function Write-Line([string]$Path, [string]$Text) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Add-Content -LiteralPath $Path -Value $Text -Encoding UTF8
}

function Test-AppRoot([string]$P) {
  if (-not $P) { return $false }
  return (Test-Path -LiteralPath (Join-Path $P 'app.py')) -or (Test-Path -LiteralPath (Join-Path $P 'bali_rocket_crypto_command_v011b\app.py'))
}

function Resolve-BaliRoot([string]$Start) {
  $candidates = New-Object System.Collections.Generic.List[string]
  if ($Start) { $candidates.Add($Start) }
  foreach ($base in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('MyDocuments'), (Join-Path $env:USERPROFILE 'Downloads'))) {
    if ($base -and (Test-Path -LiteralPath $base)) { $candidates.Add($base) }
  }

  foreach ($c in $candidates) {
    if (Test-AppRoot $c) { return (Resolve-Path -LiteralPath $c).Path.TrimEnd('\') }
  }

  foreach ($base in $candidates) {
    try {
      $dirs = Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'BALI|ROCKET|CRYPTO|COMMAND|FOREVER|V011|HOTFIX' }
      foreach ($d in $dirs) {
        if (Test-AppRoot $d.FullName) { return $d.FullName.TrimEnd('\') }
        $kids = Get-ChildItem -LiteralPath $d.FullName -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -match 'bali|rocket|crypto|command|forever|v011|hotfix' }
        foreach ($k in $kids) { if (Test-AppRoot $k.FullName) { return $k.FullName.TrimEnd('\') } }
      }
    } catch {}
  }
  return $null
}

function Resolve-AppRoot([string]$ProjectRoot) {
  if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'app.py')) { return $ProjectRoot }
  $child = Join-Path $ProjectRoot 'bali_rocket_crypto_command_v011b'
  if (Test-Path -LiteralPath (Join-Path $child 'app.py')) { return $child }
  $dirs = Get-ChildItem -LiteralPath $ProjectRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'bali_rocket_crypto_command|BALI_ROCKET' }
  foreach ($d in $dirs) { if (Test-Path -LiteralPath (Join-Path $d.FullName 'app.py')) { return $d.FullName } }
  return $null
}

function Set-JsonProp($Obj, [string]$Name, $Value) {
  if ($null -eq $Obj.PSObject.Properties[$Name]) { $Obj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force }
  else { $Obj.$Name = $Value }
}

function Repair-SystemState([string]$AppRoot, [string]$Log) {
  $shared = Join-Path $AppRoot 'shared_data'
  $path = Join-Path $shared 'system_state.json'
  if (-not (Test-Path -LiteralPath $shared)) { New-Item -ItemType Directory -Path $shared -Force | Out-Null }
  try {
    if (Test-Path -LiteralPath $path) {
      $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
      if ($raw.Trim().Length -gt 0) { $state = $raw | ConvertFrom-Json } else { $state = New-Object PSObject }
    } else { $state = New-Object PSObject }
  } catch {
    Copy-Item -LiteralPath $path -Destination ($path + '.bad_json_' + (Get-Date -Format yyyyMMdd_HHmmss) + '.bak') -Force -ErrorAction SilentlyContinue
    $state = New-Object PSObject
  }
  Set-JsonProp $state 'live_orders' 'OFF'
  Set-JsonProp $state 'champion_lock' 'LOCKED'
  Set-JsonProp $state 'approved_champions' '0/3'
  Set-JsonProp $state 'champion_claim_allowed' $false
  Set-JsonProp $state 'champion_proof_gate' 'LOCKED_BACKTEST_REQUIRED'
  Set-JsonProp $state 'mode' 'PUBLIC_DATA_RESEARCH_ONLY'
  Set-JsonProp $state 'api_keys_present' $false
  Set-JsonProp $state 'private_endpoints_enabled' $false
  Set-JsonProp $state 'recovery_launcher' 'BALI_FOREVER_ONE_FILE_REPAIR'
  Set-JsonProp $state 'recovery_updated_at' (Get-Date).ToString('s')
  $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path -Encoding UTF8
  Write-Line $Log "SYSTEM_STATE_SAFE=$path"
}

function Write-FileAscii([string]$Path, [string[]]$Lines) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Set-Content -LiteralPath $Path -Value $Lines -Encoding ASCII
}

function Create-SafeLaunchers([string]$ProjectRoot, [string]$Log) {
  $safe = Join-Path $ProjectRoot 'START_BALI_ROCKET_SAFE.cmd'
  Write-FileAscii $safe @(
    '@echo off',
    'setlocal EnableExtensions',
    'cd /d "%~dp0"',
    'title Bali Rocket Forever Safe',
    'set "LIVE_ORDERS=OFF"',
    'set "BALI_LIVE_ORDERS=OFF"',
    'set "CHAMPION_CLAIM_ALLOWED=FALSE"',
    'set "BALI_CHAMPION_LOCK=LOCKED"',
    'set "BALI_PUBLIC_DATA_ONLY=1"',
    'set "BINANCE_API_KEY="',
    'set "BINANCE_SECRET="',
    'set "API_KEY="',
    'set "API_SECRET="',
    'set "SECRET_KEY="',
    'set "PRIVATE_KEY="',
    'set "EXCHANGE_PRIVATE_KEY="',
    'if exist "%~dp0BALI_THEMED_FOREVER_STARTER_ORIGINAL_V037.bat" call "%~dp0BALI_THEMED_FOREVER_STARTER_ORIGINAL_V037.bat" & goto :done',
    'if exist "%~dp0BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat" call "%~dp0BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat" & goto :done',
    'if exist "%~dp0BALI_THEMED_FOREVER_STARTER_PRE_V031_BACKUP.bat" call "%~dp0BALI_THEMED_FOREVER_STARTER_PRE_V031_BACKUP.bat" & goto :done',
    'if exist "%~dp0ROCKET_CRYPTO_COMMAND_START.bat" call "%~dp0ROCKET_CRYPTO_COMMAND_START.bat" & goto :done',
    'echo No original Forever starter found. Trying direct local app.py startup...',
    'if exist "%~dp0app.py" (python "%~dp0app.py" & goto :done)',
    'if exist "%~dp0bali_rocket_crypto_command_v011b\app.py" (cd /d "%~dp0bali_rocket_crypto_command_v011b" & python app.py & goto :done)',
    'echo FAILED: no safe startup target found.',
    'pause',
    'exit /b 7',
    ':done',
    'exit /b %ERRORLEVEL%'
  )

  $one = Join-Path $ProjectRoot 'BALI_FOREVER_ONE_CLICK_FROM_HERE.cmd'
  Write-FileAscii $one @(
    '@echo off',
    'setlocal EnableExtensions',
    'cd /d "%~dp0"',
    'title Bali Rocket Forever One Click From Here',
    'echo Bali Rocket Forever Safe',
    'echo Live orders OFF. Champion locked. Public-data only.',
    'echo.',
    'call "%~dp0START_BALI_ROCKET_SAFE.cmd"',
    'set "RC=%ERRORLEVEL%"',
    'echo.',
    'if "%RC%"=="0" (echo DONE. From now on use the desktop icon: Bali Rocket Forever Safe) else (echo FAILED. Check _BALI_FOREVER_RECOVERY.)',
    'pause',
    'exit /b %RC%'
  )
  Write-Line $Log "SAFE_LAUNCHERS_CREATED=$safe ; $one"
}

function Redirect-OldLaunchers([string]$ProjectRoot, [string]$Log) {
  $names = @('BALI START HERE - ONE CLICK.bat','BALI_THEMED_FOREVER_STARTER.bat','BALI_ROCKET_FOREVER_STARTER.bat','Bali Supervisor Mission Control.bat','BALI_CREATE_FOREVER_DESKTOP_ICON.bat')
  $backupDir = Join-Path $ProjectRoot '_BALI_FOREVER_RECOVERY\legacy_launcher_backups'
  if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
  foreach ($n in $names) {
    $p = Join-Path $ProjectRoot $n
    if (Test-Path -LiteralPath $p) {
      $safeName = ($n -replace '[\\/:*?"<>|]', '_')
      $backup = Join-Path $backupDir ($safeName + '.before_one_file_repair.bak')
      if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $p -Destination $backup -Force }
      Write-FileAscii $p @(
        '@echo off',
        'setlocal EnableExtensions',
        'cd /d "%~dp0"',
        'echo Bali Rocket Forever Safe redirect',
        'call "%~dp0START_BALI_ROCKET_SAFE.cmd"',
        'exit /b %ERRORLEVEL%'
      )
      Write-Line $Log "REDIRECTED=$n BACKUP=$backup"
    }
  }
}

function Find-Icon([string]$ProjectRoot) {
  $assets = Join-Path $ProjectRoot 'assets'
  if (Test-Path -LiteralPath $assets) {
    $icons = Get-ChildItem -LiteralPath $assets -File -Filter '*.ico' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending, Name
    foreach ($ico in $icons) { if ($ico.Name -match 'FOREVER|ROCKET|BALI') { return $ico.FullName } }
    if ($icons.Count -gt 0) { return $icons[0].FullName }
  }
  return "$env:SystemRoot\System32\shell32.dll,43"
}

function Create-Shortcut([string]$ProjectRoot, [string]$Log) {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $lnk = Join-Path $desktop 'Bali Rocket Forever Safe.lnk'
  $target = Join-Path $ProjectRoot 'START_BALI_ROCKET_SAFE.cmd'
  $shell = New-Object -ComObject WScript.Shell
  $sc = $shell.CreateShortcut($lnk)
  $sc.TargetPath = $target
  $sc.WorkingDirectory = $ProjectRoot
  $sc.Description = 'Bali Rocket Forever Safe - local public-data startup only'
  $sc.IconLocation = Find-Icon $ProjectRoot
  $sc.Save()
  Write-Line $Log "DESKTOP_SHORTCUT=$lnk"
}

function Start-Safe([string]$ProjectRoot, [string]$Log) {
  $env:LIVE_ORDERS = 'OFF'
  $env:BALI_LIVE_ORDERS = 'OFF'
  $env:CHAMPION_CLAIM_ALLOWED = 'FALSE'
  $env:BALI_CHAMPION_LOCK = 'LOCKED'
  $env:BALI_PUBLIC_DATA_ONLY = '1'
  $env:BINANCE_API_KEY = ''
  $env:BINANCE_SECRET = ''
  $env:API_KEY = ''
  $env:API_SECRET = ''
  $env:SECRET_KEY = ''
  $env:PRIVATE_KEY = ''
  $env:EXCHANGE_PRIVATE_KEY = ''
  $cmd = Join-Path $ProjectRoot 'START_BALI_ROCKET_SAFE.cmd'
  Start-Process -FilePath 'cmd.exe' -ArgumentList @('/k', ('"' + $cmd + '"')) -WorkingDirectory $ProjectRoot
  Start-Sleep -Seconds 2
  try { Start-Process 'http://127.0.0.1:9061' } catch {}
}

$projectRoot = Resolve-BaliRoot $Root
if (-not $projectRoot) {
  Write-Host 'Could not auto-find the Bali project folder.'
  Write-Host 'Put this file inside the extracted Bali project folder, then double-click it again.'
  exit 2
}

$recovery = Join-Path $projectRoot '_BALI_FOREVER_RECOVERY'
if (-not (Test-Path -LiteralPath $recovery)) { New-Item -ItemType Directory -Path $recovery -Force | Out-Null }
$log = Join-Path $recovery ('BALI_FOREVER_ONE_FILE_REPAIR_' + (Get-Date -Format yyyyMMdd_HHmmss) + '.txt')

try {
  Write-Line $log 'BALI FOREVER ONE FILE REPAIR'
  Write-Line $log "PROJECT_ROOT=$projectRoot"
  Write-Line $log 'SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCKED | NO_API_KEYS | PUBLIC_DATA_ONLY'
  Write-Line $log 'UPDATE_ZIP_PROCESSING=DISABLED'
  $appRoot = Resolve-AppRoot $projectRoot
  if (-not $appRoot) { throw 'app.py not found in project root or bali_rocket_crypto_command_v011b child folder.' }
  Write-Line $log "APP_ROOT=$appRoot"
  Repair-SystemState $appRoot $log
  Create-SafeLaunchers $projectRoot $log
  Redirect-OldLaunchers $projectRoot $log
  Create-Shortcut $projectRoot $log
  Write-Line $log 'RESULT=PASS_REPAIR_APPLIED'
  Start-Safe $projectRoot $log
  Write-Host 'Repair applied and Bali Rocket Forever Safe started.'
  Write-Host "Report: $log"
  exit 0
} catch {
  Write-Line $log ('ERROR=' + $_.Exception.Message)
  Write-Line $log 'RESULT=FAIL_VISIBLE'
  Write-Host 'BALI FOREVER ONE FILE REPAIR FAILED'
  Write-Host $_.Exception.Message
  Write-Host "Report: $log"
  try { Start-Process notepad.exe $log } catch {}
  exit 1
}
