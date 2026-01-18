# Maven Flow

Autonomous AI development system for Claude Code CLI that implements PRD stories using a comprehensive 10-step workflow. Coordinates specialized agents for foundation, refactoring, quality, and security.

## Overview

Maven Flow combines powerful concepts for autonomous development:

1. **Multi-PRD Architecture** - Each feature has its own PRD file, processed independently
2. **PRD-Driven Iteration** - Works through user stories one at a time with clean context
3. **Maven 10-Step Workflow** - Comprehensive quality assurance via specialized agents

Each story is implemented by coordinating the right agents for the job, ensuring code quality, architecture compliance, and security best practices.

## Quick Start

```bash
# 1. Create a PRD for a feature (skill invoked automatically)
"Create a PRD for user authentication"

# 2. Convert to feature-specific JSON (skill invoked automatically)
"Convert the PRD to docs/prd-user-auth.json"

# 3. Start autonomous development
/flow start

# 4. Check progress across all features
/flow status
```

**Multi-PRD Workflow:**
- Each feature gets its own `docs/prd-[feature-name].json` file
- The flow scans for all PRD files and processes incomplete ones
- Create multiple PRDs for different features, flow handles them in order

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         /flow start                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Scan docs/ for prd-*.json files                │
│              Check each for incomplete stories              │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
              ┌───────────────┴───────────────┐
              │   Select first incomplete PRD  │
              │   (e.g., prd-task-priority)    │
              └───────────────┬───────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│           Load docs/prd-task-priority.json                  │
│           Read docs/progress-task-priority.txt              │
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
│    Update docs/prd-task-priority.json: passes: true        │
│    Append to docs/progress-task-priority.txt               │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ↓
                    ┌─────────────────┐
                    │   All stories   │
                    │   in PRD        │
                    │   complete?     │
                    └────────┬────────┘
                             │
                    No ──────┴────── Yes
                     │                   │
                     │                   ↓
                     │          Move to next PRD
                     │          (if any incomplete)
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
1. Scans `docs/` for all `prd-*.json` files
2. Finds the first PRD with incomplete stories (`passes: false`)
3. Creates/verifies feature branch from that PRD's `branchName`
4. For each iteration:
   - Spawns fresh `flow-iteration` agent with clean context
   - Picks highest priority story where `passes: false`
   - Coordinates Maven agents to implement the story
   - Runs quality checks
   - Commits if checks pass
   - Updates that PRD and its progress file
5. When PRD is complete, moves to next incomplete PRD
6. Continues until all PRDs are complete

### `/flow status`

Shows current progress and story completion status for all PRDs.

```bash
/flow status
```

**Example output:**
```
Maven Flow Status: 3 PRD files found

prd-task-priority.json (3/5 complete)
  ✓ US-001: Add priority field to database
  ✓ US-002: Display priority indicator
  ✓ US-003: Add priority selector
  ○ US-004: Filter tasks by priority (priority: 4)
  ○ US-005: Add priority sorting (priority: 5)

prd-user-auth.json (0/4 complete)
  ○ US-001: Firebase authentication setup
  ○ US-002: Supabase profile storage
  ○ US-003: Login form UI
  ○ US-004: Password reset flow

prd-notifications.json (4/4 complete) ✅

Current focus: prd-task-priority.json
```

### `/flow continue [max-iterations]`
```bash
/flow continue              # Continue with current PRD
/flow continue 5            # Continue with 5 more iterations
/flow continue task-priority # Continue specific PRD
```

Resumes from last iteration after interruption. Can specify which PRD to work on.

### `/flow reset [prd-name]`
```bash
/flow reset              # Prompts to select PRD
/flow reset task-priority  # Reset specific PRD
```

Archives current PRD run and starts fresh. Other PRDs remain unaffected.

### `/flow help`

Displays help information.

---

## Terminal Commands

Maven Flow includes terminal forwarder scripts in the `bin/` directory that allow you to run Maven Flow commands directly from your terminal without typing the `/` prefix.

### Available Terminal Scripts

| Script | Description | Usage Example |
|--------|-------------|---------------|
| `flow.sh` / `flow.ps1` / `flow.bat` | Main Maven Flow orchestrator | `flow start 10` |
| `flow-prd.sh` / `flow-prd.ps1` / `flow-prd.bat` | PRD creator | `flow-prd create authentication` |
| `flow-convert.sh` / `flow-convert.ps1` / `flow-convert.bat` | PRD to JSON converter | `flow-convert authentication` |

### Installation

