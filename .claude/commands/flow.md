---
description: Run Maven Flow - autonomous AI development with PRD-driven iteration and 10-step workflow
argument-hint: start [max-iterations] | status | continue [prd-name] | reset [prd-name] | help
---

# Maven Flow

Autonomous AI development flow that implements PRD stories using the Maven 10-Step Workflow. Supports multiple feature PRDs with automatic story tracking and completion.

**Multi-PRD Architecture:** Each feature has its own `docs/prd-[feature-name].json` file. The flow automatically scans for incomplete PRDs and processes them in order.

## Commands

### Start a new flow
```
/flow start [max-iterations]
```

**CRITICAL: This command runs AUTOMATICALLY until ALL stories complete**

**Architecture:** The `/flow` command (running in main Claude context) coordinates ALL specialist agent spawning directly. Subagents are NOT used for coordination since they cannot spawn other subagents.

---

## Prerequisites Check

Before starting, the command validates:

1. **`docs/` directory exists**
   - If missing: `❌ Error: No docs/ directory found.`
   - Fix: Create the directory: `mkdir docs`

2. **PRD files exist** (`docs/prd-*.json`)
   - If missing: `❌ Error: No PRD files found in docs/.`
   - Fix: Create a PRD first using the `flow-prd` skill:
     ```
     Tell me you want to create a PRD for [feature]
     Example: "Create a PRD for a user authentication feature"
     ```

3. **At least one incomplete story**
   - If all PRDs complete: `✅ All PRDs complete! No work to do.`
   - Fix: Create a new PRD or add stories to existing PRD

4. **Scan available MCP servers** (automatic)
   - Run: `claude mcp list` to discover available MCP servers
   - System adapts to whatever MCPs are configured
   - Works with or without MCP servers

---

When you execute `/flow start` or `/flow continue`:

1. **Validate prerequisites** (docs/, PRD files, incomplete stories)
2. **Scan available MCP servers** using `claude mcp list`
3. Scan for incomplete PRDs
4. Pick the first incomplete story
5. **Spawn specialist agents directly using Task tool:**
   - For each mavenStep in the story, spawn appropriate agent
   - Include available MCP servers in agent context
   - Wait for agent to complete before spawning next
   - Continue until all mavenSteps are done
6. Run quality checks, commit, update PRD
7. **Repeat automatically** for next story
8. Continue until ALL PRDs have ALL stories passing
9. Do NOT wait for user input between stories
10. Do NOT stop after one story - keep going until ALL are complete

**Example:**
```
/flow start 15
```

**How it works:**
1. Scans for all `docs/prd-*.json` files
2. For each PRD, checks if all stories have `passes: true`
3. Finds the first PRD with incomplete stories
4. **Scans available MCP servers** using `claude mcp list`
5. For each incomplete story (in priority order):
   - Read story's mavenSteps array
   - Read story's availableMcpTools (if specified)
   - **Merge PRD MCP hints with actual available MCPs**
   - **Spawn specialist agents directly:**
     - Step 1, 2, 7, 9 → Task(subagent_type="development-agent")
     - Step 3, 4, 6 → Task(subagent_type="refactor-agent")
     - Step 5 → Task(subagent_type="quality-agent")
     - Step 8, 10 → Task(subagent_type="security-agent")
     - Step 11 → Task(subagent_type="design-agent") [optional, for mobile apps]
   - **Include available MCP context in agent prompt:**
     ```
     Available MCP servers: [list of actually available MCPs]
     Story-suggested MCPs: [from PRD availableMcpTools if specified]
     Use whichever MCPs are actually available.
     ```
   - Wait for each agent to complete
   - Run quality checks (typecheck, lint)
   - Commit changes
   - Update PRD (set passes: true)
   - Append to progress file
6. Move to next incomplete story
7. When PRD complete, move to next incomplete PRD
8. Continue until all PRDs are complete
9. Default: 10 iterations (stories) unless specified

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

## Maven 10-Step Workflow (Plus Optional Design Step)

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
| **11** | design-agent | 🩷 Pink | **Mobile Design** - Professional UI/UX for Expo/React Native (optional) |

**Step 11 is optional** and specifically for mobile app (Expo/React Native) projects. It applies Apple's design methodology to transform basic UIs into professional, polished mobile experiences.

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
4. **Iteration Phase:** Processes that PRD's stories one by one:
   - Reads PRD JSON and picks highest priority story where `passes: false`
   - Reads story's `mavenSteps` array
   - **Spawns specialist agents directly** (one per mavenStep)
   - Waits for each agent to complete
   - Runs quality checks
   - Commits changes
   - Updates PRD to `passes: true`
   - Appends learnings to progress file
5. **Completion Phase:** When PRD is complete (all `passes: true`):
   - Marks PRD as complete
   - Moves to next incomplete PRD
   - Repeats iteration phase
6. **Final Phase:** When all PRDs are complete:
   - Outputs completion summary

### Maven Step to Agent Mapping

The `/flow` command maps each step in the story's `mavenSteps` array to the appropriate specialist agent:

