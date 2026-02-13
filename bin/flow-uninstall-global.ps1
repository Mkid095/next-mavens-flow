#!/usr/bin/env pwsh
# ============================================================================
# Maven Flow Global Uninstaller (Windows PowerShell)
# Removes all installed Maven Flow components
# ============================================================================

param(
    [switch]$Force,
    [switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Colors
$Esc = [char]0x1b
$Cyan = "${Esc}[36m"
$Green = "${Esc}[32m"
$Yellow = "${Esc}[33m"
$Blue = "${Esc}[34m"
$Red = "${Esc}[31m"
$Gray = "${Esc}[90m"
$Reset = "${Esc}[0m"

# Print header
function Print-Header {
    Write-Host ""
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host "${Cyan}|          Maven Flow - Global Uninstallation Manager        |${Reset}"
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host ""
}

Print-Header

Write-Host "${Blue}>> Uninstalling Maven Flow globally${Reset}"
Write-Host ""

# Claude directories
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$AgentsDir = Join-Path $ClaudeDir "agents"
$CommandsDir = Join-Path $ClaudeDir "commands"
$SkillsDir = Join-Path $ClaudeDir "skills"
$HooksDir = Join-Path $ClaudeDir "hooks"
$BinDir = Join-Path $ClaudeDir "bin"

# All Maven Flow files to remove (complete list)
$FlowAgents = @(
    "development.md",
    "quality.md",
    "testing.md",
    "refactor.md",
    "security.md",
    "design.md",
    "mobile-app.md",
    "Project-Auditor.md",
    "debugging-agent.md"
)

$FlowCommands = @(
    "flow.md",
    "flow-prd.md",
    "flow-convert.md",
    "flow-update.md",
    "flow-mobile.md",
    "flow-work-story.md",
    "consolidate-memory.md",
    "create-story-memory.md"
)

$FlowSkillsSubdirs = @(
    "workflow",
    "flow-convert"
)

$FlowSkillsFiles = @(
    "flow-prd-mobile.md"
)

$FlowHooks = @(
    "session-save.sh",
    "session-restore.sh",
    "pre-task-flow-validation.js",
    "agent-selector.js",
    "dependency-graph.js",
    "error-reporter.js",
    "memory-cache.js",
    "path-utils.js",
    "prd-utils.js",
    "toon-compress.js"
)

$FlowScriptsPs1 = @(
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
)

$FlowScriptsSh = @(
    "flow.sh",
    "flow-prd.sh",
    "flow-convert.sh",
    "flow-update.sh",
    "flow-status.sh",
    "flow-continue.sh",
    "flow-help.sh",
    "flow-sync.sh",
    "flow-test.sh",
    "flow-consolidate.sh",
    "flow-work-story.sh",
    "flow-install-global.sh",
    "flow-uninstall-global.sh",
    "maven-flow-wrapper.sh",
    "test-locks.sh",
    "flow-banner.sh"
)

$FlowScriptsBat = @(
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

# Function to remove files
function Remove-Files {
    param(
        [string]$Directory,
        [string[]]$Files
    )

    $removed = 0
    foreach ($file in $Files) {
        $path = Join-Path $Directory $file
        if (Test-Path $path) {
            Remove-Item -Force $path -ErrorAction SilentlyContinue
            $removed++
            Write-Host "  ${Gray}Removed:${Reset} ${Cyan}$file${Reset}"
        }
    }

    if ($removed -gt 0) {
        Write-Host "  ${Green}Removed $removed file(s)${Reset}"
    }
}

# Function to remove directories
function Remove-Dirs {
    param(
        [string]$Parent,
        [string[]]$Dirs
    )

    $removed = 0
    foreach ($dir in $Dirs) {
        $path = Join-Path $Parent $dir
        if (Test-Path $path) {
            Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
            $removed++
            Write-Host "  ${Gray}Removed:${Reset} ${Cyan}$dir/${Reset}"
        }
    }

    if ($removed -gt 0) {
        Write-Host "  ${Green}Removed $removed director(ies)${Reset}"
    }
}

# Step 1: Remove agents
Write-Host "${Gray}  -> Removing Maven Flow agents...${Reset}"
if (Test-Path $AgentsDir) {
    Remove-Files -Directory $AgentsDir -Files $FlowAgents
} else {
    Write-Host "  ${Yellow}[!] No agents directory found${Reset}"
}
Write-Host ""

# Step 2: Remove commands
Write-Host "${Gray}  -> Removing Maven Flow commands...${Reset}"
if (Test-Path $CommandsDir) {
    Remove-Files -Directory $CommandsDir -Files $FlowCommands
} else {
    Write-Host "  ${Yellow}[!] No commands directory found${Reset}"
}
Write-Host ""

# Step 3: Remove skill subdirectories
Write-Host "${Gray}  -> Removing Maven Flow skill directories...${Reset}"
if (Test-Path $SkillsDir) {
    Remove-Dirs -Parent $SkillsDir -Dirs $FlowSkillsSubdirs
    Remove-Files -Directory $SkillsDir -Files $FlowSkillsFiles
} else {
    Write-Host "  ${Yellow}[!] No skills directory found${Reset}"
}
Write-Host ""

# Step 4: Remove hooks
Write-Host "${Gray}  -> Removing Maven Flow hooks...${Reset}"
if (Test-Path $HooksDir) {
    Remove-Files -Directory $HooksDir -Files $FlowHooks
} else {
    Write-Host "  ${Yellow}[!] No hooks directory found${Reset}"
}
Write-Host ""

# Step 5: Remove scripts (all types)
Write-Host "${Gray}  -> Removing Maven Flow scripts...${Reset}"
if (Test-Path $BinDir) {
    Remove-Files -Directory $BinDir -Files $FlowScriptsPs1
    Remove-Files -Directory $BinDir -Files $FlowScriptsSh
    Remove-Files -Directory $BinDir -Files $FlowScriptsBat
} else {
    Write-Host "  ${Yellow}[!] No bin directory found${Reset}"
}
Write-Host ""

# Step 6: Remove old maven-flow subfolder if exists
Write-Host "${Gray}  -> Removing old maven-flow directory...${Reset}"
$OldMavenFlowDir = Join-Path $ClaudeDir "maven-flow"
if (Test-Path $OldMavenFlowDir) {
    Remove-Item -Recurse -Force $OldMavenFlowDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK] Removed old maven-flow directory${Reset}"
} else {
    Write-Host "  ${Gray}[skip] No old maven-flow directory found${Reset}"
}
Write-Host ""

# Step 7: Remove PATH entry from user environment
Write-Host "${Gray}  -> Checking PATH entries...${Reset}"
try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $mavenFlowPaths = $currentPath -split ';' | Where-Object { $_ -like "*mavens-flow*" -or $_ -like "*Maven Flow*" }

    if ($mavenFlowPaths) {
        $newPath = ($currentPath -split ';' | Where-Object { $_ -notlike "*mavens-flow*" -and $_ -notlike "*Maven Flow*" }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "  ${Green}[OK] Removed PATH entries${Reset}"
    } else {
        Write-Host "  ${Gray}[skip] No Maven Flow PATH entries found${Reset}"
    }
} catch {
    Write-Host "  ${Yellow}[!] Could not modify PATH: $_${Reset}"
}
Write-Host ""

# Success message
Write-Host "${Cyan}============================================================${Reset}"
Write-Host "${Green}[OK] Uninstallation complete!${Reset}"
Write-Host ""
Write-Host "${Gray}Removed components:${Reset}"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Agents${Reset}        from ~/.claude/agents/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Commands${Reset}      from ~/.claude/commands/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Skills${Reset}        from ~/.claude/skills/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Hooks${Reset}         from ~/.claude/hooks/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Scripts${Reset}       from ~/.claude/bin/"
Write-Host ""
Write-Host "${Yellow}[!] Action required:${Reset}"
Write-Host "  Restart your terminal or run: ${Green}refreshenv${Reset} (if available)"
Write-Host ""
Write-Host "${Cyan}============================================================${Reset}"
