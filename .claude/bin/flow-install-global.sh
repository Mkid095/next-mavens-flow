#!/bin/bash
# ============================================================================
# Maven Flow Global Installation Script
# ============================================================================
# Installs Maven Flow commands to /usr/local/bin for system-wide access
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
echo -e "${BLUE}  Maven Flow Global Installation${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script requires root privileges to install to /usr/local/bin${NC}"
    echo ""
    echo "Please run with sudo:"
    echo "  sudo ./flow-install-global.sh"
    echo ""
    echo "Or install to user bin:"
    echo "  ./flow-install-global.sh --user"
    echo ""
    exit 1
fi

# Installation target
TARGET_DIR="/usr/local/bin"

# Commands to install
COMMANDS=(
    "flow"
    "flow-convert"
    "flow-prd"
    "flow-status"
    "flow-update"
)

# Backup existing commands
echo -e "${CYAN}[Step 1] Backing up existing commands...${NC}"
BACKUP_DIR="/tmp/maven-flow-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

backed_up=0
for cmd in "${COMMANDS[@]}"; do
    if [ -L "$TARGET_DIR/$cmd" ] || [ -f "$TARGET_DIR/$cmd" ]; then
        cp "$TARGET_DIR/$cmd" "$BACKUP_DIR/"
        echo -e "${GREEN}  [BACKUP] $cmd${NC}"
        ((backed_up++))
    fi
done

if [ $backed_up -eq 0 ]; then
    echo -e "${GRAY}  No existing commands to backup${NC}"
    rm -rf "$BACKUP_DIR"
else
    echo -e "${GRAY}  Backup location: $BACKUP_DIR${NC}"
fi

echo ""

# Remove existing symlinks/scripts
echo -e "${CYAN}[Step 2] Removing old installations...${NC}"
for cmd in "${COMMANDS[@]}"; do
    if [ -L "$TARGET_DIR/$cmd" ] || [ -f "$TARGET_DIR/$cmd" ]; then
        rm -f "$TARGET_DIR/$cmd"
        echo -e "${GREEN}  [REMOVE] $cmd${NC}"
    fi
done

echo ""

# Create new symlinks
echo -e "${CYAN}[Step 3] Installing commands to $TARGET_DIR...${NC}"

# Use the user's .claude/bin as the source
SOURCE_DIR="/home/ken/.claude/bin"

for cmd in "${COMMANDS[@]}"; do
    if [ -f "$SOURCE_DIR/$cmd.sh" ]; then
        ln -s "$SOURCE_DIR/$cmd.sh" "$TARGET_DIR/$cmd"
        chmod +x "$TARGET_DIR/$cmd"
        echo -e "${GREEN}  [INSTALL] $cmd -> $SOURCE_DIR/$cmd.sh${NC}"
    else
        echo -e "${YELLOW}  [SKIP] $cmd (source not found: $SOURCE_DIR/$cmd.sh)${NC}"
    fi
done

echo ""

# Verify installation
echo -e "${CYAN}[Step 4] Verifying installation...${NC}"
installed=0
missing=0

for cmd in "${COMMANDS[@]}"; do
    if [ -L "$TARGET_DIR/$cmd" ] || [ -f "$TARGET_DIR/$cmd" ]; then
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

if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
    echo -e "${GRAY}  Backup: $BACKUP_DIR${NC}"
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
    echo -e "${YELLOW}  Note: Commands are now available system-wide.${NC}"
    echo -e "${YELLOW}        Log out and back in to refresh your PATH.${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}  Some commands failed to install.${NC}"
    echo ""
    exit 1
fi
