#!/usr/bin/env pwsh
# ============================================================================
# Maven Flow - Terminal Wrapper for Claude Code CLI
# ============================================================================
#
# This script is a SIMPLE WRAPPER that delegates to Claude Code commands.
# The actual Maven workflow (agent spawning, memory loading, etc.) is
# implemented in .claude/commands/flow.md which runs within Claude Code.
#
# ============================================================================

param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$ArgsArray
)

$ErrorActionPreference = 'Continue'

# Get script directory FIRST (needed by status command)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source lock library
$LockLibraryPath = Join-Path $ScriptDir "LockLibrary.ps1"
if (Test-Path $LockLibraryPath) {
    . $LockLibraryPath
} else {
    Write-Host "[ERROR] Lock library not found at $LockLibraryPath" -ForegroundColor Red
    exit 1
}

# Source banner
$BannerPath = Join-Path $ScriptDir "Banner.ps1"
if (Test-Path $BannerPath) {
    . $BannerPath
    Show-FlowBanner
}

# Default parameters
$script:MaxIterations = 100
$script:SleepSeconds = 2
$script:DryRun = $false
$script:ContinueMode = $false

# Parse arguments
$i = 0
while ($i -lt $ArgsArray.Count) {
    $arg = $ArgsArray[$i]

    switch -Regex ($arg) {
        "^--dry-run$" {
            $script:DryRun = $true
            $i++
        }
        "^status$" {
            # Show status only
            & pwsh -File (Join-Path $ScriptDir "flow-status.ps1") $ArgsArray[($i+1..$ArgsArray.Count)]
            exit $LASTEXITCODE
        }
        "^continue$" {
            $script:ContinueMode = $true
            $i++
        }
        "^reset$" {
            # Reset session with safety checks
            Write-Host ""
            Write-Host "==========================================" -ForegroundColor Yellow
            Write-Host "  Maven Flow - Session Reset" -ForegroundColor Yellow
            Write-Host "==========================================" -ForegroundColor Yellow
            Write-Host ""

            # Check for uncommitted changes
            $gitStatus = git status --porcelain 2>$null
            if ($gitStatus) {
                Write-Host "[!] WARNING: Uncommitted changes detected" -ForegroundColor Red
                Write-Host ""
                git status --short
                Write-Host ""
            }

            # Check for incomplete stories
            if (Test-Path "docs") {
                $prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue
                foreach ($prd in $prdFiles) {
                    $total = jq '.userStories | length' $prd.FullName 2>$null
                    if ($total) {
                        $completed = jq '[.userStories[] | select(.passes == true)] | length' $prd.FullName 2>$null
                        $remaining = [int]$total - [int]$completed

                        if ($remaining -gt 0) {
                            Write-Host "[!] $($prd.Name) has $remaining incomplete story(s)" -ForegroundColor Yellow
                            jq -r '.userStories[] | select(.passes == false) | "  - \(.id): \(.title)"' $prd.FullName 2>$null | ForEach-Object { Write-Host $_ }
                        }
                    }
                }
                Write-Host ""
            }

            # Check if session file exists
            $sessionFile = ".flow-session"
            if (-not (Test-Path $sessionFile)) {
                Write-Host "[INFO] No active session found" -ForegroundColor Gray
                Write-Host ""
            } else {
                $sessionId = Get-Content $sessionFile -Raw
                $sessionId = $sessionId.Trim()
                Write-Host "[INFO] Active session: $sessionId" -ForegroundColor Cyan
                Write-Host ""
            }

            # Interactive confirmation
            Write-Host "This will:" -ForegroundColor Red
            Write-Host "  - Delete the .flow-session file"
            Write-Host "  - Clear all session progress"
            Write-Host "  - Allow starting fresh from the first incomplete story"
            Write-Host ""

            # Only require confirmation if there's uncommitted work or active session
            $needsConfirmation = $gitStatus -or (Test-Path $sessionFile)
            if ($needsConfirmation) {
                Write-Host "Continue with reset? [y/N]: " -NoNewline -ForegroundColor Yellow
                $response = Read-Host
                Write-Host ""

                if ($response -ne "y" -and $response -ne "Y") {
                    Write-Host "[CANCELLED] Reset aborted" -ForegroundColor Gray
                    exit 0
                }
            }

            # Perform reset - clear locks if session exists
            if (Test-Path $sessionFile) {
                $sessionId = Get-Content $sessionFile -Raw
                $sessionId = $sessionId.Trim()
                if ($sessionId) {
                    Clear-SessionLocks $sessionId
                    Write-Host "[OK] Cleared locks for session $($sessionId.Substring(0,8))..." -ForegroundColor Green
                }
            }
            Remove-Item $sessionFile -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Session reset" -ForegroundColor Green
            Write-Host ""
            exit 0
        }
        "^(help|--help|-h)$" {
            # Show help
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
            Write-Host "  flow start [iterations]     Start autonomous development (default: 100 iterations)" -ForegroundColor White
            Write-Host "  flow status                 Show project progress and story completion" -ForegroundColor White
            Write-Host "  flow continue               Resume from previous session" -ForegroundColor White
            Write-Host "  flow reset                  Reset session state and start fresh" -ForegroundColor White
            Write-Host "  flow help, flow --help      Show this help screen" -ForegroundColor White
            Write-Host ""

            Write-Host "PRD WORKFLOW" -ForegroundColor White
            Write-Host "  flow-prd [description]      Generate a new PRD from scratch or plan.md" -ForegroundColor White
            Write-Host "  flow-convert [feature]      Convert markdown PRD to JSON format" -ForegroundColor White
            Write-Host "                              Use --all to convert all PRDs" -ForegroundColor White
            Write-Host "                              Use --force to reconvert existing JSON files" -ForegroundColor White
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
        "^[0-9]+$" {
            # Parse as number (max iterations)
            $script:MaxIterations = [int]$arg
            $i++
        }
        default {
            $i++
        }
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-Spinner {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message = "Processing"
    )

    $spinner = @('|', '/', '-', '\')
    $idx = 0

    $job = Start-Job -ScriptBlock $ScriptBlock

    while ($job.State -eq 'Running') {
        Write-Host "`r$Message $($spinner[$idx % 4])" -NoNewline -ForegroundColor Cyan
        $idx++
        Start-Sleep -Milliseconds 100
    }

    Write-Host "`r$Message [OK] " -NoNewline -ForegroundColor Green

    $result = Receive-Job $job
    Remove-Job $job

    Write-Host ""

    return $result
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

function Format-Duration {
    param([timespan]$Duration)

    if ($Duration.TotalHours -ge 1) {
        return "{0:N1}h" -f $Duration.TotalHours
    } elseif ($Duration.TotalMinutes -ge 1) {
        return "{0:N1}m" -f $Duration.TotalMinutes
    } else {
        return "{0:N0}s" -f $Duration.TotalSeconds
    }
}

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Color
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ("=" * 80) -ForegroundColor $Color
    Write-Host "  Project: $projectName" -ForegroundColor Cyan
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "  Stories: $($stats.Completed)/$($stats.Total) ($($stats.Remaining) left) - $($stats.Progress)% complete" -ForegroundColor Green
    Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Gray
    Write-Host ("=" * 80) -ForegroundColor $Color
    Write-Host ""
}

function Write-IterationHeader {
    param([int]$Current, [int]$Total)
    $stats = Get-StoryStats
    $iterPercent = [math]::Round(($Current / $Total) * 100)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "  Iteration $Current of $Total ($iterPercent%)" -ForegroundColor Yellow
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Stories: $($stats.Completed)/$($stats.Total) ($($stats.Remaining) left) - Project: $($stats.Progress)%" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host ""
}

function Write-Complete {
    param([int]$Iterations, [timespan]$Duration)
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "  [OK] ALL TASKS COMPLETE" -ForegroundColor Green
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Stories: $($stats.Total)/$($stats.Total) - 100% complete" -ForegroundColor White
    Write-Host "  Iterations: $Iterations" -ForegroundColor White
    Write-Host "  Duration: $(Format-Duration $Duration)" -ForegroundColor White
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
}

function Write-MaxReached {
    param([int]$Max)
    $stats = Get-StoryStats
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host "  [!] MAX ITERATIONS REACHED" -ForegroundColor Yellow
    Write-Host "  Session: $sessionId" -ForegroundColor Magenta
    Write-Host "  Progress: $($stats.Progress)% ($($stats.Remaining) stories remaining)" -ForegroundColor Cyan
    Write-Host "  Run 'flow continue' to resume" -ForegroundColor Gray
    Write-Host ("=" * 80) -ForegroundColor Yellow
    Write-Host ""
}

function Remove-SessionFile {
    $sessionFile = ".flow-session"
    if (Test-Path $sessionFile) {
        Remove-Item $sessionFile -Force
    }
}

function Cleanup {
    # Clean up heartbeat
    $heartbeatPidFile = ".flow-heartbeat-pid"
    if (Test-Path $heartbeatPidFile) {
        $hp = Get-Content $heartbeatPidFile -ErrorAction SilentlyContinue
        if ($hp) {
            Stop-Process -Id $hp -ErrorAction SilentlyContinue
        }
        Remove-Item $heartbeatPidFile -Force -ErrorAction SilentlyContinue
    }

    # Clear session locks
    if ($sessionId) {
        Clear-SessionLocks $sessionId
    }

    Remove-SessionFile
}

function Show-DryRunPreview {
    Write-Host ""
    Write-Host "[DRY RUN] Preview of actions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Would run: /flow start" -ForegroundColor Gray
    Write-Host "  Max iterations: $MaxIterations" -ForegroundColor Gray
    Write-Host "  Session ID: $sessionId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[DRY RUN] Use 'flow start' without --dry-run to execute" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

$projectName = (Split-Path -Leaf (Get-Location))
$startTime = Get-Date

# Generate session ID
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

# Dry run mode
if ($script:DryRun) {
    Show-DryRunPreview
    exit 0
}

# Register cleanup on exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

# ============================================================================
# Start heartbeat loop (mandatory - background)
# ============================================================================
$heartbeatInterval = if ($env:FLOW_HEARTBEAT_INTERVAL) { [int]$env:FLOW_HEARTBEAT_INTERVAL } else { 60 }

$heartbeatScript = {
    param($sessionId, $interval)

    # Import lock library
    $lockLibPath = Join-Path $PSScriptRoot "LockLibrary.ps1"
    if (Test-Path $lockLibPath) {
        . $lockLibPath
        while ($true) {
            Start-Sleep -Seconds $interval
            Update-SessionHeartbeats $sessionId
        }
    }
}

$heartbeatJob = Start-Job -ScriptBlock $heartbeatScript -ArgumentList $sessionId, $heartbeatInterval
$heartbeatJob.Id | Out-File -FilePath ".flow-heartbeat-pid" -Encoding UTF8

# Register heartbeat cleanup
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $heartbeatPidFile = ".flow-heartbeat-pid"
    if (Test-Path $heartbeatPidFile) {
        $jobId = Get-Content $heartbeatPidFile -ErrorAction SilentlyContinue
        if ($jobId) {
            Stop-Job -Id $jobId -ErrorAction SilentlyContinue
            Remove-Job -Id $jobId -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $heartbeatPidFile -Force -ErrorAction SilentlyContinue
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
            Cleanup
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
    Cleanup
    exit 0
} finally {
    Cleanup
}
