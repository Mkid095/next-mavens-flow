#!/bin/bash
# ============================================================================
# Maven Flow Global Uninstaller (Unix/Linux/macOS)
# Removes all installed Maven Flow components
# ============================================================================

set -e

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
    echo ""
    echo -e "${CYAN}+============================================================+${NC}"
    echo -e "${CYAN}|          Maven Flow - Global Uninstallation Manager        |${NC}"
    echo -e "${CYAN}+============================================================+${NC}"
    echo ""
}

# Show header
print_header

echo -e "${BLUE}>> Uninstalling Maven Flow globally${NC}"
echo ""

# Claude directories
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BIN_DIR="$CLAUDE_DIR/bin"

# All Maven Flow files to remove (complete list)
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

FLOW_COMMANDS=(
    "flow.md"
    "flow-prd.md"
    "flow-convert.md"
    "flow-update.md"
    "flow-mobile.md"
    "flow-work-story.md"
    "consolidate-memory.md"
    "create-story-memory.md"
)

FLOW_SKILLS_SUBDIRS=(
    "workflow"
    "flow-convert"
)

FLOW_SKILLS_FILES=(
    "flow-prd-mobile.md"
)

FLOW_HOOKS=(
    "session-save.sh"
    "session-restore.sh"
    "pre-task-flow-validation.js"
    "agent-selector.js"
    "dependency-graph.js"
    "error-reporter.js"
    "memory-cache.js"
    "path-utils.js"
    "prd-utils.js"
    "toon-compress.js"
)

# Shell scripts (bash)
FLOW_SCRIPTS_SH=(
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
    "flow-banner.sh"
)

# PowerShell scripts
FLOW_SCRIPTS_PS1=(
    "flow.ps1"
    "flow-prd.ps1"
    "flow-convert.ps1"
    "flow-update.ps1"
    "flow-status.ps1"
    "flow-continue.ps1"
    "flow-help.ps1"
    "flow-sync.ps1"
    "flow-test.ps1"
    "flow-consolidate.ps1"
    "flow-work-story.ps1"
    "flow-install-global.ps1"
    "Banner.ps1"
    "LockLibrary.ps1"
)

# Batch files
FLOW_SCRIPTS_BAT=(
    "flow.bat"
    "flow-prd.bat"
    "flow-convert.bat"
    "flow-update.bat"
    "flow-status.bat"
    "flow-continue.bat"
    "flow-help.bat"
    "flow-sync.bat"
    "flow-test.bat"
    "flow-consolidate.bat"
    "flow-work-story.bat"
)

