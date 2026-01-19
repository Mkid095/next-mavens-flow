# Maven Flow Convert - PowerShell wrapper
param([string[]]$ArgsArray)

$BoxTop =    "+============================================================+"
$BoxTitle =  "|           Maven Flow - PRD Format Converter               |"
$BoxBottom = "+============================================================+"

Write-Host ""
Write-Host $BoxTop -ForegroundColor Cyan
Write-Host $BoxTitle -ForegroundColor Cyan
Write-Host $BoxBottom -ForegroundColor Cyan
Write-Host ""

# Check for --all flag or no arguments
if ($ArgsArray.Count -eq 0 -or $ArgsArray[0] -eq "--all") {
    if ($ArgsArray.Count -eq 0 -or $ArgsArray[0] -eq "--all") {
        Write-Host "  Converting all markdown PRDs to JSON..." -ForegroundColor Yellow
        Write-Host ""

        # Find all markdown PRDs
        $prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.md" -ErrorAction SilentlyContinue

        if ($prdFiles.Count -eq 0) {
            Write-Host "  [!] No markdown PRDs found in docs/" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Usage: " -ForegroundColor Gray
            Write-Host "    flow-convert <feature-name>" -ForegroundColor White
            Write-Host ""
            exit 1
        }

        Write-Host "  Found " -NoNewline -ForegroundColor Green
        Write-Host "$($prdFiles.Count) markdown PRD(s)" -ForegroundColor Green
        Write-Host ""

        # Convert each one
        $successCount = 0
        $failCount = 0

        foreach ($prd in $prdFiles) {
            $feature = $prd.Name -replace "prd-" -replace "\.md$"
            Write-Host ""
            Write-Host "  Converting: " -NoNewline -ForegroundColor Cyan
            Write-Host "$feature" -ForegroundColor Yellow
            Write-Host "..."

            $Prompt = "/flow-convert $feature"
            $result = & claude --dangerously-skip-permissions -p $Prompt 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host " [OK]" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                $failCount++
            }
        }

        Write-Host ""
        Write-Host "==============================================================================" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Summary:" -ForegroundColor Gray
        Write-Host "    Converted: " -NoNewline -ForegroundColor Green
        Write-Host "$successCount PRD(s)" -ForegroundColor Green
        if ($failCount -gt 0) {
            Write-Host "    Failed: " -NoNewline -ForegroundColor Red
            Write-Host "$failCount PRD(s)" -ForegroundColor Red
        }
        Write-Host ""

        exit 0
    }
}

# Single PRD conversion
if ($ArgsArray.Count -eq 0) {
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow-convert <feature-name>" -ForegroundColor White
    Write-Host "    flow-convert --all    Convert all PRDs" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Example: " -ForegroundColor Gray
    Write-Host "    flow-convert desktop-wrapper" -ForegroundColor White
    Write-Host ""
    exit 1
}

$Feature = $ArgsArray[0]

Write-Host "  Converting: " -NoNewline -ForegroundColor Blue
Write-Host $Feature -ForegroundColor Yellow
Write-Host ""
Write-Host "  -> Reading from: docs/prd-$Feature.md" -ForegroundColor Gray
Write-Host "  -> Writing to: docs/prd-$Feature.json" -ForegroundColor Gray
Write-Host ""

$Prompt = "/flow-convert $Feature"
& claude --dangerously-skip-permissions -p $Prompt
$ExitCode = $LASTEXITCODE

Write-Host ""
if ($ExitCode -eq 0) {
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host "|                [OK] CONVERSION COMPLETE                   |" -ForegroundColor Green
    Write-Host "+============================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Created: docs/prd-$Feature.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Next: " -NoNewline -ForegroundColor Yellow
    Write-Host "flow start    Begin development" -ForegroundColor Gray
} else {
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host "|              [ERROR] CONVERSION FAILED                    |" -ForegroundColor Red
    Write-Host "+============================================================+" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Make sure docs/prd-$Feature.md exists" -ForegroundColor Gray
}
Write-Host ""

exit $ExitCode
