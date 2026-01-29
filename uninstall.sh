#!/bin/bash
# ============================================================================
# Maven Flow Uninstaller (Bash Version)
# ============================================================================
# Removes Maven Flow components from Claude folders
# ============================================================================

set -e

# -------------------------
# CONFIG
# -------------------------
HOME_CLAUDE="$HOME/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

# Maven Flow agents to remove (updated 2026)
FLOW_AGENTS=(
    "development.md"
    "quality.md"
    "testing.md"
    "refactor.md"
    "security.md"
    "design.md"
    "mobile-app.md"
    "Project-Auditor.md"
    "debugging-agent.md"
)

# Maven Flow commands to remove (updated 2026)
FLOW_COMMANDS=(
    "flow.md"
    "flow-mobile.md"
    "flow-prd.md"
    "flow-convert.md"
    "flow-update.md"
    "flow-work-story.md"
    "consolidate-memory.md"
    "create-story-memory.md"
)

# Maven Flow skill subdirectories to remove
FLOW_SKILL_SUBDIRS=(
    "flow-convert"
    "workflow"
)

# Maven Flow skill files to remove
FLOW_SKILL_FILES=(
    "flow-prd-mobile.md"
)

# Maven Flow hooks to remove (legacy)
FLOW_HOOKS=(
    "session-save.sh"
    "session-restore.sh"
)

# Maven Flow lib files to remove
FLOW_LIB_FILES=(
    "lock.sh"
)

# Maven Flow shared docs to remove
FLOW_SHARED_FILES=(
    "agent-patterns.md"
    "mcp-tools.md"
    "prd-json-schema.md"
    "required-mcps.md"
)

# Maven Flow ADRs to remove
FLOW_ADR_FILES=(
    "001-story-level-mcp-assignment.md"
    "002-multi-prd-architecture.md"
    "003-feature-based-folder-structure.md"
    "004-specialist-agent-coordination.md"
)

# Maven Flow bin files to remove from .claude/bin
FLOW_BIN_FILES=(
    "flow-banner.sh"
)

# Terminal commands to remove from ~/.local/bin
FLOW_COMMANDS=(
    "flow"
    "flow-convert"
    "flow-prd"
    "flow-status"
    "flow-update"
)

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
        gray)   echo -e "\033[0;90m$1\033[0m" ;;
        *)      echo "$1" ;;
    esac
}

remove_file_if_exists() {
    local file="$1"
    local label="$2"
    if [ -f "$file" ]; then
        rm -f "$file"
        log "  [REMOVE] $file" green
        return 0
    else
        return 1
    fi
}

remove_dir_if_exists() {
    local dir="$1"
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        log "  [REMOVE] $dir" green
        return 0
    else
        return 1
    fi
}

# -------------------------
# CONFIRM
# -------------------------
log ""
log "=============================================" blue
log " Maven Flow Uninstaller" blue
log "=============================================" blue
log ""
log "This will remove Maven Flow components from:" yellow
log "  $HOME_CLAUDE" cyan
log ""
log "Components to be removed:" yellow
log "  - Agents from ~/.claude/agents/" gray
log "  - Commands from ~/.claude/commands/" gray
log "  - Skills from ~/.claude/skills/" gray
log "  - Hooks from ~/.claude/hooks/" gray
log "  - Maven Flow from ~/.claude/maven-flow/" gray
log "  - Lib files from ~/.claude/lib/" gray
log "  - Shared docs from ~/.claude/shared/" gray
log "  - ADRs from ~/.claude/adrs/" gray
log "  - Bin files from ~/.claude/bin/" gray
log ""

read -p "Continue? (y/N): " -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log "Uninstall cancelled." yellow
    exit 0
fi

# -------------------------
# REMOVE AGENTS
# -------------------------
log "[STEP 1] Removing Maven Flow agents..." yellow
agents_dir="$HOME_CLAUDE/agents"
removed_count=0
for agent in "${FLOW_AGENTS[@]}"; do
    agent_path="$agents_dir/$agent"
    if remove_file_if_exists "$agent_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow agents found" gray
fi

