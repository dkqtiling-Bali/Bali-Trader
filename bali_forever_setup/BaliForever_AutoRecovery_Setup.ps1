param(
    [string]$ProjectRoot = "",
    [bool]$MakeDesktopIcon = $true
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SetupScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SetupScriptDirResolved = (Resolve-Path -LiteralPath $SetupScriptDir).Path

function Write-Step {
    param([string]$Message)
    Write-Host "[BALI-FOREVER] $Message"
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Read-FileSafe {
    param([string]$Path)
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -gt 262144) {
            $bytes = $bytes[0..262143]
        }
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        try {
            return Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        }
        catch {
            return ""
        }
    }
}

function Test-PathInsideExcludedDirectory {
    param([string]$FullName)
    $lower = $FullName.ToLowerInvariant()
    $excluded = @(
        "\.git\",
        "\node_modules\",
        "\venv\",
        "\.venv\",
        "\__pycache__\",
        "\archive_launchers\",
        "\_bali_forever_recovery\",
        "\recovery_snapshot",
        "\old\",
        "\backup\"
    )
    foreach ($item in $excluded) {
        if ($lower -like "*$item*") { return $true }
    }
    return $false
}

function Test-SetupFileName {
    param([string]$Name)
    $setupNames = @(
        "START_BALI_ROCKET_SAFE.cmd",
        "RUN_BALI_FOREVER_SETUP.cmd",
        "BaliForever_AutoRecovery_Setup.ps1"
    )
    return ($setupNames -contains $Name)
}

function Get-StartupFiles {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return @() }
    $allowed = @(".cmd", ".bat", ".ps1")
    return @(
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $allowed -contains $_.Extension.ToLowerInvariant() } |
            Where-Object { -not (Test-PathInsideExcludedDirectory $_.FullName) } |
            Where-Object { -not (Test-SetupFileName $_.Name) }
    )
}

