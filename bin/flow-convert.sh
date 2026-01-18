#!/bin/bash
set -e
FEATURE=$1
claude -q --dangerously-skip-permissions -p "/flow-convert $FEATURE"