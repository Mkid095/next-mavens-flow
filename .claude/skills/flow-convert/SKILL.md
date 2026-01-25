---
name: flow-convert
description: "Convert PRDs to prd.json format with memory loading and relationship analysis. Validates MCPs and tags related features. Triggers on: convert this prd, turn this into flow format, create prd.json from this, flow json."
---

# Flow PRD Converter with Memory Loading

Converts existing PRDs (markdown) to the `prd.json` format that next-mavens-flow uses for autonomous execution.

**NEW: Now loads existing context and analyzes feature relationships.**

---

## The Job

Take a markdown PRD and convert it to `docs/prd-[feature-name].json`. Create `docs/` folder if it doesn't exist.

**Important:** Each feature gets its own PRD JSON file. The flow command will scan for all `prd-*.json` files in `docs/` and process incomplete ones.

**CRITICAL:** Each story MUST have its own `mcpTools` object specifying which MCPs to use for each Maven step.

---

## STEP 1: Read the Markdown PRD

**Read the input PRD file:**

Execute: `cat "$PRD_FILE"`

**Extract key information:**
- Project name
- Branch name
- Description
- User stories
- Related features (from flow-prd.md Step 2.6)
- Context from existing features (if included)

---

## STEP 2: SCAN EXISTING JSON PRDs

**CRITICAL: Before creating the JSON PRD, scan for existing PRDs to understand relationships.**

Execute: `find docs -name "prd-*.json" -type f | sort`

**For each existing PRD found:**

1. **Read the PRD** to understand:
   - What feature it implements
   - Its status (check if all stories have `passes: true`)
   - Its relatedPRDs array
   - Its consolidatedMemory (if complete)

2. **Build a feature map:**
   ```
   FEATURE_MAP = {
     "prd-auth.json": {
       name: "User Authentication",
       status: "complete" | "incomplete",
       related: ["prd-payments.json"],
       consolidated: "..."
     },
     "prd-products.json": {
       name: "Product Catalog",
       status: "complete",
       related: ["prd-orders.json"],
       consolidated: "..."
     }
   }
   ```

---

## STEP 3: LOAD CONSOLIDATED MEMORIES

**From all complete PRDs, load consolidated memories:**

Execute: For each complete PRD, read its `consolidatedMemory` field

**Extract and categorize:**

**Architecture Decisions:**
```json
{
  "tech_stack": {
    "framework": "Next.js 14",
    "database": "Supabase (PostgreSQL)",
    "state": "React Query + Zustand",
    "auth": "Supabase Auth"
  },
  "structure": {
    "pattern": "feature-based",
    "directories": "src/features/, src/shared/"
  },
  "decisions": [
    "Feature-based architecture for isolation",
    "React Query for server state caching"
  ]
}
```

**Lessons Learned:**
```json
{
  "lessons": [
    "Always generate Supabase types first",
    "Feature isolation prevents merge conflicts",
    "Zero 'any' types policy catches bugs early"
  ]
}
```

**Integration Patterns:**
```json
{
  "authentication": {
    "provider": "Supabase Auth",
    "roles": ["SUPER_ADMIN", "SHOP_OWNER", "SHOP_EMPLOYEE"],
    "session": "server-side sessions"
  },
  "database": {
    "client": "@supabase/supabase-js",
    "migrations": "Supabase migrations",
    "types": "supabase gen types typescript"
  }
}
```

---

## STEP 4: ANALYZE FEATURE RELATIONSHIPS

**CRITICAL: Analyze how this PRD relates to existing PRDs.**

### 4.1: Extract Relationships from Markdown PRD

**From the markdown PRD's "Related Features" section, extract:**

**Depends On:**
- Feature names that must exist first
- Reasons for dependency
- Integration points

**Will Be Used By:**
- Feature names that will depend on this
- Reasons for the dependency
- Future integration points

### 4.2: Cross-Reference with Existing PRDs

**For each related feature mentioned in the markdown PRD:**

1. **Find the corresponding JSON PRD:**
   - If markdown says "auth", find "prd-auth.json"
   - If markdown says "products", find "prd-products.json"

2. **Verify the PRD exists:**
   ```bash
   test -f "docs/prd-[feature].json" && echo "EXISTS" || echo "NOT_FOUND"
   ```

3. **Check the status:**
   - Complete: All stories have `passes: true`
   - Incomplete: Some stories have `passes: false`

