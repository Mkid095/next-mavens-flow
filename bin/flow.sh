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

            # Perform reset
            rm -f .flow-session
            echo -e "${GREEN}[OK] Session reset${NC}"
            echo ""
            exit 0
            ;;
        help|--help|-h)
            echo "Maven Flow - Autonomous Development Orchestrator"
            echo ""
            echo "Usage:"
            echo "  flow start [--dry-run] [max-iterations]  - Start flow (default: 100 iterations)"
            echo "  flow status                                  - Show current status"
            echo "  flow continue                                - Continue from previous session"
            echo "  flow reset                                   - Reset session state"
            echo "  flow help                                    - Show this help"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would happen without making changes"
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
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

STORIES_COMPLETED=0

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
        PROGRESS=$(( (COMPLETED_STORIES * 100) / TOTAL_STORIES ))
    else
        PROGRESS=0
    fi

    # Show progress
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  Progress: ${GREEN}$COMPLETED_STORIES${NC}/${CYAN}$TOTAL_STORIES stories${NC}    ${YELLOW}$PROGRESS%%${NC}    ${GRAY}($REMAINING remaining)${NC}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # Find first incomplete story across all PRDs
    STORY_INFO=""
    PRD_FILE=""
    STORY_ID=""
    STORY_TITLE=""

    for prd in docs/prd-*.json; do
        if [ -f "$prd" ]; then
            story=$(jq -r '.userStories[] | select(.passes == false) | "\(.id)|\(.title)"' "$prd" 2>/dev/null | head -1)
            if [ -n "$story" ]; then
                STORY_INFO="$story"
                PRD_FILE="$prd"
                IFS='|' read -r STORY_ID STORY_TITLE <<< "$story"
                break
            fi
        fi
    done

    # Check if all stories are complete
    if [ -z "$STORY_INFO" ]; then
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

    # Extract feature name from PRD file
    FEATURE=$(basename "$PRD_FILE" .json | sed 's/prd-//')

    echo -e "${BLUE}▶ Working on: ${YELLOW}$STORY_ID${NC} ${BLUE}-${NC} ${WHITE}$STORY_TITLE${NC}"
    echo -e "${GRAY}  PRD: $PRD_FILE${NC}"
    echo ""

    # Build prompt for this iteration
    ITERATION_PROMPT="/flow-work-story $PRD_FILE $STORY_ID"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Call Claude Code to work on this story
    result=$(claude --dangerously-skip-permissions "$ITERATION_PROMPT" 2>&1)
    exit_code=$?

    echo "$result"
    echo ""

    # Check if story was marked complete
    is_complete=$(jq -r ".userStories[] | select(.id == \"$STORY_ID\") | .passes" "$PRD_FILE" 2>/dev/null)

    if [ "$is_complete" = "true" ]; then
        STORIES_COMPLETED=$((STORIES_COMPLETED + 1))
        echo -e "${GREEN}[✓] Story $STORY_ID completed!${NC}"
        echo ""
    else
        echo -e "${YELLOW}[!] Story $STORY_ID not complete, will retry in next iteration${NC}"
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
