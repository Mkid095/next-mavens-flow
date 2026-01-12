# Sync Maven Flow files from local repo to global ~/.claude directory (PowerShell)

$ErrorActionPreference = "Stop"

$Green = [ConsoleColor]::Green
$Blue = [ConsoleColor]::Blue

Write-Host "Maven Flow - Sync to Global ~/.claude" -ForegroundColor $Blue
Write-Host "========================================"
Write-Host ""

# Define source and destination
$SrcDir = $PSScriptRoot
$DstDir = "$env:USERPROFILE\.claude"

# Files/directories to sync
$Files = @(
  ".claude\commands\flow.md",
  ".claude\shared\mcp-tools.md",
  ".claude\shared\agent-patterns.md",
  ".claude\agents\development.md",
  ".claude\agents\refactor.md",
  ".claude\agents\security.md",
  ".claude\agents\quality.md",
  ".claude\adrs\001-story-level-mcp-assignment.md",
  ".claude\skills\flow-convert\SKILL.md"
)

# Sync each file
foreach ($File in $Files) {
  $Src = Join-Path $SrcDir $File
  $Dst = Join-Path $DstDir $File
  
  # Create destination directory if it doesn't exist
  $DstDir = Split-Path $Dst -Parent
  if (-not (Test-Path $DstDir)) {
    New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
  }
  
  # Copy file
  if (Test-Path $Src) {
    Copy-Item $Src $Dst -Force
    Write-Host "✓ Synced: $File" -ForegroundColor $Green
  } else {
    Write-Host "⚠ Source not found: $Src"
  }
}

Write-Host ""
Write-Host "Sync complete!" -ForegroundColor $Green
Write-Host ""
Write-Host "Files synced from: $SrcDir"
Write-Host "              to: $DstDir"
