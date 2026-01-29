#!/bin/bash
# ============================================================================
# Maven Flow - Lock System Test Script
# ============================================================================
#
# This script tests the filesystem-coordinated locking system by simulating
# multiple concurrent sessions, heartbeat updates, and lock reclaim scenarios.
#
# Usage: bin/test-locks.sh [--verbose]
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Test configuration
VERBOSE="${1:-}"
LOCK_DIR=".flow-locks"
# Use docs/ directory for test PRD since find_and_lock_story looks there
TEST_PRD_DIR="docs"
TEST_PRD_FILE="$TEST_PRD_DIR/prd-test-locks.json"
SESSION_PREFIX="test-session"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_verbose() {
    if [ "$VERBOSE" = "--verbose" ]; then
        echo -e "${GRAY}[DEBUG]${NC} $1"
    fi
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment..."

    # Create test PRD directory
    mkdir -p "$TEST_PRD_DIR"

    # Save existing test PRD if it exists
    if [ -f "$TEST_PRD_FILE" ]; then
        mv "$TEST_PRD_FILE" "${TEST_PRD_FILE}.backup"
        log_verbose "Backed up existing $TEST_PRD_FILE"
    fi

    # Create a test PRD with 5 incomplete stories
    cat > "$TEST_PRD_FILE" << 'EOF'
{
  "title": "Test PRD for Lock Validation",
  "userStories": [
    {
      "id": "story-1",
      "title": "First Story",
      "passes": false,
      "mavenSteps": [1, 2, 3, 4, 5]
    },
    {
      "id": "story-2",
      "title": "Second Story",
      "passes": false,
      "mavenSteps": [1, 2, 3, 4, 5]
    },
    {
      "id": "story-3",
      "title": "Third Story",
      "passes": false,
      "mavenSteps": [1, 2, 3, 4, 5]
    },
    {
      "id": "story-4",
      "title": "Fourth Story",
      "passes": false,
      "mavenSteps": [1, 2, 3, 4, 5]
    },
    {
      "id": "story-5",
      "title": "Fifth Story",
      "passes": false,
      "mavenSteps": [1, 2, 3, 4, 5]
    }
  ]
}
EOF

    # Create lock directory
    mkdir -p "$LOCK_DIR"

    # Source lock library
    if [ ! -f ".claude/lib/lock.sh" ]; then
        log_fail "Lock library not found at .claude/lib/lock.sh"
        exit 1
    fi
    source .claude/lib/lock.sh

    log_success "Test environment ready"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment..."

    # Restore backup if it exists
    if [ -f "${TEST_PRD_FILE}.backup" ]; then
        mv "${TEST_PRD_FILE}.backup" "$TEST_PRD_FILE"
        log_verbose "Restored backup of $TEST_PRD_FILE"
    else
        rm -f "$TEST_PRD_FILE"
    fi

    rm -rf "$LOCK_DIR"
    log_success "Cleanup complete"
}

# Test 1: Single session can lock a story
test_single_lock() {
    echo ""
    log_info "Test 1: Single session can lock a story"

    local session_id="${SESSION_PREFIX}-1"

    if result=$(find_and_lock_story "$session_id"); then
        local prd_file=$(echo "$result" | cut -d'|' -f1)
        local story_id=$(echo "$result" | cut -d'|' -f2)

        log_verbose "Locked: $story_id from $prd_file"

        # Verify lock file exists
        local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
        local lock_file="$LOCK_DIR/${prd_hash}-${story_id}.lock"
        local lock_data="$LOCK_DIR/${prd_hash}-${story_id}.lock.data"

        if [ -f "$lock_file" ] && [ -f "$lock_data" ]; then
            log_success "Single session can lock a story"

            # Verify lock data
            local locked_session=$(jq -r '.sessionId' "$lock_data")
            local locked_pid=$(jq -r '.pid' "$lock_data")

            if [ "$locked_session" = "$session_id" ]; then
                log_success "Lock data contains correct session ID"
            else
                log_fail "Lock data has incorrect session ID: $locked_session"
            fi

            # Unlock
            unlock_story "$prd_file" "$story_id" "$session_id"

            # Verify unlock
            if [ ! -f "$lock_data" ]; then
                log_success "Story unlocked successfully"
            else
                log_fail "Story did not unlock properly"
            fi
        else
            log_fail "Lock files not created"
        fi
    else
        log_fail "Failed to lock story"
    fi
}

