@echo off
REM ============================================================================
REM Maven Flow - Windows Batch Wrapper
REM ============================================================================

setlocal

set BIN_DIR=%~dp0
set PS_SCRIPT=%BIN_DIR%flow.ps1

rem Pass all arguments to PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal
