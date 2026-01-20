#!/usr/bin/env pwsh
# Maven Flow - Autonomous Development Orchestrator
# Professional UI/UX with clear progress feedback

param([int]$MaxIterations = 100, [int]$SleepSeconds = 2)

$ErrorActionPreference = 'Continue'

$projectName = (Split-Path -Leaf (Get-Location))
$startTime = Get-Date

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor $Color
    Write-Host "│" -NoNewline -ForegroundColor $Color
    Write-Host (" {0,-65} " -f $Title) -NoNewline -ForegroundColor White
    Write-Host "│" -ForegroundColor $Color
    Write-Host "├─────────────────────────────────────────────────────────────────┤" -ForegroundColor $Color
    Write-Host "│" -NoNewline -ForegroundColor $Color
    Write-Host (" Project: {0,-54} " -f $projectName) -NoNewline -ForegroundColor Cyan
    Write-Host "│" -ForegroundColor $Color
    Write-Host "│" -NoNewline -ForegroundColor $Color
    Write-Host (" Started: {0,-54} " -f $startTime.ToString("yyyy-MM-dd HH:mm:ss")) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor $Color
    Write-Host "│" -NoNewline -ForegroundColor $Color
    Write-Host (" Max Iterations: {0,-48} " -f $MaxIterations) -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor $Color
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor $Color
    Write-Host ""
}

function Write-IterationHeader {
    param([int]$Current, [int]$Total)
    $percent = [math]::Round(($Current / $Total) * 100)
    $filled = [math]::Floor(40 * $Current / $Total)
    $empty = 40 - $filled
    $bar = "█" * $filled + "░" * $empty

    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host "  │" -NoNewline -ForegroundColor Yellow
    Write-Host (" Iteration {0}/{1} " -f $Current, $Total) -NoNewline -ForegroundColor Yellow
    Write-Host ("[" -NoNewline -ForegroundColor Gray
    Write-Host $bar -NoNewline -ForegroundColor Green
    Write-Host "]" -NoNewline -ForegroundColor Gray
    Write-Host (" {0}% " -f $percent) -NoNewline -ForegroundColor Yellow
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "  └────────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Complete {
    param([int]$Iterations, [timespan]$Duration)
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│" -NoNewline -ForegroundColor Green
    Write-Host (" [OK] ALL TASKS COMPLETE{0,46} " -f "") -NoNewline -ForegroundColor Green
    Write-Host "│" -ForegroundColor Green
    Write-Host "├─────────────────────────────────────────────────────────────────┤" -ForegroundColor Green
    Write-Host "│" -NoNewline -ForegroundColor Green
    Write-Host (" Iterations: {0,-53} " -f $Iterations) -NoNewline -ForegroundColor White
    Write-Host "│" -ForegroundColor Green
    Write-Host "│" -NoNewline -ForegroundColor Green
    Write-Host (" Duration: {0,-54} " -f $Duration.ToString("hh\:mm\:ss")) -NoNewline -ForegroundColor White
    Write-Host "│" -ForegroundColor Green
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
}

function Write-MaxReached {
    param([int]$Max)
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│" -NoNewline -ForegroundColor Yellow
    Write-Host (" [!] MAX ITERATIONS REACHED{0,43} " -f "") -NoNewline -ForegroundColor Yellow
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "│" -NoNewline -ForegroundColor Yellow
    Write-Host (" Run 'flow-continue' to resume{0,48} " -f "") -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
}

Write-Header -Title "[START] Maven Flow - Starting"

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
        Write-Host "  Pausing ${SleepSeconds}s before next iteration..." -ForegroundColor DarkGray
        for ($s = $SleepSeconds; $s -gt 0; $s--) {
            Write-Host -NoNewline "`r    [$s] "
            Start-Sleep -Seconds 1
        }
        Write-Host ""
    }
}

Write-MaxReached -Max $MaxIterations
exit 0
