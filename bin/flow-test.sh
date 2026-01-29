#!/bin/bash
# ============================================================================
# Maven Flow Test - Test implemented features
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

echo -e "${CYAN}Maven Flow - Feature Testing${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Parse arguments
PRD_NAME=""
if [ -n "$1" ] && [ "$1" != "--help" ] && [ "$1" != "-h" ]; then
    PRD_NAME="$1"
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo -e "Usage: ${GREEN}flow-test [prd-name]${NC}"
    echo ""
    echo -e "Arguments:"
    echo -e "  ${GRAY}prd-name${NC}    Optional: Specific PRD to test (auto-detects if omitted)"
    echo ""
    echo -e "Description:"
    echo -e "  ${GRAY}Run comprehensive testing of all implemented features${NC}"
    echo -e "  ${GRAY}Uses chrome-devtools MCP for browser automation${NC}"
    echo -e "  ${GRAY}Tests all completed stories (where passes: true)${NC}"
    echo -e "  ${GRAY}Creates error log at docs/errors-[feature-name].md${NC}"
    echo ""
    exit 0
fi

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR] Claude CLI not found in PATH${NC}"
    echo -e "${YELLOW}[INFO] Install with: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting comprehensive feature testing...${NC}"
echo ""

# Build the command
if [ -n "$PRD_NAME" ]; then
    echo -e "${GRAY}Testing PRD: ${CYAN}$PRD_NAME${NC}"
    echo ""
    CMD="/flow-test $PRD_NAME"
else
    echo -e "${GRAY}Auto-detecting PRD to test...${NC}"
    echo ""
    CMD="/flow-test"
fi

# Execute
claude --dangerously-skip-permissions "$CMD"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[OK] Testing complete${NC}"
    echo -e "${GRAY}Check docs/errors-*.md for any issues found${NC}"
else
    echo -e "${RED}[ERROR] Testing failed${NC}"
fi
echo ""

exit $EXIT_CODE
