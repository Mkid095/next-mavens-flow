#!/bin/bash
# ============================================================================
# Maven Flow PRD Generator Terminal Forwarder
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

# Get description
DESCRIPTION="$*"

# Print header
print_header() {
    # Show ASCII banner
    show_flow_banner

    echo ""
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|      Maven Flow - PRD Generator & Requirements Analyst    |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

# If description contains "plan.md", use plan mode
if [[ "$DESCRIPTION" == *"plan.md"* ]] || [[ "$DESCRIPTION" == "plan" ]]; then
    DESCRIPTION="plan"
fi

# Show what we're doing
print_header

# Determine mode
if [ "$DESCRIPTION" = "plan" ]; then
    echo -e "${BLUE}[MODE]${NC} ${GREEN}PLAN (reading plan.md)${NC}"
elif [[ "$DESCRIPTION" == fix* ]]; then
    echo -e "${BLUE}[MODE]${NC} ${YELLOW}FIX (updating existing PRDs)${NC}"
elif [ -z "$DESCRIPTION" ]; then
    echo -e "${BLUE}[MODE]${NC} ${CYAN}SINGLE PRD (from description)${NC}"
    echo -e "${GRAY}  [INFO] Interactive mode - Claude will guide you through requirements${NC}"
else
    echo -e "${BLUE}[MODE]${NC} ${CYAN}SINGLE PRD (from description)${NC}"
    echo -e "${GRAY}  [INFO] Creating comprehensive Product Requirements Document${NC}"
    echo -e "${BLUE}[DESCRIPTION]${NC} ${YELLOW}$DESCRIPTION${NC}"
fi
echo ""

# Build the prompt
PROMPT="/flow-prd $DESCRIPTION"

# Show processing message
echo -e "${CYAN}[INFO] Generating PRD...${NC}"

# Run Claude command
if claude --dangerously-skip-permissions "$PROMPT"; then
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|                   [OK] PRD GENERATED                     |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${GRAY}Next steps:${NC}"
    echo -e "  [INFO] Run: ${YELLOW}flow start${NC} to begin development"
    echo -e "  [INFO] Or:   ${YELLOW}flow-convert <prd-file>${NC} to convert existing PRD"
else
    echo ""
    echo -e "${RED}+============================================================+${NC}"
    echo -e "${RED}|                 [ERROR] GENERATION FAILED                  |${NC}"
    echo -e "${RED}+============================================================+${NC}"
    exit 1
fi
