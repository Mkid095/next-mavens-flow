---
description: Generate PRD markdown from user message or plan.md - NO QUESTIONS
argument-hint: "[message describing what to build]"
---

# FLOW-PRD: Generate PRD Markdown from Message or Plan

**DO NOT ASK QUESTIONS. EXECUTE STEPS. CREATE FILES. EXIT.**

---

## STEP 1: Determine Input Source

**Check if plan.md exists:**

Execute: `test -f plan.md && echo "EXISTS" || echo "NOT_FOUND"`

**IF plan.md EXISTS:**
- Use plan.md as input source
- Parse structure and extract features
- Skip to STEP 3

**IF plan.md DOES NOT EXIST:**
- Check if a message was provided with the command
- Extract features from the message
- Proceed to STEP 2

---

## STEP 2: Extract Features from Message (if no plan.md)

**Analyze the user's message** to identify:
- Main feature/application being described
- Key components or modules mentioned
- User roles or use cases
- Technical requirements or constraints

**Generate a structured feature breakdown:**
1. Main application/feature name (kebab-case for filename)
2. Feature description (1-2 sentences)
3. Key sub-features (3-8 items)
4. Technical approach
5. Target platform (web/mobile/desktop)

**Example message analysis:**
- "I want to build a task management app with real-time updates and user authentication"
  → Feature: task-management
  → Sub-features: dashboard, task-list, real-time-updates, user-auth, team-workspaces

---

## STEP 3: Generate PRD Markdown Files

**Create PRD in MARKDOWN format** (not JSON) at: `docs/prd-[feature-name].md`

Use this exact markdown structure:

```markdown
---
project: [Feature Name]
branchName: flow/[feature-name-kebab-case]
description: [One-line description]
availableMCPs:
  - supabase
  - chrome-devtools
  - web-search-prime
---

# [Feature Name]

## Overview

[Brief 2-3 sentence description of what this feature does and its main purpose.]

## Technical Approach

[Description of the technical stack, architecture, and implementation approach.]

## User Stories

### US-001: [Story Title - What user wants]

**Priority:** 1
**Maven Steps:** [1, 3, 5, 7]
**MCP Tools:** `{ step1: ["supabase"], step7: ["supabase", "chrome-devtools"] }`

**Description:**
As a [user role], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [Specific, verifiable requirement 1]
- [Specific, verifiable requirement 2]
- [Specific, verifiable requirement 3]

---

### US-002: [Second Story Title]

**Priority:** 2
**Maven Steps:** [1, 3]
**MCP Tools:** `{}`

**Description:**
As a [user role], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [Requirement 1]
- [Requirement 2]

### US-002: [Second Story Title]

**Priority:** 2
**Maven Steps:** [1, 3]
**MCP Tools:** `{}`

**Description:**
As a [user role], I want to [action] so that [benefit].

**Acceptance Criteria:**
- [Requirement 1]
- [Requirement 2]

---

## Related Features

- List other PRDs/features this integrates with
- Leave empty if standalone
```

**Rules for mavenSteps:**
- Step 1: Foundation/UI from scratch → development-agent
- Step 2: Package manager changes → development-agent
- Step 3: Feature structure changes → refactor-agent
- Step 4: Component modularization (>300 lines) → refactor-agent
- Step 5: Type safety enforcement → quality-agent
- Step 6: UI centralization → refactor-agent
- Step 7: Data layer/backend → development-agent
- Step 8: Auth/integration → security-agent
- Step 9: MCP integration → development-agent
- Step 10: Security hardening → security-agent
- Step 11: Mobile UI design → design-agent

**Rules for mcpTools:**
- Only specify MCP server names (e.g., "supabase", "chrome-devtools")
- Use empty object `{}` if no MCPs needed
- Don't worry about available MCPs here - flow-convert will validate

**Rules for priority:**
- Lower number = higher priority (executed first)
- Start priority at 1 for first story
- Increment for subsequent stories

---

## STEP 4: Create Consolidated Memory File

**Create:** `docs/consolidated-[feature-name].txt`

```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: [Feature Name]
consolidatedDate: [Current Date in ISO format]
totalStories: [Number of stories in PRD]
completedStories: 0
status: initialized
---

# [Feature Name] - Consolidated Implementation Memory

## System Overview
[Brief description of what this feature does]

## Key Architectural Decisions
- Initial setup and architecture decisions will be documented here as stories complete

## Public Interfaces
- API endpoints, UI components, and integration points will be listed here

## Integration Patterns
- How this feature connects to other PRDs

## Related PRDs
[None initially - will be updated as related features are added]

## Stories to Implement
[List all story IDs and titles from PRD]

## Memory Structure
This file will be updated as stories complete
```

---

## STEP 5: Display Summary

```
==============================================================================
PRD Generation Complete
==============================================================================

Working Directory: [from pwd]

Input Source: [plan.md OR user message]

Created PRD (Markdown):
- docs/prd-[feature-name].md

Memory File:
- docs/consolidated-[feature-name].txt

Total Stories: [number]

Next Steps:
1. Review the PRD: cat docs/prd-[feature-name].md
2. Edit if needed: nano docs/prd-[feature-name].md
3. Convert to JSON: flow-convert docs/prd-[feature-name].md
4. Start development: flow start
==============================================================================
```

---

## STEP 6: Run flow-convert

**Convert PRD markdown to JSON (validates MCPs):**

Execute: `flow-convert docs/prd-[feature-name].md`

---

## STEP 7: EXIT

**DO NOT ASK QUESTIONS. DO NOT REQUEST INPUT. EXIT IMMEDIATELY.**

---

## EXECUTION RULES

1. Accept user message OR read plan.md
2. Extract main feature and sub-features
3. Generate PRD in MARKDOWN format (human-readable)
4. Generate consolidated memory file
5. Display summary
6. Run flow-convert to validate MCPs and create JSON
7. EXIT

---

**CRITICAL: Always generate markdown PRDs first, then flow-convert handles JSON conversion with MCP validation.**

**EXECUTE NOW.**
