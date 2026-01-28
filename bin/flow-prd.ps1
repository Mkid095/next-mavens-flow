# Maven Flow PRD - PowerShell wrapper
param([Parameter(ValueFromRemainingArguments)]$ArgsArray)

Write-Host ""
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host "|        Maven Flow - PRD Generator & Requirements Analyst    |" -ForegroundColor Cyan
Write-Host "+============================================================+" -ForegroundColor Cyan
Write-Host ""

if (-not $ArgsArray) {
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-prd <feature description>" -ForegroundColor White
    Write-Host ""
    Write-Host "  Examples: " -ForegroundColor Gray
    Write-Host "    flow-prd plan" -ForegroundColor White
    Write-Host "    flow-prd user authentication with login" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Join all arguments with spaces
$Description = $ArgsArray | ForEach-Object { $_ } | Out-String
$Description = $Description.Trim().Replace("`n", " ").Replace("`r", " ")

# If description contains "plan.md", use plan mode
if ($Description -match "plan\.md" -or $Description -eq "plan") {
    $Description = "plan"
}

Write-Host "  Mode: " -NoNewline -ForegroundColor Gray
if ($Description -eq "plan") {
    Write-Host "PLAN (reading plan.md)" -ForegroundColor Green
} elseif ($Description -match "^fix ") {
    Write-Host "FIX (updating existing PRDs)" -ForegroundColor Yellow
} else {
    Write-Host "SINGLE PRD (from description)" -ForegroundColor Blue
}
Write-Host ""

Write-Host "  Forwarding to Claude Code..." -ForegroundColor Gray
Write-Host ""

$Prompt = "/flow-prd $Description"
& claude --dangerously-skip-permissions $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|                   [OK] PRD GENERATED                     |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Next: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-convert --all    Convert to JSON" -ForegroundColor Gray
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|                 [ERROR] GENERATION FAILED                  |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
}
Write-Host ""

exit $ExitCode
