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

# Maven Flow files to remove (updated 2026)
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
    "consolidate-memory.md",
    "create-story-memory.md",
    "flow-convert.md"
)

$FlowSkillsSubdirs = @(
    "workflow",
    "flow-convert"
)

$FlowSkillFiles = @(
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
    "toon-compress.js",
    "retry-manager.js"
)

$FlowScripts = @(
    "flow.sh",
    "flow-prd.sh",
    "flow-convert.sh",
    "flow-install-global.sh",
    "flow-uninstall-global.sh",
    "flow-sync.sh",
    "flow-status.sh",
    "flow-continue.sh",
    "flow-help.sh",
    "flow-update.sh",
    "maven-flow-wrapper.sh",
    "flow.ps1",
    "flow-prd.ps1",
    "flow-convert.ps1",
    "flow-continue.ps1",
    "flow-help.ps1",
    "flow-status.ps1",
    "flow-sync.ps1",
    "flow-update.ps1",
    "flow-install-global.ps1",
    "flow-uninstall-global.ps1"
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
Log "  - Scripts from ~/.claude/bin/" "Gray"
Log "  - Old maven-flow subfolder (if exists)" "Gray"
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
# REMOVE SCRIPTS
# -------------------------
Log "[STEP 6] Removing Maven Flow scripts..." "Yellow"
$binDir = Join-Path $HomeClaude "bin"
$removedCount = 0
foreach ($script in $FlowScripts) {
    $scriptPath = Join-Path $binDir $script
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath -Force
        Log "  [REMOVE] $scriptPath" "Green"
        $removedCount++
    }
}
if ($removedCount -eq 0) {
    Log "  No Maven Flow scripts found" "Gray"
}

# -------------------------
# REMOVE OLD MAVEN-FLOW SUBFOLDER
# -------------------------
Log "[STEP 7] Removing old maven-flow subfolder..." "Yellow"
$oldMavenFlowDir = Join-Path $HomeClaude "maven-flow"
if (Test-Path $oldMavenFlowDir) {
    Remove-Item $oldMavenFlowDir -Recurse -Force
    Log "  [REMOVE] $oldMavenFlowDir" "Green"
} else {
    Log "  No old maven-flow directory found" "Gray"
}

# -------------------------
# REMOVE PATH ENTRY FROM SHELL CONFIG
# -------------------------
Log "[STEP 8] Removing PATH entry from shell config..." "Yellow"
$shellConfig = Join-Path $env:USERPROFILE ".bashrc"
if (Test-Path $shellConfig) {
    $content = Get-Content $shellConfig -Raw
    if ($content -match "Maven Flow") {
        $newContent = $content -replace "(?ms)# Maven Flow.*?(?=`n|$)", ""
        $newContent = $newContent -replace "(?ms)export PATH=.*?\.claude/bin.*?(?=`n|$)", ""
        Set-Content $shellConfig $newContent.Trim()
        Log "  [CLEAN] Removed Maven Flow entries from $shellConfig" "Green"
    } else {
        Log "  No Maven Flow entries in $shellConfig" "Gray"
    }
} else {
    Log "  $shellConfig not found" "Gray"
}

# -------------------------
# DONE
# -------------------------
Log ""
Log "=============================================" "Blue"
Log "[OK] Maven Flow Uninstall Complete" "Green"
Log "=============================================" "Blue"
Log ""
Log "Action required:" "Yellow"
Log "  Run: source ~/.bashrc" "Gray"
Log "  Or restart your terminal" "Gray"
Log ""
