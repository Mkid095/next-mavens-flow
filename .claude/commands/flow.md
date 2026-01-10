---
description: Run Maven Flow - autonomous AI development with PRD-driven iteration and 10-step workflow
argument-hint: start [max-iterations] | status | continue [prd-name] | reset [prd-name] | help
hooks:
  PreToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: node -e "const fs=require('fs');try{const input=JSON.parse(process.env.TOOL_INPUT||'{}');if(input.subagent_type==='flow-iteration'){if(!fs.existsSync('docs')){console.error('Error: No docs/ directory found. Create a PRD first using the flow-prd skill.');process.exit(3);}const prds=fs.readdirSync('docs').filter(f=>f.startsWith('prd-')&&f.endsWith('.json'));if(prds.length===0){console.error('Error: No PRD files found in docs/. Create a PRD first using the flow-prd skill.');process.exit(3);}}process.exit(0);}catch(e){process.exit(0);}"
          once: false
---

# Maven Flow

Autonomous AI development flow that implements PRD stories using the Maven 10-Step Workflow. Supports multiple feature PRDs with automatic story tracking and completion.

**Multi-PRD Architecture:** Each feature has its own `docs/prd-[feature-name].json` file. The flow automatically scans for incomplete PRDs and processes them in order.

## Commands

### Start a new flow
```
/flow start [max-iterations]
```
- Scans `docs/` for all `prd-*.json` files
- Finds the first PRD with incomplete stories (`passes: false`)
- Creates/verifies feature branch from that PRD's `branchName`
- Begins autonomous iteration loop on that PRD
- When PRD is complete, moves to the next incomplete PRD
- Default: 10 iterations

**Example:**
```
/flow start 15
```

**How it works:**
1. Scans for all `docs/prd-*.json` files
2. For each PRD, checks if all stories have `passes: true`
3. Finds the first PRD with incomplete stories
4. Processes that PRD until all stories pass
5. Automatically moves to the next incomplete PRD
6. Continues until all PRDs are complete

### Check status
```
/flow status
```
- Lists all PRD files in `docs/`
- Shows completion status for each PRD
- Displays stories (completed/pending) for each PRD
- Shows progress summary from each `docs/progress-[feature-name].txt`

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
  ✓ All stories complete

Current focus: prd-task-priority.json

Recent progress:
  [2025-01-10] prd-task-priority.json - US-003 Added priority dropdown
  Agents: refactor-agent, quality-agent
```

### Continue flow
```
/flow continue [max-iterations]
/flow continue [prd-name] [max-iterations]
```
- Resumes from last iteration
- Continues with current PRD (default) or specified PRD
- Continues with remaining stories where `passes: false`
- Useful when flow was interrupted

**Examples:**
```
/flow continue          # Continue with current PRD
/flow continue 5        # Continue with 5 more iterations
/flow continue task-priority  # Continue specific PRD
```

### Reset flow
```
/flow reset
/flow reset [prd-name]
```
- Archives specified PRD run to `archive/YYYY-MM-DD-[feature-name]/`
- Resets `docs/prd-[feature-name].json` and `docs/progress-[feature-name].txt`
- If no PRD specified, prompts to select which PRD to reset
- Prompts for confirmation before archiving

**Examples:**
```
/flow reset              # Prompts to select PRD
/flow reset task-priority  # Reset specific PRD
```

### Help
```
/flow help
```
- Displays this help information

## Required Files

| File | Purpose |
|------|---------|
| `docs/prd-[feature-name].json` | Feature PRD with user stories, acceptance criteria, and pass/fail status |
| `docs/progress-[feature-name].txt` | Append-only log of learnings and context for each feature |
| `AGENTS.md` | Codebase patterns and conventions (auto-updated during flow) |

## Maven 10-Step Workflow

Each story is implemented using the Maven workflow:

| Step | Agent | Color | Description |
|------|-------|-------|-------------|
| **1** | development-agent | 🟢 Green | Import UI with mock data or create from scratch |
| **2** | development-agent | 🟢 Green | Convert npm → pnpm |
| **3** | refactor-agent | 🔵 Blue | Restructure to feature-based folder structure |
| **4** | refactor-agent | 🔵 Blue | Modularize components >300 lines |
| **5** | quality-agent | 🟣 Purple | Type safety - no 'any' types, @ aliases |
| **6** | refactor-agent | 🔵 Blue | Centralize UI components to @shared/ui |
| **7** | development-agent | 🟢 Green | Centralized data layer with backend setup |
| **8** | security-agent | 🔴 Red | Firebase + Supabase authentication flow |
| **9** | development-agent | 🟢 Green | MCP integrations (web-search, web-reader, chrome, expo, supabase) |
| **10** | security-agent | 🔴 Red | Security and error handling |

## Workflow

1. **Create PRD** - Use the `flow-prd` skill to generate requirements
2. **Convert to JSON** - Use the `flow-convert` skill to create `docs/prd-[feature-name].json`
3. **Start Flow** - Run `/flow start` to begin autonomous iteration
4. **Monitor Progress** - Use `/flow status` to check all PRDs
5. **Review Results** - Each story is committed separately with descriptive messages

## How It Works

### Multi-PRD Processing

When you run `/flow start`:

1. **Scan Phase:** The flow scans `docs/` for all `prd-*.json` files
2. **Priority Phase:** For each PRD, checks completion status:
   - Loads JSON and checks if all stories have `passes: true`
   - Identifies PRDs with incomplete stories (`passes: false`)
3. **Selection Phase:** Picks the first incomplete PRD (alphabetically by filename)
4. **Iteration Phase:** Processes that PRD's stories:
   - Spawns fresh `flow-iteration` subagent (🟡 Yellow)
   - Reads that PRD's JSON and progress file
   - Picks highest priority story where `passes: false`
   - Coordinates Maven agents based on story requirements
   - Commits changes, updates PRD to `passes: true`
   - Appends learnings to progress file
5. **Completion Phase:** When PRD is complete (all `passes: true`):
   - Marks PRD as complete
   - Moves to next incomplete PRD
   - Repeats iteration phase
6. **Final Phase:** When all PRDs are complete:
   - Outputs: `<promise>ALL_FLOWS_COMPLETE</promise>`

### Each Iteration

1. Spawns a fresh `flow-iteration` subagent (🟡 Yellow) with clean context
2. Subagent reads the current PRD's JSON and progress file
3. Picks highest priority story where `passes: false`
4. Analyzes story to determine required Maven steps
5. Coordinates Maven agents based on story requirements:
   - **development-agent** (🟢) for foundation, pnpm, data layer, MCP
   - **refactor-agent** (🔵) for feature structure, modularization, UI
   - **quality-agent** (🟣) for type safety and import validation
   - **security-agent** (🔴) for auth flow and security audit
6. Runs quality checks (typecheck, lint, tests)
7. Updates `AGENTS.md` if patterns discovered
8. Commits changes if quality checks pass
9. Updates the PRD's JSON to set `passes: true`
10. Appends learnings to that PRD's progress file

---

## CRITICAL: Prompt Template for flow-iteration Agent

**When spawning flow-iteration, use ONLY this minimal prompt template:**

```
You are the Maven Flow coordinator. Your job is to continue the Maven Flow workflow.

