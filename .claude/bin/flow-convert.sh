#!/bin/bash
# ============================================================================
# Maven Flow PRD Converter
# Converts markdown PRDs to JSON format with skip/reconvert support
# Also supports --fix mode for validating and repairing existing JSON files
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
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;90m'
DARK_YELLOW='\033[0;33m'
NC='\033[0m'

# Parse arguments
FORCE=false
ALL=false
FIX=false
REPAIR=false
FEATURE=""

for arg in "$@"; do
    case $arg in
        --fix|--repair)
            FIX=true
            REPAIR=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --all)
            ALL=true
            shift
            ;;
        -*)
            # Unknown flag - pass through
            ;;
        *)
            if [ -z "$FEATURE" ]; then
                FEATURE="$arg"
            fi
            ;;
    esac
done

# Print header
print_header() {
    # Show ASCII banner
    show_flow_banner

    echo ""
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|           Maven Flow - PRD Format Converter               |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

print_header

# ===================================================================
# FIX/REPAIR MODE - Validates and repairs existing JSON PRDs
# ===================================================================
if [ "$FIX" = true ]; then
    echo -e "${YELLOW}  FIX/REPAIR MODE${NC}"
    echo ""
    echo -e "${GRAY}  This mode validates and repairs existing JSON PRD files.${NC}"
    echo ""

    # Check if the fix script exists
    FIX_SCRIPT="/home/ken/bin/flow-convert.sh"

    if [ ! -f "$FIX_SCRIPT" ]; then
        echo -e "${RED}  [ERROR] Fix script not found: $FIX_SCRIPT${NC}"
        echo ""
        echo -e "${GRAY}  Please ensure Maven Flow is properly installed.${NC}"
        echo ""
        exit 1
    fi

    # Build arguments for fix script
    FIX_ARGS="--fix"

    if [ "$ALL" = true ]; then
        FIX_ARGS="$FIX_ARGS --all"
    elif [ -n "$FEATURE" ]; then
        FIX_ARGS="$FIX_ARGS $FEATURE"
    else
        FIX_ARGS="$FIX_ARGS --all"
    fi

    # Pass through any other flags
    for arg in "$@"; do
        case $arg in
            --fix|--repair|--force|--all|--verbose|--validate-only|-h|--help)
                # Already handled or will be added
                ;;
            --*)
                FIX_ARGS="$FIX_ARGS $arg"
                ;;
        esac
    done

    echo -e "${CYAN}  Running: $FIX_SCRIPT $FIX_ARGS${NC}"
    echo ""

    # Run the fix script
    exec "$FIX_SCRIPT" $FIX_ARGS
fi

# ===================================================================
# CONVERT MODE - Markdown PRD to JSON
# ===================================================================

# --all mode
if [ "$ALL" = true ] || [ -z "$FEATURE" ]; then
    echo -e "${YELLOW}  CONVERT MODE${NC}"
    echo -e "${YELLOW}  Converting all markdown PRDs to JSON...${NC}"
    if [ "$FORCE" = true ]; then
        echo -e "${YELLOW}  Mode: FORCE (reconvert existing)${NC}"
    else
        echo -e "${GRAY}  Mode: SKIP existing JSON files${NC}"
    fi
    echo ""

    # Find all markdown PRDs
    shopt -s nullglob
    PRD_FILES=(docs/prd-*.md)
    shopt -u nullglob

    if [ ${#PRD_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}  [!] No markdown PRDs found in docs/${NC}"
        echo ""
        echo -e "${GRAY}  Usage:${NC}"
        echo -e "    flow-convert <feature-name>          # Convert single PRD"
        echo -e "    flow-convert --fix                   # Fix all PRDs"
        echo -e "    flow-convert --fix <feature>         # Fix specific PRD"
        echo ""
        exit 1
    fi

    echo -e "${GREEN}  Found ${#PRD_FILES[@]} markdown PRD(s)${NC}"
    echo ""

    success_count=0
    fail_count=0
    skip_count=0

    for prd in "${PRD_FILES[@]}"; do
        feature=$(basename "$prd" | sed 's/prd-//' | sed 's/\.md$//')
        json_file="docs/prd-$feature.json"

        echo ""
        echo -e "${CYAN}  Checking: ${YELLOW}$feature${NC}"

        # Check if JSON already exists
        if [ -f "$json_file" ] && [ "$FORCE" = false ]; then
            echo -e "${DARK_YELLOW} [SKIPPED] (JSON exists - use --force to reconvert)${NC}"
            ((skip_count++))
            continue
        fi

        echo -e "${GRAY} -> Converting...${NC}"

        force_flag=""
        if [ "$FORCE" = true ]; then
            force_flag="--force"
        fi

        if claude --dangerously-skip-permissions "/flow-convert $force_flag $feature" 2>&1; then
            echo -e "${GREEN} [OK]${NC}"
            ((success_count++))
        else
            echo -e "${RED} [FAILED]${NC}"
            ((fail_count++))
        fi
    done

    echo ""
    echo -e "${GRAY}==============================================================================${NC}"
    echo ""
    echo -e "${GRAY}  Summary:${NC}"
    echo -e "${GRAY}    Converted: ${GREEN}$success_count PRD(s)${NC}"
    if [ $skip_count -gt 0 ]; then
        echo -e "${GRAY}    Skipped: ${DARK_YELLOW}$skip_count PRD(s) (already exist)${NC}"
    fi
    if [ $fail_count -gt 0 ]; then
        echo -e "${GRAY}    Failed: ${RED}$fail_count PRD(s)${NC}"
    fi
    echo ""

    exit 0
fi

# Single PRD conversion
echo -e "${BLUE}  Converting: ${YELLOW}$FEATURE${NC}"
echo ""
echo -e "${GRAY}  -> Reading from: docs/prd-$FEATURE.md${NC}"
echo -e "${GRAY}  -> Writing to: docs/prd-$FEATURE.json${NC}"
echo ""

force_flag=""
if [ "$FORCE" = true ]; then
    force_flag="--force"
fi

PROMPT="/flow-convert $force_flag $FEATURE"

if claude --dangerously-skip-permissions "$PROMPT"; then
    echo ""
    echo -e "${GREEN}+============================================================+${NC}"
    echo -e "${GREEN}|                [OK] CONVERSION COMPLETE                   |${NC}"
    echo -e "${GREEN}+============================================================+${NC}"
    echo ""
    echo -e "${GRAY}  Created: docs/prd-$FEATURE.json${NC}"
    echo ""
    echo -e "${YELLOW}  Next: ${GRAY}flow start    Begin development${NC}"
else
    echo ""
    echo -e "${RED}+============================================================+${NC}"
    echo -e "${RED}|              [ERROR] CONVERSION FAILED                    |${NC}"
    echo -e "${RED}+============================================================+${NC}"
    echo ""
    echo -e "${GRAY}  Make sure docs/prd-$FEATURE.md exists${NC}"
    exit 1
fi

echo ""
