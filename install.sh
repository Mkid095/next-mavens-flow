#!/bin/bash
# ============================================================================
# Maven Flow Safe Installer (Manifest-Based, Idempotent)
# ============================================================================
# - Creates missing files
# - Overwrites managed files
# - Removes obsolete managed files ONLY
# - Never deletes anything outside the manifest
# ============================================================================
set -e

# -------------------------
# CONFIG
# -------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false   # Set to true to preview actions

HOME_CLAUDE="$HOME/.claude"
if [ -d "$HOME_CLAUDE" ]; then
    TARGET_DIR="$HOME_CLAUDE"
else
    TARGET_DIR="$SCRIPT_DIR/.claude/maven-flow"
fi

# -------------------------
# UI HELPERS
# -------------------------
log() {
    local color=$2
    case $color in
        red)    echo -e "\033[0;31m$1\033[0m" ;;
        green)  echo -e "\033[0;32m$1\033[0m" ;;
        yellow) echo -e "\033[1;33m$1\033[0m" ;;
        blue)   echo -e "\033[0;34m$1\033[0m" ;;
        cyan)   echo -e "\033[0;36m$1\033[0m" ;;
        *)      echo "$1" ;;
    esac
}

ensure_dir() {
    local path="$1"
    if [ ! -d "$path" ]; then
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$path"
        fi
        log "  [CREATE DIR] $path" yellow
    fi
}

safe_copy() {
    local src="$1"
    local dst="$2"
    ensure_dir "$(dirname "$dst")"
    if [ "$DRY_RUN" = false ]; then
        cp -f "$src" "$dst"
    fi
    log "  [SYNC FILE] $dst" green
}

safe_delete() {
    local path="$1"
    if [ "$DRY_RUN" = false ]; then
        rm -f "$path"
    fi
    log "  [REMOVE] $path" red
}

# -------------------------
# MANIFEST (THE SOURCE OF TRUTH)
# -------------------------
MANIFEST_DIRS=(
    "adrs"
    "agents"
    "commands"
    "hooks"
    "lib"
    "maven-flow/hooks"
    "maven-flow/config"
    "maven-flow/.claude"
    "shared"
    "skills/flow-convert"
    "skills/workflow"
    "bin"
)

# Declare arrays for file mapping
declare -A MANIFEST_FILES

# Commands
MANIFEST_FILES["commands/flow.md"]=".claude/commands/flow.md"
MANIFEST_FILES["commands/flow-mobile.md"]=".claude/commands/flow-mobile.md"
MANIFEST_FILES["commands/flow-prd.md"]=".claude/commands/flow-prd.md"
MANIFEST_FILES["commands/flow-convert.md"]=".claude/commands/flow-convert.md"
MANIFEST_FILES["commands/flow-update.md"]=".claude/commands/flow-update.md"
MANIFEST_FILES["commands/flow-work-story.md"]=".claude/commands/flow-work-story.md"
MANIFEST_FILES["commands/consolidate-memory.md"]=".claude/commands/consolidate-memory.md"
MANIFEST_FILES["commands/create-story-memory.md"]=".claude/commands/create-story-memory.md"

# Agents
MANIFEST_FILES["agents/development.md"]=".claude/agents/development.md"
MANIFEST_FILES["agents/refactor.md"]=".claude/agents/refactor.md"
MANIFEST_FILES["agents/security.md"]=".claude/agents/security.md"
MANIFEST_FILES["agents/quality.md"]=".claude/agents/quality.md"
MANIFEST_FILES["agents/design.md"]=".claude/agents/design.md"
MANIFEST_FILES["agents/mobile-app.md"]=".claude/agents/mobile-app.md"
MANIFEST_FILES["agents/testing.md"]=".claude/agents/testing.md"
MANIFEST_FILES["agents/debugging-agent.md"]=".claude/agents/debugging-agent.md"
MANIFEST_FILES["agents/Project-Auditor.md"]=".claude/agents/Project-Auditor.md"

# Hooks (legacy - kept for compatibility)
MANIFEST_FILES["hooks/session-save.sh"]=".claude/hooks/session-save.sh"
MANIFEST_FILES["hooks/session-restore.sh"]=".claude/hooks/session-restore.sh"

# Maven Flow Hooks
MANIFEST_FILES["maven-flow/hooks/post-tool-use-quality.sh"]=".claude/maven-flow/hooks/post-tool-use-quality.sh"
MANIFEST_FILES["maven-flow/hooks/stop-comprehensive-check.sh"]=".claude/maven-flow/hooks/stop-comprehensive-check.sh"
MANIFEST_FILES["maven-flow/hooks/incremental-check.sh"]=".claude/maven-flow/hooks/incremental-check.sh"
MANIFEST_FILES["maven-flow/hooks/create-memory.sh"]=".claude/maven-flow/hooks/create-memory.sh"

# Maven Flow Config
MANIFEST_FILES["maven-flow/config/eslint.config.mjs"]=".claude/maven-flow/config/eslint.config.mjs"
MANIFEST_FILES["maven-flow/.claude/settings.json"]=".claude/maven-flow/.claude/settings.json"

# Lib
MANIFEST_FILES["lib/lock.sh"]=".claude/lib/lock.sh"