4. **Build the relatedPRDs array:**
   ```json
   {
     "relatedPRDs": [
       {
         "prd": "prd-auth.json",
         "type": "depends_on",
         "status": "complete",
         "reason": "Payments require authenticated users",
         "integration": "user sessions, role-based access"
       },
       {
         "prd": "prd-products.json",
         "type": "depends_on",
         "status": "complete",
         "reason": "Payments process product purchases",
         "integration": "product pricing, inventory validation"
       },
       {
         "prd": "prd-orders.json",
         "type": "depended_by",
         "status": "incomplete",
         "reason": "Orders will need payment processing",
         "integration": "payment status, transaction history"
       }
     ]
   }
   ```

### 4.3: Validate Relationship Types

**Valid relationship types:**
- `depends_on`: This PRD depends on the related PRD
- `depended_by`: The related PRD depends on this one
- `bidirectional`: Mutual dependency (be careful with these!)

**Integration categories:**
- `authentication`: User auth, roles, permissions
- `data`: Data consumption, API calls, shared models
- `components`: Shared UI components, utilities
- `infrastructure`: Shared infrastructure, services

### 4.4: Handle Edge Cases

**If a related PRD doesn't exist:**
- Add a warning in the JSON PRD's notes field
- Example: `WARNING: Related PRD prd-xyz.json not found - may need to be created first`

**If circular dependencies detected:**
- Add a warning in the notes field
- Example: "WARNING: Circular dependency detected with prd-abc.json - review execution order"

---

## STEP 5: VALIDATE MCP AVAILABILITY

**CRITICAL: Before assigning MCPs to stories, validate they are available.**

### 5.1: Scan for Available MCPs

**How to discover available MCPs:**

**Method 1: Check Claude Code settings**
```bash
cat ~/.claude/settings.json | jq '.mcpServers | keys'
```

**Method 2: Check project-level settings**
```bash
cat .claude/settings.json 2>/dev/null | jq '.mcpServers | keys' || echo "No project MCP settings"
```

**Method 3: Check environment variables**
```bash
env | grep -i mcp || echo "No MCP environment variables found"
```

**Method 4: Ask the user**
If uncertain, ask: "What MCP servers do you have configured? (e.g., supabase, chrome-devtools, web-search-prime)"

### 5.2: Document Available MCPs

**Build the available MCPs list:**
```json
{
  "availableMCPs": {
    "supabase": {
      "status": "available",
      "tools": ["query", "mutate", "subscribe"]
    },
    "chrome-devtools": {
      "status": "available",
      "tools": ["navigate", "evaluate", "screenshot"]
    },
    "web-search-prime": {
      "status": "not_available"
    }
  }
}
```

### 5.3: Assign MCPs Based on Availability

**For each story:**

1. **Identify Maven steps** required
2. **For each step**, check if MCPs are needed:
   - Database operations → supabase
   - Browser testing → chrome-devtools
   - Documentation → web-search-prime
3. **Verify MCP is available** before assigning
4. **Only assign available MCPs** - leave `mcpTools` empty `{}` if unsure

**Example:**
```json
{
  "id": "US-001",
  "title": "Create products table",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],    // Available - assigned
    "step7": ["supabase"]     // Available - assigned
  }
}
```

**If MCP not available:**
```json
{
  "id": "US-002",
  "title": "Test checkout flow",
  "mavenSteps": [5],
  "mcpTools": {}  // chrome-devtools not available - left empty
}
```

---

## STEP 6: BUILD LESSONS LEARNED

**Extract lessons learned from all consolidated memories:**

**From TECH_STACK decisions:**
- Which frameworks work well together
- What database choices were made
- What state management approach works

**From LESSONS_LEARNED sections:**
- Development process insights
- Technical stack learnings
- Architecture insights
- Integration challenges and solutions

**Build lessonsLearned string:**
```json
{
  "lessonsLearned": "# Lessons Learned from Existing Features

## Tech Stack
- Framework: Next.js 14 provides excellent developer experience
- Database: Supabase offers PostgreSQL + real-time + auth in one service
- State: React Query eliminates most loading state boilerplate

## Architecture
- Feature-based architecture prevents merge conflicts
- src/features/ for feature code, src/shared/ for reusable code
- No cross-feature imports - use shared/ instead

## Integration
- Always generate types before implementing features
- Zero 'any' types policy catches bugs early
- Supabase real-time requires careful subscription management

## Common Patterns
- All API calls go through feature-specific api/ directories
- Centralized error handling in @shared/api/errors
- Components < 300 lines must be split"
}
```

