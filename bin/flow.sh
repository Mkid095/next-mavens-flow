#!/bin/bash
# ============================================================================
# Maven Flow - Linux Native Bash Implementation
# ============================================================================

set -e

# Default parameters
MAX_ITERATIONS=100
SLEEP_SECONDS=2

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        start)
            # Max iterations can be specified after "start"
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS=$2
                shift 2
            else
                shift
            fi
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
            # Reset session
            rm -f .flow-session
            echo "[OK] Session reset"
            exit 0
            ;;
        help|--help|-h)
            echo "Maven Flow - Autonomous Development Orchestrator"
            echo ""
            echo "Usage:"
            echo "  flow start [max-iterations]  - Start flow (default: 100 iterations)"
            echo "  flow status                  - Show current status"
            echo "  flow continue                - Continue from previous session"
            echo "  flow reset                   - Reset session state"
            echo "  flow help                    - Show this help"
            exit 0
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    rm -f "$SESSION_FILE"
}

trap cleanup EXIT

# Main flow
write_header "Maven Flow - Starting"

PROMPT='You are Maven Flow, an autonomous development agent.

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
'

# Main loop
for ((i=1; i<=MAX_ITERATIONS; i++)); do
    write_iteration_header "$i" "$MAX_ITERATIONS"

    echo -e "  ${GRAY}Starting Claude...${NC}"
    echo ""

    # Run claude and stream output in real-time
    claude --dangerously-skip-permissions -p "$PROMPT" 2>&1
    CLAUDE_EXIT_CODE=${?}

    # Check for completion using story stats
    stats=$(get_story_stats)
    IFS='|' read -r total completed remaining progress <<< "$stats"

    if [ $total -gt 0 ] && [ $completed -eq $total ]; then
        current_time=$(date +%s)
        duration=$((current_time - START_TIME))
        write_complete "$i" "$duration"
        exit 0
    fi

    # Pause between iterations
    if [ $i -lt $MAX_ITERATIONS ]; then
        echo ""
        echo -e "  ${GRAY}Pausing ${SLEEP_SECONDS}s...${NC}"
        sleep "$SLEEP_SECONDS"
        echo ""
    fi
done

write_max_reached "$MAX_ITERATIONS"
exit 0
