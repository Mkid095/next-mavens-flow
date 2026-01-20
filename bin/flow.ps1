#!/usr/bin/env pwsh
# Maven Flow - Simplified Orchestrator (Ralph-style)
# Minimal complexity, maximum reliability

param([int]$MaxIterations = 100, [int]$SleepSeconds = 2)

# Don't stop on errors - let Claude handle them
$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Maven Flow - Starting" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Gray
Write-Host "  Sleep Between: ${SleepSeconds}s" -ForegroundColor Gray
Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

$PROMPT = @"
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
"@

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "  Iteration $i of $MaxIterations" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""

    $result = & claude --dangerously-skip-permissions -p $PROMPT 2>&1 | Out-String
    Write-Host $result

    if ($result -match "<promise>COMPLETE</promise>") {
        Write-Host ""
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "  All tasks complete after $i iterations!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        exit 0
    }

    Write-Host ""
    Write-Host "  Sleeping ${SleepSeconds}s..." -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds $SleepSeconds
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host "  Reached max iterations ($MaxIterations)" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host ""
exit 0