# -------------------------
# REMOVE COMMANDS
# -------------------------
log "[STEP 2] Removing Maven Flow commands..." yellow
commands_dir="$HOME_CLAUDE/commands"
removed_count=0
for cmd in "${FLOW_COMMANDS[@]}"; do
    cmd_path="$commands_dir/$cmd"
    if remove_file_if_exists "$cmd_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow commands found" gray
fi

# -------------------------
# REMOVE SKILL DIRECTORIES
# -------------------------
log "[STEP 3] Removing Maven Flow skill directories..." yellow
skills_dir="$HOME_CLAUDE/skills"
removed_count=0
for skill_dir in "${FLOW_SKILL_SUBDIRS[@]}"; do
    skill_path="$skills_dir/$skill_dir"
    if remove_dir_if_exists "$skill_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow skill directories found" gray
fi

# -------------------------
# REMOVE SKILL FILES
# -------------------------
log "[STEP 4] Removing Maven Flow skill files..." yellow
removed_count=0
for skill in "${FLOW_SKILL_FILES[@]}"; do
    skill_path="$skills_dir/$skill"
    if remove_file_if_exists "$skill_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow skill files found" gray
fi

# -------------------------
# REMOVE HOOKS
# -------------------------
log "[STEP 5] Removing Maven Flow hooks..." yellow
hooks_dir="$HOME_CLAUDE/hooks"
removed_count=0
for hook in "${FLOW_HOOKS[@]}"; do
    hook_path="$hooks_dir/$hook"
    if remove_file_if_exists "$hook_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow hooks found" gray
fi

# -------------------------
# REMOVE MAVEN-FLOW SUBDIRECTORY
# -------------------------
log "[STEP 6] Removing Maven Flow subdirectory..." yellow
maven_flow_dir="$HOME_CLAUDE/maven-flow"
if remove_dir_if_exists "$maven_flow_dir"; then
    :
else
    log "  No maven-flow directory found" gray
fi

# -------------------------
# REMOVE LIB FILES
# -------------------------
log "[STEP 7] Removing Maven Flow lib files..." yellow
lib_dir="$HOME_CLAUDE/lib"
removed_count=0
for lib_file in "${FLOW_LIB_FILES[@]}"; do
    lib_path="$lib_dir/$lib_file"
    if remove_file_if_exists "$lib_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow lib files found" gray
fi

# -------------------------
# REMOVE SHARED DOCS
# -------------------------
log "[STEP 8] Removing Maven Flow shared docs..." yellow
shared_dir="$HOME_CLAUDE/shared"
removed_count=0
for shared_file in "${FLOW_SHARED_FILES[@]}"; do
    shared_path="$shared_dir/$shared_file"
    if remove_file_if_exists "$shared_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow shared docs found" gray
fi

# -------------------------
# REMOVE ADRS
# -------------------------
log "[STEP 9] Removing Maven Flow ADRs..." yellow
adrs_dir="$HOME_CLAUDE/adrs"
removed_count=0
for adr_file in "${FLOW_ADR_FILES[@]}"; do
    adr_path="$adrs_dir/$adr_file"
    if remove_file_if_exists "$adr_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow ADRs found" gray
fi

# -------------------------
# REMOVE BIN FILES
# -------------------------
log "[STEP 10] Removing Maven Flow bin files..." yellow
bin_dir="$HOME_CLAUDE/bin"
removed_count=0
for bin_file in "${FLOW_BIN_FILES[@]}"; do
    bin_path="$bin_dir/$bin_file"
    if remove_file_if_exists "$bin_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No Maven Flow bin files found" gray
fi

# -------------------------
# REMOVE TERMINAL COMMANDS FROM ~/.local/bin
# -------------------------
log "[STEP 11] Removing terminal commands from ~/.local/bin..." yellow
local_bin="$HOME/.local/bin"
removed_count=0
for cmd in "${FLOW_COMMANDS[@]}"; do
    cmd_path="$local_bin/$cmd"
    if remove_file_if_exists "$cmd_path"; then
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    log "  No terminal commands found in ~/.local/bin" gray
fi

# -------------------------
# DONE
# -------------------------
log ""
log "=============================================" blue
log "[OK] Maven Flow Uninstall Complete" green
log "=============================================" blue
log ""
log "Note: You may need to restart Claude Code for changes to take effect." yellow
log ""
