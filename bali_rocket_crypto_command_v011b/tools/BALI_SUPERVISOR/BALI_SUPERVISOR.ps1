$ErrorActionPreference = "Continue"
$Base = "C:\Users\CB\Desktop\BALI_ROCKET_CRYPTO_COMMAND_V011B_BAD_PYTHON_HOTFIX_FULL_BUILD"
$App = Join-Path $Base "bali_rocket_crypto_command_v011b"
$Updates = Join-Path $Base "updates"
$Applied = Join-Path $Updates "APPLIED"
$Quarantine = Join-Path $Updates "QUARANTINE"
$Reports = Join-Path $App "shared_data\reports"
$Tools = Join-Path $App "tools\BALI_SUPERVISOR"
$Report = Join-Path $Reports "BALI_SUPERVISOR_LATEST_REPORT.txt"
$JsonReport = Join-Path $Reports "BALI_SUPERVISOR_LATEST_REPORT.json"
$Transcript = Join-Path $Reports "BALI_SUPERVISOR_TRANSCRIPT.txt"
$TempRoot = Join-Path $env:TEMP ("BALI_SUPERVISOR_PATCH_" + [System.DateTime]::Now.ToString("yyyyMMdd_HHmmss_fff"))

New-Item -ItemType Directory -Force -Path $Updates, $Applied, $Quarantine, $Reports, $Tools | Out-Null
Start-Transcript -Path $Transcript -Force | Out-Null

function Write-Line($text) { Add-Content -Path $Report -Value $text }
function Safe-Move($src, $dstFolder) {
  New-Item -ItemType Directory -Force -Path $dstFolder | Out-Null
  $name = Split-Path $src -Leaf
  $dst = Join-Path $dstFolder $name
  if (Test-Path $dst) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dst = Join-Path $dstFolder ($stamp + "_" + $name)
  }
  Move-Item -LiteralPath $src -Destination $dst -Force
  return $dst
}

if (Test-Path $Report) { Remove-Item $Report -Force }
Write-Line "BALI SUPERVISOR LATEST REPORT"
Write-Line ("Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"))
Write-Line "SAFETY=LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"
Write-Line "VERSION=V039_BALI_SUPERVISOR_ONE_CLICK"
Write-Line "PYTHON_USED=NO"
Write-Line "UPDATE_DOCK_USED=NO"
Write-Line "MODE=EXTERNAL_SUPERVISOR_STABLE_LAUNCHER"
Write-Line "BASE=$Base"
Write-Line "APP=$App"
Write-Line "UPDATES=$Updates"
Write-Line "REPORTS=$Reports"

$PatchStatus = "NO_PATCH_WAITING"
$PatchName = ""
$PatchResult = ""
$MovedTo = ""

