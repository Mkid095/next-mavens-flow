#!/usr/bin/env pwsh
# Maven Flow - Autonomous Development Orchestrator

param([int]$MaxIterations = 100, [int]$SleepSeconds = 2, [int]$TaskTimeoutMinutes = 30)

$ErrorActionPreference = 'Continue'

$projectName = (Split-Path -Leaf (Get-Location))
$startTime = Get-Date
$sessionId = "$projectName-" + (New-Guid).Guid.Substring(0, 8)
$sessionFile = ".flow-session"
$claudeSessionId = $null

# Save session ID to file
$sessionId | Out-File -FilePath $sessionFile -Encoding UTF8

# Get or create Claude session
try {
    $sessionList = claude session list 2>&1
    if ($LASTEXITCODE -eq 0) {
        # Parse the session list to find active sessions
        # We'll create a new session for this flow run
        $claudeSessionId = "flow-$sessionId"
    }
} catch {
    # Ignore errors, will proceed without explicit session tracking
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
    Write-Host "  Timeout: ${TaskTimeoutMinutes}min per task" -ForegroundColor Gray
    Write-Host "  Resumed: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
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

function Stop-ClaudeSession {
    param([string]$SessionId)

    if (-not $SessionId) {
        return
    }

    Write-Host "  [INFO] Stopping Claude session..." -ForegroundColor DarkGray

    # Try to stop sessions by filtering for our session
    try {
        $sessions = claude session list 2>&1
        if ($LASTEXITCODE -eq 0 -and $sessions) {
            # Parse and stop our session
            $sessions | ForEach-Object {
                if ($_ -match $SessionId) {
                    $sessionParts = $_ -split '\s+'
                    if ($sessionParts.Length -gt 0) {
                        $actualSessionId = $sessionParts[0]
                        claude session stop $actualSessionId 2>&1 | Out-Null
                    }
                }
            }
        }
    } catch {
        # Ignore errors stopping session
    }
}

Write-Header -Title "Maven Flow - Continuing"

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

        $taskStart = Get-Date
        $claudeStarted = $false
        $timeoutSeconds = $TaskTimeoutMinutes * 60
        $jobTimedOut = $false

        # Start Claude in background and show timer
        $job = Start-Job -ScriptBlock {
            param($prompt)
            & claude --dangerously-skip-permissions -p $prompt 2>&1 | Out-String
        } -ArgumentList $PROMPT

        # Show running timer with status
        while ($job.State -eq 'Running') {
            $totalSeconds = [math]::Floor(((Get-Date) - $taskStart).TotalSeconds)
            $minutes = [math]::Floor($totalSeconds / 60)
            $seconds = $totalSeconds % 60

            if ($minutes -gt 0) {
                $elapsedStr = "${minutes}m ${seconds}s"
            } else {
                $elapsedStr = "${seconds}s"
            }

            # Update status after first few seconds
            if ($totalSeconds -gt 3 -and -not $claudeStarted) {
                $claudeStarted = $true
            }

            if ($claudeStarted) {
                $status = "[Working]"
            } else {
                $status = "[Starting]"
            }

            Write-Host -NoNewline "`r  $status [$elapsedStr] "

            # Check for timeout
            if ($totalSeconds -ge $timeoutSeconds) {
                Write-Host ""
                Write-Host "  [ERROR] Task timeout after ${TaskTimeoutMinutes} minutes" -ForegroundColor Red
                Write-Host "  [INFO] Stopping job..." -ForegroundColor Yellow
                Stop-Job $job -Force
                $jobTimedOut = $true
                break
            }

            Start-Sleep -Seconds 1
        }
        Write-Host ""

        # Get the result
        $result = Receive-Job $job
        Remove-Job $job -Force

        if ($jobTimedOut) {
            Write-Host "  [ERROR] Task timed out. Check Claude status manually." -ForegroundColor Red
            Write-Host "  [INFO] You can resume with 'flow-continue'" -ForegroundColor Yellow
            Stop-ClaudeSession -SessionId $sessionId
            Remove-SessionFile
            exit 1
        }

        # Check if job had an error
        if ($job.State -eq 'Failed') {
            Write-Host "  [ERROR] Job failed. Error:" -ForegroundColor Red
            Write-Host $result
            Stop-ClaudeSession -SessionId $sessionId
            Remove-SessionFile
            exit 1
        }

        # Show result if not empty
        if ($result -and $result.Trim() -ne "") {
            Write-Host $result
        }

        if ($result -match "<promise>COMPLETE</promise>") {
            $duration = (Get-Date) - $startTime
            Write-Complete -Iterations $i -Duration $duration
            Stop-ClaudeSession -SessionId $sessionId
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
    Stop-ClaudeSession -SessionId $sessionId
    Remove-SessionFile
    exit 0
} finally {
    # Always cleanup
    Stop-ClaudeSession -SessionId $sessionId
    Remove-SessionFile
}
