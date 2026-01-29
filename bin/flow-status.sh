#!/bin/bash
# ============================================================================
# Maven Flow - Status Script
# ============================================================================

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
RED='\033[0;31m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Must match constants from lock.sh
FLOW_HEARTBEAT_TIMEOUT=300

# Show lock status
show_lock_status() {
    [ -d .flow-locks ] || return 0

    echo ""
    echo -e "${CYAN}Story Locks:${NC}"

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

echo ""
echo -e "${CYAN}==============================================================================${NC}"
echo -e "${CYAN}                    Maven Flow - Project Status                     ${NC}"
echo -e "${CYAN}==============================================================================${NC}"
echo ""

prd_files=(docs/prd-*.json)
if [ ${#prd_files[@]} -eq 0 ] || [ ! -f "${prd_files[0]}" ]; then
    echo -e "  ${RED}[ERROR] No PRD JSON files found in docs/${NC}"
    echo -e "  Run: flow-prd plan"
    exit 1
fi

total_stories=0
total_completed=0

# Sort PRD files
IFS=$'\n' sorted_prds=($(sort <<< "${prd_files[*]}"))
unset IFS

for prd in "${sorted_prds[@]}"; do
    [ -f "$prd" ] || continue

    feature_name=$(basename "$prd" .json | sed 's/prd-//')
    story_count=$(jq '.userStories | length' "$prd" 2>/dev/null)

    # Validate story_count
    if [[ ! "$story_count" =~ ^[0-9]+$ ]]; then
        continue
    fi

    total_stories=$((total_stories + story_count))

    completed_count=0
    current_story_data=""

    for ((j=0; j<story_count; j++)); do
        passes=$(jq ".userStories[$j].passes" "$prd" 2>/dev/null | tr -d '"')

        # Story is complete if passes is NOT "false"
        is_complete=1
        if [ "$passes" = "false" ]; then
            is_complete=0
        fi

        if [ $is_complete -eq 1 ]; then
            completed_count=$((completed_count + 1))
            total_completed=$((total_completed + 1))
        else
            if [ -z "$current_story_data" ]; then
                current_story_data=$(jq -r ".userStories[$j]" "$prd" 2>/dev/null)
            fi
        fi
    done

    # Calculate progress
    if [ $story_count -gt 0 ]; then
        progress_pct=$(( (completed_count * 100) / story_count ))
    else
        progress_pct=0
    fi

    # Display progress bar
    bar_length=30
    filled=$(( bar_length * completed_count / story_count ))
    empty=$(( bar_length - filled ))

    # Build bar
    bar=""
    for ((k=0; k<filled; k++)); do bar="${bar}█"; done
    for ((k=0; k<empty; k++)); do bar="${bar}░"; done

    if [ $completed_count -eq $story_count ]; then
        # Complete - show green box
        status_text="COMPLETE ($completed_count/$story_count) "
        feature_display="$feature_name"
        if [ ${#feature_display} -gt 48 ]; then
            feature_display="${feature_display:0:45}..."
        fi
        count_display="$completed_count/$story_count"

        echo -e "${GREEN}┌────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${GREEN}│ [OK] ${feature_display}${NC}                                                  ${GREEN}│${NC}"
        echo -e "${GREEN}└────────────────────────────────────────────────────────────────────┘${NC}"
    else
        # In progress - show cyan box with progress bar
        echo -e "${CYAN}┌────────────────────────────────────────────────────────────────────┐${NC}"
        echo -en "${CYAN}│ ${NC}"
        echo -en "${feature_name}"
        echo -en " "
        echo -e "${YELLOW}[${bar}]${NC} ${CYAN}${progress_pct}%${NC} (${completed_count}/${story_count})                    ${CYAN}│${NC}"
        echo -e "${CYAN}└────────────────────────────────────────────────────────────────────┘${NC}"

        # Show current story
        if [ -n "$current_story_data" ]; then
            story_id=$(echo "$current_story_data" | jq -r '.id' 2>/dev/null)
            story_title=$(echo "$current_story_data" | jq -r '.title' 2>/dev/null)

            if [ -z "$story_id" ] || [ "$story_id" = "null" ]; then
                story_id="UNKNOWN"
            fi
            if [ -z "$story_title" ] || [ "$story_title" = "null" ]; then
                story_title="No title"
            fi

            echo ""
            echo -e "  ${YELLOW}CURRENT STORY: $story_id - $story_title${NC}"
        fi
    fi

    echo ""
done

# Overall progress
if [ $total_stories -gt 0 ]; then
    overall_pct=$(( (total_completed * 100) / total_stories ))
else
    overall_pct=0
fi

overall_filled=$(( 30 * total_completed / total_stories ))
overall_bar=""
for ((k=0; k<overall_filled; k++)); do overall_bar="${overall_bar}█"; done
for ((k=0; k<30 - overall_filled; k++)); do overall_bar="${overall_bar}░"; done

echo -e "${CYAN}┌────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ OVERALL PROGRESS                                  [${GREEN}${overall_bar}${CYAN}] ${overall_pct}% (${total_completed}/${total_stories}) │${NC}"
echo -e "${CYAN}└────────────────────────────────────────────────────────────────────┘${NC}"

# Show lock status
show_lock_status

echo ""
echo -e "  ${GRAY}Run 'flow-continue' to resume, or 'flow-help' for more commands${NC}"
echo ""