---

## STEP 7: GENERATE JSON PRD

**Create the JSON PRD file** at: `docs/prd-[feature-name].json`

**Use this enhanced structure:**

```json
{
  "project": "[Project Name]",
  "branchName": "flow/[feature-name-kebab-case]",
  "description": "[Feature description from PRD]",

  "relatedPRDs": [
    {
      "prd": "prd-auth.json",
      "type": "depends_on",
      "status": "complete",
      "reason": "Payments require authenticated users",
      "integration": "user sessions, role-based access control"
    }
  ],

  "consolidatedMemory": "",

  "lessonsLearned": "# Lessons Learned\n\n[From STEP 6 above]",

  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "[Criterion 1]",
        "[Criterion 2]",
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
    }
  ]
}
```

**Field descriptions:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | string | Yes | Project/feature name |
| `branchName` | string | Yes | Git branch name (flow/ prefix) |
| `description` | string | Yes | Brief description |
| `relatedPRDs` | array | No | Related PRDs with metadata (NEW) |
| `consolidatedMemory` | string | Yes | Empty initially, filled when PRD complete |
| `lessonsLearned` | string | Yes | Lessons from existing features (NEW) |
| `userStories` | array | Yes | Array of story objects |

**Story object fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | US-XXX format |
| `title` | string | Yes | Story title |
| `description` | string | Yes | User story format |
| `acceptanceCriteria` | array | Yes | Verifiable criteria |
| `mavenSteps` | array | Yes | Maven steps required |
| `mcpTools` | object | Yes | Step-based MCP assignments |
| `priority` | number | Yes | Execution order (1 = first) |
| `passes` | boolean | Yes | Set to true when complete |
| `notes` | string | Yes | For warnings or notes |

---

## MCP Tool Assignment (Story-Level, Step-Based)

**CRITICAL ARCHITECTURE DECISION:** MCPs are assigned PER STORY PER STEP, not at the PRD level.

**SCAN FIRST - Discover Available MCPs:**

**BEFORE assigning any MCPs to stories, you MUST:**

1. **Check which MCP servers are available** in the current environment
2. **Only assign MCPs that actually exist** - don't guess or assume
3. **If unsure, leave mcpTools empty** `{}` rather than guessing wrong

**How to Discover Available MCPs:**
- Check the user's MCP configuration
- Ask the user what MCPs they have configured
- Look for common MCP patterns in the project (e.g., if using Supabase, check if supabase MCP is set up)

**Why Scan First?**
- Prevents assigning MCPs that don't exist
- Avoids confusion when agents can't find the MCP
- Ensures PRD matches actual environment capabilities

**Why Story-Level MCP Assignment?**

1. **Context Isolation:** Each story has its own specific MCPs, reducing confusion as context grows
2. **Precision:** Flow command tells agents exactly which MCPs to use for each step
3. **No Hallucination:** Prevents agents from "forgetting" which MCPs are available in large contexts
4. **Granular Control:** Different stories and steps can use different MCPs

**How to Assign MCPs to Stories:**

When creating a PRD JSON, for each story:

1. **Identify which Maven steps** the story requires (see Maven Steps Field section below)
2. **For each step**, specify which MCPs to use (ONLY from discovered/available MCPs)
3. **List MCPs in `mcpTools` object** with step-based keys (e.g., `step1`, `step7`)

**Important:** You only specify the MCP **name**, not individual tools. The agent will automatically discover and use the available tools from that MCP.

**Common MCPs (verify these are available before using):**

| MCP Name | Use For Steps |
|----------|--------------|
| supabase | 7, 8, 10 (database operations) |
| web-search-prime | All steps (research, documentation) |
| web-reader | All steps (reading web content) |
| chrome-devtools | Testing (browser automation) |
| vercel | 9 (deployment) |
| wrangler | 9 (deployment) |
| figma | 11 (design) |