# Test 2: Two sessions cannot lock the same story
test_concurrent_locks() {
    echo ""
    log_info "Test 2: Two sessions cannot lock the same story"

    local session_1="${SESSION_PREFIX}-2a"
    local session_2="${SESSION_PREFIX}-2b"

    # Session 1 locks a story
    if result1=$(find_and_lock_story "$session_1"); then
        local prd_file=$(echo "$result1" | cut -d'|' -f1)
        local story_1=$(echo "$result1" | cut -d'|' -f2)
        log_verbose "Session 1 locked: $story_1"

        # Session 2 tries to lock a story
        if result2=$(find_and_lock_story "$session_2"); then
            local story_2=$(echo "$result2" | cut -d'|' -f2)
            log_verbose "Session 2 locked: $story_2"

            # Verify they locked DIFFERENT stories
            if [ "$story_1" != "$story_2" ]; then
                log_success "Concurrent sessions locked different stories"
            else
                log_fail "Concurrent sessions locked the SAME story!"
            fi

            # Cleanup
            unlock_story "$prd_file" "$story_1" "$session_1"

            # Find the PRD file for story 2
            local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
            local lock_file_2="$LOCK_DIR/${prd_hash}-${story_2}.lock"
            local lock_data_2="$LOCK_DIR/${prd_hash}-${story_2}.lock.data"

            # Read PRD from lock data
            if [ -f "$lock_data_2" ]; then
                local prd_file_2=$(jq -r '.prdFile' "$lock_data_2")
                unlock_story "$prd_file_2" "$story_2" "$session_2"
            fi
        else
            log_fail "Session 2 failed to lock any story"
            unlock_story "$prd_file" "$story_1" "$session_1"
        fi
    else
        log_fail "Session 1 failed to lock a story"
    fi
}

# Test 3: Heartbeat updates work correctly
test_heartbeat_update() {
    echo ""
    log_info "Test 3: Heartbeat updates work correctly"

    local session_id="${SESSION_PREFIX}-3"

    if result=$(find_and_lock_story "$session_id"); then
        local prd_file=$(echo "$result" | cut -d'|' -f1)
        local story_id=$(echo "$result" | cut -d'|' -f2)

        local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
        local lock_data="$LOCK_DIR/${prd_hash}-${story_id}.lock.data"

        # Get initial heartbeat
        local initial_heartbeat=$(jq -r '.lastHeartbeat' "$lock_data")
        log_verbose "Initial heartbeat: $initial_heartbeat"

        # Wait a moment
        sleep 2

        # Update heartbeat
        update_session_heartbeats "$session_id"

        # Get updated heartbeat
        local updated_heartbeat=$(jq -r '.lastHeartbeat' "$lock_data")
        log_verbose "Updated heartbeat: $updated_heartbeat"

        if [ "$updated_heartbeat" -gt "$initial_heartbeat" ]; then
            log_success "Heartbeat updated correctly"
        else
            log_fail "Heartbeat did not update"
        fi

        # Cleanup
        unlock_story "$prd_file" "$story_id" "$session_id"
    else
        log_fail "Failed to lock story for heartbeat test"
    fi
}

# Test 4: Dead PID allows lock reclaim
test_dead_pid_reclaim() {
    echo ""
    log_info "Test 4: Dead PID allows lock reclaim"

    local session_1="${SESSION_PREFIX}-4"
    local session_2="${SESSION_PREFIX}-4-reclaim"

    # Session 1 locks a story
    if result=$(find_and_lock_story "$session_1"); then
        local prd_file=$(echo "$result" | cut -d'|' -f1)
        local story_id=$(echo "$result" | cut -d'|' -f2)

        local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
        local lock_data="$LOCK_DIR/${prd_hash}-${story_id}.lock.data"

        # Get the PID from lock data
        local lock_pid=$(jq -r '.pid' "$lock_data")
        log_verbose "Lock PID: $lock_pid"

        # Manually set heartbeat to be old (simulate dead session)
        local old_heartbeat=$(($(date +%s) - FLOW_HEARTBEAT_TIMEOUT - 10))
        jq --arg hb "$old_heartbeat" '.lastHeartbeat = ($hb | tonumber)' "$lock_data" > "${lock_data}.tmp"
        mv "${lock_data}.tmp" "$lock_data"
        log_verbose "Set heartbeat to old value: $old_heartbeat"

        # Session 2 should be able to reclaim the lock
        if result2=$(find_and_lock_story "$session_2"); then
            local reclaimed_story=$(echo "$result2" | cut -d'|' -f2)

            if [ "$reclaimed_story" = "$story_id" ]; then
                log_success "Dead PID lock was reclaimed successfully"
            else
                log_fail "Reclaimed different story instead: $reclaimed_story"
            fi

            # Cleanup
            unlock_story "$prd_file" "$story_id" "$session_2"
        else
            log_fail "Failed to reclaim lock from dead PID"
            # Try to cleanup anyway
            rm -f "$lock_data"
        fi
    else
        log_fail "Failed to lock story for reclaim test"
    fi
}

