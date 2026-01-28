#!/bin/bash
# ============================================================================
# Maven Flow PRD Generator Terminal Forwarder
# Provides visual feedback and progress indicators
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

# Get description
DESCRIPTION="$*"

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      Maven Flow - PRD Generator & Requirements Analyst     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show what we're doing
print_header

if [ -z "$DESCRIPTION" ]; then
    echo -e "${BLUE}▶ Generating PRD from scratch${NC}"
    echo -e "${GRAY}  → Interactive mode - Claude will guide you through requirements${NC}"
else
    echo -e "${BLUE}▶ Generating PRD for:${NC} ${YELLOW}$DESCRIPTION${NC}"
    echo -e "${GRAY}  → Creating comprehensive Product Requirements Document${NC}"
fi
echo ""

# Build the prompt
PROMPT="/flow-prd $DESCRIPTION"

# Start a background spinner while Claude runs
(
    while true; do
        for frame in "${SPINNER[@]}"; do
            echo -ne "\r${CYAN}  [${frame}] Generating PRD...${NC}"
            sleep 0.1
        done
    done
) &
SPINNER_PID=$!

# Trap to ensure spinner is killed on exit
trap "kill $SPINNER_PID 2>/dev/null" EXIT

# Run Claude command
if claude --dangerously-skip-permissions "$PROMPT"; then
    # Success - kill spinner and show success
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${GREEN}[✓] PRD generated successfully${NC}                                         "
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GRAY}Next steps:${NC}"
    echo -e "  ${GREEN}→${NC} Run: ${YELLOW}flow start${NC} to begin development"
    echo -e "  ${GREEN}→${NC} Or:  ${YELLOW}flow-convert <prd-file>${NC} to convert existing PRD"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    # Error - kill spinner and show error
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${RED}[X] Error generating PRD${NC}                                               "
    exit 1
fi
