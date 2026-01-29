@echo off
REM ============================================================================
REM Maven Flow Status - Windows Batch Wrapper
REM ============================================================================

setlocal

set PS_SCRIPT=%~dp0flow-status.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal
