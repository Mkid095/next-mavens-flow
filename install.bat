@echo off
REM ============================================================================
REM Maven Flow Installation Script (Windows)
REM Installs Maven Flow autonomous development system for Claude Code CLI
REM ============================================================================

setlocal enabledelayedexpansion

REM Colors (for Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

REM ============================================================================
REM Helper Functions
REM ============================================================================

:print_header
echo %BLUE%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo %BLUE%  %~1%NC%
echo %BLUE%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo.
exit /b

:print_success
echo %GREEN%✅ %~1%NC%
exit /b

:print_error
echo %RED%❌ %~1%NC%
exit /b

:print_info
echo %CYAN%ℹ️  %~1%NC%
exit /b

:print_step
echo %YELLOW%▶ %~1%NC%
exit /b

REM ============================================================================
REM Installation
REM ============================================================================

call :print_header "Maven Flow Installation"

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

call :print_info "Maven Flow source: %SCRIPT_DIR%"

REM Check if running from maven-flow directory
echo %SCRIPT_DIR% | findstr /i "maven-flow" >nul
if errorlevel 1 (
    call :print_error "Script must be run from maven-flow directory"
    pause
    exit /b 1
)

REM Get installation mode
set "INSTALL_MODE="
set "PROJECT_DIR="

if "%1"=="--local" (
    set "INSTALL_MODE=local"
    set "PROJECT_DIR=%~2"
) else if "%1"=="--global" (
    set "INSTALL_MODE=global"
) else (
    echo.
    echo Select installation mode:
    echo   1^) Local - Install for current project only
    echo   2^) Global - Install globally ^(%%USERPROFILE%%\.claude\^)
    echo.
    set /p CHOICE="Choose [1-2]: "

    if "!CHOICE!"=="1" (
        set "INSTALL_MODE=local"
        set "PROJECT_DIR=%CD%"
    ) else if "!CHOICE!"=="2" (
        set "INSTALL_MODE=global"
    ) else (
        call :print_error "Invalid choice"
        pause
        exit /b 1
    )
)

REM ============================================================================
REM Execute Installation
REM ============================================================================

if "%INSTALL_MODE%"=="local" (
    call :install_local "%PROJECT_DIR%"
) else if "%INSTALL_MODE%"=="global" (
    call :install_global
)

echo.
pause
exit /b

REM ============================================================================
REM Local Installation
REM ============================================================================

:install_local
set "PROJECT_DIR=%~1"
set "TARGET_DIR=%PROJECT_DIR%\.claude\maven-flow"
set "SKILLS_DIR=%PROJECT_DIR%\.claude\skills"

call :print_header "Local Installation"
call :print_info "Target: %PROJECT_DIR%"

REM Create directory structure
call :print_step "Creating directory structure..."
if not exist "%TARGET_DIR%\agents" mkdir "%TARGET_DIR%\agents"
if not exist "%TARGET_DIR%\commands" mkdir "%TARGET_DIR%\commands"
if not exist "%TARGET_DIR%\hooks" mkdir "%TARGET_DIR%\hooks"
if not exist "%TARGET_DIR%\config" mkdir "%TARGET_DIR%\config"
if not exist "%TARGET_DIR%\.claude" mkdir "%TARGET_DIR%\.claude"
if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"
call :print_success "Directory structure created"

REM Copy agents (preserve existing)
call :print_step "Installing agents..."
set "AGENTS_INSTALLED=0"
for %%F in ("%SCRIPT_DIR%\agents\*.md") do (
    set "AGENT_FILE=%%~nxF"
    if not exist "%TARGET_DIR%\agents\!AGENT_FILE!" (
        copy /y "%%F" "%TARGET_DIR%\agents\" >nul
        set /a "AGENTS_INSTALLED+=1"
    ) else (
        call :print_info "  (skipped existing: !AGENT_FILE!)"
    )
)
call :print_success "Agents installed (!AGENTS_INSTALLED! new files)"

REM Copy commands (preserve existing)
call :print_step "Installing commands..."
set "CMDS_INSTALLED=0"
for %%F in ("%SCRIPT_DIR%\commands\*.md") do (
    set "CMD_FILE=%%~nxF"
    if not exist "%TARGET_DIR%\commands\!CMD_FILE!" (
        copy /y "%%F" "%TARGET_DIR%\commands\" >nul
        set /a "CMDS_INSTALLED+=1"
    ) else (
        call :print_info "  (skipped existing: !CMD_FILE!)"
    )
)
call :print_success "Commands installed (!CMDS_INSTALLED! new files)"