function Get-DirectoryScore {
    param([string]$Path)
    $score = 0
    $reasons = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return [pscustomobject]@{ Path = $Path; Score = -999; Reasons = "missing" }
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $leaf = (Split-Path -Leaf $resolved).ToLowerInvariant()
    $lowerPath = $resolved.ToLowerInvariant()
    $lowerSetup = $SetupScriptDirResolved.ToLowerInvariant()

    if ($lowerPath -eq $lowerSetup -or $lowerPath.StartsWith($lowerSetup + "\")) {
        $score -= 200
        $reasons.Add("is_setup_folder_penalty")
    }

    if ($leaf -match "bali") { $score += 35; $reasons.Add("dir:bali") }
    if ($leaf -match "rocket") { $score += 25; $reasons.Add("dir:rocket") }
    if ($leaf -match "crypto") { $score += 15; $reasons.Add("dir:crypto") }
    if ($leaf -match "command") { $score += 10; $reasons.Add("dir:command") }

    foreach ($d in @("core", "logs", "evidence", "dashboard")) {
        if (Test-Path -LiteralPath (Join-Path $resolved $d)) {
            $score += 8
            $reasons.Add("has:$d")
        }
    }

    $files = @(Get-StartupFiles -Path $resolved | Select-Object -First 80)
    if ($files.Count -gt 0) {
        $score += 15
        $reasons.Add("startup_files:$($files.Count)")
    }

    foreach ($file in ($files | Select-Object -First 20)) {
        $name = $file.Name.ToLowerInvariant()
        $text = (Read-FileSafe -Path $file.FullName).ToLowerInvariant()
        if ($name -match "forever") { $score += 18; $reasons.Add("file:forever") }
        if ($name -match "start|launch") { $score += 8; $reasons.Add("file:start") }
        if ($text -match "v015a_backtest_walk_forward_gate") { $score += 25; $reasons.Add("text:v015a") }
        if ($text -match "dashboard") { $score += 10; $reasons.Add("text:dashboard") }
        if ($text -match "paper shadow|papershadow|paper_shadow") { $score += 8; $reasons.Add("text:paper_shadow") }
        if ($text -match "candle harvester|candle_harvester|harvester") { $score += 6; $reasons.Add("text:harvester") }
        if ($text -match "universe scanner|universe_scanner|scanner") { $score += 6; $reasons.Add("text:scanner") }
        if ($text -match "backtest gate|backtest_gate|walk.forward") { $score += 6; $reasons.Add("text:backtest") }
    }

    return [pscustomobject]@{
        Path = $resolved
        Score = $score
        Reasons = ($reasons -join ";")
    }
}

function Find-AutoProjectRoot {
    param([string]$InitialPath)

    $paths = New-Object System.Collections.Generic.List[string]
    function Add-PathIfPresent {
        param([string]$P)
        if (-not [string]::IsNullOrWhiteSpace($P)) {
            try {
                if (Test-Path -LiteralPath $P -PathType Container) {
                    $resolved = (Resolve-Path -LiteralPath $P).Path
                    if (-not $paths.Contains($resolved)) { $paths.Add($resolved) }
                }
            }
            catch { }
        }
    }

    Add-PathIfPresent $InitialPath
    Add-PathIfPresent $SetupScriptDirResolved
    Add-PathIfPresent (Split-Path -Parent $SetupScriptDirResolved)
    Add-PathIfPresent (Split-Path -Parent (Split-Path -Parent $SetupScriptDirResolved))

    $desktop = [Environment]::GetFolderPath("Desktop")
    $documents = [Environment]::GetFolderPath("MyDocuments")
    $downloads = Join-Path $env:USERPROFILE "Downloads"
    $commonRoots = @($desktop, $documents, $downloads) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($base in $commonRoots) {
        if (Test-Path -LiteralPath $base -PathType Container) {
            Add-PathIfPresent $base
            try {
                Get-ChildItem -LiteralPath $base -Directory -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match "bali|rocket|crypto|command" } |
                    Where-Object { $_.FullName.ToLowerInvariant() -notlike ($SetupScriptDirResolved.ToLowerInvariant() + "*") } |
                    Select-Object -First 120 |
                    ForEach-Object { Add-PathIfPresent $_.FullName }
            }
            catch { }
        }
    }

    $ranked = @()
    foreach ($p in $paths) {
        $ranked += Get-DirectoryScore -Path $p
    }

    return ($ranked |
        Sort-Object -Property @{Expression = "Score"; Descending = $true}, @{Expression = "Path"; Descending = $false} |
        Select-Object -First 1)
}

