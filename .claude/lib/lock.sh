#!/usr/bin/env bash
#
# PRD and Story Locking Library for Maven Flow
#
# Provides flock-based locking with heartbeat-based stale lock detection.
# Supports both PRD-level and story-level locking.
#
# Usage:
#   source .claude/lib/lock.sh
#   acquire_prd_lock "docs/prd-feature.json" "session-id"
#   # ... do work ...
#   release_prd_lock "docs/prd-feature.json" "session-id"
#

# Lock directory
FLOW_LOCK_DIR="${FLOW_LOCK_DIR:-.flow-locks}"

# Heartbeat timeout in seconds (default: 5 minutes)
FLOW_HEARTBEAT_TIMEOUT="${FLOW_HEARTBEAT_TIMEOUT:-300}"

# Maximum retries for lock acquisition (default: 3)
FLOW_LOCK_MAX_RETRIES="${FLOW_LOCK_MAX_RETRIES:-3}"

# Retry delay in seconds (default: 2)
FLOW_LOCK_RETRY_DELAY="${FLOW_LOCK_RETRY_DELAY:-2}"

#
# Ensure lock directory exists
#
ensure_lock_dir() {
    mkdir -p "$FLOW_LOCK_DIR"
}

#
# Get lock path for a PRD
#
prd_lock_path() {
    local prd_file="$1"
    # Use hash of full path to ensure uniqueness
    local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
    echo "${FLOW_LOCK_DIR}/${prd_hash}-prd.lock"
}

#
# Get lock path for a story within a PRD
#
story_lock_path() {
    local prd_file="$1"
    local story_id="$2"
    # Use hash of PRD path + story ID
    local story_hash=$(echo "${prd_file}:${story_id}" | md5sum | cut -d' ' -f1)
    echo "${FLOW_LOCK_DIR}/${story_hash}-story.lock"
}

#
# Update heartbeat for an existing lock
#
update_heartbeat() {
    local lock_data_path="$1"
    if [ -f "$lock_data_path" ]; then
        (
            flock -x 9
            local session_id=$(jq -r '.sessionId // empty' "$lock_data_path" 2>/dev/null)
            if [ -n "$session_id" ]; then
                jq --arg ts "$(date +%s)" '.lastHeartbeat = ($ts | tonumber)' "$lock_data_path" > "${lock_data_path}.tmp" 2>/dev/null
                if [ $? -eq 0 ]; then
                    mv "${lock_data_path}.tmp" "$lock_data_path"
                fi
            fi
        ) 9>"${lock_data_path}.lock"
    fi
}

#
# Check if a lock is stale (owner dead or heartbeat expired)
#
is_lock_stale() {
    local lock_data_path="$1"
    [ -f "$lock_data_path" ] || return 1

    local owner_pid=$(jq -r '.pid // empty' "$lock_data_path" 2>/dev/null)
    local last_heartbeat=$(jq -r '.lastHeartbeat // 0' "$lock_data_path" 2>/dev/null)
    local now=$(date +%s)
    local age=$((now - last_heartbeat))

    # Lock is stale if owner is dead or heartbeat expired
    if [ -z "$owner_pid" ] || ! kill -0 "$owner_pid" 2>/dev/null || [ "$age" -ge "$FLOW_HEARTBEAT_TIMEOUT" ]; then
        return 0
    fi

    return 1
}

#
# Acquire PRD-level lock for conversion/repair
#
# Returns: 0 on success, 1 on failure, exits on max retries
#
acquire_prd_lock() {
    local prd_file="$1"
    local session_id="${2:-manual-$$}"
    local session_pid=$$
    local retry_count=0

    ensure_lock_dir
    local lock_path=$(prd_lock_path "$prd_file")
    local lock_data_path="${lock_path}.data"

    while [ $retry_count -lt $FLOW_LOCK_MAX_RETRIES ]; do
        (
            flock -x -n 9 || exit 1

            # Check if lock exists and is valid
            if [ -f "$lock_data_path" ]; then
                if is_lock_stale "$lock_data_path"; then
                    # Clean up stale lock
                    rm -f "$lock_data_path"
                else
                    # Lock is valid and owner is alive
                    local owner=$(jq -r '.sessionId // "unknown"' "$lock_data_path" 2>/dev/null)
                    local owner_pid=$(jq -r '.pid // "?"' "$lock_data_path" 2>/dev/null)
                    echo "ERROR: PRD is locked by session ${owner} (PID: ${owner_pid})" >&2
                    exit 1
                fi
            fi

            # Write lock data with timestamp
            cat > "$lock_data_path" <<EOF
{
  "sessionId": "${session_id}",
  "pid": ${session_pid},
  "prdFile": "${prd_file}",
  "lockedAt": $(date +%s),
  "lastHeartbeat": $(date +%s),
  "lockType": "prd"
}
EOF
            echo "$session_id"
            exit 0
        ) 9>"$lock_path"

        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $FLOW_LOCK_MAX_RETRIES ]; then
            echo "Waiting for lock... (retry $retry_count/$FLOW_LOCK_MAX_RETRIES)" >&2
            sleep $FLOW_LOCK_RETRY_DELAY
        fi
    done

    echo "ERROR: Failed to acquire lock after $FLOW_LOCK_MAX_RETRIES attempts" >&2
    return 1
}

