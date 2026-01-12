#!/bin/bash
# Convert all PRD files in a directory from old MCP format to new format

if [ -z "$1" ]; then
  echo "Usage: ./convert-all-prs.sh <docs-directory>"
  echo ""
  echo "Example:"
  echo "  ./convert-all-prs.sh docs"
  echo "  ./convert-all-prs.sh ../soostori/docs"
  exit 1
fi

DOCS_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Converting all PRD files in: $DOCS_DIR"
echo "================================================"
echo ""

# Find all prd-*.json files and convert them
find "$DOCS_DIR" -name "prd-*.json" -type f | while read -r file; do
  node "$SCRIPT_DIR/convert-prd-mcp.js" "$file"
done

echo ""
echo "✨ All PRD files converted!"
