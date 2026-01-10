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
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

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
  ...
}

// UI component story
{
  "id": "US-002",
  "title": "Add status badge to task cards",
  "mavenSteps": [5, 6],  // Type safety + UI centralization
  ...
}

// Full feature story
{
  "id": "US-003",
  "title": "Create user profile page",
  "mavenSteps": [1, 3, 5, 6, 7, 10],  // Most steps
  ...
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE flow iteration (one context window).**

The flow-iteration subagent spawns fresh each iteration with no memory of previous work. If a story is too big, the context fills before finishing and produces broken code.

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

- [ ] **Previous run archived** (if docs/prd-[feature-name].json exists)
- [ ] Each story is completable in one iteration
- [ ] Stories are ordered by dependency (schema to backend to UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser" as criterion
- [ ] **Every story has mavenSteps array specifying required Maven steps**
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Created `docs/` folder if it didn't exist
- [ ] Extracted feature name from PRD title (kebab-case)
- [ ] Saved to `docs/prd-[feature-name].json`
- [ ] Created `docs/progress-[feature-name].txt`