**Option 1: Global Installation (Recommended)**
```bash
# Linux/macOS
./bin/flow-install-global.sh
source ~/.bashrc  # or restart your terminal

# Windows - Add bin/ folder to your PATH manually
```

**Option 2: Local Installation**
```bash
# Use scripts directly from bin/ folder
./bin/flow.sh start 10
./bin/flow-prd.sh create authentication
./bin/flow-convert.sh authentication
```

### Usage Examples

**Start autonomous development:**
```bash
flow start              # Start with default 10 iterations
flow start 20           # Start with 20 iterations
flow status             # Check progress
flow continue           # Resume from last iteration
flow reset auth         # Reset specific PRD
```

**Create and convert PRDs:**
```bash
# Create a new PRD (markdown)
flow-prd create user authentication system with login and signup

# Convert to JSON format
flow-convert authentication

# Start development
flow start
```

### Terminal vs Claude Code Commands

The terminal scripts are simple forwarders - they just pass your input to Claude Code:

| Terminal Command | Claude Code Command |
|------------------|-------------------|
| `flow start 10` | `/flow start 10` |
| `flow status` | `/flow status` |
| `flow-prd create auth` | `/flow-prd create auth` |
| `flow-convert auth` | `/flow-convert auth` |

All the actual work (agent coordination, folder creation, memory management) is handled by Claude Code commands, not the terminal scripts.

### Platform-Specific Scripts

**Linux/macOS (Bash):**
```bash
./bin/flow.sh start 10
./bin/flow-prd.sh create authentication
./bin/flow-convert.sh authentication
```

**Windows (PowerShell):**
```powershell
.\bin\flow.ps1 start 10
.\bin\flow-prd.ps1 create authentication
.\bin\flow-convert.ps1 authentication
```

**Windows (CMD):**
```batch
bin\flow.bat start 10
bin\flow-prd.bat create authentication
bin\flow-convert.bat authentication
```

---

## Required Files

| File Pattern | Purpose | Location |
|--------------|---------|----------|
| `prd-[feature-name].json` | Feature PRD with stories, acceptance criteria, pass/fail | `docs/prd-[feature-name].json` |
| `progress-[feature-name].txt` | Append-only log of learnings and context | `docs/progress-[feature-name].txt` |
| `AGENTS.md` | Codebase patterns (auto-updated) | `[directory]/AGENTS.md` |

## Multi-PRD File Structure

```
docs/
├── prd-task-priority.json         # Task priority feature PRD
├── prd-user-auth.json             # User authentication feature PRD
├── prd-notifications.json         # Notifications feature PRD
├── progress-task-priority.txt     # Task priority progress log
├── progress-user-auth.txt         # User auth progress log
└── progress-notifications.txt     # Notifications progress log
```

## Skills

**Note:** Skills in Claude Code are invoked automatically based on your request. You don't type `/skill-name` - just describe what you want and Claude will use the appropriate skill.

### PRD Creation (flow-prd skill)

Describe your feature to create a PRD. The skill will ask clarifying questions and generate a structured document with user stories, acceptance criteria, and dependencies.

**Output:** `docs/prd-[feature-name].md`

**Example:**
- "Create a PRD for user authentication"
- "Write requirements for a task priority feature"

### PRD Conversion (flow-convert skill)

Convert a PRD (markdown or existing format) to `docs/prd-[feature-name].json` format for Maven Flow autonomous execution.

**Output:** `docs/prd-[feature-name].json`

**Example:**
- "Convert the task priority PRD to JSON format"

**Creates feature-specific JSON with structure:**
```json
{
  "project": "My App",
  "branchName": "feature/task-priority",
  "description": "Task priority feature",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "priority": 1,
      "passes": false,
      "mavenSteps": [1, 7],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase", "web-search-prime"]
      },
      "acceptanceCriteria": ["..."]
    }
  ]
}
```

**Note:** MCP tools are specified per step (e.g., `step1`, `step7`). Only list MCP names like `"supabase"`, not individual tools. The agent will automatically discover and use available tools from those MCPs.

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

### Quick Install (Simplified Scripts - Recommended)

Use the simplified installation scripts for easy setup:

**Linux/macOS (Bash):**
```bash
# Global installation (available for all projects) - default
./install-simple.sh global

# Local installation (for current project)
./install-simple.sh local
```

**Windows (PowerShell):**
```powershell
# Global installation
.\install-simple.ps1 global

# Local installation
.\install-simple.ps1 local
```

**Windows (CMD):**
```batch
# Global installation
install-simple.bat global

# Local installation
install-simple.bat local
```

