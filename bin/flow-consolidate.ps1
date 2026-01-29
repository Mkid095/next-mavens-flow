#!/usr/bin/env pwsh
# Maven Flow Consolidate - PowerShell wrapper
param(
    [Parameter(Position=0)]
    [string]$PrdName
)

$ErrorActionPreference = 'Continue'

# Box drawing
$BoxTop =    "+============================================================+"
$BoxTitle =  "|         Maven Flow - Error Consolidation                   |"
$BoxBottom = "+============================================================+"

Write-Host ""
Write-Host $BoxTop -ForegroundColor Cyan
Write-Host $BoxTitle -ForegroundColor Cyan
Write-Host $BoxBottom -ForegroundColor Cyan
Write-Host ""

# Help
if ($PrdName -eq "--help" -or $PrdName -eq "-h") {
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-consolidate [prd-name]" -ForegroundColor White
    Write-Host ""
    Write-Host "  Arguments:" -ForegroundColor Gray
    Write-Host "    prd-name    Optional: Specific PRD to consolidate (auto-detects if omitted)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Description:" -ForegroundColor Gray
    Write-Host "    Fix errors found during testing" -ForegroundColor Gray
    Write-Host "    Reads error log from docs/errors-[feature-name].md" -ForegroundColor Gray
    Write-Host "    Re-runs ONLY affected steps (not entire stories)" -ForegroundColor Gray
    Write-Host "    Does NOT reimplement completed features" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Check if claude is available
$claudeExe = Get-Command "claude" -ErrorAction SilentlyContinue
if (-not $claudeExe) {
    Write-Host "  [ERROR] Claude CLI not found in PATH" -ForegroundColor Red
    Write-Host "  [INFO] Install with: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Starting error consolidation..." -ForegroundColor Yellow
Write-Host ""

# Build the command
if ($PrdName) {
    Write-Host "  Consolidating PRD: " -NoNewline -ForegroundColor Gray
    Write-Host "$PrdName" -ForegroundColor Cyan
    Write-Host ""
    $Prompt = "/flow-consolidate $PrdName"
} else {
    Write-Host "  Auto-detecting PRD to consolidate..." -ForegroundColor Gray
    Write-Host ""
    $Prompt = "/flow-consolidate"
}

# Execute
& claude --dangerously-skip-permissions $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|              [OK] Consolidation Complete                   |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Re-run flow-test to verify all fixes" -ForegroundColor Gray
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|             [ERROR] Consolidation Failed                   |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
}
Write-Host ""

exit $ExitCode
