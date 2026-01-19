# ============================================================================
# Maven Flow Global Installer (Windows PowerShell)
# Installs Flow components directly to Claude folders
# ============================================================================

param(
    [switch]$Force,
    [switch]$Verbose
)

# Strict mode
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

# Print header function
function Print-Header {
    Write-Host ""
    Write-Host "${Cyan}╔════════════════════════════════════════════════════════════╗${Reset}"
    Write-Host "${Cyan}║           Maven Flow - Global Installation Manager          ║${Reset}"
    Write-Host "${Cyan}╚════════════════════════════════════════════════════════════╝${Reset}"
    Write-Host ""
}

# Spinner function
function Show-Spinner {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message
    )

    $spinner = @('⠋', '⠙', '⠸', '⠴', '⠦', '⠇', '⠏')
    $job = Start-Job -ScriptBlock $ScriptBlock

    $i = 0
    while ($job.State -eq 'Running') {
        $frame = $spinner[$i % $spinner.Length]
        Write-Host -NoNewline "`r${Cyan}  [$frame] ${Message}...${Reset}"
        $i++
        Start-Sleep -Milliseconds 100
    }

    $job | Wait-Job | Out-Null
    Write-Host "`r${Green}[✓]${Reset} ${Message}                    "
    $job | Remove-Job
}

# Show header
Print-Header

Write-Host "${Blue}▶ Installing Maven Flow globally${Reset}"
Write-Host ""

# Get script directory
$BinDir = Split-Path -Parent $PSScriptRoot
$ProjectDir = Split-Path -Parent $BinDir

# Claude directories
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$AgentsDir = Join-Path $ClaudeDir "agents"
$CommandsDir = Join-Path $ClaudeDir "commands"
$SkillsDir = Join-Path $ClaudeDir "skills"
$HooksDir = Join-Path $ClaudeDir "hooks"
$GlobalBinDir = Join-Path $ClaudeDir "bin"

# Step 1: Remove old maven-flow subfolder if exists
Write-Host "${Gray}  → Cleaning up old installation...${Reset}"
$OldMavenFlowDir = Join-Path $ClaudeDir "maven-flow"
if (Test-Path $OldMavenFlowDir) {
    Show-Spinner -ScriptBlock {
        param($dir)
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
    } -Message "Removing old maven-flow directory" -ArgumentList $OldMavenFlowDir
} else {
    Write-Host "`r${Green}[✓]${Reset} No old installation to remove                    "
}

# Step 2: Create required directories
Write-Host "${Gray}  → Creating Claude directories...${Reset}"
Show-Spinner -ScriptBlock {
    param($agents, $commands, $skills, $hooks, $bin)
    New-Item -ItemType Directory -Force $agents | Out-Null
    New-Item -ItemType Directory -Force $commands | Out-Null
    New-Item -ItemType Directory -Force $skills | Out-Null
    New-Item -ItemType Directory -Force $hooks | Out-Null
    New-Item -ItemType Directory -Force $bin | Out-Null
} -Message "Creating Claude directories" -ArgumentList $AgentsDir, $CommandsDir, $SkillsDir, $HooksDir, $GlobalBinDir

# Step 3: Install agents
Write-Host "${Gray}  → Installing agents...${Reset}"
$ProjectAgentsDir = Join-Path $ProjectDir ".claude\agents"
if (Test-Path $ProjectAgentsDir) {
    Show-Spinner -ScriptBlock {
        param($src, $dest)
        Copy-Item -Force "$src\*.md" $dest -ErrorAction SilentlyContinue
    } -Message "Installing agents" -ArgumentList $ProjectAgentsDir, $AgentsDir
} else {
    Write-Host "`r${Yellow}[!]${Reset} No agents directory found                    "
}

# Step 4: Install commands
Write-Host "${Gray}  → Installing commands...${Reset}"
$ProjectCommandsDir = Join-Path $ProjectDir ".claude\commands"
if (Test-Path $ProjectCommandsDir) {
    Show-Spinner -ScriptBlock {
        param($src, $dest)
        Copy-Item -Force "$src\*.md" $dest -ErrorAction SilentlyContinue
    } -Message "Installing commands" -ArgumentList $ProjectCommandsDir, $CommandsDir
} else {
    Write-Host "`r${Yellow}[!]${Reset} No commands directory found                    "
}

# Step 5: Install skills
Write-Host "${Gray}  → Installing skills...${Reset}"
$ProjectSkillsDir = Join-Path $ProjectDir ".claude\skills"
if (Test-Path $ProjectSkillsDir) {
    Show-Spinner -ScriptBlock {
        param($src, $dest)
        # Copy subdirectories
        Get-ChildItem $src -Directory | ForEach-Object {
            $skillDest = Join-Path $dest $_.Name
            New-Item -ItemType Directory -Force $skillDest | Out-Null
            Copy-Item -Force "$($_.FullName)\*.md" $skillDest -ErrorAction SilentlyContinue
        }
        # Copy top-level files
        Copy-Item -Force "$src\*.md" $dest -ErrorAction SilentlyContinue
    } -Message "Installing skills" -ArgumentList $ProjectSkillsDir, $SkillsDir
} else {
    Write-Host "`r${Yellow}[!]${Reset} No skills directory found                    "
}

# Step 6: Install hooks
Write-Host "${Gray}  → Installing hooks...${Reset}"
$ProjectHooksDir = Join-Path $ProjectDir ".claude\hooks"
if (Test-Path $ProjectHooksDir) {
    Show-Spinner -ScriptBlock {
        param($src, $dest)
        Copy-Item -Force "$src\*" $dest -ErrorAction SilentlyContinue
    } -Message "Installing hooks" -ArgumentList $ProjectHooksDir, $HooksDir
} else {
    Write-Host "`r${Yellow}[!]${Reset} No hooks directory found                    "
}

# Step 7: Copy PowerShell scripts
Write-Host "${Gray}  → Installing PowerShell scripts...${Reset}"
Show-Spinner -ScriptBlock {
    param($src, $dest)
    Copy-Item -Force "$src\*.ps1" $dest -ErrorAction SilentlyContinue
    Copy-Item -Force "$src\*.bat" $dest -ErrorAction SilentlyContinue
} -Message "Installing PowerShell scripts" -ArgumentList $BinDir, $GlobalBinDir

# Step 8: Copy shell scripts (for Git Bash/WSL)
Write-Host "${Gray}  → Installing shell scripts...${Reset}"
Show-Spinner -ScriptBlock {
    param($src, $dest)
    Copy-Item -Force "$src\*.sh" $dest -ErrorAction SilentlyContinue
} -Message "Installing shell scripts" -ArgumentList $BinDir, $GlobalBinDir

# Step 9: Add to PATH
Write-Host "${Gray}  → Updating PATH configuration...${Reset}"

# Check if already in PATH (current session)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$GlobalBinDir*") {
    # Add to user PATH
    $newPath = $currentPath + ";$GlobalBinDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "`r${Green}[✓]${Reset} Added to user PATH                    "
} else {
    Write-Host "`r${Green}[✓]${Reset} Already in PATH configuration                    "
}

# Success message
Write-Host ""
Write-Host "${Cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${Reset}"
Write-Host "${Green}[✓] Installation complete!${Reset}"
Write-Host ""
Write-Host "${Gray}Installed components:${Reset}"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Agents${Reset}        → ~/.claude/agents/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Commands${Reset}      → ~/.claude/commands/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Skills${Reset}        → ~/.claude/skills/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Hooks${Reset}         → ~/.claude/hooks/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Scripts${Reset}       → ~/.claude/bin/"
Write-Host ""
Write-Host "${Gray}Available commands:${Reset}"
Write-Host "  ${Cyan}*${Reset} ${Yellow}flow${Reset}          - Main Maven Flow command"
Write-Host "  ${Cyan}*${Reset} ${YELLOW}flow-prd${Reset}      - Generate PRDs"
Write-Host "  ${Cyan}*${Reset} ${YELLOW}flow-convert${Reset}  - Convert PRDs to JSON"
Write-Host "  ${Cyan}*${Reset} ${YELLOW}flow-update${Reset}   - Update Maven Flow"
Write-Host ""
Write-Host "${Yellow}[!] Action required:${Reset}"
Write-Host "  ${YELLOW}Restart your terminal${Reset} to use the new commands"
Write-Host ""
Write-Host "${Cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${Reset}"
