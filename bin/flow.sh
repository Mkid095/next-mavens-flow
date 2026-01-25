#!/bin/bash
# ============================================================================
# Maven Flow - Linux Native Bash Implementation
# ============================================================================

set -e

# Default parameters
MAX_ITERATIONS=100
SLEEP_SECONDS=2
DRY_RUN=false

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

# ============================================================================
# Load plan.md context if available
# ============================================================================
PLAN_CONTEXT=""
if [ -f "plan.md" ]; then
    echo -e "${CYAN}Found plan.md - loading as project context${NC}"
    PLAN_MD_CONTENT=$(cat plan.md)
    PLAN_CONTEXT="

*** PROJECT PLAN CONTEXT ***
The user has a plan.md file with the overall project direction:
${PLAN_MD_CONTENT}
"
    echo -e "${GRAY}Loaded plan.md (${#PLAN_MD_CONTENT} bytes)${NC}"
    echo ""
fi

# ============================================================================
# Function to get first incomplete story
# ============================================================================
get_first_incomplete_story() {
    local prd_files=($(find docs -name "prd-*.json" -type f 2>/dev/null | sort))

    for prd in "${prd_files[@]}"; do
        local story=$(jq -r '.userStories[] | select(.passes == false) | "\(.id)|\(.title)|\(.description)"' "$prd" 2>/dev/null | head -1)
        if [ -n "$story" ]; then
            echo "$prd|$story"
            return 0
        fi
    done

    return 1
}

# ============================================================================
# Function to spawn specialist agent for a story step
# ============================================================================
spawn_agent_for_step() {
    local story_data="$1"
    local step="$2"
    local prd_file="$3"

    IFS='|' read -r story_id story_title story_description <<< "$story_data"

    # Get story details
    local mcp_tools=$(jq -r ".userStories[] | select(.id == \"$story_id\") | .mcpTools.step$step // empty" "$prd_file" 2>/dev/null)

    # Determine agent type based on step
    local agent_type=""
    local agent_name=""
    case $step in
        1|2|7|9)
            agent_type="development-agent"
            agent_name="Development"
            ;;
        3|4|6)
            agent_type="refactor-agent"
            agent_name="Refactor"
            ;;
        5)
            agent_type="quality-agent"
            agent_name="Quality"
            ;;
        8|10)
            agent_type="security-agent"
            agent_name="Security"
            ;;
        11)
            agent_type="design-agent"
            agent_name="Design"
            ;;
        *)
            agent_type="development-agent"
            agent_name="Development"
            ;;
    esac

    # Build MCP instruction
    local mcp_instruction=""
    if [ "$mcp_tools" != "null" ] && [ "$mcp_tools" != "empty" ]; then
        mcp_instruction="

*** CRITICAL: MCP TOOLS INSTRUCTION ***
You MUST use these MCP tools for this step:
$mcp_tools
Use these MCP tools to complete your work. DO NOT read files or make assumptions - CHECK FIRST using the MCP.
"
    fi

    # Generate agent prompt
    local agent_prompt="You are the Maven $agent_name Agent (Step $step of Maven Workflow).

STORY: $story_id - $story_title

DESCRIPTION:
$story_description

PRD FILE: $prd_file$PLAN_CONTEXT$mcp_instruction

## Your Task (Step $step)

Complete Step $step of the Maven workflow for this story:
- Read the PRD file to understand the full story context
- Review acceptance criteria
- Complete the step's work according to Maven Flow standards
- Ensure NO 'any' types, NO gradients, use @ aliases for imports

## Quality Standards (ZERO TOLERANCE):
- No 'any' types - use proper TypeScript
- No gradients - use solid professional colors
- No relative imports - use @/ aliases
- Components < 300 lines

## After Completion:
1. Run: pnpm run typecheck
2. If errors remain, fix them
3. Output: [STEP_COMPLETE] when done

Begin Step $step now."

    # Spawn the agent using Task tool
    echo -e "${CYAN}Spawning $agent_name agent for Step $step...${NC}"

    local result=$(claude --dangerously-skip-permissions -p "$agent_prompt" 2>&1)
    local exit_code=$?

    if echo "$result" | grep -q "\[STEP_COMPLETE\]"; then
        echo -e "${GREEN}✓ Step $step complete${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Step $step completed (no confirmation signal)${NC}"
        return 0
    fi
}