#
# Release PRD-level lock
#
release_prd_lock() {
    local prd_file="$1"
    local session_id="${2:-manual-$$}"

    local lock_path=$(prd_lock_path "$prd_file")
    local lock_data="${lock_path}.data"

    [ -f "$lock_data" ] || return 0

    (
        flock -x 9
        local owner=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        if [ "$owner" = "$session_id" ]; then
            rm -f "$lock_data"
        else
            echo "WARNING: Cannot release lock owned by ${owner}" >&2
            return 1
        fi
    ) 9>"$lock_path"
}

#
# Check if PRD is locked
#
is_prd_locked() {
    local prd_file="$1"
    local lock_path=$(prd_lock_path "$prd_file")
    local lock_data="${lock_path}.data"

    [ -f "$lock_data" ] || return 1

    # Check if lock is stale
    if is_lock_stale "$lock_data"; then
        rm -f "$lock_data"  # Clean up stale lock
        return 1
    fi

    return 0
}

#
# Get lock info for a PRD
#
get_prd_lock_info() {
    local prd_file="$1"
    local lock_data="$(prd_lock_path "$prd_file").data"

    [ -f "$lock_data" ] || return 1

    if is_lock_stale "$lock_data"; then
        echo "Lock is stale (owner dead or expired)"
        return 1
    fi

    jq -r '"Session: \(.sessionId)\nPID: \(.pid)\nFile: \(.prdFile)\nLocked: \(.lockedAt | tonumber | strftime("%Y-%m-%d %H:%M:%S"))\nHeartbeat: \(.lastHeartbeat | tonumber | strftime("%Y-%m-%d %H:%M:%S"))"' "$lock_data" 2>/dev/null
}

#
# Acquire story-level lock for working on a specific story
#
acquire_story_lock() {
    local prd_file="$1"
    local story_id="$2"
    local session_id="${3:-manual-$$}"
    local session_pid=$$
    local retry_count=0

    ensure_lock_dir
    local lock_path=$(story_lock_path "$prd_file" "$story_id")
    local lock_data_path="${lock_path}.data"

    while [ $retry_count -lt $FLOW_LOCK_MAX_RETRIES ]; do
        (
            flock -x -n 9 || exit 1

            if [ -f "$lock_data_path" ]; then
                if is_lock_stale "$lock_data_path"; then
                    rm -f "$lock_data_path"
                else
                    local owner=$(jq -r '.sessionId // "unknown"' "$lock_data_path" 2>/dev/null)
                    echo "ERROR: Story ${story_id} is locked by session ${owner}" >&2
                    exit 1
                fi
            fi

            cat > "$lock_data_path" <<EOF
{
  "sessionId": "${session_id}",
  "pid": ${session_pid},
  "prdFile": "${prd_file}",
  "storyId": "${story_id}",
  "lockedAt": $(date +%s),
  "lastHeartbeat": $(date +%s),
  "lockType": "story"
}
EOF
            echo "$session_id"
            exit 0
        ) 9>"$lock_path"

        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $FLOW_LOCK_MAX_RETRIES ]; then
            sleep $FLOW_LOCK_RETRY_DELAY
        fi
    done

    return 1
}

#
# Release story-level lock
#
release_story_lock() {
    local prd_file="$1"
    local story_id="$2"
    local session_id="${3:-manual-$$}"

    local lock_path=$(story_lock_path "$prd_file" "$story_id")
    local lock_data="${lock_path}.data"

    [ -f "$lock_data" ] || return 0

    (
        flock -x 9
        local owner=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        if [ "$owner" = "$session_id" ]; then
            rm -f "$lock_data"
        fi
    ) 9>"$lock_path"
}

#
# Check if story is locked
#
is_story_locked() {
    local prd_file="$1"
    local story_id="$2"
    local lock_path=$(story_lock_path "$prd_file" "$story_id")
    local lock_data="${lock_path}.data"

    [ -f "$lock_data" ] || return 1

    if is_lock_stale "$lock_data"; then
        rm -f "$lock_data"
        return 1
    fi

    return 0
}

