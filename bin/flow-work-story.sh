#!/bin/bash
# ============================================================================
# Maven Flow - Work on Single Story
# ============================================================================
# Loads memory for a specific story and spawns specialized agents
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
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

# Print header
print_header() {
    # Show ASCII banner
    show_flow_banner

    echo ""
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|         Maven Flow - Single Story Workflow               |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

print_header

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  flow-work-story <story-id>     Work on a specific story"
    echo ""
    echo -e "${GRAY}Example:${NC}"
    echo "  flow-work-story us-001         Work on story US-001"
    echo ""
    exit 1
fi

STORY_ID="$1"

# Validate story ID format
if [[ ! "$STORY_ID" =~ ^[A-Za-z]{2,}-[0-9]+$ ]]; then
    echo -e "${RED}[ERROR] Invalid story ID format: $STORY_ID${NC}"
    echo -e "${GRAY}Expected format: US-001, FE-042, etc.${NC}"
    echo ""
    exit 1
fi

# Find PRD containing this story
PRD_FILE=""
for prd in docs/prd-*.json; do
    if [ -f "$prd" ]; then
        if jq -e ".userStories[] | select(.id == \"$STORY_ID\")" "$prd" &>/dev/null; then
            PRD_FILE="$prd"
            break
        fi
    fi
done

if [ -z "$PRD_FILE" ]; then
    echo -e "${RED}[ERROR] Story $STORY_ID not found in any PRD${NC}"
    echo ""
    exit 1
fi

echo -e "${BLUE}  Story: ${YELLOW}$STORY_ID${NC}"
echo -e "${GRAY}  PRD: $PRD_FILE${NC}"
echo ""

# Extract story info
STORY_TITLE=$(jq -r ".userStories[] | select(.id == \"$STORY_ID\") | .title" "$PRD_FILE")
STORY_STATUS=$(jq -r ".userStories[] | select(.id == \"$STORY_ID\") | .passes" "$PRD_FILE")

if [ "$STORY_STATUS" = "true" ]; then
    echo -e "${YELLOW}[!] Story $STORY_ID is already marked as complete${NC}"
    echo ""
    echo -n "Continue anyway? [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GRAY}[CANCELLED]${NC}"
        exit 0
    fi
fi

# Source lock library
if [ -f ".claude/lib/lock.sh" ]; then
    source .claude/lib/lock.sh

    # Acquire lock for this story
    SESSION_ID="$(hostname)-$$"
    echo -e "${GRAY}Acquiring lock for story...${NC}"
    if ! acquire_story_lock "$PRD_FILE" "$STORY_ID" "$SESSION_ID" 2>/dev/null; then
        echo -e "${RED}[ERROR] Failed to acquire lock for story $STORY_ID${NC}"
        echo -e "${GRAY}The story may be locked by another session${NC}"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}[OK] Lock acquired${NC}"
    echo ""

    # Set up cleanup on exit
    cleanup_locks() {
        echo ""
        echo -e "${GRAY}Releasing lock...${NC}"
        release_story_lock "$PRD_FILE" "$STORY_ID" "$SESSION_ID"
    }
    trap cleanup_locks EXIT
fi

echo -e "${CYAN}Starting work on: ${YELLOW}$STORY_ID - $STORY_TITLE${NC}"
echo ""

# Run flow-work-story command
if claude --dangerously-skip-permissions "/flow-work-story $STORY_ID" 2>&1; then
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|           [OK] STORY WORK COMPLETE                       |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${GRAY}  Story: $STORY_ID${NC}"
    echo ""

    # Ask if story should be marked complete
    echo -n "Mark story as complete? [y/N]: "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Update PRD to mark story as complete
        tmp_file=$(mktemp)
        jq "(.userStories[] | select(.id == \"$STORY_ID\")).passes = true" "$PRD_FILE" > "$tmp_file"
        mv "$tmp_file" "$PRD_FILE"
        echo -e "${GREEN}[OK] Story marked as complete${NC}"
    fi
else
    echo ""
    echo -e "${RED}+============================================================+${NC}"
    echo -e "${RED}|              [ERROR] STORY WORK FAILED                    |${NC}"
    echo -e "${RED}+============================================================+${NC}"
    echo ""
    exit 1
fi

echo ""