function Get-CandidateScore {
    param(
        [System.IO.FileInfo]$File,
        [string]$Content
    )

    $name = $File.Name.ToLowerInvariant()
    $path = $File.FullName.ToLowerInvariant()
    $text = $Content.ToLowerInvariant()
    $score = 0
    $reasons = New-Object System.Collections.Generic.List[string]
    $unsafe = New-Object System.Collections.Generic.List[string]

    if ($name -match "forever") { $score += 120; $reasons.Add("name:forever") }
    if ($name -match "original") { $score += 30; $reasons.Add("name:original") }
    if ($name -match "safe") { $score += 25; $reasons.Add("name:safe") }
    if ($name -match "start") { $score += 20; $reasons.Add("name:start") }
    if ($name -match "launcher|launch") { $score += 10; $reasons.Add("name:launch") }
    if ($name -match "supervisor") { $score -= 20; $reasons.Add("name:supervisor_penalty") }
    if ($name -match "validator|update.?dock|zip") { $score -= 100; $reasons.Add("name:validator_penalty") }
    if ($path -match "archive|legacy|old|backup") { $score -= 80; $reasons.Add("path:archive_penalty") }

    if ($text -match "v015a_backtest_walk_forward_gate") { $score += 45; $reasons.Add("core:v015a") }
    if ($text -match "dashboard") { $score += 25; $reasons.Add("component:dashboard") }
    if ($text -match "paper shadow|papershadow|paper_shadow") { $score += 20; $reasons.Add("component:paper_shadow") }
    if ($text -match "candle harvester|candle_harvester|harvester") { $score += 15; $reasons.Add("component:candle_harvester") }
    if ($text -match "universe scanner|universe_scanner|scanner") { $score += 15; $reasons.Add("component:universe_scanner") }
    if ($text -match "backtest gate|backtest_gate|walk.forward") { $score += 15; $reasons.Add("component:backtest_gate") }

    if ($text -match "update.?dock") { $score -= 60; $reasons.Add("content:update_dock_penalty") }
    if ($text -match "zip.?validator|validator") { $score -= 50; $reasons.Add("content:validator_penalty") }
    if ($text -match "autopatch|auto.?patch|patcher") { $score -= 50; $reasons.Add("content:patcher_penalty") }

    $unsafePatterns = @(
        @{ Name = "live_orders_on"; Pattern = "live[_ -]?orders\s*(=|:)\s*(on|true|1|yes)" },
        @{ Name = "enable_live_orders"; Pattern = "enable[_ -]?live[_ -]?orders|live[_ -]?trading\s*(=|:)\s*(on|true|1|yes)" },
        @{ Name = "champion_unlock"; Pattern = "champion.*unlock|unlock.*champion|champion[_ -]?claim[_ -]?allowed\s*(=|:)\s*(true|1|yes)" },
        @{ Name = "api_key_assignment"; Pattern = 'api[_ -]?key\s*=\s*[^\s"'']+' },
        @{ Name = "secret_assignment"; Pattern = 'secret[_ -]?key\s*=\s*[^\s"'']+' },
        @{ Name = "private_endpoint"; Pattern = "private[_ -]?endpoint|broker[_ -]?endpoint|exchange[_ -]?endpoint" },
        @{ Name = "real_order"; Pattern = "real[_ -]?order|place[_ -]?order|submit[_ -]?order" }
    )

    foreach ($p in $unsafePatterns) {
        if ($text -match $p.Pattern) {
            $unsafe.Add($p.Name)
            $score -= 1000
        }
    }

    return [pscustomobject]@{
        FullName = $File.FullName
        Name = $File.Name
        Length = $File.Length
        LastWriteTime = $File.LastWriteTime
        Score = $score
        UnsafeHits = ($unsafe -join ";")
        Reasons = ($reasons -join ";")
    }
}

function New-ForeverIcon {
    param([string]$IconPath)
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $bmp = New-Object System.Drawing.Bitmap -ArgumentList 256, 256
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $bgColor = [System.Drawing.Color]::FromArgb(22, 18, 36)
        $ringColor = [System.Drawing.Color]::FromArgb(145, 105, 255)
        $goldColor = [System.Drawing.Color]::FromArgb(255, 209, 102)
        $bg = New-Object System.Drawing.SolidBrush -ArgumentList $bgColor
        $ring = New-Object System.Drawing.Pen -ArgumentList $ringColor, 14
        $gold = New-Object System.Drawing.SolidBrush -ArgumentList $goldColor
        $white = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::White)
        $g.FillRectangle($bg, 0, 0, 256, 256)
        $g.DrawEllipse($ring, 26, 26, 204, 204)
        $fontBig = New-Object System.Drawing.Font -ArgumentList "Arial", 50, ([System.Drawing.FontStyle]::Bold)
        $fontSmall = New-Object System.Drawing.Font -ArgumentList "Arial", 23, ([System.Drawing.FontStyle]::Bold)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = [System.Drawing.StringAlignment]::Center
        $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
        $rectBig = New-Object System.Drawing.RectangleF -ArgumentList 0, 74, 256, 70
        $rectSmall = New-Object System.Drawing.RectangleF -ArgumentList 0, 139, 256, 44
        $g.DrawString("BALI", $fontBig, $gold, $rectBig, $fmt)
        $g.DrawString("FOREVER", $fontSmall, $white, $rectSmall, $fmt)
        $handle = $bmp.GetHicon()
        $icon = [System.Drawing.Icon]::FromHandle($handle)
        $fs = [System.IO.File]::Open($IconPath, [System.IO.FileMode]::Create)
        $icon.Save($fs)
        $fs.Close()
        $fmt.Dispose()
        $fontBig.Dispose()
        $fontSmall.Dispose()
        $bg.Dispose()
        $ring.Dispose()
        $gold.Dispose()
        $white.Dispose()
        $g.Dispose()
        $bmp.Dispose()
        return $true
    }
    catch {
        Write-Step "Icon drawing failed, shortcut will use the default command icon. $($_.Exception.Message)"
        return $false
    }
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Get-Location).Path
}

