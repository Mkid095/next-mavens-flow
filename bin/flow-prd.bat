@echo off
setlocal enabledelayedexpansion
set "ARGS=%*"
claude -q --dangerously-skip-permissions "/flow-prd %ARGS%"