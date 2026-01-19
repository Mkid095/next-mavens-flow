---
description: Generate PRDs from plan.md with MCP scanning
argument-hint: [plan] or [feature description]
---

# Maven Flow PRD Generator

Generate Product Requirements Documents (PRDs) with MCP scanning and memorial integration.

**CRITICAL: Always work in the current working directory.**
- Use `$PWD` or `$(pwd)` to get current working directory
- Create ALL files in `[working-directory]/docs/`

## Workflow

### Step 1: Scan Available MCPs

First, identify what MCP servers are available in the current environment:

```bash
# Check Claude Code settings for configured MCPs
# Common MCPs:
# - supabase: Database operations, schema management
# - chrome-devtools: UI testing, browser automation
# - web-search-prime: Web research, documentation lookup
# - web-reader: Fetch and read web content
# - filesystem: File system operations
```

**Output:** List available MCPs with their purposes:
```
Available MCPs:
- supabase: Database schema, queries, migrations
- chrome-devtools: UI testing, screenshot validation
- web-search-prime: Research, find examples
```

### Step 2: Read User Prompt

Get the feature description from:
- User input after `/flow-prd` command
- OR `plan.md` file if argument is "plan"

### Step 3: Analyze and Create PRDs

Using the MCP list + user prompt, create PRD markdown files:

1. **Parse the requirements** - Identify features, components, user stories
2. **Split into focused PRDs** - One PRD per major feature
3. **For each PRD, create:**
   - `docs/prd-[feature-name].md` - Main PRD with user stories
   - `docs/consolidated-[feature-name].txt` - Memory stub file

### Step 4: PRD Structure (Markdown)

Each PRD markdown file follows this structure:

```markdown
---
project: [Feature Name]
branch: flow/[feature-name]
availableMCPs:
  - [scanned MCPs relevant to this feature]
---

# [Feature Name]

## Overview
[2-3 sentences describing what this feature does and why]

## Technical Approach
[Brief technical approach - what stack, what patterns]

## User Stories

### US-001: [Story Title]
**Priority:** 1
**Maven Steps:** [1, 3, 7, 10]
**MCP Tools:**
- step1: [supabase]
- step3: []

As a [user], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [Specific, testable criteria 1]
- [Specific, testable criteria 2]
- [Specific, testable criteria 3]
- Typecheck passes

**Status:** false
```

**Key Guidelines:**
- Keep stories **focused and atomic** - one clear objective
- Each story completable in 1-2 hours
- Order by dependency: database → backend → UI → integration
- Assign relevant MCPs to each step
- Max 10 stories per PRD

### Step 5: Consolidated Memory Stub

Create `docs/consolidated-[feature-name].txt`:

```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: [Feature Name]
consolidatedDate: [Current Date]
totalStories: [Count from PRD]
completedStories: 0
status: initialized
---

# [Feature Name] - Consolidated Implementation Memory

## System Overview
[Copy from PRD overview]

## Current Status
PRD created, waiting for story execution.

## Technical Approach
[Copy from PRD technical approach]

## Related PRDs
[List other PRDs this depends on or integrates with]

## Stories to Implement
- US-001: [Story Title]
- US-002: [Story Title]
...

## Memory Structure
This file will be updated as stories complete, containing:
- Architectural decisions made
- Integration patterns established
- Public interfaces created
- Lessons learned
```

---

## Commands

### Generate PRDs from Plan
```
/flow-prd plan
```

1. Reads `plan.md` from working directory
2. Scans available MCPs
3. Analyzes plan for features
4. Generates multiple `docs/prd-*.md` files
5. Creates `docs/consolidated-*.txt` stubs for each

### Generate Single PRD
```
/flow-prd [feature description]
```

Example: `/flow-prd user authentication with login and signup`

1. Scans available MCPs
2. Parses feature description
3. Generates single `docs/prd-[feature].md`
4. Creates `docs/consolidated-[feature].txt` stub

---

## MCP Assignment Guidelines

| MCP | When to Use | Maven Steps |
|-----|-------------|-------------|
| **supabase** | Database schema, queries, migrations | Step 1, 2, 7 |
| **chrome-devtools** | UI testing, visual validation | Step 6, 10 |
| **web-search-prime** | Research, find examples | Step 1, 8 |
| **web-reader** | Read documentation | Step 1, 8 |
| **filesystem** | File operations | Step 1, 5 |

---

## Story Size and Scope

**GOOD Story (Focused):**
```
US-001: Create users table
- Define schema with id, email, password_hash
- Add RLS policies
- Run migration
```

**BAD Story (Too Large):**
```
US-001: Build entire authentication system
- Database, backend, UI, testing, docs
```

**Split large stories into:**
1. Database schema
2. Backend API
3. UI components
4. Integration
5. Testing

---

## Output Format

After generating PRDs, display:

```
==============================================================================
PRD Generation Complete
==============================================================================

Available MCPs detected:
- supabase (database)
- chrome-devtools (testing)

Created PRDs:
- docs/prd-user-authentication.md (5 stories)
- docs/prd-user-dashboard.md (3 stories)

Memory files created:
- docs/consolidated-user-authentication.txt
- docs/consolidated-user-dashboard.txt

Next steps:
1. Review PRDs: cat docs/prd-*.md
2. Convert to JSON: flow-convert --all
3. Start flow: flow start
```

---

## Implementation Instructions for the Command

When invoked, the command should:

1. **Get working directory:** Run `pwd`
2. **Scan MCPs:** List available MCPs with purposes
3. **Read input:**
   - If "plan": Read plan.md
   - Otherwise: Use user prompt
4. **Analyze requirements:** Identify features, components, stories
5. **Create PRD files:**
   - For each feature: `docs/prd-[feature].md`
   - For each PRD: `docs/consolidated-[feature].txt`
6. **Report results:** Show what was created

---

## Example: Full Workflow

**User runs:**
```bash
cd /path/to/project
flow-prd plan
```

**Command does:**
1. `pwd` → `/path/to/project`
2. Scan MCPs → `supabase, chrome-devtools`
3. Read `plan.md` → Finds features: auth, dashboard, settings
4. Create `docs/prd-authentication.md` with 5 stories
5. Create `docs/consolidated-authentication.txt` stub
6. Create `docs/prd-dashboard.md` with 3 stories
7. Create `docs/consolidated-dashboard.txt` stub
8. Display summary

**User then:**
```bash
flow-convert --all  # Markdown → JSON
flow start          # Begin execution
```

---

*Generate focused PRDs with MCP integration and memorial structure*
