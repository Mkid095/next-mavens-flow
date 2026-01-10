---
description: Run Maven Flow - autonomous AI development with PRD-driven iteration and 10-step workflow
argument-hint: start [max-iterations] | status | continue | reset | help
hooks:
  PreToolUse:
    - matcher: "Task"
      hooks:
        - type: command
          command: |
            #!/bin/bash
            # Validate flow-iteration subagent invocation
            SUBAGENT_TYPE=$(echo "$TOOL_INPUT" | jq -r '.subagent_type // empty')
            if [ "$SUBAGENT_TYPE" = "flow-iteration" ]; then
              # Ensure prd.json exists
              if [ ! -f "docs/prd.json" ]; then
                echo "Error: docs/prd.json not found. Create a PRD first using the flow-prd skill." >&2
                exit 3
              fi
            fi
          once: false
---

# Maven Flow

Autonomous AI development flow that implements PRD stories using the Maven 10-Step Workflow. Coordinates specialized agents (development, refactor, quality, security) for comprehensive code quality.

## Commands

### Start a new flow
```
/flow start [max-iterations]
```
- Validates `docs/prd.json` exists
- Creates/verifies feature branch from PRD `branchName`
- Begins autonomous iteration loop
- Default: 10 iterations

**Example:**
```
/flow start 15
```

### Check status
```
/flow status
```
- Shows completed/pending stories from `docs/prd.json`
- Displays progress summary from `docs/progress.txt`
- Lists recent commits

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
  [2025-01-10] US-003 - Added priority dropdown with save-on-change
  Agents: refactor-agent, quality-agent
```

### Continue flow
```
/flow continue [max-iterations]
```
- Resumes from last iteration
- Continues with remaining stories where `passes: false`
- Useful when flow was interrupted

### Reset flow
```
/flow reset
```
- Archives current run to `archive/YYYY-MM-DD-feature-name/`
- Resets `docs/prd.json` and `docs/progress.txt` for new feature
- Prompts for confirmation before archiving

### Help
```
/flow help
```
- Displays this help information

## Required Files

| File | Purpose |
|------|---------|
| `docs/prd.json` | PRD with user stories, acceptance criteria, and pass/fail status |
| `docs/progress.txt` | Append-only log of learnings and context for future iterations |
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
2. **Convert to JSON** - Use the `flow-convert` skill to create `docs/prd.json`
3. **Start Flow** - Run `/flow start` to begin autonomous iteration
4. **Monitor Progress** - Use `/flow status` to check progress
5. **Review Results** - Each story is committed separately with descriptive messages

## How It Works

Each iteration:

1. Spawns a fresh `flow-iteration` subagent (🟡 Yellow) with clean context
2. Subagent reads `docs/prd.json` and `docs/progress.txt`
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
9. Updates `docs/prd.json` to set `passes: true`
10. Appends learnings to `docs/progress.txt`

When all stories complete, outputs: `<promise>FLOW_COMPLETE</promise>`

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

## Automated Quality Hooks

Maven Flow includes automated hooks that run during development:

### PostToolUse Hook
Runs after every Write/Edit operation:
- ✅ Relative imports → should use @ aliases
- ✅ 'any' types → should use proper types
- ✅ File size >300 lines → needs modularization
- ✅ Direct API calls → should use data layer
- ✅ UI duplication → should use @shared/ui
- ✅ Exposed secrets → security risk

### Stop Hook
Runs before completing work:
- ✅ Large components (>300 lines)
- ✅ Type safety ('any' count)
- ✅ Import path violations
- ✅ Feature boundary violations (ESLint)
- ✅ UI component duplication
- ✅ Security scan (secrets, tokens, passwords)

## Tips

- **Story size**: Keep stories small enough for one context window (~30-50 files max)
- **Dependencies**: Order stories by dependency (schema → backend → UI)
- **Quality hooks**: Automatically configured in `maven-flow/.claude/settings.json`
- **Browser verification**: UI stories should include browser testing steps
- **Agent coordination**: The flow-iteration agent automatically delegates to appropriate Maven agents

## Troubleshooting

**Flow not starting?**
- Check that `docs/prd.json` exists and is valid JSON
- Verify `branchName` in PRD matches your intended branch
- Run `/flow status` for detailed diagnostics

**Iteration failing?**
- Check `docs/progress.txt` for error messages and learnings
- Review git log: `git log --oneline -10`
- Resume with `/flow continue` after fixing issues

**Quality hooks not running?**
- Ensure `maven-flow/.claude/settings.json` is configured
- Check that hook scripts are executable: `chmod +x maven-flow/hooks/*.sh`

**Need to start over?**
- Use `/flow reset` to archive and begin fresh
- Previous runs are preserved in `archive/`

---

*Maven Flow: Autonomous AI development with comprehensive quality assurance powered by Claude Code CLI*
