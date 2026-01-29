@echo off
REM ============================================================================
REM Maven Flow Safe Installer (Manifest-Based, Idempotent)
REM ============================================================================
REM This batch file calls the PowerShell installer for full functionality
REM ============================================================================
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"

echo =============================================
echo  Maven Flow Safe Installation
echo =============================================
echo.
echo Launching PowerShell installer...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] Installation failed. Please check the errors above.
    pause
    exit /b 1
)

echo.
echo [OK] Installation complete.
echo.
echo [!] ACTION REQUIRED:
echo   Run this command to start using Maven Flow immediately:
echo     . $PROFILE
echo.
echo   Or restart your PowerShell session.
echo.
pause
exit /b 0
