#!/usr/bin/env pwsh
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
$Esc = [char]0x1b
$Cyan = "${Esc}[36m"
$Green = "${Esc}[32m"
$Yellow = "${Esc}[33m"
$Blue = "${Esc}[34m"
$Red = "${Esc}[31m"
$Gray = "${Esc}[90m"
$Reset = "${Esc}[0m"

# Print header function
function Print-Header {
    Write-Host ""
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host "${Cyan}|           Maven Flow - Global Installation Manager         |${Reset}"
    Write-Host "${Cyan}+============================================================+${Reset}"
    Write-Host ""
}

# Show header
Print-Header

Write-Host "${Blue}>> Installing Maven Flow globally${Reset}"
Write-Host ""

# Get script directory - $PSScriptRoot is already the bin directory
$BinDir = $PSScriptRoot
$ProjectDir = Split-Path -Parent $BinDir

# Claude directories
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$AgentsDir = Join-Path $ClaudeDir "agents"
$CommandsDir = Join-Path $ClaudeDir "commands"
$SkillsDir = Join-Path $ClaudeDir "skills"
$HooksDir = Join-Path $ClaudeDir "hooks"
$GlobalBinDir = Join-Path $ClaudeDir "bin"

# Step 1: Remove old maven-flow subfolder if exists
Write-Host "${Gray}  -> Cleaning up old installation...${Reset}"
$OldMavenFlowDir = Join-Path $ClaudeDir "maven-flow"
if (Test-Path $OldMavenFlowDir) {
    Remove-Item -Recurse -Force $OldMavenFlowDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK]${Reset} Removed old maven-flow directory"
} else {
    Write-Host "  ${Gray}[skip]${Reset} No old installation to remove"
}

# Step 2: Create required directories
Write-Host "${Gray}  -> Creating Claude directories...${Reset}"
New-Item -ItemType Directory -Force $AgentsDir | Out-Null
New-Item -ItemType Directory -Force $CommandsDir | Out-Null
New-Item -ItemType Directory -Force $SkillsDir | Out-Null
New-Item -ItemType Directory -Force $HooksDir | Out-Null
New-Item -ItemType Directory -Force $GlobalBinDir | Out-Null
Write-Host "  ${Green}[OK]${Reset} Directories created"

# Step 3: Install agents
Write-Host "${Gray}  -> Installing agents...${Reset}"
$ProjectAgentsDir = Join-Path $ProjectDir ".claude\agents"
if (Test-Path $ProjectAgentsDir) {
    Copy-Item -Force "$ProjectAgentsDir\*.md" $AgentsDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK]${Reset} Agents installed"
} else {
    Write-Host "  ${Yellow}[!]${Reset} No agents directory found"
}

# Step 4: Install commands
Write-Host "${Gray}  -> Installing commands...${Reset}"
$ProjectCommandsDir = Join-Path $ProjectDir ".claude\commands"
if (Test-Path $ProjectCommandsDir) {
    Copy-Item -Force "$ProjectCommandsDir\*.md" $CommandsDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK]${Reset} Commands installed"
} else {
    Write-Host "  ${Yellow}[!]${Reset} No commands directory found"
}

# Step 5: Install skills
Write-Host "${Gray}  -> Installing skills...${Reset}"
$ProjectSkillsDir = Join-Path $ProjectDir ".claude\skills"
if (Test-Path $ProjectSkillsDir) {
    # Copy subdirectories
    Get-ChildItem $ProjectSkillsDir -Directory | ForEach-Object {
        $skillDest = Join-Path $SkillsDir $_.Name
        New-Item -ItemType Directory -Force $skillDest | Out-Null
        Copy-Item -Force "$($_.FullName)\*.md" $skillDest -ErrorAction SilentlyContinue
    }
    # Copy top-level files
    Copy-Item -Force "$ProjectSkillsDir\*.md" $SkillsDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK]${Reset} Skills installed"
} else {
    Write-Host "  ${Yellow}[!]${Reset} No skills directory found"
}

# Step 6: Install hooks
Write-Host "${Gray}  -> Installing hooks...${Reset}"
$ProjectHooksDir = Join-Path $ProjectDir ".claude\hooks"
if (Test-Path $ProjectHooksDir) {
    Copy-Item -Force "$ProjectHooksDir\*" $HooksDir -ErrorAction SilentlyContinue
    Write-Host "  ${Green}[OK]${Reset} Hooks installed"
} else {
    Write-Host "  ${Yellow}[!]${Reset} No hooks directory found"
}

# Step 7: Copy PowerShell scripts
Write-Host "${Gray}  -> Installing PowerShell scripts...${Reset}"
Copy-Item -Force "$BinDir\*.ps1" $GlobalBinDir -ErrorAction SilentlyContinue
Copy-Item -Force "$BinDir\*.bat" $GlobalBinDir -ErrorAction SilentlyContinue
Write-Host "  ${Green}[OK]${Reset} PowerShell scripts installed"

# Step 8: Copy shell scripts (for Git Bash/WSL)
Write-Host "${Gray}  -> Installing shell scripts...${Reset}"
Copy-Item -Force "$BinDir\*.sh" $GlobalBinDir -ErrorAction SilentlyContinue
Write-Host "  ${Green}[OK]${Reset} Shell scripts installed"

# Step 9: Add to PATH
Write-Host "${Gray}  -> Updating PATH configuration...${Reset}"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$GlobalBinDir*") {
    $newPath = $currentPath + ";" + $GlobalBinDir
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  ${Green}[OK]${Reset} Added to user PATH"
} else {
    Write-Host "  ${Green}[OK]${Reset} Already in PATH configuration"
}

# Success message
Write-Host ""
Write-Host "${Cyan}============================================================${Reset}"
Write-Host "${Green}[OK] Installation complete!${Reset}"
Write-Host ""
Write-Host "${Gray}Installed components:${Reset}"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Agents${Reset}        -> ~/.claude/agents/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Commands${Reset}      -> ~/.claude/commands/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Skills${Reset}        -> ~/.claude/skills/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Hooks${Reset}         -> ~/.claude/hooks/"
Write-Host "  ${Cyan}*${Reset} ${Yellow}Scripts${Reset}       -> ~/.claude/bin/"
Write-Host ""
Write-Host "${Gray}Available commands:${Reset}"
Write-Host "  ${Cyan}*${Reset} ${Yellow}flow${Reset}          - Main Maven Flow command"
Write-Host "  ${Cyan}*${Reset} ${Yellow}flow-prd${Reset}      - Generate PRDs"
Write-Host "  ${Cyan}*${Reset} ${Yellow}flow-convert${Reset}  - Convert PRDs to JSON"
Write-Host "  ${Cyan}*${Reset} ${Yellow}flow-update${Reset}   - Update Maven Flow"
Write-Host ""
Write-Host "${Yellow}[!] Action required:${Reset}"
Write-Host "  ${Yellow}Restart your terminal${Reset} to use the new commands"
Write-Host ""
Write-Host "${Cyan}============================================================${Reset}"
