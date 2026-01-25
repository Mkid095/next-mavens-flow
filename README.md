# Maven Flow

**Memory-Driven Autonomous AI Development System for Claude Code CLI**

Maven Flow is a comprehensive development system that implements PRD stories using a 10-step workflow with specialist agents. Its unique **memory ecosystem** ensures that each new feature learns from previous work, creating an intelligent codebase that accumulates knowledge over time.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [System Architecture](#system-architecture)
4. [Memory Ecosystem](#memory-ecosystem)
5. [Complete Workflow](#complete-workflow)
6. [Commands Reference](#commands-reference)
7. [Terminal Scripts](#terminal-scripts)
8. [Maven 10-Step Workflow](#maven-10-step-workflow)
9. [Specialist Agents](#specialist-agents)
10. [Feature-Based Architecture](#feature-based-architecture)
11. [Quality Hooks](#quality-hooks)
12. [Installation](#installation)
13. [Troubleshooting](#troubleshooting)

---

## Overview

Maven Flow combines powerful concepts for autonomous development:

| Concept | Description |
|---------|-------------|
| **Multi-PRD Architecture** | Each feature has its own PRD file, processed independently |
| **PRD-Driven Iteration** | Works through user stories one at a time with clean context |
| **Maven 10-Step Workflow** | Comprehensive quality assurance via specialized agents |
| **Memory Ecosystem** | New features learn from existing implementations |
| **Claude Code Native** | Built for Claude Code CLI architecture |

### Key Benefits

- **Intelligent Context Loading**: Agents receive context from related features
- **Feature Relationship Tracking**: Automatic dependency detection and validation
- **Accumulated Knowledge**: Each story creates memory, consolidated at PRD completion
- **Zero-Tolerance Quality**: Automated hooks enforce standards (no 'any' types, no gradients)
- **Multi-Feature Coordination**: Process multiple PRDs in dependency order

---

## Quick Start

```bash
# 1. Create a PRD (memory-aware - loads existing context)
flow-prd create "I want a payment processing system"

# 2. Convert to JSON (analyzes relationships, validates MCPs)
flow-convert payments

# 3. Start autonomous development (loads related memories)
flow start

# 4. Check progress
flow status
```

**What happens:**
1. **flow-prd** scans existing PRDs, loads consolidated memories, identifies relationships
2. **flow-convert** validates MCPs, tags related features, extracts lessons learned
3. **flow start** loads related PRD memories + previous story memories before spawning agents

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE LAYER                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Terminal Commands                                    Claude Code Commands   │
│  ─────────────────                                    ────────────────────   │
│  flow start              ──executes──→  /flow start                          │
│  flow status             ──executes──→  /flow status                         │
│  flow-prd create "...""  ──executes──→  /flow-prd "..."                      │
│  flow-convert auth       ──calls skill→  flow-convert docs/prd-auth.md       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BASH WRAPPER LAYER (thin)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  bin/flow.sh          bin/flow-prd.sh          bin/flow-convert.sh           │
│  ───────────          ───────────────          ─────────────────            │
│  • Parse arguments     • Parse arguments        • Parse arguments            │
│  • Invoke Claude       • Invoke Claude          • Invoke skill               │
│                                                                              │
│  NOTE: Bash does NOT do AI work. Bash ONLY:                                 │
│        - Parse CLI arguments                                                 │
│        - Find file paths                                                     │
│        - Invoke Claude Code commands/skills                                  │
│        - Display output to user                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CLAUDE CODE COMMAND/SKILL LAYER                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  .claude/commands/              .claude/skills/                              │
│  ─────────────────              ──────────────                               │
│  flow.md                        flow-convert/SKILL.md                        │
│  flow-prd.md                                                                │
│  consolidate-memory.md                                                   ┌───┤
│  create-story-memory.md                                                 │   │
│                                                                       AGENTS│
│  NOTE: These are TEXT FILES containing                                  ────┤
│        instructions that Claude Code EXECUTES.                          │   │
│        Claude Code READS these files and                                │   │
│        FOLLOWS the instructions.                                         │   │
│                                                                          │   │
│  This is where ALL AI work happens:                                     │   │
│  - Memory loading                                                        │   │
│  - Feature relationship analysis                                        │   │
│  - Context building                                                      │   │
│  - Agent spawning coordination                                          │   │
└──────────────────────────────────────────────────────────────────────────┴───┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SPECIALIST AGENTS LAYER                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  @development-agent    @refactor-agent    @quality-agent   @security-agent  │
│  ─────────────────    ────────────────    ─────────────   ───────────────  │
│  • Foundation          • Restructure       • Type safety    • Auth flow      │
│  • Data layer          • Modularize        • Import aliases  • RLS policies  │
│  • MCP integration     • UI centralization • Zero 'any'     • Error handling │
│                                                                              │
│  @design-agent         @testing-agent      @mobile-app-agent                  │
│  ─────────────         ────────────────    ─────────────────                  │
│  • Mobile UI/UX        • Browser testing   • Mobile screens                   │
│  • Professional design • Console errors    • Offline support                  │
│                                                                              │
│  NOTE: Agents are Claude Code subagents.                                     │
│        Main Claude spawns them using @agent-name syntax.                     │
│        Each agent has ISOLATED context window.                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AUTOMATED HOOKS LAYER                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  .claude/hooks/                                                               │
│  ─────────────                                                               │
│  post-tool-use-quality.sh       stop-comprehensive-check.sh                  │
│  ────────────────────────────   ──────────────────────────────               │
│  • Runs after EVERY tool use    • Runs before story completion              │
│  • Checks for 'any' types       • Validates entire codebase                  │
│  • Checks for gradients         • Generates fix tasks if needed              │
│  • Auto-fixes import paths                                                        │
│                                                                              │
│  NOTE: Hooks are AUTOMATIC. Claude Code runs them after tool use.           │
│        Hooks are bash scripts that Claude Code INVOKES.                      │
│        Hooks do NOT coordinate - they only check quality.                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Who Does What?

| Layer | Technology | Responsibility |
|-------|-----------|----------------|
| **User Interface** | Terminal | User types commands |
| **Bash Wrappers** | Shell scripts | Parse arguments, invoke Claude Code |
| **Claude Code (Main)** | Claude Code CLI | Read instructions, do AI work, coordinate agents |
| **Specialist Agents** | Claude Code subagents | Perform specific tasks (dev, refactor, quality, etc.) |
| **Hooks** | Bash scripts | Automatic quality checks |

---

## Memory Ecosystem

### Memory Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MEMORY FLOW CYCLE                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    Existing PRDs          ──load──>   flow-prd                              │
│    (prd-*.json)                            │                                │
│         │                                  │                                │
│         │                                  │                                │
│         └──────────────load────────────────┘                                │
│                    │                                                        │
│                    ▼                                                        │
│  Consolidated Memories  ──load──>  flow-convert                             │
│  (consolidated-*.txt)                    │                                 │
│         │                                   │                              │
│         │                                   │                              │
│         └────────────load───────────────────┘                              │
│                    │                                                        │
│                    ▼                                                        │
│  Story Memories        ──load──>  flow.md (execution)                       │
│  (story-US-*.txt)                       │                                  │
│         │                                 │                                  │
│         │                                 │                                  │
│         └─────────────feed────────────────┘                                  │
│                      │                                                       │
│                      ▼                                                       │
│              New Implementation                                              │
│                      │                                                       │
│                      ▼                                                       │
│              Create Story Memory                                             │
│                      │                                                       │
│                      ▼                                                       │
│              Consolidate (when all done)                                     │
│                      │                                                       │
│                      └─────feeds back to Existing PRDs ─────┘                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Three Memory Layers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MEMORY LAYER ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ LAYER 1: Story Memory (Per Story)                                   │    │
│  │ ────────────────────────────────────────────────────────────────────│    │
│  │ File: docs/[feature]/story-US-[###]-[title].txt                     │    │
│  │                                                                      │    │
│  │ Contents:                                                            │    │
│  │ • What was implemented (files, components, functions)                │    │
│  │ • Key decisions made (architecture, design patterns)                 │    │
│  │ • Challenges resolved (problems and solutions)                       │    │
│  │ • Integration points (connections to other features)                 │    │
│  │ • Lessons learned (important takeaways)                              │    │
│  │                                                                      │    │
│  │ Created: After each story completes                                  │    │
│  │ Used by: Next stories in same PRD                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ LAYER 2: Consolidated Memory (Per PRD)                              │    │
│  │ ────────────────────────────────────────────────────────────────────│    │
│  │ File: docs/consolidated-[feature].txt                               │    │
│  │                                                                      │    │
│  │ Contents (aggressively summarized to ~15K tokens):                   │    │
│  │ • System overview (brief description)                                │    │
│  │ • Architecture decisions (tech stack, patterns)                      │    │
│  │ • Public interfaces (API endpoints, components)                      │    │
│  │ • Integration patterns (how this connects to other PRDs)             │    │
│  │ • Related PRDs (dependencies)                                        │    │
│  │                                                                      │    │
│  │ Created: When ALL stories in PRD complete                            │    │
│  │ Used by: New PRDs that depend on this feature                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ LAYER 3: Cross-PRD Context (During Execution)                       │    │
│  │ ────────────────────────────────────────────────────────────────────│    │
│  │ Not a file - assembled dynamically during story execution:           │    │
│  │                                                                      │    │
│  │ Contents:                                                            │    │
│  │ • Related PRD summaries (~3-5K tokens per related PRD)               │    │
│  │ • Previous story summaries (~10K tokens total)                        │    │
│  │ • Current story requirements                                          │    │
│  │                                                                      │    │
│  │ Assembled: By flow.md before spawning agents                         │    │
│  │ Used by: Specialist agents during implementation                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Folder Structure

```
docs/
├── authentication/                    # Story memories folder (auto-created)
│   ├── story-US-001-login.txt        # Story: User login
│   ├── story-US-002-signup.txt       # Story: User signup
│   └── story-US-003-reset-password.txt # Story: Password reset
├── prd-authentication.md              # Human-readable PRD (from flow-prd)
├── prd-authentication.json            # Machine-readable PRD (from flow-convert)
└── consolidated-authentication.txt    # Consolidated memory (when PRD complete)
```

---

## Complete Workflow

### Phase 1: Create PRD (Memory-Aware)

```bash
flow-prd create "I want a payment processing system"
```

**What happens internally:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Create PRD (/flow-prd)                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  INPUT: User message describing feature                                      │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 1: Determine Input Source                                        │    │
│  │ • Check if plan.md exists                                            │    │
│  │ • If yes: Use plan.md                                                │    │
│  │ • If no: Extract features from user message                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 2.5: LOAD EXISTING CONTEXT (MEMORY AWARENESS)                   │    │
│  │                                                                      │    │
│  │ 2.5.1: Scan for Existing PRDs                                       │    │
│  │   find docs -name "prd-*.json"                                       │    │
│  │   → prd-auth.json, prd-products.json, prd-orders.json               │    │
│  │                                                                      │    │
│  │ 2.5.2: Load Consolidated Memories                                    │    │
│  │   For each complete PRD:                                             │    │
│  │   - Architecture Patterns (tech stack, structure)                    │    │
│  │   - Key Decisions                                                    │    │
│  │   - Lessons Learned                                                  │    │
│  │                                                                      │    │
│  │   Example from prd-auth.json:                                        │    │
│  │   - Tech: Next.js 14, Supabase, React Query                          │    │
│  │   - Pattern: Feature-based architecture                              │    │
│  │   - Lesson: Always generate types first                              │    │
│  │                                                                      │    │
│  │ 2.5.3: Load Story Memories                                           │    │
│  │   find docs -name "story-*.txt"                                      │    │
│  │   For each story:                                                    │    │
│  │   - Development process insights                                     │    │
│  │   - Tech stack learnings                                             │    │
│  │   - Architecture insights                                            │    │
│  │   - Integration challenges and solutions                             │    │
│  │                                                                      │    │
│  │ 2.5.4: Extract Integration Points                                    │    │
│  │   - Authentication: Supabase Auth with role-based access             │    │
│  │   - Database: Supabase (PostgreSQL) with RLS                         │    │
│  │   - API: REST endpoints in /api/*                                    │    │
│  │   - State: React Query + Zustand                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 2.6: ANALYZE FEATURE RELATIONSHIPS                             │    │
│  │                                                                      │    │
│  │ For the new feature:                                                  │    │
│  │ 1. Does it depend on existing?                                       │    │
│  │    - Need authentication? → depends_on prd-auth.json                 │    │
│  │    - Need product data? → depends_on prd-products.json               │    │
│  │                                                                      │    │
│  │ 2. Will existing depend on new?                                      │    │
│  │    - Orders need payments? → depended_by prd-orders.json             │    │
│  │                                                                      │    │
│  │ Build RELATIONSHIPS map:                                             │    │
│  │ {                                                                    │    │
│  │   prd-auth.json: {                                                   │    │
│  │     type: "depends_on",                                              │    │
│  │     reason: "Payments require authenticated users",                   │    │
│  │     integration: "user sessions, role-based access"                   │    │
│  │   }                                                                  │    │
│  │ }                                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  OUTPUT: docs/prd-[feature].md                                            │
│          - Context from existing features                                  │
│          - Related features (depends_on, depended_by)                      │
│          - User stories with mavenSteps                                    │
│                                                                              │
│  AUTO-RUN: flow-convert docs/prd-[feature].md                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase 2: Convert PRD (Analyze Relationships)

```bash
flow-convert payments
```

**What happens internally:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Convert PRD (flow-convert)                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  INPUT: docs/prd-[feature].md (from Phase 1)                                │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 2: SCAN EXISTING JSON PRDs                                      │    │
│  │                                                                      │    │
│  │ find docs -name "prd-*.json"                                         │    │
│  │ → Build FEATURE_MAP with status, relatedPRDs, consolidatedMemory     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 3: LOAD CONSOLIDATED MEMORIES                                   │    │
│  │                                                                      │    │
│  │ From complete PRDs:                                                   │    │
│  │ - Architecture Decisions (tech_stack, structure, patterns)            │    │
│  │ - Integration Patterns (auth, database, api, state)                   │    │
│  │ - Lessons Learned (what worked, what didn't)                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 4: ANALYZE FEATURE RELATIONSHIPS                               │    │
│  │                                                                      │    │
│  │ 4.1: Extract from markdown PRD                                       │    │
│  │ 4.2: Cross-reference with existing JSON PRDs                          │    │
│  │ 4.3: Build relatedPRDs array with metadata                           │    │
│  │ 4.4: Handle edge cases (missing PRDs, circular deps)                  │    │
│  │                                                                      │    │
│  │ relatedPRDs: [                                                        │    │
│  │   {                                                                  │    │
│  │     prd: "prd-auth.json",                                            │    │
│  │     type: "depends_on",                                              │    │
│  │     status: "complete",                                              │    │
│  │     reason: "Payments require authenticated users",                   │    │
│  │     integration: "user sessions, role-based access"                   │    │
│  │   }                                                                  │    │
│  │ ]                                                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 5: VALIDATE MCP AVAILABILITY                                    │    │
│  │                                                                      │    │
│  • Check which MCPs are configured in Claude Code                        │    │
│  • Only assign available MCPs to stories                                 │    │
│  • Leave mcpTools empty {} if uncertain                                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ STEP 6: BUILD LESSONS LEARNED                                        │    │
│  │                                                                      │    │
│  │ Extract from consolidated memories:                                  │    │
│  │ - Tech stack decisions                                                │    │
│  │ - Architecture patterns                                               │    │
│  │ - Integration lessons                                                 │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  OUTPUT: docs/prd-[feature].json                                          │
│          - relatedPRDs: [] (relationship metadata)                         │
│          - lessonsLearned: "" (from existing features)                     │
│          - consolidatedMemory: "" (empty initially)                         │
│          - userStories: [] (with mavenSteps, mcpTools, priority)           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase 3: Execute Flow (With Memory Loading)

```bash
flow start
```

**What happens internally:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Execute Flow (/flow start)                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ PREREQUISITES CHECK                                                  │    │
│  │ • docs/ directory exists                                              │    │
│  │ • PRD files exist (docs/prd-*.json)                                  │    │
│  │ • At least one incomplete story                                       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ SCAN PHASE                                                           │    │
│  │ • Scan docs/ for all prd-*.json files                                │    │
│  │ • Check completion status (all stories passes: true?)                │    │
│  │ • Pick first incomplete PRD (alphabetically)                          │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ FOR EACH INCOMPLETE STORY:                                           │    │
│  │                                                                      │    │
│  │ ════════════════════════════════════════════════════════════════   │    │
│  │ MEMORY LOADING PHASE (CRITICAL!)                                     │    │
│  │ ════════════════════════════════════════════════════════════════   │    │
│  │                                                                      │    │
│  │ Step 1: Read PRD's relatedPRDs array                                 │    │
│  │   cat docs/prd-[feature].json | jq '.relatedPRDs'                   │    │
│  │                                                                      │    │
│  │ Step 2: Load consolidated memory from related PRDs                    │    │
│  │   For each related PRD:                                              │    │
│  │   - Read docs/consolidated-[feature].txt                             │    │
│  │   - Extract: Architecture, Integration, Lessons                      │    │
│  │   - Summarize: ~3-5K tokens per PRD                                  │    │
│  │                                                                      │    │
│  │ Step 3: Load previous story memories from same PRD                    │    │
│  │   find docs/[feature]/story-*.txt                                    │    │
│  │   For each story memory:                                             │    │
│  │   - Extract: Implemented, Decisions, Challenges, Lessons             │    │
│  │   - Total budget: ~10K tokens                                        │    │
│  │                                                                      │    │
│  │ Step 4: Build story session with context structure                    │    │
│  │   CONTEXT = {                                                         │    │
│  │     relatedPRDs: { architecture, integration, lessons },              │    │
│  │     previousStories: { implemented, decisions },                     │    │
│  │     currentStory: { description, acceptanceCriteria }                 │    │
│  │   }                                                                  │    │
│  │                                                                      │    │
│  │ ════════════════════════════════════════════════════════════════   │    │
│  ════════════════════════════════════════════════════════════════════   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ IMPLEMENTATION PHASE                                                 │    │
│  │                                                                      │    │
│  │ For each mavenStep:                                                  │    │
│  │   1. Determine which agent to spawn:                                 │    │
│  │      Steps 1,2,7,9 → @development-agent                               │    │
│  │      Steps 3,4,6 → @refactor-agent                                    │    │
│  │      Step 5 → @quality-agent                                          │    │
│  │      Steps 8,10 → @security-agent                                     │    │
│  │      Step 11 → @design-agent                                          │    │
│  │                                                                      │    │
│  │   2. Build agent prompt with FULL CONTEXT:                            │    │
│  │      @development-agent                                               │    │
│  │                                                                      │    │
│  │      ## CONTEXT FROM RELATED FEATURES:                                │    │
│  │      ### Authentication (prd-auth.json):                             │    │
│  │      - Auth: Supabase Auth with RLS                                  │    │
│  │      - User ID: auth.getUser()                                        │    │
│  │                                                                      │    │
│  │      ### Products (prd-products.json):                               │    │
│  │      - API: /api/products/*                                          │    │
│  │                                                                      │    │
│  │      ## CONTEXT FROM PREVIOUS STORIES:                                │    │
│  │      ### US-001: Database schema                                      │    │
│  │      - Table: tasks (id, title, status)                               │    │
│  │                                                                      │    │
│  │      ## YOUR TASK:                                                   │    │
│  │      [Detailed requirements from PRD]                                 │    │
│  │                                                                      │    │
│  │   3. Spawn agent and wait for completion                              │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ QUALITY CHECKS                                                       │    │
│  │ • pnpm run typecheck                                                 │    │
│  │ • Verify no 'any' types, gradients, emojis                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ MEMORY CREATION PHASE (MANDATORY)                                    │    │
│  │                                                                      │    │
│  │ 1. Create: docs/[feature]/story-US-[###]-[title].txt                │    │
│  │    Contents: Implemented, Decisions, Integration, Lessons             │    │
│  │                                                                      │    │
│  │ 2. Update PRD: passes: true for story                                │    │
│  │                                                                      │    │
│  │ 3. Commit: git commit -m "feat: [US-XXX] [title]"                    │    │
│  │                                                                      │    │
│  │ 4. Output: <STORY_COMPLETE> signal                                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│  ═════════════════════════════════════════════════════════════════════════   │
│                        Move to next story                                   │
│  ═════════════════════════════════════════════════════════════════════════   │
│                              │                                               │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ CONSOLIDATION PHASE (when ALL stories complete)                      │    │
│  │                                                                      │    │
│  │ 1. Read all story memory files                                       │    │
│  │ 2. Consolidate into docs/consolidated-[feature].txt                  │    │
│  │ 3. Target: ~15K tokens (aggressive summarization)                    │    │
│  │ 4. Output: <ALL_COMPLETE> signal                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                              │                                               │
│                              ▼                                               │
│                    Continue to next incomplete PRD                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Commands Reference

### `/flow start [max-iterations]`

Starts autonomous flow execution.

```bash
/flow start          # Default 10 iterations
/flow start 20       # Custom iteration limit
/flow start 1        # Process exactly 1 story then stop
```

**What happens:**
1. Validates prerequisites (docs/, PRD files, incomplete stories)
2. Scans for all PRD files in `docs/`
3. Identifies incomplete stories (`passes: false`)
4. For each story:
   - **MEMORY LOADING PHASE**: Loads related PRD memories + previous story memories
   - **IMPLEMENTATION PHASE**: Spawns specialist agents for each mavenStep
   - **QUALITY CHECKS**: Runs typecheck and lint
   - **MEMORY CREATION PHASE**: Creates story memory file
   - Commits changes with standardized format
   - Marks story as complete in PRD
5. Continues until max iterations or all PRDs complete

### `/flow status`

Shows current progress across all PRDs.

```bash
/flow status
```

**Example output:**
```
Maven Flow Status: 3 PRD files found

prd-task-priority.json (3/5 complete)
  ✓ US-001: Add priority field to database
  ✓ US-002: Display priority indicator
  ✓ US-003: Add priority selector
  ○ US-004: Filter tasks by priority (priority: 4)
  ○ US-005: Add priority sorting (priority: 5)

prd-user-auth.json (0/4 complete)
  ○ US-001: Firebase authentication setup
  ○ US-002: Supabase profile storage
  ○ US-003: Login form UI
  ○ US-004: Password reset flow

prd-notifications.json (4/4 complete) ✅

Current focus: prd-task-priority.json

Recent progress:
  [2026-01-25] prd-task-priority.json - US-003 Added priority dropdown
  Agents: refactor-agent, quality-agent
```

### `/flow continue [prd-name] [max-iterations]`

Resumes flow execution from where it left off.

```bash
/flow continue           # Continue with current PRD
/flow continue 5         # Continue with 5 more iterations
/flow continue auth 10   # Continue specific PRD
```

### `/flow reset [prd-name]`

Archives current PRD run and resets for fresh start.

```bash
/flow reset           # Prompts to select PRD
/flow reset auth      # Reset specific PRD
```

**What happens:**
- Creates archive: `archive/YYYY-MM-DD-[feature-name]/`
- Moves current PRD and progress file to archive
- Resets all stories to `passes: false`
- Creates fresh PRD and progress files
- Prompts for confirmation before archiving

### `/flow test [prd-name]`

Runs comprehensive testing of implemented features.

```bash
/flow test                    # Test current PRD (auto-detects)
/flow test authentication     # Test authentication PRD
/flow test task-priority      # Test task-priority PRD
```

**What happens:**
1. Reads PRD to find completed stories
2. Starts dev server: `pnpm dev`
3. Opens application using chrome-devtools MCP
4. Tests user signup/login with standard test user
5. Tests each completed feature's acceptance criteria
6. Checks console for errors
7. Creates error log at `docs/errors-[feature-name].md`

**Test User Credentials:**
- Email: `revccnt@gmail.com`
- Password: `Elishiba!90`

### `/flow consolidate [prd-name]`

Fixes errors found during testing (without re-implementing features).

```bash
/flow consolidate            # Consolidate current PRD
/flow consolidate auth       # Consolidate authentication PRD
```

**What happens:**
1. Reads error log from `docs/errors-[feature-name].md`
2. Identifies which stories/steps have errors
3. Re-runs ONLY the affected steps (not entire stories)
4. Fixes specific errors found during testing

### `/flow help`

Displays comprehensive help information.

---

## Terminal Scripts

Maven Flow includes terminal forwarder scripts in the `bin/` directory.

### Available Scripts

| Script | Description | Usage Example |
|--------|-------------|---------------|
| `flow.sh` / `flow.ps1` / `flow.bat` | Main Maven Flow orchestrator | `flow start 10` |
| `flow-prd.sh` / `flow-prd.ps1` / `flow-prd.bat` | PRD creator | `flow-prd create authentication` |
| `flow-convert.sh` / `flow-convert.ps1` / `flow-convert.bat` | PRD to JSON converter | `flow-convert authentication` |

### Installation

**Option 1: Global Installation (Recommended)**
```bash
# Linux/macOS
./bin/flow-install-global.sh
source ~/.bashrc  # or restart your terminal

# Windows - Add bin/ folder to your PATH manually
```

**Option 2: Local Installation**
```bash
# Use scripts directly from bin/ folder
./bin/flow.sh start 10
./bin/flow-prd.sh create authentication
./bin/flow-convert.sh authentication
```

### Usage Examples

**Start autonomous development:**
```bash
flow start              # Start with default 10 iterations
flow start 20           # Start with 20 iterations
flow status             # Check progress
flow continue           # Resume from last iteration
flow reset auth         # Reset specific PRD
```

**Create and convert PRDs:**
```bash
# Create a new PRD (markdown)
flow-prd create user authentication system with login and signup

# Convert to JSON format
flow-convert authentication

# Start development
flow start
```

### Terminal vs Claude Code Commands

The terminal scripts are simple forwarders - they just pass your input to Claude Code:

| Terminal Command | Claude Code Command |
|------------------|-------------------|
| `flow start 10` | `/flow start 10` |
| `flow status` | `/flow status` |
| `flow-prd create auth` | `/flow-prd create auth` |
| `flow-convert auth` | `flow-convert auth` |

All the actual work (agent coordination, memory management, context building) is handled by Claude Code commands, not the terminal scripts.

---

## Maven 10-Step Workflow

| Step | Agent | Color | Description |
|------|-------|-------|-------------|
| **1** | development-agent | 🟢 Green | Foundation - Import UI with mock data or create from scratch |
| **2** | development-agent | 🟢 Green | Package Manager - Convert npm → pnpm |
| **3** | refactor-agent | 🔵 Blue | Feature Structure - Restructure to feature-based folders |
| **4** | refactor-agent | 🔵 Blue | Modularization - Split components >300 lines |
| **5** | quality-agent | 🟣 Purple | Type Safety - No 'any' types, @ aliases |
| **6** | refactor-agent | 🔵 Blue | UI Centralization - Move to @shared/ui |
| **7** | development-agent | 🟢 Green | Data Layer - Backend setup, Supabase integration |
| **8** | security-agent | 🔴 Red | Auth Integration - Firebase + Supabase auth |
| **9** | development-agent | 🟢 Green | MCP Integration - Connect MCP tools |
| **10** | security-agent | 🔴 Red | Security & Error Handling |
| **11** | design-agent | 🩷 Pink | Mobile Design - Professional UI (optional) |

### Step to Agent Mapping

```
┌─────────────────────────────────────────────────────────────┐
│  Story Maven Steps → Agent Assignment                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Steps 1, 2, 7, 9  →  @development-agent                    │
│  ─────────────────────────────────────────                   │
│  • Foundation (UI import or create from scratch)             │
│  • Package Manager (npm → pnpm)                              │
│  • Data Layer (backend setup, Supabase)                      │
│  • MCP Integration (connect external tools)                  │
│                                                              │
│  Steps 3, 4, 6    →  @refactor-agent                        │
│  ─────────────────────────────────────────                   │
│  • Feature Structure (feature-based folders)                 │
│  • Modularization (split large components)                   │
│  • UI Centralization (move to @shared/ui)                    │
│                                                              │
│  Step 5           →  @quality-agent                          │
│  ─────────────────────────────────────────                   │
│  • Type Safety (no 'any' types, @ aliases)                   │
│                                                              │
│  Steps 8, 10     →  @security-agent                         │
│  ─────────────────────────────────────────                   │
│  • Auth Integration (Firebase + Supabase)                    │
│  • Security & Error Handling                                 │
│                                                              │
│  Step 11          →  @design-agent (optional)                │
│  ─────────────────────────────────────────                   │
│  • Mobile Design (professional UI for Expo/React Native)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Specialist Agents

### development-agent (🟢 Green)

**Use for:** Steps 1, 2, 7, 9

**Responsibilities:**
- Import UI with mock data or create from scratch
- Convert package manager (npm → pnpm)
- Set up data layer (Supabase, API clients)
- Integrate MCP tools
- Set up project foundation

**Key actions:**
- Creates base components with mock data
- Installs and configures Supabase client
- Sets up API middleware
- Connects MCP tools (web-search, web-reader, browser)
- Commits with prefix `feat:`

### refactor-agent (🔵 Blue)

**Use for:** Steps 3, 4, 6

**Responsibilities:**
- Restructure to feature-based architecture
- Modularize large components
- Centralize UI components to @shared/ui

**Key actions:**
- Moves code to feature-based folders
- Splits components >300 lines
- Extracts reusable UI components
- Enforces architecture rules
- Commits with prefix `refactor:`

### quality-agent (🟣 Purple)

**Use for:** Step 5

**Responsibilities:**
- Type safety enforcement
- Import alias verification
- Quality standards compliance

**Key actions:**
- Removes ALL 'any' types (zero tolerance)
- Converts relative imports to @ aliases
- Verifies component sizes
- Blocks on quality violations
- Auto-fixes import paths
- Commits with prefix `fix:`

**BLOCKING Issues:**
- 'any' types in code
- Gradients in CSS
- Emojis in UI components
- Relative imports

### security-agent (🔴 Red)

**Use for:** Steps 8, 10

**Responsibilities:**
- Authentication flow implementation
- Security vulnerability checks
- Error handling setup

**Key actions:**
- Firebase Auth integration
- Supabase Row-Level Security (RLS)
- JWT validation
- Input sanitization
- Error boundary implementation
- Commits with prefix `security:`

### design-agent (🩷 Pink)

**Use for:** Step 11 (optional, mobile apps only)

**Responsibilities:**
- Professional mobile UI/UX design
- Apple design methodology application

**Key actions:**
- Applies professional visual design
- Implements proper navigation patterns
- Ensures touch targets (44x44pt minimum)
- Validates in Expo preview
- Commits with prefix `design:`

### testing-agent (🟠 Orange)

**Use for:** `/flow test` command (not part of mavenSteps)

**Responsibilities:**
- Comprehensive application testing
- Error logging and reporting
- Browser automation with chrome-devtools MCP

**Key actions:**
- Opens application using chrome-devtools MCP
- Tests all completed stories (where `passes: true`)
- Tests signup/login with standard test user
- Checks console for errors (logs ALL errors found)
- Tests each acceptance criterion
- Creates error log at `docs/errors-[feature-name].md`

**Required MCP:** chrome-devtools (REQUIRED)

**Test Credentials:**
- Email: `revccnt@gmail.com`
- Password: `Elishiba!90`

### mobile-app-agent (🔵 Cyan)

**Use for:** Mobile development (React Native + Expo apps)

**Responsibilities:**
- Mobile screen implementation with Expo Router
- Offline-first data management with TanStack Query
- Native UI patterns (swipe, pull-to-refresh, bottom sheets)
- NativeWind styling (Tailwind for React Native)

**Tech Stack:**
- Frontend: React Native + Expo
- Navigation: Expo Router
- Styling: NativeWind (Tailwind)
- State: TanStack Query + Zustand
- Auth: Firebase Authentication
- Backend: Supabase (shared with web)
- Push: Firebase Cloud Messaging

---

## Feature-Based Architecture

Maven Flow enforces a strict feature-based structure for all new code:

```
src/
├── app/                    # Entry points, routing
├── features/               # Isolated feature modules
│   ├── auth/              # Cannot import from other features
│   │   ├── api/           # API calls
│   │   ├── components/    # Feature components
│   │   ├── hooks/         # Custom hooks
│   │   ├── types/         # TypeScript types
│   │   └── index.ts       # Public exports
│   ├── dashboard/
│   └── [feature-name]/
├── shared/                # Shared code (no feature imports)
│   ├── ui/                # Reusable components
│   ├── api/               # Backend clients (Firebase, Supabase)
│   └── utils/             # Utilities
└── [type: "app"]
```

### Architecture Rules

| From | Can Import To |
|------|---------------|
| features/ | shared/, features/[same feature] |
| shared/ | shared/ only |
| app/ | features/, shared/ |

**Import Aliases (no relative imports):**
- `@shared/*` → `src/shared/*`
- `@features/*` → `src/features/*`
- `@app/*` → `src/app/*`
- `@/*` → `src/*`

### Why Feature-Based Architecture?

| Benefit | Description |
|---------|-------------|
| **Isolation** | Features can't accidentally depend on each other |
| **Merge Safety** | Multiple developers can work on different features |
| **Clear Boundaries** | ESLint enforces boundaries at compile time |
| **Easy Deletion** | Delete a feature folder, nothing breaks |
| **Testability** | Features can be tested independently |

---

## Quality Hooks

Maven Flow includes automated hooks that enforce quality standards during development.

### PostToolUse Hook

**File:** `.claude/hooks/post-tool-use-quality.sh`

**Runs:** After every Write/Edit operation

```bash
Checks:
  ✅ Relative imports      → Auto-fix to @ aliases
  ✅ 'any' types           → Should use proper types
  ✅ Gradients             → Should use solid colors
  ✅ File size >300 lines  → Needs modularization
  ✅ Direct API calls      → Should use data layer
  ✅ UI duplication        → Should use @shared/ui
  ✅ Exposed secrets       → Security risk
  ✅ Auth file changes     → Security review needed
```

### Stop Hook

**File:** `.claude/hooks/stop-comprehensive-check.sh`

**Runs:** Before completing work

```bash
Checks:
  ✅ Large components (>300 lines)
  ✅ Type safety ('any' count)
  ✅ Import path violations
  ✅ Feature boundary violations (ESLint)
  ✅ UI component duplication
  ✅ Security scan (secrets, tokens, passwords)

Output:
  ✅ PASS    → Ready to commit
  ⚠️  WARN   → Manual review needed
  ❌ BLOCK   → Spawn agents to fix
```

### Zero Tolerance Rules

The following violations will BLOCK commits:

1. **'any' Types - ZERO TOLERANCE**
   - No `: any`, `: any[]`, `<any>`, `Promise<any>`
   - Use proper interfaces or `unknown` with type guards

2. **Gradients in CSS - ZERO TOLERANCE**
   - No `linear-gradient`, `radial-gradient`, `conic-gradient`
   - Use solid professional colors only

3. **Emojis in UI - ZERO TOLERANCE**
   - No emojis anywhere in UI components
   - Use professional icon libraries (lucide-react, heroicons)

4. **Relative Imports**
   - No `import { Foo } from './foo'` or `../bar`
   - Use `@/` aliases for all imports

---

## Installation

### Quick Install (Simplified Scripts)

Use the simplified installation scripts for easy setup:

**Linux/macOS (Bash):**
```bash
# Global installation (available for all projects) - default
./install-simple.sh global

# Local installation (for current project)
./install-simple.sh local
```

**Windows (PowerShell):**
```powershell
# Global installation
.\install-simple.ps1 global

# Local installation
.\install-simple.ps1 local
```

**Windows (CMD):**
```batch
# Global installation
install-simple.bat global

# Local installation
install-simple.bat local
```

### Configuration

#### ESLint Boundaries

Copy `maven-flow/config/eslint.config.mjs` to your project root to enable feature-based architecture enforcement.

#### Settings

The hooks are configured in `.claude/maven-flow/.claude/settings.json`. Ensure the paths match your project structure.

---

## Troubleshooting

### Flow not starting?

**Check:**
- At least one `docs/prd-*.json` file exists
- PRD JSON is valid
- Run `/flow status` for diagnostics

### Iteration failing?

**Check:**
- That PRD's `docs/progress-[feature-name].txt` for error messages
- Git log: `git log --oneline -10`
- Resume with `/flow continue`

### Wrong PRD being processed?

**Check:**
- Use `/flow status` to see all PRDs and their status
- Use `/flow continue [prd-name]` to specify which PRD to work on

### Quality hooks not running?

**Check:**
- `.claude/maven-flow/.claude/settings.json` is configured
- Hooks are executable: `chmod +x .claude/maven-flow/hooks/*.sh`
- Bash is available on your system

### Need to restart a PRD?

```bash
/flow reset [prd-name]
```

Previous runs are preserved in `archive/YYYY-MM-DD-[feature-name]/`. Other PRDs remain unaffected.

---

## File Structure

```
maven-flow/                              # Distribution directory
├── .claude/
│   └── settings.json                   # Hook configurations
├── agents/
│   └── [agent definitions]             # Specialist agents
├── commands/
│   └── flow.md                         # /flow slash command
├── skills/
│   ├── flow-prd/SKILL.md               # PRD creation skill
│   └── flow-convert/SKILL.md           # PRD conversion skill
├── hooks/
│   ├── post-tool-use-quality.sh        # Real-time quality
│   └── stop-comprehensive-check.sh    # Pre-completion check
├── config/
│   └── eslint.config.mjs               # Feature boundaries
├── bin/                                # Terminal scripts
│   ├── flow.sh / flow.ps1 / flow.bat
│   ├── flow-prd.sh / flow-prd.ps1 / flow-prd.bat
│   └── flow-convert.sh / flow-convert.ps1 / flow-convert.bat
└── README.md                           # This file

# After Installation

.claude/
├── maven-flow/                         # Maven Flow system
│   ├── hooks/                          # Quality enforcement hooks
│   ├── config/                         # ESLint configuration
│   └── .claude/settings.json           # Hook settings
├── skills/                             # Skills in official location
│   ├── flow-prd/SKILL.md               # PRD creation skill
│   └── flow-convert/SKILL.md           # PRD conversion skill
├── agents/                             # Global agents location
│   └── [agent definitions]             # Specialist agents
└── commands/                           # Global commands location
    └── flow.md                         # /flow command
```

---

## Contributing

Maven Flow is designed to be extensible. To add custom agents or steps:

1. Create new agent file in `.claude/agents/`
2. Add unique color in frontmatter
3. Set `model: inherit` and appropriate `permissionMode`
4. Update `.claude/commands/flow.md` to include new agent in coordination
5. Update this README with new agent details

---

## License

Maven Flow is part of the autonomous AI development pattern implementation.

---

**Maven Flow: Memory-Driven Autonomous AI Development with Multi-PRD Support and Comprehensive Quality Assurance Powered by Claude Code CLI**