#
# List all active locks
#
list_active_locks() {
    ensure_lock_dir

    for lock_data in "${FLOW_LOCK_DIR}"/*.data; do
        [ -f "$lock_data" ] || continue

        if is_lock_stale "$lock_data"; then
            # Clean up stale locks
            local lock_file="${lock_data%.data}"
            rm -f "$lock_data" "$lock_file"
            continue
        fi

        local lock_type=$(jq -r '.lockType // "unknown"' "$lock_data" 2>/dev/null)
        local session=$(jq -r '.sessionId // "unknown"' "$lock_data" 2>/dev/null)
        local pid=$(jq -r '.pid // "?"' "$lock_data" 2>/dev/null)

        case "$lock_type" in
            prd)
                local prd_file=$(jq -r '.prdFile // ""' "$lock_data" 2>/dev/null)
                echo "PRD Lock: $prd_file (session: $session, pid: $pid)"
                ;;
            story)
                local prd_file=$(jq -r '.prdFile // ""' "$lock_data" 2>/dev/null)
                local story_id=$(jq -r '.storyId // ""' "$lock_data" 2>/dev/null)
                echo "Story Lock: $prd_file:$story_id (session: $session, pid: $pid)"
                ;;
        esac
    done
}

#
# Clean up all stale locks
#
cleanup_stale_locks() {
    ensure_lock_dir

    local cleaned=0
    for lock_data in "${FLOW_LOCK_DIR}"/*.data; do
        [ -f "$lock_data" ] || continue

        if is_lock_stale "$lock_data"; then
            local lock_file="${lock_data%.data}"
            rm -f "$lock_data" "$lock_file"
            cleaned=$((cleaned + 1))
        fi
    done

    echo "Cleaned $cleaned stale lock(s)"
}

#
# Force unlock a PRD (use with caution!)
#
force_unlock_prd() {
    local prd_file="$1"
    local lock_path=$(prd_lock_path "$prd_file")
    local lock_data="${lock_path}.data"

    if [ -f "$lock_data" ]; then
        local owner=$(jq -r '.sessionId // "unknown"' "$lock_data" 2>/dev/null)
        local pid=$(jq -r '.pid // "?"' "$lock_data" 2>/dev/null)
        echo "WARNING: Force unlocking PRD locked by $owner (PID: $pid)" >&2
        rm -f "$lock_data"
        return 0
    fi

    return 1
}

#
# Find and lock the next available incomplete story
#
# Returns: "prd_file|story_id" on success, 1 on failure (all complete)
#
find_and_lock_story() {
    local session_id="${1:-manual-$$}"

    # Iterate through all PRD files
    for prd_file in docs/prd-*.json; do
        [ -f "$prd_file" ] || continue

        # Get all incomplete stories, sorted by priority
        local stories=$(jq -r '.userStories | map(select(.passes != true)) | sort_by(.priority) | .[] | "\(.id)|\(.title)|\(.priority)"' "$prd_file" 2>/dev/null)

        if [ -z "$stories" ]; then
            continue  # No incomplete stories in this PRD
        fi

        # Try each story in priority order
        while IFS='|' read -r story_id story_title priority; do
            [ -n "$story_id" ] || continue

            # Try to acquire lock for this story
            if acquire_story_lock "$prd_file" "$story_id" "$session_id" 2>/dev/null; then
                echo "${prd_file}|${story_id}"
                return 0
            fi
        done <<< "$stories"
    done

    return 1  # No available stories
}

#
# Unlock a story (alias for release_story_lock)
#
unlock_story() {
    local prd_file="$1"
    local story_id="$2"
    local session_id="${3:-manual-$$}"

    release_story_lock "$prd_file" "$story_id" "$session_id"
}

#
# Update heartbeats for all locks owned by this session
#
update_session_heartbeats() {
    local session_id="${1:-manual-$$}"

    ensure_lock_dir

    for lock_data in "${FLOW_LOCK_DIR}"/*.data; do
        [ -f "$lock_data" ] || continue

        local owner=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
        if [ "$owner" = "$session_id" ]; then
            update_heartbeat "$lock_data"
        fi
    done
}

# Export functions for use in other scripts
export -f ensure_lock_dir
export -f prd_lock_path
export -f story_lock_path
export -f update_heartbeat
export -f is_lock_stale
export -f acquire_prd_lock
export -f release_prd_lock
export -f is_prd_locked
export -f get_prd_lock_info
export -f acquire_story_lock
export -f release_story_lock
export -f is_story_locked
export -f list_active_locks
export -f cleanup_stale_locks
export -f force_unlock_prd
export -f find_and_lock_story
export -f unlock_story
export -f update_session_heartbeats
