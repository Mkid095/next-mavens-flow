@echo off
REM ============================================================================
REM Maven Flow Continue - Windows Batch Wrapper
REM ============================================================================

setlocal

set PS_SCRIPT=%~dp0flow-continue.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal
