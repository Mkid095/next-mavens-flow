# ADR-001: Story-Level MCP Tool Assignment

**Status:** Accepted

**Date:** 2025-01-11

**Last Updated:** 2025-01-11 (Simplified structure)

## Context

When implementing Maven Flow, we faced a critical decision about how to assign MCP (Model Context Protocol) tools to specialist agents:

**Problem:**
- If MCP tools are assigned at the PRD level, all stories inherit the same tools
- As context grows large during flow execution, agents may "forget" which tools are available
- Agents may hallucinate tool availability or use inappropriate tools
- Lack of granular control leads to confusion and errors

**Observed Issues:**
- Agents struggling to identify available tools in large contexts
- Inconsistent tool usage across stories
- Difficulty debugging which tools should be used for specific tasks

## Decision

**MCP tools are assigned PER STORY PER STEP in the PRD JSON's `mcpTools` object, NOT at the PRD level.**

Each story specifies which MCPs to use for each Maven step:

```json
{
  "id": "US-001",
  "title": "Add status field to tasks table",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "web-search-prime"]
  }
}
```

**Key Principles:**
1. **Story-level specificity**: Each story lists its exact MCP requirements
2. **Step-level granularity**: Different steps may use different MCPs
3. **Simple declaration**: Only list MCP names (e.g., "supabase"), not individual tools
4. **Agent auto-discovery**: Agents automatically discover available tools from those MCPs

**Important:** You only specify the MCP **name**, not individual tools. The agent will automatically discover and use the available tools from that MCP.

## Consequences

**Benefits:**
- **Context Isolation**: Each story has its own specific MCPs, reducing confusion as context grows
- **Precision**: Flow command tells agents exactly which MCPs to use for each step
- **No Hallucination**: Prevents agents from "forgetting" which MCPs are available in large contexts
- **Granular Control**: Different stories and steps can use different MCPs
- **Debuggability**: Easy to see which MCPs are available for each story/step
- **Simplicity**: No need to list individual tools - just MCP names

**Trade-offs:**
- **Manual specification**: PRD creators must specify MCPs for each story
- **Larger PRD files**: Each story includes MCP configuration

## Alternatives Considered

### Alternative 1: PRD-Level MCP Assignment
**Description:** Assign MCPs once at the PRD level, all stories inherit them.

**Rejected because:**
- Causes context overload as all stories share the same MCP list
- Agents may use inappropriate MCPs for specific tasks
- No granular control per story or step

### Alternative 2: Individual Tool Listing
**Description:** List individual tools within each MCP (e.g., `{ "mcp": "supabase", "tools": ["supabase_query", "supabase_exec"] }`).

**Rejected because:**
- Over-complicated structure
- Agents automatically discover tools from MCPs anyway
- More prone to errors when MCP tools change

### Alternative 3: Automatic MCP Discovery
**Description:** Automatically discover available MCP tools using `claude mcp list` during flow execution.

**Rejected because:**
- Creates architecture confusion
- Agents may hallucinate tool availability in large contexts
- Unpredictable behavior as MCP configuration changes

## Implementation

**PRD JSON Structure:**
```json
{
  "project": "Project Name",
  "branchName": "flow/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want feature so that benefit",
      "acceptanceCriteria": ["Criterion 1", "Typecheck passes"],
      "mavenSteps": [1, 7],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase", "web-search-prime"]
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Flow Processing:**
1. Read story's `mavenSteps` array (e.g., [1, 7])
2. For each step, read story's `mcpTools` for that step (e.g., `mcpTools.step1`)
3. Spawn specialist agent and tell them: "Use these MCPs: supabase"
4. Agent checks if those MCPs are in their available tools
5. Agent uses those MCPs (or falls back to standard tools if unavailable)

**Maven Step to Agent Mapping:**
| Maven Step | Agent |
|------------|-------|
| 1, 2, 7, 9 | development-agent |
| 3, 4, 6 | refactor-agent |
| 5 | quality-agent |
| 8, 10 | security-agent |
| 11 | design-agent (optional, for mobile) |

## References

- `.claude/shared/mcp-tools.md` - MCP tools reference documentation
- `.claude/skills/flow-convert/SKILL.md` - PRD conversion instructions
- `.claude/commands/flow.md` - Flow command documentation
