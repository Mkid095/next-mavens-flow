# Maven Flow - PowerShell wrapper (streams real-time output)
param(
    [string[]]$ArgsArray,
    [int]$MaxIterations = 100
)

# Parse command and arguments
$Command = "start"
$ExtraArgs = @()

foreach ($arg in $ArgsArray) {
    switch ($arg) {
        "status" { $Command = "status" }
        "continue" { $Command = "continue" }
        "reset" { $Command = "reset" }
        "test" { $Command = "test" }
        "consolidate" { $Command = "consolidate" }
        "help" { $Command = "help" }
        "--help" { $Command = "help" }
        "-h" { $Command = "help" }
        default {
            if ($arg -match "^\d+$") {
                $MaxIterations = [int]$arg
            } else {
                $ExtraArgs += $arg
            }
        }
    }
}

# Display header
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# Handle help command
if ($Command -eq "help") {
    Write-Host "  Usage:" -ForegroundColor Yellow
    Write-Host "    flow [command] [options]" -ForegroundColor White
    Write-Host ""
    Write-Host "  Commands:" -ForegroundColor Yellow
    Write-Host "    start [iterations]  Start autonomous development (default: 100)" -ForegroundColor White
    Write-Host "    status             Show current flow status" -ForegroundColor White
    Write-Host "    continue [iterations] Resume flow execution" -ForegroundColor White
    Write-Host "    reset              Reset flow state" -ForegroundColor White
    Write-Host "    test               Run flow tests" -ForegroundColor White
    Write-Host "    consolidate        Consolidate completed stories" -ForegroundColor White
    Write-Host "    help, --help, -h   Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "  Examples:" -ForegroundColor Yellow
    Write-Host "    flow start          Start with 100 iterations" -ForegroundColor Gray
    Write-Host "    flow start 50       Start with 50 iterations" -ForegroundColor Gray
    Write-Host "    flow continue        Resume flow execution" -ForegroundColor Gray
    Write-Host "    flow status          Check current status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host "  Command: /flow $Command" -ForegroundColor Yellow
Write-Host "  Max iterations: $MaxIterations" -ForegroundColor Gray
Write-Host ""

# Build the flow prompt
if ($Command -eq "start") {
    $Prompt = "/flow start $MaxIterations"
} elseif ($Command -eq "continue" -and $ExtraArgs.Count -eq 0) {
    $Prompt = "/flow continue $MaxIterations"
} elseif ($ExtraArgs.Count -gt 0) {
    $Prompt = "/flow $Command " + ($ExtraArgs -join " ")
} else {
    $Prompt = "/flow $Command"
}

Write-Host "  Starting Maven Flow..." -ForegroundColor Yellow
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

# Call claude directly and stream output
& claude --dangerously-skip-permissions -p $Prompt

$ExitCode = $LASTEXITCODE

# Show completion
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

if ($ExitCode -eq 0) {
    Write-Host "  [OK] Maven Flow complete" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Maven Flow failed (exit code: $ExitCode)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

exit $ExitCode
