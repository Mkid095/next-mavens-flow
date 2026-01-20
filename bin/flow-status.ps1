# Maven Flow Status Command
# Self-contained script to show PRD status

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                    Maven Flow - Project Status                     " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

$prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
if ($prdFiles.Count -eq 0) {
    Write-Host "  [ERROR] No PRD JSON files found in docs/" -ForegroundColor Red
    Write-Host "  Run: flow-prd plan" -ForegroundColor Yellow
    exit 1
}

$totalStories = 0
$totalCompleted = 0

foreach ($prd in $prdFiles | Sort-Object Name) {
    $featureName = $prd.Name -replace "prd-", "" -replace ".json", ""
    $storyCount = jq '.userStories | length' $prd.FullName 2>$null
    # Validate storyCount is numeric and non-negative (matches Get-IncompleteStory logic)
    if (-not $storyCount -or $storyCount -match 'error|Error|parse|invalid') { continue }
    $storyCountInt = 0
    if (-not [int]::TryParse($storyCount, [ref]$storyCountInt)) { continue }
    if ($storyCountInt -lt 0) { continue }
    $totalStories += $storyCountInt

    $completedCount = 0
    $currentStoryData = $null

    for ($j = 0; $j -lt $storyCountInt; $j++) {
        $passesOutput = jq ".userStories[$j].passes" $prd.FullName 2>$null
        $passesTrimmed = if ($passesOutput) { $passesOutput.Trim() } else { "" }
        # Story is complete if passes is NOT "false" (matches Get-IncompleteStory logic)
        # Case-insensitive check for "false" (defensive programming)
        $isComplete = -not ($passesTrimmed -ieq "false" -or $passesTrimmed -ieq "false`n" -or $passesTrimmed -imatch "^false")
        if ($isComplete) {
            $completedCount++
            $totalCompleted++
        } else {
            if ($null -eq $currentStoryData) {
                $currentStoryData = jq -r ".userStories[$j]" $prd.FullName 2>$null
            }
        }
    }

    # Display progress bar
    $progressPct = if ($storyCountInt -gt 0) { [math]::Round(($completedCount / $storyCountInt) * 100) } else { 0 }

    if ($completedCount -eq $storyCountInt) {
        $statusText = "COMPLETE ($completedCount/$storyCountInt) "
        $featureDisplay = if ($featureName.Length -gt 48) { $featureName.Substring(0, 45) + "..." } else { $featureName }
        $countDisplay = "$completedCount/$storyCountInt"
        Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "│ " -NoNewline -ForegroundColor Green
        Write-Host "✓ $featureDisplay" -NoNewline -ForegroundColor Green
        Write-Host (" " * [math]::Max(0, 51 - $featureDisplay.Length)) -NoNewline
        Write-Host $statusText.PadRight(58) -NoNewline -ForegroundColor Green
        Write-Host "│" -ForegroundColor Green
        Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    } else {
        $barLength = 30
        $filled = [math]::Floor($barLength * $completedCount / $storyCountInt)
        $empty = $barLength - $filled
        $progressBar = "█" * $filled + "░" * $empty

        Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
        Write-Host "│ " -NoNewline -ForegroundColor Cyan
        Write-Host "$featureName" -NoNewline -ForegroundColor White
        Write-Host " " -NoNewline
        Write-Host "[$progressBar]" -NoNewline -ForegroundColor Yellow
        Write-Host " " -NoNewline
        Write-Host "$progressPct%" -NoNewline -ForegroundColor Cyan
        Write-Host " (" -NoNewline -ForegroundColor Gray
        Write-Host "$completedCount/$storyCountInt" -NoNewline -ForegroundColor Gray
        Write-Host ")" -NoNewline -ForegroundColor Gray
        Write-Host (" " * [math]::Max(0, 12 - "$completedCount/$storyCountInt".Length)) -NoNewline
        Write-Host "│" -ForegroundColor Cyan
        Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

        # Show current story
        if ($currentStoryData) {
            $storyId = $currentStoryData | jq -r '.id' 2>$null
            $storyTitle = $currentStoryData | jq -r '.title' 2>$null
            # Null safety for display
            if (-not $storyId -or $storyId -eq "null") { $storyId = "UNKNOWN" }
            if (-not $storyTitle -or $storyTitle -eq "null") { $storyTitle = "No title" }

            Write-Host ""
            Write-Host "  CURRENT STORY: $storyId - $storyTitle" -ForegroundColor Yellow
        }
    }

    Write-Host ""
}

# Overall progress
$overallPct = if ($totalStories -gt 0) { [math]::Round(($totalCompleted / $totalStories) * 100) } else { 0 }
$overallFilled = [math]::Floor(30 * $totalCompleted / [math]::Max(1, $totalStories))
$overallBar = "█" * $overallFilled + "░" * (30 - $overallFilled)
$overallCountDisplay = "$totalCompleted/$totalStories"

Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│ " -NoNewline -ForegroundColor Cyan
Write-Host "OVERALL PROGRESS" -NoNewline -ForegroundColor White
Write-Host " " * 38 -NoNewline
Write-Host "[$overallBar]" -NoNewline -ForegroundColor Green
Write-Host " " -NoNewline
Write-Host "$overallPct%" -NoNewline -ForegroundColor Cyan
Write-Host " (" -NoNewline -ForegroundColor Gray
Write-Host "$totalCompleted/$totalStories" -NoNewline -ForegroundColor Gray
Write-Host ")" -NoNewline -ForegroundColor Gray
Write-Host (" " * [math]::Max(0, 12 - $overallCountDisplay.Length)) -NoNewline
Write-Host "│" -ForegroundColor Cyan
Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

Write-Host ""
Write-Host "  Run 'flow-continue' to resume, or 'flow-help' for more commands" -ForegroundColor Gray
Write-Host ""
