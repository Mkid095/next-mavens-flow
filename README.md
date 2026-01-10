# Maven Flow

Autonomous AI development system for Claude Code CLI that implements PRD stories using a comprehensive 10-step workflow. Coordinates specialized agents for foundation, refactoring, quality, and security.

## Overview

Maven Flow combines two powerful concepts:

1. **PRD-Driven Iteration** - Works through user stories one at a time with clean context
2. **Maven 10-Step Workflow** - Comprehensive quality assurance via specialized agents

Each story is implemented by coordinating the right agents for the job, ensuring code quality, architecture compliance, and security best practices.

## Quick Start

```bash
# 1. Create a PRD (just describe what you want - skill invoked automatically)
"Create a PRD for user authentication"

# 2. Convert to JSON (skill invoked automatically)
"Convert the PRD to docs/prd.json format"

# 3. Start autonomous development
/flow start

# 4. Check progress
/flow status
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         /flow start                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Load docs/prd.json                        │
│                   Read docs/progress.txt                     │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
              ┌───────────────┴───────────────┐
              │   For each story where         │
              │   passes: false               │
              └───────────────┬───────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              flow-iteration agent (🟡 Yellow)                │
│              Analyzes story → Determines steps               │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ↓                     ↓                     ↓
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ development   │   │   refactor    │   │   quality     │
│   agent (🟢)  │   │   agent (🔵)  │   │   agent (🟣)  │
│               │   │               │   │               │
│ Steps:        │   │ Steps:        │   │ Steps:        │
│ • Foundation  │   │ • Structure   │   │ • Type safety │
│ • pnpm        │   │ • Modularize  │   │ • @ aliases   │
│ • Data layer  │   │ • UI central  │   │               │
│ • MCP         │   │               │   │               │
└───────────────┘   └───────────────┘   └───────────────┘
                              │
                              ↓
                    ┌───────────────┐
                    │   security    │
                    │   agent (🔴)  │
                    │               │
                    │ Steps:        │
                    │ • Auth flow   │
                    │ • Security    │
                    └───────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Quality Checks                           │
│              • typecheck • lint • tests                     │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Commit: feat: [Story ID] - [Title]            │
│              Update docs/prd.json: passes: true            │
│              Append to docs/progress.txt                    │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
                    ┌─────────────────┐
                    │   All stories   │
                    │   complete?     │
                    └────────┬────────┘
                             │
                    No ──────┴────── Yes
                     │                   │
                     │                   ↓
                     │          <promise>FLOW_COMPLETE</promise>
                     │
                     └── Next iteration
```

## The Maven 10-Step Workflow

| Step | Agent | Color | Description |
|------|-------|-------|-------------|
| **1** | development-agent | 🟢 Green | Import UI with mock data (web) or create from scratch (mobile/desktop) |
| **2** | development-agent | 🟢 Green | Convert package manager from npm to pnpm |
| **3** | refactor-agent | 🔵 Blue | Restructure to feature-based folder structure with ESLint boundaries |
| **4** | refactor-agent | 🔵 Blue | Modularize components larger than 300 lines |
| **5** | quality-agent | 🟣 Purple | Enforce type safety - no 'any' types, use @ import aliases |
| **6** | refactor-agent | 🔵 Blue | Centralize UI components to @shared/ui |
| **7** | development-agent | 🟢 Green | Create centralized data layer with backend setup |
| **8** | security-agent | 🔴 Red | Implement Firebase + Supabase authentication flow |
| **9** | development-agent | 🟢 Green | Integrate MCP servers (web-search, web-reader, chrome, expo, supabase) |
| **10** | security-agent | 🔴 Red | Comprehensive security and error handling validation |

## Feature-Based Architecture

Maven Flow enforces a strict feature-based structure for all new code:

```
src/
├── app/                    # Entry points, routing
├── features/               # Isolated feature modules
│   ├── auth/              # Cannot import from other features
│   │   ├── api/           # API calls
│   │   ├── components/    # Feature components
│   │   ├── hooks/         # Custom hooks
│   │   ├── types/         # TypeScript types
│   │   └── index.ts       # Public exports
│   ├── dashboard/
│   └── [feature-name]/
├── shared/                # Shared code (no feature imports)
│   ├── ui/                # Reusable components
│   ├── api/               # Backend clients (Firebase, Supabase)
│   └── utils/             # Utilities
└── [type: "app"]
```

