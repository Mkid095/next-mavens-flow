---
description: Run Maven Flow - autonomous AI development with PRD-driven iteration and 10-step workflow
argument-hint: start [max-iterations] | status | continue [prd-name] | reset [prd-name] | test [prd-name] | consolidate [prd-name] | help
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

4. **Maven Flow wrapper script** (optional, for local execution)
   - The flow can create `maven-flow.sh` locally for direct execution
   - This wrapper is created automatically when needed
   - If you encounter syntax errors, delete `maven-flow.sh` and let flow recreate it

---

When you execute `/flow start` or `/flow continue`:

## EXACT EXECUTION INSTRUCTIONS (READ CAREFULLY):

**You MUST invoke specialist agents using the @agent-name syntax. Each agent runs in its own isolated context window.**

### For each story, execute each mavenStep by invoking the appropriate agent:

**Step 1, 2, 7, 9 (Development):**
```
@development-agent

You are working on Step [N] of Maven Workflow for story: [US-XXX - Story title]

PRD: docs/prd-[feature].json
MCPs to use for this step: [from mcpTools.mcpTools.step[N]]

## Your Task (Step [N]):
[Detailed step requirements from PRD acceptance criteria]

## Quality Standards (ZERO TOLERANCE):
- No 'any' types - use proper TypeScript
- No gradients - use solid professional colors
- No relative imports - use @/ aliases
- Components < 300 lines

When complete, output: [STEP_COMPLETE]
```

**Step 3, 4, 6 (Refactor):**
```
@refactor-agent
[Same prompt structure as above]
```

**Step 5 (Quality):**
```
@quality-agent
[Same prompt structure as above]
```

**Step 8, 10 (Security):**
```
@security-agent
[Same prompt structure as above]
```

**Step 11 (Design):**
```
@design-agent
[Same prompt structure as above]
```

### Wait for agent completion before proceeding to next step

### After all steps complete:
1. Run: `pnpm run typecheck` (or `pnpm tsc`)
2. Update PRD: Set `passes: true` for the story
3. Commit: `git add . && git commit -m "feat: [US-XXX] [title]"`
4. Output: `<STORY_COMPLETE>`

### Then move to next incomplete story

**DO NOT STOP. Continue automatically until ALL stories complete.**

---

Now continue with the standard flow:
   - Wait for agent to complete before spawning next
   - Continue until all mavenSteps are done
5. Run quality checks, commit, update PRD
6. **Repeat automatically** for next story
7. Continue until ALL PRDs have ALL stories passing
8. Do NOT wait for user input between stories
9. Do NOT stop after one story - keep going until ALL are complete

**Example:**
```
/flow start 15
```

**How it works:**
1. Scans for all `docs/prd-*.json` files
2. For each PRD, checks if all stories have `passes: true`
3. Finds the first PRD with incomplete stories
4. For each incomplete story (in priority order):

   **MEMORY LOADING PHASE:**

   **CRITICAL: Before spawning any agents, you MUST load memory context.**

   **Step 1: Read PRD's relatedPRDs array**
   ```bash
   # Extract relatedPRDs from the PRD JSON
   cat docs/prd-[feature].json | jq '.relatedPRDs'
   ```

   **Step 2: Load consolidated memory from each related PRD (if any)**

   For each related PRD in the array:
   1. **Find the consolidated memory file:**
      ```bash
      # Related PRD: docs/prd-auth.json
      # Load: docs/consolidated-auth.txt
      ```
   2. **Read and extract relevant sections:**
      ```bash
      cat docs/consolidated-[feature].txt
      ```
   3. **Pre-analyze and summarize** (~3-5K tokens per related PRD):
      - Architecture decisions (tech stack, structure)
      - Integration patterns (authentication, database, API)
      - Public interfaces (endpoints, components)
      - Key lessons learned

   **Build consolidated memory summary:**
   ```
   RELATED_PRD_CONTEXT = {
     prd-auth.json: {
       architecture: [tech stack, structure],
       integration: [auth patterns, API endpoints],
       lessons: [key learnings]
     },
     prd-products.json: {
       architecture: [data models],
       integration: [product API endpoints],
       lessons: [database patterns]
     }
   }
   ```

   **Step 3: Load previous story memories from same PRD**

   Execute:
   ```bash
   find docs/[feature]/story-*.txt -type f | sort
   ```

   For each story memory file (~10K tokens total):
   1. **Read the story memory file**
   2. **Extract:**
      - What was implemented (files, components, functions)
      - Key decisions made
      - Challenges resolved
      - Integration points
      - Lessons learned

   **Build story memory summary:**
   ```
   PREVIOUS_STORIES_CONTEXT = {
     "US-001": {
       implemented: [database schema, API endpoints],
       decisions: [used Supabase MCP for direct DB access],
       integration: [connected to auth feature]
     },
     "US-002": {
       implemented: [UI components, forms],
       decisions: [used centralized Form component],
       lessons: [test with real data, not mocks]
     }
   }
   ```

   **Step 4: Build story session with proper context structure**

   When spawning each agent, include:

   ```
   ## CONTEXT FOR CURRENT STORY

   ### From Related PRDs:
   - [prd-auth.json]: Authentication uses Supabase Auth with RLS
   - [prd-products.json]: Product data accessed via /api/products/*

   ### From Previous Stories:
   - [US-001]: Database schema uses 'status' enum column
   - [US-002]: UI components centralized in @shared/ui

   ### Current Story:
   - Story: US-003
   - Task: [story description]
   - Acceptance Criteria: [from PRD]
   ```

   **Step 5: Inject context into agent prompts**

   For each mavenStep, when spawning the agent:
   1. **Include PRD JSON** (story description, acceptance criteria)
   2. **Include relatedPRDs context** (architecture, integration patterns)
   3. **Include previous stories context** (decisions, patterns)
   4. **Specify MCPs to use** (from mcpTools.step[N])

   **Example agent prompt with context:**
   ```
   @development-agent

   You are working on Step 1 of Maven Workflow for story: US-003 - Add task filtering

   PRD: docs/prd-task-management.json
   MCPs to use for this step: supabase

   ## CONTEXT FROM RELATED FEATURES:

   ### Authentication (prd-auth.json):
   - Auth provider: Supabase Auth
   - User ID accessed via: auth.getUser()
   - RLS policies filter by user_id automatically

   ### Products (prd-products.json):
   - Product API: /api/products (GET, POST, PUT, DELETE)
   - Data model: { id, name, price, status }

   ## CONTEXT FROM PREVIOUS STORIES:

   ### US-001: Database schema
   - Table: tasks (id, title, status, user_id, created_at)
   - Status enum: 'pending', 'in_progress', 'completed'
   - Decision: Used Supabase MCP for direct schema creation

   ### US-002: UI components
   - Form component: @shared/ui/Form
   - Input component: @shared/ui/Input
   - Decision: Centralize reusable UI components

   ## YOUR TASK (Step 1 - Foundation):

   [Detailed step requirements from PRD acceptance criteria]

   ## QUALITY STANDARDS (ZERO TOLERANCE):
   - No 'any' types - use proper TypeScript
   - No gradients - use solid professional colors
   - No relative imports - use @/ aliases
   - Components < 300 lines

   When complete, output: [STEP_COMPLETE]
   ```

   **⚠️ CRITICAL:** Do NOT skip memory loading. Agents need context from:
   - Related PRDs (how to integrate)
   - Previous stories (patterns to follow)
   - Architecture decisions (what already exists)

   **IMPLEMENTATION PHASE:**
   - Read story's mavenSteps array
   - Read story's mcpTools (if specified for each step)
   - **Spawn specialist agents using @agent-name syntax:**
     - Step 1, 2, 7, 9 → @development-agent
     - Step 3, 4, 6 → @refactor-agent
     - Step 5 → @quality-agent
     - Step 8, 10 → @security-agent
     - Step 11 → @design-agent [optional, for mobile apps]
   - **Tell agent which MCPs to use with EXPLICIT INSTRUCTIONS at the start of prompt:**
     ```
     *** CRITICAL: MCP TOOLS INSTRUCTION ***
     You MUST use the Supabase MCP tools for ALL database operations.
     DO NOT read migration files or create scripts.
     SCAN FIRST - Use MCP to list/check what exists in the database BEFORE making any changes.
     Query the database DIRECTLY using Supabase MCP tools.

     Story: US-POS-001, Step 1
     MCPs: supabase
     ```
   - Wait for each agent to complete
   - Run quality checks (typecheck, lint)

   **MEMORY CREATION PHASE (MANDATORY - DO NOT SKIP!):**

   This phase is CRITICAL for the memory system. You MUST execute it for EVERY completed story.

   **Invoke the story memory creation command:**

   ```
   /create-story-memory docs/prd-[feature].json US-[XXX]
   ```

   This command will:
   1. Extract story details from the PRD
   2. Analyze the git diff to understand what was implemented
   3. Generate a comprehensive story memory file at:
      `docs/[feature]/story-US-[###]-[title].txt`
   4. Include:
      - What was implemented (specific files, functions, components)
      - Key decisions made (architecture choices, design patterns)
      - Technical challenges encountered and how they were resolved
      - Integration points with other features
      - Lessons learned for future work

   **After the command completes, verify the memory file was created:**
   ```bash
   test -f docs/[feature]/story-US-[###]-*.txt && echo "✓ Memory created" || echo "✗ Memory missing"
   ```

   **Then update PRD JSON and commit:**
   1. Update PRD JSON: Set `passes: true` for the completed story
   2. Commit changes with proper format: `feat: [story-id] [story-title]`
   3. Output the `<STORY_COMPLETE>` signal to indicate completion

   **⚠️ WARNING:** Do NOT skip or defer memory creation. The memory system depends on these files being created after each story.

