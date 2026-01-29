#!/bin/bash
# ============================================================================
# Maven Flow - Terminal Wrapper for Claude Code CLI
# ============================================================================
#
# This script is a SIMPLE WRAPPER that delegates to Claude Code commands.
# The actual Maven workflow (agent spawning, memory loading, etc.) is
# implemented in .claude/commands/flow.md which runs within Claude Code.
#
# ============================================================================

set -e

# Get script directory FIRST (needed by status command)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner
if [ -f "$SCRIPT_DIR/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/flow-banner.sh"
fi

# Default parameters
MAX_ITERATIONS=100
SLEEP_SECONDS=2

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        start)
            shift
            # Parse options after "start"
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --dry-run)
                        DRY_RUN=true
                        shift
                        ;;
                    [0-9]*)
                        MAX_ITERATIONS=$1
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            ;;
        status)
            # Show status only
            exec bash "$SCRIPT_DIR/flow-status.sh" "$@"
            ;;
        continue)
            # Continue from previous session
            CONTINUE=true
            shift
            ;;
        reset)
            # Reset session with safety checks
            echo ""
            echo "=========================================="
            echo "  Maven Flow - Session Reset"
            echo "=========================================="
            echo ""

            # Check for uncommitted changes
            if git status --porcelain | grep -q .; then
                echo -e "${RED}[!] WARNING: Uncommitted changes detected${NC}"
                echo ""
                git status --short
                echo ""
            fi

            # Check for incomplete stories
            if [ -d "docs" ]; then
                for prd in docs/prd-*.json; do
                    if [ -f "$prd" ]; then
                        local total=$(jq '.userStories | length' "$prd" 2>/dev/null || echo 0)
                        local completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo 0)
                        local remaining=$((total - completed))

                        if [ $remaining -gt 0 ]; then
                            echo -e "${YELLOW}[!] $prd has $remaining incomplete story(s)${NC}"
                            jq -r '.userStories[] | select(.passes == false) | "  - \(.id): \(.title)"' "$prd" 2>/dev/null || true
                        fi
                    fi
                done
                echo ""
            fi

            # Check if session file exists
            if [ ! -f ".flow-session" ]; then
                echo -e "${GRAY}[INFO] No active session found${NC}"
                echo ""
            else
                local session_id=$(cat .flow-session 2>/dev/null || echo "unknown")
                echo -e "${CYAN}[INFO] Active session: $session_id${NC}"
                echo ""
            fi

            # Interactive confirmation
            echo -e "${RED}This will:${NC}"
            echo "  - Delete the .flow-session file"
            echo "  - Clear all session progress"
            echo "  - Allow starting fresh from the first incomplete story"
            echo ""

            # Only require confirmation if there's uncommitted work or active session
            if git status --porcelain | grep -q . || [ -f ".flow-session" ]; then
                echo -n -e "${YELLOW}Continue with reset? [y/N]: ${NC}"
                read -r response
                echo ""

                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    echo -e "${GRAY}[CANCELLED] Reset aborted${NC}"
                    exit 0
                fi
            fi

            # Perform reset - clear locks if session exists
            if [ -f ".flow-session" ]; then
                local session_id=$(cat .flow-session 2>/dev/null || echo "")
                if [ -f ".claude/lib/lock.sh" ] && [ -n "$session_id" ]; then
                    source .claude/lib/lock.sh
                    clear_all_session_locks "$session_id"
                    echo -e "${GREEN}[OK] Cleared locks for session ${session_id:0:8}...${NC}"
                fi
            fi
            rm -f .flow-session
            echo -e "${GREEN}[OK] Session reset${NC}"
            echo ""
            exit 0
            ;;
        help|--help|-h)
            cat << 'HELP'

 __    __     ______     __   __   ______     __   __     ______        ______   __         ______     __     __
/\ "-./  \   /\  __ \   /\ \ / /  /\  ___\   /\ "-.\ \   /\  ___\      /\  ___\ /\ \       /\  __ \   /\ \  _ \ \
\ \ \-./\ \  \ \  __ \  \ \ \/   \ \  __\   \ \ \-.  \  \ \___  \     \ \  __\ \ \ \____  \ \ \/\ \  \ \ \/ ".\ \
 \ \_\ \ \_\  \ \_\ \_\  \ \__|    \ \_____\  \ \_\\"\_\  \/\_____\     \ \_\    \ \_____\  \_____\  \ \__/".~\_\
  \/_/  \/_/   \/_/\/_/   \/_/      \/_____/   \/_/ \/_/   \/_____/      \/_/     \/_____/   \/_____/   \/_/   \_/

