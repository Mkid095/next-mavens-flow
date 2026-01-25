---
description: Generate PRD markdown from user message or plan.md with memory loading - NO QUESTIONS
argument-hint: "[message describing what to build]"
---

# FLOW-PRD: Generate PRD Markdown with Memory Context

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

## STEP 2.5: LOAD EXISTING CONTEXT (MEMORY AWARENESS)

**CRITICAL: Before creating the PRD, you MUST load existing context from the codebase.**

### 2.5.1: Scan for Existing PRDs

**Execute:**
```bash
find docs -name "prd-*.json" -type f | sort
```

**For each PRD found, extract:**
- Project name
- Branch name
- Status (complete/incomplete based on `passes` field)
- Related PRDs (from `relatedPRDs` array)
- Consolidated memory (from `consolidatedMemory` field)

### 2.5.2: Load Consolidated Memories

**For each existing PRD, read the `consolidatedMemory` field and extract:**

**Architecture Patterns:**
- Tech stack choices (framework, database, state management)
- Project structure (feature-based, modular, etc.)
- Integration patterns (API, authentication, data flow)

**Key Decisions:**
- Design patterns used
- Libraries/frameworks chosen
- Architectural trade-offs

**Lessons Learned:**
- What worked well
- What didn't work
- Challenges resolved
- Best practices established

**Build a consolidated memory database:**
```
EXISTING_ARCHITECTURE = {
  tech_stack: [frameworks, databases, tools used],
  patterns: [architectural patterns established],
  decisions: [key architectural decisions],
  lessons: [lessons learned from all PRDs]
}
```

### 2.5.3: Load Story Memories

**Execute:**
```bash
find docs -name "story-*.txt" -type f | sort
```

**For each story memory file, extract:**

**From "LESSONS LEARNED" section:**
- Development process insights
- Tech stack learnings
- Architecture insights

**From "CHALLENGES RESOLVED" section:**
- Problems encountered
- Solutions applied
- Lessons for future

**From "CODE PATTERNS ESTABLISHED" section:**
- Reusable patterns
- Component structures
- API conventions

**Build a lessons learned database:**
```
LESSONS_LEARNED = {
  development: [lessons about process, workflow],
  technical: [lessons about tech stack, tools],
  architecture: [lessons about structure, patterns],
  integration: [lessons about connecting features]
}
```

### 2.5.4: Extract Integration Points

**From consolidated memories, identify:**

**Authentication Patterns:**
- How is authentication implemented across features?
- What auth provider is used?
- Role-based access control patterns?

**Data Layer Patterns:**
- Database technology (PostgreSQL, MongoDB, etc.)
- ORM/database client used
- Migration patterns

**API Patterns:**
- REST vs GraphQL
- API client libraries
- Error handling patterns

**State Management:**
- Client state: Redux, Zustand, Context, etc.
- Server state: React Query, SWR, etc.
- Real-time: WebSockets, SSE, etc.

**Build integration knowledge base:**
```
INTEGRATION_PATTERNS = {
  auth: { provider, patterns, roles },
  database: { technology, client, migrations },
  api: { style, client, errors },
  state: { client, server, realtime }
}
```

---

## STEP 2.6: ANALYZE FEATURE RELATIONSHIPS

**CRITICAL: Analyze how the new feature relates to existing features.**

### 2.6.1: Identify Dependencies

**For each existing feature, determine:**

**1. Does the new feature depend on this existing feature?**

Ask yourself:
- Does the new feature need authentication from this feature?
- Does the new feature consume data from this feature?
- Does the new feature extend components from this feature?
- Does the new feature use APIs from this feature?

**If YES to any:** Add to `relatedPRDs` as **"depends_on"**

**Example:**
- New feature: "payments"
- Existing feature: "auth"
- Question: Does payments need authentication?
- Answer: YES → `relatedPRDs: ["prd-auth.json"]`

**2. Does this existing feature depend on the new feature?**

Ask yourself:
- Will this feature consume data from the new feature?
- Will this feature extend components from the new feature?
- Will this feature use APIs from the new feature?

**If YES to any:** Add to `relatedPRDs` as **"depended_by"**

**Example:**
- New feature: "products"
- Existing feature: "orders"
- Question: Will orders consume product data?
- Answer: YES → `relatedPRDs: ["prd-orders.json"]` (as depended_by)

### 2.6.2: Identify Integration Points

**For each related feature, identify:**

**Data Flow:**
- What data flows between features?
- Direction of data flow (bidirectional?)
- Real-time vs batch synchronization

**Component Sharing:**
- Shared UI components?
- Shared utilities/libraries?
- Shared types/interfaces?

