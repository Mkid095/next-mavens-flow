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
$ManifestDirs = @(
    "adrs",
    "agents",
    "commands",
    "hooks",
    "lib",
    "maven-flow\hooks",
    "maven-flow\config",
    "maven-flow\.claude",
    "shared",
    "skills\flow-convert",
    "skills\workflow",
    "bin"
)

# Explicit file mappings (source -> destination relative to target)
$ManifestFiles = @{
    # Commands
    ".claude\commands\flow.md" = ".claude\commands\flow.md"
    ".claude\commands\flow-mobile.md" = ".claude\commands\flow-mobile.md"
    ".claude\commands\flow-prd.md" = ".claude\commands\flow-prd.md"
    ".claude\commands\flow-convert.md" = ".claude\commands\flow-convert.md"
    ".claude\commands\flow-update.md" = ".claude\commands\flow-update.md"
    ".claude\commands\flow-work-story.md" = ".claude\commands\flow-work-story.md"
    ".claude\commands\consolidate-memory.md" = ".claude\commands\consolidate-memory.md"
    ".claude\commands\create-story-memory.md" = ".claude\commands\create-story-memory.md"

    # Agents
    ".claude\agents\development.md" = ".claude\agents\development.md"
    ".claude\agents\refactor.md" = ".claude\agents\refactor.md"
    ".claude\agents\security.md" = ".claude\agents\security.md"
    ".claude\agents\quality.md" = ".claude\agents\quality.md"
    ".claude\agents\design.md" = ".claude\agents\design.md"
    ".claude\agents\mobile-app.md" = ".claude\agents\mobile-app.md"
    ".claude\agents\testing.md" = ".claude\agents\testing.md"
    ".claude\agents\debugging-agent.md" = ".claude\agents\debugging-agent.md"
    ".claude\agents\Project-Auditor.md" = ".claude\agents\Project-Auditor.md"

    # Hooks (legacy - kept for compatibility)
    ".claude\hooks\session-save.sh" = ".claude\hooks\session-save.sh"
    ".claude\hooks\session-restore.sh" = ".claude\hooks\session-restore.sh"

    # Maven Flow Hooks
    ".claude\maven-flow\hooks\post-tool-use-quality.sh" = ".claude\maven-flow\hooks\post-tool-use-quality.sh"
    ".claude\maven-flow\hooks\stop-comprehensive-check.sh" = ".claude\maven-flow\hooks\stop-comprehensive-check.sh"
    ".claude\maven-flow\hooks\incremental-check.sh" = ".claude\maven-flow\hooks\incremental-check.sh"
    ".claude\maven-flow\hooks\create-memory.sh" = ".claude\maven-flow\hooks\create-memory.sh"

    # Maven Flow Config
    ".claude\maven-flow\config\eslint.config.mjs" = ".claude\maven-flow\config\eslint.config.mjs"
    ".claude\maven-flow\.claude\settings.json" = ".claude\maven-flow\.claude\settings.json"

    # Lib
    ".claude\lib\lock.sh" = ".claude\lib\lock.sh"

    # Shared docs
    ".claude\shared\agent-patterns.md" = ".claude\shared\agent-patterns.md"
    ".claude\shared\mcp-tools.md" = ".claude\shared\mcp-tools.md"
    ".claude\shared\prd-json-schema.md" = ".claude\shared\prd-json-schema.md"
    ".claude\shared\required-mcps.md" = ".claude\shared\required-mcps.md"

    # Skills
    ".claude\skills\flow-convert\SKILL.md" = ".claude\skills\flow-convert\SKILL.md"
    ".claude\skills\workflow\SKILL.md" = ".claude\skills\workflow\SKILL.md"
    ".claude\skills\flow-prd-mobile.md" = ".claude\skills\flow-prd-mobile.md"

    # ADRs
    ".claude\adrs\001-story-level-mcp-assignment.md" = ".claude\adrs\001-story-level-mcp-assignment.md"
    ".claude\adrs\002-multi-prd-architecture.md" = ".claude\adrs\002-multi-prd-architecture.md"
    ".claude\adrs\003-feature-based-folder-structure.md" = ".claude\adrs\003-feature-based-folder-structure.md"
    ".claude\adrs\004-specialist-agent-coordination.md" = ".claude\adrs\004-specialist-agent-coordination.md"

    # Bin
    ".claude\bin\flow-banner.sh" = ".claude\bin\flow-banner.sh"
    ".claude\bin\flow-convert.sh" = ".claude\bin\flow-convert.sh"
    ".claude\bin\flow-install-global.sh" = ".claude\bin\flow-install-global.sh"
    ".claude\bin\flow-install-user.sh" = ".claude\bin\flow-install-user.sh"
    ".claude\bin\flow.sh" = ".claude\bin\flow.sh"
    ".claude\bin\flow-status.sh" = ".claude\bin\flow-status.sh"
    ".claude\bin\test-locks.sh" = ".claude\bin\test-locks.sh"
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
foreach ($dir in $ManifestDirs) {
    Ensure-Dir (Join-Path $TargetDir $dir)
}

# -------------------------
# STEP 2: SYNC FILES (CREATE + OVERWRITE)
# -------------------------
Log "[STEP 2] Syncing managed files..." "Yellow"

$ManagedFiles = @()

foreach ($targetRel in $ManifestFiles.Keys) {
    $sourceRel = $ManifestFiles[$targetRel]
    $src = Join-Path $ScriptDir $sourceRel
    $dest = Join-Path $TargetDir $targetRel

    if (Test-Path $src) {
        Safe-Copy $src $dest
        $realDest = Resolve-Path $dest -ErrorAction SilentlyContinue
        if ($realDest) {
            $ManagedFiles += $realDest.Path
        }
    } else {
        Log "  [SKIP] Source not found: $src" "Cyan"
    }
}

# Make shell scripts executable on Unix systems (skip on Windows)
# This is a no-op on Windows but keeps logic aligned

# -------------------------
# STEP 3: REMOVE OBSOLETE MANAGED FILES
# -------------------------
Log "[STEP 3] Cleaning obsolete managed files..." "Yellow"

foreach ($dir in $ManifestDirs) {
    $fullDir = Join-Path $TargetDir $dir
    if (-not (Test-Path $fullDir)) {
        continue
    }

    $files = Get-ChildItem $fullDir -File -ErrorAction SilentlyContinue
    if ($files) {
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
}

# -------------------------
# STEP 4: ADD TO PATH (PowerShell only)
# -------------------------
Log "[STEP 4] Adding to PowerShell PATH..." "Yellow"

$BinDir = Join-Path $TargetDir "bin"
$ProfilePath = $PROFILE
$PathEntry = "`$env:Path += `";$BinDir`""

# Ensure profile exists
if (-not (Test-Path $ProfilePath)) {
    if (-not $DryRun) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    }
    Log "  [CREATE] PowerShell profile: $ProfilePath" "Yellow"
}

# Check if PATH entry already exists
if (Test-Path $ProfilePath) {
    $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match [regex]::Escape($BinDir)) {
        Log "  [SKIP] Already in PowerShell PATH" "Gray"
    } else {
        if (-not $DryRun) {
            Add-Content $ProfilePath ""
            Add-Content $ProfilePath "# Maven Flow - Added by install.ps1"
            Add-Content $ProfilePath $PathEntry
        }
        Log "  [ADD] Added to PowerShell PATH in $ProfilePath" "Green"
    }
}

# Also add to .bashrc for Git Bash/WSL users
$BashrcPath = Join-Path $env:USERPROFILE ".bashrc"
$BashPathEntry = "export PATH=`"$BinDir`:`$PATH`""

if (Test-Path $BashrcPath) {
    $bashContent = Get-Content $BashrcPath -Raw -ErrorAction SilentlyContinue
    if ($bashContent -and $bashContent -match "Maven Flow") {
        Log "  [SKIP] Already in .bashrc" "Gray"
    } else {
        if (-not $DryRun) {
            Add-Content $BashrcPath ""
            Add-Content $BashrcPath "# Maven Flow - Added by install.ps1"
            Add-Content $BashrcPath $BashPathEntry
        }
        Log "  [ADD] Added to .bashrc PATH" "Green"
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
Log ""
Log "  Terminal Commands (via bin/flow):" "Cyan"
Log "    flow start [n]           # Start autonomous development" "Gray"
Log "    flow status              # Check progress" "Gray"
Log "    flow-prd create ...      # Create PRD" "Gray"
Log "    flow-convert <feature>   # Convert PRD to JSON" "Gray"
Log ""