**Example MCP Assignment:**
```json
{
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

This tells the flow:
- For Step 1: Use supabase MCP
- For Step 7: Use supabase MCP and web-search-prime MCP

---

## Maven Steps Field

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
| 11 | design-agent | Mobile Design - Professional UI/UX for Expo/React Native (optional) |

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
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase"]
  }
}

// UI component story
{
  "id": "US-002",
  "title": "Add status badge to task cards",
  "mavenSteps": [5, 6],  // Type safety + UI centralization
  "mcpTools": {}
}

// Full feature story
{
  "id": "US-003",
  "title": "Create user profile page",
  "mavenSteps": [1, 3, 5, 6, 7, 10],  // Most steps
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"],
    "step10": ["web-search-prime"]
  }
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE flow iteration (one context window).**

The flow spawns fresh each iteration with no memory of previous work. If a story is too big, the context fills before finishing and produces broken code.

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

**CONSIDER relatedPRDs when ordering:**
- If this PRD depends on prd-auth.json, auth must be complete first
- Add notes about dependency requirements
- Consider priority in the broader project context

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
8. **CRITICAL**: Add `mcpTools` object to each story - only list MCP names, not individual tools
9. **NEW**: Add `relatedPRDs` array with relationship metadata
10. **NEW**: Add `lessonsLearned` field with context from existing features
11. **NEW**: Add `consolidatedMemory` field (empty initially)

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

### Input PRD (Markdown from flow-prd.md)

```markdown
---
project: Payment Processing
branchName: flow/payment-processing
description: Payment processing feature for e-commerce
availableMCPs:
  - supabase
  - chrome-devtools
  - web-search-prime
---

# Payment Processing

## Overview

Payment processing system for e-commerce transactions with multiple payment methods.

## Context from Existing Features

### Architecture Alignment
This feature follows established patterns from the codebase:

**Tech Stack:**
- Framework: Next.js 14 (App Router)
- Database: Supabase (PostgreSQL)
- State: React Query + Zustand
- Auth: Supabase Auth

**Project Structure:**
- Feature-based architecture under src/features/
- Shared code in src/shared/

**Integration Patterns:**
- API calls through feature-specific api/ directories
- Centralized error handling in @shared/api/errors

### Lessons Learned
**Key Lessons to Apply:**
- Always generate Supabase types before implementing features
- Feature isolation prevents merge conflicts
- React Query eliminates most loading state boilerplate

## Related Features

### Depends On (these features must exist first):
- **auth**: User authentication and authorization (prd-auth.json)
  - Why: Payments require authenticated users
  - Integration: User sessions, role-based access control
  - Status: Complete

- **products**: Product catalog and inventory (prd-products.json)
  - Why: Payments process product purchases
  - Integration: Product pricing, inventory validation
  - Status: Complete

### Will Be Used By (these features depend on this):
- **orders**: Order processing and management (prd-orders.json)
  - Why: Orders need payment processing
  - Integration: Payment status, transaction history
  - Status: Incomplete

### Integration Points:
- Will use user sessions from auth feature
- Will consume product data from products feature
- Will provide payment status to orders feature

## User Stories

### US-001: Setup payment database schema

**Priority:** 1
**Maven Steps:** [1, 7]
**MCP Tools:** `{ step1: ["supabase"], step7: ["supabase"] }`

**Description:**
As a developer, I need to create payment database tables.

**Acceptance Criteria:**
- Create payments table with id, amount, status, method
- Create payment_methods table with id, type, is_active
- Add foreign key to users table (from auth)
- Generate and run migration successfully
- Typecheck passes

---

### US-002: Integrate payment gateway API

**Priority:** 2
**Maven Steps:** [7, 9, 10]
**MCP Tools:** `{ step7: ["supabase"], step9: ["web-search-prime"], step10: ["web-search-prime"] }`

**Description:**
As a developer, I need to integrate payment gateway for processing transactions.

