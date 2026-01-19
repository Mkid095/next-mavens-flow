# Maven Flow PRD - PowerShell wrapper
param([string[]]$ArgsArray)

Write-Host ""
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host "|        Maven Flow - PRD Generator & Requirements Analyst    |" -ForegroundColor Cyan
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host ""

if (-not $ArgsArray) {
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-prd <feature description>" -ForegroundColor White
    Write-Host ""
    Write-Host "  Example: " -ForegroundColor Gray
    Write-Host "    flow-prd create a user authentication system" -ForegroundColor White
    Write-Host "    flow-prd build an e-commerce shopping cart" -ForegroundColor White
    Write-Host ""
    exit 1
}

$Description = $ArgsArray -join " "
Write-Host "  Generating PRD for: " -NoNewline -ForegroundColor Blue
Write-Host $Description -ForegroundColor Yellow
Write-Host ""
Write-Host "  -> Analyzing requirements..." -ForegroundColor Gray
Write-Host ""

$Prompt = "/flow-prd $Description"
& claude --dangerously-skip-permissions -p $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|                   [OK] PRD GENERATED                     |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-convert <feature>    Convert to JSON" -ForegroundColor Gray
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|                 [ERROR] GENERATION FAILED                  |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
}
Write-Host ""

exit $ExitCode
