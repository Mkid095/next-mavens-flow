#!/bin/bash
# ============================================================================
# Maven Flow Session Restore Hook
#
# Restores session state if within timeout period.
# Auto-loads PRD context, story, and step information.
#
# Usage: Called automatically by flow command or manually
#   ./session-restore.sh [--force] [--format json|text|export]
#
# Session file: .claude/.session-state.json
# Timeout: 24 hours (configurable via SESSION_TIMEOUT_HOURS)
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
CYAN='\033[0;36m'
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================================================
# Session Validation Functions
# ============================================================================

# Check if session file exists
session_exists() {
    [ -f "$SESSION_FILE" ]
}

# Check if session is within timeout
is_session_valid() {
    if ! session_exists; then
        return 1
    fi

    local session_ms=$(jq -r '.timestamp_ms // 0' "$SESSION_FILE" 2>/dev/null || echo "0")
    local current_ms=$(date +%s%3N)
    local timeout_ms=$((SESSION_TIMEOUT_HOURS * 60 * 60 * 1000))

    [ $((current_ms - session_ms)) -lt $timeout_ms ]
}

# Get session age in milliseconds
get_session_age_ms() {
    if ! session_exists; then
        echo "0"
        return
    fi

    local session_ms=$(jq -r '.timestamp_ms // 0' "$SESSION_FILE" 2>/dev/null || echo "0")
    local current_ms=$(date +%s%3N)
    echo $((current_ms - session_ms))
}

