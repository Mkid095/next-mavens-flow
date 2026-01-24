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
    "agents"
    "commands"
    "maven-flow/hooks"
    "maven-flow/config"
    "maven-flow/.claude"
    "skills"
)

declare -A MANIFEST_FILES
MANIFEST_FILES["agents"]=".claude/agents/*.md"
MANIFEST_FILES["commands"]=".claude/commands/*.md"
MANIFEST_FILES["maven-flow/hooks"]=".claude/maven-flow/hooks/*.sh"
MANIFEST_FILES["maven-flow/config"]=".claude/maven-flow/config/*.mjs"
MANIFEST_FILES["maven-flow/.claude/settings.json"]=".claude/maven-flow/.claude/settings.json"

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
    source_glob="$SCRIPT_DIR/${MANIFEST_FILES[$target_rel]}"

    if ls $source_glob 1> /dev/null 2>&1; then
        for src in $source_glob; do
            if [ -f "$src" ]; then
                if [[ "$target_rel" == *.json ]]; then
                    dest="$TARGET_DIR/$target_rel"
                else
                    dest="$TARGET_DIR/$target_rel/$(basename "$src")"
                fi

                safe_copy "$src" "$dest"
                MANAGED_FILES+=("$(realpath "$dest" 2>/dev/null || readlink -f "$dest" 2>/dev/null || echo "$dest")")
            fi
        done
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