5. Move to next incomplete story

6. **CONSOLIDATION PHASE (when ALL stories in PRD complete):**

   When ALL stories in the PRD have `passes: true`, you MUST consolidate all story memories.

   **Invoke the consolidation command:**

   ```
   /consolidate-memory docs/prd-[feature].json
   ```

   This command will:
   1. **Read all story memory files** from `docs/[feature]/story-US-*.txt`
   2. **Update the consolidated memory file:** `docs/consolidated-[feature].txt`
      - Read existing content first
      - Consolidate all story memories into comprehensive format
      - Update totals: `totalStories` and `completedStories` to actual counts
      - Set `status: completed`
      - Update `consolidatedDate` to current date
   3. **Target ~30-50K tokens** - Summarize while preserving critical information
   4. **Focus on:** Patterns, decisions, interfaces, integration points, lessons learned
   5. **Output:** `<ALL_COMPLETE>` signal

   **After the command completes, verify the consolidated memory was updated:**
   ```bash
   grep -q "status: completed" docs/consolidated-[feature].txt && echo "✓ Consolidated" || echo "✗ Consolidation failed"
   ```

   **⚠️ IMPORTANT:** This UPDATES the existing `docs/consolidated-[feature].txt` file that was created by flow-prd. Do NOT overwrite - UPDATE it by reading first, then updating the fields.

7. Continue to next incomplete PRD until all PRDs complete
8. Default: 10 iterations (stories) unless specified

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

### Test application
```
/flow test [prd-name]
```
- Runs comprehensive testing of all implemented features
- Uses testing-agent with chrome-devtools MCP
- Tests all completed stories (where `passes: true`)
- Creates error log at `docs/errors-[feature-name].md`
- Uses standard test user: `revccnt@gmail.com` / `Elishiba!90`

**Process:**
1. Reads PRD to find completed stories
2. Starts dev server: `pnpm dev`
3. Opens application using chrome-devtools MCP
4. Tests user signup/login
5. Tests each completed feature's acceptance criteria
6. Checks console for errors
7. Logs all errors found with details
8. Creates error log markdown file

**What gets tested:**
- User authentication (signup, login, logout)
- All completed stories' acceptance criteria
- Console errors (JavaScript, network, API)
- UI functionality
- Navigation between pages
- Form submissions
- Data display

**Error log format:** `docs/errors-[feature-name].md`
- Each error with story ID, severity, error message
- Steps to reproduce
- Expected vs actual behavior
- Related file references
- Suggested fixes

**Examples:**
```bash
/flow test                    # Test current PRD (auto-detects)
/flow test authentication     # Test authentication PRD
/flow test task-priority      # Test task-priority PRD
```

**After testing:**
- Review error log: `docs/errors-[feature-name].md`
- Run `/flow consolidate [prd-name]` to fix errors

---

### Consolidate and fix errors
```
/flow consolidate [prd-name]
```
- Reads error log from `docs/errors-[feature-name].md`
- Identifies which stories/steps have errors
- Re-runs ONLY the affected steps (not entire stories)
- Fixes specific errors found during testing
- Does NOT reimplement completed features

**Process:**
1. Read error log: `docs/errors-[feature-name].md`
2. Parse each error to identify:
   - Which story (US-XXX) has the error
   - Which step/mavenStep needs to be re-run
   - What the specific error is
3. For each error:
   - Spawn appropriate agent (development, quality, security, etc.)
   - Tell agent exactly what error to fix
   - Wait for fix to be applied
4. Re-test ONLY the fixed item
5. Mark error as resolved in log
6. Continue until all errors fixed

**What it does NOT do:**
- Does NOT run full mavenSteps again
- Does NOT re-implement completed features
- Does NOT touch working code
- Only fixes the specific errors identified

**Examples:**
```bash
/flow consolidate            # Consolidate current PRD
/flow consolidate auth       # Consolidate authentication PRD
```

**Output:**
- Shows which errors are being fixed
- Shows which agent is handling each fix
- Commits each fix separately
- Updates error log as fixes are applied

---

### Help
```
/flow help
```
- Displays comprehensive help information
- Shows detailed command reference, workflow, and troubleshooting

---

# Comprehensive Guide

