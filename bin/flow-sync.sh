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
# SCRIPT_DIR is already the bin/ directory - no need to go up
BIN_DIR="$SCRIPT_DIR"
PROJECT_DIR="$(dirname "$BIN_DIR")"

GLOBAL_BIN_DIR="$HOME/.claude/bin"

# Ensure global bin directory exists
mkdir -p "$GLOBAL_BIN_DIR"

# All shell scripts to sync
SYNC_FILES=(
    "flow.sh"
    "flow-prd.sh"
    "flow-convert.sh"
    "flow-update.sh"
    "flow-status.sh"
    "flow-continue.sh"
    "flow-help.sh"
    "flow-sync.sh"
    "flow-test.sh"
    "flow-consolidate.sh"
    "flow-work-story.sh"
    "flow-install-global.sh"
    "flow-uninstall-global.sh"
    "maven-flow-wrapper.sh"
    "test-locks.sh"
)

# Get file hash - cross-platform
get_file_hash() {
    if [ -f "$1" ]; then
        # Try sha256sum first (Linux), fall back to shasum (macOS)
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1 || echo ""
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

# Get file modification time - cross-platform
get_file_mtime() {
    local file="$1"
    if [ -f "$file" ]; then
        # Try stat -c (Linux), fall back to stat -f (macOS/BSD)
        stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Parse command
DIRECTION="${1:-auto}"
FORCE=false
VERBOSE=false

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --verbose|-v)
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
            global_time=$(get_file_mtime "$global_path")
            project_time=$(get_file_mtime "$project_path")

            if [ "$global_time" -gt "$project_time" ] 2>/dev/null; then
                ((global_newer++))
                if [ "$VERBOSE" = true ]; then
                    echo "  ${GRAY}Global is newer: ${CYAN}${file}${NC}"
                fi
            elif [ "$project_time" -gt "$global_time" ] 2>/dev/null; then
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

            # Skip if file doesn't exist in project
            if [ ! -f "$project_path" ]; then
                continue
            fi

            status=$(compare_files "$global_path" "$project_path")

            case $status in
                "Same")
                    echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - In sync"
                    ;;
                "SourceMissing")
                    echo "  ${YELLOW}[?]${NC} ${CYAN}${file}${NC} - Not in global (use push)"
                    all_synced=false
                    ;;
                "DestMissing")
                    echo "  ${YELLOW}[?]${NC} ${CYAN}${file}${NC} - Not in project (use pull)"
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

        pulled=0
        for file in "${SYNC_FILES[@]}"; do
            global_path="$GLOBAL_BIN_DIR/$file"
            project_path="$BIN_DIR/$file"

            status=$(compare_files "$global_path" "$project_path")

            if [ "$status" = "Different" ] || [ "$status" = "DestMissing" ] || [ "$FORCE" = true ]; then
                if [ -f "$global_path" ]; then
                    cp -f "$global_path" "$project_path"
                    chmod +x "$project_path"
                    echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - Pulled from global"
                    ((pulled++))
                else
                    echo "  ${GRAY}[skip]${NC} ${CYAN}${file}${NC} - Not found in global"
                fi
            elif [ "$status" = "Same" ]; then
                echo "  ${GRAY}[=]${NC} ${CYAN}${file}${NC} - Already in sync"
            fi
        done

        echo ""
        if [ $pulled -gt 0 ]; then
            echo -e "${GREEN}Pull complete! Updated ${pulled} file(s).${NC}"
        else
            echo -e "${GREEN}All files already in sync.${NC}"
        fi
        ;;

    "push")
        echo -e "${BLUE}▶ Pushing from project to global...${NC}"
        echo ""

        pushed=0
        for file in "${SYNC_FILES[@]}"; do
            global_path="$GLOBAL_BIN_DIR/$file"
            project_path="$BIN_DIR/$file"

            # Skip if file doesn't exist in project
            if [ ! -f "$project_path" ]; then
                continue
            fi

            status=$(compare_files "$global_path" "$project_path")

            if [ "$status" = "Different" ] || [ "$status" = "SourceMissing" ] || [ "$FORCE" = true ]; then
                cp -f "$project_path" "$global_path"
                chmod +x "$global_path"
                echo "  ${GREEN}[✓]${NC} ${CYAN}${file}${NC} - Pushed to global"
                ((pushed++))
            elif [ "$status" = "Same" ]; then
                echo "  ${GRAY}[=]${NC} ${CYAN}${file}${NC} - Already in sync"
            fi
        done

        echo ""
        if [ $pushed -gt 0 ]; then
            echo -e "${GREEN}Push complete! Updated ${pushed} file(s).${NC}"
            echo ""
            echo -e "${YELLOW}[!] Note: Restart terminal to use updated global scripts${NC}"
        else
            echo -e "${GREEN}All files already in sync.${NC}"
        fi
        ;;

    "help"|"-h"|"--help")
        echo -e "${CYAN}Usage: flow-sync [command] [options]${NC}"
        echo ""
        echo "Commands:"
        echo "  auto      Auto-detect sync direction (default)"
        echo "  status    Show sync status only"
        echo "  pull      Pull from global (~/.claude/bin) to project"
        echo "  push      Push from project to global"
        echo "  help      Show this help"
        echo ""
        echo "Options:"
        echo "  --force, -f    Force sync even if files match"
        echo "  --verbose, -v  Show detailed output"
        ;;

    *)
        echo -e "${RED}Unknown command: ${DIRECTION}${NC}"
        echo -e "${YELLOW}Use: flow-sync [auto|status|pull|push|help]${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
