#!/bin/bash
# ============================================================================
# Maven Flow Sync Script (Unix/Linux/macOS)
# Syncs changes between global installation and project source
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

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Maven Flow - Sync Manager                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Get directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$BIN_DIR")"

GLOBAL_BIN_DIR="$HOME/.claude/bin"

# Files to sync
SYNC_FILES=("flow.sh" "flow-prd.sh" "flow-convert.sh" "flow-update.sh")

# Get file hash
get_file_hash() {
    if [ -f "$1" ]; then
        sha256sum "$1" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Compare files
compare_files() {
    local source="$1"
    local dest="$2"

    local source_hash=$(get_file_hash "$source")
    local dest_hash=$(get_file_hash "$dest")

    if [ -z "$source_hash" ]; then
        echo "SourceMissing"
    elif [ -z "$dest_hash" ]; then
        echo "DestMissing"
    elif [ "$source_hash" = "$dest_hash" ]; then
        echo "Same"
    else
        echo "Different"
    fi
}

# Parse command
DIRECTION="${1:-auto}"
FORCE=false
VERBOSE=false

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

print_header

# Auto-detect direction
if [ "$DIRECTION" = "auto" ]; then
    echo -e "${BLUE}▶ Auto-detecting sync direction...${NC}"
    echo ""

    global_newer=0
    project_newer=0

    for file in "${SYNC_FILES[@]}"; do
        global_path="$GLOBAL_BIN_DIR/$file"
        project_path="$BIN_DIR/$file"

        if [ -f "$global_path" ] && [ -f "$project_path" ]; then
            global_time=$(stat -c %Y "$global_path" 2>/dev/null || stat -f %m "$global_path")
            project_time=$(stat -c %Y "$project_path" 2>/dev/null || stat -f %m "$project_path")

            if [ "$global_time" -gt "$project_time" ]; then
                ((global_newer++))
                if [ "$VERBOSE" = true ]; then
                    echo "  ${GRAY}Global is newer: ${CYAN}${file}${NC}"
                fi
            elif [ "$project_time" -gt "$global_time" ]; then
                ((project_newer++))
                if [ "$VERBOSE" = true ]; then
                    echo "  ${GRAY}Project is newer: ${CYAN}${file}${NC}"
                fi
            fi
        fi
    done

    if [ $global_newer -gt $project_newer ]; then
        DIRECTION="pull"
        echo "  ${YELLOW}→ Pull mode${NC} (Global is newer)"
    elif [ $project_newer -gt $global_newer ]; then
        DIRECTION="push"
        echo "  ${YELLOW}→ Push mode${NC} (Project is newer)"
    else
        DIRECTION="status"
        echo "  ${GREEN}→ Status mode${NC} (Everything in sync)"
    fi
    echo ""
fi

# Execute sync based on direction
case $DIRECTION in
    "status")
        echo -e "${BLUE}▶ Checking sync status...${NC}"
        echo ""

        all_synced=true
        for file in "${SYNC_FILES[@]}"; do
            global_path="$GLOBAL_BIN_DIR/$file"
            project_path="$BIN_DIR/$file"

            status=$(compare_files "$global_path" "$project_path")

            case $status in
                "Same")
                    echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - In sync"
                    ;;
                "SourceMissing")
                    echo "  ${RED}[!]${NC} ${CYAN}${file}${NC} - Missing in global"
                    all_synced=false
                    ;;
                "DestMissing")
                    echo "  ${RED}[!]${NC} ${CYAN}${file}${NC} - Missing in project"
                    all_synced=false
                    ;;
                "Different")
                    echo "  ${YELLOW}[~]${NC} ${CYAN}${file}${NC} - Out of sync"
                    all_synced=false
                    ;;
            esac
        done

        echo ""
        if [ "$all_synced" = true ]; then
            echo -e "${GREEN}All files are in sync!${NC}"
        else
            echo -e "${YELLOW}Files are out of sync. Use: flow-sync pull|push${NC}"
        fi
        ;;

    "pull")
        echo -e "${BLUE}▶ Pulling from global to project...${NC}"
        echo ""

        for file in "${SYNC_FILES[@]}"; do
            global_path="$GLOBAL_BIN_DIR/$file"
            project_path="$BIN_DIR/$file"

            status=$(compare_files "$global_path" "$project_path")

            if [ "$status" = "Different" ] || [ "$status" = "DestMissing" ] || [ "$FORCE" = true ]; then
                if [ -f "$global_path" ]; then
                    cp -f "$global_path" "$project_path"
                    echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - Pulled from global"
                else
                    echo "  ${RED}[!]${NC} ${CYAN}${file}${NC} - Not found in global"
                fi
            elif [ "$status" = "Same" ]; then
                echo "  ${GRAY}[=]${NC} ${CYAN}${file}${NC} - Already in sync"
            fi
        done

        echo ""
        echo -e "${GREEN}Pull complete!${NC}"
        ;;

    "push")
        echo -e "${BLUE}▶ Pushing from project to global...${NC}"
        echo ""

        for file in "${SYNC_FILES[@]}"; do
            global_path="$GLOBAL_BIN_DIR/$file"
            project_path="$BIN_DIR/$file"

            status=$(compare_files "$global_path" "$project_path")

            if [ "$status" = "Different" ] || [ "$status" = "SourceMissing" ] || [ "$FORCE" = true ]; then
                if [ -f "$project_path" ]; then
                    cp -f "$project_path" "$global_path"
                    chmod +x "$global_path"
                    echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - Pushed to global"
                else
                    echo "  ${RED}[!]${NC} ${CYAN}${file}${NC} - Not found in project"
                fi
            elif [ "$status" = "Same" ]; then
                echo "  ${GRAY}[=]${NC} ${CYAN}${file}${NC} - Already in sync"
            fi
        done

        echo ""
        echo -e "${GREEN}Push complete!${NC}"
        echo ""
        echo -e "${YELLOW}[!] Note: Restart terminal to use updated global scripts${NC}"
        ;;
esac

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