## Table of Contents
1. [Quick Start](#quick-start)
2. [Command Reference](#command-reference)
3. [Maven 10-Step Workflow](#maven-10-step-workflow)
4. [Specialist Agents](#specialist-agents)
5. [MCP Tool Assignment](#mcp-tool-assignment)
6. [Quality Standards](#quality-standards)
7. [Browser Testing](#browser-testing)
8. [Required MCPs](#required-mcps)
9. [Testing & Consolidation](#testing--consolidation)
10. [Mobile Development](#mobile-development)
11. [Common Workflows](#common-workflows)
12. [Troubleshooting](#troubleshooting)

---

## Quick Start

### For New Users

**Step 1: Create your first PRD**
```
Tell me you want to create a PRD for [feature description]
Example: "Create a PRD for a user authentication system"
```

**Step 2: Convert to JSON format**
```
/flow-convert
```
This creates `docs/prd-[feature-name].json`

**Step 3: Start autonomous development**
```
/flow start
```

The flow will:
- Scan for all incomplete PRDs
- Process each story automatically
- Spawn specialist agents for each step
- Commit changes with proper format
- Continue until ALL stories are complete

**Step 4: Monitor progress**
```
/flow status
```

---

## Command Reference

### `/flow start [max-iterations]`
Starts autonomous flow execution.

**Parameters:**
- `max-iterations` (optional): Number of stories to process (default: 10)

**Behavior:**
- Scans for all PRD files in `docs/`
- Identifies incomplete stories (`passes: false`)
- Processes stories in priority order
- Spawns specialist agents for each mavenStep
- Runs quality checks after each story
- Commits changes with standardized format
- Updates PRD to mark story complete
- Continues to next story automatically

**Examples:**
```bash
/flow start          # Process up to 10 stories (default)
/flow start 20       # Process up to 20 stories
/flow start 1        # Process exactly 1 story then stop
```

**What happens during execution:**
1. Validates prerequisites (docs/, PRD files, incomplete stories)
2. Lists all PRD files found
3. Shows which PRD will be processed first
4. For each incomplete story:
   - Displays story ID and title
   - Shows mavenSteps to be executed
   - Shows MCPs assigned for each step
   - Spawns agents one at a time
   - Waits for each agent to complete
   - Runs typecheck and lint
   - Creates git commit
   - Marks story as complete in PRD
5. Moves to next story automatically
6. Continues until max iterations or all PRDs complete

### `/flow status`
Shows current status of all PRDs.

**Output includes:**
- Total PRD files found
- Completion status for each PRD
- List of all stories with completion status
- Recent progress from progress files

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
  [2025-01-10] prd-task-priority.json - US-003 Added priority dropdown
```

### `/flow continue [prd-name] [max-iterations]`
Resumes flow execution from where it left off.

**Parameters:**
- `prd-name` (optional): Specific PRD to process (default: current)
- `max-iterations` (optional): Number of stories to process

**When to use:**
- After fixing an error that stopped the flow
- After manually editing PRD or code
- To continue with a specific PRD
- To process more stories than originally planned

**Examples:**
```bash
/flow continue           # Continue with current PRD
/flow continue 5         # Process 5 more stories
/flow continue auth 10   # Process auth PRD for 10 stories
```

### `/flow reset [prd-name]`
Archives current PRD run and resets for fresh start.

**Parameters:**
- `prd-name` (optional): Specific PRD to reset (prompts if omitted)

**Behavior:**
- Creates archive: `archive/YYYY-MM-DD-[feature-name]/`
- Moves current PRD and progress file to archive
- Resets all stories to `passes: false`
- Creates fresh PRD and progress files
- Prompts for confirmation before archiving

**Examples:**
```bash
/flow reset           # Prompts to select PRD
/flow reset auth      # Reset auth PRD specifically
```

**When to use:**
- PRD has fundamental issues
- Want to start over with different approach
- Need to archive current progress before major changes

---

## Maven 10-Step Workflow

Each story is implemented through specific steps, each handled by a specialist agent.

| Step | Agent | Description | Duration |
|------|-------|-------------|----------|
| 1 | development-agent | Foundation - Import UI or create from scratch | ~5-10 min |
| 2 | development-agent | Package Manager - Convert npm → pnpm | ~2-5 min |
| 3 | refactor-agent | Feature Structure - Restructure folders | ~5-10 min |
| 4 | refactor-agent | Modularization - Split large components | ~5-15 min |
| 5 | quality-agent | Type Safety - Remove 'any' types, add @ aliases | ~5-10 min |
| 6 | refactor-agent | UI Centralization - Move to @shared/ui | ~5-10 min |
| 7 | development-agent | Data Layer - Backend setup, Supabase integration | ~10-20 min |
| 8 | security-agent | Auth Integration - Firebase + Supabase auth | ~10-15 min |
| 9 | development-agent | MCP Integration - Connect MCP tools | ~5-10 min |
| 10 | security-agent | Security & Error Handling | ~10-15 min |
| 11 | design-agent | Mobile Design - Professional UI (optional) | ~15-20 min |

**Total typical story duration:** 1-2 hours depending on complexity

**Step dependencies:**
- Steps must be completed in order
- Each step builds on previous steps
- Quality checks run after all steps complete

---

## Specialist Agents

### development-agent (🟢 Green)
**Use for:** Steps 1, 2, 7, 9

**Responsibilities:**
- Import UI with mock data or create from scratch
- Convert package manager (npm → pnpm)
- Set up data layer (Supabase, API clients)
- Integrate MCP tools
- Set up project foundation

**Key actions:**
- Creates base components with mock data
- Installs and configures Supabase client
- Sets up API middleware
- Connects MCP tools (web-search, web-reader, browser)
- Commits with prefix `feat:`

### refactor-agent (🔵 Blue)
**Use for:** Steps 3, 4, 6

**Responsibilities:**
- Restructure to feature-based architecture
- Modularize large components
- Centralize UI components to @shared/ui

**Key actions:**
- Moves code to feature-based folders
- Splits components >300 lines
- Extracts reusable UI components
- Enforces architecture rules
- Commits with prefix `refactor:`

### quality-agent (🟣 Purple)
**Use for:** Step 5

**Responsibilities:**
- Type safety enforcement
- Import alias verification
- Quality standards compliance

**Key actions:**
- Removes ALL 'any' types (zero tolerance)
- Converts relative imports to @ aliases
- Verifies component sizes
- Blocks on quality violations
- Auto-fixes import paths
- Commits with prefix `fix:`

**BLOCKING Issues:**
- 'any' types in code
- Gradients in CSS
- Emojis in UI components
- Relative imports

### security-agent (🔴 Red)
**Use for:** Steps 8, 10

**Responsibilities:**
- Authentication flow implementation
- Security vulnerability checks
- Error handling setup

**Key actions:**
- Firebase Auth integration
- Supabase Row-Level Security (RLS)
- JWT validation
- Input sanitization
- Error boundary implementation
- Commits with prefix `security:`

### design-agent (🩷 Pink)
**Use for:** Step 11 (optional, mobile apps only)

**Responsibilities:**
- Professional mobile UI/UX design
- Apple design methodology application

**Key actions:**
- Applies professional visual design
- Implements proper navigation patterns
- Ensures touch targets (44x44pt minimum)
- Validates in Expo preview
- Commits with prefix `design:`

### testing-agent (🟠 Orange)
**Use for:** `/flow test` command (not part of mavenSteps)

**Responsibilities:**
- Comprehensive application testing
- Error logging and reporting
- Browser automation with chrome-devtools MCP

**Key actions:**
- Opens application using chrome-devtools MCP
- Tests all completed stories (where `passes: true`)
- Tests signup/login with standard test user
- Checks console for errors (logs ALL errors found)
- Tests each acceptance criterion
- Creates error log at `docs/errors-[feature-name].md`
- Reports testing results with error counts and severity

**Required MCP:**
- chrome-devtools (REQUIRED - cannot test without it)

**Test Credentials:**
- Email: `revccnt@gmail.com`
- Password: `Elishiba!90`

**Commit prefix:** `test:` (only commits if making test fixes)

---

### mobile-app-agent (🔵 Cyan)
**Use for:** Mobile development (React Native + Expo apps)

**Responsibilities:**
- Mobile screen implementation with Expo Router
- Offline-first data management with TanStack Query
- Native UI patterns (swipe, pull-to-refresh, bottom sheets)
- NativeWind styling (Tailwind for React Native)
- Push notifications with Firebase Cloud Messaging
- Touch-optimized interactions (44pt minimum)

**Key actions:**
- Creates mobile screens in `mobile/app/` folder
- Implements offline support with AsyncStorage
- Uses NativeWind utility classes for styling
- Integrates Firebase Cloud Messaging for push notifications
- Implements native UI patterns (pull-to-refresh, swipe actions)
- Tests with Expo Go or device simulators
- Uses same Supabase backend as web app
- Commits with prefix `mobile:`

**Required MCPs:**
- supabase (REQUIRED - shared backend with web)
- web-search-prime (Recommended - for mobile best practices)

**Mobile Location:**
- Works in `mobile/` folder
- Mobile PRDs in `mobile/docs/prd-*.json`
- Uses Expo Router (file-based routing)
- TypeScript with strict mode

**Server Management:**
- Expo server runs on port 8081
- Stop ONLY Expo process, not all Node processes
- Use: `kill -9 $(lsof -ti:8081)`

**Tech Stack:**
- Frontend: React Native + Expo
- Navigation: Expo Router
- Styling: NativeWind (Tailwind)
- State: TanStack Query + Zustand
- Auth: Firebase Authentication
- Backend: Supabase (shared with web)
- Push: Firebase Cloud Messaging
- Offline: AsyncStorage with sync


## MCP Tool Assignment

### What are MCPs?
MCPs (Model Context Protocol) extend Claude with external tools like databases, web search, and browser automation.

### How MCP Assignment Works

**1. PRD specifies MCPs per step:**
```json
{
  "id": "US-001",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

**2. Flow tells agent which MCPs to use:**
```
*** CRITICAL: MCP TOOLS INSTRUCTION ***
You MUST use the Supabase MCP tools for ALL database operations.
SCAN FIRST - Use MCP to list/check what exists in the database BEFORE making changes.
Query the database DIRECTLY using Supabase MCP tools.

Story: US-001, Step 1
MCPs: supabase
```

**3. Agent uses those MCPs:**
- Checks if MCPs are available in their tool set
- Uses MCP tools directly to query database, run migrations, etc.
- Falls back to standard tools only if MCPs unavailable

### Available MCPs

| MCP Name | Purpose | Steps Used For |
|----------|---------|----------------|
| supabase | Database operations | 1, 7, 8, 10 |
| web-search-prime | Research, documentation | All steps |
| web-reader | Read web content | All steps |
| chrome-devtools | Browser testing | Testing phases |
| playwright | Browser automation | Testing phases |
| vercel | Deployment to Vercel | 9 |
| wrangler | Deployment to Cloudflare | 9 |
| figma | Design work | 11 |

**MCP Usage Rules:**
- **SCAN FIRST** - Always list/check what exists before making changes
- **Query directly** - Use MCP tools, don't read migration files
- **Verify in actual database** - Don't trust type files, verify with MCP
- **Fall back gracefully** - Use standard tools if MCP unavailable

---

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
- mcpTools: { step1: ["supabase"], step7: ["supabase", "web-search-prime"] }
- Description: [Story description]
- Acceptance Criteria: [List from PRD]

**Processing:**

1. [Step 1 - Foundation]
   Spawning development agent...
   Instruction: "Use these MCPs: supabase"
   INSTRUCTION: USE SUPABASE MCP TOOLS to query/verify database directly. DO NOT just read type files.
   → [Waiting for completion]
   → [Agent completed successfully]

2. [Step 3 - Feature Structure]
   Spawning refactor agent...
   → [Waiting for completion]
   → [Agent completed successfully]

3. [Step 5 - Type Safety]
   Spawning quality agent...
   → [Waiting for completion]
   → [Agent completed successfully]

4. [Step 7 - Data Layer]
   Spawning development agent...
   Instruction: "Use these MCPs: supabase, web-search-prime"
   INSTRUCTION: USE SUPABASE MCP TOOLS to query/verify database directly. USE WEB-SEARCH for research.
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

**IMPORTANT: MCP Assignment**

The PRD file specifies which MCPs to use for each step:

```json
{
  "id": "US-001",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

**How it works:**
1. Read the PRD's `mcpTools` for the current step
2. Tell the agent: "Use these MCPs: [list]"
3. Agent figures out how to use them
4. If MCPs aren't specified, agent uses standard tools

**Simple and direct:**
- No complex discovery or categorization
- No merging or mapping logic
- Just pass the MCP names to the agent
- Agent knows their own tools and how to use them

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

## Quality Standards

### Zero Tolerance Rules

**The following violations will BLOCK commits:**

1. **'any' Types - ZERO TOLERANCE**
   - No `: any`, `: any[]`, `<any>`, `Promise<any>`
   - Use proper interfaces or `unknown` with type guards

2. **Gradients in CSS - ZERO TOLERANCE**
   - No `linear-gradient`, `radial-gradient`, `conic-gradient`
   - Use solid professional colors only

3. **Emojis in UI - ZERO TOLERANCE**
   - No emojis anywhere in UI components
   - Use professional icon libraries (lucide-react, heroicons)
   - Never use emojis as icons or in text

4. **Relative Imports**
   - No `import { Foo } from './foo'` or `../bar`
   - Use `@/` aliases for all imports

### Component Size Limits

- **Maximum 300 lines** per component
- Components larger than 300 lines must be split
- Flagged for refactoring agent to modularize

### Professional Color Palette

**Semantic Colors:**
```css
--color-primary: #3b82f6;      /* Blue */
--color-success: #10b981;      /* Green */
--color-warning: #f59e0b;      /* Amber */
--color-error: #ef4444;        /* Red */
--color-neutral: #6b7280;      /* Gray */
```

**Rules:**
- Use semantic color names
- No hard-coded hex values
- No gradients (solid colors only)

### Import Path Rules

**✅ CORRECT:**
```tsx
import { Button } from '@shared/ui';
import { useAuth } from '@features/auth/hooks';
import { apiClient } from '@/shared/api';
```

**❌ BLOCKED:**
```tsx
import { Button } from '../../../shared/ui';
import { useAuth } from '../hooks';
```

---

## Browser Testing

### Test User Credentials (Standard Across All Projects)

**Email:** `revccnt@gmail.com`
**Password:** `Elishiba!90`

### Testing Process

**For ALL web applications with browser MCPs:**

1. **Start dev server:** `pnpm dev`
2. **Navigate to application** using browser MCP
3. **Check browser console** for errors and warnings
4. **Check Network tab** for failed API calls
5. **Test all user flows** with standard test user
6. **Fix any console errors** found
7. **Re-test** to verify clean console

### Console Log Verification

**ALWAYS read console logs. Common issues to fix:**

| Issue | Example | Fix |
|-------|---------|-----|
| ReferenceError | `Uncaught ReferenceError: foo is not defined` | Import or define the variable |
| TypeError | `Cannot read property 'x' of undefined` | Add null checks |
| Failed to fetch | `Failed to fetch: /api/endpoint` | Check API route exists |
| CORS | `CORS policy: No 'Access-Control-Allow-Origin'` | Configure CORS headers |
| 404 / 500 | API returns error status | Fix backend endpoint |

### Role Switching (Multi-Role Apps)

**Do NOT create separate accounts for each role. Use role switching:**

1. Log in as `revccnt@gmail.com`
2. Use role switcher in application
3. Change roles: SUPER_ADMIN → SHOP_OWNER → SHOP_EMPLOYEE
4. Test each role's features
5. Switch back and forth as needed

---

## Required MCPs

### Mandatory MCPs for Maven Flow

Maven Flow requires specific MCP servers to be configured for autonomous development and testing to function correctly.

#### Two Mandatory MCPs

**1. Supabase MCP (MANDATORY)**
- **Purpose:** Direct database access, schema verification, migrations, type generation
- **Why mandatory:**
  - Agents need to QUERY the actual database (not read files)
  - Agents need to VERIFY tables and schema exist
  - Agents need to CREATE tables and run migrations
  - Agents need to GENERATE TypeScript types from live schema
- **Without Supabase MCP:**
  - Agents will fall back to reading migration files (doesn't verify actual database)
  - Agents will create migration scripts manually (error-prone)
  - Agents cannot verify what's actually in the database

**2. chrome-devtools MCP (MANDATORY)**
- **Purpose:** Live browser testing, console log reading, application verification
- **Why mandatory:**
  - testing-agent MUST open the application to test features
  - Agents MUST read console logs to find errors
  - Agents MUST verify UI works in real browser
  - Agents MUST test user flows end-to-end
- **Without chrome-devtools MCP:**
  - testing-agent cannot test the application
  - Console errors go undetected
  - Features cannot be verified in browser
  - Testing becomes manual and incomplete

#### How to Verify MCPs Are Configured

**Before running `/flow start`:**

1. **Check Claude Code MCP Settings:**
   - Open Claude Code Settings
   - Go to MCP Servers section
   - Verify "supabase" is in the list
   - Verify "chrome-devtools" is in the list

2. **Test MCPs are working:**
   - Start a conversation
   - Ask agent to list tables using Supabase MCP
   - Ask agent to open browser using chrome-devtools MCP

3. **If MCPs are missing:**
   - DO NOT start `/flow start`
   - Configure the missing MCP first
   - Restart Claude Code
   - Verify again

#### Optional MCPs (Recommended but Not Required)

| MCP Name | Purpose | When to Include |
|----------|---------|-----------------|
| web-search-prime | Research documentation | All steps |
| web-reader | Read web pages | All steps |
| playwright | Browser automation testing | Testing phases |
| wrangler | Cloudflare Workers deployment | Step 9 |
| vercel | Vercel deployment | Step 9 |
| figma | Design work | Step 11 (mobile) |

**Only include these MCPs if:**
- They are actually configured in your environment
- The story specifically needs them
- You've verified they're available

#### Summary

**MANDATORY MCPs (Must Have):**
- ✅ supabase
- ✅ chrome-devtools

**Before running `/flow start`:**
1. Verify supabase MCP is configured
2. Verify chrome-devtools MCP is configured
3. Test both MCPs work correctly
4. Only then start the flow

**Remember:** Without these MCPs, Maven Flow cannot function as designed. Agents will fall back to less reliable methods (reading files instead of querying database, manual testing instead of automated browser testing).

---

## Testing & Consolidation

### Workflow: Test → Log → Consolidate → Fix

Maven Flow includes a systematic testing and error consolidation workflow to ensure quality.

### Step 1: Test (`/flow test`)

**Purpose:** Comprehensive automated testing of all completed features

**What happens:**
1. Reads PRD to find completed stories (where `passes: true`)
2. Starts dev server: `pnpm dev`
3. Opens application using chrome-devtools MCP
4. Tests user signup/login with standard test credentials
5. Tests each completed feature's acceptance criteria
6. Checks console for errors (logs ALL errors found)
7. Tests navigation, forms, data display
8. Creates error log at `docs/errors-[feature-name].md`

**Standard Test User:**
- Email: `revccnt@gmail.com`
- Password: `Elishiba!90`

**What gets tested:**
- User authentication (signup, login, logout)
- All completed stories' acceptance criteria
- Console errors (JavaScript, network, API)
- UI functionality
- Navigation between pages
- Form submissions
- Data display

**Example:**
```bash
/flow test task-priority
```

**Output:**
- Shows which features are being tested
- Reports errors in real-time
- Creates error log markdown file
- Summary with error counts by severity

### Step 2: Review Error Log

**Error log format:** `docs/errors-[feature-name].md`

**Each error includes:**
- Story ID (US-XXX)
- Severity (Critical / High / Medium / Low)
- Error type (Console Error / Network Error / UI Issue)
- Error message (exact text from console)
- Steps to reproduce
- Expected vs actual behavior
- Related file references
- Suggested fixes

**Example error log entry:**
```markdown
## Error 1

**Story:** US-003 - Add priority selector
**Feature:** Task creation form
**Severity:** High

**Error Type:** Console Error

**Error Message:**
```
Uncaught TypeError: Cannot read property 'map' of undefined
at PrioritySelector.tsx:24
```

**Steps to Reproduce:**
1. Navigate to /tasks/create
2. Click on "Priority" dropdown
3. Observe error in console

**Expected Behavior:**
Priority dropdown shows options: Low, Medium, High, Urgent

**Actual Behavior:**
Application crashes, dropdown doesn't render

**Related Files:**
- File: src/features/tasks/components/PrioritySelector.tsx
- Line: 24
- Component: PrioritySelector

**Suggested Fix:**
Check that priorities prop is defined before mapping. Add default value or null check.
```

### Step 3: Consolidate (`/flow consolidate`)

**Purpose:** Fix ONLY the specific errors found during testing (NOT reimplement features)

**What happens:**
1. Reads error log from `docs/errors-[feature-name].md`
2. Parses each error to identify:
   - Which story (US-XXX) has the error
   - Which step/mavenStep needs to be re-run
   - What the specific error is
3. For each error:
   - Spawns appropriate specialist agent (development, quality, security, etc.)
   - Tells agent exactly what error to fix
   - Waits for fix to be applied
4. Re-tests ONLY the fixed item
5. Marks error as resolved in log
6. Continues until all errors fixed

**What it does NOT do:**
- Does NOT run full mavenSteps again
- Does NOT re-implement completed features
- Does NOT touch working code
- Only fixes the specific errors identified

**Example:**
```bash
/flow consolidate task-priority
```

**Output:**
- Shows which errors are being fixed
- Shows which agent is handling each fix
- Commits each fix separately
- Updates error log as fixes are applied

### Step 4: Re-test

After consolidation:
1. Run `/flow test [prd-name]` again
2. Verify all errors are fixed
3. Verify console is clean
4. If errors remain, repeat consolidation

### Complete Workflow Example

```bash
# 1. Run development flow
/flow start

# 2. Test all completed features
/flow test task-priority

# Output: Testing Complete
# Error Log: docs/errors-task-priority.md
# Total Errors: 5
# Critical: 1 | High: 2 | Medium: 1 | Low: 1

# 3. Review error log
cat docs/errors-task-priority.md

# 4. Fix all errors
/flow consolidate task-priority

# Output:
# Fixing Error 1: TypeError in PrioritySelector
# Spawning quality-agent...
# → Fixed
# Fixing Error 2: Network error in API
# Spawning development-agent...
# → Fixed
# ...

# 5. Re-test to verify
/flow test task-priority

# Output: Testing Complete
# Total Errors: 0
# ✅ All features working correctly
```

### Key Differences: `/flow start` vs `/flow consolidate`

| Aspect | `/flow start` | `/flow consolidate` |
|--------|---------------|---------------------|
| Purpose | Implement new features | Fix specific errors |
| Input | PRD stories | Error log |
| Runs | Full mavenSteps for each story | Only affected steps |
| Scope | Entire story implementation | Specific error fixes |
| Commits | Full feature commits | Targeted bug fixes |
| Result | New features implemented | Errors resolved |

---


---

## Mobile Development

Maven Flow includes comprehensive support for React Native + Expo mobile app development with shared Supabase backend.

### Quick Start for Mobile

**Step 1: Setup mobile environment**
```bash
/flow-mobile setup
```
This creates the complete mobile app structure in `mobile/` folder.

**Step 2: Create mobile PRDs**
```bash
flow-prd-mobile [feature-name]
```
Converts existing web PRDs to mobile-specific PRDs with offline support.

**Step 3: Sync with web app**
```bash
/flow-mobile sync
```
Syncs database types and configuration from web to mobile.

**Step 4: Develop mobile features**
```bash
/flow start
```
Maven Flow detects mobile PRDs and uses mobile-app-agent for implementation.

### Mobile App Structure

```
mobile/
├── app/                    # Expo Router screens (file-based routing)
│   ├── (tabs)/            # Tab navigation screens
│   ├── auth/              # Authentication screens
│   └── _layout.tsx        # Root layout
├── components/            # Mobile-specific components
├── lib/                   # Utilities (Supabase, Firebase, Storage)
├── hooks/                 # Custom React hooks
├── store/                 # Zustand state management
├── constants/             # App constants
├── types/                 # TypeScript types (shared with web)
├── docs/                  # Mobile PRDs
│   ├── prd-*.json        # Mobile PRDs
│   └── progress-*.txt    # Mobile progress files
└── package.json
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | React Native + Expo SDK 51 |
| **Navigation** | Expo Router (file-based routing) |
| **Styling** | NativeWind (Tailwind for React Native) |
| **State** | TanStack Query + Zustand |
| **Auth** | Firebase Authentication |
| **Backend** | Supabase (shared with web app) |
| **Push** | Firebase Cloud Messaging |
| **Offline** | AsyncStorage with auto-sync |

### Mobile-Specific Features

#### Offline-First Architecture
All mobile features work offline with automatic sync:

**Read Pattern:**
1. Check AsyncStorage cache first
2. If fresh (< 5 min), use cached data
3. If missing/stale, fetch from Supabase
4. Update cache and display

**Write Pattern:**
1. Optimistically update UI immediately
2. If online: Execute immediately
3. If offline: Queue in AsyncStorage
4. When back online: Process queue automatically

#### Native UI Patterns
Use mobile-specific interactions:
- **Pull-to-refresh** for data reload
- **Swipe actions** for quick actions (delete, complete)
- **Bottom sheets** for options/modals
- **Tab bar** for main navigation
- **Stack navigation** for drilling down
- **Long-press** for context menus

#### Touch Targets
- **Minimum 44x44 points** for all touch targets (Apple)
- **48x48 dp minimum** for Android
- Adequate spacing between targets

#### Push Notifications
- Firebase Cloud Messaging for push notifications
- Task assignments, due reminders, status changes
- Background message handling
- Notification channels (Android)

### Commands

#### `/flow-mobile setup`
Creates complete React Native + Expo mobile app:
- Installs all dependencies
- Configures Expo Router
- Sets up NativeWind styling
- Configures Supabase client (shared with web)
- Configures Firebase Auth + FCM
- Implements offline storage + sync logic
- Creates base screens and navigation

#### `/flow-mobile status`
Shows mobile app status:
- Mobile folder existence
- Expo configuration
- Dependencies status
- Supabase connection
- Firebase configuration
- Mobile PRDs and progress
- Offline sync status

#### `/flow-mobile sync`
Synchronizes web and mobile:
- Database types (from Supabase schema)
- Environment variables
- API endpoints
- Auth configuration

#### `flow-prd-mobile [feature-name]`
Converts web PRD to mobile PRD:
- Adds offline requirements
- Adds native UI patterns
- Adds touch interactions
- Adds push notification specs
- Creates `mobile/docs/prd-[feature-name].json`

### Development Workflow

**For Web Development:**
```bash
# 1. Create web PRD
flow-prd
# 2. Convert to JSON
flow-convert
# 3. Start development
/flow start
```

**For Mobile Development:**
```bash
# 1. Setup mobile (one-time)
/flow-mobile setup

# 2. Create mobile PRDs from web PRDs
flow-prd-mobile task-management
flow-prd-mobile user-auth

# 3. Sync types and config
/flow-mobile sync

# 4. Start mobile development
/flow start
```

### Testing Mobile Apps

**Test with Expo Go (quickest):**
```bash
cd mobile
pnpm start
# Scan QR code with Expo Go app on phone
```

**Test on iOS simulator:**
```bash
cd mobile
pnpm ios
```

**Test on Android emulator:**
```bash
cd mobile
pnpm android
```

**Test offline functionality:**
1. Load app and data
2. Enable Airplane mode
3. Navigate around (data should load from cache)
4. Create/update/delete items
5. Disable Airplane mode
6. Verify sync happens automatically

### Building and Deploying

**Build with EAS Build:**
```bash
cd mobile
eas build --platform ios
eas build --platform android
```

**Submit to stores:**
```bash
eas submit --platform ios
eas submit --platform android
```

**Over-the-air updates:**
```bash
eas update --branch production
```

### Shared Backend

Mobile app shares the same Supabase backend as web:
- Same database schema
- Same RLS policies
- Same API endpoints
- Same types (generated from schema)

**Sync types:**
```bash
/flow-mobile sync
```

This generates `mobile/types/database.types.ts` from Supabase schema.

### Mobile PRD Structure

Mobile PRDs include additional fields:

**Offline Requirements:**
```json
"offline": {
  "required": true,
  "cacheKey": "tasks-cache",
  "cacheTTL": 300000,
  "syncStrategy": "auto-on-online"
}
```

**Native UI Patterns:**
```json
"uiPatterns": {
  "navigation": "tab-bar",
  "actions": {
    "complete": "swipe-left",
    "delete": "swipe-right",
    "edit": "tap-card"
  },
  "refresh": "pull-to-refresh"
}
```

**Push Notifications:**
```json
"notifications": {
  "enabled": true,
  "events": [
    {
      "event": "task_assigned",
      "title": "New Task Assigned",
      "body": "You've been assigned: {task_title}",
      "tapAction": "navigate_to_task_details"
    }
  ]
}
```

### Agent Assignments for Mobile

| Maven Step | Agent | Purpose for Mobile |
|------------|-------|-------------------|
| 1 | mobile-app-agent | Create mobile screens with Expo Router |
| 2 | mobile-app-agent | Mobile dependencies setup |
| 3 | mobile-app-agent | Mobile folder structure |
| 5 | quality-agent | Type safety (same as web) |
| 6 | mobile-app-agent | Centralize mobile components |
| 7 | mobile-app-agent | Supabase integration (shared) |
| 8 | mobile-app-agent | Firebase Auth + push notifications |
| 9 | mobile-app-agent | Mobile MCP integrations |
| 10 | mobile-app-agent | Mobile security + error handling |
| 11 | design-agent | Professional mobile UI/UX |

### Key Differences: Web vs Mobile

| Aspect | Web | Mobile |
|--------|-----|--------|
| **Framework** | Next.js | React Native + Expo |
| **Routing** | Next.js App Router | Expo Router |
| **Styling** | Tailwind CSS | NativeWind (Tailwind) |
| **State** | TanStack Query | TanStack Query + AsyncStorage |
| **Navigation** | Links/buttons | Tabs/stacks/gestures |
| **Offline** | Rarely required | **Always required** |
| **Updates** | Realtime | Queue + sync |
| **Notifications** | In-app only | Push (FCM) |
| **Input** | Keyboard + mouse | Touch + keyboard |
| **Touch Targets** | N/A | 44x44pt minimum |

### Server Management for Mobile

**Expo server runs on port 8081.**

**❌ FORBIDDEN:**
```bash
pkill -9 node
killall node
```

**✅ CORRECT:**
```bash
# Find Expo server
lsof -ti:8081
# Kill ONLY that process
kill -9 $(lsof -ti:8081)
```

## Common Workflows

### Workflow 1: New Feature with Database

**Story requires:** Database schema + Backend API + UI

**Recommended mavenSteps:** `[1, 3, 5, 7, 10]`

**What happens:**
1. **Step 1 (dev):** Create table with Supabase MCP, generate types
2. **Step 3 (refactor):** Structure to feature-based folders
3. **Step 5 (quality):** Remove 'any' types, add @ aliases
4. **Step 7 (dev):** Create API endpoints, connect to database
5. **Step 10 (security):** Add RLS policies, error handling

**Total time:** ~1-2 hours

### Workflow 2: UI Component Only

**Story requires:** Add new UI component to existing page

**Recommended mavenSteps:** `[3, 5, 6]`

**What happens:**
1. **Step 3 (refactor):** Create in feature-based structure
2. **Step 5 (quality):** Type safety, no 'any' types
3. **Step 6 (refactor):** Move reusable parts to @shared/ui

**Total time:** ~30-45 minutes

### Workflow 3: Authentication Flow

**Story requires:** User signup, login, session management

**Recommended mavenSteps:** `[1, 7, 8, 10]`

**What happens:**
1. **Step 1 (dev):** Create auth UI pages
2. **Step 7 (dev):** Set up Supabase Auth, Firebase integration
3. **Step 8 (security):** Implement auth flow, RLS policies
4. **Step 10 (security):** Security hardening, error handling

**Total time:** ~1.5 hours

### Workflow 4: Mobile App (Expo/React Native)

**Story requires:** Mobile screen with professional design

**Recommended mavenSteps:** `[1, 3, 5, 6, 11]`

**What happens:**
1. **Step 1 (dev):** Create base screen
2. **Step 3 (refactor):** Structure properly
3. **Step 5 (quality):** Type safety
4. **Step 6 (refactor):** Centralize UI components
5. **Step 11 (design):** Apply professional mobile design

**Total time:** ~1.5-2 hours

---

## Troubleshooting

### Prerequisites Issues

**Error: `No docs/ directory found`**
```bash
# Fix: Create the directory
mkdir docs
```

**Error: `No PRD files found in docs/`**
```bash
# Fix: Create a PRD using flow-prd skill
Tell me you want to create a PRD for [feature]
```

**Message: `All PRDs complete! No work to do.`**
- All stories in all PRDs have `passes: true`
- Create a new PRD or add more stories to existing PRD

### Flow Execution Issues

**Flow stops mid-story:**

1. **Check progress file:**
   ```bash
   cat docs/progress-[feature-name].txt
   ```

2. **Review recent commits:**
   ```bash
   git log --oneline -10
   ```

3. **Fix the issue** (code error, typecheck fail, etc.)

4. **Resume flow:**
   ```bash
   /flow continue
   ```

**Typecheck failing:**
- Run `pnpm typecheck` to see specific errors
- Fix 'any' types, missing imports, type mismatches
- Run `/flow continue` when fixed

**Quality agent blocking commit:**
- Check for 'any' types, gradients, emojis
- Fix all BLOCKING issues
- Run `/flow continue`

### MCP Tool Issues

**Agent not using MCP tools:**

1. **Verify MCP is configured:**
   - Check Claude Code MCP settings
   - Ensure MCP server is running

2. **Check PRD mcpTools:**
   ```json
   "mcpTools": {
     "step1": ["supabase"]
   }
   ```

3. **Agent should see instruction:**
   ```
   Use these MCPs: supabase
   ```

4. **If still not working:**
   - Check agent has `tools` field in frontmatter (should NOT have it)
   - Restart Claude Code
   - Try `/flow continue`

### Architecture Issues

**Import path errors:**
- Ensure `tsconfig.json` has correct `paths` configuration
- Use `@/` aliases, not relative imports
- quality-agent will auto-fix most import issues

**Component too large (>300 lines):**
- refactor-agent will split it
- Or manually split before running flow
- Mark story as complete if acceptable

### Browser Testing Issues

**Console has errors:**
- Fix all JavaScript errors before marking complete
- Check for missing imports, undefined variables
- Verify API endpoints exist

**Test user cannot log in:**
- Create user: `revccnt@gmail.com` / `Elishiba!90`
- Verify signup flow works
- Check database for user record

### Getting Help

**Still stuck?**
1. Run `/flow status` for detailed diagnostics
2. Check progress file: `docs/progress-[feature-name].txt`
3. Review git history: `git log --oneline -20`
4. Check agent documentation in `.claude/agents/`

---

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

## Memory System Architecture

### Story-Level Memory Files

Each story gets a permanent memory file: `docs/[feature]/story-US-[###]-[title].txt`

**Folder Structure:**
```
docs/
├── authentication/              # Story memories folder (auto-created)
│   ├── story-US-001-login.txt
│   ├── story-US-002-signup.txt
│   └── story-US-003-reset-password.txt
├── prd-authentication.md       # Human-readable PRD
├── prd-authentication.json     # Machine-readable PRD
└── consolidated-authentication.txt  # Consolidated memory (after all stories)
```

**Memory File Format:**
```markdown
---
memoryVersion: 1
schemaVersion: 1
storyId: US-001
storyTitle: User Login
feature: Authentication System
completedDate: 2025-01-18
agents: development-agent, security-agent
---

# Story US-001: User Login

## Implemented
- Created users table with id, email, password_hash columns
- Built login UI with email/password fields and validation
- Implemented authenticate() server action
- Added session management with cookies

## Database Decisions
- Users table in Supabase with RLS policies
- Password hashing using bcrypt (cost factor 10)
- Session tokens stored in supabase_auth.sessions

## UI/UX Patterns
- Login form uses centralized Form component
- Error messages display inline below fields
- Success redirects to /dashboard

## Integration Points
- Authentication state managed via React Context (AuthContext)
- Server actions in src/actions/auth.ts
- Session validation middleware for protected routes

## Lessons Learned
- Always use Supabase MCP for database operations
- Test authentication flow with real credentials
- RLS policies must be applied before testing

## Best Practices Identified
- Server actions return { success, error, data } pattern
- All auth-related UI components use AuthContext

## Commit
feat: add user login with email/password authentication
```

### Consolidated Memory (PRD-Level)

After ALL stories in a PRD complete, consolidates into `docs/consolidated-[feature].txt` (~30-50K tokens max)

**Consolidation Rules (HARD CAP):**
- Summarize AGGRESSIVELY - focus on patterns, decisions, interfaces
- AVOID repeating step-by-step details already in story files
- Target ~30-50K tokens maximum
- Story files remain the detailed source; consolidation is for cross-PRD context

**Consolidation Format:**
```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: Authentication System
consolidatedDate: 2025-01-18
totalStories: 5
---

# Authentication System - Consolidated Implementation Memory

## System Overview
Complete user authentication supporting login, signup, password reset, and session management.

## Key Architectural Decisions

### Database
- **Supabase as single source of truth** - Always use MCP for queries
- **users table**: id, email, password_hash, created_at, updated_at
- **RLS**: Authenticated users read/write own data only

### Authentication Flow
1. Email/password → authenticate() action
2. Session token → HTTP-only cookie
3. Protected routes → middleware validation
4. Logout → clear cookie + Supabase session

## Public Interfaces

### Server Actions (`src/actions/auth.ts`)
```typescript
authenticate(email, password) → { success, error, data }
register(email, password) → { success, error, data }
requestPasswordReset(email) → { success, error }
resetPassword(token, newPassword) → { success, error }
logout() → { success }
```

## Integration Patterns

### For New Features Requiring Auth
1. Wrap with `AuthContext` provider
2. Check `user` state before allowing access
3. Use `authenticate()` for credential validation
4. Apply RLS policies to new tables with `user_id` FK

## Related PRDs
- **Dashboard PRD**: Requires auth, loads this memory

## Consolidated From Stories
US-001: User login | US-002: User signup | US-003: Password reset | US-004: Session management | US-005: Logout
```

### Cross-PRD Memory Loading

When implementing a PRD that depends on other PRDs:

1. **Load related consolidated memory** from `relatedPRDs` array
2. **Pre-analyze and summarize** to create focused summary (~3-5K tokens)
3. **Inject into story context** only relevant parts

**Example: Dashboard PRD depends on Authentication PRD**
```json
{
  "project": "User Dashboard",
  "consolidatedMemory": "docs/consolidated-dashboard.txt",
  "relatedPRDs": ["docs/prd-authentication.json"]
}
```

**Context budget per story:** ~35K tokens
- Main prompt: ~5K
- Previous stories in same PRD: ~10K
- Related PRD summaries: ~15K
- Agent definitions: referenced, not embedded
- Buffer: ~5K

---

## Signal Format

### Story Complete Signal

After each story completes, output this signal:

```xml
<STORY_COMPLETE>
<story_id>US-001</story_id>
<story_title>User login</story_title>
<feature>Authentication System</feature>
<agents_used>development-agent, security-agent</agents_used>
<commit>feat: add user login with email/password authentication</commit>
<memory_file>docs/authentication/story-US-001-login.txt</memory_file>
</STORY_COMPLETE>
```

**Signal triggers:**
1. Create/update `docs/[feature]/story-US-[###]-[title].txt`
2. Update PRD JSON: `passes: true`
3. Commit changes with proper format
4. Output signal to indicate completion

### All Complete Signal

After ALL stories in a PRD complete, output this signal:

```xml
<ALL_COMPLETE>
<feature>Authentication System</feature>
<total_stories>5</total_stories>
<completed_stories>5</completed_stories>
<consolidated_memory>docs/consolidated-authentication.txt</consolidated_memory>
</ALL_COMPLETE>
```

**Signal triggers:**
1. Spawn consolidation agent
2. Consolidate all story memories into `docs/consolidated-[feature].txt`
3. Hard cap at ~30-50K tokens (aggressive summarization)
4. Output signal with consolidation path

---

## Enhanced Story Processing Flow

### With Memory System and Signals

When processing each story:

```markdown
## Story: US-001 - User Login

**From PRD:**
- Feature: Authentication System
- mavenSteps: [1, 7, 10]
- mcpTools: { step1: ["supabase"], step7: ["supabase"], step10: [] }
- relatedPRDs: []

**Loading Context:**
- Previous stories in this PRD: 0
- Related PRD memories: 0

**Processing:**

1. [Step 1 - Foundation]
   Spawning development agent...
   → [Agent completed successfully]

2. [Step 7 - Data Layer]
   Spawning development agent...
   → [Agent completed successfully]

3. [Step 10 - Security & Error Handling]
   Spawning security agent...
   → [Agent completed successfully]

4. Running quality checks...
   pnpm run typecheck
   → Passed

5. Committing changes...
   git commit -m "feat: add user login with email/password authentication"
   → Committed

6. Creating story memory...
   Writing docs/authentication/story-US-001-login.txt
   → Created

7. Updating PRD...
   Setting passes: true for US-001
   → Updated

<STORY_COMPLETE>
<story_id>US-001</story_id>
<story_title>User login</story_title>
<feature>Authentication System</feature>
<agents_used>development-agent, development-agent, security-agent</agents_used>
<commit>feat: add user login with email/password authentication</commit>
<memory_file>docs/authentication/story-US-001-login.txt</memory_file>
</STORY_COMPLETE>

✅ Story US-001 complete
```

### Consolidation Flow (When All Stories Complete)

```markdown
## All Stories Complete - Consolidating

**Feature:** Authentication System
**Total Stories:** 5
**Completed Stories:** 5

1. Spawning consolidation agent...
   → Reading all story memory files
   → Summarizing patterns, decisions, interfaces
   → Target: ~30-50K tokens (hard cap)
   → [Agent completed successfully]

2. Creating consolidated memory...
   Writing docs/consolidated-authentication.txt
   → Created (14,234 tokens)

<ALL_COMPLETE>
<feature>Authentication System</feature>
<total_stories>5</total_stories>
<completed_stories>5</completed_stories>
<consolidated_memory>docs/consolidated-authentication.txt</consolidated_memory>
</ALL_COMPLETE>

✅ All stories complete for Authentication System
```

---

## Folder Creation and Memory Management

### Automatic Folder Creation

The flow automatically creates the `docs/[feature]/` folder when processing the first story of a PRD:

```bash
# First story of authentication PRD
docs/authentication/                    # Auto-created
├── story-US-001-login.txt            # Created after US-001 complete
├── story-US-002-signup.txt           # Created after US-002 complete
└── story-US-003-reset-password.txt   # Created after US-003 complete
```

### Memory File Updates

When a story is re-run (e.g., after consolidation):
1. Read existing memory file
2. Append new learnings
3. Update `memoryVersion` if format changes
4. Keep full history of iterations

### Memory Versioning

Each memory file includes version info for future compatibility:

```yaml
---
memoryVersion: 1
schemaVersion: 1
---
```

**Benefits:**
- System evolution: Old memories won't be misinterpreted
- Backward compatibility: Agents can adapt behavior based on version
- Migration support: Clear path for upgrading memory formats
- Debugging: Version mismatches immediately visible

---

## Terminal Command Integration

The terminal forwarder scripts (`bin/flow.sh`, `bin/flow-prd.sh`, `bin/flow-convert.sh`) invoke these Claude Code commands directly.

**Terminal → Claude Code mapping:**
```bash
flow start           → /flow start
flow status          → /flow status
flow-prd create ...  → /flow-prd create ...
flow-convert auth    → /flow-convert auth
```

The terminal scripts are minimal - they just forward user input to Claude Code which handles all the actual work.

---

## Help

### `/flow help`

Displays comprehensive help information for Maven Flow.

```bash
/flow help
flow help
```

### Quick Reference

| Command | Description | Usage |
|---------|-------------|-------|
| `start [n]` | Start autonomous development | `flow start 10` |
| `status` | Show progress across all PRDs | `flow status` |
| `continue [prd] [n]` | Resume from last iteration | `flow continue auth 5` |
| `reset [prd]` | Archive and reset a PRD | `flow reset auth` |
| `test [prd]` | Test implemented features | `flow test auth` |
| `consolidate [prd]` | Fix errors from testing | `flow consolidate auth` |
| `help` | Show this help | `flow help` |

### Memory System Overview

Maven Flow uses a three-layer memory ecosystem:

1. **Story Memory** (`docs/[feature]/story-US-[###]-[title].txt`)
   - Created after each story completes
   - Contains: implemented, decisions, challenges, lessons

2. **Consolidated Memory** (`docs/consolidated-[feature].txt`)
   - Created when ALL stories in PRD complete
   - Aggressively summarized to ~30-50K tokens
   - Contains: architecture, interfaces, integration patterns

3. **Cross-PRD Context** (assembled dynamically)
   - Related PRD summaries (~3-5K tokens per PRD)
   - Previous story summaries (~10K tokens total)
   - Assembled before spawning agents

### Feature Relationships

PRDs can have relationships with other PRDs:

| Type | Description | Example |
|------|-------------|---------|
| `depends_on` | This PRD depends on another | Payments → Authentication |
| `depended_by` | Another PRD depends on this | Payments ← Orders |
| `bidirectional` | Mutual dependency (rare) | Auth ↔ Profiles |

### Maven Steps

Each story specifies which Maven steps to execute:

| Step | Agent | Description |
|------|-------|-------------|
| 1 | development | Foundation - Import UI or create from scratch |
| 2 | development | Package Manager - Convert npm → pnpm |
| 3 | refactor | Feature Structure - Feature-based folders |
| 4 | refactor | Modularization - Split components >300 lines |
| 5 | quality | Type Safety - No 'any' types, @ aliases |
| 6 | refactor | UI Centralization - Move to @shared/ui |
| 7 | development | Data Layer - Backend setup, Supabase |
| 8 | security | Auth Integration - Firebase + Supabase |
| 9 | development | MCP Integration - Connect MCP tools |
| 10 | security | Security & Error Handling |
| 11 | design | Mobile Design - Professional UI (optional) |

### MCP Tools

MCPs (Model Context Protocol) are assigned per step:

```json
{
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

**Common MCPs:**
- `supabase` - Database operations (steps 1, 7, 8, 10)
- `chrome-devtools` - Browser testing (testing phases)
- `web-search-prime` - Research, documentation (all steps)
- `web-reader` - Read web content (all steps)

### Quality Standards

**Zero Tolerance Rules:**

1. **'any' Types - ZERO TOLERANCE**
   - No `: any`, `: any[]`, `<any>`, `Promise<any>`
   - Use proper interfaces or `unknown` with type guards

2. **Gradients in CSS - ZERO TOLERANCE**
   - No `linear-gradient`, `radial-gradient`, `conic-gradient`
   - Use solid professional colors only

3. **Emojis in UI - ZERO TOLERANCE**
   - No emojis anywhere in UI components
   - Use professional icon libraries (lucide-react, heroicons)

4. **Relative Imports**
   - No `import { Foo } from './foo'` or `../bar`
   - Use `@/` aliases for all imports

### File Structure

```
docs/
├── [feature]/                          # Story memories folder
│   ├── story-US-001-[title].txt       # Story: US-001
│   └── story-US-002-[title].txt       # Story: US-002
├── prd-[feature].md                   # Human-readable PRD
├── prd-[feature].json                 # Machine-readable PRD
├── consolidated-[feature].txt          # Consolidated memory
└── progress-[feature].txt             # Progress log
```

### Common Workflows

**New Feature:**
```bash
1. flow-prd create "feature description"
2. flow-convert feature
3. flow start
4. flow status
```

**Resume After Error:**
```bash
1. Fix the error
2. flow continue
```

**Test Implementation:**
```bash
1. flow test [prd]
2. Review docs/errors-[prd].md
3. flow consolidate [prd]
```

**Start Fresh:**
```bash
1. flow reset [prd]
2. flow start
```

### Getting More Help

**For specific topics:**
- PRD Creation: See `.claude/commands/flow-prd.md`
- PRD Conversion: See `.claude/skills/flow-convert/SKILL.md`
- Terminal Scripts: See `bin/README.md`
- Memory System: See main `README.md`

**For troubleshooting:**
- Run `flow status` for diagnostics
- Check progress file: `docs/progress-[feature].txt`
- Review git log: `git log --oneline -10`

---

*Maven Flow: Autonomous AI development with comprehensive quality assurance, multi-PRD support, and intelligent memory management powered by Claude Code CLI*