REM Copy skills to .claude\skills\ (preserve existing)
call :print_step "Installing skills..."
set "SKILLS_INSTALLED=0"
for /d %%D in ("%SCRIPT_DIR%\skills\*") do (
    set "SKILL_NAME=%%~nxD"
    if not exist "%SKILLS_DIR%\!SKILL_NAME!" mkdir "%SKILLS_DIR%\!SKILL_NAME!"
    if exist "%%D\SKILL.md" (
        if not exist "%SKILLS_DIR%\!SKILL_NAME!\SKILL.md" (
            copy /y "%%D\SKILL.md" "%SKILLS_DIR%\!SKILL_NAME!\" >nul
            set /a "SKILLS_INSTALLED+=1"
        ) else (
            call :print_info "  (skipped existing: !SKILL_NAME!/SKILL.md)"
        )
    )
)
call :print_success "Skills installed (!SKILLS_INSTALLED! new skills)"

REM Copy hooks
call :print_step "Installing hooks..."
copy /y "%SCRIPT_DIR%\hooks\*.sh" "%TARGET_DIR%\hooks\" >nul
call :print_success "Hooks installed"

REM Copy config
call :print_step "Installing configuration..."
copy /y "%SCRIPT_DIR%\config\*.mjs" "%TARGET_DIR%\config\" >nul
call :print_success "Configuration installed"

REM Copy settings.json
call :print_step "Installing settings.json..."
copy /y "%SCRIPT_DIR%\.claude\settings.json" "%TARGET_DIR%\.claude\" >nul
call :print_success "Settings configured"

REM Create docs directory
call :print_step "Creating docs directory..."
if not exist "%PROJECT_DIR%\docs" mkdir "%PROJECT_DIR%\docs"

REM Create prd.json if not exists
if not exist "%PROJECT_DIR%\docs\prd.json" (
    (
        echo {
        echo   "projectName": "My Project",
        echo   "branchName": "main",
        echo   "stories": []
        echo }
    ) > "%PROJECT_DIR%\docs\prd.json"
    call :print_info "Created docs/prd.json"
)

REM Create progress.txt if not exists
if not exist "%PROJECT_DIR%\docs\progress.txt" (
    (
        echo # Maven Flow Progress
        echo.
        echo ## Codebase Patterns
        echo ^<!-- Add reusable patterns discovered during development --^>
        echo.
        echo ## Iteration Log
        echo ^<!-- Progress from each iteration will be appended here --^>
    ) > "%PROJECT_DIR%\docs\progress.txt"
    call :print_info "Created docs/progress.txt"
)

call :print_success "Documentation structure created"

REM Update settings.json for local paths
powershell -Command "(Get-Content '%TARGET_DIR%\.claude\settings.json') -replace 'bash maven-flow/hooks/', 'bash .claude/maven-flow/hooks/' | Set-Content '%TARGET_DIR%\.claude\settings.json'" >nul 2>&1
call :print_success "Settings paths updated for local installation"

call :installation_summary "%TARGET_DIR%" "%PROJECT_DIR%" local
exit /b

REM ============================================================================
REM Global Installation
REM ============================================================================

:install_global
set "TARGET_DIR=%USERPROFILE%\.claude\maven-flow"
set "SKILLS_DIR=%USERPROFILE%\.claude\skills"

call :print_header "Global Installation"
call :print_info "Target: %TARGET_DIR%"

REM Create directory structure
call :print_step "Creating directory structure..."
if not exist "%TARGET_DIR%\agents" mkdir "%TARGET_DIR%\agents"
if not exist "%TARGET_DIR%\commands" mkdir "%TARGET_DIR%\commands"
if not exist "%TARGET_DIR%\hooks" mkdir "%TARGET_DIR%\hooks"
if not exist "%TARGET_DIR%\config" mkdir "%TARGET_DIR%\config"
if not exist "%TARGET_DIR%\.claude" mkdir "%TARGET_DIR%\.claude"
if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"
call :print_success "Directory structure created"

REM Copy agents (preserve existing)
call :print_step "Installing agents..."
set "AGENTS_INSTALLED=0"
for %%F in ("%SCRIPT_DIR%\agents\*.md") do (
    set "AGENT_FILE=%%~nxF"
    if not exist "%TARGET_DIR%\agents\!AGENT_FILE!" (
        copy /y "%%F" "%TARGET_DIR%\agents\" >nul
        set /a "AGENTS_INSTALLED+=1"
    ) else (
        call :print_info "  (skipped existing: !AGENT_FILE!)"
    )
)
call :print_success "Agents installed (!AGENTS_INSTALLED! new files)"