Maven Flow - Autonomous AI Development System
═════════════════════════════════════════════════════════════════════════════════════════════

MAIN COMMANDS
  flow start [iterations]     Start autonomous development (default: 100 iterations)
  flow status                 Show project progress and story completion
  flow continue               Resume from previous session
  flow reset                  Reset session state and start fresh
  flow help, flow --help      Show this help screen

PRD WORKFLOW
  flow-prd [description]      Generate a new PRD from scratch or plan.md
  flow-convert [feature]      Convert markdown PRD to JSON format
                              Use --all to convert all PRDs
                              Use --force to reconvert existing JSON files

MAINTENANCE
  flow-update [description]   Update Maven Flow system from GitHub

OPTIONS
  --dry-run                   Show what would happen without making changes
  -h, --help, help            Show help screen

WORKFLOW
  1. Create PRD:    flow-prd "your feature description"
  2. Convert:       flow-convert feature-name
  3. Develop:       flow start

GETTING STARTED
  GitHub: https://github.com/Mkid095/next-mavens-flow

HELP
            exit 0
            ;;
        --dry-run)
            # Already handled above
            shift
            ;;
        *)
            # Try to parse as number (max iterations)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS=$1
            fi
            shift
            ;;
    esac
done

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'
NC='\033[0m'

# Spinner animation
SPINNER=('⠋' '⠙' '⠸' '⠴' '⠦' '⠇' '⠏')

# Function to show spinner while running a command
show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1

    # Save cursor position
    tput sc

    while kill -0 $pid 2>/dev/null; do
        for frame in "${SPINNER[@]}"; do
            # Restore cursor position and draw spinner only
            tput rc
            echo -ne "${CYAN}[${frame}]${NC}   "
            sleep $delay
            # Check if process still running
            kill -0 $pid 2>/dev/null || break
        done
    done

    # Clear spinner line
    tput rc
    echo -ne "                                                                 \r"
}

# Session setup
PROJECT_NAME="$(basename "$(pwd)")"
SESSION_ID="${PROJECT_NAME}-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
SESSION_FILE=".flow-session"
START_TIME=$(date +%s)

# Save session ID to file
echo "$SESSION_ID" > "$SESSION_FILE"

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR] Claude CLI not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}[ERROR] jq not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: sudo apt-get install jq${NC}"
    exit 1
fi

# Function to get story stats
get_story_stats() {
    local total=0
    local completed=0

    if [ -d "docs" ]; then
        for prd in docs/prd-*.json; do
            if [ -f "$prd" ]; then
                local count=$(jq '.userStories | length' "$prd" 2>/dev/null || echo 0)
                total=$((total + count))

                local complete=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo 0)
                completed=$((completed + complete))
            fi
        done
    fi

    local remaining=$((total - completed))
    local progress=0
    if [ $total -gt 0 ]; then
        progress=$(( (completed * 100) / total ))
    fi

    echo "$total|$completed|$remaining|$progress"
}

# Function to format duration
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $secs
}

