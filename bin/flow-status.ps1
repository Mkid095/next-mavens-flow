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
    if (-not $storyCount -or $storyCount -match 'error|Error') { continue }
    $totalStories += [int]$storyCount

    $completedCount = 0
    $currentStoryData = $null

    for ($j = 0; $j -lt [int]$storyCount; $j++) {
        $passesOutput = jq ".userStories[$j].passes" $prd.FullName 2>$null
        $passesTrimmed = if ($passesOutput) { $passesOutput.Trim() } else { "" }
        # Story is complete if passes is NOT "false" (matches Get-IncompleteStory logic)
        $isComplete = -not ($passesTrimmed -eq "false" -or $passesTrimmed -eq "false`n" -or $passesTrimmed -match "^false")
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
    $progressPct = if ([int]$storyCount -gt 0) { [math]::Round(($completedCount / [int]$storyCount) * 100) } else { 0 }

    if ($completedCount -eq [int]$storyCount) {
        $statusText = "COMPLETE ($completedCount/$storyCount) "
        $featureDisplay = if ($featureName.Length -gt 48) { $featureName.Substring(0, 45) + "..." } else { $featureName }
        $countDisplay = "$completedCount/$storyCount"
        Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "│ " -NoNewline -ForegroundColor Green
        Write-Host "✓ $featureDisplay" -NoNewline -ForegroundColor Green
        Write-Host (" " * [math]::Max(0, 51 - $featureDisplay.Length)) -NoNewline
        Write-Host $statusText.PadRight(58) -NoNewline -ForegroundColor Green
        Write-Host "│" -ForegroundColor Green
        Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    } else {
        $barLength = 30
        $filled = [math]::Floor($barLength * $completedCount / [int]$storyCount)
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
        Write-Host "$completedCount/$storyCount" -NoNewline -ForegroundColor Gray
        Write-Host ")" -NoNewline -ForegroundColor Gray
        Write-Host (" " * [math]::Max(0, 12 - "$completedCount/$storyCount".Length)) -NoNewline
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
