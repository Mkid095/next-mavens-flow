#!/bin/bash
# ============================================================================
# Maven Flow - Shell Wrapper
# ============================================================================

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the PowerShell script with all arguments
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/flow.ps1" "$@"
