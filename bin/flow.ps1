#!/usr/bin/env pwsh
# Maven Flow - Autonomous Development Orchestrator

param(
    [int]$MaxIterations = 100,
    [int]$SleepSeconds = 2,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Continue'

# Handle help arguments
if ($RemainingArgs -contains "help" -or $RemainingArgs -contains "--help" -or $RemainingArgs -contains "-h") {
    Write-Host ""

    $banner = @"

 __    __     ______     __   __   ______     __   __     ______        ______   __         ______     __     __
/\ "-./  \   /\  __ \   /\ \ / /  /\  ___\   /\ "-.\ \   /\  ___\      /\  ___\ /\ \       /\  __ \   /\ \  _ \ \
\ \ \-./\ \  \ \  __ \  \ \ \/   \ \  __\   \ \ \-.  \  \ \___  \     \ \  __\ \ \ \____  \ \ \/\ \  \ \ \/ ".\ \
 \ \_\ \ \_\  \ \_\ \_\  \ \__|    \ \_____\  \ \_\\"\_\  \/\_____\     \ \_\    \ \_____\  \_____\  \ \__/".~\_\
  \/_/  \/_/   \/_/\/_/   \/_/      \/_____/   \/_/ \/_/   \/_____/      \/_/     \/_____/   \/_____/   \/_/   \_/
"@

    Write-Host $banner -ForegroundColor Cyan

    Write-Host "Maven Flow - Autonomous AI Development System" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""

    Write-Host "MAIN COMMANDS" -ForegroundColor White
    Write-Host "  flow start [iterations]     Start autonomous development (default: 100)" -ForegroundColor White
    Write-Host "  flow status                 Show project progress and story completion" -ForegroundColor White
    Write-Host "  flow continue               Resume from previous session" -ForegroundColor White
    Write-Host "  flow reset                  Reset session state and start fresh" -ForegroundColor White
    Write-Host "  flow help, flow --help      Show this help screen" -ForegroundColor White
    Write-Host ""

    Write-Host "PRD WORKFLOW" -ForegroundColor White
    Write-Host "  flow-prd [description]      Generate a new PRD from scratch or plan.md" -ForegroundColor White
    Write-Host "  flow-convert [feature]      Convert markdown PRD to JSON format" -ForegroundColor White
    Write-Host "                              Use --all to convert all PRDs" -ForegroundColor White
    Write-Host "                              Use --force to reconvert existing JSON" -ForegroundColor White
    Write-Host ""

    Write-Host "MAINTENANCE" -ForegroundColor White
    Write-Host "  flow-update [description]   Update Maven Flow system from GitHub" -ForegroundColor White
    Write-Host ""

    Write-Host "OPTIONS" -ForegroundColor White
    Write-Host "  --dry-run                   Show what would happen without making changes" -ForegroundColor White
    Write-Host "  -h, --help, help            Show help screen" -ForegroundColor White
    Write-Host ""

    Write-Host "WORKFLOW" -ForegroundColor White
    Write-Host "  1. Create PRD:    flow-prd `"your feature description`"" -ForegroundColor White
    Write-Host "  2. Convert:       flow-convert feature-name" -ForegroundColor White
    Write-Host "  3. Develop:       flow start" -ForegroundColor White
    Write-Host ""

    Write-Host "GETTING STARTED" -ForegroundColor White
    Write-Host "  GitHub: https://github.com/Mkid095/next-mavens-flow" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

$projectName = (Split-Path -Leaf (Get-Location))
$startTime = Get-Date
$sessionId = "$projectName-" + (New-Guid).Guid.Substring(0, 8)
$sessionFile = ".flow-session"

# Save session ID to file
$sessionId | Out-File -FilePath $sessionFile -Encoding UTF8

# Check if claude is available
$claudeExe = Get-Command "claude" -ErrorAction SilentlyContinue
if (-not $claudeExe) {
    Write-Host "  [ERROR] Claude CLI not found in PATH" -ForegroundColor Red
    Write-Host "  [INFO] Install with: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    exit 1
}

function Get-StoryStats {
    $prdFiles = @(Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue)
    $totalStories = 0
    $completedStories = 0

    foreach ($prd in $prdFiles) {
        $count = jq '.userStories | length' $prd.FullName 2>$null
        if ($count) {
            $totalStories += [int]$count
        }
        $complete = jq '[.userStories[] | select(.passes == true)] | length' $prd.FullName 2>$null
        if ($complete) {
            $completedStories += [int]$complete
        }
    }

    $progress = if ($totalStories -gt 0) { [math]::Round(($completedStories / $totalStories) * 100) } else { 0 }
    return @{ Total = $totalStories; Completed = $completedStories; Remaining = $totalStories - $completedStories; Progress = $progress }
}

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host "  Project: $projectName" -ForegroundColor Cyan
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "  Stories: $($stats.Completed)/$($stats.Total) ($($stats.Remaining) left) - $($stats.Progress)% complete" -ForegroundColor Green
    Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Gray
    Write-Host "===========================================" -ForegroundColor $Color
    Write-Host ""
}

function Write-IterationHeader {
    param([int]$Current, [int]$Total)
    $stats = Get-StoryStats
    $iterPercent = [math]::Round(($Current / $Total) * 100)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "  Iteration $Current of $Total ($iterPercent%)" -ForegroundColor Yellow
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Stories: $($stats.Completed)/$($stats.Total) ($($stats.Remaining) left) - Project: $($stats.Progress)%" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Complete {
    param([int]$Iterations, [timespan]$Duration)
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "  [OK] ALL TASKS COMPLETE" -ForegroundColor Green
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Stories: $($stats.Total)/$($stats.Total) - 100% complete" -ForegroundColor White
    Write-Host "  Iterations: $Iterations" -ForegroundColor White
    Write-Host "  Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
}

function Write-MaxReached {
    param([int]$Max)
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "  [!] MAX ITERATIONS REACHED" -ForegroundColor Yellow
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Progress: $($stats.Progress)% ($($stats.Remaining) stories remaining)" -ForegroundColor Cyan
    Write-Host "  Run 'flow-continue' to resume" -ForegroundColor Gray
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
}

function Remove-SessionFile {
    if (Test-Path $sessionFile) {
        Remove-Item $sessionFile -Force
    }
}

Write-Header -Title "Maven Flow - Starting"

$PROMPT = @'
You are Maven Flow, an autonomous development agent.

## Your Task

1. Find the first incomplete story in the PRD files (docs/prd-*.json)
2. Implement that story completely
3. Update the PRD to mark it complete (set "passes": true)
4. Run tests: pnpm run typecheck
5. Commit: git add . && git commit -m "feat: [story-id] [description]" -m "Co-Authored-By: Next Mavens Flow <flow@nextmavens.com>"

## Completion Signal

When ALL stories are complete, output EXACTLY:
<promise>COMPLETE</promise>

## If Not Complete

Do NOT output the signal. Just end your response.

## Important: Output Formatting

- Use ASCII characters only - no Unicode symbols like checkmarks, arrows, etc.
- Use [OK] or [X] instead of checkmarks
- Use * or - for bullets instead of Unicode symbols
- Keep formatting simple and compatible with all terminals
'@

try {
    for ($i = 1; $i -le $MaxIterations; $i++) {
        Write-IterationHeader -Current $i -Total $MaxIterations

        Write-Host "  Starting Claude..." -ForegroundColor Gray
        Write-Host ""

        # Stream output in real-time AND capture it for pattern matching
        $claudeOutput = @()
        & claude --dangerously-skip-permissions $PROMPT 2>&1 | ForEach-Object {
            Write-Host $_
            $claudeOutput += $_
        }
        $result = $claudeOutput -join "`n"

        # Check for completion - use story stats instead of hardcoded patterns
        $stats = Get-StoryStats
        if ($stats.Completed -eq $stats.Total -and $stats.Total -gt 0) {
            $duration = (Get-Date) - $startTime
            Write-Complete -Iterations $i -Duration $duration
            Remove-SessionFile
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
    Remove-SessionFile
    exit 0
} finally {
    Remove-SessionFile
}
