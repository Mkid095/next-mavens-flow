@echo off
setlocal enabledelayedexpansion
set FEATURE=%1
claude -q --dangerously-skip-permissions -p "/flow-convert %FEATURE%"