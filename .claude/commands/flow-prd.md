---
description: Generate PRDs without asking questions
argument-hint: [plan] or [feature description]
---

# Maven Flow PRD Generator - EXECUTE WITHOUT QUESTIONS

**CRITICAL: DO NOT ASK THE USER ANY QUESTIONS. EXECUTE AND GENERATE FILES DIRECTLY.**

When this command is invoked:
1. READ the input/plan.md
2. SCAN available MCPs
3. GENERATE PRD markdown files
4. CREATE memory stub files
5. DISPLAY summary
6. EXIT - DO NOT ASK FOR CONFIRMATION

Read the input, scan MCPs, generate PRD files, display summary, EXIT.

## Step 1: Get Working Directory

Run `pwd` to get the current working directory. All files will be created in `[working-directory]/docs/`.

## Step 2: Scan Available MCPs

List what MCP servers are available:
- supabase: Database operations
- chrome-devtools: UI testing
- web-search-prime: Research
- web-reader: Documentation fetching

## Step 3: Parse Input

- If input is "plan": Read `plan.md` from working directory and generate multiple PRDs
- If input is "fix" followed by instructions: Read existing PRDs and apply fixes
- If input starts with "I want" or contains "plan.md": Treat as "plan" mode, read plan.md
- Otherwise: Use input as feature description for single PRD

## Step 4: Generate PRDs

For "plan" mode:
1. Read plan.md
2. Identify major features (each should become a separate PRD)
3. For each feature, create:
   - `docs/prd-[feature-name].md` with user stories
   - `docs/consolidated-[feature-name].txt` memory stub

For single feature mode:
1. Parse feature description
2. Create `docs/prd-[feature-name].md` with user stories
3. Create `docs/consolidated-[feature-name].txt` memory stub

For "fix" mode:
1. Read existing PRD files from docs/
2. Apply fix instructions
3. Update files in place

## PRD Template

```markdown
---
project: [Feature Name]
branch: flow/[feature-name]
availableMCPs:
  - [relevant MCPs]
---

# [Feature Name]

## Overview
[2-3 sentences]

## Technical Approach
[Stack and patterns]

## User Stories

### US-001: [Title]
**Priority:** 1
**Maven Steps:** [1, 3, 7, 10]
**MCP Tools:**
- step1: []

As a [user], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [criteria 1]
- [criteria 2]
- [criteria 3]
- Typecheck passes

**Status:** false
```

**Story Guidelines:**
- Focused and atomic (1-2 hours each)
- Order by dependency: database → backend → UI
- Max 10 stories per PRD

## Memory Stub Template

```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: [Feature Name]
consolidatedDate: [Current Date]
totalStories: [Count]
completedStories: 0
status: initialized
---

# [Feature Name] - Consolidated Implementation Memory

## System Overview
[From PRD]

## Current Status
PRD created, waiting for execution.

## Stories to Implement
- US-001: [Title]
- US-002: [Title]
...
```

## Step 5: Display Summary and EXIT

```
==============================================================================
PRD Generation Complete
==============================================================================

Available MCPs:
- [list]

Created PRDs:
- docs/prd-[feature].md ([N] stories)

Memory files:
- docs/consolidated-[feature].txt

Next: flow-convert --all
```

**Then EXIT. Do NOT ask questions. Do NOT wait for confirmation.**

---

## EXECUTION CHECKLIST

When `/flow-prd` is invoked:

1. [ ] Get working directory with `pwd`
2. [ ] List available MCPs
3. [ ] Parse input (plan/fix/feature)
4. [ ] Create PRD markdown files
5. [ ] Create memory stub files
6. [ ] Display summary
7. [ ] EXIT immediately

**NEVER ASK QUESTIONS.**
