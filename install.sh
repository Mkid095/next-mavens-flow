#!/bin/bash
# ============================================================================
# Maven Flow Installation Script
# Installs Maven Flow autonomous development system for Claude Code CLI
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print with color
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

# ============================================================================
# Installation Options
# ============================================================================
INSTALL_MODE=""
PROJECT_DIR=""
GLOBAL_INSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            INSTALL_MODE="local"
            PROJECT_DIR="$2"
            shift 2
            ;;
        --global)
            INSTALL_MODE="global"
            shift
            ;;
        --help|-h)
            echo "Maven Flow Installation Script"
            echo ""
            echo "Usage:"
            echo "  ./install.sh --local <project-dir>    # Install for specific project"
            echo "  ./install.sh --global                 # Install globally for all projects"
            echo ""
            echo "Examples:"
            echo "  ./install.sh --local /path/to/project"
            echo "  ./install.sh --global"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# Preflight Checks
# ============================================================================
print_header "Maven Flow Installation"

# Check if Maven Flow directory exists
MAVEN_FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$MAVEN_FLOW_DIR" ]; then
    print_error "Maven Flow directory not found"
    exit 1
fi

print_info "Maven Flow source: $MAVEN_FLOW_DIR"

# Check for required commands
print_step "Checking requirements..."

MISSING_CMDS=()
for cmd in rg jq; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_CMDS+=($cmd)
    fi
done

if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
    print_error "Missing required commands: ${MISSING_CMDS[*]}"
    print_info "Install with: apt-get install ripgrep jq (Linux)"
    print_info "               brew install ripgrep jq (macOS)"
    exit 1
fi

print_success "All requirements met"

# ============================================================================
# Determine Install Mode
# ============================================================================
if [ -z "$INSTALL_MODE" ]; then
    echo ""
    echo "Select installation mode:"
    echo "  1) Local - Install for current project only"
    echo "  2) Global - Install globally (~/.claude/)"
    echo ""
    read -p "Choose [1-2]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[1]$ ]]; then
        INSTALL_MODE="local"
        PROJECT_DIR="$(pwd)"
    elif [[ $REPLY =~ ^[2]$ ]]; then
        INSTALL_MODE="global"
    else
        print_error "Invalid choice"
        exit 1
    fi
fi

# ============================================================================
# Installation Functions
# ============================================================================

