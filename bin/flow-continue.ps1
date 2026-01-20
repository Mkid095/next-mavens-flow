#!/usr/bin/env pwsh
# Maven Flow - Autonomous Development Orchestrator

param([int]$MaxIterations = 100, [int]$SleepSeconds = 2)

$ErrorActionPreference = 'Continue'

$projectName = (Split-Path -Leaf (Get-Location))
$startTime = Get-Date

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host "  Project: $projectName" -ForegroundColor Cyan
    Write-Host "  Resumed: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Gray
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host ""
}

function Write-IterationHeader {
    param([int]$Current, [int]$Total)
    $percent = [math]::Round(($Current / $Total) * 100)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "  Iteration $Current of $Total ($percent%)" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Complete {
    param([int]$Iterations, [timespan]$Duration)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "  [OK] ALL TASKS COMPLETE" -ForegroundColor Green
    Write-Host "  Iterations: $Iterations" -ForegroundColor White
    Write-Host "  Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
}

function Write-MaxReached {
    param([int]$Max)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "  [!] MAX ITERATIONS REACHED" -ForegroundColor Yellow
    Write-Host "  Run 'flow-continue' to resume" -ForegroundColor Gray
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
}

Write-Header -Title "Maven Flow - Continuing"

$PROMPT = @'
You are Maven Flow, an autonomous development agent.

## Your Task

1. Find the first incomplete story in the PRD files (docs/prd-*.json)
2. Implement that story completely
3. Update the PRD to mark it complete (set "passes": true)
4. Run tests: pnpm run typecheck
5. Commit: git add . && git commit -m "feat: [story-id] [description]"

## Completion Signal

When ALL stories are complete, output EXACTLY:
<promise>COMPLETE</promise>

## If Not Complete

Do NOT output the signal. Just end your response.
'@

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-IterationHeader -Current $i -Total $MaxIterations

    Write-Host "  Executing Claude..." -ForegroundColor Gray
    Write-Host ""

    $result = & claude --dangerously-skip-permissions -p $PROMPT 2>&1 | Out-String
    Write-Host $result

    if ($result -match "<promise>COMPLETE</promise>") {
        $duration = (Get-Date) - $startTime
        Write-Complete -Iterations $i -Duration $duration
        exit 0
    }

    if ($i -lt $MaxIterations) {
        Write-Host ""
        Write-Host "  Pausing ${SleepSeconds}s..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $SleepSeconds
        Write-Host ""
    }
}

Write-MaxReached -Max $MaxIterations
exit 0
