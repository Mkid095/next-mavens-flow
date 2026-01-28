#!/bin/bash
# ============================================================================
# Maven Flow Updater Terminal Forwarder
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
    echo -e "${CYAN}║          Maven Flow - System Updater & Maintenance         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show what we're doing
print_header

if [ -z "$DESCRIPTION" ]; then
    echo -e "${BLUE}▶ Updating Maven Flow System${NC}"
    echo -e "${GRAY}  → Checking for updates and applying latest improvements${NC}"
else
    echo -e "${BLUE}▶ Updating Maven Flow:${NC} ${YELLOW}$DESCRIPTION${NC}"
    echo -e "${GRAY}  → Applying updates and enhancements${NC}"
fi
echo ""

# Build the prompt
PROMPT="/flow-update $DESCRIPTION"

# Start a background spinner while Claude runs
(
    while true; do
        for frame in "${SPINNER[@]}"; do
            echo -ne "\r${CYAN}  [${frame}] Updating Maven Flow...${NC}"
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
    echo -e "\r${GREEN}[✓] Maven Flow updated successfully${NC}                                       "
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GRAY}System ready:${NC}"
    echo -e "  ${GREEN}→${NC} Run: ${YELLOW}flow start${NC} to continue development"
    echo -e "  ${GREEN}→${NC} Run: ${YELLOW}flow status${NC} to see current state"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    # Error - kill spinner and show error
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${RED}[X] Error updating Maven Flow${NC}                                             "
    exit 1
fi
