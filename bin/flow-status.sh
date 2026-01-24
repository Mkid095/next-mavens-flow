#!/bin/bash
# ============================================================================
# Maven Flow - Status Script
# ============================================================================

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

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
    local prd_list=""

    if [ -d "docs" ]; then
        for prd in docs/prd-*.json; do
            if [ -f "$prd" ]; then
                local count=$(jq '.userStories | length' "$prd" 2>/dev/null || echo 0)
                total=$((total + count))

                local complete=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd" 2>/dev/null || echo 0)
                completed=$((completed + complete))

                # Get PRD name
                local prd_name=$(jq -r '.title // "Unknown"' "$prd" 2>/dev/null)
                local feature=$(basename "$prd" .json | sed 's/prd-//')
                prd_list="${prd_list}  ${CYAN}${feature}${NC}: ${GREEN}${complete}/${count}${NC} - ${prd_name}\n"
            fi
        done
    fi

    local remaining=$((total - completed))
    local progress=0
    if [ $total -gt 0 ]; then
        progress=$(( (completed * 100) / total ))
    fi

    echo "$total|$completed|$remaining|$progress|$prd_list"
}

# Check for session file
if [ -f ".flow-session" ]; then
    SESSION_ID=$(cat .flow-session)
    echo -e "${GREEN}[ACTIVE]${NC} Session: ${MAGENTA}${SESSION_ID}${NC}"
else
    echo -e "${GRAY}No active session${NC}"
fi

# Get stats
stats=$(get_story_stats)
IFS='|' read -r total completed remaining progress prd_list <<< "$stats"

echo ""
echo -e "${CYAN}Maven Flow Status${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "Stories: ${GREEN}${completed}/${total}${NC} ${GRAY}(${remaining} remaining)${NC}"
echo -e "Progress: ${YELLOW}${progress}%${NC}"

if [ -n "$prd_list" ]; then
    echo ""
    echo -e "${GRAY}PRDs:${NC}"
    echo -e "$prd_list" | sed 's/\\n/\n/g'
fi

echo -e "${CYAN}════════════════════════════════════════${NC}"

if [ $total -gt 0 ] && [ $completed -eq $total ]; then
    echo -e "${GREEN}[OK] All stories complete!${NC}"
    exit 0
elif [ $total -eq 0 ]; then
    echo -e "${YELLOW}[!] No PRDs found in docs/${NC}"
    exit 1
else
    echo -e "${YELLOW}[INFO] Work in progress${NC}"
    exit 0
fi