REM Copy commands (preserve existing)
call :print_step "Installing commands..."
set "CMDS_INSTALLED=0"
for %%F in ("%SCRIPT_DIR%\commands\*.md") do (
    set "CMD_FILE=%%~nxF"
    if not exist "%TARGET_DIR%\commands\!CMD_FILE!" (
        copy /y "%%F" "%TARGET_DIR%\commands\" >nul
        set /a "CMDS_INSTALLED+=1"
    ) else (
        call :print_info "  (skipped existing: !CMD_FILE!)"
    )
)
call :print_success "Commands installed (!CMDS_INSTALLED! new files)"

REM Copy skills to ~/.claude/skills/ (preserve existing)
call :print_step "Installing skills..."
set "SKILLS_INSTALLED=0"
for /d %%D in ("%SCRIPT_DIR%\skills\*") do (
    set "SKILL_NAME=%%~nxD"
    if not exist "%SKILLS_DIR%\!SKILL_NAME!" mkdir "%SKILLS_DIR%\!SKILL_NAME!"
    if exist "%%D\SKILL.md" (
        if not exist "%SKILLS_DIR%\!SKILL_NAME!\SKILL.md" (
            copy /y "%%D\SKILL.md" "%SKILLS_DIR%\!SKILL_NAME!\" >nul
            set /a "SKILLS_INSTALLED+=1"
        ) else (
            call :print_info "  (skipped existing: !SKILL_NAME!/SKILL.md)"
        )
    )
)
call :print_success "Skills installed (!SKILLS_INSTALLED! new skills)"

REM Copy hooks
call :print_step "Installing hooks..."
copy /y "%SCRIPT_DIR%\hooks\*.sh" "%TARGET_DIR%\hooks\" >nul
call :print_success "Hooks installed"

REM Copy config
call :print_step "Installing configuration..."
copy /y "%SCRIPT_DIR%\config\*.mjs" "%TARGET_DIR%\config\" >nul
call :print_success "Configuration installed"

REM Copy settings.json
call :print_step "Installing settings.json..."
copy /y "%SCRIPT_DIR%\.claude\settings.json" "%TARGET_DIR%\.claude" >nul
call :print_success "Settings configured"

REM Update settings.json for global paths
powershell -Command "(Get-Content '%TARGET_DIR%\.claude\settings.json') -replace 'bash maven-flow/hooks/', 'bash ~/.claude/maven-flow/hooks/' | Set-Content '%TARGET_DIR%\.claude\settings.json'" >nul 2>&1
call :print_success "Settings paths updated for global installation"

call :installation_summary "%TARGET_DIR%" "" global
exit /b

REM ============================================================================
REM Installation Summary
REM ============================================================================

:installation_summary
set "TARGET_DIR=%~1"
set "PROJECT_DIR=%~2"
set "MODE=%~3"

call :print_header "Installation Complete"

echo.
echo %PURPLE%┌─────────────────────────────────────────────────────────┐%NC%
echo %PURPLE%│                    Maven Flow                           │%NC%
echo %PURPLE%│              Autonomous AI Development                │%NC%
echo %PURPLE%└─────────────────────────────────────────────────────────┘%NC%
echo.

if "%MODE%"=="local" (
    echo %GREEN%✓ Installed locally for:%NC% %PROJECT_DIR%
    echo.
    echo %CYAN%Next steps:%NC%
    echo   1. Create a PRD: /flow-prd
    echo   2. Convert to JSON: /flow-convert
    echo   3. Start development: /flow start
    echo.
    echo %CYAN%Files created:%NC%
    echo   • .claude\maven-flow\    (Maven Flow system)
    echo   • docs\prd.json          (Product requirements)
    echo   • docs\progress.txt      (Progress tracking)
) else (
    echo %GREEN%✓ Installed globally:%NC% %USERPROFILE%\.claude\maven-flow\
    echo.
    echo %CYAN%Next steps for each project:%NC%
    echo   1. cd to your project directory
    echo   2. Create docs\ directory with prd.json and progress.txt
    echo   3. Run: /flow start
    echo.
    echo %CYAN%Available commands:%NC%
    echo   • /flow start          - Start autonomous development
    echo   • /flow status         - Check progress
    echo   • /flow continue       - Resume from last iteration
    echo   • /flow-prd            - Create Product Requirements Document
    echo   • /flow-convert        - Convert PRD to JSON format
)

echo.
echo %CYAN%Documentation:%NC%
echo   README.md: %SCRIPT_DIR%\README.md
echo.

echo %YELLOW%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo %YELLOW%  🚀 Maven Flow is ready! Start building with AI autonomy.%NC%
echo %YELLOW%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo.

exit /b
