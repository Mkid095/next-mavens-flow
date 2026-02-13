#!/usr/bin/env pwsh
# ============================================================================
# Maven Flow Sync Script (Windows PowerShell)
# Syncs changes between global installation and project source
# ============================================================================

param(
    [ValidateSet("Pull", "Push", "Status", "Auto", "Help")]
    [string]$Direction = "Auto",

    [switch]$Force,
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Colors (using $([char]0x1b) for better compatibility)
$Esc = [char]0x1b
$Cyan = "${Esc}[36m"
$Green = "${Esc}[32m"
$Yellow = "${Esc}[33m"
$Blue = "${Esc}[34m"
$Red = "${Esc}[31m"
$Gray = "${Esc}[90m"
$Reset = "${Esc}[0m"

function Print-Header {
    Write-Host ""
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host "${Cyan}|              Maven Flow - Sync Manager                     |${Reset}"
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host ""
}

Print-Header

# Get paths - $PSScriptRoot is already the bin directory
$BinDir = $PSScriptRoot
$ProjectDir = Split-Path -Parent $BinDir
$GlobalBinDir = Join-Path $env:USERPROFILE ".claude\bin"

# Ensure global bin directory exists
if (-not (Test-Path $GlobalBinDir)) {
    New-Item -ItemType Directory -Force -Path $GlobalBinDir | Out-Null
    Write-Host "${Gray}Created global bin directory: $GlobalBinDir${Reset}"
}

# All PowerShell scripts and batch files to sync
$SyncFiles = @(
    # PowerShell scripts
    "flow.ps1",
    "flow-prd.ps1",
    "flow-convert.ps1",
    "flow-update.ps1",
    "flow-status.ps1",
    "flow-continue.ps1",
    "flow-help.ps1",
    "flow-sync.ps1",
    "flow-test.ps1",
    "flow-consolidate.ps1",
    "flow-work-story.ps1",
    "flow-install-global.ps1",
    "Banner.ps1",
    "LockLibrary.ps1"
    # Note: .bat files are wrappers, sync them too
)

$SyncBatFiles = @(
    "flow.bat",
    "flow-prd.bat",
    "flow-convert.bat",
    "flow-update.bat",
    "flow-status.bat",
    "flow-continue.bat",
    "flow-help.bat",
    "flow-sync.bat",
    "flow-test.bat",
    "flow-consolidate.bat",
    "flow-work-story.bat"
)

function Get-FileHashCustom {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            return (Get-FileHash -Path $Path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        } catch {
            return $null
        }
    }
    return $null
}

function Compare-Files {
    param(
        [string]$Source,
        [string]$Dest
    )

    $sourceHash = Get-FileHashCustom -Path $Source
    $destHash = Get-FileHashCustom -Path $Dest

    if ($null -eq $sourceHash) { return "SourceMissing" }
    if ($null -eq $destHash) { return "DestMissing" }
    if ($sourceHash -eq $destHash) { return "Same" }
    return "Different"
}

# Show help
if ($Direction -eq "Help") {
    Write-Host "${Cyan}Usage: flow-sync [command] [options]${Reset}"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  Auto      Auto-detect sync direction (default)"
    Write-Host "  Status    Show sync status only"
    Write-Host "  Pull      Pull from global (~/.claude/bin) to project"
    Write-Host "  Push      Push from project to global"
    Write-Host "  Help      Show this help"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Force    Force sync even if files match"
    Write-Host "  -Verbose  Show detailed output"
    exit 0
}

