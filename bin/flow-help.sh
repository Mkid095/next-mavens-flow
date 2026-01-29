#!/bin/bash
# ============================================================================
# Maven Flow - Help Command
# ============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner from .claude/bin
if [ -f "$SCRIPT_DIR/../.claude/bin/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/../.claude/bin/flow-banner.sh"
    show_flow_banner
fi

# Colors
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

cat << 'HELP'

 __    __     ______     __   __   ______     __   __     ______        ______   __         ______     __     __
/\ "-./  \   /\  __ \   /\ \ / /  /\  ___\   /\ "-.\ \   /\  ___\      /\  ___\ /\ \       /\  __ \   /\ \  _ \ \
\ \ \-./\ \  \ \  __ \  \ \ \/   \ \  __\   \ \ \-.  \  \ \___  \     \ \  __\ \ \ \____  \ \ \/\ \  \ \ \/ ".\ \
 \ \_\ \ \_\  \ \_\ \_\  \ \__|    \ \_____\  \ \_\\"\_\  \/\_____\     \ \_\    \ \_____\  \_____\  \ \__/".~\_\
  \/_/  \/_/   \/_/\/_/   \/_/      \/_____/   \/_/ \/_/   \/_____/      \/_/     \/_____/   \/_____/   \/_/   \_/

HELP

echo -e "${CYAN}Maven Flow - Autonomous AI Development System${NC}"
echo -e "${CYAN}================================================================================${NC}"
echo ""

echo -e "${WHITE}MAIN COMMANDS${NC}"
echo "  flow start [iterations]     Start autonomous development (default: 100)"
echo "  flow status                 Show project progress and story completion"
echo "  flow continue               Resume from previous session"
echo "  flow reset                  Reset session state and start fresh"
echo "  flow help, flow --help      Show this help screen"
echo ""

echo -e "${WHITE}PRD WORKFLOW${NC}"
echo "  flow-prd [description]      Generate a new PRD from scratch or plan.md"
echo "  flow-convert [feature]      Convert markdown PRD to JSON format"
echo "                              Use --all to convert all PRDs"
echo "                              Use --force to reconvert existing JSON"
echo ""

echo -e "${WHITE}MAINTENANCE${NC}"
echo "  flow-update [description]   Update Maven Flow system from GitHub"
echo ""

echo -e "${WHITE}OPTIONS${NC}"
echo "  --dry-run                   Show what would happen without making changes"
echo "  -h, --help, help            Show help screen"
echo ""

echo -e "${WHITE}WORKFLOW${NC}"
echo "  1. Create PRD:    flow-prd \"your feature description\""
echo "  2. Convert:       flow-convert feature-name"
echo "  3. Develop:       flow start"
echo ""

echo -e "${WHITE}GETTING STARTED${NC}"
echo "  GitHub: https://github.com/Mkid095/next-mavens-flow"
echo ""

exit 0
