#!/usr/bin/env pwsh
# ============================================================================
# Maven Flow - Work on Single Story
# ============================================================================
# Loads memory for a specific story and spawns specialized agents
# ============================================================================

param(
    [Parameter(Position=0)]
    [string]$StoryId
)

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source banner
$BannerPath = Join-Path $ScriptDir "Banner.ps1"
if (Test-Path $BannerPath) {
    . $BannerPath
    Show-FlowBanner
}

# Import lock library
$LockLibraryPath = Join-Path $ScriptDir "LockLibrary.ps1"
if (Test-Path $LockLibraryPath) {
    . $LockLibraryPath
}

$BoxTop =    "+============================================================+"
$BoxTitle =  "|         Maven Flow - Single Story Workflow               |"
$BoxBottom = "+============================================================+"

Write-Host ""
Write-Host $BoxTop -ForegroundColor Cyan
Write-Host $BoxTitle -ForegroundColor Cyan
Write-Host $BoxBottom -ForegroundColor Cyan
Write-Host ""

# Check arguments
if ([string]::IsNullOrWhiteSpace($StoryId)) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  flow-work-story <story-id>     Work on a specific story" -ForegroundColor White
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Gray
    Write-Host "  flow-work-story us-001         Work on story US-001" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Validate story ID format
if ($StoryId -notmatch "^[A-Za-z]{2,}-[0-9]+$") {
    Write-Host "[ERROR] Invalid story ID format: $StoryId" -ForegroundColor Red
    Write-Host "Expected format: US-001, FE-042, etc." -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Find PRD containing this story
$PrdFile = $null
$prdFiles = Get-ChildItem -Path "docs" -Filter "prd-*.json" -ErrorAction SilentlyContinue

foreach ($prd in $prdFiles) {
    $storyExists = jq -e ".userStories[] | select(.id == \"$StoryId\")" $prd.FullName 2>$null
    if ($LASTEXITCODE -eq 0) {
        $PrdFile = $prd.FullName
        break
    }
}

if (-not $PrdFile) {
    Write-Host "[ERROR] Story $StoryId not found in any PRD" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "  Story: " -NoNewline -ForegroundColor Blue
Write-Host $StoryId -ForegroundColor Yellow
Write-Host "  PRD: $PrdFile" -ForegroundColor Gray
Write-Host ""

# Extract story info
$StoryTitle = jq -r ".userStories[] | select(.id == \"$StoryId\") | .title" $PrdFile 2>$null
$StoryStatus = jq -r ".userStories[] | select(.id == \"$StoryId\") | .passes" $PrdFile 2>$null

if ($StoryStatus -eq "true") {
    Write-Host "[!] Story $StoryId is already marked as complete" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Continue anyway? [y/N]: " -NoNewline -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "[CANCELLED]" -ForegroundColor Gray
        exit 0
    }
}

# Acquire lock for this story
$SessionId = "$env:COMPUTERNAME-$PID"
Write-Host "Acquiring lock for story..." -ForegroundColor Gray

$lockResult = Acquire-StoryLock -PrdFile $PrdFile -StoryId $StoryId -SessionId $SessionId

if (-not $lockResult) {
    Write-Host "[ERROR] Failed to acquire lock for story $StoryId" -ForegroundColor Red
    Write-Host "The story may be locked by another session" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "[OK] Lock acquired" -ForegroundColor Green
Write-Host ""

# Set up cleanup on exit
$cleanupScript = {
    Write-Host ""
    Write-Host "Releasing lock..." -ForegroundColor Gray
    Release-StoryLock -PrdFile $PrdFile -StoryId $StoryId -SessionId $SessionId
}

# Register cleanup (PowerShell doesn't have a simple trap, use try/finally)
try {
    Write-Host "Starting work on: " -NoNewline -ForegroundColor Cyan
    Write-Host "$StoryId - $StoryTitle" -ForegroundColor Yellow
    Write-Host ""

    # Run flow-work-story command
    $Prompt = "/flow-work-story $StoryId"
    $result = & claude --dangerously-skip-permissions $Prompt 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "+============================================================+" -ForegroundColor Green
        Write-Host "|           [OK] STORY WORK COMPLETE                       |" -ForegroundColor Green
        Write-Host "+============================================================+" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Story: $StoryId" -ForegroundColor Gray
        Write-Host ""

        # Ask if story should be marked complete
        Write-Host "Mark story as complete? [y/N]: " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -eq "y" -or $response -eq "Y") {
            # Update PRD to mark story as complete
            $tmpFile = [System.IO.Path]::GetTempFileName()
            jq "(.userStories[] | select(.id == \"$StoryId\")).passes = true" $PrdFile > $tmpFile 2>$null
            Move-Item $tmpFile $PrdFile -Force
            Write-Host "[OK] Story marked as complete" -ForegroundColor Green
        }
    } else {
        Write-Host ""
        Write-Host "+============================================================+" -ForegroundColor Red
        Write-Host "|              [ERROR] STORY WORK FAILED                    |" -ForegroundColor Red
        Write-Host "+============================================================+" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    Write-Host ""
} finally {
    # Cleanup locks
    & $cleanupScript
}