## Configuration

### ESLint Boundaries

Copy `maven-flow/config/eslint.config.mjs` to your project root to enable feature-based architecture enforcement.

### Settings

The hooks are configured in `.claude/maven-flow/.claude/settings.json`. Ensure the paths match your project structure.

## Tips

### Story Size

Keep stories small enough for one context window (~30-50 files max). Larger stories should be broken down.

### Multiple Features

Create separate PRDs for each feature. The flow will process them in order:
1. Create PRD for feature A → Convert to `docs/prd-feature-a.json`
2. Create PRD for feature B → Convert to `docs/prd-feature-b.json`
3. Run `/flow start` → Processes feature A, then feature B

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
4. Document verification in progress file

## Troubleshooting

### Flow not starting?

**Check:**
- At least one `docs/prd-*.json` file exists
- PRD JSON is valid
- Run `/flow status` for diagnostics

### Iteration failing?

**Check:**
- That PRD's `docs/progress-[feature-name].txt` for error messages
- Git log: `git log --oneline -10`
- Resume with `/flow continue`

### Wrong PRD being processed?

**Check:**
- Use `/flow status` to see all PRDs and their status
- Use `/flow continue [prd-name]` to specify which PRD to work on

### Quality hooks not running?

**Check:**
- `.claude/maven-flow/.claude/settings.json` is configured
- Hooks are executable: `chmod +x .claude/maven-flow/hooks/*.sh`
- Bash is available on your system

### Need to restart a PRD?

```bash
/flow reset [prd-name]
```

Previous runs are preserved in `archive/YYYY-MM-DD-[feature-name]/`. Other PRDs remain unaffected.

## File Structure

```
maven-flow/                              # Distribution directory
├── .claude/
│   └── settings.json                   # Hook configurations
├── agents/
│   └── flow-iteration.md               # 🟡 Main coordinator
├── commands/
│   └── flow.md                         # /flow slash command
├── skills/
│   ├── flow-prd/SKILL.md               # PRD creation skill
│   └── flow-convert/SKILL.md           # PRD conversion skill
├── hooks/
│   ├── post-tool-use-quality.sh        # Real-time quality
│   └── stop-comprehensive-check.sh    # Pre-completion check
├── config/
│   └── eslint.config.mjs               # Feature boundaries
├── install-simple.sh                   # ✅ Simplified installation (Linux/macOS)
├── install-simple.ps1                  # ✅ Simplified installation (PowerShell)
├── install-simple.bat                  # ✅ Simplified installation (Windows CMD)
└── README.md                           # This file

# After Installation

.claude/
├── maven-flow/                         # Maven Flow system
│   ├── hooks/                          # Quality enforcement hooks
│   ├── config/                         # ESLint configuration
│   └── .claude/settings.json           # Hook settings
├── skills/                             # ✅ Skills in official location
│   ├── flow-prd/SKILL.md               # PRD creation skill
│   └── flow-convert/SKILL.md           # PRD conversion skill
├── agents/                             # ✅ Global agents location
│   └── flow-iteration.md               # Main iteration agent
└── commands/                           # ✅ Global commands location
    └── flow.md                         # /flow command
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
# 1. User wants multiple features
User: "Add user login and task priority features"

# 2. Create PRD for each feature
User: "Create a PRD for user authentication"
→ Generates docs/prd-user-auth.md

User: "Create a PRD for task priority"
→ Generates docs/prd-task-priority.md

# 3. Convert each PRD to JSON
User: "Convert user auth PRD to JSON"
→ Creates docs/prd-user-auth.json

User: "Convert task priority PRD to JSON"
→ Creates docs/prd-task-priority.json

# 4. Start autonomous development
User: /flow start

# 5. Maven Flow automatically:
# Scans for PRDs → Finds 2 incomplete PRDs
# Selects prd-task-priority.json (alphabetically first)

Iteration 1-5: prd-task-priority.json stories
  → development-agent, refactor-agent, quality-agent
  → Commits: feat: US-001 through US-005
  → Updates docs/prd-task-priority.json: all passes: true
  → PRD complete!

Iteration 6-9: prd-user-auth.json stories
  → development-agent, security-agent, refactor-agent
  → Commits: feat: US-001 through US-004
  → Updates docs/prd-user-auth.json: all passes: true
  → PRD complete!

# 6. All PRDs complete
<promise>ALL_FLOWS_COMPLETE</promise>
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

**Maven Flow: Autonomous AI development with multi-PRD support and comprehensive quality assurance powered by Claude Code CLI**
