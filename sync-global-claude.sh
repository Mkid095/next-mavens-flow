#!/bin/bash
# Sync Maven Flow files from local repo to global ~/.claude directory

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Maven Flow - Sync to Global ~/.claude${NC}"
echo "========================================"
echo ""

# Define source and destination (absolute paths)
SRC_DIR="/c/Users/HomePC/Documents/GitHub/next-mavens-flow"
DST_DIR="/c/Users/HomePC/.claude"

# Files to sync
FILES=(
  ".claude/commands/flow.md"
  ".claude/shared/mcp-tools.md"
  ".claude/shared/agent-patterns.md"
  ".claude/agents/development.md"
  ".claude/agents/refactor.md"
  ".claude/agents/security.md"
  ".claude/agents/quality.md"
  ".claude/adrs/001-story-level-mcp-assignment.md"
  ".claude/skills/flow-convert/SKILL.md"
)

# Sync each file
for file in "${FILES[@]}"; do
  src="$SRC_DIR/$file"
  dst="$DST_DIR/$file"
  
  # Create destination directory if it doesn't exist
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"
  
  # Copy file
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    echo -e "${GREEN}✓${NC} Synced: $file"
  else
    echo "⚠ Source not found: $src"
  fi
done

echo ""
echo -e "${GREEN}Sync complete!${NC}"
echo ""
echo "Files synced from: $SRC_DIR"
echo "              to: $DST_DIR"