# Format session age in human-readable format
format_session_age() {
    local diff_ms=$(get_session_age_ms)
    local diff_seconds=$((diff_ms / 1000))

    local hours=$((diff_seconds / 3600))
    local minutes=$(((diff_seconds % 3600) / 60))
    local seconds=$((diff_seconds % 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# ============================================================================
# Session Data Extraction Functions
# ============================================================================

# Get session field value
get_session_field() {
    local field="$1"
    if session_exists; then
        jq -r "$field // \"\"" "$SESSION_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Get current PRD file
get_prd() {
    get_session_field '.current.prd'
}

# Get current story ID
get_story() {
    get_session_field '.current.story'
}

# Get current step
get_step() {
    get_session_field '.current.step'
}

# Get current agent
get_agent() {
    get_session_field '.current.agent'
}

# Get current status
get_status() {
    get_session_field '.current.status'
}

# Get git branch
get_branch() {
    get_session_field '.git.branch'
}

# Get git commit
get_commit() {
    get_session_field '.git.commit'
}

# Get timestamp
get_timestamp() {
    get_session_field '.timestamp'
}

# ============================================================================
# Session Restoration Functions
# ============================================================================

# Check if git state has changed
has_git_changed() {
    if ! session_exists; then
        return 0  # No session to compare
    fi

    local session_branch=$(get_branch)
    local session_commit=$(get_commit)
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    if [ "$session_branch" != "$current_branch" ]; then
        return 0  # Branch changed
    fi

    if [ "$session_commit" != "$current_commit" ]; then
        return 0  # Commit changed
    fi

    return 1  # No change
}

# Restore session and print summary
restore_session() {
    local format="${1:-text}"
    local force="${2:-false}"

    # Check if session exists
    if ! session_exists; then
        if [ "$format" = "json" ]; then
            echo '{"restored":false,"reason":"no_session"}'
        elif [ "$format" = "export" ]; then
            echo "# No session to restore"
            echo "export SESSION_RESTORED=false"
        else
            log_warning "No previous session found"
        fi
        return 1
    fi

    # Check if session is valid (within timeout)
    if ! is_session_valid && [ "$force" != "true" ]; then
        if [ "$format" = "json" ]; then
            echo "{\"restored\":false,\"reason\":\"expired\",\"age\":\"$(format_session_age)\"}"
        elif [ "$format" = "export" ]; then
            echo "# Session expired ($(format_session_age) old)"
            echo "export SESSION_RESTORED=false"
        else
            log_warning "Session expired ($(format_session_age) old)"
            log_info "Use --force to restore anyway"
        fi
        return 1
    fi

    # Check if git state has changed
    if has_git_changed; then
        if [ "$format" = "json" ]; then
            echo '{"restored":false,"reason":"git_changed"}'
        elif [ "$format" = "export" ]; then
            echo "# Git state has changed since last session"
            echo "export SESSION_RESTORED=false"
        else
            log_warning "Git state has changed since last session"
            log_info "Previous branch: $(get_branch), current: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
        fi
        return 1
    fi

    # Extract session data
    local prd=$(get_prd)
    local story=$(get_story)
    local step=$(get_step)
    local agent=$(get_agent)
    local status=$(get_status)
    local timestamp=$(get_timestamp)

    # Output based on format
    case "$format" in
        json)
            cat << EOF
{
  "restored": true,
  "prd": "$prd",
  "story": "$story",
  "step": $step,
  "agent": "$agent",
  "status": "$status",
  "timestamp": "$timestamp",
  "age": "$(format_session_age)"
}
EOF
            ;;
        export)
            cat << EOF
# Session restored from $timestamp ($(format_session_age) ago)
export SESSION_RESTORED=true
export SESSION_PRD="$prd"
export SESSION_STORY="$story"
export SESSION_STEP=$step
export SESSION_AGENT="$agent"
export SESSION_STATUS="$status"
EOF
            ;;
        *)
            echo ""
            echo "=========================================="
            echo "  Session Restored"
            echo "=========================================="
            echo "  Age: $(format_session_age) ago"
            echo "  Timestamp: $timestamp"
            echo ""
            echo "  Current Work:"
            if [ -n "$prd" ]; then
                echo "    PRD: $prd"
            fi
            if [ -n "$story" ]; then
                echo "    Story: $story"
            fi
            if [ -n "$step" ] && [ "$step" != "null" ]; then
                echo "    Step: $step"
            fi
            if [ -n "$agent" ]; then
                echo "    Agent: $agent"
            fi
            if [ -n "$status" ]; then
                echo "    Status: $status"
            fi
            echo "=========================================="
            echo ""
            ;;
    esac

    return 0
}

# Show detailed session info
show_session_info() {
    if ! session_exists; then
        log_warning "No session state found"
        return 1
    fi

    echo ""
    echo "=========================================="
    echo "  Session State Details"
    echo "=========================================="

    local valid="No"
    local age=$(format_session_age)
    if is_session_valid; then
        valid="Yes"
    fi

    echo "  Valid: $valid"
    echo "  Age: $age"
    echo ""

    # Git info
    echo "  Git State:"
    echo "    Branch: $(get_branch)"
    echo "    Commit: $(get_commit | head -c 12)"
    echo ""

    # Current work
    local prd=$(get_prd)
    local story=$(get_story)
    local step=$(get_step)
    local agent=$(get_agent)
    local status=$(get_status)

    echo "  Current Work:"
    [ -n "$prd" ] && echo "    PRD: $prd"
    [ -n "$story" ] && echo "    Story: $story"
    [ -n "$step" ] && [ "$step" != "null" ] && echo "    Step: $step"
    [ -n "$agent" ] && echo "    Agent: $agent"
    [ -n "$status" ] && echo "    Status: $status"

    echo ""
    echo "=========================================="
    echo ""
}

# ============================================================================
# Main Function
# ============================================================================

show_help() {
    cat << EOF
Maven Flow Session Restore Hook

Usage: $(basename "$0") [OPTIONS]

Restores session state if within timeout period (24 hours).

Options:
    -h, --help              Show this help message
    -f, --force             Restore even if expired
    --format FORMAT         Output format: json, text, export (default: text)
    --show                  Show detailed session info
    --check                 Check if session is valid (exit code)
    --age                   Show session age only

Output Formats:
    text    Human-readable summary (default)
    json    JSON output for scripting
    export  Shell export format for sourcing

Exit Codes:
    0       Session restored or valid
    1       No session, expired, or error

Examples:
    # Restore session (if valid)
    $(basename "$0}")

    # Force restore even if expired
    $(basename "$0") --force

    # Get session info as JSON
    $(basename "$0") --format json

    # Export session variables
    eval "\$( $(basename "$0") --format export )"

    # Check if session is valid
    $(basename "$0") --check && echo "Valid session"

    # Show detailed info
    $(basename "$0") --show

    # Show session age only
    $(basename "$0") --age

Session File: $SESSION_FILE
Timeout: $SESSION_TIMEOUT_HOURS hours

EOF
}

main() {
    local format="text"
    local force=false
    local show_info=false
    local check_valid=false
    local show_age=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --show)
                show_info=true
                shift
                ;;
            --check)
                check_valid=true
                shift
                ;;
            --age)
                show_age=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Handle special commands
    if [ "$show_info" = true ]; then
        show_session_info
        exit $?
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

    if [ "$show_age" = true ]; then
        if session_exists; then
            echo "$(format_session_age)"
            exit 0
        else
            echo "no session"
            exit 1
        fi
    fi

    # Restore session
    restore_session "$format" "$force"
    exit $?
}

main "$@"
