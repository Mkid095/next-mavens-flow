#!/bin/bash
# ============================================================================
# Maven Flow Incremental Quality Check Hook
#
# Only checks files changed since last "good" commit.
# Tracks last successful check state and only validates changed files.
#
# Usage: Called manually or as a pre-commit hook
#   ./incremental-check.sh [--force] [--commit <sha>]
#
# State file: .claude/.last-good-commit
# ============================================================================

set -o pipefail

# Configuration
STATE_FILE=".claude/.last-good-commit"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FORCE_CHECK=false
BASE_COMMIT=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

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
# State Management
# ============================================================================

# Get the last known good commit
get_last_good_commit() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Save the last known good commit
save_last_good_commit() {
    local commit="$1"
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$commit" > "$STATE_FILE"
}

# Clear the state (force full check next time)
clear_state() {
    rm -f "$STATE_FILE"
}

# ============================================================================
# File Analysis
# ============================================================================

# Get list of changed files since a commit
get_changed_files() {
    local base_commit="$1"

    if [ -z "$base_commit" ]; then
        # No base commit, check all files
        find "$PROJECT_ROOT/src" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) 2>/dev/null
        return
    fi

    # Get changed files using git diff
    git diff --name-only --diff-filter=d "$base_commit" 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' || true
}

# Get list of TypeScript files to check
get_files_to_check() {
    local base_commit="$1"

    if [ "$FORCE_CHECK" = true ]; then
        log_info "Force check enabled - checking all files"
        get_changed_files ""
        return
    fi

    # Check if there's a last good commit
    local last_good=$(get_last_good_commit)

    if [ -z "$last_good" ]; then
        log_warning "No last good commit found - checking all files"
        get_changed_files ""
        return
    fi

    # Use the provided base commit or last good commit
    local base="${base_commit:-$last_good}"
    log_info "Checking files changed since $base"

    get_changed_files "$base"
}

# Count lines of code in files
count_loc() {
    local files=("$@")
    local total=0

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local count=$(wc -l < "$file" 2>/dev/null || echo 0)
            total=$((total + count))
        fi
    done

    echo "$total"
}

# ============================================================================
# Quality Checks
# ============================================================================

# Check for 'any' types (ZERO TOLERANCE)
check_any_types() {
    local files=("$@")
    local any_count=0
    local details=()

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi

        local count=$(rg ": any\b|: any\[:|: any<|as any|Promise<any>|Record<any|<T = any>" "$file" 2>/dev/null | wc -l || echo "0")
        if [ "$count" -gt 0 ]; then
            any_count=$((any_count + count))
            details+=("$file: $count instance(s)")
        fi
    done

    echo "$any_count|${details[@]}"
}

# Check for gradients (ZERO TOLERANCE)
check_gradients() {
    local files=("$@")
    local gradient_count=0
    local details=()

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi

        local count=$(rg "linear-gradient|radial-gradient|conic-gradient|repeating-(linear|radial|conic)-gradient" "$file" 2>/dev/null | wc -l || echo "0")
        if [ "$count" -gt 0 ]; then
            gradient_count=$((gradient_count + count))
            details+=("$file: $count instance(s)")
        fi
    done

    echo "$gradient_count|${details[@]}"
}

# Check for relative imports
check_relative_imports() {
    local files=("$@")
    local relative_count=0
    local details=()

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi

        local count=$(rg "from ['\"]\.\.?\/" "$file" 2>/dev/null | wc -l || echo "0")
        if [ "$count" -gt 0 ]; then
            relative_count=$((relative_count + count))
            details+=("$file: $count instance(s)")
        fi
    done

    echo "$relative_count|${details[@]}"
}

# Check for large components
check_large_components() {
    local files=("$@")
    local large_count=0
    local details=()

    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi

        if [[ "$file" =~ \.(tsx|jsx|vue)$ ]]; then
            local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
            if [ "$lines" -gt 300 ]; then
                large_count=$((large_count + 1))
                details+=("$file: $lines lines")
            fi
        fi
    done

    echo "$large_count|${details[@]}"
}

# ============================================================================
# Main Check Function
# ============================================================================

