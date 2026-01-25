#!/bin/bash
# ============================================================================
# Maven Flow Session Save Hook
#
# Saves session state for auto-restore functionality.
# Stores: current PRD, story, step, timestamp, progress
#
# Usage: Called automatically by flow command or manually
#   ./session-save.sh --prd docs/prd-feature.json --story US-001 --step 1
#
# Session file: .claude/.session-state.json
# ============================================================================

set -o pipefail

# Configuration
SESSION_FILE=".claude/.session-state.json"
SESSION_TIMEOUT_HOURS=24
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# Session State Functions
# ============================================================================

# Save session state
save_session() {
    local prd_file="${1:-}"
    local story_id="${2:-}"
    local step="${3:-}"
    local agent="${4:-}"
    local status="${5:-in_progress}"

    # Get current timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local timestamp_ms=$(date +%s%3N)

    # Get git branch
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Get git commit
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    # Get project root
    local project_root="$(pwd)"

    # Create session state JSON
    local session_json=$(cat << EOF
{
  "version": 1,
  "timestamp": "$timestamp",
  "timestamp_ms": $timestamp_ms,
  "project_root": "$project_root",
  "git": {
    "branch": "$git_branch",
    "commit": "$git_commit"
  },
  "current": {
    "prd": "$prd_file",
    "story": "$story_id",
    "step": $step,
    "agent": "$agent",
    "status": "$status"
  }
}
EOF
)

    # Ensure .claude directory exists
    mkdir -p "$(dirname "$SESSION_FILE")"

    # Save to file
    echo "$session_json" > "$SESSION_FILE"

    log_success "Session state saved"
    log_info "PRD: $prd_file"
    log_info "Story: $story_id"
    log_info "Step: $step"
}

# Get session state
get_session() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo "{}"
        return
    fi

    cat "$SESSION_FILE"
}

# Check if session is still valid (within timeout)
is_session_valid() {
    if [ ! -f "$SESSION_FILE" ]; then
        return 1
    fi

    # Get session timestamp in milliseconds
    local session_ms=$(jq -r '.timestamp_ms // 0' "$SESSION_FILE" 2>/dev/null || echo "0")
    local current_ms=$(date +%s%3N)
    local timeout_ms=$((SESSION_TIMEOUT_HOURS * 60 * 60 * 1000))

    # Check if session is within timeout
    if [ $((current_ms - session_ms)) -lt $timeout_ms ]; then
        return 0
    else
        return 1
    fi
}

# Format session age in human-readable format
format_session_age() {
    local session_ms=$(jq -r '.timestamp_ms // 0' "$SESSION_FILE" 2>/dev/null || echo "0")
    local current_ms=$(date +%s%3N)
    local diff_ms=$((current_ms - session_ms))
    local diff_seconds=$((diff_ms / 1000))

    local hours=$((diff_seconds / 3600))
    local minutes=$(((diff_seconds % 3600) / 60))
    local seconds=$((diff_seconds % 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# Show session info
show_session_info() {
    if [ ! -f "$SESSION_FILE" ]; then
        log_warning "No session state found"
        return 1
    fi

    echo ""
    echo "=========================================="
    echo "  Session State"
    echo "=========================================="

    local timestamp=$(jq -r '.timestamp // "unknown"' "$SESSION_FILE")
    local prd=$(jq -r '.current.prd // "none"' "$SESSION_FILE")
    local story=$(jq -r '.current.story // "none"' "$SESSION_FILE")
    local step=$(jq -r '.current.step // "none"' "$SESSION_FILE")
    local agent=$(jq -r '.current.agent // "none"' "$SESSION_FILE")
    local status=$(jq -r '.current.status // "unknown"' "$SESSION_FILE")
    local branch=$(jq -r '.git.branch // "unknown"' "$SESSION_FILE")
    local commit=$(jq -r '.git.commit // "unknown"' "$SESSION_FILE")

    echo "  Timestamp: $timestamp"
    echo "  Age: $(format_session_age) ago"
    echo "  Branch: $branch"
    echo "  Commit: ${commit:0:8}"
    echo ""
    echo "  Current Work:"
    echo "    PRD: $prd"
    echo "    Story: $story"
    echo "    Step: $step"
    echo "    Agent: $agent"
    echo "    Status: $status"
    echo "=========================================="
    echo ""
}

# Clear session state
clear_session() {
    if [ -f "$SESSION_FILE" ]; then
        rm -f "$SESSION_FILE"
        log_success "Session state cleared"
    else
        log_warning "No session state to clear"
    fi
}

# ============================================================================
# Main Function
# ============================================================================

show_help() {
    cat << EOF
Maven Flow Session Save Hook

Usage: $(basename "$0") [OPTIONS]

Saves session state for auto-restore functionality.

Options:
    -h, --help              Show this help message
    --prd FILE              PRD JSON file path
    --story ID              Story ID (e.g., US-001)
    --step N                Current step number (1-10)
    --agent NAME            Current agent name
    --status STATUS         Current status (in_progress, complete, error)
    --show                  Show current session state
    --clear                 Clear session state
    --is-valid              Check if session is valid (exit code 0/1)

Examples:
    # Save session state
    $(basename "$0") --prd docs/prd-auth.json --story US-001 --step 1 --agent development-agent

    # Show current session
    $(basename "$0") --show

    # Check if session is valid
    $(basename "$0") --is-valid && echo "Session valid"

    # Clear session
    $(basename "$0") --clear

Session File: $SESSION_FILE
Timeout: $SESSION_TIMEOUT_HOURS hours

EOF
}

main() {
    local prd_file=""
    local story_id=""
    local step=""
    local agent=""
    local status="in_progress"
    local show_info=false
    local do_clear=false
    local check_valid=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --prd)
                prd_file="$2"
                shift 2
                ;;
            --story)
                story_id="$2"
                shift 2
                ;;
            --step)
                step="$2"
                shift 2
                ;;
            --agent)
                agent="$2"
                shift 2
                ;;
            --status)
                status="$2"
                shift 2
                ;;
            --show)
                show_info=true
                shift
                ;;
            --clear)
                do_clear=true
                shift
                ;;
            --is-valid)
                check_valid=true
                shift
                ;;
            *)
                log_warning "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Handle commands
    if [ "$show_info" = true ]; then
        show_session_info
        exit $?
    fi

    if [ "$do_clear" = true ]; then
        clear_session
        exit 0
    fi

    if [ "$check_valid" = true ]; then
        if is_session_valid; then
            log_info "Session is valid ($(format_session_age) old)"
            exit 0
        else
            log_warning "Session is invalid or expired"
            exit 1
        fi
    fi

    # Save session state (default action)
    save_session "$prd_file" "$story_id" "$step" "$agent" "$status"
    exit 0
}

main "$@"
