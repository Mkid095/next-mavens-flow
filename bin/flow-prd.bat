@echo off
setlocal enabledelayedexpansion
set "ARGS=%*"
claude -q --dangerously-skip-permissions -p "/flow-prd %ARGS%"