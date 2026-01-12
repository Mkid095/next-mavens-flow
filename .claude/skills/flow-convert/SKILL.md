---
name: flow-convert
description: "Convert PRDs to prd.json format for next-mavens-flow autonomous execution. Use when you have an existing PRD and need to convert it. Triggers on: convert this prd, turn this into flow format, create prd.json from this, flow json."
---

# Flow PRD Converter

Converts existing PRDs (markdown or text) to the `prd.json` format that next-mavens-flow uses for autonomous execution.

---

## The Job

Take a PRD and convert it to `docs/prd-[feature-name].json`. Create `docs/` folder if it doesn't exist.

**Important:** Each feature gets its own PRD JSON file. The flow command will scan for all `prd-*.json` files in `docs/` and process incomplete ones.

**CRITICAL:** Each story MUST have its own `mcpTools` object specifying which MCPs to use for each Maven step.

---

## MCP Tool Assignment (Story-Level, Step-Based)

**CRITICAL ARCHITECTURE DECISION:** MCPs are assigned PER STORY PER STEP, not at the PRD level.

**SCAN FIRST - Discover Available MCPs:**

**BEFORE assigning any MCPs to stories, you MUST:**

1. **Check which MCP servers are available** in the current environment
2. **Only assign MCPs that actually exist** - don't guess or assume
3. **If unsure, leave mcpTools empty** `{}` rather than guessing wrong

**How to Discover Available MCPs:**
- Check the user's MCP configuration
- Ask the user what MCPs they have configured
- Look for common MCP patterns in the project (e.g., if using Supabase, check if supabase MCP is set up)

**Why Scan First?**
- Prevents assigning MCPs that don't exist
- Avoids confusion when agents can't find the MCP
- Ensures PRD matches actual environment capabilities

**Why Story-Level MCP Assignment?**

1. **Context Isolation:** Each story has its own specific MCPs, reducing confusion as context grows
2. **Precision:** Flow command tells agents exactly which MCPs to use for each step
3. **No Hallucination:** Prevents agents from "forgetting" which MCPs are available in large contexts
4. **Granular Control:** Different stories and steps can use different MCPs

**How to Assign MCPs to Stories:**

When creating a PRD JSON, for each story:

1. **Identify which Maven steps** the story requires (see Maven Steps Field section below)
2. **For each step**, specify which MCPs to use (ONLY from discovered/available MCPs)
3. **List MCPs in `mcpTools` object** with step-based keys (e.g., `step1`, `step7`)

**Important:** You only specify the MCP **name**, not individual tools. The agent will automatically discover and use the available tools from that MCP.

**Common MCPs (verify these are available before using):**

| MCP Name | Use For Steps |
|----------|--------------|
| supabase | 7, 8, 10 (database operations) |
| web-search-prime | All steps (research, documentation) |
| web-reader | All steps (reading web content) |
| chrome-devtools | Testing (browser automation) |
| vercel | 9 (deployment) |
| wrangler | 9 (deployment) |
| figma | 11 (design) |