run_incremental_check() {
    local base_commit="$1"

    echo ""
    echo "=========================================="
    echo "  Maven Incremental Quality Check"
    echo "=========================================="
    echo ""

    # Get files to check
    local files_to_check=($(get_files_to_check "$base_commit"))

    if [ ${#files_to_check[@]} -eq 0 ]; then
        log_success "No files to check - all good!"
        echo ""
        return 0
    fi

    local file_count=${#files_to_check[@]}
    local loc=$(count_loc "${files_to_check[@]}")

    echo -e "${CYAN}Files to check:${NC} $file_count"
    echo -e "${CYAN}Lines of code:${NC} $loc"
    echo ""

    # Run quality checks
    local blocking=0
    local warnings=0

    # Check 1: Any types (ZERO TOLERANCE)
    log_info "Checking for 'any' types..."
    local any_result=$(check_any_types "${files_to_check[@]}")
    local any_count=$(echo "$any_result" | cut -d'|' -f1)
    if [ "$any_count" -gt 0 ]; then
        log_error "Found $any_count 'any' type(s) - ZERO TOLERANCE"
        blocking=$((blocking + any_count))
        echo "$any_result" | cut -d'|' -f2- | tr ' ' '\n' | grep -v '^$' | while read -r line; do
            echo "  - $line"
        done
    else
        log_success "No 'any' types found"
    fi

    # Check 2: Gradients (ZERO TOLERANCE)
    log_info "Checking for gradients..."
    local gradient_result=$(check_gradients "${files_to_check[@]}")
    local gradient_count=$(echo "$gradient_result" | cut -d'|' -f1)
    if [ "$gradient_count" -gt 0 ]; then
        log_error "Found $gradient_count gradient(s) - ZERO TOLERANCE"
        blocking=$((blocking + gradient_count))
        echo "$gradient_result" | cut -d'|' -f2- | tr ' ' '\n' | grep -v '^$' | while read -r line; do
            echo "  - $line"
        done
    else
        log_success "No gradients found"
    fi

    # Check 3: Relative imports
    log_info "Checking for relative imports..."
    local relative_result=$(check_relative_imports "${files_to_check[@]}")
    local relative_count=$(echo "$relative_result" | cut -d'|' -f1)
    if [ "$relative_count" -gt 0 ]; then
        log_warning "Found $relative_count relative import(s)"
        warnings=$((warnings + relative_count))
        echo "$relative_result" | cut -d'|' -f2- | tr ' ' '\n' | grep -v '^$' | while read -r line; do
            echo "  - $line"
        done
    else
        log_success "No relative imports found"
    fi

    # Check 4: Large components
    log_info "Checking for large components..."
    local large_result=$(check_large_components "${files_to_check[@]}")
    local large_count=$(echo "$large_result" | cut -d'|' -f1)
    if [ "$large_count" -gt 0 ]; then
        log_warning "Found $large_count large component(s) (>300 lines)"
        warnings=$((warnings + large_count))
        echo "$large_result" | cut -d'|' -f2- | tr ' ' '\n' | grep -v '^$' | while read -r line; do
            echo "  - $line"
        done
    else
        log_success "No large components found"
    fi

    echo ""
    echo "=========================================="
    echo "  Summary"
    echo "=========================================="
    echo "  Files checked: $file_count"
    echo "  Blocking violations: $blocking"
    echo "  Warnings: $warnings"
    echo "=========================================="
    echo ""

    # Return appropriate exit code
    if [ $blocking -gt 0 ]; then
        log_error "Blocking violations found - please fix before committing"
        return 2
    elif [ $warnings -gt 0 ]; then
        log_warning "Warnings found - review recommended"
        return 1
    else
        log_success "All checks passed!"

        # Update last good commit on success
        local current_head=$(git rev-parse HEAD 2>/dev/null || echo "")
        if [ -n "$current_head" ]; then
            save_last_good_commit "$current_head"
            log_info "Updated last good commit: $current_head"
        fi

        return 0
    fi
}

# ============================================================================
# Main Function
# ============================================================================

show_help() {
    cat << EOF
Maven Flow Incremental Quality Check

Usage: $(basename "$0") [OPTIONS]

Only checks files changed since last successful check.

Options:
    -h, --help              Show this help message
    -f, --force             Force check of all files
    -c, --commit <sha>      Check files changed since this commit
    --clear                 Clear the last good commit state
    --show-state            Show the current last good commit

State Management:
    The script tracks the last successful check in:
    $STATE_FILE

    Only files changed since this commit are checked,
    making incremental checks much faster for large codebases.

Exit Codes:
    0   All checks passed
    1   Warnings found (non-blocking)
    2   Blocking violations found

Examples:
    # Check incrementally since last good commit
    $(basename "$0")

    # Force check all files
    $(basename "$0}) --force

    # Check files changed since a specific commit
    $(basename "$0}) --commit abc123

    # Clear the state (next run will check all files)
    $(basename "$0}) --clear

EOF
}

main() {
    cd "$PROJECT_ROOT" || exit 1

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                FORCE_CHECK=true
                shift
                ;;
            -c|--commit)
                BASE_COMMIT="$2"
                shift 2
                ;;
            --clear)
                clear_state
                log_success "Cleared last good commit state"
                exit 0
                ;;
            --show-state)
                local last_good=$(get_last_good_commit)
                if [ -z "$last_good" ]; then
                    echo "No last good commit state found"
                else
                    echo "Last good commit: $last_good"
                fi
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Run the incremental check
    run_incremental_check "$BASE_COMMIT"
}

main "$@"
