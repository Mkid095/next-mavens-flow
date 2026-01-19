# Maven Flow - Orchestrator wrapper (uses jq for JSON parsing)
param(
    [string[]]$ArgsArray,
    [int]$MaxIterations = 100
)

# Parse command
$Command = "start"
foreach ($arg in $ArgsArray) {
    switch ($arg) {
        "status" { $Command = "status"; break }
        "continue" { $Command = "continue"; break }
        "reset" { $Command = "reset"; break }
        "test" { $Command = "test"; break }
        "consolidate" { $Command = "consolidate"; break }
        "help" { $Command = "help"; break }
        "--help" { $Command = "help"; break }
        "-h" { $Command = "help"; break }
        default {
            if ($arg -match "^\d+$") { $MaxIterations = [int]$arg }
        }
    }
}

# Show header
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""

# Handle help
if ($Command -eq "help") {
    Write-Host "  Usage: flow [command] [iterations]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Commands:" -ForegroundColor Yellow
    Write-Host "    start [iterations]  Start flow (default: 100 iterations)" -ForegroundColor White
    Write-Host "    status              Show flow status" -ForegroundColor White
    Write-Host "    continue            Resume flow" -ForegroundColor White
    Write-Host "    reset               Reset all stories to incomplete" -ForegroundColor White
    Write-Host "    help, --help, -h    Show this help" -ForegroundColor White
    Write-Host ""
    Write-Host "  Flow Process:" -ForegroundColor Gray
    Write-Host "    1. Scan docs/prd-*.json for incomplete stories" -ForegroundColor Gray
    Write-Host "    2. Process ONE story at a time via Claude Code" -ForegroundColor Gray
    Write-Host "    3. Update JSON (passes: true) after completion" -ForegroundColor Gray
    Write-Host "    4. Continue until ALL stories complete" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Handle status command
if ($Command -eq "status") {
    Write-Host "  Scanning PRD files..." -ForegroundColor Yellow
    Write-Host ""

    $prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue
    if ($prdFiles.Count -eq 0) {
        Write-Host "  No PRD JSON files found in docs/" -ForegroundColor Red
        Write-Host "  Run: flow-prd plan" -ForegroundColor Yellow
        exit 1
    }

    $totalStories = 0
    $completedStories = 0

    foreach ($prd in $prdFiles) {
        $storyCount = jq '[.userStories | length]' $prd.FullName 2>$null
        $passCount = jq '[.userStories | select(.passes == true) | length]' $prd.FullName 2>$null
        if ($null -eq $storyCount) { $storyCount = 0 }
        if ($null -eq $passCount) { $passCount = 0 }
        $totalStories += [int]$storyCount
        $completedStories += [int]$passCount

        $feature = $prd.Name -replace "prd-", "" -replace ".json", ""
        Write-Host "  $feature" -ForegroundColor Cyan
        Write-Host "    Stories: " -NoNewline -ForegroundColor Gray
        Write-Host "$passCount/$storyCount complete" -ForegroundColor $(if ($passCount -eq $storyCount) { "Green" } else { "Yellow" })
    }

    Write-Host ""
    Write-Host "  Total: " -NoNewline -ForegroundColor Gray
    Write-Host "$completedStories/$totalStories stories complete" -ForegroundColor $(if ($completedStories -eq $totalStories) { "Green" } else { "Yellow" })
    Write-Host ""
    exit 0
}

# Handle reset command
if ($Command -eq "reset") {
    Write-Host "  Resetting all stories to incomplete..." -ForegroundColor Yellow
    Write-Host ""

    $prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue
    foreach ($prd in $prdFiles) {
        $output = jq '(.userStories | map(.passes = false) | {userStories: .}) | del(.userStories) | . + {userStories}' $prd.FullName 2>$null
        if ($output) {
            $output | Out-File -FilePath $prd.FullName -Encoding UTF8
            Write-Host "  Reset: $($prd.Name)" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "  All stories reset to incomplete" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# MAIN FLOW LOOP
Write-Host "  Command: $Command" -ForegroundColor Yellow
Write-Host "  Max iterations: $MaxIterations" -ForegroundColor Gray
Write-Host ""
Write-Host "  Starting Maven Flow..." -ForegroundColor Yellow
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

# Check for jq
$null = jq --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] jq is required. Install from: https://jqlang.github.io/" -ForegroundColor Red
    exit 1
}

# Check for PRD files
$prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue
if ($prdFiles.Count -eq 0) {
    Write-Host "  [ERROR] No PRD JSON files found in docs/" -ForegroundColor Red
    Write-Host "  Run: flow-prd plan" -ForegroundColor Yellow
    exit 1
}

# Find first incomplete story
$currentPrd = $null
$currentStory = $null
$storyId = $null
$storyIndex = $null

foreach ($prd in $prdFiles | Sort-Object Name) {
    # Check if PRD has incomplete stories
    $incomplete = jq '[.userStories | select(.passes == false)] | length' $prd.FullName 2>$null
    if ([int]$incomplete -gt 0) {
        $currentPrd = $prd.FullName
        # Get first incomplete story
        $storyIndex = jq '[.userStories | to_entries | select(.value.passes == false) | .key | tonumber] | .[0]' $prd.FullName 2>$null
        $currentStory = jq -r ".userStories[$storyIndex]" $prd.FullName 2>$null
        $storyId = jq -r ".userStories[$storyIndex].id" $prd.FullName 2>$null
        break
    }
}

if ($null -eq $currentPrd) {
    Write-Host "  [OK] All PRD stories are complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Run 'flow consolidate' to consolidate memories" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

$featureName = (Split-Path $currentPrd -Leaf) -replace "prd-", "" -replace ".json", ""

Write-Host "  Processing: " -NoNewline -ForegroundColor Cyan
Write-Host "$featureName" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Story: " -NoNewline -ForegroundColor Cyan
Write-Host "$storyId" -ForegroundColor Yellow
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

# Build story prompt for Claude
$storyPrompt = @"
# Maven Flow - Story Execution

**Current Story:** $storyId
**PRD File:** $currentPrd

**Story Data:**
$currentStory

**Your Task:**
Execute this story through all mavenSteps, then output:
<STORY_COMPLETE>
<story_id>$storyId</story_id>
<feature>$featureName</feature_id>
</STORY_COMPLETE>

Do NOT ask questions. Execute the story now.
"@

# Execute Claude with story
& claude --dangerously-skip-permissions -p $storyPrompt
$ExitCode = $LASTEXITCODE

# Update PRD if successful
if ($ExitCode -eq 0) {
    Write-Host ""
    Write-Host "  Updating PRD..." -ForegroundColor Yellow

    # Update passes: true using jq
    $null = jq "(.userStories[$storyIndex] | .passes = true) | {userStories: .} | del(.userStories) | . + {userStories}" $currentPrd 2>$null | Out-File -FilePath $currentPrd -Encoding UTF8

    # Update progress file
    $progressFile = "docs/progress-$featureName.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $progressFile -Value "`n[$timestamp] $storyId - Completed" -Encoding UTF8

    Write-Host "  Story marked complete" -ForegroundColor Green
}

# Show completion
Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

if ($ExitCode -eq 0) {
    Write-Host "  [OK] Story complete - Run 'flow continue' for next story" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Story failed - Fix issues and run 'flow continue'" -ForegroundColor Red
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Gray
Write-Host ""

exit $ExitCode
