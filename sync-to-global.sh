#!/bin/bash
# Sync local to global Claude installation

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Syncing local Maven Flow to global ~/.claude${NC}"
echo "======================================================"
echo ""

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR"
DST_DIR="$HOME/.claude"

# Files and directories to sync
SYNC_ITEMS=(
  # Commands
  ".claude/commands/flow.md"
  ".claude/commands/flow-mobile.md"
  ".claude/commands/flow-prd.md"
  ".claude/commands/flow-convert.md"
  ".claude/commands/flow-update.md"
  ".claude/commands/flow-work-story.md"
  ".claude/commands/consolidate-memory.md"
  ".claude/commands/create-story-memory.md"

  # Agents
  ".claude/agents/development.md"
  ".claude/agents/refactor.md"
  ".claude/agents/security.md"
  ".claude/agents/quality.md"
  ".claude/agents/design.md"
  ".claude/agents/mobile-app.md"
  ".claude/agents/testing.md"
  ".claude/agents/debugging-agent.md"
  ".claude/agents/Project-Auditor.md"

  # Hooks (legacy)
  ".claude/hooks/session-save.sh"
  ".claude/hooks/session-restore.sh"

  # Maven Flow Hooks
  ".claude/maven-flow/hooks/post-tool-use-quality.sh"
  ".claude/maven-flow/hooks/stop-comprehensive-check.sh"
  ".claude/maven-flow/hooks/incremental-check.sh"
  ".claude/maven-flow/hooks/create-memory.sh"

  # Maven Flow Config
  ".claude/maven-flow/config/eslint.config.mjs"
  ".claude/maven-flow/.claude/settings.json"

  # Lib
  ".claude/lib/lock.sh"

  # Shared docs
  ".claude/shared/agent-patterns.md"
  ".claude/shared/mcp-tools.md"
  ".claude/shared/prd-json-schema.md"
  ".claude/shared/required-mcps.md"

  # Skills
  ".claude/skills/flow-convert/SKILL.md"
  ".claude/skills/workflow/SKILL.md"
  ".claude/skills/flow-prd-mobile.md"

  # ADRs
  ".claude/adrs/001-story-level-mcp-assignment.md"
  ".claude/adrs/002-multi-prd-architecture.md"
  ".claude/adrs/003-feature-based-folder-structure.md"
  ".claude/adrs/004-specialist-agent-coordination.md"

  # Bin (.claude/bin - internal scripts)
  ".claude/bin/flow-banner.sh"
  ".claude/bin/flow-convert.sh"
  ".claude/bin/flow-install-global.sh"
  ".claude/bin/flow-install-user.sh"

  # Bin (project bin/ - main wrapper scripts to ~/.claude/bin)
  "bin/flow.sh:.claude/bin/flow.sh"
  "bin/flow-status.sh:.claude/bin/flow-status.sh"
  "bin/test-locks.sh:.claude/bin/test-locks.sh"
)

# Sync each item
for item in "${SYNC_ITEMS[@]}"; do
  # Check if item uses source:destination format
  if [[ "$item" == *:* ]]; then
    src_path="${item%%:*}"
    dst_rel="${item#*:}"
    src="$SRC_DIR/$src_path"
    dst="$DST_DIR/$dst_rel"
    item_label="$src_path -> $dst_rel"
  else
    src="$SRC_DIR/$item"
    dst="$DST_DIR/$item"
    item_label="$item"
  fi

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
    echo -e "${GREEN}✓${NC} Synced: $item_label"
  else
    echo -e "${YELLOW}⚠${NC} Source not found: $src"
  fi
done

echo ""
echo -e "${GREEN}Sync complete!${NC}"
