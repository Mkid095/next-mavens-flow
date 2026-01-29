#!/bin/bash
# ============================================================================
# Maven Flow User Installation Script (No Root Required)
# ============================================================================
# Installs Maven Flow commands to ~/.local/bin for current user
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Maven Flow User Installation${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Installation target
USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"

echo -e "${CYAN}Installing to: ${YELLOW}$USER_BIN${NC}"
echo ""

# Commands to install
COMMANDS=(
    "flow"
    "flow-convert"
    "flow-prd"
    "flow-status"
    "flow-update"
)

# Source directory
SOURCE_DIR="$PROJECT_ROOT/bin"

# Remove existing symlinks/scripts
echo -e "${CYAN}[Step 1] Removing old installations...${NC}"
for cmd in "${COMMANDS[@]}"; do
    if [ -L "$USER_BIN/$cmd" ] || [ -f "$USER_BIN/$cmd" ]; then
        rm -f "$USER_BIN/$cmd"
        echo -e "${GREEN}  [REMOVE] $cmd${NC}"
    fi
done

echo ""

# Create symlinks to actual scripts in .claude/bin
echo -e "${CYAN}[Step 2] Installing commands...${NC}"

for cmd in "${COMMANDS[@]}"; do
    script_path="$PROJECT_ROOT/.claude/bin/$cmd.sh"
    if [ -f "$script_path" ]; then
        ln -s "$script_path" "$USER_BIN/$cmd"
        chmod +x "$USER_BIN/$cmd"
        echo -e "${GREEN}  [INSTALL] $cmd -> $script_path${NC}"
    else
        echo -e "${YELLOW}  [SKIP] $cmd (source not found)${NC}"
    fi
done

echo ""

# Verify ~/.local/bin is in PATH
echo -e "${CYAN}[Step 3] Checking PATH...${NC}"
if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
    echo -e "${YELLOW}  [WARN] $USER_BIN is not in your PATH${NC}"
    echo ""
    echo -e "${GRAY}  Add this to your ~/.bashrc or ~/.zshrc:${NC}"
    echo -e "${CYAN}    export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
    echo -e "${GRAY}  Then run: source ~/.bashrc (or source ~/.zshrc)${NC}"
else
    echo -e "${GREEN}  [OK] $USER_BIN is in your PATH${NC}"
fi

echo ""

# Verify installation
echo -e "${CYAN}[Step 4] Verifying installation...${NC}"
installed=0
missing=0

for cmd in "${COMMANDS[@]}"; do
    if [ -L "$USER_BIN/$cmd" ] || [ -f "$USER_BIN/$cmd" ]; then
        echo -e "${GREEN}  [OK] $cmd${NC}"
        ((installed++))
    else
        echo -e "${RED}  [MISSING] $cmd${NC}"
        ((missing++))
    fi
done

echo ""

# Summary
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${GREEN}  Installed: $installed command(s)${NC}"

if [ $missing -gt 0 ]; then
    echo -e "${RED}  Missing: $missing command(s)${NC}"
fi

echo ""

if [ $missing -eq 0 ]; then
    echo -e "${GREEN}  All commands installed successfully!${NC}"
    echo ""
    echo -e "${CYAN}  Available commands:${NC}"
    for cmd in "${COMMANDS[@]}"; do
        echo -e "${GRAY}    - $cmd${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Commands will be available in new terminal sessions.${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}  Some commands failed to install.${NC}"
    echo ""
    exit 1
fi
