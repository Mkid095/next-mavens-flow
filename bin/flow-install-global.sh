#!/bin/bash
# ============================================================================
# Maven Flow Global Installer
# Installs Flow components directly to Claude folders
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
    echo -e "${CYAN}║           Maven Flow - Global Installation Manager          ║${NC}"
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

echo -e "${BLUE}▶ Installing Maven Flow globally${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Claude directories
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BIN_DIR="$CLAUDE_DIR/bin"

# Step 1: Remove old maven-flow subfolder if exists
echo -e "${GRAY}  → Cleaning up old installation...${NC}"
if [ -d "$CLAUDE_DIR/maven-flow" ]; then
    (rm -rf "$CLAUDE_DIR/maven-flow") &
    show_spinner $! "Removing old maven-flow directory"
else
    echo -e "\r${GREEN}[✓]${NC} No old installation to remove                    "
fi

# Step 2: Create required directories
echo -e "${GRAY}  → Creating Claude directories...${NC}"
(mkdir -p "$AGENTS_DIR" "$COMMANDS_DIR" "$SKILLS_DIR" "$HOOKS_DIR" "$BIN_DIR") &
show_spinner $! "Creating Claude directories"

# Step 3: Install agents
echo -e "${GRAY}  → Installing agents...${NC}"
if [ -d "$PROJECT_DIR/.claude/agents" ]; then
    (cp -f "$PROJECT_DIR"/.claude/agents/*.md "$AGENTS_DIR/" 2>/dev/null) &
    show_spinner $! "Installing agents"
else
    echo -e "\r${YELLOW}[!]${NC} No agents directory found                    "
fi

# Step 4: Install commands
echo -e "${GRAY}  → Installing commands...${NC}"
if [ -d "$PROJECT_DIR/.claude/commands" ]; then
    (cp -f "$PROJECT_DIR"/.claude/commands/*.md "$COMMANDS_DIR/" 2>/dev/null) &
    show_spinner $! "Installing commands"
else
    echo -e "\r${YELLOW}[!]${NC} No commands directory found                    "
fi

# Step 5: Install skills
echo -e "${GRAY}  → Installing skills...${NC}"
if [ -d "$PROJECT_DIR/.claude/skills" ]; then
    # Create skill subdirectories as needed
    for skill_dir in "$PROJECT_DIR"/.claude/skills/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            mkdir -p "$SKILLS_DIR/$skill_name"
            cp -f "$skill_dir"/*.md "$SKILLS_DIR/$skill_name/" 2>/dev/null || true
        fi
    done
    # Also copy top-level skill files
    (cp -f "$PROJECT_DIR"/.claude/skills/*.md "$SKILLS_DIR/" 2>/dev/null || true) &
    show_spinner $! "Installing skills"
else
    echo -e "\r${YELLOW}[!]${NC} No skills directory found                    "
fi

# Step 6: Install hooks
echo -e "${GRAY}  → Installing hooks...${NC}"
if [ -d "$PROJECT_DIR/.claude/hooks" ]; then
    (cp -f "$PROJECT_DIR"/.claude/hooks/* "$HOOKS_DIR/" 2>/dev/null) &
    show_spinner $! "Installing hooks"
else
    echo -e "\r${YELLOW}[!]${NC} No hooks directory found                    "
fi

# Step 7: Copy shell scripts
echo -e "${GRAY}  → Installing shell scripts...${NC}"
(cp -f "$SCRIPT_DIR"/*.sh "$BIN_DIR/" 2>/dev/null) &
show_spinner $! "Installing shell scripts"

# Step 7b: Copy bin utilities (banner, etc)
echo -e "${GRAY}  → Installing bin utilities...${NC}"
if [ -d "$PROJECT_DIR/.claude/bin" ]; then
    (cp -f "$PROJECT_DIR"/.claude/bin/*.sh "$BIN_DIR/" 2>/dev/null) &
    show_spinner $! "Installing bin utilities"
else
    echo -e "\r${YELLOW}[!]${NC} No .claude/bin directory found                    "
fi

# Step 8: Make scripts executable
echo -e "${GRAY}  → Setting executable permissions...${NC}"
(chmod +x "$BIN_DIR"/*.sh 2>/dev/null) &
show_spinner $! "Setting executable permissions"

# Step 9: Add to PATH if not already
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

echo -e "${GRAY}  → Updating PATH configuration...${NC}"

if ! grep -q "$BIN_DIR" "$SHELL_CONFIG" 2>/dev/null; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Maven Flow - Added by flow-install-global.sh" >> "$SHELL_CONFIG"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_CONFIG"
    echo -e "\r${GREEN}[✓]${NC} Added to PATH in $SHELL_CONFIG                    "
else
    echo -e "\r${GREEN}[✓]${NC} Already in PATH configuration                    "
fi

# Success message
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[✓] Installation complete!${NC}"
echo ""
echo -e "${GRAY}Installed components:${NC}"
echo -e "  ${CYAN}*${NC} ${YELLOW}Agents${NC}        → ~/.claude/agents/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Commands${NC}      → ~/.claude/commands/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Skills${NC}        → ~/.claude/skills/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Hooks${NC}         → ~/.claude/hooks/"
echo -e "  ${CYAN}*${NC} ${YELLOW}Scripts${NC}       → ~/.claude/bin/"
echo ""
echo -e "${GRAY}Available commands:${NC}"
echo -e "  ${CYAN}*${NC} ${YELLOW}flow${NC}          - Main Maven Flow command"
echo -e "  ${CYAN}*${NC} ${YELLOW}flow-prd${NC}      - Generate PRDs"
echo -e "  ${CYAN}*${NC} ${YELLOW}flow-convert${NC}  - Convert PRDs to JSON"
echo -e "  ${CYAN}*${NC} ${YELLOW}flow-update${NC}   - Update Maven Flow"
echo ""
echo -e "${YELLOW}[!] Action required:${NC}"
echo -e "  Run: ${GREEN}source $SHELL_CONFIG${NC}"
echo -e "  Or restart your terminal to use the new commands"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