### Architecture Rules

| From | Can Import To |
|------|---------------|
| features/ | shared/, features/[same feature] |
| shared/ | shared/ only |
| app/ | features/, shared/ |

**Import Aliases (no relative imports):**
- `@shared/*` → `src/shared/*`
- `@features/*` → `src/features/*`
- `@app/*` → `src/app/*`
- `@/*` → `src/*`

## Commands

### `/flow start [max-iterations]`

Begins autonomous iteration through PRD stories.

```bash
/flow start        # Default 10 iterations
/flow start 20     # Custom iteration limit
```

**What happens:**
1. Validates `docs/prd.json` exists
2. Creates/verifies feature branch from PRD's `branchName`
3. For each iteration:
   - Spawns fresh `flow-iteration` agent with clean context
   - Picks highest priority story where `passes: false`
   - Coordinates Maven agents to implement the story
   - Runs quality checks
   - Commits if checks pass
   - Updates PRD and progress

### `/flow status`

Shows current progress and story completion status.

```bash
/flow status
```

**Example output:**
```
Maven Flow Status: 3 of 5 stories complete

Completed:
  ✓ US-001: Add priority field to database
  ✓ US-002: Display priority indicator
  ✓ US-003: Add priority selector

Remaining:
  ○ US-004: Filter tasks by priority (priority: 4)
  ○ US-005: Add priority sorting (priority: 5)

Recent progress:
  [2025-01-10] US-003 - Added priority dropdown
  Agents: refactor-agent, quality-agent
  Files: src/features/task/components/TaskCard.tsx
```

### `/flow continue [max-iterations]`

Resumes from last iteration after interruption.

```bash
/flow continue      # Continue with default iterations
/flow continue 5    # Continue with custom iterations
```

### `/flow reset`

Archives current run and starts fresh.

```bash
/flow reset
```

**What happens:**
1. Prompts for confirmation
2. Archives to `archive/YYYY-MM-DD-feature-name/`
3. Resets `docs/prd.json` and `docs/progress.txt`

### `/flow help`

Displays help information.

## Required Files

| File | Purpose | Location |
|------|---------|----------|
| `prd.json` | PRD with stories, acceptance criteria, pass/fail | `docs/prd.json` |
| `progress.txt` | Append-only log of learnings and context | `docs/progress.txt` |
| `AGENTS.md` | Codebase patterns (auto-updated) | `[directory]/AGENTS.md` |

## Skills

**Note:** Skills in Claude Code are invoked automatically based on your request. You don't type `/skill-name` - just describe what you want and Claude will use the appropriate skill.

### PRD Creation (flow-prd skill)

Describe your feature to create a PRD. The skill will ask clarifying questions and generate a structured document with user stories, acceptance criteria, and dependencies.

**Example:**
- "Create a PRD for user authentication"
- "Write requirements for a task priority feature"

### PRD Conversion (flow-convert skill)

Convert a PRD (markdown or existing format) to `docs/prd.json` format for Maven Flow autonomous execution.

**Example:**
- "Convert this PRD to JSON format"
- "Turn the PRD in tasks/ into prd.json"

Creates `docs/prd.json` with structure:
```json
{
  "projectName": "My App",
  "branchName": "feature/user-profile",
  "stories": [
    {
      "id": "US-001",
      "title": "Story title",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": ["..."]
    }
  ]
}
```

## Automated Quality Hooks

Maven Flow includes automated hooks that enforce quality standards during development.

### PostToolUse Hook

Runs **after every Write/Edit operation:**

```bash
Checks:
  ✅ Relative imports      → should use @ aliases
  ✅ 'any' types           → should use proper types
  ✅ File size >300 lines  → needs modularization
  ✅ Direct API calls      → should use data layer
  ✅ UI duplication        → should use @shared/ui
  ✅ Exposed secrets       → security risk
  ✅ Auth file changes     → security review needed
  ✅ Environment changes   → validation needed
```

### Stop Hook

Runs **before completing work:**

