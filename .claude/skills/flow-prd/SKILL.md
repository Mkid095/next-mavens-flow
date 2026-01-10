---
name: flow-prd
description: "Generate a Product Requirements Document (PRD) for next-mavens-flow. Use when planning features, starting new projects, or creating requirements. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

# Flow PRD Generator

Create detailed Product Requirements Documents optimized for the next-mavens-flow autonomous development system.

---

## The Job

1. Receive a feature description from the user
2. Ask 3-5 essential clarifying questions (with lettered options)
3. Generate a structured PRD based on answers
4. Save to `tasks/prd-[feature-name].md`

**Important:** Do NOT start implementing. Just create the PRD.

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core Functionality:** What are the key actions?
- **Scope/Boundaries:** What should it NOT do?
- **Success Criteria:** How do we know it's done?

### Format Questions Like This:

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI
```

This lets users respond with "1A, 2C, 3B" for quick iteration.

---

## Step 2: PRD Structure

Generate the PRD with these sections:

### 1. Title
Concise feature name.

### 2. Overview
Brief description of the feature and the problem it solves.

### 3. Goals
Specific, measurable objectives (bullet list).

### 4. User Stories

Each story needs:
- **ID:** Sequential (US-001, US-002, etc.)
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist

**Critical:** Each story must be **small enough to complete in one iteration**.

**Format:**
```markdown
### US-001: [Title]

**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck/lint passes
- [ ] **[UI stories only]** Verify in browser

**Priority:** 1
```

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### 5. Functional Requirements
Numbered list:
- FR-1: The system must allow users to...
- FR-2: When a user clicks X, the system must...

### 6. Non-Goals
What this feature will NOT include (critical for scope management).

### 7. Technical Considerations
- Known constraints or dependencies
- Integration points with existing systems
- Performance requirements

### 8. Success Metrics
How will success be measured?

---

## Story Ordering: Dependencies First

Stories must be ordered by priority (dependency order):

1. **Schema/database changes** (migrations)
2. **Server actions / backend logic**
3. **UI components that use the backend**
4. **Dashboard/summary views that aggregate data**

**Correct order:**
- US-001: Add database column
- US-002: Create API endpoint
- US-003: Build UI component
- US-004: Add summary view

**Wrong order:**
- US-001: UI component (depends on schema that doesn't exist yet)
- US-002: Schema change

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

### Always include as final criterion:
```
- [ ] Typecheck passes
```

For stories with testable logic, also include:
```
- [ ] Tests pass
```

### For stories that change UI:
```
- [ ] Verify in browser
```

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Task Priority System

## Overview

Add priority levels to tasks so users can focus on what matters most.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering and sorting by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field to database

**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration successfully
- [ ] Typecheck passes

**Priority:** 1

### US-002: Display priority indicator on task cards

**Description:** As a user, I want to see task priority at a glance.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering or clicking
- [ ] Typecheck passes
- [ ] Verify in browser

**Priority:** 2

### US-003: Add priority selector to task edit

**Description:** As a user, I want to change a task's priority when editing.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] Typecheck passes
- [ ] Verify in browser

**Priority:** 3

## Functional Requirements

- FR-1: Add `priority` field to tasks table ('high' | 'medium' | 'low', default 'medium')
- FR-2: Display colored priority badge on each task card
- FR-3: Include priority selector in task edit modal
- FR-4: Add priority filter dropdown to task list header

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
- Priority stored in database, not computed

## Success Metrics

- Users can change priority in under 2 clicks
- High-priority tasks immediately visible at top of lists
- No regression in task list performance
```

---

## Checklist

Before saving the PRD:

- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories are small and specific
- [ ] Stories are ordered by dependency
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Saved to `tasks/prd-[feature-name].md`
