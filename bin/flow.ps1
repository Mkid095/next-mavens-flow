﻿# Maven Flow - Orchestrator wrapper (loop until complete)
param(
    [string[]]$ArgsArray,
    [int]$MaxIterations = 100,
    [int]$SleepSeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Parse command
$Command = "status"
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

# Show header only for start command
if ($Command -eq "start") {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Starting Maven Flow - Max $MaxIterations iterations" -ForegroundColor Yellow
    Write-Host ""
}

# STATUS COMMAND
if ($Command -eq "status") {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "                    Maven Flow - Project Status                     " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
    if ($prdFiles.Count -eq 0) {
        Write-Host "  [ERROR] No PRD JSON files found in docs/" -ForegroundColor Red
        Write-Host "  Run: flow-prd" -ForegroundColor Yellow
        exit 1
    }

    $totalStories = 0
    $totalCompleted = 0

    foreach ($prd in $prdFiles | Sort-Object Name) {
        $featureName = $prd.Name -replace "prd-", "" -replace ".json", ""
        $storyCount = jq '.userStories | length' $prd.FullName 2>$null
        $totalStories += [int]$storyCount

        $completedCount = 0
        $currentStoryIndex = $null
        $currentStoryData = $null

        for ($j = 0; $j -lt [int]$storyCount; $j++) {
            $passesOutput = jq ".userStories[$j].passes" $prd.FullName 2>$null
            $isComplete = -not (($passesOutput -match "false") -and ($passesOutput -notmatch "true"))
            if ($isComplete) {
                $completedCount++
                $totalCompleted++
            } else {
                if ($null -eq $currentStoryIndex) {
                    $currentStoryIndex = $j
                    $currentStoryData = jq -r ".userStories[$j]" $prd.FullName 2>$null
                }
            }
        }

        # Feature header
        $progressPct = if ([int]$storyCount -gt 0) { [math]::Round(($completedCount / [int]$storyCount) * 100) } else { 0 }

        if ($completedCount -eq [int]$storyCount) {
            Write-Host "┌────────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
            Write-Host "│ " -NoNewline -ForegroundColor Green
            Write-Host "✓ $featureName" -NoNewline -ForegroundColor Green
            Write-Host " " -NoNewline
            $statusText = "COMPLETE ($completedCount/$storyCount) "
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
            Write-Host (" " * (12 - "$completedCount/$storyCount".Length)) -NoNewline
            Write-Host "│" -ForegroundColor Cyan
            Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

            # Show current story details if incomplete
            if ($currentStoryData) {
                $storyId = $currentStoryData | jq -r '.id' 2>$null
                $storyTitle = $currentStoryData | jq -r '.title' 2>$null
                $storyDesc = $currentStoryData | jq -r '.description' 2>$null

                Write-Host ""
                Write-Host "  CURRENT STORY:" -ForegroundColor Yellow
                Write-Host "  ┌──────────────────────────────────────────────────────────────────┐" -ForegroundColor Gray
                Write-Host "  │ ID:     " -NoNewline -ForegroundColor Gray
                Write-Host $storyId.PadRight(62) -NoNewline -ForegroundColor Cyan
                Write-Host "│" -ForegroundColor Gray
                Write-Host "  │ Title:  " -NoNewline -ForegroundColor Gray
                Write-Host ($storyTitle.Substring(0, [math]::Min(58, $storyTitle.Length))).PadRight(62) -NoNewline -ForegroundColor White
                Write-Host "│" -ForegroundColor Gray

                if ($storyDesc -and $storyDesc -ne "null" -and $storyDesc.Length -gt 0) {
                    $descTruncated = if ($storyDesc.Length -gt 58) { $storyDesc.Substring(0, 55) + "..." } else { $storyDesc }
                    Write-Host "  │ " -NoNewline -ForegroundColor Gray
                    Write-Host $descTruncated.PadRight(62) -NoNewline -ForegroundColor Gray
                    Write-Host "│" -ForegroundColor Gray
                }

                # Show Maven Steps
                $mavenSteps = $currentStoryData | jq -r '.mavenSteps // "[]"' 2>$null
                $stepArray = $mavenSteps | jq -r '.[]' 2>$null
                if ($stepArray) {
                    Write-Host "  │ Steps:  " -NoNewline -ForegroundColor Gray
                    $stepsString = $stepArray -join ", "
                    $stepsTruncated = if ($stepsString.Length -gt 55) { $stepsString.Substring(0, 52) + "..." } else { $stepsString }
                    Write-Host $stepsTruncated.PadRight(62) -NoNewline -ForegroundColor Cyan
                    Write-Host "│" -ForegroundColor Gray
                }

                # Show Acceptance Criteria
                $acceptanceCriteria = $currentStoryData | jq -r '.acceptanceCriteria // "[]"' 2>$null
                $criteriaCount = $acceptanceCriteria | jq '.length' 2>$null
                if ($criteriaCount -gt 0) {
                    Write-Host "  │ Criteria:" -ForegroundColor Gray
                    for ($k = 0; $k -lt [math]::Min(3, [int]$criteriaCount); $k++) {
                        $criterion = $acceptanceCriteria | jq -r ".[$k]" 2>$null
                        $criterionTruncated = if ($criterion.Length -gt 56) { $criterion.Substring(0, 53) + "..." } else { $criterion }
                        Write-Host "  │   • " -NoNewline -ForegroundColor Gray
                        Write-Host $criterionTruncated.PadRight(60) -NoNewline -ForegroundColor White
                        Write-Host "│" -ForegroundColor Gray
                    }
                    if ([int]$criteriaCount -gt 3) {
                        Write-Host "  │   " -NoNewline -ForegroundColor Gray
                        Write-Host "...and ($([int]$criteriaCount - 3)) more criteria".PadRight(60) -NoNewline -ForegroundColor Gray
                        Write-Host "│" -ForegroundColor Gray
                    }
                }

                Write-Host "  └──────────────────────────────────────────────────────────────────┘" -ForegroundColor Gray
            }
        }

        Write-Host ""
    }

    # Overall progress summary
    $overallPct = if ($totalStories -gt 0) { [math]::Round(($totalCompleted / $totalStories) * 100) } else { 0 }
    $overallBar = "█" * [math]::Floor(30 * $totalCompleted / [math]::Max(1, $totalStories))
    $overallBar += "░" * (30 - [math]::Floor(30 * $totalCompleted / [math]::Max(1, $totalStories)))

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
    Write-Host (" " * (12 - "$totalCompleted/$totalStories".Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "└────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "  Run 'flow continue' to resume, or 'flow help' for more commands" -ForegroundColor Gray
    Write-Host ""

    exit 0
}

# HELP COMMAND
if ($Command -eq "help") {
    Write-Host ""
    Write-Host "Maven Flow Commands:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  flow start [iterations]  Start autonomous flow (default: 100 iterations)" -ForegroundColor White
    Write-Host "  flow status              Show all PRDs and completion status" -ForegroundColor White
    Write-Host "  flow continue [prd]     Continue from last incomplete story" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  flow start              Start flow" -ForegroundColor White
    Write-Host "  flow start 50           Start with max 50 iterations" -ForegroundColor White
    Write-Host "  flow continue           Continue current PRD" -ForegroundColor White
    Write-Host "  flow continue database    Continue specific PRD" -ForegroundColor White
    Write-Host "  flow status             Show all PRD status" -ForegroundColor White
    Write-Host ""
    exit 0
}

# CONTINUE COMMAND
if ($Command -eq "continue") {
    Write-Host ""
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "         Maven Flow - Continue" -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
    if ($prdFiles.Count -eq 0) {
        Write-Host "  [ERROR] No PRD JSON files found in docs/" -ForegroundColor Red
        exit 1
    }

    # Check if specific PRD requested
    $targetPrd = $null
    foreach ($arg in $ArgsArray) {
        if ($arg -ne "continue" -and $arg -notmatch "^\d+$") {
            $targetPrd = $arg
            break
        }
    }

    $selectedPrd = $null
    if ($targetPrd) {
        $selectedPrd = $prdFiles | Where-Object { $_.Name -like "prd-$targetPrd.json" } | Select-Object -First 1
        if (-not $selectedPrd) {
            Write-Host "  [ERROR] PRD '$targetPrd' not found" -ForegroundColor Red
            Write-Host "  Available PRDs:" -ForegroundColor Yellow
            foreach ($prd in $prdFiles) {
                Write-Host "    - $($prd.Name -replace 'prd-', '' -replace '.json', '')" -ForegroundColor Gray
            }
            exit 1
        }
    } else {
        # Auto-select first incomplete PRD
        foreach ($prd in $prdFiles | Sort-Object Name) {
            $storyCount = jq '.userStories | length' $prd.FullName 2>$null
            for ($j = 0; $j -lt [int]$storyCount; $j++) {
                $passesOutput = jq ".userStories[$j].passes" $prd.FullName 2>$null
                $isIncomplete = ($passesOutput -match "false") -and ($passesOutput -notmatch "true")
                if ($isIncomplete) {
                    $selectedPrd = $prd
                    break
                }
            }
            if ($selectedPrd) { break }
        }

        if (-not $selectedPrd) {
            Write-Host "  [INFO] All PRDs are complete!" -ForegroundColor Green
            Write-Host "  Run 'flow start' to verify and run consolidation" -ForegroundColor Yellow
            exit 0
        }
    }

    $featureName = $selectedPrd.Name -replace "prd-", "" -replace ".json", ""
    Write-Host "  Continuing: $featureName" -ForegroundColor Yellow
    Write-Host ""

    # Find first incomplete story
    $storyCount = jq '.userStories | length' $selectedPrd.FullName 2>$null
    $storyIndex = $null
    for ($j = 0; $j -lt [int]$storyCount; $j++) {
        $passesOutput = jq ".userStories[$j].passes" $selectedPrd.FullName 2>$null
        $isIncomplete = ($passesOutput -match "false") -and ($passesOutput -notmatch "true")
        if ($isIncomplete) {
            $storyIndex = $j
            break
        }
    }

    if ($null -eq $storyIndex) {
        Write-Host "  [INFO] PRD '$featureName' is already complete!" -ForegroundColor Green
        exit 0
    }

    $storyId = jq -r ".userStories[$storyIndex].id" $selectedPrd.FullName 2>$null
    $storyTitle = jq -r ".userStories[$storyIndex].title" $selectedPrd.FullName 2>$null
    $mavenSteps = jq -r ".userStories[$storyIndex].mavenSteps" $selectedPrd.FullName 2>$null

    Write-Host "  Next story: $storyId - $storyTitle" -ForegroundColor Cyan
    Write-Host "  Maven Steps: $mavenSteps" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Starting flow for this story..." -ForegroundColor Yellow
    Write-Host ""

    # Continue to main loop (the loop will pick up this PRD)
}

# MAIN LOOP
for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host "  Iteration $i of $MaxIterations" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""

    # Scan for incomplete story using jq
    $prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
    if ($prdFiles.Count -eq 0) {
        Write-Host "  [ERROR] No PRD JSON files found in docs/" -ForegroundColor Red
        Write-Host "  Run: flow-prd plan" -ForegroundColor Yellow
        exit 1
    }

    $currentPrd = $null
    $currentStory = $null
    $storyId = $null
    $storyIndex = $null
    $featureName = $null

    foreach ($prd in $prdFiles | Sort-Object Name) {
        # Get first incomplete story index
        $storyIndex = $null
        $storyCount = jq '.userStories | length' $prd.FullName 2>$null
        for ($j = 0; $j -lt [int]$storyCount; $j++) {
            $passes = jq ".userStories[$j].passes" $prd.FullName 2>$null
            if ($passes -eq "false") {
                $storyIndex = $j
                break
            }
        }

        if ($null -ne $storyIndex) {
            $currentPrd = $prd.FullName
            $currentStory = jq ".userStories[$storyIndex]" $prd.FullName 2>$null
            $storyId = jq -r ".userStories[$storyIndex].id" $prd.FullName 2>$null
            $featureName = $prd.Name -replace "prd-", "" -replace ".json", ""
            break
        }
    }

    # Check if all complete
    if ($null -eq $currentPrd) {
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "  All PRD stories complete after $i iterations!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Run 'flow consolidate' to consolidate memories" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }

    Write-Host "  Feature: " -NoNewline -ForegroundColor Cyan
    Write-Host $featureName -ForegroundColor Yellow
    Write-Host "  Story: " -NoNewline -ForegroundColor Cyan
    Write-Host "$storyId" -ForegroundColor Yellow
    Write-Host ""

    # Load progress file for context
    $progressFile = "docs/progress-$featureName.txt"
    $progressContent = ""
    if (Test-Path $progressFile) {
        $progressContent = Get-Content $progressFile -Raw -Encoding UTF8
    }

    # Load consolidated memory if exists
    $memoryContent = ""
    $memoryFile = "docs/consolidated-$featureName.txt"
    if (Test-Path $memoryFile) {
        $memoryContent = Get-Content $memoryFile -Raw -Encoding UTF8
    }

    # Check MCP server availability (agent must reason from actual environment)
    $mcpList = & claude mcp list 2>&1 | Out-String

    # Build story prompt - using bullet points instead of numbered lists
    $prompt = @"
# Maven Flow - Story Execution

## Current Story
**Story ID:** $storyId
**Feature:** $featureName
**PRD:** $currentPrd

## Story Data
```json
$currentStory
```

## Previous Progress (Learnings)
$progressContent

## Consolidated Memory
$memoryContent

## Available MCP Servers
$mcpList

## Your Task

Execute this story through ALL its mavenSteps:

* Read the mavenSteps array from the story
* For each step, spawn the appropriate specialist agent:
  * Steps 1, 2, 7, 9 → development-agent
  * Steps 3, 4, 6 → refactor-agent
  * Step 5 → quality-agent
  * Steps 8, 10 → security-agent
* Tell each agent which MCPs to use (from mcpTools in story)
* Wait for agent completion before spawning next
* Run quality checks after all steps complete
* Commit changes: feat: $storyId - [title]
* Output completion signal

## Critical Requirements

* DO NOT ask questions - EXECUTE directly
* Use MCP tools for database operations (supabase, etc.)
* Run typecheck: pnpm run typecheck
* Update progress after completion

## Completion Signal

After completing the story successfully, output EXACTLY:

<STORY_COMPLETE>
<story_id>$storyId</story_id>
<feature>$featureName</feature>
<maven_steps_completed>all</maven_steps_completed>
</STORY_COMPLETE>

If the story FAILS (tests do not pass, errors occur), do NOT output the signal.
Instead, append failure details to progress file for next iteration to learn from.
"@

    # Execute Claude
    $result = & claude --dangerously-skip-permissions -p $prompt 2>&1 | Out-String

    # Display result
    Write-Host $result
    Write-Host ""

    # Check for completion - ONLY accept XML signal (deterministic, machine-safe)
    $isComplete = $result -match "<STORY_COMPLETE>"

    if ($isComplete) {
        Write-Host "  [OK] Story complete - Updating PRD..." -ForegroundColor Green

        # Update JSON: passes: true using simpler jq
        $prdContent = Get-Content $currentPrd -Raw -Encoding UTF8
        $updatedJson = $prdContent | jq ".userStories[$storyIndex].passes = true"
        $updatedJson | Out-File -FilePath $currentPrd -Encoding UTF8

        # Update progress file
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $progressFile -Value "`n## Iteration $i - $storyId`n- Completed successfully`n- Timestamp: $timestamp" -Encoding UTF8

        Write-Host "  PRD updated: passes = true" -ForegroundColor Green
        Write-Host "  Progress logged to: $progressFile" -ForegroundColor Gray
    } else {
        Write-Host "  [WARNING] Story not complete - logged for next iteration" -ForegroundColor Yellow

        # Log failure to progress
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $progressFile -Value "`n## Iteration $i - $storyId (FAILED)`n- Timestamp: $timestamp`n- Review result above for issues" -Encoding UTF8

        Write-Host "  Failure logged to: $progressFile" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Fix the issues and the next iteration will retry" -ForegroundColor Yellow
    }

    Write-Host ""

    # Check if should continue
    $allComplete = $true
    foreach ($prd in $prdFiles) {
        $storyCount = jq '.userStories | length' $prd.FullName 2>$null
        for ($j = 0; $j -lt [int]$storyCount; $j++) {
            $passes = jq ".userStories[$j].passes" $prd.FullName 2>$null
            if ($passes -eq "false") {
                $allComplete = $false
                break
            }
        }
        if (-not $allComplete) { break }
    }

    if ($allComplete) {
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "  All PRD stories complete!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Run 'flow consolidate' to consolidate memories" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }

    # Sleep before next iteration
    Write-Host "  Sleeping ${SleepSeconds}s before next iteration..." -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds $SleepSeconds
}

Write-Host "===========================================" -ForegroundColor Yellow
Write-Host "  Reached max iterations ($MaxIterations)" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Run 'flow status' to see remaining stories" -ForegroundColor Gray
Write-Host ""
exit 1
