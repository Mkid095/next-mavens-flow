# Maven Flow - Terminal Command Reference

**Complete guide to terminal scripts for Maven Flow memory-driven autonomous development.**

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Available Commands](#available-commands)
4. [Installation](#installation)
5. [Command Reference](#command-reference)
6. [Platform-Specific Notes](#platform-specific-notes)
7. [Sync & Update](#sync--update)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Maven Flow terminal scripts are **thin wrappers** that forward your commands to Claude Code. They do NOT perform AI work - they simply:

1. Parse CLI arguments
2. Find file paths (e.g., locate PRD files)
3. Invoke Claude Code commands/skills
4. Display output to user

All the actual work (memory loading, agent coordination, context building) is handled by Claude Code commands, not the terminal scripts.

### Architecture

```
┌──────────────┐     ┌─────────────┐     ┌─────────────────────────────┐
│   USER       │────▶│   BASH      │────▶│      CLAUDE CODE           │
│   Terminal   │     │   Scripts   │     │  (All AI work happens here) │
│              │     │  (forwarder)│     │                             │
│  flow start  │     │  flow.sh    │     │  /flow start                 │
│  flow status │     │  flow-prd.sh│     │  /flow-prd create ...        │
│  flow-convert│     │  flow-convert│    │  flow-convert docs/prd-*.md  │
└──────────────┘     └─────────────┘     └─────────────────────────────┘
```

### Key Points

- **Bash scripts are simple forwarders** - they don't do AI work
- **Claude Code does all the work** - memory loading, agent spawning, context building
- **Terminal scripts are optional** - you can use Claude Code commands directly with `/` prefix

---

## Quick Start

### After Installation

```bash
# 1. Create a PRD (memory-aware)
flow-prd create "I want a payment processing system"

# 2. Convert to JSON (analyzes relationships)
flow-convert payments

# 3. Start autonomous development (loads memories)
flow start

# 4. Check progress
flow status
```

### What Happens

| Terminal Command | Claude Code Command | What Claude Does |
|------------------|-------------------|-----------------|
| `flow-prd create "..."` | `/flow-prd "..."` | Scans existing PRDs, loads consolidated memories, identifies relationships |
| `flow-convert payments` | `flow-convert docs/prd-payments.md` | Validates MCPs, tags related features, extracts lessons |
| `flow start` | `/flow start` | Loads related memories + previous stories, spawns agents |

---

## Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `flow start [n]` | Start autonomous development | `flow start 10` |
| `flow status` | Show progress across all PRDs | `flow status` |
| `flow continue [prd] [n]` | Resume from last iteration | `flow continue auth 5` |
| `flow reset [prd]` | Archive and reset a PRD | `flow reset auth` |
| `flow test [prd]` | Test implemented features | `flow test auth` |
| `flow consolidate [prd]` | Fix errors from testing | `flow consolidate auth` |
| `flow help` | Show comprehensive help | `flow help` |
| `flow-prd create "..."` | Create a new PRD | `flow-prd create auth` |
| `flow-convert [feature]` | Convert PRD to JSON | `flow-convert auth` |

---

## Installation

### Linux/macOS (Bash)

**Global Installation (Recommended):**
```bash
./bin/flow-install-global.sh
source ~/.bashrc  # or restart terminal
```

**Local Installation:**
```bash
# Use scripts directly from bin/ folder
./bin/flow.sh start 10
./bin/flow-prd.sh create auth
./bin/flow-convert.sh auth
```

### Windows (PowerShell)

**Global Installation:**
```powershell
.\bin\flow-install-global.ps1
# Restart terminal
```

**Local Installation:**
```powershell
# Use scripts directly from bin/ folder
.\bin\flow.ps1 start 10
.\bin\flow-prd.ps1 create auth
.\bin\flow-convert.ps1 auth
```

### Windows (CMD)

**Global Installation:**
```batch
REM Add bin/ folder to your PATH manually
REM Then use from anywhere:
flow start 10
```

**Local Installation:**
```batch
REM Use scripts directly from bin/ folder
bin\flow.bat start 10
bin\flow-prd.bat create auth
bin\flow-convert.bat auth
```

### Verify Installation

```bash
# Check if commands are available
flow --help      # Should show help
flow-prd --help  # Should show PRD creation help
```

---

## Command Reference

### flow start

**Syntax:**
```bash
flow start [max-iterations]
```

**Description:** Starts autonomous flow execution. Processes stories from incomplete PRDs.

**Options:**
- `max-iterations` (optional): Number of stories to process (default: 10)

**Examples:**
```bash
flow start          # Process up to 10 stories (default)
flow start 20       # Process up to 20 stories
flow start 1        # Process exactly 1 story then stop
```

**What happens:**
1. Validates prerequisites (docs/, PRD files, incomplete stories)
2. Scans for all PRD files in `docs/`
3. Identifies incomplete stories (`passes: false`)
4. For each story:
   - **MEMORY LOADING PHASE**: Loads related PRD memories + previous story memories
   - **IMPLEMENTATION PHASE**: Spawns specialist agents for each mavenStep
   - **QUALITY CHECKS**: Runs typecheck and lint
   - **MEMORY CREATION PHASE**: Creates story memory file
   - Commits changes with standardized format
   - Marks story as complete in PRD
5. Continues until max iterations or all PRDs complete

---

### flow status

**Syntax:**
```bash
flow status
```

**Description:** Shows current progress across all PRDs.

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

Recent progress:
  [2026-01-25] prd-task-priority.json - US-003 Added priority dropdown
  Agents: refactor-agent, quality-agent
```

---

### flow continue

**Syntax:**
```bash
flow continue [prd-name] [max-iterations]
```

**Description:** Resumes flow execution from where it left off.

**Options:**
- `prd-name` (optional): Specific PRD to process (default: current)
- `max-iterations` (optional): Number of stories to process

**Examples:**
```bash
flow continue           # Continue with current PRD
flow continue 5         # Continue with 5 more iterations
flow continue auth      # Continue auth PRD specifically
flow continue auth 10   # Continue auth PRD for 10 stories
```

**When to use:**
- After fixing an error that stopped the flow
- After manually editing PRD or code
- To continue with a specific PRD
- To process more stories than originally planned

---

### flow reset

**Syntax:**
```bash
flow reset [prd-name]
```

**Description:** Archives current PRD run and resets for fresh start.

**Options:**
- `prd-name` (optional): Specific PRD to reset (prompts if omitted)

**Examples:**
```bash
flow reset           # Prompts to select PRD
flow reset auth      # Reset auth PRD specifically
```

**What happens:**
- Creates archive: `archive/YYYY-MM-DD-[feature-name]/`
- Moves current PRD and progress file to archive
- Resets all stories to `passes: false`
- Creates fresh PRD and progress files
- Prompts for confirmation before archiving

**When to use:**
- PRD has fundamental issues
- Want to start over with different approach
- Need to archive current progress before major changes

---

### flow test

**Syntax:**
```bash
flow test [prd-name]
```

**Description:** Runs comprehensive testing of implemented features.

**Options:**
- `prd-name` (optional): Specific PRD to test (auto-detects if omitted)

**Examples:**
```bash
flow test                # Test current PRD (auto-detects)
flow test auth           # Test authentication PRD
flow test task-priority  # Test task-priority PRD
```

**What happens:**
1. Reads PRD to find completed stories
2. Starts dev server: `pnpm dev`
3. Opens application using chrome-devtools MCP
4. Tests user signup/login with standard test user
5. Tests each completed feature's acceptance criteria
6. Checks console for errors
7. Creates error log at `docs/errors-[feature-name].md`

**Test User Credentials:**
- Email: `revccnt@gmail.com`
- Password: `Elishiba!90`

---

### flow consolidate

**Syntax:**
```bash
flow consolidate [prd-name]
```

**Description:** Fixes errors found during testing (without re-implementing features).

**Options:**
- `prd-name` (optional): Specific PRD to consolidate (auto-detects if omitted)

**Examples:**
```bash
flow consolidate         # Consolidate current PRD
flow consolidate auth    # Consolidate authentication PRD
```

**What happens:**
1. Reads error log from `docs/errors-[feature-name].md`
2. Identifies which stories/steps have errors
3. Re-runs ONLY the affected steps (not entire stories)
4. Fixes specific errors found during testing

**What it does NOT do:**
- Does NOT run full mavenSteps again
- Does NOT re-implement completed features
- Does NOT touch working code

---

### flow help

**Syntax:**
```bash
flow help
```

**Description:** Displays comprehensive help information.

---

### flow-prd create

**Syntax:**
```bash
flow-prd create "[feature description]"
```

**Description:** Creates a new PRD with memory-aware context loading.

**What happens:**
1. **Scans existing PRDs** for `docs/prd-*.json`
2. **Loads consolidated memories** from complete PRDs
3. **Analyzes feature relationships** (depends_on, depended_by)
4. **Extracts integration points** (authentication, database, API, state)
5. **Loads story memories** for lessons learned
6. **Generates markdown PRD** with full context

**Examples:**
```bash
# Simple feature
flow-prd create "user authentication"

# Complex feature with description
flow-prd create "I want a payment processing system with Stripe integration"

# From existing plan.md
flow-prd create  # Will use plan.md if it exists
```

**Output:**
- `docs/prd-[feature-name].md` (human-readable PRD)
- `docs/consolidated-[feature-name].txt` (memory placeholder)
- Auto-runs: `flow-convert [feature]`

---

### flow-convert

**Syntax:**
```bash
flow-convert [feature-name]
```

**Description:** Converts PRD markdown to JSON format with relationship analysis.

**What happens:**
1. **Scans existing JSON PRDs** to build feature map
2. **Loads consolidated memories** from complete PRDs
3. **Analyzes feature relationships** from markdown PRD
4. **Validates MCP availability** before assigning
5. **Builds lessons learned** from existing features
6. **Generates JSON PRD** with relatedPRDs and lessonsLearned

**Examples:**
```bash
flow-convert auth          # Converts docs/prd-auth.md
flow-convert payments       # Converts docs/prd-payments.md
flow-convert task-priority  # Converts docs/prd-task-priority.md
```

**Output:**
- `docs/prd-[feature-name].json` (machine-readable PRD)
- Populated fields:
  - `relatedPRDs`: [] (relationship metadata)
  - `lessonsLearned`: "" (from existing features)
  - `consolidatedMemory`: "" (empty initially)
  - `userStories`: [] (with mavenSteps, mcpTools)

---

## Platform-Specific Notes

### Linux/macOS

**Script extension:** `.sh`

**Shebang:** `#!/bin/bash`

**Path separator:** `/`

**Example:**
```bash
./bin/flow.sh start 10
./bin/flow-prd.sh create "user authentication"
./bin/flow-convert.sh auth
```

**Common issues:**
- Permission denied: Run `chmod +x bin/*.sh`
- Command not found: Use `./bin/` prefix or install globally

### Windows (PowerShell)

**Script extension:** `.ps1`

**Shebang:** Not applicable

**Path separator:** `\`

**Example:**
```powershell
.\bin\flow.ps1 start 10
.\bin\flow-prd.ps1 create "user authentication"
.\bin\flow-convert.ps1 auth
```

**Common issues:**
- Execution policy: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Permission denied: Run PowerShell as Administrator

### Windows (CMD)

**Script extension:** `.bat`

**Shebang:** Not applicable

**Path separator:** `\`

**Example:**
```batch
bin\flow.bat start 10
bin\flow-prd.bat create "user authentication"
bin\flow-convert.bat auth
```

**Common issues:**
- Special characters: Enclose arguments in quotes
- Path length: Keep paths short (<260 chars)

---

## Sync & Update

### flow-sync (Sync Scripts Between Project and Global)

Maven Flow supports syncing scripts between your project and global installation.

**Check sync status:**
```bash
# Linux/macOS
./flow-sync.sh status

# Windows
flow-sync status
```

**Pull from global to project:**
```bash
# Use when global has updates
./flow-sync.sh pull  # Linux/macOS
flow-sync pull       # Windows
```

**Push from project to global:**
```bash
# Use when you've made changes in project
./flow-sync.sh push  # Linux/macOS
flow-sync push       # Windows
```

**Auto-detect mode:**
```bash
# Auto-detects which direction to sync
./flow-sync.sh       # Linux/macOS
flow-sync           # Windows
```

### flow-update (Update Maven Flow from Repository)

```bash
# Linux/macOS
./flow-update.sh

# Windows
flow-update
```

Then run `flow-sync pull` to update your project.

---

## Troubleshooting

### Command Not Found

**Symptoms:**
```bash
flow: command not found
```

**Solutions:**

1. **Check if installed:**
   ```bash
   # Linux/macOS
   which flow

   # Windows
   where flow
   ```

2. **Install globally:**
   ```bash
   # Linux/macOS
   ./bin/flow-install-global.sh
   source ~/.bashrc

   # Windows
   .\bin\flow-install-global.ps1
   # Restart terminal
   ```

3. **Use local scripts:**
   ```bash
   # Linux/macOS
   ./bin/flow.sh start 10

   # Windows
   .\bin\flow.ps1 start 10
   ```

### Permission Denied

**Symptoms:**
```bash
bash: ./bin/flow.sh: Permission denied
```

**Solution:**
```bash
chmod +x bin/*.sh
```

### PowerShell Execution Policy

**Symptoms:**
```powershell
flow.ps1 cannot be loaded because running scripts is disabled on this system
```

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Wrong Claude Code Version

**Symptoms:**
- Commands not recognized
- @agent-name syntax not working

**Solution:**
```bash
# Check Claude Code version
claude --version

# Requires Claude Code v1.0.62+ for @agent-name syntax
```

---

## Summary

| Command | Purpose | Claude Code Equivalent |
|---------|---------|------------------------|
| `flow start [n]` | Start autonomous development | `/flow start [n]` |
| `flow status` | Show progress | `/flow status` |
| `flow continue [prd] [n]` | Resume from last iteration | `/flow continue [prd] [n]` |
| `flow reset [prd]` | Archive and reset PRD | `/flow reset [prd]` |
| `flow test [prd]` | Test implemented features | `/flow test [prd]` |
| `flow consolidate [prd]` | Fix errors from testing | `/flow consolidate [prd]` |
| `flow help` | Show help | `/flow help` |
| `flow-prd create "..."` | Create PRD with context | `/flow-prd "..."` |
| `flow-convert [feature]` | Convert PRD to JSON | `flow-convert docs/prd-[feature].md` |

**Remember:** Terminal scripts are just forwarders. All AI work happens in Claude Code.

---

**Maven Flow: Memory-Driven Autonomous AI Development**
