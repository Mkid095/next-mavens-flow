#!/bin/bash
# ============================================================================
# Maven Flow Memory File Creation Hook
#
# Creates story memory files after story completion.
# Format: docs/[feature]/story-US-[###]-[title].txt
#
# Usage: Called after story completion or via /flow command
# Dependencies: Requires jq for JSON parsing
# ============================================================================

set -o pipefail

# Source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Memory file version
MEMORY_VERSION=1
SCHEMA_VERSION=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Slugify a string (convert to filename-safe format)
slugify() {
    local input="$1"
    # Convert to lowercase
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    # Replace spaces and special chars with hyphens
    input=$(echo "$input" | sed 's/[^a-z0-9]\+/-/g')
    # Remove leading/trailing hyphens
    input=$(echo "$input" | sed 's/^-\+//;s/-\+$//')
    echo "$input"
}

# Escape special characters for JSON
escape_json() {
    local input="$1"
    # Escape backslashes, quotes, and newlines
    echo "$input" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

# Get feature name from PRD filename
get_feature_name() {
    local prd_file="$1"
    basename "$prd_file" | sed 's/^prd-//' | sed 's/\.json$//'
}

# Get feature directory path
get_feature_dir() {
    local prd_file="$1"
    local feature_name=$(get_feature_name "$prd_file")
    echo "$PROJECT_ROOT/docs/$feature_name"
}

# ============================================================================
# Memory File Creation
# ============================================================================

# Create story memory file
create_story_memory() {
    local prd_file="$1"
    local story_id="$2"
    local story_title="$3"
    local agents="$4"
    local implemented="$5"
    local decisions="$6"
    local challenges="$7"
    local integration_points="$8"
    local lessons="$9"
    local commit_msg="${10}"

    local feature_dir=$(get_feature_dir "$prd_file")
    local title_slug=$(slugify "$story_title")
    local memory_file="$feature_dir/story-${story_id}-${title_slug}.txt"
    local completed_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create feature directory if it doesn't exist
    if [ ! -d "$feature_dir" ]; then
        mkdir -p "$feature_dir"
        log_info "Created feature directory: $feature_dir"
    fi

    # Build the memory file content
    cat > "$memory_file" << EOF
---
memoryVersion: $MEMORY_VERSION
schemaVersion: $SCHEMA_VERSION
storyId: $story_id
storyTitle: $story_title
feature: $(get_feature_name "$prd_file")
completedDate: $completed_date
agents: $agents
---

# Story $story_id: $story_title

## Implemented
$implemented

## Key Decisions
$decisions

## Challenges Resolved
$challenges

## Integration Points
$integration_points

## Lessons Learned
$lessons

## Commit
$commit_msg
EOF

    log_success "Created story memory: $memory_file"
    echo "$memory_file"
}

# ============================================================================
# PRD-Based Memory Creation
# ============================================================================

# Create memory from PRD story data
create_memory_from_prd() {
    local prd_file="$1"
    local story_id="$2"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq."
        return 1
    fi

    # Check if PRD file exists
    if [ ! -f "$prd_file" ]; then
        log_error "PRD file not found: $prd_file"
        return 1
    fi

    # Extract story data from PRD
    local story_data=$(jq -r ".userStories[] | select(.id == \"$story_id\")" "$prd_file")

    if [ -z "$story_data" ]; then
        log_error "Story $story_id not found in PRD"
        return 1
    fi

    local story_title=$(echo "$story_data" | jq -r '.title')
    local story_desc=$(echo "$story_data" | jq -r '.description')
    local acceptance=$(echo "$story_data" | jq -r '.acceptanceCriteria[]?' | sed 's/^/- /')

    # Default values
    local implemented="- $story_desc"
    local decisions="See PRD for acceptance criteria"
    local challenges="None documented"
    local integration_points="None documented"
    local lessons="None documented"
    local commit_msg="feat: $story_id - $story_title"

    # Call the main create function
    create_story_memory \
        "$prd_file" \
        "$story_id" \
        "$story_title" \
        "development-agent" \
        "$implemented" \
        "$decisions" \
        "$challenges" \
        "$integration_points" \
        "$lessons" \
        "$commit_msg"
}

# ============================================================================
# Interactive Memory Creation
# ============================================================================

# Interactive mode for creating memory file
interactive_create_memory() {
    local prd_file="$1"

    if [ ! -f "$prd_file" ]; then
        log_error "PRD file not found: $prd_file"
        return 1
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Maven Flow Story Memory Creation"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    log_info "PRD: $prd_file"
    log_info "Feature: $(get_feature_name "$prd_file")"
    echo ""

    # List available stories
    if command -v jq &> /dev/null; then
        echo "Available stories in PRD:"
        jq -r '.userStories[] | "- \(.id): \(.title)"' "$prd_file"
        echo ""
    fi

    # Get story details
    read -p "Enter story ID (e.g., US-001): " story_id
    read -p "Enter story title: " story_title
    read -p "Enter agents used (comma-separated, default: development-agent): " agents
    read -p "Enter commit message: " commit_msg

    # Set defaults
    agents=${agents:-development-agent}

    echo ""
    log_info "What was implemented?"
    read -r implemented

    log_info "Key decisions made?"
    read -r decisions

    log_info "Challenges resolved?"
    read -r challenges

    log_info "Integration points with other features?"
    read -r integration_points

    log_info "Lessons learned?"
    read -r lessons

    echo ""

    # Create the memory file
    create_story_memory \
        "$prd_file" \
        "$story_id" \
        "$story_title" \
        "$agents" \
        "$implemented" \
        "$decisions" \
        "$challenges" \
        "$integration_points" \
        "$lessons" \
        "$commit_msg"

    return 0
}

# ============================================================================
# Main Function
# ============================================================================

show_help() {
    cat << EOF
Maven Flow Memory File Creation Hook

Usage: $(basename "$0") [OPTIONS] [PRD_FILE] [STORY_ID]

Creates story memory files after story completion.
Format: docs/[feature]/story-US-[###]-[title].txt

Options:
    -h, --help          Show this help message
    -i, --interactive   Interactive mode for creating memory
    -p, --prd FILE      PRD JSON file to read story from
    -s, --story ID      Story ID to create memory for

Examples:
    # Interactive mode
    $(basename "$0") -i docs/prd-authentication.json

    # Create from PRD story
    $(basename "$0") -p docs/prd-authentication.json -s US-001

    # Direct creation with all parameters
    $(basename "$0") docs/prd-authentication.json US-001

Memory File Format:
    ---
    memoryVersion: 1
    storyId: US-001
    storyTitle: Create login form
    feature: authentication
    completedDate: 2025-01-24T10:30:00Z
    agents: development-agent, security-agent
    ---

    # Story US-001: Create login form

    ## Implemented
    - Created login form component with email and password fields
    - Added form validation
    - Integrated with auth API

    ## Key Decisions
    - Used React Hook Form for form management
    - Password visibility toggle
    - Remember me checkbox

    ## Challenges Resolved
    - Fixed form submission on Enter key
    - Resolved autofocus issue on mobile

    ## Integration Points
    - Connects to: @features/auth/api/login
    - Used by: @app/pages/login

    ## Lessons Learned
    - Always test form on mobile devices
    - Use native HTML5 validation where possible

    ## Commit
    feat: US-001 - Create login form

EOF
}

main() {
    local prd_file=""
    local story_id=""
    local interactive=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--interactive)
                interactive=true
                shift
                ;;
            -p|--prd)
                prd_file="$2"
                shift 2
                ;;
            -s|--story)
                story_id="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$prd_file" ]; then
                    prd_file="$1"
                elif [ -z "$story_id" ]; then
                    story_id="$1"
                fi
                shift
                ;;
        esac
    done

    # Find default PRD if none specified
    if [ -z "$prd_file" ]; then
        # Look for prd-*.json files in docs/
        local prd_files=($(find "$PROJECT_ROOT/docs" -name "prd-*.json" 2>/dev/null))
        if [ ${#prd_files[@]} -eq 0 ]; then
            log_error "No PRD files found in docs/"
            exit 1
        elif [ ${#prd_files[@]} -eq 1 ]; then
            prd_file="${prd_files[0]}"
            log_info "Using PRD: $prd_file"
        else
            log_error "Multiple PRD files found. Please specify one:"
            printf '%s\n' "${prd_files[@]}"
            exit 1
        fi
    fi

    # Make path absolute
    if [[ ! "$prd_file" = /* ]]; then
        prd_file="$PROJECT_ROOT/$prd_file"
    fi

    # Interactive mode
    if [ "$interactive" = true ]; then
        interactive_create_memory "$prd_file"
        exit $?
    fi

    # Create from PRD
    if [ -n "$story_id" ]; then
        create_memory_from_prd "$prd_file" "$story_id"
        exit $?
    fi

    # No story ID specified - show help
    log_error "Story ID required (use -s or --story)"
    show_help
    exit 1
}

# Run main function
main "$@"