# Auto-detect direction
if ($Direction -eq "Auto") {
    Write-Host "${Blue}>> Auto-detecting sync direction...${Reset}"
    Write-Host ""

    $globalNewer = 0
    $projectNewer = 0
    $allFiles = $SyncFiles + $SyncBatFiles

    foreach ($file in $allFiles) {
        $globalPath = Join-Path $GlobalBinDir $file
        $projectPath = Join-Path $BinDir $file

        if ((Test-Path $globalPath) -and (Test-Path $projectPath)) {
            $globalTime = (Get-Item $globalPath).LastWriteTime
            $projectTime = (Get-Item $projectPath).LastWriteTime

            if ($globalTime -gt $projectTime) {
                $globalNewer++
                if ($Verbose) {
                    Write-Host "  ${Gray}Global is newer: ${Cyan}${file}${Reset}"
                }
            } elseif ($projectTime -gt $globalTime) {
                $projectNewer++
                if ($Verbose) {
                    Write-Host "  ${Gray}Project is newer: ${Cyan}${file}${Reset}"
                }
            }
        }
    }

    if ($globalNewer -gt $projectNewer) {
        $Direction = "Pull"
        Write-Host "  ${Yellow}-> Pull mode${Reset} (Global is newer)"
    } elseif ($projectNewer -gt $globalNewer) {
        $Direction = "Push"
        Write-Host "  ${Yellow}-> Push mode${Reset} (Project is newer)"
    } else {
        $Direction = "Status"
        Write-Host "  ${Green}-> Status mode${Reset} (Everything in sync)"
    }
    Write-Host ""
}

# Execute sync based on direction
switch ($Direction) {
    "Status" {
        Write-Host "${Blue}>> Checking sync status...${Reset}"
        Write-Host ""

        $allSynced = $true
        $allFiles = $SyncFiles + $SyncBatFiles

        foreach ($file in $allFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            # Skip if file doesn't exist in project
            if (-not (Test-Path $projectPath)) {
                continue
            }

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            switch ($status) {
                "Same" {
                    Write-Host "  ${Green}[OK]${Reset} ${Cyan}${file}${Reset} - In sync"
                }
                "SourceMissing" {
                    Write-Host "  ${Yellow}[?]${Reset} ${Cyan}${file}${Reset} - Not in global (use push)"
                    $allSynced = $false
                }
                "DestMissing" {
                    Write-Host "  ${Yellow}[?]${Reset} ${Cyan}${file}${Reset} - Not in project (use pull)"
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
        Write-Host "${Blue}>> Pulling from global to project...${Reset}"
        Write-Host ""

        $pulled = 0
        $allFiles = $SyncFiles + $SyncBatFiles

        foreach ($file in $allFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            if ($status -eq "Different" -or $status -eq "DestMissing" -or $Force) {
                if (Test-Path $globalPath) {
                    Copy-Item -Force $globalPath $projectPath
                    Write-Host "  ${Green}[OK]${Reset} ${Cyan}${file}${Reset} - Pulled from global"
                    $pulled++
                } else {
                    Write-Host "  ${Gray}[skip]${Reset} ${Cyan}${file}${Reset} - Not found in global"
                }
            } elseif ($status -eq "Same") {
                Write-Host "  ${Gray}[=]${Reset} ${Cyan}${file}${Reset} - Already in sync"
            }
        }

        Write-Host ""
        if ($pulled -gt 0) {
            Write-Host "${Green}Pull complete! Updated $pulled file(s).${Reset}"
        } else {
            Write-Host "${Green}All files already in sync.${Reset}"
        }
    }

    "Push" {
        Write-Host "${Blue}>> Pushing from project to global...${Reset}"
        Write-Host ""

        $pushed = 0
        $allFiles = $SyncFiles + $SyncBatFiles

        foreach ($file in $allFiles) {
            $globalPath = Join-Path $GlobalBinDir $file
            $projectPath = Join-Path $BinDir $file

            # Skip if file doesn't exist in project
            if (-not (Test-Path $projectPath)) {
                continue
            }

            $status = Compare-Files -Source $globalPath -Dest $projectPath

            if ($status -eq "Different" -or $status -eq "SourceMissing" -or $Force) {
                Copy-Item -Force $projectPath $globalPath
                Write-Host "  ${Green}[OK]${Reset} ${Cyan}${file}${Reset} - Pushed to global"
                $pushed++
            } elseif ($status -eq "Same") {
                Write-Host "  ${Gray}[=]${Reset} ${Cyan}${file}${Reset} - Already in sync"
            }
        }

        Write-Host ""
        if ($pushed -gt 0) {
            Write-Host "${Green}Push complete! Updated $pushed file(s).${Reset}"
            Write-Host ""
            Write-Host "${Yellow}[!] Note: Restart terminal to use updated global scripts${Reset}"
        } else {
            Write-Host "${Green}All files already in sync.${Reset}"
        }
    }
}

Write-Host ""
Write-Host "${Cyan}============================================================${Reset}"
