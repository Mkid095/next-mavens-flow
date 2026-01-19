#!/bin/bash
# ============================================================================
# Maven Flow Terminal Forwarder
# Provides interactive UX with visual feedback and progress indicators
# ============================================================================

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m'

# Animation frames
SPINNER=('⠋' '⠙' '⠸' '⠴' '⠦' '⠇' '⠏')

# Get command and arguments
COMMAND="${1:-start}"
ARGS="${@:2}"

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Maven Flow - Autonomous AI Development System       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show what we're doing
print_header

case "$COMMAND" in
    start)
        echo -e "${BLUE}▶ Starting Autonomous Development Mode${NC}"
        echo -e "${GRAY}  → Claude Code will analyze your codebase and implement features${NC}"
        echo ""
        ;;
    status)
        echo -e "${BLUE}▶ Checking Status${NC}"
        echo -e "${GRAY}  → Shows all PRDs and their completion status${NC}"
        echo ""
        ;;
    continue)
        echo -e "${BLUE}▶ Continuing Development${NC}"
        echo -e "${GRAY}  → Resumes from where you left off${NC}"
        echo ""
        ;;
    reset)
        echo -e "${YELLOW}▶ Reset PRD${NC}"
        echo -e "${GRAY}  → Archives current progress and starts fresh${NC}"
        echo ""
        ;;
    test)
        echo -e "${BLUE}▶ Testing Application${NC}"
        echo -e "${GRAY}  → Runs comprehensive browser testing${NC}"
        echo ""
        ;;
    consolidate)
        echo -e "${YELLOW}▶ Consolidating & Fixing${NC}"
        echo -e "${GRAY}  → Fixes errors found during testing${NC}"
        echo ""
        ;;
    *)
        echo -e "${BLUE}▶ Running: /flow $COMMAND $ARGS${NC}"
        echo ""
        ;;
esac

# Build the prompt
PROMPT="/flow $COMMAND $ARGS"

# Start a background spinner while Claude runs
(
    while true; do
        for frame in "${SPINNER[@]}"; do
            echo -ne "\r${CYAN}  [${frame}] Working on your request...${NC}"
            sleep 0.1
        done
    done
) &
SPINNER_PID=$!

# Trap to ensure spinner is killed on exit
trap "kill $SPINNER_PID 2>/dev/null" EXIT

# Run Claude command
if claude --dangerously-skip-permissions -p "$PROMPT"; then
    # Success - kill spinner and show success
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${GREEN}[✓] Completed successfully${NC}                                        "
    echo ""
else
    # Error - kill spinner and show error
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${RED}[X] Error occurred${NC}                                                 "
    exit 1
fi
