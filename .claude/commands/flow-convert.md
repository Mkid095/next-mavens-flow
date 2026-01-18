---
description: Convert Markdown PRDs to JSON format for Maven Flow
argument-hint: [feature-name]
---

# Maven Flow PRD Converter

Convert markdown PRD files to JSON format for Maven Flow processing.

**CRITICAL: Always work in the current working directory (user's project root), NOT in the command installation directory.**
- Use `$PWD` or `$(pwd)` to get the current working directory
- Read PRD files from `./docs/prd-*.md`
- Create JSON files in `./docs/prd-*.json`

## Commands

### Convert PRD to JSON
```
/flow-convert [feature-name]
```

Converts an existing markdown PRD to JSON format with intelligent relationship detection.

**What happens:**
1. Reads `docs/prd-[feature-name].md`
2. Parses frontmatter (project, branch, availableMCPs)
3. Extracts all user stories with their details
4. Intelligently detects related PRDs by analyzing:
   - Feature dependencies (auth, database, api mentions)
   - Similar naming patterns in `docs/`
   - Common integration points
5. Creates `docs/prd-[feature-name].json` with:
   - Boolean `passes` fields (true/false for each story)
   - `relatedPRDs` array with paths to related PRD JSONs
   - `consolidatedMemory` path (always points to THIS PRD's own memory file)
   - Proper `mcpTools` mapping per step
   - Schema version for future compatibility

**Example usage:**
```
/flow-convert authentication
```

**Input:** `docs/prd-authentication.md`
**Output:** `docs/prd-authentication.json`

### Convert All PRDs
```
/flow-convert --all
```

Converts all markdown PRDs in `docs/` to JSON format.

### Help
```
/flow-convert help
```

Displays help information about PRD conversion.

---

## JSON Schema

### PRD JSON Structure

```json
{
  "schemaVersion": 1,
  "project": "Authentication System",
  "branchName": "flow/authentication",
  "description": "Complete user authentication with login, signup, password reset, and session management",
  "availableMCPs": ["supabase", "web-search-prime", "chrome-devtools", "web-reader"],
  "consolidatedMemory": "docs/consolidated-authentication.txt",
  "relatedPRDs": [],
  "userStories": [
    {
      "id": "US-001",
      "title": "User login",
      "description": "As a user, I want to log in with email and password so that I can access my account.",
      "acceptanceCriteria": [
        "Create users table with id, email, password_hash",
        "Add login UI with email/password fields",
        "Implement server action for authentication",
        "Add session management",
        "Typecheck passes"
      ],
      "mavenSteps": [1, 7, 10],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase"],
        "step10": []
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Key JSON Fields

| Field | Type | Description |
|-------|------|-------------|
| `schemaVersion` | number | Version of PRD JSON schema (currently 1) |
| `project` | string | Project name from frontmatter |
| `branchName` | string | Git branch name from frontmatter |
| `description` | string | Short description of the feature |
| `availableMCPs` | string[] | List of available MCP servers |
| `consolidatedMemory` | string | Path to THIS PRD's OWN consolidated memory |
| `relatedPRDs` | string[] | Paths to OTHER PRD JSON files this PRD depends on |
| `userStories` | array | Array of story objects |

### Story Object Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Story identifier (e.g., "US-001") |
| `title` | string | Story title |
| `description` | string | User story description |
| `acceptanceCriteria` | string[] | List of acceptance criteria |
| `mavenSteps` | number[] | Maven workflow steps to execute |
| `mcpTools` | object | Map of step to MCP tools |
| `priority` | number | Execution order (lower = earlier) |
| `passes` | boolean | **Authoritative** completion status (true/false) |
| `notes` | string | Additional notes or context |

---

## Related PRD Detection

The converter intelligently detects related PRDs by analyzing:

### 1. Feature Dependencies
- **Authentication PRD**: Auto-detected when stories mention:
  - "user", "login", "signup", "auth", "session"
  - Protected routes, permissions
- **Database PRD**: Auto-detected when stories mention:
  - "table", "schema", "migration", "database"
  - Supabase, PostgreSQL

### 2. Naming Patterns
Scans `docs/prd-*.md` files for similar keywords:
- "dashboard" relates to "authentication" (requires auth)
- "tasks" relates to "users" (has user_id foreign key)
- "notifications" relates to "users" (sends to users)

### 3. Integration Points
- Features that share database tables
- Features with API dependencies
- UI components that reference other features

### Related PRD Example

**Dashboard PRD (depends on Authentication):**
```json
{
  "schemaVersion": 1,
  "project": "User Dashboard",
  "consolidatedMemory": "docs/consolidated-dashboard.txt",
  "relatedPRDs": ["docs/prd-authentication.json"],
  ...
}
```

- Dashboard's `consolidatedMemory` points to ITS OWN memory
- Dashboard's `relatedPRDs` points to Authentication PRD

---

## Conversion Rules

### 1. Boolean Status Fields

**Markdown Status Field** (informational for humans):
```markdown
**Status:** false (informational - for humans)
```

**JSON passes Field** (authoritative for machines):
```json
"passes": false
```

- Use `true`/`false` (boolean), NOT "complete"/"incomplete"
- The JSON `passes` field is the authoritative source
- Markdown status is informational only

### 2. Memory References

**consolidatedMemory** (points to THIS PRD's memory):
```json
"consolidatedMemory": "docs/consolidated-[feature].txt"
```

- Always points to THIS PRD's OWN consolidated memory
- Will be created AFTER all stories complete
- Used by OTHER PRDs that depend on this one

**relatedPRDs** (points to OTHER PRDs):
```json
"relatedPRDs": ["docs/prd-authentication.json"]
```

- Array of OTHER PRD JSON files
- Used to load their consolidated memories
- Enables cross-PRD context sharing

### 3. MCP Tools Mapping

Each step can specify different MCP tools:

```json
"mcpTools": {
  "step1": ["supabase"],
  "step7": ["supabase", "web-search-prime"],
  "step10": []
}
```

- `step1`: Use supabase MCP
- `step7`: Use supabase AND web-search-prime MCPs
- `step10`: No specific MCPs required

---

## Conversion Workflow

### Step 1: Read Markdown PRD
```
Input: docs/prd-[feature].md
```

Parse:
- Frontmatter (YAML)
- Story sections
- Acceptance criteria
- Maven steps
- MCP tools

### Step 2: Detect Related PRDs
```
Scan: docs/prd-*.md
```

Analyze:
- Feature keywords in stories
- Integration points
- Database dependencies
- API relationships

### Step 3: Build JSON Structure
```
Output: docs/prd-[feature].json
```

Include:
- All stories with `passes: false`
- Detected `relatedPRDs`
- `consolidatedMemory` path
- `availableMCPs` from environment

### Step 4: Validate JSON
```
Check:
- Valid JSON syntax
- All required fields present
- passes is boolean (true/false)
- relatedPRDs paths exist
```

---

## Complete Example

### Input: `docs/prd-dashboard.md`

```markdown
---
project: User Dashboard
branch: flow/dashboard
availableMCPs:
  - supabase
  - web-search-prime
---

# User Dashboard

## Overview
Personalized dashboard for authenticated users.

### US-001: Dashboard Layout
**Priority:** 1
**Maven Steps:** [1, 3, 5, 6]
**MCP Tools:**
- step1: []

As an authenticated user, I want to see a personalized dashboard so that I can view my information.

**Acceptance Criteria:**
- Display user profile information
- Show navigation menu
- Responsive layout
- Typecheck passes

**Status:** false
```

### Output: `docs/prd-dashboard.json`

```json
{
  "schemaVersion": 1,
  "project": "User Dashboard",
  "branchName": "flow/dashboard",
  "description": "Personalized dashboard for authenticated users",
  "availableMCPs": ["supabase", "web-search-prime"],
  "consolidatedMemory": "docs/consolidated-dashboard.txt",
  "relatedPRDs": ["docs/prd-authentication.json"],
  "userStories": [
    {
      "id": "US-001",
      "title": "Dashboard Layout",
      "description": "As an authenticated user, I want to see a personalized dashboard so that I can view my information.",
      "acceptanceCriteria": [
        "Display user profile information",
        "Show navigation menu",
        "Responsive layout",
        "Typecheck passes"
      ],
      "mavenSteps": [1, 3, 5, 6],
      "mcpTools": {
        "step1": []
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Note:** The converter detected `docs/prd-authentication.json` as a related PRD because the dashboard story mentions "authenticated user".

---

## Troubleshooting

**Conversion fails with parse error:**
- Check markdown PRD has valid frontmatter
- Verify story format matches expected structure
- Ensure no syntax errors in YAML

**Related PRDs not detected:**
- Manually review and add to `relatedPRDs` array if needed
- Check that related PRD JSON files exist
- Run `/flow-convert` on related PRDs first

**JSON output is empty:**
- Verify markdown PRD has at least one story
- Check that stories have required fields (id, title, mavenSteps)
- Ensure `docs/` directory is readable

---

## Versioning

### Schema Version 1

Current version supports:
- Boolean `passes` fields
- `relatedPRDs` and `consolidatedMemory` references
- Per-step MCP tool mapping
- Priority-based story ordering

**Future versions** may add:
- Story dependencies
- Parallel execution support
- Enhanced context management
- Custom agent assignments

---

*Maven Flow PRD Converter - Convert markdown PRDs to JSON for autonomous processing*
