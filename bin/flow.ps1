# Maven Flow - Main Orchestrator
# Self-contained script with all logic inline (like Ralph but with Maven Flow features)

param(
    [string[]]$ArgsArray,
    [int]$MaxIterations = 100,
    [int]$BaseCooldownSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#==============================================================================
# CONFIGURATION
#==============================================================================
$MaxConsecutiveFailures = 5
$MaxCooldown = 300  # 5 minutes
$CooldownMultiplier = 2
$MaxRetries = 3
$RetryDelay = 5

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================
function Invoke-ProcessCleanup {
    Write-Host "  [CLEANUP] Checking for stale Node.js processes..." -ForegroundColor Yellow
    try {
        $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
        if ($nodeProcesses) {
            Write-Host "  [CLEANUP] Found $($nodeProcesses.Count) Node.js process(es) - terminating..." -ForegroundColor Yellow
            $nodeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            Write-Host "  [CLEANUP] Cleanup complete" -ForegroundColor Green
        } else {
            Write-Host "  [CLEANUP] No stale processes found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [CLEANUP] Warning: Could not clean up processes: $_" -ForegroundColor Yellow
    }
}

function Invoke-ClaudeWithRetry {
    param([string]$Prompt)

    $result = ""
    $exitCode = 1

    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        try {
            Write-Host "  [EXEC] Calling Claude (attempt $retry/$MaxRetries)..." -ForegroundColor Yellow
            $result = & claude --dangerously-skip-permissions -p $Prompt 2>&1 | Out-String
            $exitCode = $LASTEXITCODE

            $hasPreflightWarning = $result -match "BashTool.*Pre-flight check.*taking longer than expected"
            $hasPromiseRejection = $result -match "promise rejected" -or $result -match "unhandled.*exception"
            $hasConnectionError = $result -match "Connection error" -or $result -match "timed out"

            if ($exitCode -eq 0 -and -not $hasPreflightWarning -and -not $hasPromiseRejection -and -not $hasConnectionError) {
                return @{ Success = $true; Result = $result; ExitCode = $exitCode }
            }

            if ($hasPreflightWarning) { Write-Host "  [RETRY] Pre-flight timeout" -ForegroundColor Yellow }
            elseif ($hasPromiseRejection) { Write-Host "  [RETRY] Promise rejection" -ForegroundColor Yellow }
            elseif ($hasConnectionError) { Write-Host "  [RETRY] Connection error" -ForegroundColor Yellow }
            else { Write-Host "  [RETRY] Exit code: $exitCode" -ForegroundColor Yellow }

            if ($retry -lt $MaxRetries) {
                Invoke-ProcessCleanup
                Write-Host "  [RETRY] Waiting ${RetryDelay}s..." -ForegroundColor Gray
                Start-Sleep -Seconds $RetryDelay
            }
        } catch {
            Write-Host "  [RETRY] Exception: $_" -ForegroundColor Yellow
            $result = "Exception: $_"
            $exitCode = 1

            if ($retry -lt $MaxRetries) {
                Invoke-ProcessCleanup
                Write-Host "  [RETRY] Waiting ${RetryDelay}s..." -ForegroundColor Gray
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }

    return @{ Success = $false; Result = $result; ExitCode = $exitCode }
}

function Get-IncompleteStory {
    $prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
    if ($prdFiles.Count -eq 0) { return $null }

    foreach ($prd in $prdFiles | Sort-Object Name) {
        $storyCount = jq '.userStories | length' $prd.FullName 2>$null
        for ($j = 0; $j -lt [int]$storyCount; $j++) {
            $passes = jq ".userStories[$j].passes" $prd.FullName 2>$null
            if ($passes -eq "false") {
                $storyData = jq ".userStories[$j]" $prd.FullName 2>$null
                $storyId = jq -r ".userStories[$j].id" $prd.FullName 2>$null
                $featureName = $prd.Name -replace "prd-", "" -replace ".json", ""
                return @{
                    StoryId = $storyId
                    FeatureName = $featureName
                    PrdPath = $prd.FullName
                    StoryData = $storyData
                }
            }
        }
    }
    return $null
}

function Show-StoryDisplay {
    param([string]$StoryId, [string]$FeatureName, [string]$StoryData)

    $storyTitle = $storyData | jq -r '.title' 2>$null
    $storyDesc = $storyData | jq -r '.description' 2>$null
    $mavenStepsArray = $storyData | jq -r '.mavenSteps[]?' 2>$null
    $acceptanceCriteria = $storyData | jq -r '.acceptanceCriteria[]?' 2>$null

    Write-Host ""
    Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│ WORKING ON: $FeatureName" -NoNewline -ForegroundColor Cyan
    Write-Host (" " * (63 - $FeatureName.Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────┤" -ForegroundColor Gray
    Write-Host "│ Story: $StoryId" -NoNewline -ForegroundColor White
    Write-Host (" " * (58 - $StoryId.Length)) -NoNewline
    Write-Host "│" -ForegroundColor Gray
    Write-Host "│ Title: " -NoNewline -ForegroundColor Gray
    Write-Host $storyTitle.Substring(0, [math]::Min(54, $storyTitle.Length)).PadRight(54) -NoNewline -ForegroundColor White
    Write-Host "    │" -ForegroundColor Gray

    if ($storyDesc -and $storyDesc.Length -gt 0 -and $storyDesc -ne "null") {
        $descTruncated = if ($storyDesc.Length -gt 54) { $storyDesc.Substring(0, 51) + "..." } else { $storyDesc }
        Write-Host "│ " -NoNewline -ForegroundColor Gray
        Write-Host $descTruncated.PadRight(62) -NoNewline -ForegroundColor Gray
        Write-Host "│" -ForegroundColor Gray
    }

    if ($mavenStepsArray) {
        $stepsList = $mavenStepsArray -join ", "
        $stepsTruncated = if ($stepsList.Length -gt 51) { $stepsList.Substring(0, 48) + "..." } else { $stepsList }
        Write-Host "│ Steps: " -NoNewline -ForegroundColor Gray
        Write-Host $stepsTruncated.PadRight(58) -NoNewline -ForegroundColor Yellow
        Write-Host "│" -ForegroundColor Gray
    }

    if ($acceptanceCriteria) {
        $criteriaList = @($acceptanceCriteria)
        Write-Host "│ Criteria:" -ForegroundColor Gray
        for ($k = 0; $k -lt [math]::Min(2, $criteriaList.Count); $k++) {
            $criterion = $criteriaList[$k]
            $criterionTruncated = if ($criterion.Length -gt 54) { $criterion.Substring(0, 51) + "..." } else { $criterion }
            Write-Host "│   • " -NoNewline -ForegroundColor Gray
            Write-Host $criterionTruncated.PadRight(56) -NoNewline -ForegroundColor White
            Write-Host "│" -ForegroundColor Gray
        }
        if ($criteriaList.Count -gt 2) {
            Write-Host "│   ...and ($($criteriaList.Count - 2)) more" -NoNewline -ForegroundColor Gray
            Write-Host (" " * (57 - "...and ($($criteriaList.Count - 2)) more".Length)) -NoNewline
            Write-Host "│" -ForegroundColor Gray
        }
    }

    Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

#==============================================================================
# MAIN
#==============================================================================

# Check for jq
$null = jq --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [ERROR] jq is required. Install from: https://jqlang.github.io/" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Starting Maven Flow - Max $MaxIterations iterations" -ForegroundColor Yellow
Write-Host "  Base cooldown: ${BaseCooldownSeconds}s (adaptive backoff enabled)" -ForegroundColor Gray
Write-Host ""

# Inline prompt (like Ralph)
$CLAUDE_PROMPT = @"
You are Maven Flow, an autonomous development agent working on a Next Mavens project.

## Your Task

* Read the PRD file to understand the story requirements
* Implement the story completely
* Update the PRD file to mark the story complete (set passes: true)
* Run tests: pnpm run typecheck
* Commit your changes: git add . && git commit -m ""feat: [story-id] [brief description]""

## Completion Signal

After ALL steps are complete, output EXACTLY:
<STORY_COMPLETE>
<story_id>[STORY_ID]</story_id>
<feature>[FEATURE_NAME]</feature>
<maven_steps_completed>all</maven_steps_completed>
</STORY_COMPLETE>

## If Failed

Do NOT output the signal. The orchestrator will retry on the next iteration.
"@

$consecutiveFailures = 0
$currentCooldown = $BaseCooldownSeconds

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host "  Iteration $i of $MaxIterations" -ForegroundColor Yellow
    Write-Host "  Consecutive failures: $consecutiveFailures" -ForegroundColor Gray
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""

    # Circuit breaker
    if ($consecutiveFailures -ge $MaxConsecutiveFailures) {
        Write-Host ""
        Write-Host "===========================================" -ForegroundColor Red
        Write-Host "  CRITICAL: $MaxConsecutiveFailures consecutive failures" -ForegroundColor Red
        Write-Host "  Stopping to prevent resource exhaustion" -ForegroundColor Red
        Write-Host "===========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Try:" -ForegroundColor Cyan
        Write-Host "  1. Restart your computer" -ForegroundColor White
        Write-Host "  2. Run 'flow-continue' after fixing issues" -ForegroundColor White
        Write-Host ""
        exit 1
    }

    # Get next story
    $story = Get-IncompleteStory

    if ($null -eq $story) {
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "  All PRD stories complete after $i iterations!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        exit 0
    }

    Show-StoryDisplay -StoryId $story.StoryId -FeatureName $story.FeatureName -StoryData $story.StoryData

    # Build prompt with story details
    $prompt = "$CLAUDE_PROMPT`n`n## Current Story`n`nStory ID: $($story.StoryId)`nFeature: $($story.FeatureName)`nPRD File: docs/prd-$($story.FeatureName).json`n`nImplement this story now."

    # Execute Claude
    $claudeResponse = Invoke-ClaudeWithRetry -Prompt $prompt

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "  CLAUDE RESPONSE:" -ForegroundColor Gray
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
    Write-Host $claudeResponse.Result
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""

    # Handle result
    if (-not $claudeResponse.Success) {
        $consecutiveFailures++
        $currentCooldown = [math]::Min($MaxCooldown, $BaseCooldownSeconds * [math]::Pow($CooldownMultiplier, $consecutiveFailures - 1))

        Write-Host "  [ERROR] Failed after retries" -ForegroundColor Red
        Write-Host "  Consecutive failures: $consecutiveFailures" -ForegroundColor Yellow
        Write-Host "  Next cooldown: ${currentCooldown}s" -ForegroundColor Yellow
        Write-Host ""

        if ($i -lt $MaxIterations) {
            Write-Host "  Sleeping ${currentCooldown}s..." -ForegroundColor Gray
            Write-Host ""
            Start-Sleep -Seconds $currentCooldown
            continue
        }
    }

    $isComplete = $claudeResponse.Result -match "<STORY_COMPLETE>"

    if ($isComplete) {
        $consecutiveFailures = 0
        $currentCooldown = $BaseCooldownSeconds
        Write-Host "  [OK] Story complete!" -ForegroundColor Green
    } else {
        $consecutiveFailures++
        $currentCooldown = [math]::Min($MaxCooldown, $BaseCooldownSeconds * [math]::Pow($CooldownMultiplier, [math]::Max(0, $consecutiveFailures - 2)))
        Write-Host "  [WARNING] Story not complete - will retry" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  Sleeping ${currentCooldown}s before next iteration..." -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds $currentCooldown
}

Write-Host "===========================================" -ForegroundColor Yellow
Write-Host "  Reached max iterations ($MaxIterations)" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host ""
exit 1