```bash
Checks:
  ✅ Large components (>300 lines)
  ✅ Type safety ('any' count)
  ✅ Import path violations
  ✅ Feature boundary violations (ESLint)
  ✅ UI component duplication
  ✅ Security scan (secrets, tokens, passwords)

Output:
  ✅ PASS    → Ready to commit
  ⚠️  WARN   → Manual review needed
  ❌ BLOCK   → Spawn agents to fix
```

## Firebase + Supabase Auth Architecture

Maven Flow implements a dual-provider authentication system:

```
┌─────────────┐
│   Firebase  │ ← Authentication (email/password)
└──────┬──────┘
       │ Firebase UID
       ↓
┌─────────────┐
│  Supabase   │ ← Profile Data (display_name, avatar_url)
└─────────────┘
```

### Sign Up Flow

```typescript
1. Create Firebase account → returns Firebase UID
2. Create Supabase profile with firebase_uid
3. Return complete user data
```

### Sign In Flow

```typescript
1. Firebase verifies email/password → returns Firebase UID
2. Fetch Supabase profile using firebase_uid
3. Return complete user data
```

## Installation

### Quick Install (Recommended)

Use the installation script for automatic setup:

**Linux/macOS:**
```bash
cd maven-flow
chmod +x install.sh

# Local installation (for current project)
./install.sh --local

# Global installation (available for all projects)
./install.sh --global
```

**Windows:**
```batch
cd maven-flow

# Local installation (for current project)
install.bat --local

# Global installation
install.bat --global
```

### Manual Installation

1. **Copy Maven Flow agents, commands, and hooks to your project:**
   ```bash
   # Create directory structure
   mkdir -p .claude/maven-flow/{agents,commands,hooks,config,.claude}
   mkdir -p .claude/skills

   # Copy components
   cp -r maven-flow/agents/* .claude/maven-flow/agents/
   cp -r maven-flow/commands/* .claude/maven-flow/commands/
   cp -r maven-flow/hooks/* .claude/maven-flow/hooks/
   cp -r maven-flow/config/* .claude/maven-flow/config/
   cp -r maven-flow/.claude/settings.json .claude/maven-flow/.claude/

   # Copy skills to .claude/skills/ (official location)
   cp -r maven-flow/skills/* .claude/skills/
   ```

2. **Make hooks executable:**
   ```bash
   chmod +x .claude/maven-flow/hooks/*.sh
   ```

3. **Verify installation:**
   ```bash
   ls .claude/maven-flow/
   # Should show: agents/, commands/, hooks/, config/, .claude/

   ls .claude/skills/
   # Should show: workflow/, flow-prd/, flow-convert/
   ```

## Configuration

### ESLint Boundaries

Copy `maven-flow/config/eslint.config.mjs` to your project root to enable feature-based architecture enforcement.

### Settings

The hooks are configured in `.claude/maven-flow/.claude/settings.json`. Ensure the paths match your project structure.

## Tips

### Story Size

Keep stories small enough for one context window (~30-50 files max). Larger stories should be broken down.

### Dependencies

Order stories by dependency:
1. Database schema
2. Backend API
3. UI components

### Quality

All quality checks run automatically via hooks. No manual intervention needed.

### Browser Verification

UI stories require browser testing. The flow-iteration agent will:
1. Start dev server
2. Navigate to relevant page
3. Verify changes work as expected
4. Document verification in progress.txt

## Troubleshooting

### Flow not starting?

**Check:**
- `docs/prd.json` exists and is valid JSON
- PRD's `branchName` matches your intended branch
- Run `/flow status` for diagnostics

### Iteration failing?

**Check:**
- `docs/progress.txt` for error messages
- Git log: `git log --oneline -10`
- Resume with `/flow continue`

### Quality hooks not running?

**Check:**
- `.claude/maven-flow/.claude/settings.json` is configured
- Hooks are executable: `chmod +x .claude/maven-flow/hooks/*.sh`
- Bash is available on your system

### Need to start over?

```bash
/flow reset
```

Previous runs are preserved in `archive/YYYY-MM-DD-feature-name/`

## File Structure

