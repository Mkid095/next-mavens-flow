#!/bin/bash
# ============================================================================
# Maven Flow - Status Script
# ============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source banner
if [ -f "$SCRIPT_DIR/flow-banner.sh" ]; then
    source "$SCRIPT_DIR/flow-banner.sh"
fi

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Must match constants from lock.sh
FLOW_HEARTBEAT_TIMEOUT=300

# Show lock status
show_lock_status() {
    [ -d .flow-locks ] || return 0

    echo -e "\n${CYAN}Story Locks:${NC}"

    local found=0
    for lock_data in .flow-locks/*.lock.data; do
        [ -f "$lock_data" ] || continue
        found=1

        local story_id=$(jq -r '.storyId' "$lock_data")
        local session_id=$(jq -r '.sessionId' "$lock_data")
        local pid=$(jq -r '.pid' "$lock_data")
        local locked_at=$(jq -r '.lockedAt' "$lock_data")
        local last_heartbeat=$(jq -r '.lastHeartbeat' "$lock_data")

        local now=$(date +%s)
        local age=$((now - locked_at))
        local heartbeat_age=$((now - last_heartbeat))

        # PID + heartbeat AND logic: BOTH must be valid for "alive"
        local status="unknown"
        if kill -0 "$pid" 2>/dev/null && [ "$heartbeat_age" -lt "$FLOW_HEARTBEAT_TIMEOUT" ]; then
            status="owner alive"
            icon="${GREEN}[LOCKED]${NC}"
        else
            status="owner dead (reclaimable)"
            icon="${YELLOW}[STALE]${NC}"
        fi

        local age_str="$((age / 60))m"
        echo -e "  ${icon} ${story_id} - session ${session_id:0:8} - ${status} (${age_str} old)"
    done

    [ $found -eq 0 ] && echo -e "  ${GRAY}No active locks${NC}"
}

# Show ASCII banner
show_flow_banner

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

# Show lock status
show_lock_status

echo ""

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