try {
  $zips = @(Get-ChildItem -LiteralPath $Updates -Filter *.zip -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)
  Write-Line ("ROOT_UPDATE_ZIP_COUNT=" + $zips.Count)
  $selected = $null
  foreach ($zip in $zips) {
    $list = & tar -tf $zip.FullName 2>$null
    $hasManifest = $false
    $hasInstaller = $false
    foreach ($entry in $list) {
      if ($entry -eq "BALI_AUTO_PATCH_MANIFEST.txt" -or $entry -like "*/BALI_AUTO_PATCH_MANIFEST.txt") { $hasManifest = $true }
      if ($entry -eq "AUTO_PATCH_INSTALL.bat" -or $entry -like "*/AUTO_PATCH_INSTALL.bat") { $hasInstaller = $true }
    }
    if ($hasManifest -and $hasInstaller) {
      $selected = $zip
      break
    } else {
      Write-Line ("SKIP_NON_AUTOPATCH_ZIP=" + $zip.FullName)
      $moved = Safe-Move $zip.FullName (Join-Path $Updates "LEGACY_SKIPPED")
      Write-Line ("MOVED_TO_LEGACY_SKIPPED=" + $moved)
    }
  }

  if ($selected -ne $null) {
    $PatchName = $selected.FullName
    Write-Line "PATCH_FOUND=$PatchName"
    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
    Expand-Archive -LiteralPath $selected.FullName -DestinationPath $TempRoot -Force
    $installer = Get-ChildItem -LiteralPath $TempRoot -Recurse -Filter "AUTO_PATCH_INSTALL.bat" -File | Select-Object -First 1
    if ($installer -eq $null) {
      Write-Line "PATCH_STATUS=QUARANTINE_NO_INSTALLER_AFTER_EXTRACT"
      $MovedTo = Safe-Move $selected.FullName $Quarantine
      $PatchStatus = "QUARANTINE_NO_INSTALLER_AFTER_EXTRACT"
    } else {
      Write-Line ("PATCH_INSTALLER=" + $installer.FullName)
      $psi = New-Object System.Diagnostics.ProcessStartInfo
      $psi.FileName = "cmd.exe"
      $psi.Arguments = "/c call `"" + $installer.FullName + "`" `"" + $App + "`" `"" + $Base + "`" `"" + $Reports + "`""
      $psi.WorkingDirectory = Split-Path $installer.FullName -Parent
      $psi.UseShellExecute = $false
      $psi.RedirectStandardOutput = $true
      $psi.RedirectStandardError = $true
      $p = [System.Diagnostics.Process]::Start($psi)
      $out = $p.StandardOutput.ReadToEnd()
      $err = $p.StandardError.ReadToEnd()
      $p.WaitForExit()
      Add-Content -Path $Report -Value $out
      if ($err.Trim().Length -gt 0) { Write-Line ("PATCH_STDERR=" + $err.Trim()) }
      Write-Line ("PATCH_EXIT_CODE=" + $p.ExitCode)
      if ($p.ExitCode -eq 0) {
        $MovedTo = Safe-Move $selected.FullName $Applied
        Write-Line "PATCH_STATUS=APPLIED"
        Write-Line "MOVED_TO_APPLIED=$MovedTo"
        $PatchStatus = "APPLIED"
        $PatchResult = "PASS_PATCH_APPLIED_BEFORE_BALI_START"
      } else {
        $MovedTo = Safe-Move $selected.FullName $Quarantine
        Write-Line "PATCH_STATUS=QUARANTINE_INSTALLER_FAILED"
        Write-Line "MOVED_TO_QUARANTINE=$MovedTo"
        $PatchStatus = "QUARANTINE_INSTALLER_FAILED"
        $PatchResult = "FAIL_PATCH_QUARANTINED_INSTALLER_FAILED"
      }
    }
  } else {
    Write-Line "PATCH_STATUS=NO_PATCH_WAITING"
    $PatchStatus = "NO_PATCH_WAITING"
    $PatchResult = "PASS_NO_PATCH_WAITING_BALI_STARTING"
  }
} catch {
  Write-Line ("SUPERVISOR_EXCEPTION=" + $_.Exception.Message)
  $PatchStatus = "SUPERVISOR_EXCEPTION"
  $PatchResult = "FAIL_SUPERVISOR_EXCEPTION"
}

$OriginalCandidates = @(
  (Join-Path $Base "BALI_THEMED_FOREVER_STARTER_ORIGINAL_V030.bat"),
  (Join-Path $Base "BALI_THEMED_FOREVER_STARTER_PRE_V031_BACKUP.bat"),
  (Join-Path $Base "BALI_THEMED_FOREVER_STARTER_BACKUP_BEFORE_V030_15860.bat")
)
$Original = $null
foreach ($c in $OriginalCandidates) { if (Test-Path $c) { $Original = $c; break } }
if ($Original -ne $null) {
  Write-Line "STARTING_ORIGINAL=$Original"
  Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$Original`"" -WorkingDirectory $Base -WindowStyle Minimized
  Start-Sleep -Seconds 2
  Start-Process "http://127.0.0.1:9061" | Out-Null
  Write-Line "DASHBOARD_OPEN_REQUESTED=http://127.0.0.1:9061"
} else {
  Write-Line "STARTING_ORIGINAL=NOT_FOUND"
  Write-Line "ACTION_REQUIRED=Restore original Bali starter backup"
}

Write-Line ("AUTOPATCH_RESULT=" + $PatchStatus)
Write-Line ("RESULT=" + $PatchResult)

$json = [ordered]@{
  generated = (Get-Date).ToString("o")
  safety = "LIVE_ORDERS_OFF | CHAMPION_LOCK_LOCKED | NO_API_KEYS"
  version = "V039_BALI_SUPERVISOR_ONE_CLICK"
  python_used = "NO"
  update_dock_used = "NO"
  base = $Base
  app = $App
  updates = $Updates
  patch_status = $PatchStatus
  patch = $PatchName
  moved_to = $MovedTo
  result = $PatchResult
}
$json | ConvertTo-Json -Depth 4 | Set-Content -Path $JsonReport -Encoding UTF8

Stop-Transcript | Out-Null
Start-Process notepad.exe $Report
