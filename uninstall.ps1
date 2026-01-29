# ============================================================================
# Maven Flow Uninstaller
# ============================================================================
# Removes Maven Flow components from Claude folders
# ============================================================================
#Requires -Version 5.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------------------------
# CONFIG
# -------------------------
$HomeClaude = Join-Path $env:USERPROFILE ".claude"

# Maven Flow agents to remove (updated 2026)
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

# Maven Flow commands to remove (updated 2026)
$FlowCommands = @(
    "flow.md",
    "flow-mobile.md",
    "flow-prd.md",
    "flow-convert.md",
    "flow-update.md",
    "flow-work-story.md",
    "consolidate-memory.md",
    "create-story-memory.md"
)

# Maven Flow skill subdirectories to remove
$FlowSkillsSubdirs = @(
    "flow-convert",
    "workflow"
)

# Maven Flow skill files to remove
$FlowSkillFiles = @(
    "flow-prd-mobile.md"
)

# Maven Flow hooks to remove (legacy + maven-flow)
$FlowHooks = @(
    "session-save.sh",
    "session-restore.sh"
)

# Maven Flow maven-flow subdirectory to remove entirely
$FlowMavenFlowSubdirs = @(
    "hooks",
    "config",
    ".claude"
)

# Maven Flow lib files to remove
$FlowLibFiles = @(
    "lock.sh"
)

# Maven Flow shared docs to remove
$FlowSharedFiles = @(
    "agent-patterns.md",
    "mcp-tools.md",
    "prd-json-schema.md",
    "required-mcps.md"
)

# Maven Flow ADRs to remove
$FlowAdrFiles = @(
    "001-story-level-mcp-assignment.md",
    "002-multi-prd-architecture.md",
    "003-feature-based-folder-structure.md",
    "004-specialist-agent-coordination.md"
)

# Maven Flow bin files to remove
$FlowBinFiles = @(
    "flow-banner.sh"
)

# -------------------------
# UI HELPERS
# -------------------------
function Log {
    param([string]$msg, [string]$color="Gray")
    Write-Host $msg -ForegroundColor $color
}

# -------------------------
# CONFIRM
# -------------------------
Log ""
Log "=============================================" "Blue"
Log " Maven Flow Uninstaller" "Blue"
Log "=============================================" "Blue"
Log ""
Log "This will remove Maven Flow components from:" "Yellow"
Log "  $HomeClaude" "Cyan"
Log ""
Log "Components to be removed:" "Yellow"
Log "  - Agents from ~/.claude/agents/" "Gray"
Log "  - Commands from ~/.claude/commands/" "Gray"
Log "  - Skills from ~/.claude/skills/" "Gray"
Log "  - Hooks from ~/.claude/hooks/" "Gray"
Log "  - Maven Flow from ~/.claude/maven-flow/" "Gray"
Log "  - Lib files from ~/.claude/lib/" "Gray"
Log "  - Shared docs from ~/.claude/shared/" "Gray"
Log "  - ADRs from ~/.claude/adrs/" "Gray"
Log "  - Bin files from ~/.claude/bin/" "Gray"
Log ""

$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Log "Uninstall cancelled." "Yellow"
    exit 0
}

