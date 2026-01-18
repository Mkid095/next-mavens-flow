# PRD JSON Schema

This document defines the canonical JSON structure for Product Requirements Documents (PRDs) in the Maven Flow system. All tools and agents must use this schema.

## JSON Structure

```json
{
  "project": "string - Project name from PRD title",
  "branchName": "string - Git branch name in format: flow/feature-name-kebab-case",
  "description": "string - Brief one-line description of the feature",
  "memorialFile": "string - Path to memorial file: docs/memorial-feature-name.txt",
  "relatedMemorials": [
    "string - Paths to related memorial files"
  ],
  "userStories": [
    {
      "id": "string - User story ID: US-001, US-002, etc.",
      "title": "string - Short title describing the story",
      "description": "string - Full user story: As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "string - Verifiable criterion 1",
        "string - Verifiable criterion 2",
        "string - Typecheck passes"
      ],
      "mavenSteps": [number, number],
      "mcpTools": {
        "step1": ["mcp-name-1", "mcp-name-2"],
        "step7": ["mcp-name-3"]
      },
      "priority": number,
      "passes": boolean,
      "notes": "string"
    }
  ]
}
```

## Field Specifications

### Root Level

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | string | Yes | Project name, typically from PRD title |
| `branchName` | string | Yes | Git branch name for this feature (format: `flow/feature-name`) |
| `description` | string | Yes | One-line summary of what this feature does |
| `memorialFile` | string | Yes | Path to this feature's memorial file |
| `relatedMemorials` | array | Yes | List of related memorial file paths |
| `userStories` | array | Yes | Array of user story objects (minimum 1) |

### User Story Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Story identifier: US-001, US-002, etc. |
| `title` | string | Yes | Short descriptive title |
| `description` | string | Yes | Full user story format: "As a [user], I want [feature] so that [benefit]" |
| `acceptanceCriteria` | array | Yes | List of verifiable criteria. Must include "Typecheck passes" |
| `mavenSteps` | array | Yes | Array of step numbers (1-10). Never empty. |
| `mcpTools` | object | Yes | Step-based MCP tool mapping. Use `{}` if none. |
| `priority` | number | Yes | Priority order (lower = higher priority). Must be ≥ 1. |
| `passes` | boolean | Yes | Story completion status. Always `false` initially. |
| `notes` | string | Yes | Implementation notes. Always empty string initially. |

## Maven Steps Reference

Every user story must specify which Maven Flow steps are required:

| Step | Agent | Purpose |
|------|-------|---------|
| 1 | development | Foundation/UI from scratch |
| 2 | development | Package manager changes (npm→pnpm) |
| 3 | refactor | Feature structure changes |
| 4 | refactor | Modularization (when >300 lines) |
| 5 | quality | Type safety enforcement (no 'any' types) |
| 6 | refactor | UI centralization (@shared/ui) |
| 7 | development | Data layer/backend implementation |
| 8 | security | Authentication/authorization integration |
| 9 | development | MCP integration |
| 10 | security | Security hardening & error handling |

### Step Mapping by Story Type

- **Database changes** → `[1, 7]`
- **UI component** → `[5, 6]`
- **Backend API** → `[1, 7, 10]`
- **Auth flow** → `[1, 7, 8, 10]`
- **Full feature** → `[1, 3, 4, 5, 6, 7, 10]`

## MCP Tools Format

The `mcpTools` object maps step numbers to MCP server names:

```json
{
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

**Rules:**
- Only list MCP **server names** (e.g., "supabase"), not individual tools
- Use step-based keys: "step1", "step2", etc.
- Use empty object `{}` if no MCPs needed for this story

### Common MCPs

| MCP Name | When to Use |
|----------|-------------|
| `supabase` | Steps 1, 7, 8, 10 - Database/auth operations |
| `web-search-prime` | All steps - Web searches |
| `chrome-devtools` | Testing - Browser automation |
| `4-5v-mcp` | All steps - Image analysis |

## Story Sizing Rules

Each story MUST be completable in ONE iteration (one context window).

### RIGHT-sized stories:
- Add database column + migration
- Add UI component to existing page
- Update server action with new logic
- Implement single API endpoint

### TOO BIG (split these):
- "Build entire dashboard" → Split into: schema, queries, UI, filters
- "Add authentication" → Split into: schema, middleware, login UI, sessions
- "Create CRUD system" → Split into: Create, Read, Update, Delete separately

## Story Ordering

Stories should be ordered by dependency:

1. **Schema/database changes** (foundational)
2. **Server actions/backend logic** (depend on schema)
3. **UI components** (depend on backend)
4. **Dashboard/summary views** (depend on everything)

## Acceptance Criteria Rules

All criteria must be **verifiable**:

✓ Good: "Add status column with default 'pending'"
✓ Good: "Redirect unauthenticated users to /login"
✓ Good: "Typecheck passes"

✗ Bad: "Works correctly"
✗ Bad: "User friendly interface"
✗ Bad: "Error handling"

**Required:** Every story MUST include `"Typecheck passes"` in acceptance criteria.

## Example Complete JSON

```json
{
  "project": "Artboard System",
  "branchName": "flow/vector-canvas",
  "description": "Infinite vector canvas with pan, zoom, and object manipulation",
  "memorialFile": "docs/memorial-vector-canvas.txt",
  "relatedMemorials": [
    "docs/memorial-workspace-file-management.txt",
    "docs/maven-flow-wrapper.txt"
  ],
  "userStories": [
    {
      "id": "US-001",
      "title": "Database schema for canvas objects",
      "description": "As a developer, I need a database schema to store canvas objects so that users can save their work",
      "acceptanceCriteria": [
        "Create canvas_objects table with id, type, x, y, width, height, rotation, properties columns",
        "Add indexes on workspace_id and object_type",
        "Create migration file in supabase/migrations/",
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
      "title": "Canvas object component",
      "description": "As a user, I want to see and manipulate canvas objects so that I can create designs",
      "acceptanceCriteria": [
        "Create CanvasObject component with selection, move, resize handles",
        "Implement keyboard shortcuts (Delete, Ctrl+D for duplicate)",
        "Add z-index management (bring to front/send to back)",
        "Typecheck passes"
      ],
      "mavenSteps": [5, 6],
      "mcpTools": {},
      "priority": 2,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Validation Checklist

When generating or consuming PRD JSON files, verify:

- [ ] All required fields present
- [ ] `mavenSteps` is never empty
- [ ] `mcpTools` object exists (use `{}` if empty)
- [ ] Every story has "Typecheck passes" in acceptance criteria
- [ ] `passes` is `false` for all new stories
- [ ] `notes` is empty string for new stories
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] Stories ordered by dependency
- [ ] Each story completable in one iteration
- [ ] MCP names only (not individual tools)
- [ ] Step-based keys in mcpTools ("step1", "step7", etc.)

## File Naming Convention

PRD JSON files must follow this naming pattern:
- Pattern: `prd-{feature-name}.json`
- Example: `prd-vector-canvas.json`
- Location: `docs/` directory

These files are generated from `prd-{feature-name}.md` markdown PRDs.