# Test 5: Clear all session locks works
test_clear_all_locks() {
    echo ""
    log_info "Test 5: Clear all session locks works"

    local session_id="${SESSION_PREFIX}-5"

    # Lock multiple stories
    local locked_stories=()
    for i in {1..3}; do
        if result=$(find_and_lock_story "$session_id"); then
            local prd_file=$(echo "$result" | cut -d'|' -f1)
            local story_id=$(echo "$result" | cut -d'|' -f2)
            locked_stories+=("$prd_file|$story_id")
            log_verbose "Locked: $story_id"
        fi
    done

    if [ ${#locked_stories[@]} -eq 0 ]; then
        log_fail "Failed to lock any stories"
        return
    fi

    # Clear all locks for session
    clear_all_session_locks "$session_id"

    # Verify all locks are cleared
    local all_cleared=true
    for lock_entry in "${locked_stories[@]}"; do
        local prd_file=$(echo "$lock_entry" | cut -d'|' -f1)
        local story_id=$(echo "$lock_entry" | cut -d'|' -f2)
        local prd_hash=$(echo "$prd_file" | md5sum | cut -d' ' -f1)
        local lock_data="$LOCK_DIR/${prd_hash}-${story_id}.lock.data"

        if [ -f "$lock_data" ]; then
            log_verbose "Lock still exists for $story_id"
            all_cleared=false
        fi
    done

    if [ "$all_cleared" = true ]; then
        log_success "All session locks cleared successfully"
    else
        log_fail "Some locks were not cleared"
    fi
}

# Test 6: Lock status display
test_lock_status_display() {
    echo ""
    log_info "Test 6: Lock status display"

    local session_id="${SESSION_PREFIX}-6"

    if result=$(find_and_lock_story "$session_id"); then
        local prd_file=$(echo "$result" | cut -d'|' -f1)
        local story_id=$(echo "$result" | cut -d'|' -f2)

        # Check that lock files exist
        local lock_count=$(ls -1 "$LOCK_DIR"/*.lock.data 2>/dev/null | wc -l)

        if [ "$lock_count" -gt 0 ]; then
            log_success "Lock files created for status display ($lock_count lock(s))"

            if [ "$VERBOSE" = "--verbose" ]; then
                echo ""
                echo "Current lock status:"
                for lock_data in "$LOCK_DIR"/*.lock.data; do
                    [ -f "$lock_data" ] || continue
                    local sid=$(jq -r '.storyId' "$lock_data")
                    local sess=$(jq -r '.sessionId' "$lock_data")
                    local pid=$(jq -r '.pid' "$lock_data")
                    echo "  - Story: $sid, Session: ${sess:0:8}, PID: $pid"
                done
                echo ""
            fi
        else
            log_fail "No lock files found for status display"
        fi

        # Cleanup
        unlock_story "$prd_file" "$story_id" "$session_id"
    else
        log_fail "Failed to lock story for status test"
    fi
}

# Main test runner
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Maven Flow - Lock System Test Suite                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Save current directory
    local original_dir=$(pwd)

    # Change to project root
    cd "$(dirname "$0")/.." || exit 1

    # Setup
    setup_test_env

    # Run tests
    test_single_lock
    test_concurrent_locks
    test_heartbeat_update
    test_dead_pid_reclaim
    test_clear_all_locks
    test_lock_status_display

    # Cleanup
    cleanup_test_env

    # Return to original directory
    cd "$original_dir"

    # Summary
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Test Summary                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] All tests passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}[FAILURE] Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Run main function
main "$@"
