#!/usr/bin/env pwsh
# Maven Flow Test - PowerShell wrapper
param(
    [Parameter(Position=0)]
    [string]$PrdName
)

$ErrorActionPreference = 'Continue'

# Box drawing
$BoxTop =    "+============================================================+"
$BoxTitle =  "|           Maven Flow - Feature Testing                    |"
$BoxBottom = "+============================================================+"

Write-Host ""
Write-Host $BoxTop -ForegroundColor Cyan
Write-Host $BoxTitle -ForegroundColor Cyan
Write-Host $BoxBottom -ForegroundColor Cyan
Write-Host ""

# Help
if ($PrdName -eq "--help" -or $PrdName -eq "-h") {
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-test [prd-name]" -ForegroundColor White
    Write-Host ""
    Write-Host "  Arguments:" -ForegroundColor Gray
    Write-Host "    prd-name    Optional: Specific PRD to test (auto-detects if omitted)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Description:" -ForegroundColor Gray
    Write-Host "    Run comprehensive testing of all implemented features" -ForegroundColor Gray
    Write-Host "    Uses chrome-devtools MCP for browser automation" -ForegroundColor Gray
    Write-Host "    Tests all completed stories (where passes: true)" -ForegroundColor Gray
    Write-Host "    Creates error log at docs/errors-[feature-name].md" -ForegroundColor Gray
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

Write-Host "  Starting comprehensive feature testing..." -ForegroundColor Yellow
Write-Host ""

# Build the command
if ($PrdName) {
    Write-Host "  Testing PRD: " -NoNewline -ForegroundColor Gray
    Write-Host "$PrdName" -ForegroundColor Cyan
    Write-Host ""
    $Prompt = "/flow-test $PrdName"
} else {
    Write-Host "  Auto-detecting PRD to test..." -ForegroundColor Gray
    Write-Host ""
    $Prompt = "/flow-test"
}

# Execute
& claude --dangerously-skip-permissions $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|                 [OK] Testing Complete                       |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Check docs/errors-*.md for any issues found" -ForegroundColor Gray
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|               [ERROR] Testing Failed                       |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
}
Write-Host ""

exit $ExitCode
