# ============================================================================
# Maven Flow Safe Installer (Manifest-Based, Idempotent)
# ============================================================================
# - Creates missing files
# - Overwrites managed files
# - Removes obsolete managed files ONLY
# - Never deletes anything outside the manifest
# ============================================================================

#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# CONFIG
# -------------------------
$ScriptDir = $PSScriptRoot
$DryRun = $false   # Set to $true to preview actions

$HomeClaude = Join-Path $env:USERPROFILE ".claude"
$TargetDir = if (Test-Path $HomeClaude) {
    $HomeClaude
} else {
    Join-Path $ScriptDir ".claude\maven-flow"
}

# -------------------------
# UI HELPERS
# -------------------------
function Log {
    param([string]$msg, [string]$color="Gray")
    Write-Host $msg -ForegroundColor $color
}

function Ensure-Dir {
    param([string]$path)
    if (-not (Test-Path $path)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
        Log "  [CREATE DIR] $path" "Yellow"
    }
}

function Safe-Copy {
    param([string]$src, [string]$dst)
    Ensure-Dir (Split-Path $dst)
    if (-not $DryRun) {
        Copy-Item $src $dst -Force
    }
    Log "  [SYNC FILE] $dst" "Green"
}

function Safe-Delete {
    param([string]$path)
    if (-not $DryRun) {
        Remove-Item $path -Force
    }
    Log "  [REMOVE] $path" "Red"
}

# -------------------------
# MANIFEST (THE SOURCE OF TRUTH)
# -------------------------
$Manifest = @{
    Directories = @(
        "agents",
        "commands",
        "maven-flow\hooks",
        "maven-flow\config",
        "maven-flow\.claude",
        "skills"
    )

    Files = @{
        "agents" = ".claude\agents\*.md"
        "commands" = ".claude\commands\*.md"
        "maven-flow\hooks" = ".claude\maven-flow\hooks\*.sh"
        "maven-flow\config" = ".claude\maven-flow\config\*.mjs"
        "maven-flow\.claude\settings.json" = ".claude\maven-flow\.claude\settings.json"
    }
}

# -------------------------
# START
# -------------------------
Log ""
Log "=============================================" "Blue"
Log " Maven Flow Safe Installation" "Blue"
Log "=============================================" "Blue"
Log "Target: $TargetDir" "Cyan"
Log "Dry Run: $DryRun" "Cyan"
Log ""

# -------------------------
# STEP 1: ENSURE DIRECTORIES
# -------------------------
Log "[STEP 1] Ensuring directories..." "Yellow"
foreach ($dir in $Manifest.Directories) {
    Ensure-Dir (Join-Path $TargetDir $dir)
}

# -------------------------
# STEP 2: SYNC FILES (CREATE + OVERWRITE)
# -------------------------
Log "[STEP 2] Syncing managed files..." "Yellow"

$ManagedFiles = @()

foreach ($entry in $Manifest.Files.GetEnumerator()) {
    $targetRel = $entry.Key
    $sourceGlob = Join-Path $ScriptDir $entry.Value

    if (Test-Path $sourceGlob) {
        $files = Get-ChildItem $sourceGlob
        foreach ($file in $files) {
            if ($targetRel.EndsWith(".json")) {
                $dest = Join-Path -Path $TargetDir -ChildPath $targetRel
            } else {
                $subPath = Join-Path -Path $targetRel -ChildPath $file.Name
                $dest = Join-Path -Path $TargetDir -ChildPath $subPath
            }

            Safe-Copy $file.FullName $dest
            $realDest = Resolve-Path $dest -ErrorAction SilentlyContinue
            if ($realDest) {
                $ManagedFiles += $realDest.Path
            }
        }
    }
}

# -------------------------
# STEP 3: REMOVE OBSOLETE MANAGED FILES
# -------------------------
Log "[STEP 3] Cleaning obsolete managed files..." "Yellow"

foreach ($dir in $Manifest.Directories) {
    $fullDir = Join-Path $TargetDir $dir
    if (-not (Test-Path $fullDir)) {
        continue
    }

    $files = Get-ChildItem $fullDir -File
    foreach ($file in $files) {
        $realPath = $file.FullName
        $isManaged = $false

        foreach ($managed in $ManagedFiles) {
            if ($managed -eq $realPath) {
                $isManaged = $true
                break
            }
        }

        if (-not $isManaged) {
            Safe-Delete $realPath
        }
    }
}

# -------------------------
# DONE
# -------------------------
Log ""
Log "=============================================" "Blue"
Log "[OK] Maven Flow Installation Complete" "Green"
Log "=============================================" "Blue"
Log ""

if ($DryRun) {
    Log "NOTE: Dry-run mode enabled. No changes were made." "Yellow"
}

# Show usage hints
Log ""
Log "Usage:" "Cyan"
Log "  Claude Code Commands:" "Cyan"
Log "    /flow start              # Start autonomous development" "Gray"
Log "    /flow status             # Check progress" "Gray"
Log "    /flow-prd create ...     # Create PRD" "Gray"
Log "    /flow-convert <feature>  # Convert PRD to JSON" "Gray"
