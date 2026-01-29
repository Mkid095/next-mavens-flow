#!/bin/bash
# ============================================================================
# Maven Flow - Filesystem-Coordinated Locking Library
# ============================================================================
#
# This library provides story-level locking using flock to prevent parallel
# sessions from working on the same story simultaneously.
#
# Critical Invariants:
#   1. Only flow.sh mutates PRDs - workers cannot modify story state
#   2. Heartbeat is source of truth - NOT time-based expiry
#   3. PID + heartbeat AND logic - Both must be valid for lock ownership
#   4. Never delete .lock files - Use flock exclusive mode for cleanup
#
# ============================================================================

# Heartbeat configuration (must be defined before use)
FLOW_HEARTBEAT_INTERVAL=60   # Update every 60 seconds
FLOW_HEARTBEAT_TIMEOUT=300   # 5x interval = 5 minutes before lock considered stale

# Get lock path for a story
story_lock_path() {
    local prd_file="$1"
    local story_id="$2"
    local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
    echo ".flow-locks/${prd_hash}-${story_id}.lock"
}

# Find and lock the next available story
# Returns: 0=success, 1=no stories available
# Outputs: PRD file and story ID to stdout
# IMPORTANT: stdout is authoritative only if function exits 0
find_and_lock_story() {
    local session_id="$1"
    local session_pid=$$

    mkdir -p .flow-locks

    for prd in docs/prd-*.json; do
        [ -f "$prd" ] || continue

        while IFS= read -r story_id; do
            local lock_path=$(story_lock_path "$prd" "$story_id")
            local lock_data_path="${lock_path}.data"

            # Try to acquire lock (non-blocking)
            (
                flock -x -n 9 || exit 1

                # CRITICAL: Re-verify story is still incomplete under lock
                # This avoids race conditions where PRD changes between scan and lock
                if ! jq -e ".userStories[] | select(.id==\"$story_id\" and .passes==false)" "$prd" >/dev/null 2>&1; then
                    exit 1
                fi

                # Read existing lock data
                if [ -f "$lock_data_path" ]; then
                    local owner_pid=$(jq -r '.pid // empty' "$lock_data_path" 2>/dev/null)
                    local last_heartbeat=$(jq -r '.lastHeartbeat // 0' "$lock_data_path" 2>/dev/null)
                    local now=$(date +%s)
                    local age=$((now - last_heartbeat))

                    # PID + heartbeat AND logic: BOTH must be valid
                    # Owner is alive only if PID exists AND heartbeat is fresh
                    if [ -n "$owner_pid" ] && kill -0 "$owner_pid" 2>/dev/null && [ "$age" -lt "$FLOW_HEARTBEAT_TIMEOUT" ]; then
                        exit 1  # Lock is valid, owner is alive
                    fi
                    # Owner dead or heartbeat stale - we can take it
                fi

                # Write our lock data
                cat > "$lock_data_path" <<EOF
{
  "sessionId": "$session_id",
  "pid": $session_pid,
  "storyId": "$story_id",
  "prdFile": "$prd",
  "lockedAt": $(date +%s),
  "lastHeartbeat": $(date +%s)
}
EOF

                # Output what we locked
                echo "$prd|$story_id"
                exit 0
            ) 9>"$lock_path"

            if [ $? -eq 0 ]; then
                return 0
            fi
        done < <(jq -r '.userStories[] | select(.passes == false) | .id' "$prd" 2>/dev/null)
    done

    return 1
}

# Unlock a single story (story-scoped, NOT session-scoped)
# Use this on story completion - NOT clear_all_session_locks
unlock_story() {
    local prd="$1"
    local story_id="$2"
    local session_id="$3"

    local lock_path=$(story_lock_path "$prd" "$story_id")
    local lock_data="${lock_path}.data"

    [ -f "$lock_data" ] || return 0

    (
        flock -x 9
        local owner=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        [ "$owner" = "$session_id" ] && rm -f "$lock_data"
    ) 9>"$lock_path"
}

# Clear all locks for current session (emergency cleanup only)
# Use this on session abort, NOT on story completion
clear_all_session_locks() {
    local session_id="$1"
    [ -d .flow-locks ] || return 0

    for lock_data in .flow-locks/*.lock.data; do
        [ -f "$lock_data" ] || continue

        local owner_session=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        if [ "$owner_session" = "$session_id" ]; then
            local lock_path="${lock_data%.data}"
            # Acquire lock to safely clear data
            (
                flock -x 9
                rm -f "$lock_data"
            ) 9>"$lock_path"
        fi
    done
}

# Update heartbeat for all locks owned by this session
update_session_heartbeats() {
    local session_id="$1"
    [ -d .flow-locks ] || return 0

    for lock_data in .flow-locks/*.lock.data; do
        [ -f "$lock_data" ] || continue

        local owner_session=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        if [ "$owner_session" = "$session_id" ]; then
            local lock_path="${lock_data%.data}"
            (
                flock -x 9
                jq --arg now "$(date +%s)" '.lastHeartbeat = ($now | tonumber)' "$lock_data" \
                  > "${lock_data}.tmp" && mv "${lock_data}.tmp" "$lock_data"
            ) 9>"$lock_path"
        fi
    done
}
