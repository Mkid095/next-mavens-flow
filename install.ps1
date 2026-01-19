# ============================================================================
# Maven Flow Safe Installer (Manifest-Based, Idempotent)
# ============================================================================
# - Creates missing files
# - Overwrites managed files
# - Removes obsolete managed files ONLY
# - Never deletes anything outside the manifest
# - Files installed directly to Claude folders (no maven-flow subfolder)
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
    Join-Path $ScriptDir ".claude"
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
# Files are installed DIRECTLY to Claude folders, NOT in a maven-flow subfolder
$Manifest = @{
    Directories = @(
        "agents",
        "commands",
        "hooks",
        "skills",
        "skills\workflow",
        "skills\flow-prd",
        "skills\flow-convert",
        "bin"
    )

    Files = @{
        "agents" = ".claude\agents\*.md"
        "commands" = ".claude\commands\*.md"
        "skills" = ".claude\skills\*.md"
        "skills\workflow" = ".claude\skills\workflow\*.md"
        "skills\flow-prd" = ".claude\skills\flow-prd\*.md"
        "skills\flow-convert" = ".claude\skills\flow-convert\*.md"
        "hooks" = ".claude\hooks\*"
        "bin" = @("bin\*.sh", "bin\*.ps1")
    }
}

# -------------------------
# CLEANUP OLD INSTALLATION
# -------------------------
$OldMavenFlowDir = Join-Path $TargetDir "maven-flow"
if (Test-Path $OldMavenFlowDir) {
    Log "[CLEANUP] Removing old maven-flow subfolder..." "Yellow"
    if (-not $DryRun) {
        Remove-Item $OldMavenFlowDir -Recurse -Force
    }
    Log "  [REMOVE DIR] $OldMavenFlowDir" "Red"
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
    $sourcePatterns = $entry.Value

    # Handle both single string and array of patterns
    if ($sourcePatterns -is [string]) {
        $sourcePatterns = @($sourcePatterns)
    }

    foreach ($pattern in $sourcePatterns) {
        $sourceGlob = Join-Path $ScriptDir $pattern

        if (Test-Path $sourceGlob) {
            $files = Get-ChildItem $sourceGlob
            foreach ($file in $files) {
                $subPath = Join-Path -Path $targetRel -ChildPath $file.Name
                $dest = Join-Path -Path $TargetDir -ChildPath $subPath

                Safe-Copy $file.FullName $dest
                $realDest = Resolve-Path $dest -ErrorAction SilentlyContinue
                if ($realDest) {
                    $ManagedFiles += $realDest.Path
                }
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
# STEP 4: ADD TO POWERSHELL PATH
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
Log "Installed Components:" "Cyan"
Log "  Agents    -> ~/.claude/agents/" "Gray"
Log "  Commands  -> ~/.claude/commands/" "Gray"
Log "  Skills    -> ~/.claude/skills/" "Gray"
Log "  Hooks     -> ~/.claude/hooks/" "Gray"
Log "  Scripts   -> ~/.claude/bin/" "Gray"
Log ""
Log "Usage:" "Cyan"
Log "  Claude Code Commands (in Claude Code):" "Cyan"
Log "    /flow start              # Start autonomous development" "Gray"
Log "    /flow status             # Check progress" "Gray"
Log "    /flow-prd create ...     # Create PRD" "Gray"
Log "    /flow-convert <feature>  # Convert PRD to JSON" "Gray"
Log "    /flow-update sync        # Update Maven Flow" "Gray"
Log ""
Log "  Terminal Commands (in PowerShell/terminal):" "Cyan"
Log "    flow start               # Start autonomous development" "Gray"
Log "    flow status              # Check progress" "Gray"
Log "    flow-prd <description>   # Generate PRD" "Gray"
Log "    flow-convert <feature>   # Convert PRD to JSON" "Gray"
Log "    flow-update              # Update Maven Flow" "Gray"
Log ""
Log "[!] Action Required:" "Yellow"
Log "  Run:  . `$PROFILE  (or restart your terminal)" "Gray"
Log ""
