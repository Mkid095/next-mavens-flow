# ADR-004: Specialist Agent Coordination via Main Claude Context

**Status:** Accepted

**Date:** 2025-01-11

## Context

**Problem:**
- Maven Flow requires coordinating multiple specialist agents (development, refactor, quality, security, design)
- Each story may require different agents based on its `mavenSteps`
- Need to execute steps sequentially with proper state management

**Technical Limitation:**
From Claude Code CLI documentation:
> "The premise of this tool is to spin off a sub-agent that will have the same access to tools as your main agent (**except that it cannot spawn another sub-task**) and reports back the results."

**Observed Issues:**
- Subagents cannot spawn other subagents
- Need a coordination mechanism that respects this limitation
- Must ensure each step completes before starting the next

## Decision

**The `/flow` command (running in main Claude context) coordinates ALL specialist agent spawning directly.**

**Architecture:**
```
Main Claude (with /flow command loaded)
  │
  ├─→ Task tool → development-agent (Step 1) → Wait → Continue
  ├─→ Task tool → refactor-agent (Step 3) → Wait → Continue
  ├─→ Task tool → quality-agent (Step 5) → Wait → Continue
  ├─→ Task tool → refactor-agent (Step 6) → Wait → Continue
  └─→ Task tool → security-agent (Step 10) → Wait → Continue
```

**Key Principles:**
1. **Main context coordination**: /flow command runs in main Claude context
2. **Sequential execution**: Wait for each agent to complete before spawning next
3. **Direct spawning**: Main Claude spawns specialist agents via Task tool
4. **State management**: /flow maintains state between agent executions

## Consequences

**Benefits:**
- **Simple architecture**: Clear coordination logic in one place
- **Reliable execution**: Sequential execution prevents race conditions
- **Easy debugging**: Can see each step's result in order
- **No subagent chains**: Respects CLI limitation (subagents can't spawn subagents)

**Trade-offs:**
- **Long-lived flow**: Flow command must remain loaded throughout execution
- **No parallelism**: Steps must execute sequentially (can't parallelize independent steps)
- **Manual coordination**: /flow command contains all coordination logic

## Alternatives Considered

### Alternative 1: flow-iteration Subagent
**Description:** Use a flow-iteration subagent to coordinate specialist agents.

**Rejected because:**
- **Blocked by CLI limitation**: Subagents cannot spawn other subagents
- Adds unnecessary indirection
- More complex to debug

### Alternative 2: Parallel Execution
**Description:** Spawn multiple agents simultaneously for independent steps.

**Rejected because:**
- More complex coordination
- Potential race conditions
- Difficult to debug failures
- No clear benefit for Maven workflow (steps are typically sequential)

### Alternative 3: Event-Driven Coordination
**Description:** Use events to trigger agent spawns.

**Rejected because:**
- Over-engineering for this use case
- Requires additional infrastructure
- Harder to reason about execution order

## Implementation

**Maven Step to Agent Mapping:**

| Maven Step | Agent Type | Task subagent_type | Description |
|------------|------------|-------------------|-------------|
| 1 | Foundation | development-agent | Import UI with mock data or create from scratch |
| 2 | Package Manager | development-agent | Convert npm → pnpm |
| 3 | Feature Structure | refactor-agent | Restructure to feature-based folder structure |
| 4 | Modularization | refactor-agent | Modularize components >300 lines |
| 5 | Type Safety | quality-agent | Type safety - no 'any' types, @ aliases |
| 6 | UI Centralization | refactor-agent | Centralize UI components to @shared/ui |
| 7 | Data Layer | development-agent | Centralized data layer with backend setup |
| 8 | Auth Integration | security-agent | Firebase + Supabase authentication flow |
| 9 | MCP Integration | development-agent | MCP integrations |
| 10 | Security & Error Handling | security-agent | Security and error handling |
| 11 | Mobile Design | design-agent | Professional UI/UX for Expo/React Native (optional) |

**Story Processing Flow:**
```markdown
## Story: US-001 - Add status field to tasks table

**From PRD:**
- mavenSteps: [1, 7]
- mcpTools: { step1: ["supabase"], step7: ["supabase"] }

**Processing:**

1. [Step 1 - Foundation]
   Spawning development agent...
   Instruction: "Use these MCPs: supabase"
   *** CRITICAL: MCP TOOLS INSTRUCTION ***
   You MUST use the Supabase MCP tools for ALL database operations.
   DO NOT read migration files or create scripts.
   Query the database DIRECTLY using Supabase MCP tools.
   → [Waiting for completion]
   → [Agent completed successfully]

2. [Step 7 - Data Layer]
   Spawning development agent...
   Instruction: "Use these MCPs: supabase"
   *** CRITICAL: MCP TOOLS INSTRUCTION ***
   You MUST use the Supabase MCP tools for ALL database operations.
   → [Waiting for completion]
   → [Agent completed successfully]

3. Running quality checks...
   pnpm run typecheck → Passed

4. Committing changes...
   git commit → Committed

5. Updating PRD...
   Setting passes: true for US-001 → Updated

✅ Story US-001 complete
```

**Deprecated Files:**
- `.claude/agents/flow-iteration.md` - No longer used (subagent approach abandoned)
- `.claude/agents/prd-update.md` - No longer used (PRD updates handled by /flow directly)

## References

- `.claude/commands/flow.md` - Flow command implementation
- `.claude/agents/flow-iteration.md` - Deprecated subagent approach (kept for reference)
- `.claude/adrs/001-story-level-mcp-assignment.md` - Story-level MCP architecture
