# ============================================================================
# Maven Flow Lock Library for PowerShell
# ============================================================================
# Provides flock-based locking with heartbeat-based stale lock detection.
# Supports both PRD-level and story-level locking.
#
# Usage:
#   . .\bin\LockLibrary.ps1
#   Acquire-PrdLock "docs/prd-feature.json" "session-id"
#   # ... do work ...
#   Release-PrdLock "docs/prd-feature.json" "session-id"
# ============================================================================

# Lock directory
$Script:FlowLockDir = if ($env:FLOW_LOCK_DIR) { $env:FLOW_LOCK_DIR } else { ".flow-locks" }

# Heartbeat timeout in seconds (default: 5 minutes)
$Script:FlowHeartbeatTimeout = if ($env:FLOW_HEARTBEAT_TIMEOUT) { [int]$env:FLOW_HEARTBEAT_TIMEOUT } else { 300 }

# Maximum retries for lock acquisition (default: 3)
$Script:FlowLockMaxRetries = if ($env:FLOW_LOCK_MAX_RETRIES) { [int]$env:FLOW_LOCK_MAX_RETRIES } else { 3 }

# Retry delay in seconds (default: 2)
$Script:FlowLockRetryDelay = if ($env:FLOW_LOCK_RETRY_DELAY) { [int]$env:FLOW_LOCK_RETRY_DELAY } else { 2 }

#
# Ensure lock directory exists
#
function Ensure-LockDir {
    if (-not (Test-Path $Script:FlowLockDir)) {
        New-Item -ItemType Directory -Path $Script:FlowLockDir -Force | Out-Null
    }
}

#
# Get hash of a string (for lock file naming)
#
function Get-StringHash {
    param([string]$InputString)
    $hashAlgorithm = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $hashAlgorithm.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))
    $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    $hashAlgorithm.Dispose()
    return $hash.Substring(0, 16)  # Use first 16 chars
}

#
# Get lock path for a PRD
#
function Get-PrdLockPath {
    param([string]$PrdFile)
    $prdHash = Get-StringHash $PrdFile
    return Join-Path $Script:FlowLockDir "${prdHash}-prd.lock"
}

#
# Get lock path for a story within a PRD
#
function Get-StoryLockPath {
    param([string]$PrdFile, [string]$StoryId)
    $storyHash = Get-StringHash "${PrdFile}:${StoryId}"
    return Join-Path $Script:FlowLockDir "${storyHash}-story.lock"
}

#
# Get lock data file path
#
function Get-LockDataPath {
    param([string]$LockPath)
    return "${LockPath}.data"
}

#
# Update heartbeat for an existing lock
#
function Update-Heartbeat {
    param([string]$LockDataPath)

    if (Test-Path $LockDataPath) {
        $lockData = Get-Content $LockDataPath -Raw | ConvertFrom-Json
        $lockData.lastHeartbeat = [int][double]::Parse((Get-Date -UFormat %s))
        $lockData | ConvertTo-Json -Depth 10 | Set-Content $LockDataPath
    }
}

#
# Check if a lock is stale (owner dead or heartbeat expired)
#
function Test-LockStale {
    param([string]$LockDataPath)

    if (-not (Test-Path $LockDataPath)) {
        return $false
    }

    $lockData = Get-Content $LockDataPath -Raw | ConvertFrom-Json
    $ownerPid = $lockData.pid
    $lastHeartbeat = $lockData.lastHeartbeat
    $now = [int][double]::Parse((Get-Date -UFormat %s))
    $age = $now - $lastHeartbeat

    # Check if owner process is still running
    $ownerAlive = $false
    try {
        $process = Get-Process -Id $ownerPid -ErrorAction Stop
        if ($process) {
            $ownerAlive = $true
        }
    } catch {
        $ownerAlive = $false
    }

    # Lock is stale if owner is dead or heartbeat expired
    return (-not $ownerAlive -or $age -ge $Script:FlowHeartbeatTimeout)
}

