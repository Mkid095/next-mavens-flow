---
description: Generate PRDs - EXECUTE DIRECTLY, DO NOT ASK QUESTIONS
argument-hint: [plan] or [feature description]
---

# EXECUTE WITHOUT ASKING QUESTIONS

**YOUR TASK: Generate PRD files without any interaction with the user.**

## Step 1: Get Working Directory

Execute: `pwd`

## Step 2: Parse Input Argument

- If argument is "plan": Go to Step 3 (Plan Mode)
- If argument starts with "fix": Go to Step 5 (Fix Mode)
- Otherwise: Go to Step 4 (Single Feature Mode)

## Step 3: Plan Mode - Read plan.md and Generate PRDs

1. Execute: `cat plan.md` from working directory
2. Identify major features in the plan (each becomes a separate PRD)
3. For each feature:
   - Create `docs/prd-[feature-name].md`
   - Create `docs/consolidated-[feature-name].txt`

4. Use this PRD template:

```markdown
---
project: [Feature Name]
branch: flow/[feature-name]
availableMCPs:
  - supabase
---

# [Feature Name]

## Overview
[2-3 sentences]

## User Stories

### US-001: [Title]
**Priority:** 1
**Maven Steps:** [1, 3, 7, 10]
**MCP Tools:** []

As a [user], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [criteria]
- Typecheck passes

**Status:** false
```

5. Go to Step 6

## Step 4: Single Feature Mode - Create One PRD

1. Parse the feature description
2. Create `docs/prd-[feature-name].md`
3. Create `docs/consolidated-[feature-name].txt`
4. Go to Step 6

## Step 5: Fix Mode - Update Existing PRDs

1. Read existing PRD files from `docs/prd-*.md`
2. Apply fix instructions
3. Update files in place
4. Go to Step 6

## Step 6: Display Summary and EXIT

```
==============================================================================
PRD Generation Complete
==============================================================================

Created PRDs:
- docs/prd-[feature].md

Memory files:
- docs/consolidated-[feature].txt

Next: flow-convert --all
==============================================================================
```

**THEN EXIT. DO NOT ASK ANY QUESTIONS.**

---

## RULES - YOU MUST FOLLOW THESE

1. **DO NOT ASK THE USER ANY QUESTIONS**
2. **DO NOT REQUEST CLARIFICATION**
3. **DO NOT ASK FOR CONFIRMATION**
4. **EXECUTE THE STEPS ABOVE**
5. **CREATE THE FILES**
6. **DISPLAY SUMMARY**
7. **EXIT**

---

## MCP Mapping

| Feature | Use MCP |
|---------|---------|
| Database operations | supabase |
| UI testing | chrome-devtools |
| Research | web-search-prime |
| Documentation | web-reader |

---

## Story Guidelines

- Keep stories atomic (1-2 hours each)
- Order: database → backend → UI → integration
- Max 10 stories per PRD
- Each story: title, priority, maven steps, acceptance criteria

---

**EXECUTE NOW. DO NOT ASK QUESTIONS.**
