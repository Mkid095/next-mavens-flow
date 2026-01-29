#!/bin/bash
# ============================================================================
# Maven Flow Consolidate - Fix errors from testing
# ============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner if available
if [ -f "$SCRIPT_DIR/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/flow-banner.sh"
fi

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

# Show ASCII banner
show_flow_banner

echo -e "${CYAN}Maven Flow - Error Consolidation${NC}"
echo -e "${CYAN}===================================${NC}"
echo ""

# Parse arguments
PRD_NAME=""
if [ -n "$1" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    PRD_NAME="$1"
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo -e "Usage: ${GREEN}flow-consolidate [prd-name]${NC}"
    echo ""
    echo -e "Arguments:"
    echo -e "  ${GRAY}prd-name${NC}    Optional: Specific PRD to consolidate (auto-detects if omitted)"
    echo ""
    echo -e "Description:"
    echo -e "  ${GRAY}Fix errors found during testing${NC}"
    echo -e "  ${GRAY}Reads error log from docs/errors-[feature-name].md${NC}"
    echo -e "  ${GRAY}Re-runs ONLY affected steps (not entire stories)${NC}"
    echo -e "  ${GRAY}Does NOT reimplement completed features${NC}"
    echo ""
    exit 0
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR] Claude CLI not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting error consolidation...${NC}"
echo ""

# Build the command
if [ -n "$PRD_NAME" ]; then
    echo -e "${GRAY}Consolidating PRD: ${CYAN}$PRD_NAME${NC}"
    echo ""
    CMD="/flow-consolidate $PRD_NAME"
else
    echo -e "${GRAY}Auto-detecting PRD to consolidate...${NC}"
    echo ""
    CMD="/flow-consolidate"
fi

# Execute
claude --dangerously-skip-permissions "$CMD"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[OK] Consolidation complete${NC}"
    echo -e "${GRAY}Re-run flow-test to verify all fixes${NC}"
else
    echo -e "${RED}[ERROR] Consolidation failed${NC}"
fi
echo ""

exit $EXIT_CODE