```
maven-flow/                              # Distribution directory
├── .claude/
│   └── settings.json                   # Hook configurations
├── agents/
│   ├── flow-iteration.md               # 🟡 Main coordinator
│   ├── development.md                  # 🟢 Foundation, pnpm, data, MCP
│   ├── refactor.md                     # 🔵 Structure, modularize, UI
│   ├── quality.md                      # 🟣 Type safety, imports
│   └── security.md                     # 🔴 Auth flow, security
├── commands/
│   └── flow.md                         # /flow slash command
├── skills/
│   ├── workflow/SKILL.md               # Main workflow
│   ├── flow-prd/SKILL.md               # PRD creation
│   └── flow-convert/SKILL.md           # PRD conversion
├── hooks/
│   ├── post-tool-use-quality.sh        # Real-time quality
│   └── stop-comprehensive-check.sh    # Pre-completion check
├── config/
│   └── eslint.config.mjs               # Feature boundaries
├── install.sh                          # Installation script (Linux/macOS)
├── install.bat                         # Installation script (Windows)
└── README.md                           # This file

# After Installation

.claude/
├── maven-flow/                         # Maven Flow system
│   ├── agents/                         # Specialized agents
│   ├── commands/                       # /flow command
│   ├── hooks/                          # Quality enforcement hooks
│   ├── config/                         # ESLint configuration
│   └── .claude/settings.json           # Hook settings
└── skills/                             # ✅ Skills in official location
    ├── workflow/SKILL.md               # Main workflow skill
    ├── flow-prd/SKILL.md               # PRD creation skill
    └── flow-convert/SKILL.md           # PRD conversion skill
```

## Agent Reference

### flow-iteration (🟡 Yellow)

**Role:** Main coordinator - manages PRD loop and delegates to Maven agents

**Tools:** Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite, AskUserQuestion, Task

**Skills:** workflow

**When to use:** Autonomous story-by-story implementation

### development-agent (🟢 Green)

**Role:** Foundation specialist - sets up projects, integrates services

**Tools:** Full access including Task

**Steps:** 1, 2, 7, 9

**When to use:** Project setup, pnpm conversion, data layer, MCP integrations

### refactor-agent (🔵 Blue)

**Role:** Architecture enforcer - restructures code, enforces boundaries

**Tools:** Full development tools

**Steps:** 3, 4, 6

**When to use:** Feature-based structure, modularization, UI consolidation

### quality-agent (🟣 Purple)

**Role:** Quality validator - enforces standards, auto-fixes violations

**Tools:** Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite

**Permission Mode:** acceptEdits (can auto-fix)

**Steps:** 5 + repetitive checks

**When to use:** Type safety, import validation, quality standards

### security-agent (🔴 Red)

**Role:** Security guardian - validates auth, checks vulnerabilities

**Tools:** Full security tools

**Steps:** 8, 10

**When to use:** Firebase + Supabase auth, security audits

## Example Workflow

```bash
# 1. User wants to add user authentication
User: "Add user login and registration with profile management"

# 2. Create PRD
/flow-prd
→ Generates stories for auth flow, profile UI, password reset

# 3. Convert to JSON
/flow-convert
→ Creates docs/prd.json

# 4. Start autonomous development
/flow start

# 5. Maven Flow automatically:
Iteration 1: US-001 - Firebase authentication setup
  → development-agent: Firebase SDK integration
  → security-agent: Auth flow validation
  → Commit: feat: US-001 - Firebase authentication setup

Iteration 2: US-002 - Supabase profile storage
  → development-agent: Supabase client setup
  → security-agent: Profile schema validation
  → Commit: feat: US-002 - Supabase profile storage

Iteration 3: US-003 - Login form UI
  → refactor-agent: Create features/auth/ structure
  → refactor-agent: Extract LoginForm to @shared/ui
  → quality-agent: Type safety check
  → Browser verification
  → Commit: feat: US-003 - Login form UI

# 6. All stories complete
<promise>FLOW_COMPLETE</promise>
```

## Contributing

Maven Flow is designed to be extensible. To add custom agents or steps:

1. Create new agent file in `maven-flow/agents/`
2. Add unique color in frontmatter
3. Set `model: inherit` and appropriate `permissionMode`
4. Update `flow-iteration.md` to include new agent in coordination
5. Update this README with new agent details

## License

Maven Flow is part of the Ralph autonomous agent pattern implementation.

---

**Maven Flow: Autonomous AI development with comprehensive quality assurance powered by Claude Code CLI**
