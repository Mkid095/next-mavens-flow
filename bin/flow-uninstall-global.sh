#!/bin/bash
# ============================================================================
# Maven Flow Global Uninstaller
# Removes all installed Maven Flow components
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

# Animation frames for loading
SPINNER=('⠋' '⠙' '⠸' '⠴' '⠦' '⠇' '⠏')

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Maven Flow - Global Uninstallation Manager        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Spinner for operations
show_spinner() {
    local pid=$1
    local message=$2

    while kill -0 $pid 2>/dev/null; do
        for frame in "${SPINNER[@]}"; do
            echo -ne "\r${CYAN}  [${frame}] ${message}...${NC}"
            sleep 0.1
        done
    done
    wait $pid 2>/dev/null
    echo -e "\r${GREEN}[✓]${NC} ${message}                    "
}

# Show header
print_header

echo -e "${BLUE}▶ Uninstalling Maven Flow globally${NC}"
echo ""

# Claude directories
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BIN_DIR="$CLAUDE_DIR/bin"

# Maven Flow files to remove (updated 2026)
FLOW_AGENTS=("development.md" "quality.md" "testing.md" "refactor.md" "security.md" "design.md" "mobile-app.md" "Project-Auditor.md" "debugging-agent.md")
FLOW_COMMANDS=("flow.md" "flow-prd.md" "consolidate-memory.md" "create-story-memory.md" "flow-convert.md")
FLOW_SKILLS_SUBDIRS=("workflow" "flow-convert")
FLOW_SKILLS_FILES=("flow-prd-mobile.md")
FLOW_HOOKS=("session-save.sh" "session-restore.sh" "pre-task-flow-validation.js" "agent-selector.js" "dependency-graph.js" "error-reporter.js" "memory-cache.js" "path-utils.js" "prd-utils.js" "toon-compress.js" "retry-manager.js")
FLOW_SCRIPTS=("flow.sh" "flow-prd.sh" "flow-convert.sh" "flow-install-global.sh" "flow-uninstall-global.sh" "flow-sync.sh" "flow-status.sh" "flow-continue.sh" "flow-help.sh" "flow-update.sh" "maven-flow-wrapper.sh" "flow.ps1" "flow-prd.ps1" "flow-convert.ps1" "flow-continue.ps1" "flow-help.ps1" "flow-status.ps1" "flow-sync.ps1" "flow-update.ps1" "flow-install-global.ps1" "flow-uninstall-global.ps1")

# Step 1: Remove agents
echo -e "${GRAY}  → Removing Maven Flow agents...${NC}"
removed_any=false
for agent in "${FLOW_AGENTS[@]}"; do
    if [ -f "$AGENTS_DIR/$agent" ]; then
        (rm -f "$AGENTS_DIR/$agent") &
        show_spinner $! "Removing Maven Flow agents"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow agents found                    "
fi

# Step 2: Remove commands
echo -e "${GRAY}  → Removing Maven Flow commands...${NC}"
removed_any=false
for cmd in "${FLOW_COMMANDS[@]}"; do
    if [ -f "$COMMANDS_DIR/$cmd" ]; then
        (rm -f "$COMMANDS_DIR/$cmd") &
        show_spinner $! "Removing Maven Flow commands"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow commands found                    "
fi

# Step 3: Remove skill subdirectories
echo -e "${GRAY}  → Removing Maven Flow skill directories...${NC}"
removed_any=false
for skill_dir in "${FLOW_SKILLS_SUBDIRS[@]}"; do
    if [ -d "$SKILLS_DIR/$skill_dir" ]; then
        (rm -rf "$SKILLS_DIR/$skill_dir") &
        show_spinner $! "Removing Maven Flow skill directories"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow skill directories found                    "
fi

# Step 4: Remove skill files
echo -e "${GRAY}  → Removing Maven Flow skill files...${NC}"
removed_any=false
for skill in "${FLOW_SKILLS_FILES[@]}"; do
    if [ -f "$SKILLS_DIR/$skill" ]; then
        (rm -f "$SKILLS_DIR/$skill") &
        show_spinner $! "Removing Maven Flow skill files"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow skill files found                    "
fi

# Step 5: Remove hooks
echo -e "${GRAY}  → Removing Maven Flow hooks...${NC}"
removed_any=false
for hook in "${FLOW_HOOKS[@]}"; do
    if [ -f "$HOOKS_DIR/$hook" ]; then
        (rm -f "$HOOKS_DIR/$hook") &
        show_spinner $! "Removing Maven Flow hooks"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow hooks found                    "
fi

# Step 6: Remove scripts
echo -e "${GRAY}  → Removing Maven Flow scripts...${NC}"
removed_any=false
for script in "${FLOW_SCRIPTS[@]}"; do
    if [ -f "$BIN_DIR/$script" ]; then
        (rm -f "$BIN_DIR/$script") &
        show_spinner $! "Removing Maven Flow scripts"
        removed_any=true
        break
    fi
done
if [ "$removed_any" = false ]; then
    echo -e "\r${YELLOW}[!]${NC} No Maven Flow scripts found                    "
fi

# Step 7: Remove old maven-flow subfolder if exists
echo -e "${GRAY}  → Removing old maven-flow directory...${NC}"
if [ -d "$CLAUDE_DIR/maven-flow" ]; then
    (rm -rf "$CLAUDE_DIR/maven-flow") &
    show_spinner $! "Removing old maven-flow directory"
else
    echo -e "\r${GREEN}[✓]${NC} No old maven-flow directory found                    "
fi

# Step 8: Remove PATH entry from shell config
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

echo -e "${GRAY}  → Removing PATH entry from $SHELL_CONFIG...${NC}"
if grep -q "Maven Flow" "$SHELL_CONFIG" 2>/dev/null; then
    # Create a temp file without Maven Flow entries
    (grep -v "Maven Flow" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp" 2>/dev/null && mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG") &
    show_spinner $! "Removing PATH entry"
else
    echo -e "\r${GREEN}[✓]${NC} No PATH entry found                    "
fi

# Success message
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[✓] Uninstallation complete!${NC}"
echo ""
echo -e "${GRAY}Removed components:${NC}"
echo -e "  ${CYAN}*${NC} ${YELLOW}Agents${NC}        from ~/.claude/agents/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Commands${NC}      from ~/.claude/commands/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Skills${NC}        from ~/.claude/skills/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Hooks${NC}         from ~/.claude/hooks/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Scripts${NC}       from ~/.claude/bin/"
echo ""
echo -e "${YELLOW}[!] Action required:${NC}"
echo -e "  Run: ${GREEN}source $SHELL_CONFIG${NC}"
echo -e "  Or restart your terminal to complete removal"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