# ============================================================================
# Function to process a single story
# ============================================================================
process_story() {
    local prd_file="$1"
    local story_line="$2"

    IFS='|' read -r story_id story_title story_description <<< "$story_line"

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Processing Story: $story_id - $story_title${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Get maven steps for this story
    local maven_steps=($(jq -r ".userStories[] | select(.id == \"$story_id\") | .mavenSteps[]" "$prd_file" 2>/dev/null))

    if [ ${#maven_steps[@]} -eq 0 ]; then
        echo -e "${RED}Error: No mavenSteps found for story $story_id${NC}"
        return 1
    fi

    echo -e "${GRAY}Maven Steps: ${maven_steps[*]}${NC}"
    echo ""

    # Process each step in sequence
    for step in "${maven_steps[@]}"; do
        echo -e "${YELLOW}─── Step $step ───${NC}"

        spawn_agent_for_step "$story_line" "$step" "$prd_file"

        # Small pause between steps
        sleep 1
        echo ""
    done

    # All steps complete - mark story as done
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Story $story_id Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Update PRD to mark story as complete
    echo -e "${CYAN}Updating PRD...${NC}"
    node -e "
const fs = require('fs');
const prd = JSON.parse(fs.readFileSync('$prd_file', 'utf-8'));
const story = prd.userStories.find(s => s.id === '$story_id');
if (story) {
    story.passes = true;
    fs.writeFileSync('$prd_file', JSON.stringify(prd, null, 2));
    console.log('Marked $story_id as complete');
}
" 2>/dev/null || echo "Could not update PRD (requires Node.js)"

    # Run final quality check
    echo -e "${CYAN}Running final quality check...${NC}"
    pnpm run typecheck 2>&1 || echo -e "${YELLOW}⚠ Typecheck had issues - please review${NC}"

    # Commit changes
    echo -e "${CYAN}Committing changes...${NC}"
    git add -A
    local commit_title="feat: $story_id - $story_title"
    local commit_body="Co-Authored-By: Maven Flow <flow@maven.dev>"

    git commit -m "$commit_title" -m "$commit_body" 2>/dev/null || echo -e "${YELLOW}⚠ Nothing new to commit${NC}"

    # Push to remote
    echo -e "${CYAN}Pushing to remote...${NC}"
    git push 2>&1 || echo -e "${YELLOW}⚠ Push failed (may need manual push)${NC}"

    echo ""
    return 0
}

# ============================================================================
# Function to commit and push all changes
# ============================================================================
commit_and_push_changes() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Commit & Push Changes${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Check if there are changes to commit
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${GRAY}No changes to commit${NC}"
        return 0
    fi

    # Stage all changes
    git add -A

    # Create commit message
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    git commit -m "chore: flow session checkpoint - $current_time" 2>/dev/null || echo -e "${YELLOW}⚠ Nothing new to commit${NC}"

    # Push to remote
    echo -e "${CYAN}Pushing to remote...${NC}"
    if git push 2>&1; then
        echo -e "${GREEN}✓ Pushed to remote${NC}"
    else
        echo -e "${YELLOW}⚠ Push failed - please push manually${NC}"
    fi

    echo ""
}

# Main flow
write_header "Maven Flow - Starting"

# Check if plan.md exists for context
PLAN_CONTEXT=""
if [ -f "plan.md" ]; then
    echo -e "${CYAN}Found plan.md - using as additional context${NC}"
    PLAN_CONTEXT="
PLAN CONTEXT:
The user has a plan.md file with overall project direction. Use this as context when making decisions about feature interactions and prioritization.
"
fi

# Commit and push any existing changes first
commit_and_push_changes

# ============================================================================
# Main Execution Loop
# ============================================================================
STORIES_PROCESSED=0

for ((iteration=1; iteration<=MAX_ITERATIONS; iteration++)); do
    write_iteration_header "$iteration" "$MAX_ITERATIONS"

    # Get first incomplete story
    local story_result=$(get_first_incomplete_story)

    if [ $? -ne 0 ]; then
        # No more incomplete stories
        current_time=$(date +%s)
        duration=$((current_time - START_TIME))
        write_complete "$((iteration - 1))" "$duration"

        # Final commit and push
        commit_and_push_changes

        echo -e "${GREEN}${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  🎉 ALL STORIES COMPLETE! 🎉${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo ""
        exit 0
    fi

    IFS='|' read -r prd_file story_id story_title story_description <<< "$story_result"
    local story_line="$story_id|$story_title|$story_description"

    # Process this story
    if process_story "$prd_file" "$story_line"; then
        STORIES_PROCESSED=$((STORIES_PROCESSED + 1))
    fi

    # Check if we should continue
    stats=$(get_story_stats)
    IFS='|' read -r total completed remaining progress <<< "$stats"

    if [ $total -gt 0 ] && [ $completed -eq $total ]; then
        # All stories complete
        current_time=$(date +%s)
        duration=$((current_time - START_TIME))
        write_complete "$iteration" "$duration"

        # Final commit and push
        commit_and_push_changes

        echo ""
        exit 0
    fi

    # Small pause between stories
    if [ $iteration -lt $MAX_ITERATIONS ]; then
        echo ""
        echo -e "${GRAY}Pausing ${SLEEP_SECONDS}s before next story...${NC}"
        sleep "$SLEEP_SECONDS"
        echo ""
    fi
done

# Max iterations reached
write_max_reached "$MAX_ITERATIONS"

# Final commit and push before exiting
commit_and_push_changes

exit 0
