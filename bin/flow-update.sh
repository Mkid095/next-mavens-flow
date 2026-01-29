#!/bin/bash
# ============================================================================
# Maven Flow Updater Terminal Forwarder
# Provides visual feedback and progress indicators
# ============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner
if [ -f "$SCRIPT_DIR/../.claude/bin/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/../.claude/bin/flow-banner.sh"
    show_flow_banner
fi

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

# Get command
COMMAND="${1:-sync}"

# Print header
print_header() {
    # Show ASCII banner
    show_flow_banner

    echo ""
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|          Maven Flow - System Updater & Maintenance        |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

# Show what we're doing
print_header

case "$COMMAND" in
    check)
        echo -e "${YELLOW}[INFO] Checking for updates...${NC}"
        echo -e "${GRAY}  [INFO] Comparing with GitHub repository${NC}"
        ;;
    sync)
        echo -e "${YELLOW}[INFO] Updating Maven Flow...${NC}"
        echo -e "${GRAY}  [INFO] Fetching latest changes${NC}"
        echo -e "${GRAY}  [INFO] Syncing components${NC}"
        ;;
    force)
        echo -e "${YELLOW}[INFO] Force updating...${NC}"
        echo -e "${GRAY}  [INFO] Reinstalling all components${NC}"
        ;;
    help)
        echo -e "${CYAN}Maven Flow Updater Commands:${NC}"
        echo ""
        echo -e "  ${YELLOW}flow-update check${NC}    Check for updates"
        echo -e "  ${YELLOW}flow-update sync${NC}     Fetch and apply updates"
        echo -e "  ${YELLOW}flow-update force${NC}    Force reinstall"
        echo ""
        exit 0
        ;;
    *)
        echo -e "${RED}[ERROR] Unknown command: $COMMAND${NC}"
        echo -e "${GRAY}[INFO] Run 'flow-update help' for options${NC}"
        exit 1
        ;;
esac
echo ""

# Build the prompt
PROMPT="/flow-update $COMMAND"

# Show processing message
echo -e "${CYAN}[INFO] Processing update...${NC}"

# Run Claude command
if claude --dangerously-skip-permissions "$PROMPT"; then
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|                 [OK] UPDATE COMPLETE                       |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${GRAY}System ready:${NC}"
    echo -e "  [INFO] Run: ${YELLOW}flow start${NC} to continue development"
    echo -e "  [INFO] Run: ${YELLOW}flow status${NC} to see current state"
else
    echo ""
    echo -e "${RED}+============================================================+${NC}"
    echo -e "${RED}|               [ERROR] UPDATE FAILED                        |${NC}"
    echo -e "${RED}+============================================================+${NC}"
    exit 1
fi
