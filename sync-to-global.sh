#!/bin/bash
# Sync local to global Claude installation

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Syncing local Maven Flow to global ~/.claude${NC}"
echo "======================================================"
echo ""

# Define paths
SRC_DIR="$(pwd)"
DST_DIR="$HOME/.claude"

# Files and directories to sync
SYNC_ITEMS=(
  ".claude/commands/flow.md"
  ".claude/commands/flow-mobile.md"
  ".claude/shared/agent-patterns.md"
  ".claude/shared/mcp-tools.md"
  ".claude/shared/prd-json-schema.md"
  ".claude/shared/required-mcps.md"
  ".claude/agents/development.md"
  ".claude/agents/refactor.md"
  ".claude/agents/security.md"
  ".claude/agents/quality.md"
  ".claude/agents/design.md"
  ".claude/agents/mobile-app.md"
  ".claude/agents/testing.md"
  ".claude/agents/debugging-agent.md"
  ".claude/agents/Project-Auditor.md"
  ".claude/maven-flow/hooks/stop-comprehensive-check.sh"
  ".claude/maven-flow/hooks/post-tool-use-quality.sh"
  ".claude/maven-flow/.claude/settings.json"
  ".claude/skills/flow-convert/SKILL.md"
  ".claude/skills/flow-prd/SKILL.md"
  ".claude/skills/workflow/SKILL.md"
  ".claude/adrs/001-story-level-mcp-assignment.md"
  ".claude/adrs/002-multi-prd-architecture.md"
  ".claude/adrs/003-feature-based-folder-structure.md"
  ".claude/adrs/004-specialist-agent-coordination.md"
)

# Sync each item
for item in "${SYNC_ITEMS[@]}"; do
  src="$SRC_DIR/$item"
  dst="$DST_DIR/$item"
  
  # Create destination directory
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"
  
  # Copy file
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    # Fix line endings for shell scripts
    if [[ "$src" == *.sh ]]; then
      sed -i 's/\r$//' "$dst"
      chmod +x "$dst"
    fi
    echo -e "${GREEN}✓${NC} Synced: $item"
  else
    echo "⚠ Source not found: $src"
  fi
done

echo ""
echo -e "${GREEN}Sync complete!${NC}"