**Acceptance Criteria:**
- Integrate Stripe SDK for payments
- Create payment intent API endpoint
- Create webhook handler for payment status
- Add error handling for failed payments
- Typecheck passes
```

### Output JSON PRD

```json
{
  "project": "Payment Processing",
  "branchName": "flow/payment-processing",
  "description": "Payment processing feature for e-commerce with multiple payment methods",

  "relatedPRDs": [
    {
      "prd": "prd-auth.json",
      "type": "depends_on",
      "status": "complete",
      "reason": "Payments require authenticated users",
      "integration": "user sessions, role-based access control"
    },
    {
      "prd": "prd-products.json",
      "type": "depends_on",
      "status": "complete",
      "reason": "Payments process product purchases",
      "integration": "product pricing, inventory validation"
    },
    {
      "prd": "prd-orders.json",
      "type": "depended_by",
      "status": "incomplete",
      "reason": "Orders will need payment processing",
      "integration": "payment status, transaction history"
    }
  ],

  "consolidatedMemory": "",

  "lessonsLearned": "# Lessons Learned from Existing Features\n\n## Tech Stack\n- Framework: Next.js 14 provides excellent developer experience\n- Database: Supabase offers PostgreSQL + real-time + auth in one service\n- State: React Query eliminates most loading state boilerplate\n\n## Architecture\n- Feature-based architecture prevents merge conflicts\n- src/features/ for feature code, src/shared/ for reusable code\n- No cross-feature imports - use shared/ instead\n\n## Integration\n- Always generate types before implementing features\n- Zero 'any' types policy catches bugs early\n- Supabase real-time requires careful subscription management\n\n## Common Patterns\n- All API calls go through feature-specific api/ directories\n- Centralized error handling in @shared/api/errors",

  "userStories": [
    {
      "id": "US-001",
      "title": "Setup payment database schema",
      "description": "As a developer, I need to create payment database tables.",
      "acceptanceCriteria": [
        "Create payments table with id, amount, status, method",
        "Create payment_methods table with id, type, is_active",
        "Add foreign key to users table (from auth)",
        "Generate and run migration successfully",
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
      "title": "Integrate payment gateway API",
      "description": "As a developer, I need to integrate payment gateway for processing transactions.",
      "acceptanceCriteria": [
        "Integrate Stripe SDK for payments",
        "Create payment intent API endpoint",
        "Create webhook handler for payment status",
        "Add error handling for failed payments",
        "Typecheck passes"
      ],
      "mavenSteps": [7, 9, 10],
      "mcpTools": {
        "step7": ["supabase"],
        "step9": ["web-search-prime"],
        "step10": ["web-search-prime"]
      },
      "priority": 2,
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

**FIRST - Before assigning MCPs:**
- [ ] **Scanned for available MCP servers** in the environment
- [ ] **Verified which MCPs actually exist** before assigning them
- [ ] **Asked user if unsure** what MCPs are configured

**THEN - PRD validation:**
- [ ] **Previous run archived** (if docs/prd-[feature-name].json exists)
- [ ] **Scanned existing PRDs** and loaded consolidated memories
- [ ] **Analyzed feature relationships** and built relatedPRDs array
- [ ] **Extracted lessons learned** from consolidated memories
- [ ] Each story is completable in one iteration
- [ ] Stories are ordered by dependency (schema to backend to UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser" as criterion
- [ ] **Every story has mavenSteps array** specifying required Maven steps
- [ ] **Every story has mcpTools object** (even if empty `{}`)
- [ ] **mcpTools uses step-based keys** (step1, step7, etc.)
- [ ] **mcpTools only lists ACTUALLY AVAILABLE MCP names** (not guessed)
- [ ] **mcpTools only lists MCP names** (e.g., "supabase"), not individual tools
- [ ] **relatedPRDs array populated** with relationship metadata (not empty)
- [ ] **lessonsLearned field populated** with context from existing features
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Created `docs/` folder if it didn't exist
- [ ] Extracted feature name from PRD title (kebab-case)
- [ ] Saved to `docs/prd-[feature-name].json`
- [ ] Created `docs/progress-[feature-name].txt`

---

## STEP 8: Display Summary

```
==============================================================================
PRD Conversion Complete
==============================================================================

Input: docs/prd-[feature].md

Output: docs/prd-[feature].json

Memory Context Loaded:
- Existing PRDs Scanned: [number]
- Complete PRDs Found: [number]
- Consolidated Memories Loaded: [number]
- Story Memories Available: [number]

Feature Relationships:
- Depends On: [features that must exist first]
- Will Be Used By: [features that depend on this]
- Integration Points: [key integration details]

MCP Validation:
- Available MCPs: [list of available MCPs]
- Assigned MCPs: [MCPs assigned to stories]

Lessons Applied:
- Architecture Patterns: [patterns followed]
- Integration Patterns: [integration approaches]
- Key Lessons: [lessons applied from existing features]

Total Stories: [number]
Next Steps:
1. Review the JSON PRD: cat docs/prd-[feature].json
2. Edit if needed: nano docs/prd-[feature].json
3. Start development: flow start
==============================================================================
```

---

## EXECUTE NOW

**DO NOT ASK QUESTIONS. DO NOT REQUEST INPUT. EXECUTE STEPS. CREATE FILE. EXIT.**