# Function to remove files with progress
remove_files() {
    local dir="$1"
    shift
    local files=("$@")
    local removed=0
    local total=${#files[@]}

    for file in "${files[@]}"; do
        local path="$dir/$file"
        if [ -f "$path" ]; then
            rm -f "$path"
            ((removed++))
            echo -e "  ${GRAY}Removed:${NC} ${CYAN}$file${NC}"
        fi
    done

    echo -e "  ${GREEN}Removed $removed file(s)${NC}"
}

# Function to remove directories with progress
remove_dirs() {
    local parent="$1"
    shift
    local dirs=("$@")
    local removed=0

    for dir in "${dirs[@]}"; do
        local path="$parent/$dir"
        if [ -d "$path" ]; then
            rm -rf "$path"
            ((removed++))
            echo -e "  ${GRAY}Removed:${NC} ${CYAN}$dir/${NC}"
        fi
    done

    echo -e "  ${GREEN}Removed $removed director(ies)${NC}"
}

# Step 1: Remove agents
echo -e "${GRAY}  -> Removing Maven Flow agents...${NC}"
if [ -d "$AGENTS_DIR" ]; then
    remove_files "$AGENTS_DIR" "${FLOW_AGENTS[@]}"
else
    echo -e "  ${YELLOW}[!] No agents directory found${NC}"
fi
echo ""

# Step 2: Remove commands
echo -e "${GRAY}  -> Removing Maven Flow commands...${NC}"
if [ -d "$COMMANDS_DIR" ]; then
    remove_files "$COMMANDS_DIR" "${FLOW_COMMANDS[@]}"
else
    echo -e "  ${YELLOW}[!] No commands directory found${NC}"
fi
echo ""

# Step 3: Remove skill subdirectories
echo -e "${GRAY}  -> Removing Maven Flow skill directories...${NC}"
if [ -d "$SKILLS_DIR" ]; then
    remove_dirs "$SKILLS_DIR" "${FLOW_SKILLS_SUBDIRS[@]}"
    remove_files "$SKILLS_DIR" "${FLOW_SKILLS_FILES[@]}"
else
    echo -e "  ${YELLOW}[!] No skills directory found${NC}"
fi
echo ""

# Step 4: Remove hooks
echo -e "${GRAY}  -> Removing Maven Flow hooks...${NC}"
if [ -d "$HOOKS_DIR" ]; then
    remove_files "$HOOKS_DIR" "${FLOW_HOOKS[@]}"
else
    echo -e "  ${YELLOW}[!] No hooks directory found${NC}"
fi
echo ""

# Step 5: Remove scripts (all types)
echo -e "${GRAY}  -> Removing Maven Flow scripts...${NC}"
if [ -d "$BIN_DIR" ]; then
    remove_files "$BIN_DIR" "${FLOW_SCRIPTS_SH[@]}"
    remove_files "$BIN_DIR" "${FLOW_SCRIPTS_PS1[@]}"
    remove_files "$BIN_DIR" "${FLOW_SCRIPTS_BAT[@]}"
else
    echo -e "  ${YELLOW}[!] No bin directory found${NC}"
fi
echo ""

# Step 6: Remove old maven-flow subfolder if exists
echo -e "${GRAY}  -> Removing old maven-flow directory...${NC}"
if [ -d "$CLAUDE_DIR/maven-flow" ]; then
    rm -rf "$CLAUDE_DIR/maven-flow"
    echo -e "  ${GREEN}[OK] Removed old maven-flow directory${NC}"
else
    echo -e "  ${GRAY}[skip] No old maven-flow directory found${NC}"
fi
echo ""

# Step 7: Remove PATH entry from shell config
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
    echo -e "${GRAY}  -> Removing PATH entry from $SHELL_CONFIG...${NC}"
    if grep -q "Maven Flow" "$SHELL_CONFIG" 2>/dev/null; then
        # Create backup
        cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup"
        # Remove lines containing "Maven Flow" and the following line if it's a PATH export
        sed -i '/Maven Flow/d' "$SHELL_CONFIG" 2>/dev/null || \
            grep -v "Maven Flow" "${SHELL_CONFIG}.backup" > "$SHELL_CONFIG"
        rm -f "${SHELL_CONFIG}.backup"
        echo -e "  ${GREEN}[OK] Removed PATH entry${NC}"
    else
        echo -e "  ${GRAY}[skip] No PATH entry found${NC}"
    fi
fi
echo ""

# Success message
echo -e "${CYAN}============================================================${NC}"
echo -e "${GREEN}[OK] Uninstallation complete!${NC}"
echo ""
echo -e "${GRAY}Removed components:${NC}"
echo -e "  ${CYAN}*${NC} ${YELLOW}Agents${NC}        from ~/.claude/agents/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Commands${NC}      from ~/.claude/commands/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Skills${NC}        from ~/.claude/skills/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Hooks${NC}         from ~/.claude/hooks/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Scripts${NC}       from ~/.claude/bin/"
echo ""
if [ -n "$SHELL_CONFIG" ]; then
    echo -e "${YELLOW}[!] Action required:${NC}"
    echo -e "  Run: ${GREEN}source $SHELL_CONFIG${NC}"
    echo -e "  Or restart your terminal to complete removal"
fi
echo ""
echo -e "${CYAN}============================================================${NC}"