# -------------------------
# REMOVE AGENTS
# -------------------------
Log "[STEP 1] Removing Maven Flow agents..." "Yellow"
$agentsDir = Join-Path $HomeClaude "agents"
$removedCount = 0
foreach ($agent in $FlowAgents) {
    $agentPath = Join-Path $agentsDir $agent
    if (Test-Path $agentPath) {
        Remove-Item $agentPath -Force
        Log "  [REMOVE] $agentPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow agents found" "Gray"
}

# -------------------------
# REMOVE COMMANDS
# -------------------------
Log "[STEP 2] Removing Maven Flow commands..." "Yellow"
$commandsDir = Join-Path $HomeClaude "commands"
$removedCount = 0
foreach ($cmd in $FlowCommands) {
    $cmdPath = Join-Path $commandsDir $cmd
    if (Test-Path $cmdPath) {
        Remove-Item $cmdPath -Force
        Log "  [REMOVE] $cmdPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow commands found" "Gray"
}

# -------------------------
# REMOVE SKILL DIRECTORIES
# -------------------------
Log "[STEP 3] Removing Maven Flow skill directories..." "Yellow"
$skillsDir = Join-Path $HomeClaude "skills"
$removedCount = 0
foreach ($skillDir in $FlowSkillsSubdirs) {
    $skillPath = Join-Path $skillsDir $skillDir
    if (Test-Path $skillPath) {
        Remove-Item $skillPath -Recurse -Force
        Log "  [REMOVE] $skillPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow skill directories found" "Gray"
}

# -------------------------
# REMOVE SKILL FILES
# -------------------------
Log "[STEP 4] Removing Maven Flow skill files..." "Yellow"
$removedCount = 0
foreach ($skill in $FlowSkillFiles) {
    $skillPath = Join-Path $skillsDir $skill
    if (Test-Path $skillPath) {
        Remove-Item $skillPath -Force
        Log "  [REMOVE] $skillPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow skill files found" "Gray"
}

# -------------------------
# REMOVE HOOKS
# -------------------------
Log "[STEP 5] Removing Maven Flow hooks..." "Yellow"
$hooksDir = Join-Path $HomeClaude "hooks"
$removedCount = 0
foreach ($hook in $FlowHooks) {
    $hookPath = Join-Path $hooksDir $hook
    if (Test-Path $hookPath) {
        Remove-Item $hookPath -Force
        Log "  [REMOVE] $hookPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow hooks found" "Gray"
}

# -------------------------
# REMOVE MAVEN-FLOW SUBDIRECTORY
# -------------------------
Log "[STEP 6] Removing Maven Flow subdirectory..." "Yellow"
$mavenFlowDir = Join-Path $HomeClaude "maven-flow"
if (Test-Path $mavenFlowDir) {
    Remove-Item $mavenFlowDir -Recurse -Force
    Log "  [REMOVE] $mavenFlowDir" "Green"
} else {
    Log "  No maven-flow directory found" "Gray"
}

# -------------------------
# REMOVE LIB FILES
# -------------------------
Log "[STEP 7] Removing Maven Flow lib files..." "Yellow"
$libDir = Join-Path $HomeClaude "lib"
$removedCount = 0
foreach ($libFile in $FlowLibFiles) {
    $libPath = Join-Path $libDir $libFile
    if (Test-Path $libPath) {
        Remove-Item $libPath -Force
        Log "  [REMOVE] $libPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow lib files found" "Gray"
}

# -------------------------
# REMOVE SHARED DOCS
# -------------------------
Log "[STEP 8] Removing Maven Flow shared docs..." "Yellow"
$sharedDir = Join-Path $HomeClaude "shared"
$removedCount = 0
foreach ($sharedFile in $FlowSharedFiles) {
    $sharedPath = Join-Path $sharedDir $sharedFile
    if (Test-Path $sharedPath) {
        Remove-Item $sharedPath -Force
        Log "  [REMOVE] $sharedPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow shared docs found" "Gray"
}

# -------------------------
# REMOVE ADRS
# -------------------------
Log "[STEP 9] Removing Maven Flow ADRs..." "Yellow"
$adrsDir = Join-Path $HomeClaude "adrs"
$removedCount = 0
foreach ($adrFile in $FlowAdrFiles) {
    $adrPath = Join-Path $adrsDir $adrFile
    if (Test-Path $adrPath) {
        Remove-Item $adrPath -Force
        Log "  [REMOVE] $adrPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow ADRs found" "Gray"
}

# -------------------------
# REMOVE BIN FILES
# -------------------------
Log "[STEP 10] Removing Maven Flow bin files..." "Yellow"
$binDir = Join-Path $HomeClaude "bin"
$removedCount = 0
foreach ($binFile in $FlowBinFiles) {
    $binPath = Join-Path $binDir $binFile
    if (Test-Path $binPath) {
        Remove-Item $binPath -Force
        Log "  [REMOVE] $binPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow bin files found" "Gray"
}

# -------------------------
# DONE
# -------------------------
Log ""
Log "=============================================" "Blue"
Log "[OK] Maven Flow Uninstall Complete" "Green"
Log "=============================================" "Blue"
Log ""
Log "Note: You may need to restart Claude Code for changes to take effect." "Yellow"
Log ""