#
# Acquire PRD-level lock for conversion/repair
#
function Acquire-PrdLock {
    param(
        [string]$PrdFile,
        [string]$SessionId = "manual-$PID",
        [int]$RetryCount = 0
    )

    Ensure-LockDir
    $lockPath = Get-PrdLockPath $PrdFile
    $lockDataPath = Get-LockDataPath $lockPath

    while ($RetryCount -lt $Script:FlowLockMaxRetries) {
        # Try to create lock file exclusively
        try {
            # Check if lock exists and is valid
            if (Test-Path $lockDataPath) {
                if (Test-LockStale $lockDataPath) {
                    # Clean up stale lock
                    Remove-Item $lockDataPath -Force
                } else {
                    # Lock is valid and owner is alive
                    $lockData = Get-Content $lockDataPath -Raw | ConvertFrom-Json
                    $owner = $lockData.sessionId
                    $ownerPid = $lockData.pid
                    Write-Error "ERROR: PRD is locked by session ${owner} (PID: ${ownerPid})"
                    return $null
                }
            }

            # Write lock data with timestamp
            $lockObject = @{
                sessionId = $SessionId
                pid = $PID
                prdFile = $PrdFile
                lockedAt = [int][double]::Parse((Get-Date -UFormat %s))
                lastHeartbeat = [int][double]::Parse((Get-Date -UFormat %s))
                lockType = "prd"
            }
            $lockObject | ConvertTo-Json -Depth 10 | Set-Content $lockDataPath

            return $SessionId
        } catch {
            # Failed to acquire lock
        }

        $RetryCount++
        if ($RetryCount -lt $Script:FlowLockMaxRetries) {
            Write-Host "Waiting for lock... (retry $RetryCount/$($Script:FlowLockMaxRetries))" -ForegroundColor Yellow
            Start-Sleep -Seconds $Script:FlowLockRetryDelay
        }
    }

    Write-Error "ERROR: Failed to acquire lock after $Script:FlowLockMaxRetries attempts"
    return $null
}

#
# Release PRD-level lock
#
function Release-PrdLock {
    param(
        [string]$PrdFile,
        [string]$SessionId = "manual-$PID"
    )

    $lockPath = Get-PrdLockPath $PrdFile
    $lockDataPath = Get-LockDataPath $lockPath

    if (-not (Test-Path $lockDataPath)) {
        return
    }

    try {
        $lockData = Get-Content $lockDataPath -Raw | ConvertFrom-Json
        $owner = $lockData.sessionId
        if ($owner -eq $SessionId) {
            Remove-Item $lockDataPath -Force
        } else {
            Write-Warning "WARNING: Cannot release lock owned by ${owner}"
        }
    } catch {
        # Lock file might have been removed already
    }
}

#
# Check if PRD is locked
#
function Test-PrdLocked {
    param([string]$PrdFile)

    $lockDataPath = Get-LockDataPath (Get-PrdLockPath $PrdFile)

    if (-not (Test-Path $lockDataPath)) {
        return $false
    }

    # Check if lock is stale
    if (Test-LockStale $lockDataPath) {
        Remove-Item $lockDataPath -Force  # Clean up stale lock
        return $false
    }

    return $true
}

#
# Get lock info for a PRD
#
function Get-PrdLockInfo {
    param([string]$PrdFile)

    $lockDataPath = Get-LockDataPath (Get-PrdLockPath $PrdFile)

    if (-not (Test-Path $lockDataPath)) {
        return $null
    }

    if (Test-LockStale $lockDataPath) {
        return "Lock is stale (owner dead or expired)"
    }

    return Get-Content $lockDataPath -Raw | ConvertFrom-Json
}

#
# Acquire story-level lock for working on a specific story
#
function Acquire-StoryLock {
    param(
        [string]$PrdFile,
        [string]$StoryId,
        [string]$SessionId = "manual-$PID",
        [int]$RetryCount = 0
    )

    Ensure-LockDir
    $lockPath = Get-StoryLockPath $PrdFile $StoryId
    $lockDataPath = Get-LockDataPath $lockPath

    while ($RetryCount -lt $Script:FlowLockMaxRetries) {
        try {
            # Check if lock exists and is valid
            if (Test-Path $lockDataPath) {
                if (Test-LockStale $lockDataPath) {
                    Remove-Item $lockDataPath -Force
                } else {
                    $lockData = Get-Content $lockDataPath -Raw | ConvertFrom-Json
                    $owner = $lockData.sessionId
                    Write-Error "ERROR: Story ${StoryId} is locked by session ${owner}"
                    return $null
                }
            }

            # Write lock data
            $lockObject = @{
                sessionId = $SessionId
                pid = $PID
                prdFile = $PrdFile
                storyId = $StoryId
                lockedAt = [int][double]::Parse((Get-Date -UFormat %s))
                lastHeartbeat = [int][double]::Parse((Get-Date -UFormat %s))
                lockType = "story"
            }
            $lockObject | ConvertTo-Json -Depth 10 | Set-Content $lockDataPath

            return $SessionId
        } catch {
            # Failed to acquire lock
        }

        $RetryCount++
        if ($RetryCount -lt $Script:FlowLockMaxRetries) {
            Start-Sleep -Seconds $Script:FlowLockRetryDelay
        }
    }

    return $null
}

#
# Release story-level lock
#
function Release-StoryLock {
    param(
        [string]$PrdFile,
        [string]$StoryId,
        [string]$SessionId = "manual-$PID"
    )

    $lockPath = Get-StoryLockPath $PrdFile $StoryId
    $lockDataPath = Get-LockDataPath $lockPath

    if (-not (Test-Path $lockDataPath)) {
        return
    }

    try {
        $lockData = Get-Content $lockDataPath -Raw | ConvertFrom-Json
        $owner = $lockData.sessionId
        if ($owner -eq $SessionId) {
            Remove-Item $lockDataPath -Force
        }
    } catch {
        # Lock might have been removed
    }
}