**Example MCP Assignment:**
```json
{
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

This tells the flow:
- For Step 1: Use supabase MCP
- For Step 7: Use supabase MCP and web-search-prime MCP

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "flow/[feature-name-kebab-case]",
  "description": "[Feature description from PRD]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "mavenSteps": [1, 7],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase", "web-search-prime"]
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Note:** The `mcpTools` object specifies MCPs for each step using step-based keys. Only list MCP names (e.g., "supabase"), not individual tools. Agents will automatically discover available tools from those MCPs.

---

**CRITICAL ARCHITECTURAL DECISION:**

**Why MCPs are at the STORY level (not PRD level):**

1. **Context Isolation:** Each story has its own specific MCPs, reducing confusion as context grows
2. **Precision:** Flow command tells agents exactly which MCPs to use for each step
3. **No Hallucination:** Prevents agents from "forgetting" which MCPs are available in large contexts
4. **Granular Control:** Different stories and steps can use different MCPs

**How it works:**

When `/flow` processes a story:
1. Reads the story's `mavenSteps` array
2. For each step, reads the story's `mcpTools` for that step (e.g., `mcpTools.step1`)
3. Spawns the specialist agent and tells them: "Use these MCPs: supabase"
4. Agent checks if those MCPs are in their available tools
5. Agent uses those MCPs (or falls back to standard tools if unavailable)

**Example Story with MCP Tools:**

```json
{
  "id": "US-001",
  "title": "Add status field to tasks table",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

When processing this story:
- Step 1 (development-agent): Told to use supabase MCP
- Step 7 (development-agent): Told to use supabase MCP, web-search-prime MCP

### Maven Steps Field

**CRITICAL:** Each story MUST include a `mavenSteps` array that specifies which Maven workflow steps are required.

**Maven Step to Agent Mapping:**

| Maven Step | Agent | Description |
|------------|-------|-------------|
| 1 | development-agent | Foundation - Import UI with mock data or create from scratch |
| 2 | development-agent | Package Manager - Convert npm → pnpm |
| 3 | refactor-agent | Feature Structure - Restructure to feature-based folder structure |
| 4 | refactor-agent | Modularization - Modularize components >300 lines |
| 5 | quality-agent | Type Safety - No 'any' types, @ aliases |
| 6 | refactor-agent | UI Centralization - Centralize UI components to @shared/ui |
| 7 | development-agent | Data Layer - Centralized data layer with backend setup |
| 8 | security-agent | Auth Integration - Firebase + Supabase authentication flow |
| 9 | development-agent | MCP Integration - MCP integrations (web-search, web-reader, chrome, expo, supabase) |
| 10 | security-agent | Security & Error Handling - Security and error handling |
| 11 | design-agent | Mobile Design - Professional UI/UX for Expo/React Native (optional) |

**Map Maven steps to story types:**

| Story Type | Required Maven Steps |
|------------|---------------------|
| New feature UI from scratch | [1, 3, 5, 6, 10] |
| Adding UI component to existing page | [3, 5, 6] |
| Database schema changes | [1, 7] |
| Backend API/Server actions | [1, 7, 10] |
| Authentication flow | [1, 7, 8, 10] |
| MCP integration | [9] |
| Refactoring existing code | [4, 5] |
| Full feature (schema + backend + UI) | [1, 3, 4, 5, 6, 7, 10] |

**Example assignments:**
```json
// Database migration story
{
  "id": "US-001",
  "title": "Add status column to tasks table",
  "mavenSteps": [1, 7],  // Foundation + Data layer
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase"]
  }
}

// UI component story
{
  "id": "US-002",
  "title": "Add status badge to task cards",
  "mavenSteps": [5, 6],  // Type safety + UI centralization
  "mcpTools": {}
}

// Full feature story
{
  "id": "US-003",
  "title": "Create user profile page",
  "mavenSteps": [1, 3, 5, 6, 7, 10],  // Most steps
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"],
    "step10": ["web-search-prime"]
  }
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE flow iteration (one context window).**

The flow spawns fresh each iteration with no memory of previous work. If a story is too big, the context fills before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it's too big.

---

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Wrong order:**
1. UI component (depends on schema that does not exist yet)
2. Schema change

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something that can be CHECKED.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"

### Always include:
```
"Typecheck passes"
```

For testable stories:
```
"Tests pass"
```

### For UI stories:
```
"Verify in browser"
```

---

## Conversion Rules

1. **Each user story** becomes one JSON entry
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `flow/`
6. **Always add**: "Typecheck passes" to every story's acceptance criteria
7. **CRITICAL**: Add `mavenSteps` array to each story - see Maven Steps Field section above
8. **CRITICAL**: Add `mcpTools` object to each story - only list MCP names, not individual tools

---

## Splitting Large PRDs

If a PRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. US-001: Add notifications table to database
2. US-002: Create notification service for sending notifications
3. US-003: Add notification bell icon to header
4. US-004: Create notification dropdown panel
5. US-005: Add mark-as-read functionality
6. US-006: Add notification preferences page

Each is one focused change completable independently.

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output docs/prd-task-status.json:**
```json
{
  "project": "TaskApp",
  "branchName": "flow/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "mavenSteps": [1, 7],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase"]
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck passes",
        "Verify in browser"
      ],
      "mavenSteps": [5, 6],
      "mcpTools": {},
      "priority": 2,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add status toggle to task list rows",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck passes",
        "Verify in browser"
      ],
      "mavenSteps": [3, 5, 6, 7],
      "mcpTools": {
        "step7": ["supabase"]
      },
      "priority": 3,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck passes",
        "Verify in browser"
      ],
      "mavenSteps": [5, 6],
      "mcpTools": {},
      "priority": 4,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Archiving Previous Runs

**Before writing a new PRD JSON file:**

1. Ensure `docs/` folder exists (create if needed)
2. Extract feature name from the PRD title (kebab-case)
3. Output file will be: `docs/prd-[feature-name].json`
4. If that exact file already exists:
   - Archive the old version: `archive/YYYY-MM-DD-[feature-name]-prd.json`
   - Create new version with current timestamp
5. Create `docs/progress-[feature-name].txt` for tracking iteration progress

**Note:** Each feature has its own PRD JSON file and progress file.

---

## Checklist Before Saving

**FIRST - Before assigning MCPs:**
- [ ] **Scanned for available MCP servers** in the environment
- [ ] **Verified which MCPs actually exist** before assigning them
- [ ] **Asked user if unsure** what MCPs are configured

**Then - PRD validation:**
- [ ] **Previous run archived** (if docs/prd-[feature-name].json exists)
- [ ] Each story is completable in one iteration
- [ ] Stories are ordered by dependency (schema to backend to UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser" as criterion
- [ ] **Every story has mavenSteps array specifying required Maven steps**
- [ ] **Every story has mcpTools object (even if empty {})**
- [ ] **mcpTools uses step-based keys (step1, step7, etc.)**
- [ ] **mcpTools only lists ACTUALLY AVAILABLE MCP names** (not guessed)
- [ ] **mcpTools only lists MCP names (e.g., "supabase"), not individual tools**
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Created `docs/` folder if it didn't exist
- [ ] Extracted feature name from PRD title (kebab-case)
- [ ] Saved to `docs/prd-[feature-name].json`
- [ ] Created `docs/progress-[feature-name].txt`