try {
    $initialRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
catch {
    throw "ProjectRoot does not exist: $ProjectRoot"
}

$initialScore = Get-DirectoryScore -Path $initialRoot
if ($initialScore.Score -lt 25) {
    Write-Step "The current folder does not look like the Bali Rocket project root. Auto-locating from Desktop, Documents, and Downloads..."
    $autoRoot = Find-AutoProjectRoot -InitialPath $initialRoot
    if ($null -eq $autoRoot -or $autoRoot.Score -lt 25) {
        throw "Could not auto-locate the Bali Rocket project root. Move this setup pack into the Bali project root, or drag the Bali project folder onto RUN_BALI_FOREVER_SETUP.cmd. No files were patched or unlocked."
    }
    $root = $autoRoot.Path
    Write-Step "Auto-selected project root: $root"
    Write-Step "Auto-select reasons: $($autoRoot.Reasons)"
}
else {
    $root = $initialScore.Path
    Write-Step "Project root: $root"
    Write-Step "Root check reasons: $($initialScore.Reasons)"
}

$recoveryRoot = Join-Path $root "_BALI_FOREVER_RECOVERY"
$logsRoot = Join-Path $recoveryRoot "logs"
$auditRoot = Join-Path $recoveryRoot "audit"
$iconRoot = Join-Path $recoveryRoot "icon"
Ensure-Directory $recoveryRoot
Ensure-Directory $logsRoot
Ensure-Directory $auditRoot
Ensure-Directory $iconRoot
Ensure-Directory (Join-Path $root "archive_launchers")

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$auditCsv = Join-Path $auditRoot "startup_candidates_$stamp.csv"
$auditTxt = Join-Path $auditRoot "startup_audit_$stamp.txt"

Write-Step "Scanning startup candidates read-only..."
$files = @(Get-StartupFiles -Path $root)

$candidates = New-Object System.Collections.Generic.List[object]
foreach ($file in $files) {
    $content = Read-FileSafe -Path $file.FullName
    $candidate = Get-CandidateScore -File $file -Content $content
    $candidates.Add($candidate)
}

$candidates |
    Sort-Object -Property @{Expression = "Score"; Descending = $true}, @{Expression = "LastWriteTime"; Descending = $true} |
    Export-Csv -NoTypeInformation -Path $auditCsv

$selected = $candidates |
    Where-Object { $_.UnsafeHits -eq "" -and $_.Score -gt 0 } |
    Sort-Object -Property @{Expression = "Score"; Descending = $true}, @{Expression = "LastWriteTime"; Descending = $true} |
    Select-Object -First 1

$reportLines = New-Object System.Collections.Generic.List[string]
$reportLines.Add("Bali Rocket Forever Startup Audit")
$reportLines.Add("Generated: $(Get-Date -Format s)")
$reportLines.Add("ProjectRoot: $root")
$reportLines.Add("")
$reportLines.Add("Safety baseline enforced by wrapper:")
$reportLines.Add("- LIVE_ORDERS=OFF")
$reportLines.Add("- BALI_LIVE_ORDERS=OFF")
$reportLines.Add("- CHAMPION_CLAIM_ALLOWED=False")
$reportLines.Add("- BALI_CHAMPION_UNLOCK=False")
$reportLines.Add("- API/secret environment variables cleared inside launcher process")
$reportLines.Add("")
$reportLines.Add("Audit CSV: $auditCsv")
$reportLines.Add("")

if ($null -ne $selected) {
    $reportLines.Add("Selected startup target:")
    $reportLines.Add($selected.FullName)
    $reportLines.Add("Score: $($selected.Score)")
    $reportLines.Add("Reasons: $($selected.Reasons)")
}
else {
    $reportLines.Add("Selected startup target: NONE")
    $reportLines.Add("Reason: No non-unsafe startup candidate scored above zero.")
    $reportLines.Add("The generated desktop launcher will open visibly and stop safely.")
}

$reportLines.Add("")
$reportLines.Add("Top candidates:")
foreach ($c in ($candidates |
    Sort-Object -Property @{Expression = "Score"; Descending = $true}, @{Expression = "LastWriteTime"; Descending = $true} |
    Select-Object -First 20)) {
    $reportLines.Add("Score=$($c.Score) Unsafe=[$($c.UnsafeHits)] File=$($c.FullName)")
    if ($c.Reasons) { $reportLines.Add("  Reasons=$($c.Reasons)") }
}

Set-Content -LiteralPath $auditTxt -Value $reportLines -Encoding UTF8
Write-Step "Audit written: $auditTxt"

$safeCmd = Join-Path $root "START_BALI_ROCKET_SAFE.cmd"
$selectedPath = if ($null -ne $selected) { $selected.FullName } else { "" }
$selectedExt = if ($selectedPath) { [System.IO.Path]::GetExtension($selectedPath).ToLowerInvariant() } else { "" }
$logRel = "_BALI_FOREVER_RECOVERY\logs"
$targetLine = $selectedPath.Replace("%", "%%")

$cmdLines = @()
$cmdLines += '@echo off'
$cmdLines += 'setlocal EnableExtensions'
$cmdLines += 'cd /d "%~dp0"'
$cmdLines += 'set "BALI_MODE=SAFE_PUBLIC_RESEARCH"'
$cmdLines += 'set "BALI_LIVE_ORDERS=OFF"'
$cmdLines += 'set "LIVE_ORDERS=OFF"'
$cmdLines += 'set "CHAMPION_CLAIM_ALLOWED=False"'
$cmdLines += 'set "BALI_CHAMPION_UNLOCK=False"'
$cmdLines += 'set "API_KEY="'
$cmdLines += 'set "SECRET_KEY="'
$cmdLines += 'set "EXCHANGE_API_KEY="'
$cmdLines += 'set "EXCHANGE_SECRET_KEY="'
$cmdLines += 'set "BROKER_API_KEY="'
$cmdLines += 'set "BROKER_SECRET_KEY="'
$cmdLines += 'if not exist "' + $logRel + '" mkdir "' + $logRel + '"'
$cmdLines += 'set "LOG=' + $logRel + '\forever_safe_start_%DATE:/=-%_%TIME::=-%.txt"'
$cmdLines += 'set "LOG=%LOG: =0%"'
$cmdLines += 'echo Bali Rocket Forever Safe Launcher'
$cmdLines += 'echo Started: %DATE% %TIME%'
$cmdLines += 'echo Safety: live orders OFF, Champion locked, no keys in launcher process.'
$cmdLines += 'echo.'
$cmdLines += 'echo Bali Rocket Forever Safe Launcher > "%LOG%"'
$cmdLines += 'echo Started: %DATE% %TIME% >> "%LOG%"'
$cmdLines += 'echo Safety: live orders OFF, Champion locked, no keys in launcher process. >> "%LOG%"'
if ($selectedPath) {
    $cmdLines += 'set "TARGET=' + $targetLine + '"'
    $cmdLines += 'echo Startup target: %TARGET%'
    $cmdLines += 'echo Startup target: %TARGET% >> "%LOG%"'
    $cmdLines += 'if not exist "%TARGET%" ('
    $cmdLines += '  echo ERROR: Startup target missing: %TARGET%'
    $cmdLines += '  echo ERROR: Startup target missing: %TARGET% >> "%LOG%"'
    $cmdLines += '  pause'
    $cmdLines += '  exit /b 2'
    $cmdLines += ')'
    if ($selectedExt -eq '.ps1') {
        $cmdLines += 'powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET%"'
    }
    else {
        $cmdLines += 'call "%TARGET%"'
    }
    $cmdLines += 'set "EXITCODE=%ERRORLEVEL%"'
    $cmdLines += 'echo.'
    $cmdLines += 'echo Target exited with code %EXITCODE%.'
    $cmdLines += 'echo Target exited with code %EXITCODE%. >> "%LOG%"'
    $cmdLines += 'echo Log: %LOG%'
    $cmdLines += 'pause'
    $cmdLines += 'exit /b %EXITCODE%'
}
else {
    $cmdLines += 'echo No safe startup target was selected.'
    $cmdLines += 'echo No safe startup target was selected. >> "%LOG%"'
    $cmdLines += 'echo Open the audit report here:'
    $cmdLines += 'echo ' + $auditTxt.Replace('%', '%%')
    $cmdLines += 'echo Open the audit report here: ' + $auditTxt.Replace('%', '%%') + ' >> "%LOG%"'
    $cmdLines += 'echo Nothing was patched. Live trading remains off.'
    $cmdLines += 'pause'
    $cmdLines += 'exit /b 3'
}

Set-Content -LiteralPath $safeCmd -Value $cmdLines -Encoding ASCII
Write-Step "Canonical safe launcher written: $safeCmd"

$readme = @"
# Bali Rocket Forever Safe Startup

This folder has been configured for one canonical startup path:

```text
START_BALI_ROCKET_SAFE.cmd
```

Use the desktop shortcut named:

```text
Bali Rocket Forever Safe
```

## Safety rules enforced by the wrapper

- Live orders remain OFF.
- Champion claim remains False.
- Champion unlock remains False.
- API and secret environment variables are cleared inside the launcher process.
- No private endpoints are added.
- No old launcher is patched.
- The selected target is called through one visible wrapper.
- The window stays open if the launcher exits or fails.

## Selected startup target

```text
$selectedPath
```

## Audit files

```text
$auditTxt
$auditCsv
```

## Current evidence status

Backtest/walk-forward evidence is not proven yet.
Champion claim allowed: False.
Live orders: OFF.

## Do not do this

- Do not run old Update Dock ZIP validators as install proof.
- Do not add another launcher layer.
- Do not patch launchers repeatedly.
- Do not unlock Champion.
- Do not add API keys.
- Do not enable live trading.
"@
Set-Content -LiteralPath (Join-Path $root "README_STARTUP.md") -Value $readme -Encoding UTF8
Write-Step "Startup README written: $(Join-Path $root "README_STARTUP.md")"

if ($MakeDesktopIcon) {
    $iconPath = Join-Path $iconRoot "BaliRocketForeverSafe.ico"
    $iconOk = New-ForeverIcon -IconPath $iconPath
    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktop "Bali Rocket Forever Safe.lnk"
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $safeCmd
        $shortcut.WorkingDirectory = $root
        $shortcut.Description = "Bali Rocket Forever Safe Launcher - live orders off"
        if ($iconOk -and (Test-Path -LiteralPath $iconPath)) {
            $shortcut.IconLocation = "$iconPath,0"
        }
        $shortcut.Save()
        Write-Step "Desktop shortcut written: $shortcutPath"
    }
    catch {
        Write-Step "Desktop shortcut creation failed: $($_.Exception.Message)"
        Write-Step "You can still run: $safeCmd"
    }
}

Write-Host ""
Write-Step "Done. Start Bali from the desktop shortcut or START_BALI_ROCKET_SAFE.cmd only."
Write-Step "Audit report: $auditTxt"
if ($null -eq $selected) {
    Write-Step "No safe target was selected. Review the audit before starting."
}