**Authentication:**
- Does this feature require authenticated users?
- What roles need access?
- Any special permissions?

**Build relationship map:**
```
RELATIONSHIPS = {
  prd-auth.json: {
    type: "depends_on",
    reason: "Payments require authenticated users",
    integration: "user sessions, role-based access"
  },
  prd-products.json: {
    type: "depended_by",
    reason: "Orders will consume product catalog",
    integration: "product data, inventory updates"
  }
}
```

### 2.6.3: Tag Related PRDs in Markdown

**In the markdown PRD, include:**

```markdown
## Related Features

### Depends On (these features must exist first):
- **auth**: User authentication and authorization (prd-auth.json)
  - Why: Payments require authenticated users
  - Integration: User sessions, role-based access control

- **products**: Product catalog and inventory (prd-products.json)
  - Why: Payments process product purchases
  - Integration: Product pricing, inventory validation

### Will Be Used By (these features depend on this):
- **orders**: Order processing and management (prd-orders.json)
  - Why: Orders need payment processing
  - Integration: Payment status, transaction history
```

---

## STEP 3: Generate PRD Markdown Files

**Create PRD in MARKDOWN format** (not JSON) at: `docs/prd-[feature-name].md`

**Use this enhanced markdown structure:**

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

## Context from Existing Features

[INCLUDE this section ONLY if there are existing PRDs]

### Architecture Alignment
This feature follows established patterns from the codebase:

**Tech Stack:**
[From EXISTING_ARCHITECTURE - match existing choices]

**Project Structure:**
[From EXISTING_ARCHITECTURE - follow feature-based pattern]

**Integration Patterns:**
[From INTEGRATION_PATTERNS - match existing approach]

### Lessons Learned
[From LESSONS_LEARNED - avoid past mistakes]

**Key Lessons to Apply:**
- [Lesson 1 from database]
- [Lesson 2 from state management]
- [Lesson 3 from API design]

## Related Features

### Depends On (these features must exist first):
[List features that must be implemented first, with reasons]

### Will Be Used By (these features depend on this):
[List features that will depend on this one, with reasons]

### Integration Points:
[Describe how this feature integrates with existing features]

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

---

## Implementation Notes

[If there are existing features, include notes about:]
- Integration with existing [feature]
- Reusing components from [feature]
- Following patterns from [feature]
- Avoiding mistakes from [feature]
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
relatedPRDs: [List of related PRD filenames from analysis]
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
[List related PRDs with relationship types]

## Stories to Implement
[List all story IDs and titles from PRD]

## Memory Structure
This file will be updated as stories complete

## Lessons from Related Features
[Include key lessons from related PRDs that apply to this feature]
```

---

## STEP 5: Display Summary

```
==============================================================================
PRD Generation Complete
==============================================================================

Working Directory: [from pwd]

Input Source: [plan.md OR user message]

Memory Context Loaded:
- Existing PRDs Found: [number]
- Consolidated Memories Loaded: [number]
- Story Memories Loaded: [number]
- Related Features Identified: [list]

Created PRD (Markdown):
- docs/prd-[feature-name].md

Memory File:
- docs/consolidated-[feature-name].txt

Total Stories: [number]

Context Applied:
- Following architecture patterns from: [features]
- Integrating with: [features]
- Applying lessons from: [number] story memories

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
2. **SCAN for existing PRDs and LOAD consolidated memories**
3. **SCAN for story memories and EXTRACT lessons learned**
4. **ANALYZE feature relationships and TAG relatedPRDs**
5. Generate PRD in MARKDOWN format (with rich context)
6. Generate consolidated memory file
7. Display summary with context details
8. Run flow-convert to validate MCPs and create JSON
9. EXIT

---

## MEMORY LOADING SUMMARY

**When creating a PRD, you MUST:**

1. **Find existing PRDs** → `find docs -name "prd-*.json"`
2. **Load consolidated memories** → Extract architecture, patterns, lessons
3. **Find story memories** → `find docs -name "story-*.txt"`
4. **Extract lessons learned** → From "LESSONS LEARNED" sections
5. **Analyze relationships** → Determine dependencies
6. **Tag related features** → In markdown PRD with reasons
7. **Include context** → In PRD's "Context from Existing Features" section

**This ensures new features:**
- Follow established architecture patterns
- Avoid past mistakes
- Integrate properly with existing features
- Benefit from lessons learned

---

**CRITICAL: Always generate markdown PRDs first with full context, then flow-convert handles JSON conversion with MCP validation.**

**EXECUTE NOW.**