# Function to write header
write_header() {
    local title="$1"
    local stats=$(get_story_stats)
    IFS='|' read -r total completed remaining progress <<< "$stats"

    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  $title${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "  Project: ${CYAN}${PROJECT_NAME}${NC}"
    echo -e "  Session: ${MAGENTA}${SESSION_ID}${NC}"
    echo -e "  Started: ${GRAY}$(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "  Stories: ${GREEN}${completed}/${total}${NC} ${GRAY}(${remaining} left) - ${progress}% complete${NC}"
    echo -e "  Max Iterations: ${GRAY}${MAX_ITERATIONS}${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
}

# Function to write iteration header
write_iteration_header() {
    local current=$1
    local total=$2
    local stats=$(get_story_stats)
    IFS='|' read -r prd_total prd_completed prd_remaining prd_progress <<< "$stats"

    local iter_percent=$(( (current * 100) / total ))

    echo ""
    echo -e "${YELLOW}==========================================${NC}"
    echo -e "${YELLOW}  Iteration $current of $total ($iter_percent%)${NC}"
    echo -e "  Session: ${MAGENTA}${SESSION_ID}${NC}"
    echo -e "  Stories: ${CYAN}${prd_completed}/${prd_total}${NC} ${GRAY}(${prd_remaining} left) - Project: ${prd_progress}%${NC}"
    echo -e "${YELLOW}==========================================${NC}"
    echo ""
}

# Function to write completion message
write_complete() {
    local iterations=$1
    local duration=$2
    local stats=$(get_story_stats)
    IFS='|' read -r total completed remaining progress <<< "$stats"

    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  [OK] ALL TASKS COMPLETE${NC}"
    echo -e "  Session: ${MAGENTA}${SESSION_ID}${NC}"
    echo -e "  Stories: ${WHITE}${total}/${total}${NC} - 100% complete"
    echo -e "  Iterations: ${WHITE}${iterations}${NC}"
    echo -e "  Duration: ${WHITE}$(format_duration $duration)${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
}

# Function to write max reached message
write_max_reached() {
    local max=$1
    local stats=$(get_story_stats)
    IFS='|' read -r total completed remaining progress <<< "$stats"

    echo ""
    echo -e "${YELLOW}==========================================${NC}"
    echo -e "${YELLOW}  [!] MAX ITERATIONS REACHED${NC}"
    echo -e "  Session: ${MAGENTA}${SESSION_ID}${NC}"
    echo -e "  Progress: ${CYAN}${progress}%${NC} ${GRAY}(${remaining} stories remaining)${NC}"
    echo -e "${GRAY}  Run 'flow continue' to resume${NC}"
    echo -e "${YELLOW}==========================================${NC}"
    echo ""
}

# Cleanup function
cleanup() {
    local session_id=$(cat "$SESSION_FILE" 2>/dev/null || echo "")

    if [ -n "$session_id" ]; then
        # Clean up all locks for this session
        if [ -f ".claude/lib/lock.sh" ]; then
            source .claude/lib/lock.sh
            # Remove all lock files owned by this session
            for lock_data in .flow-locks/*.data; do
                [ -f "$lock_data" ] || continue
                local owner=$(jq -r '.sessionId // empty' "$lock_data" 2>/dev/null)
                if [ "$owner" = "$session_id" ]; then
                    rm -f "${lock_data%.data}" "${lock_data}"
                fi
            done
        fi
    fi

    rm -f "$SESSION_FILE"
}

trap cleanup EXIT

# ============================================================================
# Dry-Run Preview Function
# ============================================================================
dry_run_preview() {
    echo ""
    echo "=========================================="
    echo "  Maven Flow - Dry Run Preview"
    echo "=========================================="
    echo ""
    echo "This is a PREVIEW of what would happen."
    echo "No changes will be made."
    echo ""

    # Check for PRD files
    if [ ! -d "docs" ]; then
        echo -e "${RED}[ERROR] No docs/ directory found${NC}"
        echo "  Create a PRD first using the flow-prd skill."
        exit 1
    fi

    local prd_files=($(find docs -name "prd-*.json" -type f 2>/dev/null))
    if [ ${#prd_files[@]} -eq 0 ]; then
        echo -e "${RED}[ERROR] No PRD files found in docs/${NC}"
        echo "  Create a PRD first using the flow-prd skill."
        exit 1
    fi

    echo -e "${CYAN}PRD Files Found:${NC}"
    for prd in "${prd_files[@]}"; do
        local feature=$(basename "$prd" | sed 's/^prd-//' | sed 's/\.json$//')
        local total=$(jq '.userStories | length' "$prd" 2>/dev/null || echo 0)
        local completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo 0)
        local remaining=$((total - completed))
        echo "  - $feature"
        echo "    File: $prd"
        echo "    Stories: $completed/$total complete ($remaining remaining)"
    done
    echo ""

    # Get first incomplete story across all PRDs
    local first_prd=""
    local first_story_id=""
    local first_story_title=""
    local first_maven_steps=()
    local first_mcp_tools="{}"

    for prd in "${prd_files[@]}"; do
        local story=$(jq -r '.userStories[] | select(.passes == false) | "\(.id)|\(.title)"' "$prd" 2>/dev/null | head -1)
        if [ -n "$story" ]; then
            first_prd="$prd"
            IFS='|' read -r first_story_id first_story_title <<< "$story"
            first_maven_steps=($(jq -r ".userStories[] | select(.id == \"$first_story_id\") | .mavenSteps[]" "$prd" 2>/dev/null || echo ""))
            first_mcp_tools=$(jq -r ".userStories[] | select(.id == \"$first_story_id\") | .mcpTools" "$prd" 2>/dev/null || echo "{}")
            break
        fi
    done

    if [ -z "$first_story_id" ]; then
        echo -e "${GREEN}[OK] All stories are complete!${NC}"
        echo ""
        echo "No work to do. All stories in all PRDs are marked as complete."
        exit 0
    fi

    echo -e "${CYAN}Next Story to Process:${NC}"
    echo "  PRD: $first_prd"
    echo "  Story ID: $first_story_id"
    echo "  Title: $first_story_title"
    echo "  Maven Steps: ${first_maven_steps[*]:-none}"
    echo "  MCP Tools:"
    echo "$first_mcp_tools" | jq -r 'to_entries | map("    \(.key): \(.value | join(", "))") | .[]' 2>/dev/null || echo "    (none)"
    echo ""

    # Determine agent for first step
    local first_step="${first_maven_steps[0]}"
    local agent=""
    case $first_step in
        1|2|7|9) agent="development-agent" ;;
        3|4|6) agent="refactor-agent" ;;
        5) agent="quality-agent" ;;
        8|10) agent="security-agent" ;;
        11) agent="design-agent" ;;
        *) agent="development-agent" ;;
    esac

    echo -e "${CYAN}Execution Plan:${NC}"
    echo "  Max Iterations: $MAX_ITERATIONS"
    echo "  First Agent: $agent"
    echo "  Estimated Steps per Story: ${#first_maven_steps[@]}"
    echo "  Pause Between Iterations: ${SLEEP_SECONDS}s"
    echo ""

    # Show what files would be modified
    echo -e "${CYAN}Files That Would Be Modified:${NC}"
    echo "  - $first_prd (story marked as complete)"
    echo "  - Source files in src/ (implementation)"
    echo "  - Git history (commits)"
    echo ""

    echo "=========================================="
    echo -e "${YELLOW}To execute, run: flow start${NC}"
    echo "=========================================="
    echo ""
}

# Check if dry-run mode
if [ "$DRY_RUN" = true ]; then
    dry_run_preview
    exit 0
fi

# MAIN ENTRY POINT
# ============================================================================
#
# This script is a SIMPLE WRAPPER that delegates to Claude Code.
# All the actual Maven workflow logic (agent spawning, memory loading,
# PRD processing, etc.) is implemented in .claude/commands/flow.md which
# runs within Claude Code where agent spawning actually works.
#
# ============================================================================

# Determine which command to run
if [ "$CONTINUE" = true ]; then
    # Continue command - delegate to /flow continue
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Maven Flow - Continuing Development             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check if docs directory exists
    if [ ! -d "docs" ]; then
        echo -e "${RED}[ERROR] No docs/ directory found${NC}"
        echo ""
        exit 1
    fi

    FLOW_PROMPT="/flow continue"
    if [ "$MAX_ITERATIONS" -ne 100 ]; then
        FLOW_PROMPT="$FLOW_PROMPT $MAX_ITERATIONS"
    fi

    echo -e "${BLUE}▶ Continuing from previous session...${NC}"
    echo -e "${GRAY}  Command: ${YELLOW}$FLOW_PROMPT${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    claude --dangerously-skip-permissions "$FLOW_PROMPT"
    exit $?
fi

# If we reach this point, it means the user ran "flow start" (default command)

# Show ASCII banner
show_flow_banner

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Maven Flow - Starting Autonomous Development      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo -e "${RED}[ERROR] No docs/ directory found${NC}"
    echo ""
    echo -e "${YELLOW}To get started:${NC}"
    echo "  1. Create a PRD using: flow-prd create \"your feature description\""
    echo "  2. Convert to JSON: flow-convert <feature-name>"
    echo "  3. Start development: flow start"
    echo ""
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}[ERROR] jq not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: sudo apt-get install jq${NC}"
    exit 1
fi

echo -e "${BLUE}▶ Maven Flow will work in iterations${NC}"
echo -e "${GRAY}  Each iteration processes ONE incomplete story${NC}"
echo -e "${GRAY}  Max iterations: ${YELLOW}$MAX_ITERATIONS${NC}"
echo ""

# Scan PRDs to show initial activity
echo -ne "${CYAN}▶ Scanning PRDs for stories...${NC}"
(
    # Simple spinner
    for i in {1..2}; do
        for frame in "${SPINNER[@]}"; do
            sleep 0.15
        done
    done
)
echo -e "\r${GREEN}✓ Ready${NC}                                        "
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

STORIES_COMPLETED=0

# ============================================================================
# Source lock library and start heartbeat loop
# ============================================================================
# Source lock library (defines FLOW_HEARTBEAT_INTERVAL constant and functions)
if [ -f ".claude/lib/lock.sh" ]; then
    source .claude/lib/lock.sh
else
    echo -e "${RED}[ERROR] Lock library not found at .claude/lib/lock.sh${NC}"
    exit 1
fi

# Set heartbeat interval if not defined
FLOW_HEARTBEAT_INTERVAL=${FLOW_HEARTBEAT_INTERVAL:-60}

# Start heartbeat loop (mandatory - background)
(
    while true; do
        sleep "$FLOW_HEARTBEAT_INTERVAL"
        update_session_heartbeats "$SESSION_ID"
    done
) &
heartbeat_pid=$!
echo $heartbeat_pid > .flow-heartbeat-pid

# Cleanup heartbeat on exit (in addition to session cleanup)
heartbeat_cleanup() {
    local heartbeat_pid_file=".flow-heartbeat-pid"
    if [ -f "$heartbeat_pid_file" ]; then
        local hp=$(cat "$heartbeat_pid_file" 2>/dev/null || echo "")
        [ -n "$hp" ] && kill $hp 2>/dev/null || true
        rm -f "$heartbeat_pid_file"
    fi
}
trap heartbeat_cleanup EXIT

# ============================================================================
# MAIN ITERATION LOOP
# ============================================================================
for ((iteration=1; iteration<=$MAX_ITERATIONS; iteration++)); do
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  Iteration $iteration of $MAX_ITERATIONS${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Calculate story stats
    TOTAL_STORIES=0
    COMPLETED_STORIES=0
    for prd in docs/prd-*.json; do
        if [ -f "$prd" ]; then
            total=$(jq '.userStories | length' "$prd" 2>/dev/null || echo "0")
            completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo "0")
            TOTAL_STORIES=$((TOTAL_STORIES + total))
            COMPLETED_STORIES=$((COMPLETED_STORIES + completed))
        fi
    done

    REMAINING=$((TOTAL_STORIES - COMPLETED_STORIES))
    if [ $TOTAL_STORIES -gt 0 ]; then
        # Use awk for decimal percentage calculation
        PROGRESS=$(awk "BEGIN {printf \"%.1f\", ($COMPLETED_STORIES * 100.0) / $TOTAL_STORIES}")
    else
        PROGRESS="0.0"
    fi

    # Show progress with proper alignment
    PROGRESS_BAR=$(printf "│  Progress: ${GREEN}%3d${NC}/${CYAN}%-3d stories    ${YELLOW}%6s${NC}    ${GRAY}(%3d remaining)${NC} │" "$COMPLETED_STORIES" "$TOTAL_STORIES" "$PROGRESS%" "$REMAINING")
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}$PROGRESS_BAR${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Find and lock next story using filesystem lock
    PRD_FILE=""
    STORY_ID=""
    STORY_TITLE=""

    if ! result=$(find_and_lock_story "$SESSION_ID"); then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           🎉 ALL STORIES COMPLETE! 🎉                     ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GRAY}Completed $STORIES_COMPLETED stories in $((iteration - 1)) iterations${NC}"
        echo ""

        # Trigger consolidation if all stories complete
        echo -e "${CYAN}▶ Consolidating memory from all completed stories...${NC}"
        claude --dangerously-skip-permissions "/consolidate-memory" 2>/dev/null || true

        exit 0
    fi

    # Parse result from find_and_lock_story
    # Get the last line (contains "prd_file|story_id") - first line is session ID
    result=$(echo "$result" | tail -1)
    PRD_FILE=$(echo "$result" | cut -d'|' -f1)
    STORY_ID=$(echo "$result" | cut -d'|' -f2)

    # Get story title from PRD
    STORY_TITLE=$(jq -r ".userStories[] | select(.id==\"$STORY_ID\") | .title" "$PRD_FILE" 2>/dev/null || echo "Unknown")

    # Extract feature name from PRD file
    FEATURE=$(basename "$PRD_FILE" .json | sed 's/prd-//')

    echo -e "${BLUE}▶ Working on: ${YELLOW}$STORY_ID${NC} ${BLUE}-${NC} ${WHITE}$STORY_TITLE${NC}"
    echo -e "${GRAY}  PRD: $PRD_FILE${NC}"
    echo ""

    # Build prompt for this iteration
    ITERATION_PROMPT="/flow-work-story $PRD_FILE $STORY_ID"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Call Claude Code to work on this story with spinner
    echo -e "${BLUE}▶ Processing: ${YELLOW}$STORY_ID${NC} - ${WHITE}$STORY_TITLE${NC}"
    echo ""

    # Run Claude Code in background and show spinner
    # Pass SESSION_ID as environment variable
    SESSION_ID="$SESSION_ID" claude --dangerously-skip-permissions "$ITERATION_PROMPT" > /tmp/flow_output.txt 2>&1 &
    CLAUDE_PID=$!
    show_spinner $CLAUDE_PID "Working on $STORY_ID" &
    SPINNER_PID=$!

    # Wait for Claude Code to finish
    wait $CLAUDE_PID 2>/dev/null
    exit_code=$?

    # Kill spinner if still running
    kill $SPINNER_PID 2>/dev/null || true

    # Display output
    result=$(cat /tmp/flow_output.txt)
    rm -f /tmp/flow_output.txt

    echo "$result"
    echo ""

    # Check if story was marked complete
    is_complete=$(jq -r ".userStories[] | select(.id == \"$STORY_ID\") | .passes" "$PRD_FILE" 2>/dev/null)

    if [ "$is_complete" = "true" ]; then
        STORIES_COMPLETED=$((STORIES_COMPLETED + 1))
        echo -e "${GREEN}[✓] Story $STORY_ID completed!${NC}"
        # Unlock this story (story-scoped, not session-scoped)
        unlock_story "$PRD_FILE" "$STORY_ID" "$SESSION_ID"
        echo ""
    else
        echo -e "${YELLOW}[!] Story $STORY_ID not complete, will retry in next iteration${NC}"
        # Keep lock for retry - story remains locked to this session
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Check if we should continue (all stories complete)
    all_complete=true
    for prd in docs/prd-*.json; do
        if [ -f "$prd" ]; then
            incomplete=$(jq '[.userStories[] | select(.passes != true)] | length' "$prd" 2>/dev/null || echo "0")
            if [ "$incomplete" -gt 0 ]; then
                all_complete=false
                break
            fi
        fi
    done

    if [ "$all_complete" = true ]; then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           🎉 ALL STORIES COMPLETE! 🎉                     ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GRAY}Completed $STORIES_COMPLETED stories in $iteration iterations${NC}"
        echo ""

        # Trigger consolidation
        echo -e "${CYAN}▶ Consolidating memory from all completed stories...${NC}"
        claude --dangerously-skip-permissions "/consolidate-memory" 2>/dev/null || true

        exit 0
    fi

    # Small pause between iterations
    if [ $iteration -lt $MAX_ITERATIONS ]; then
        echo -e "${GRAY}Pausing ${SLEEP_SECONDS}s before next iteration...${NC}"
        sleep "$SLEEP_SECONDS"
    fi
done

# Max iterations reached
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     Reached max iterations ($MAX_ITERATIONS)                 ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}Stories completed: $STORIES_COMPLETED${NC}"
echo -e "${GRAY}Run 'flow start' again to continue${NC}"
echo ""

exit 1
