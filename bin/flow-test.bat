@echo off
REM ============================================================================
REM Maven Flow Test - Windows Batch Wrapper
REM ============================================================================

setlocal

set PS_SCRIPT=%~dp0flow-test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal
