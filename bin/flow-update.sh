#!/bin/bash
set -e
PROMPT="/flow-update $*"
claude -q --dangerously-skip-permissions -p "$PROMPT"