# Shared docs
MANIFEST_FILES["shared/agent-patterns.md"]=".claude/shared/agent-patterns.md"
MANIFEST_FILES["shared/mcp-tools.md"]=".claude/shared/mcp-tools.md"
MANIFEST_FILES["shared/prd-json-schema.md"]=".claude/shared/prd-json-schema.md"
MANIFEST_FILES["shared/required-mcps.md"]=".claude/shared/required-mcps.md"

# Skills
MANIFEST_FILES["skills/flow-convert/SKILL.md"]=".claude/skills/flow-convert/SKILL.md"
MANIFEST_FILES["skills/workflow/SKILL.md"]=".claude/skills/workflow/SKILL.md"
MANIFEST_FILES["skills/flow-prd-mobile.md"]=".claude/skills/flow-prd-mobile.md"

# ADRs
MANIFEST_FILES["adrs/001-story-level-mcp-assignment.md"]=".claude/adrs/001-story-level-mcp-assignment.md"
MANIFEST_FILES["adrs/002-multi-prd-architecture.md"]=".claude/adrs/002-multi-prd-architecture.md"
MANIFEST_FILES["adrs/003-feature-based-folder-structure.md"]=".claude/adrs/003-feature-based-folder-structure.md"
MANIFEST_FILES["adrs/004-specialist-agent-coordination.md"]=".claude/adrs/004-specialist-agent-coordination.md"

# Bin
MANIFEST_FILES["bin/flow-banner.sh"]=".claude/bin/flow-banner.sh"
MANIFEST_FILES["bin/flow-convert.sh"]=".claude/bin/flow-convert.sh"
MANIFEST_FILES["bin/flow-install-global.sh"]=".claude/bin/flow-install-global.sh"
MANIFEST_FILES["bin/flow-install-user.sh"]=".claude/bin/flow-install-user.sh"
MANIFEST_FILES["bin/flow.sh"]=".claude/bin/flow.sh"
MANIFEST_FILES["bin/flow-status.sh"]=".claude/bin/flow-status.sh"
MANIFEST_FILES["bin/test-locks.sh"]=".claude/bin/test-locks.sh"

# -------------------------
# START
# -------------------------
log ""
log "=============================================" blue
log " Maven Flow Safe Installation" blue
log "=============================================" blue
log "Target: $TARGET_DIR" cyan
log "Dry Run: $DRY_RUN" cyan
log ""

# -------------------------
# STEP 1: ENSURE DIRECTORIES
# -------------------------
log "[STEP 1] Ensuring directories..." yellow
for dir in "${MANIFEST_DIRS[@]}"; do
    ensure_dir "$TARGET_DIR/$dir"
done

# -------------------------
# STEP 2: SYNC FILES (CREATE + OVERWRITE)
# -------------------------
log "[STEP 2] Syncing managed files..." yellow

MANAGED_FILES=()

for target_rel in "${!MANIFEST_FILES[@]}"; do
    source_rel="${MANIFEST_FILES[$target_rel]}"
    src="$SCRIPT_DIR/$source_rel"
    dest="$TARGET_DIR/$target_rel"

    if [ -f "$src" ]; then
        safe_copy "$src" "$dest"
        MANAGED_FILES+=("$(realpath "$dest" 2>/dev/null || readlink -f "$dest" 2>/dev/null || echo "$dest")")
    else
        log "  [SKIP] Source not found: $src" cyan
    fi
done

# Make shell scripts executable
for file in "${MANAGED_FILES[@]}"; do
    if [[ "$file" == *.sh ]]; then
        if [ "$DRY_RUN" = false ]; then
            chmod +x "$file"
        fi
    fi
done

# -------------------------
# STEP 3: REMOVE OBSOLETE MANAGED FILES
# -------------------------
log "[STEP 3] Cleaning obsolete managed files..." yellow

for dir in "${MANIFEST_DIRS[@]}"; do
    full_dir="$TARGET_DIR/$dir"
    if [ ! -d "$full_dir" ]; then
        continue
    fi

    for file in "$full_dir"/*; do
        if [ -f "$file" ]; then
            real_path="$(realpath "$file" 2>/dev/null || readlink -f "$file" 2>/dev/null || echo "$file")"
            # Check if file is in managed list
            is_managed=false
            for managed in "${MANAGED_FILES[@]}"; do
                if [ "$managed" = "$real_path" ]; then
                    is_managed=true
                    break
                fi
            done

            if [ "$is_managed" = false ]; then
                safe_delete "$file"
            fi
        fi
    done
done

# -------------------------
# DONE
# -------------------------
log ""
log "=============================================" blue
log "[OK] Maven Flow Installation Complete" green
log "=============================================" blue
log ""

if [ "$DRY_RUN" = true ]; then
    log "NOTE: Dry-run mode enabled. No changes were made." yellow
fi

# Show usage hints
log "" cyan
log "Usage:" cyan
log "  Claude Code Commands:" cyan
log "    /flow start              # Start autonomous development" gray
log "    /flow status             # Check progress" gray
log "    /flow-prd create ...     # Create PRD" gray
log "    /flow-convert <feature>  # Convert PRD to JSON" gray
log ""
log "  Terminal Commands (via bin/flow):" cyan
log "    flow start [n]           # Start autonomous development" gray
log "    flow status              # Check progress" gray
log "    flow-prd create ...      # Create PRD" gray
log "    flow-convert <feature>   # Convert PRD to JSON" gray
