# Maven Flow - Orchestrator wrapper (loop until complete)
param(
    [int]$MaxIterations = 100,
    [int]$SleepSeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "         Maven Flow - Autonomous AI Development System               " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Starting Maven Flow - Max $MaxIterations iterations" -ForegroundColor Yellow
Write-Host ""

# Check for jq
$null = jq --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] jq is required. Install from: https://jqlang.github.io/" -ForegroundColor Red
    exit 1
}

# MAIN LOOP
for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host "  Iteration $i of $MaxIterations" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Gray
    Write-Host ""

    # Scan for incomplete story using jq
    $prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue
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
        $incomplete = jq '[.userStories | select(.passes == false)] | length' $prd.FullName 2>$null
        if ([int]$incomplete -gt 0) {
            $currentPrd = $prd.FullName
            $storyIndex = jq '[.userStories | to_entries | select(.value.passes == false) | .key | tonumber] | .[0]' $prd.FullName 2>$null
            $currentStory = jq -r ".userStories[$storyIndex]" $prd.FullName 2>$null
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

    # Build story prompt
    $prompt = @"
# Maven Flow - Story Execution

## Current Story
**Story ID:** $storyId
**Feature:** $featureName
**PRD:** $currentPrd

## Story Data
$currentStory

## Previous Progress (Learnings)
$progressContent

## Consolidated Memory
$memoryContent

## Your Task

Execute this story through ALL its mavenSteps:

1. Read the mavenSteps array from the story
2. For each step, spawn the appropriate specialist agent:
   - Steps 1, 2, 7, 9 → development-agent
   - Steps 3, 4, 6 → refactor-agent
   - Step 5 → quality-agent
   - Steps 8, 10 → security-agent
3. Tell each agent which MCPs to use (from mcpTools in story)
4. Wait for agent completion before spawning next
5. Run quality checks after all steps complete
6. Commit changes: \`feat: $storyId - [title]\`
7. Output completion signal

## Critical Requirements

- DO NOT ask questions - EXECUTE directly
- Use MCP tools for database operations (supabase, etc.)
- Run typecheck: \`pnpm run typecheck\`
- Update progress after completion

## Completion Signal

After completing the story successfully, output EXACTLY:

<STORY_COMPLETE>
<story_id>$storyId</story_id>
<feature>$featureName</feature_id>
<maven_steps_completed>all</maven_steps_completed>
</STORY_COMPLETE>

If the story FAILS (tests don't pass, errors occur), do NOT output the signal.
Instead, append failure details to progress file for next iteration to learn from.
"@

    # Execute Claude
    $result = & claude --dangerously-skip-permissions -p $prompt 2>&1 | Out-String

    # Display result
    Write-Host $result
    Write-Host ""

    # Check for completion signal
    if ($result -match "<STORY_COMPLETE>") {
        Write-Host "  [OK] Story complete - Updating PRD..." -ForegroundColor Green

        # Update JSON: passes: true
        $null = jq "(.userStories[$storyIndex] | .passes = true) | {userStories: .} | del(.userStories) | . + {userStories}" $currentPrd 2>$null | Out-File -FilePath $currentPrd -Encoding UTF8

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
        $incomplete = jq '[.userStories | select(.passes == false)] | length' $prd.FullName 2>$null
        if ([int]$incomplete -gt 0) {
            $allComplete = $false
            break
        }
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
