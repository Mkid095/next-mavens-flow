# ============================================================================
# Maven Flow Sync Script
# Syncs changes between global installation and project source
# ============================================================================

param(
    [ValidateSet("Pull", "Push", "Status", "Auto")]
    [string]$Direction = "Auto",

    [switch]$Force,
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Colors
$Cyan = "`e[36m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Red = "`e[31m"
$Gray = "`e[37m"
$Reset = "`e[0m"

function Print-Header {
    Write-Host ""
    Write-Host "${Cyan}╔════════════════════════════════════════════════════════════╗${Reset}"
    Write-Host "${Cyan}║              Maven Flow - Sync Manager                      ║${Reset}"
    Write-Host "${Cyan}╚════════════════════════════════════════════════════════════╝${Reset}"
    Write-Host ""
}

Print-Header

# Get paths
$BinDir = Split-Path -Parent $PSScriptRoot
$ProjectDir = Split-Path -Parent $BinDir
$GlobalBinDir = Join-Path $env:USERPROFILE ".claude\bin"

# Files to sync
$SyncFiles = @(
    "flow.ps1",
    "flow-prd.ps1",
    "flow-convert.ps1",
    "flow-update.ps1"
)

function Get-FileHash {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    }
    return $null
}

function Compare-Files {
    param(
        [string]$Source,
        [string]$Dest
    )

    $sourceHash = Get-FileHash -Path $Source
    $destHash = Get-FileHash -Path $Dest

    if ($null -eq $sourceHash) { return "SourceMissing" }
    if ($null -eq $destHash) { return "DestMissing" }
    if ($sourceHash -eq $destHash) { return "Same" }
    return "Different"
}

# Auto-detect direction
if ($Direction -eq "Auto") {
    Write-Host "${Blue}▶ Auto-detecting sync direction...${Reset}"
    Write-Host ""

    $globalNewer = 0
    $projectNewer = 0

    foreach ($file in $SyncFiles) {
        $globalPath = Join-Path $GlobalBinDir $file
        $projectPath = Join-Path $BinDir $file

        if (Test-Path $globalPath -and Test-Path $projectPath) {
            $globalTime = (Get-Item $globalPath).LastWriteTime
            $projectTime = (Get-Item $projectPath).LastWriteTime

            if ($globalTime -gt $projectTime) {
                $globalNewer++
                if ($Verbose) {
                    Write-Host "  ${Gray}Global is newer: ${Cyan}${file}${Reset} ($($globalTime.ToString('yyyy-MM-dd HH:mm:ss')))"
                }
            } elseif ($projectTime -gt $globalTime) {
                $projectNewer++
                if ($Verbose) {
                    Write-Host "  ${Gray}Project is newer: ${Cyan}${file}${Reset} ($($projectTime.ToString('yyyy-MM-dd HH:mm:ss')))"
                }
            }
        }
    }

    if ($globalNewer -gt $projectNewer) {
        $Direction = "Pull"
        Write-Host "  ${Yellow}→ Pull mode${Reset} (Global is newer)"
    } elseif ($projectNewer -gt $globalNewer) {
        $Direction = "Push"
        Write-Host "  ${Yellow}→ Push mode${Reset} (Project is newer)"
    } else {
        $Direction = "Status"
        Write-Host "  ${Green}→ Status mode${Reset} (Everything in sync)"
    }
    Write-Host ""
}

# Execute sync based on direction
switch ($Direction) {
    "Status" {
        Write-Host "${Blue}▶ Checking sync status...${Reset}"
        Write-Host ""

        $allSynced = $true
        foreach ($file in $SyncFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            switch ($status) {
                "Same" {
                    Write-Host "  ${Green}[✓]${Reset} ${Cyan}${file}${Reset} - In sync"
                }
                "SourceMissing" {
                    Write-Host "  ${Red}[!]${Reset} ${Cyan}${file}${Reset} - Missing in global"
                    $allSynced = $false
                }
                "DestMissing" {
                    Write-Host "  ${Red}[!]${Reset} ${Cyan}${file}${Reset} - Missing in project"
                    $allSynced = $false
                }
                "Different" {
                    Write-Host "  ${Yellow}[~]${Reset} ${Cyan}${file}${Reset} - Out of sync"
                    $allSynced = $false
                }
            }
        }

        Write-Host ""
        if ($allSynced) {
            Write-Host "${Green}All files are in sync!${Reset}"
        } else {
            Write-Host "${Yellow}Files are out of sync. Use: flow-sync pull|push${Reset}"
        }
    }

    "Pull" {
        Write-Host "${Blue}▶ Pulling from global to project...${Reset}"
        Write-Host ""

        foreach ($file in $SyncFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            if ($status -eq "Different" -or $status -eq "DestMissing" -or $Force) {
                if (Test-Path $globalPath) {
                    Copy-Item -Force $globalPath $projectPath
                    Write-Host "  ${Green}[✓]${Reset} ${Cyan}${file}${Reset} - Pulled from global"
                } else {
                    Write-Host "  ${Red}[!]${Reset} ${Cyan}${file}${Reset} - Not found in global"
                }
            } elseif ($status -eq "Same") {
                Write-Host "  ${Gray}[=]${Reset} ${Cyan}${file}${Reset} - Already in sync"
            }
        }

        Write-Host ""
        Write-Host "${Green}Pull complete!${Reset}"
    }

    "Push" {
        Write-Host "${Blue}▶ Pushing from project to global...${Reset}"
        Write-Host ""

        foreach ($file in $SyncFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            if ($status -eq "Different" -or $status -eq "SourceMissing" -or $Force) {
                if (Test-Path $projectPath) {
                    Copy-Item -Force $projectPath $globalPath
                    Write-Host "  ${Green}[✓]${Reset} ${Cyan}${file}${Reset} - Pushed to global"
                } else {
                    Write-Host "  ${Red}[!]${Reset} ${Cyan}${file}${Reset} - Not found in project"
                }
            } elseif ($status -eq "Same") {
                Write-Host "  ${Gray}[=]${Reset} ${Cyan}${file}${Reset} - Already in sync"
            }
        }

        Write-Host ""
        Write-Host "${Green}Push complete!${Reset}"
        Write-Host ""
        Write-Host "${Yellow}[!] Note: Restart terminal to use updated global scripts${Reset}"
    }
}

Write-Host ""
Write-Host "${Cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${Reset}"
