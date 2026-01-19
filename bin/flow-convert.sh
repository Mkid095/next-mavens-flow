#!/bin/bash
# ============================================================================
# Maven Flow PRD Converter Terminal Forwarder
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

# Get feature/file to convert
FEATURE="$1"

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       Maven Flow - PRD Converter & Format Transformer      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show what we're doing
print_header

if [ -z "$FEATURE" ]; then
    echo -e "${BLUE}▶ Converting PRD from clipboard or editor${NC}"
    echo -e "${GRAY}  → Converting Markdown PRD to JSON format for Maven Flow${NC}"
else
    echo -e "${BLUE}▶ Converting PRD:${NC} ${YELLOW}$FEATURE${NC}"
    echo -e "${GRAY}  → Transforming to Maven Flow JSON format${NC}"
fi
echo ""

# Build the prompt
PROMPT="/flow-convert $FEATURE"

# Start a background spinner while Claude runs
(
    while true; do
        for frame in "${SPINNER[@]}"; do
            echo -ne "\r${CYAN}  [${frame}] Converting PRD format...${NC}"
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
    echo -e "\r${GREEN}[✓] PRD converted successfully${NC}                                          "
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GRAY}Next steps:${NC}"
    echo -e "  ${GREEN}→${NC} Run: ${YELLOW}flow start${NC} to begin development"
    echo -e "  ${GREEN}→${NC} View: ${YELLOW}prd.json${NC} to see the converted format"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    # Error - kill spinner and show error
    kill $SPINNER_PID 2>/dev/null
    echo -e "\r${RED}[X] Error converting PRD${NC}                                                "
    exit 1
fi
