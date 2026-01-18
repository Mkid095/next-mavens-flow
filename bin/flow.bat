@echo off
setlocal enabledelayedexpansion
set COMMAND=%1
set "ARGS=%*"
claude -q --dangerously-skip-permissions -p "/flow %COMMAND% %ARGS%"