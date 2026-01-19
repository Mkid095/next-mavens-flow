---
description: Parse plan.md and create multiple PRDs - NO QUESTIONS
argument-hint: [plan]
---

# FLOW-PRD: PARSE PLAN.MD, CREATE MULTIPLE PRDS, EXIT

**DO NOT ASK QUESTIONS. EXECUTE STEPS. CREATE FILES. EXIT.**

---

## STEP 1: Get Working Directory

Execute: `pwd`

---

## STEP 2: Read plan.md

Execute: `cat plan.md`

---

## STEP 3: Parse plan.md Structure

The plan.md contains TWO complete PRDs:
1. **Web Version** (lines 1-237) - "Next Mavens Artboard System (NNMA)"
2. **Desktop Edition** (lines 237-522) - "NNMA – Desktop Edition"

For EACH PRD, extract major features from these sections:
- ### 3.1 Workspace (Dashboard) → `prd-workspace.md`
- ### 3.2 Vector Engine (Canvas) → `prd-vector-canvas.md`
- ### 3.3 Property System → `prd-property-system.md`
- Typography → `prd-typography.md`
- System Architecture → `prd-technical-architecture.md`
- Performance → `prd-performance.md`
- UI/UX → `prd-ui-ux.md`
- Documentation → `prd-documentation.md`
- Keyboard/Commands → `prd-keyboard-shortcuts.md`
- Export → `prd-export-documentation.md`
- AI Integration → `prd-ai-analysis-integration.md`

---

## STEP 4: Create PRD Files

For EACH feature identified:

### Create: `docs/prd-[feature-name].md`

```markdown
---
project: [Feature Name]
branch: flow/[feature-name]
availableMCPs:
  - supabase
  - chrome-devtools
  - web-search-prime
---

# [Feature Name]

## Overview
[Extracted from plan.md - 2-3 sentences]

## Technical Approach
[Extracted from plan.md]

## User Stories

### US-001: [Story from feature]
**Priority:** 1
**Maven Steps:** [1, 3, 7, 10]
**MCP Tools:** []

As a [user type from plan.md], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [Extract from plan.md requirements]
- Typecheck passes

**Status:** false

[Add more stories as needed - max 10 per PRD]
```

---

## STEP 5: Create Memory Files

For EACH PRD created:

### Create: `docs/consolidated-[feature-name].txt`

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
[From PRD overview]

## Current Status
PRD created, waiting for execution.

## Technical Approach
[From PRD technical approach]

## Related PRDs
[List other PRDs this integrates with]

## Stories to Implement
[List all story IDs and titles from PRD]

## Memory Structure
This file will be updated as stories complete.
```

---

## STEP 6: Display Summary

```
==============================================================================
PRD Generation Complete
==============================================================================

Working Directory: [from pwd]

Analyzed: plan.md (2 PRDs - Web + Desktop)

Created PRDs:
- docs/prd-workspace.md
- docs/prd-vector-canvas.md
- docs/prd-property-system.md
- docs/prd-typography.md
- docs/prd-technical-architecture.md
- docs/prd-ui-ux.md
- docs/prd-performance.md
- docs/prd-documentation.md
- docs/prd-keyboard-shortcuts.md
- docs/prd-export-documentation.md
- docs/prd-ai-analysis-integration.md

Memory Files:
- docs/consolidated-workspace.txt
- docs/consolidated-vector-canvas.txt
- docs/consolidated-property-system.txt
- docs/consolidated-typography.txt
- docs/consolidated-technical-architecture.txt
- docs/consolidated-ui-ux.txt
- docs/consolidated-performance.txt
- docs/consolidated-documentation.txt
- docs/consolidated-keyboard-shortcuts.txt
- docs/consolidated-export-documentation.txt
- docs/consolidated-ai-analysis-integration.txt

Total: 11 PRDs + 11 Memory Files

Next: flow-convert --all
==============================================================================
```

---

## STEP 7: EXIT

**DO NOT ASK QUESTIONS. DO NOT REQUEST INPUT. EXIT IMMEDIATELY.**

---

## EXECUTION RULES

1. Read plan.md completely
2. Parse BOTH PRDs (Web + Desktop)
3. Extract ALL major features (### 3.x sections)
4. Create PRD file for EACH feature
5. Create memory file for EACH PRD
6. Display summary
7. EXIT

---

**EXECUTE NOW.**
