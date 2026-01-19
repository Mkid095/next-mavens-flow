@echo off
REM ============================================================================
REM Maven Flow Sync - Windows Batch Wrapper
REM ============================================================================

setlocal

if "%1"=="pull" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flow-sync.ps1" -Direction Pull
) else if "%1"=="push" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flow-sync.ps1" -Direction Push
) else if "%1"=="status" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flow-sync.ps1" -Direction Status
) else if "%1"=="force" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flow-sync.ps1" -Direction Pull -Force
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flow-sync.ps1" %*
)

endlocal
