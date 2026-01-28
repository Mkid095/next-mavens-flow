# Maven Flow Update - PowerShell wrapper
param([string[]]$ArgsArray)

$Command = if ($ArgsArray) { $ArgsArray -join " " } else { "sync" }

Write-Host ""
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host "|           Maven Flow - System Updater                    |" -ForegroundColor Cyan
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host ""

switch ($Command) {
    "check" {
        Write-Host "  Checking for updates..." -ForegroundColor Yellow
        Write-Host "  -> Comparing with GitHub repository" -ForegroundColor Gray
    }
    "sync" {
        Write-Host "  Updating Maven Flow..." -ForegroundColor Yellow
        Write-Host "  -> Fetching latest changes" -ForegroundColor Gray
        Write-Host "  -> Syncing components" -ForegroundColor Gray
    }
    "force" {
        Write-Host "  Force updating..." -ForegroundColor Yellow
        Write-Host "  -> Reinstalling all components" -ForegroundColor Gray
    }
    "help" {
        Write-Host "  Maven Flow Updater Commands:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    flow-update check    Check for updates" -ForegroundColor Yellow
        Write-Host "    flow-update sync     Fetch and apply updates" -ForegroundColor Yellow
        Write-Host "    flow-update force    Force reinstall" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    default {
        Write-Host "  Unknown command: $Command" -ForegroundColor Red
        Write-Host "  Run 'flow-update help' for options" -ForegroundColor Gray
        exit 1
    }
}

Write-Host ""

$Prompt = "/flow-update $Command"
& claude --dangerously-skip-permissions $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|                 [OK] UPDATE COMPLETE                       |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  System ready:" -ForegroundColor Gray
    Write-Host "    -> flow start     Continue development" -ForegroundColor Yellow
    Write-Host "    -> flow status    Check current state" -ForegroundColor Yellow
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|               [ERROR] UPDATE FAILED                        |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
}
Write-Host ""

exit $ExitCode
