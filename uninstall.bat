@echo off
REM ============================================================================
REM Maven Flow Uninstaller
REM ============================================================================
REM This batch file calls the PowerShell uninstaller for full functionality
REM ============================================================================
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"

echo =============================================
echo  Maven Flow Uninstallation
echo =============================================
echo.
echo This will remove Maven Flow components from:
echo   %USERPROFILE%\.claude\
echo.
echo Components to be removed:
echo   - Agents from ~/.claude/agents/
echo   - Commands from ~/.claude/commands/
echo   - Skills from ~/.claude/skills/
echo   - Hooks from ~/.claude/hooks/
echo   - Scripts from ~/.claude/bin/
echo   - Old maven-flow subfolder (if exists)
echo.
set /p confirm="Continue? (y/N): "

if /i not "%confirm%"=="y" (
    echo.
    echo Uninstall cancelled.
    pause
    exit /b 0
)

echo.
echo Launching PowerShell uninstaller...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%uninstall.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] Uninstallation failed. Please check the errors above.
    pause
    exit /b 1
)

echo.
echo [OK] Uninstallation complete. You can close this window.
pause
exit /b 0
