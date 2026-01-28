#!/bin/bash

##############################################################################
# Maven Flow Wrapper Script Template
#
# This script runs Maven Flow autonomous development using Claude Code CLI.
# It iterates through incomplete PRD stories and executes them.
#
# This file is a template. The flow command copies this to maven-flow.sh
# when running Maven Flow in a project directory.
#
##############################################################################

set -e

# Color codes
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
GRAY=$'\033[0;90m'
BOLD=$'\033[1m'
NC=$'\033[0m' # No Color

# Parse arguments
MAX_ITERATIONS=${1:-100}
SLEEP_SECONDS=${2:-2}

# Timing variables
SCRIPT_START_TIME=$(date +%s)
TOTAL_STORIES_COMPLETED=0
TOTAL_STORIES_FAILED=0

##############################################################################
# UI Helper Functions
##############################################################################

# Spinner animation
spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    local start_time=$(date +%s)

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local temp=${spinstr#?}
        printf "\r${CYAN}[${spinstr:0:1}]${NC} ${message} ${GRAY}(${elapsed}s)${NC}" 2>/dev/null || true
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r${GREEN}[✓]${NC} ${message} ${GRAY}($(($(date +%s) - start_time))s)${NC}\n"
}

# Format duration
format_duration() {
    local seconds=$1
    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    elif [ $seconds -lt 3600 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $((seconds % 3600 / 60))m"
    fi
}

# Print section header
print_header() {
    local title="$1"
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    printf "${MAGENTA}║${NC}  ${BOLD}%-60s${NC} ${MAGENTA}║${NC}\n" "$title"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
}

# Print info line
print_info() {
    local label="$1"
    local value="$2"
    printf "  ${CYAN}%-20s${NC} ${GREEN}%s${NC}\n" "$label:" "$value"
}

# Print status update
print_status() {
    local status="$1"
    local message="$2"
    echo -e "  ${GRAY}→${NC} ${CYAN}$status${NC}: $message"
}

##############################################################################
# Verification Functions
##############################################################################

# Create output file for agent
create_output_file() {
    local story_id="$1"
    local feature="$2"
    local feature_dir="docs/$feature"

    mkdir -p "$feature_dir"
    echo "=== $story_id Output ===" > "$feature_dir/${story_id}_output.txt"
}

# Append to output file
append_output() {
    local story_id="$1"
    local feature="$2"
    local content="$3"
    local feature_dir="docs/$feature"

    if [ -f "$feature_dir/${story_id}_output.txt" ]; then
        echo "$content" >> "$feature_dir/${story_id}_output.txt"
    fi
}

##############################################################################
# PRD Processing Functions
##############################################################################

# Find all PRD files
find_prd_files() {
    find docs -name "prd-*.json" -type f 2>/dev/null | sort
}

# Get incomplete stories from PRD
get_incomplete_stories() {
    local prd_file="$1"
    jq -r '.userStories[] | select(.passes == false) | @json' "$prd_file" 2>/dev/null
}

# Count stories in PRD
count_stories() {
    local prd_file="$1"
    local total=$(jq '.userStories | length' "$prd_file" 2>/dev/null || echo "0")
    local complete=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd_file" 2>/dev/null || echo "0")
    echo "$total $complete"
}

##############################################################################
# Story Processing Functions
##############################################################################

# Process a single story
process_story() {
    local story_json="$1"
    local prd_file="$2"
    local iteration_count="$3"

    local story_id=$(echo "$story_json" | jq -r '.id')
    local story_title=$(echo "$story_json" | jq -r '.title')
    local story_description=$(echo "$story_json" | jq -r '.description')
    local maven_steps=$(echo "$story_json" | jq -r '.mavenSteps // []')
    local feature=$(echo "$story_json" | jq -r '.feature // .project // "unknown"')
    local mcp_tools=$(echo "$story_json" | jq -r '.mcpTools // {}')

    print_header "Story $story_id: $story_title"

    print_info "Feature" "$feature"
    print_info "Description" "$story_description"
    print_info "Maven Steps" "$(echo "$maven_steps" | jq -r 'join(", ")')"
    print_info "Iteration" "#$iteration_count"
    echo ""

    # Create output file
    create_output_file "$story_id" "$feature"

    # Build the prompt for Claude
    local prompt="/flow start"
    prompt="$prompt --story-id $story_id"
    prompt="$prompt --prd-file $prd_file"
    prompt="$prompt --max-iterations 1"

    print_status "EXECUTING" "Running Claude Code for story $story_id..."

    # Run Claude Code
    if claude --dangerously-skip-permissions "$prompt"; then
        TOTAL_STORIES_COMPLETED=$((TOTAL_STORIES_COMPLETED + 1))
        print_status "SUCCESS" "Story $story_id completed successfully"
        echo ""

        # Update PRD to mark story as complete
        jq "(.userStories[] | select(.id == \"$story_id\") | .passes) = true" "$prd_file" > "${prd_file}.tmp"
        mv "${prd_file}.tmp" "$prd_file"

        # Create memory file
        create_story_memory "$story_id" "$story_title" "$feature" "$prd_file"
    else
        TOTAL_STORIES_FAILED=$((TOTAL_STORIES_FAILED + 1))
        print_status "ERROR" "Story $story_id failed"
        echo ""

        # Log error to progress file
        local progress_file="docs/progress-${feature}.txt"
        echo "[$(date)] Story $story_id failed - see output for details" >> "$progress_file"
    fi
}

# Create story memory file
create_story_memory() {
    local story_id="$1"
    local story_title="$2"
    local feature="$3"
    local prd_file="$4"

    local feature_dir="docs/$feature"
    local memory_file="$feature_dir/story-${story_id}-$(echo "$story_title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-').txt"

    # Build memory content safely (no command substitutions in heredoc)
    local current_date=$(date +%Y-%m-%d)
    local acceptance_criteria=$(jq -r ".userStories[] | select(.id == \"$story_id\") | .acceptanceCriteria" "$prd_file")
    local files_changed=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')

    cat > "$memory_file" << MEMORY_EOF
---
memoryVersion: 1
schemaVersion: 1
storyId: $story_id
storyTitle: $story_title
feature: $feature
completedDate: $current_date
agents: development-agent, quality-agent
---

# Story $story_id: $story_title

## Implemented
- Story completed via Maven Flow autonomous development
- Changes committed to git

## Key Decisions
- Followed Maven 10-Step Workflow
- Applied quality standards: no 'any' types, @/ imports, professional UI

## Files Changed
Total files modified: $files_changed

## Acceptance Criteria
$acceptance_criteria

---
TECHNICAL DECISIONS
-------------------
[Technical decisions made during implementation will be documented here]

---
OPEN QUESTIONS / FUTURE WORK
-----------------------------
- None documented

---
DEPENDENCIES
------------
Requires: None
Required by: None
MEMORY_EOF

    print_status "MEMORY" "Memory file created: $memory_file"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    print_header "Maven Flow - Autonomous Development"

    print_info "Max Iterations" "$MAX_ITERATIONS"
    print_info "Sleep Between" "$SLEEP_SECONDS seconds"
    echo ""

    # Find all PRD files
    local prd_files=$(find_prd_files)

    if [ -z "$prd_files" ]; then
        echo -e "${YELLOW}No PRD files found in docs/${NC}"
        echo ""
        echo "To create a PRD, run:"
        echo "  /flow-prd [feature description]"
        echo ""
        echo "Then convert it:"
        echo "  /flow-convert"
        exit 0
    fi

    echo -e "${GREEN}Found PRD files:${NC}"
    echo "$prd_files" | while read -r prd; do
        local counts=$(count_stories "$prd")
        local total=$(echo "$counts" | awk '{print $1}')
        local complete=$(echo "$counts" | awk '{print $2}')
        echo "  $(basename "$prd"): $complete/$total complete"
    done
    echo ""

    # Process stories
    local iteration=0
    local prd_array=($prd_files)

    while [ $iteration -lt $MAX_ITERATIONS ]; do
        local processed_any=false

        for prd_file in "${prd_array[@]}"; do
            local incomplete=$(get_incomplete_stories "$prd_file")

            if [ -n "$incomplete" ]; then
                iteration=$((iteration + 1))

                if [ $iteration -gt $MAX_ITERATIONS ]; then
                    break
                fi

                # Process first incomplete story
                echo "$incomplete" | head -1 | while read -r story_json; do
                    process_story "$story_json" "$prd_file" "$iteration"
                done

                processed_any=true
                sleep $SLEEP_SECONDS
            fi
        done

        if [ "$processed_any" = false ]; then
            echo ""
            echo -e "${GREEN}All stories complete!${NC}"
            break
        fi
    done

    # Final summary
    local script_end_time=$(date +%s)
    local total_duration=$((script_end_time - SCRIPT_START_TIME))

    print_header "Execution Summary"

    print_info "Completed" "$TOTAL_STORIES_COMPLETED stories"
    print_info "Failed" "$TOTAL_STORIES_FAILED stories"
    print_info "Duration" "$(format_duration $total_duration)"
    echo ""

    if [ $TOTAL_STORIES_FAILED -gt 0 ]; then
        echo -e "${YELLOW}Some stories failed. Check output files for details.${NC}"
        exit 1
    else
        echo -e "${GREEN}All stories completed successfully!${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