#
# Check if story is locked
#
function Test-StoryLocked {
    param(
        [string]$PrdFile,
        [string]$StoryId
    )

    $lockDataPath = Get-LockDataPath (Get-StoryLockPath $PrdFile $StoryId)

    if (-not (Test-Path $lockDataPath)) {
        return $false
    }

    if (Test-LockStale $lockDataPath) {
        Remove-Item $lockDataPath -Force
        return $false
    }

    return $true
}

#
# List all active locks
#
function Get-ActiveLocks {
    Ensure-LockDir

    $lockDataFiles = Get-ChildItem -Path $Script:FlowLockDir -Filter "*.data" -ErrorAction SilentlyContinue

    foreach ($lockDataFile in $lockDataFiles) {
        if (Test-LockStale $lockDataFile.FullName) {
            # Clean up stale locks
            $lockFile = $lockDataFile.FullName -replace '\.data$'
            Remove-Item $lockDataFile.FullName -Force -ErrorAction SilentlyContinue
            Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
            continue
        }

        $lockData = Get-Content $lockDataFile.FullName -Raw | ConvertFrom-Json
        $lockType = $lockData.lockType
        $session = $lockData.sessionId
        $pid = $lockData.pid

        switch ($lockType) {
            "prd" {
                $prdFile = $lockData.prdFile
                Write-Host "PRD Lock: $prdFile (session: $session, pid: $pid)"
            }
            "story" {
                $prdFile = $lockData.prdFile
                $storyId = $lockData.storyId
                Write-Host "Story Lock: $prdFile : $storyId (session: $session, pid: $pid)"
            }
        }
    }
}

#
# Clean up all stale locks
#
function Remove-StaleLocks {
    Ensure-LockDir

    $cleaned = 0
    $lockDataFiles = Get-ChildItem -Path $Script:FlowLockDir -Filter "*.data" -ErrorAction SilentlyContinue

    foreach ($lockDataFile in $lockDataFiles) {
        if (Test-LockStale $lockDataFile.FullName) {
            $lockFile = $lockDataFile.FullName -replace '\.data$'
            Remove-Item $lockDataFile.FullName -Force -ErrorAction SilentlyContinue
            Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
            $cleaned++
        }
    }

    Write-Host "Cleaned $cleaned stale lock(s)"
}

#
# Force unlock a PRD (use with caution!)
#
function Unlock-PrdForce {
    param([string]$PrdFile)

    $lockDataPath = Get-LockDataPath (Get-PrdLockPath $PrdFile)

    if (Test-Path $lockDataPath) {
        $lockData = Get-Content $lockDataPath -Raw | ConvertFrom-Json
        $owner = $lockData.sessionId
        $pid = $lockData.pid
        Write-Warning "WARNING: Force unlocking PRD locked by $owner (PID: $pid)"
        Remove-Item $lockDataPath -Force
        return $true
    }

    return $false
}

#
# Update heartbeats for all locks owned by this session
#
function Update-SessionHeartbeats {
    param([string]$SessionId = "manual-$PID")

    Ensure-LockDir

    $lockDataFiles = Get-ChildItem -Path $Script:FlowLockDir -Filter "*.data" -ErrorAction SilentlyContinue

    foreach ($lockDataFile in $lockDataFiles) {
        $lockData = Get-Content $lockDataFile.FullName -Raw | ConvertFrom-Json
        $owner = $lockData.sessionId
        if ($owner -eq $SessionId) {
            Update-Heartbeat $lockDataFile.FullName
        }
    }
}

#
# Clear all locks for a session
#
function Clear-SessionLocks {
    param([string]$SessionId)

    Ensure-LockDir

    $lockDataFiles = Get-ChildItem -Path $Script:FlowLockDir -Filter "*.data" -ErrorAction SilentlyContinue

    foreach ($lockDataFile in $lockDataFiles) {
        $lockData = Get-Content $lockDataFile.FullName -Raw | ConvertFrom-Json
        $owner = $lockData.sessionId
        if ($owner -eq $SessionId) {
            $lockFile = $lockDataFile.FullName -replace '\.data$'
            Remove-Item $lockDataFile.FullName -Force -ErrorAction SilentlyContinue
            Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Ensure-LockDir',
    'Get-PrdLockPath',
    'Get-StoryLockPath',
    'Update-Heartbeat',
    'Test-LockStale',
    'Acquire-PrdLock',
    'Release-PrdLock',
    'Test-PrdLocked',
    'Get-PrdLockInfo',
    'Acquire-StoryLock',
    'Release-StoryLock',
    'Test-StoryLocked',
    'Get-ActiveLocks',
    'Remove-StaleLocks',
    'Unlock-PrdForce',
    'Update-SessionHeartbeats',
    'Clear-SessionLocks'
)