Current Context:
- Working directory: [current directory]
- Current git branch: [branch name]
- PRD file: docs/prd-[feature-name].json
- Progress file: docs/progress-[feature-name].txt

Your Tasks:
1. Read the PRD file
2. Read the progress file
3. Find the first story with passes: false (highest priority)
4. For that story, read the mavenSteps array
5. Use the Task tool to spawn specialist agents for EACH mavenStep:
   - Step 1, 2, 7, 9 → Task(subagent_type="development-agent", prompt="...")
   - Step 3, 4, 6 → Task(subagent_type="refactor-agent", prompt="...")
   - Step 5 → Task(subagent_type="quality-agent", prompt="...")
   - Step 8, 10 → Task(subagent_type="security-agent", prompt="...")
6. Wait for each agent to complete before starting the next
7. Run quality checks (typecheck, lint)
8. Commit changes
9. Update PRD JSON to set passes: true (use Edit tool)
10. Append to progress file (use Edit tool)

IMPORTANT:
- You are a COORDINATOR only
- Use Task tool to spawn specialist agents for ALL implementation
- NEVER implement code directly
- Your Write/Edit tools are ONLY for updating PRD and progress files
```

**DO NOT include:**
- Detailed implementation instructions
- Step-by-step coding tasks
- File paths or specific implementation details
- "Implement X feature" instructions

**The flow-iteration agent will figure out what to do based on:**
1. The PRD story's acceptance criteria
2. The mavenSteps array in the story
3. Its own agent definition (flow-iteration.md)

## Feature-Based Architecture

Maven Flow enforces this structure for all new code:

```
src/
├── app/                    # Entry points, routing
├── features/               # Isolated feature modules
│   ├── auth/              # Cannot import from other features
│   ├── dashboard/
│   └── [feature-name]/
├── shared/                # Shared code (no feature imports)
│   ├── ui/                # Reusable components
│   ├── api/               # Backend clients
│   └── utils/             # Utilities
```

**Architecture Rules:**
- Features → Cannot import from other features
- Features → Can import from shared/
- Shared → Cannot import from features
- Use `@shared/*`, `@features/*`, `@app/*` aliases (no relative imports)

## Tips

- **Multiple features:** Create separate PRDs for each feature using `flow-prd` skill
- **Story size:** Keep stories small enough for one context window (~30-50 files max)
- **Dependencies:** Order stories by dependency (schema → backend → UI)
- **Quality hooks:** Automatically configured in `maven-flow/.claude/settings.json`
- **Browser verification:** UI stories should include browser testing steps
- **Agent coordination:** The flow-iteration agent automatically delegates to appropriate Maven agents

## Troubleshooting

**Flow not starting?**
- Check that at least one `docs/prd-*.json` file exists
- Verify JSON is valid
- Run `/flow status` for detailed diagnostics

**Iteration failing?**
- Check that PRD's `docs/progress-[feature-name].txt` for errors
- Review git log: `git log --oneline -10`
- Resume with `/flow continue` after fixing issues

**Wrong PRD being processed?**
- Use `/flow status` to see all PRDs and their status
- Use `/flow continue [prd-name]` to specify which PRD to work on

**Need to restart a PRD?**
- Use `/flow reset [prd-name]` to archive and begin fresh for that PRD
- Other PRDs remain unaffected

**Quality hooks not running?**
- Ensure `maven-flow/.claude/settings.json` is configured
- Check that hook scripts are executable: `chmod +x maven-flow/hooks/*.sh`

---

*Maven Flow: Autonomous AI development with comprehensive quality assurance and multi-PRD support powered by Claude Code CLI*
