# Maven Flow Help Command
# Self-contained script to show help

Write-Host ""
Write-Host "Maven Flow Commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Main Commands:" -ForegroundColor White
Write-Host "  flow [iterations]        Start autonomous flow (default: 100 iterations)" -ForegroundColor White
Write-Host "  flow start [iterations]   Explicit start command" -ForegroundColor White
Write-Host ""
Write-Host "Standalone Commands:" -ForegroundColor White
Write-Host "  flow-status               Show all PRDs and completion status" -ForegroundColor White
Write-Host "  flow-continue [prd]     Continue from last incomplete story" -ForegroundColor White
Write-Host "  flow-help                 Show this help message" -ForegroundColor White
Write-Host ""
Write-Host "Supporting Commands:" -ForegroundColor Gray
Write-Host "  flow-prd plan             Create PRD from plan.md" -ForegroundColor Gray
Write-Host "  flow-convert              Convert markdown to PRD format" -ForegroundColor Gray
Write-Host "  flow-update               Update Maven Flow system" -ForegroundColor Gray
Write-Host ""
Write-Host "Examples:" -ForegroundColor Cyan
Write-Host "  flow                      Start flow" -ForegroundColor White
Write-Host "  flow 50                   Start with max 50 iterations" -ForegroundColor White
Write-Host "  flow-status               Show all PRD status" -ForegroundColor White
Write-Host "  flow-continue database     Continue specific PRD" -ForegroundColor White
Write-Host ""