install_local() {
    local project_dir="$1"
    local target_dir="$project_dir/.claude/maven-flow"
    local skills_dir="$project_dir/.claude/skills"

    print_header "Local Installation"
    print_info "Target: $project_dir"

    # Create target directory
    print_step "Creating directory structure..."
    mkdir -p "$target_dir"/{agents,commands,hooks,config,.claude}
    mkdir -p "$skills_dir"
    print_success "Directory structure created"

    # Copy agents (use -n to not overwrite existing)
    print_step "Installing agents..."
    local agents_installed=0
    for agent_file in "$MAVEN_FLOW_DIR/agents/"*.md; do
        local agent_name=$(basename "$agent_file")
        if [ ! -f "$target_dir/agents/$agent_name" ]; then
            cp "$agent_file" "$target_dir/agents/"
            ((agents_installed++))
        else
            print_info "  (skipped existing: $agent_name)"
        fi
    done
    print_success "Agents installed ($agents_installed new files)"

    # Copy commands (use -n to not overwrite existing)
    print_step "Installing commands..."
    local commands_installed=0
    for cmd_file in "$MAVEN_FLOW_DIR/commands/"*.md; do
        local cmd_name=$(basename "$cmd_file")
        if [ ! -f "$target_dir/commands/$cmd_name" ]; then
            cp "$cmd_file" "$target_dir/commands/"
            ((commands_installed++))
        else
            print_info "  (skipped existing: $cmd_name)"
        fi
    done
    print_success "Commands installed ($commands_installed new files)"

    # Copy skills to .claude/skills/ (official location) - preserve existing
    print_step "Installing skills..."
    local skills_installed=0
    for skill_dir in "$MAVEN_FLOW_DIR/skills"/*; do
        if [ -d "$skill_dir" ]; then
            local skill_name=$(basename "$skill_dir")
            mkdir -p "$skills_dir/$skill_name"

            # Copy SKILL.md only if not exists
            if [ -f "$skill_dir/SKILL.md" ] && [ ! -f "$skills_dir/$skill_name/SKILL.md" ]; then
                cp "$skill_dir/SKILL.md" "$skills_dir/$skill_name/"
                ((skills_installed++))
            elif [ -f "$skills_dir/$skill_name/SKILL.md" ]; then
                print_info "  (skipped existing: $skill_name/SKILL.md)"
            fi
        fi
    done
    print_success "Skills installed ($skills_installed new skills)"

    # Copy hooks
    print_step "Installing hooks..."
    cp "$MAVEN_FLOW_DIR/hooks/"*.sh "$target_dir/hooks/"
    chmod +x "$target_dir/hooks/"*.sh
    print_success "Hooks installed and made executable"

    # Copy config
    print_step "Installing configuration..."
    cp "$MAVEN_FLOW_DIR/config/"*.mjs "$target_dir/config/"
    print_success "Configuration installed"

    # Copy settings.json
    print_step "Installing settings.json..."
    cp "$MAVEN_FLOW_DIR/.claude/settings.json" "$target_dir/.claude/"
    print_success "Settings configured"

    # Create docs directory
    print_step "Creating docs directory..."
    mkdir -p "$project_dir/docs"

    # Create placeholder files
    if [ ! -f "$project_dir/docs/prd.json" ]; then
        cat > "$project_dir/docs/prd.json" << 'EOF'
{
  "projectName": "My Project",
  "branchName": "main",
  "stories": []
}
EOF
        print_info "Created docs/prd.json"
    fi

    if [ ! -f "$project_dir/docs/progress.txt" ]; then
        cat > "$project_dir/docs/progress.txt" << 'EOF'
# Maven Flow Progress

## Codebase Patterns
<!-- Add reusable patterns discovered during development -->

## Iteration Log
<!-- Progress from each iteration will be appended here -->
EOF
        print_info "Created docs/progress.txt"
    fi

    print_success "Documentation structure created"

    # Update settings.json path for local install
    sed -i "s|bash maven-flow/hooks/|bash .claude/maven-flow/hooks/|g" "$target_dir/.claude/settings.json"
    print_success "Settings paths updated for local installation"
}

install_global() {
    local target_dir="$HOME/.claude/maven-flow"
    local skills_dir="$HOME/.claude/skills"

    print_header "Global Installation"
    print_info "Target: $target_dir"

    # Create target directory
    print_step "Creating directory structure..."
    mkdir -p "$target_dir"/{agents,commands,hooks,config,.claude}
    mkdir -p "$skills_dir"
    print_success "Directory structure created"

    # Copy agents (preserve existing)
    print_step "Installing agents..."
    local agents_installed=0
    for agent_file in "$MAVEN_FLOW_DIR/agents/"*.md; do
        local agent_name=$(basename "$agent_file")
        if [ ! -f "$target_dir/agents/$agent_name" ]; then
            cp "$agent_file" "$target_dir/agents/"
            ((agents_installed++))
        else
            print_info "  (skipped existing: $agent_name)"
        fi
    done
    print_success "Agents installed ($agents_installed new files)"

    # Copy commands (preserve existing)
    print_step "Installing commands..."
    local commands_installed=0
    for cmd_file in "$MAVEN_FLOW_DIR/commands/"*.md; do
        local cmd_name=$(basename "$cmd_file")
        if [ ! -f "$target_dir/commands/$cmd_name" ]; then
            cp "$cmd_file" "$target_dir/commands/"
            ((commands_installed++))
        else
            print_info "  (skipped existing: $cmd_name)"
        fi
    done
    print_success "Commands installed ($commands_installed new files)"

    # Copy skills to ~/.claude/skills/ (preserve existing)
    print_step "Installing skills..."
    local skills_installed=0
    for skill_dir in "$MAVEN_FLOW_DIR/skills"/*; do
        if [ -d "$skill_dir" ]; then
            local skill_name=$(basename "$skill_dir")
            mkdir -p "$skills_dir/$skill_name"

            # Copy SKILL.md only if not exists
            if [ -f "$skill_dir/SKILL.md" ] && [ ! -f "$skills_dir/$skill_name/SKILL.md" ]; then
                cp "$skill_dir/SKILL.md" "$skills_dir/$skill_name/"
                ((skills_installed++))
            elif [ -f "$skills_dir/$skill_name/SKILL.md" ]; then
                print_info "  (skipped existing: $skill_name/SKILL.md)"
            fi
        fi
    done
    print_success "Skills installed ($skills_installed new skills)"

    # Copy hooks
    print_step "Installing hooks..."
    cp "$MAVEN_FLOW_DIR/hooks/"*.sh "$target_dir/hooks/"
    chmod +x "$target_dir/hooks/"*.sh
    print_success "Hooks installed and made executable"

    # Copy config
    print_step "Installing configuration..."
    cp "$MAVEN_FLOW_DIR/config/"*.mjs "$target_dir/config/"
    print_success "Configuration installed"

    # Copy settings.json
    print_step "Installing settings.json..."
    cp "$MAVEN_FLOW_DIR/.claude/settings.json" "$target_dir/.claude/"
    print_success "Settings configured"

    # Update settings.json path for global install
    sed -i "s|bash maven-flow/hooks/|bash ~/.claude/maven-flow/hooks/|g" "$target_dir/.claude/settings.json"
    print_success "Settings paths updated for global installation"
}

# ============================================================================
# Execute Installation
# ============================================================================

if [ "$INSTALL_MODE" = "local" ]; then
    install_local "$PROJECT_DIR"
elif [ "$INSTALL_MODE" = "global" ]; then
    install_global
fi

# ============================================================================
# Verification
# ============================================================================
print_header "Installation Verification"

# Check if files exist
print_step "Verifying installation..."

if [ "$INSTALL_MODE" = "local" ]; then
    TARGET_DIR="$PROJECT_DIR/.claude/maven-flow"
else
    TARGET_DIR="$HOME/.claude/maven-flow"
fi

# Count installed files
AGENT_COUNT=$(ls -1 "$TARGET_DIR/agents/"*.md 2>/dev/null | wc -l)
COMMAND_COUNT=$(ls -1 "$TARGET_DIR/commands/"*.md 2>/dev/null | wc -l)
if [ "$INSTALL_MODE" = "local" ]; then
    SKILL_COUNT=$(find "$PROJECT_DIR/.claude/skills/" -name "SKILL.md" 2>/dev/null | wc -l)
else
    SKILL_COUNT=$(find "$HOME/.claude/skills/" -name "SKILL.md" 2>/dev/null | wc -l)
fi
HOOK_COUNT=$(ls -1 "$TARGET_DIR/hooks/"*.sh 2>/dev/null | wc -l)

print_success "Verification complete"
echo ""
echo "  Agents:   $AGENT_COUNT/5"
echo "  Commands: $COMMAND_COUNT/1"
echo "  Skills:   $SKILL_COUNT/3"
echo "  Hooks:    $HOOK_COUNT/2"
echo ""

# ============================================================================
# Summary
# ============================================================================
print_header "Installation Complete"

echo ""
echo -e "${PURPLE}┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${PURPLE}│                    Maven Flow                           │${NC}"
echo -e "${PURPLE}│              Autonomous AI Development                │${NC}"
echo -e "${PURPLE}└─────────────────────────────────────────────────────────┘${NC}"
echo ""

if [ "$INSTALL_MODE" = "local" ]; then
    echo -e "${GREEN}✓ Installed locally for:${NC} $PROJECT_DIR"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Create a PRD: /flow-prd"
    echo "  2. Convert to JSON: /flow-convert"
    echo "  3. Start development: /flow start"
    echo ""
    echo -e "${CYAN}Files created:${NC}"
    echo "  • .claude/maven-flow/    (Maven Flow system)"
    echo "  • docs/prd.json          (Product requirements)"
    echo "  • docs/progress.txt      (Progress tracking)"
else
    echo -e "${GREEN}✓ Installed globally:${NC} ~/.claude/maven-flow/"
    echo ""
    echo -e "${CYAN}Next steps for each project:${NC}"
    echo "  1. cd to your project directory"
    echo "  2. Create docs/ directory with prd.json and progress.txt"
    echo "  3. Run: /flow start"
    echo ""
    echo -e "${CYAN}Available commands:${NC}"
    echo "  • /flow start          - Start autonomous development"
    echo "  • /flow status         - Check progress"
    echo "  • /flow continue       - Resume from last iteration"
    echo "  • /flow-prd            - Create Product Requirements Document"
    echo "  • /flow-convert        - Convert PRD to JSON format"
fi

echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  README.md: $MAVEN_FLOW_DIR/README.md"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  🚀 Maven Flow is ready! Start building with AI autonomy.${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
