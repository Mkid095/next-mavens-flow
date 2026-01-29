@echo off
REM ============================================================================
REM Maven Flow Help - Windows Batch Wrapper
REM ============================================================================

setlocal

set PS_SCRIPT=%~dp0flow-help.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal
