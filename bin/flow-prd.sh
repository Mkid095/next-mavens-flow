#!/bin/bash
set -e
PROMPT="/flow-prd $*"
claude -q --dangerously-skip-permissions -p "$PROMPT"