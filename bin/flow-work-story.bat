@echo off
REM ============================================================================
REM Maven Flow - Work on Single Story
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"

echo.
echo +============================================================+
echo ^|         Maven Flow - Single Story Workflow               ^|
echo +============================================================+
echo.

if "%~1"=="" (
    echo Usage:
    echo   flow-work-story ^<story-id^>     Work on a specific story
    echo.
    echo Example:
    echo   flow-work-story us-001         Work on story US-001
    echo.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%flow-work-story.ps1" %*

if errorlevel 1 (
    echo.
    echo [ERROR] Story work failed
    echo.
    exit /b 1
)

exit /b 0