| Maven Step | Agent Type | Task subagent_type | Description |
|------------|------------|-------------------|-------------|
| 1 | Foundation | development-agent | Import UI with mock data or create from scratch |
| 2 | Package Manager | development-agent | Convert npm → pnpm |
| 3 | Feature Structure | refactor-agent | Restructure to feature-based folder structure |
| 4 | Modularization | refactor-agent | Modularize components >300 lines |
| 5 | Type Safety | quality-agent | Type safety - no 'any' types, @ aliases |
| 6 | UI Centralization | refactor-agent | Centralize UI components to @shared/ui |
| 7 | Data Layer | development-agent | Centralized data layer with backend setup |
| 8 | Auth Integration | security-agent | Firebase + Supabase authentication flow |
| 9 | MCP Integration | development-agent | MCP integrations (web-search, web-reader, chrome, expo, supabase) |
| 10 | Security & Error Handling | security-agent | Security and error handling |
| 11 | Mobile Design | design-agent | Professional UI/UX for Expo/React Native (optional) |

### Story Processing Flow

For each incomplete story:

```markdown
## Story: [Story ID] - [Story Title]

**From PRD:**
- mavenSteps: [1, 3, 5, 7]
- availableMcpTools: { development-agent: [...], refactor-agent: [...] } (optional)
- Description: [Story description]
- Acceptance Criteria: [List from PRD]

**MCP Discovery:**
Running: claude mcp list
Found: 5 MCP servers (supabase, web-search-prime, web-reader, chrome-devtools, zai-mcp-server)

**Processing:**

1. [Step 1 - Foundation]
   Spawning development agent...
   Available MCP servers: supabase, web-search-prime, web-reader, chrome-devtools, zai-mcp-server
   Story-suggested MCPs: supabase, web-search-prime (if specified in PRD)
   → [Waiting for completion]
   → [Agent completed successfully]

2. [Step 3 - Feature Structure]
   Spawning refactor agent...
   Available MCP servers: (all MCPs available, but none specifically needed)
   → [Waiting for completion]
   → [Agent completed successfully]

3. [Step 5 - Type Safety]
   Spawning quality agent...
   Available MCP servers: (all MCPs available)
   → [Waiting for completion]
   → [Agent completed successfully]

4. [Step 7 - Data Layer]
   Spawning development agent...
   Available MCP servers: supabase, web-search-prime, web-reader, chrome-devtools, zai-mcp-server
   Story-suggested MCPs: database (supabase if available)
   → [Waiting for completion]
   → [Agent completed successfully]

5. Running quality checks...
   pnpm run typecheck
   → Passed

6. Committing changes...
   git commit -m "feat: [Story ID] - [Story Title]

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"
   → Committed

7. Updating PRD...
   Setting passes: true for [Story ID]
   → Updated

8. Logging progress...
   Appending to docs/progress-[feature].txt
   → Logged

✅ Story [Story ID] complete
```

**IMPORTANT: Dynamic MCP Discovery**

The flow command automatically discovers available MCP servers at runtime:

1. **Scan MCPs:** Run `claude mcp list` to get all configured MCP servers
2. **Merge with PRD hints:** Combine PRD `availableMcpTools` (if specified) with actual available MCPs
3. **Pass to agents:** Include the available MCP list in each agent's prompt
4. **Agent adapts:** Agents use whatever MCPs are actually available

**PRD MCP Configuration (Optional):**

```json
{
  "id": "US-001",
  "mavenSteps": [1, 7],
  "availableMcpTools": {
    "development-agent": [
      { "mcp": "database" },
      { "mcp": "web-search" }
    ]
  }
}
```

**How it works:**
- **If** the specified MCPs are available → prioritize those
- **If not available** → use whatever MCPs are available
- **If no MCPs available** → use standard tools (Read, Write, Bash, etc.)

**Why story-level MCP tools?**

1. **Context Isolation:** Prevents confusion as context grows large
2. **Precision:** Agents know which MCP servers might be helpful for that story
3. **No Hallucination:** Reduces risk of agents "forgetting" available tools
4. **Granular Control:** Different stories can suggest different MCP preferences
5. **Dynamic Discovery:** Flow scans actual available MCPs at runtime and merges with PRD hints
6. **Optional & Hint-Based:** PRD MCPs are suggestions, not requirements - system works without them

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
- **Agent coordination:** The /flow command directly spawns specialist agents for each mavenStep

### Mobile App Development (Expo/React Native)

- **Step 11 (design-agent)**: Add to stories for mobile apps to apply professional UI/UX design
- **Design principles**: Based on Apple's design methodology (Structure, Navigation, Content, Visual Design)
- **Expo integration**: Design-agent validates changes using Expo preview
- **When to use**: Include Step 11 in mavenSteps for stories that create or modify mobile UI screens
- **Example PRD story for mobile**:
  ```json
  {
    "id": "US-001",
    "title": "Create mobile home screen",
    "mavenSteps": [1, 3, 5, 6, 11],
    "description": "Create the main home screen for the mobile app"
  }
  ```

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
