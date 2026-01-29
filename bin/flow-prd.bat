@echo off
REM ============================================================================
REM Maven Flow PRD - Windows Batch Wrapper
REM ============================================================================

setlocal

set PS_SCRIPT=%~dp0flow-prd.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

endlocal