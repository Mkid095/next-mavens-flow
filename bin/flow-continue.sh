#!/bin/bash
# ============================================================================
# Maven Flow - Continue from Previous Session
# ============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner from .claude/bin
if [ -f "$SCRIPT_DIR/../.claude/bin/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/../.claude/bin/flow-banner.sh"
    show_flow_banner
fi

# Default parameters
MAX_ITERATIONS=100
SLEEP_SECONDS=2

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        [0-9]*)
            MAX_ITERATIONS=$1
            shift
            ;;
        *)
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
NC='\033[0m'

# Check if session exists
if [ ! -f ".flow-session" ]; then
    echo -e "${YELLOW}[!] No active session found${NC}"
    echo -e "${GRAY}Run 'flow start' to begin a new session${NC}"
    echo ""
    exit 1
fi

PROJECT_NAME=$(basename "$(pwd)")
START_TIME=$(date +%s)
SESSION_ID=$(cat .flow-session 2>/dev/null || echo "$PROJECT_NAME-continue")

# Check if claude is available
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR] Claude CLI not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

# Story stats function
get_story_stats() {
    local completed=0
    local total=0

    for prd in docs/prd-*.json; do
        if [ -f "$prd" ]; then
            local count=$(jq '.userStories | length' "$prd" 2>/dev/null || echo 0)
            total=$((total + count))
            local complete=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo 0)
            completed=$((completed + complete))
        fi
    done

    local remaining=$((total - completed))
    local progress=0
    if [ $total -gt 0 ]; then
        progress=$(( (completed * 100) / total ))
    fi

    echo "$total $completed $remaining $progress"
}

# Write header
write_header() {
    local stats=($(get_story_stats))
    local total=${stats[0]}
    local completed=${stats[1]}
    local remaining=${stats[2]}
    local progress=${stats[3]}

    echo ""
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${CYAN}  Maven Flow - Continuing${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo -e "  Project: ${CYAN}$PROJECT_NAME${NC}"
    echo -e "  Session: ${MAGENTA}$SESSION_ID${NC}"
    echo -e "  Resumed: ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "  Stories: ${GREEN}$completed/$total${NC} ($remaining left) - ${progress}% complete"
    echo -e "  Max Iterations: ${GRAY}$MAX_ITERATIONS${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo ""
}

# Write iteration header
write_iteration_header() {
    local current=$1
    local total=$2
    local stats=($(get_story_stats))
    local total_stories=${stats[0]}
    local completed=${stats[1]}
    local remaining=${stats[2]}
    local project_progress=${stats[3]}
    local iter_percent=$(( (current * 100) / total ))

    echo ""
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}  Iteration $current of $total ($iter_percent%)${NC}"
    echo -e "${YELLOW}  Session: ${MAGENTA}$SESSION_ID${NC}"
    echo -e "${YELLOW}  Stories: ${CYAN}$completed/$total_stories${NC} ($remaining left) - Project: ${project_progress}%"
    echo -e "${YELLOW}===========================================${NC}"
    echo ""
}

# Write complete message
write_complete() {
    local iterations=$1
    local duration=$2
    local stats=($(get_story_stats))

    echo ""
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}  [OK] ALL TASKS COMPLETE${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo -e "  Session: ${MAGENTA}$SESSION_ID${NC}"
    echo -e "  Stories: ${stats[0]}/${stats[0]} - 100% complete"
    echo -e "  Iterations: $iterations"
    echo -e "  Duration: $duration"
    echo -e "${GREEN}===========================================${NC}"
    echo ""
}

# Write max reached message
write_max_reached() {
    local max=$1
    local stats=($(get_story_stats))

    echo ""
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}  [!] MAX ITERATIONS REACHED${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "  Session: ${MAGENTA}$SESSION_ID${NC}"
    echo -e "  Progress: ${stats[3]}% (${stats[2]} stories remaining)"
    echo -e "  Run 'flow continue' to resume"
    echo -e "${YELLOW}===========================================${NC}"
    echo ""
}

# Format duration
format_duration() {
    local seconds=$1
    if [ $seconds -ge 3600 ]; then
        echo "$((seconds / 3600))h $(( (seconds % 3600) / 60 ))m"
    elif [ $seconds -ge 60 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "${seconds}s"
    fi
}

# Remove session file
remove_session_file() {
    if [ -f ".flow-session" ]; then
        rm -f .flow-session
    fi
}

write_header

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
for ((iteration=1; iteration<=$MAX_ITERATIONS; iteration++)); do
    write_iteration_header $iteration $MAX_ITERATIONS

    echo -e "${GRAY}  Starting Claude...${NC}"
    echo ""

    # Run claude
    if claude --dangerously-skip-permissions "$PROMPT" 2>&1; then
        :
    fi

    # Check for completion
    stats=($(get_story_stats))
    total=${stats[0]}
    completed=${stats[1]}

    if [ $completed -eq $total ] && [ $total -gt 0 ]; then
        end_time=$(date +%s)
        duration=$((end_time - START_TIME))
        duration_str=$(format_duration $duration)
        write_complete $iteration "$duration_str"
        remove_session_file
        exit 0
    fi

    if [ $iteration -lt $MAX_ITERATIONS ]; then
        echo ""
        echo -e "${GRAY}  Pausing ${SLEEP_SECONDS}s...${NC}"
        sleep $SLEEP_SECONDS
        echo ""
    fi
done

write_max_reached $MAX_ITERATIONS
remove_session_file
exit 0
