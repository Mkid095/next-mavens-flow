# MCP Tools Reference for Maven Flow Agents

This document provides reference for MCP tools used in Maven Flow.

---

## How MCP Assignment Works

**Simple and direct:**

1. **PRD specifies MCPs per step:**
   ```json
   {
     "id": "US-001",
     "mavenSteps": [1, 7],
     "mcpTools": {
       "step1": ["supabase"],
       "step7": ["supabase", "web-search-prime"]
     }
   }
   ```

2. **Flow tells agent:** "Use these MCPs: supabase"

3. **Agent:** Uses the MCP tools they have available

**Important:** You only specify the MCP **name**, not individual tools. The agent will automatically discover and use the available tools from that MCP.

---

## Common MCPs

| MCP Name | Use For | Examples |
|----------|---------|----------|
| supabase | Database operations | Query tables, create schemas, run migrations |
| web-search-prime | Research | Find documentation, look up errors |
| web-reader | Read web pages | Parse docs, extract examples |
| chrome-devtools | Browser testing | Test web apps, check console |
| playwright | Browser automation | Automated browser testing |
| vercel | Deployment | Deploy to Vercel |
| wrangler | Deployment | Deploy to Cloudflare |
| figma | Design | Design-to-code workflow |

---

## Supabase MCP

**When told to use the "supabase" MCP server:**

The supabase MCP provides direct access to your Supabase project for database operations.

**What you can do with supabase MCP:**
- **Database Operations:** List tables, query data, execute SQL, apply migrations
- **Schema Management:** Create/modify tables, add columns, set up relationships
- **Type Generation:** Auto-generate TypeScript types from your database schema
- **Project Configuration:** Get API keys, URLs, and project details
- **Branching:** Test schema changes in isolated database branches
- **Edge Functions:** List, deploy, and manage edge functions
- **Monitoring:** View logs and get performance recommendations

**IMPORTANT:**
- Always use the MCP to verify the actual database state
- Don't read type files or migration files - they may be outdated
- Query the database directly to verify tables, columns, and data

---

## For Agents

**When you're told to use an MCP:**

1. Check if that MCP is in your available tools
2. If yes → use it
3. If no → use standard tools (Read, Write, Bash, etc.)

**Example:**
```
Task: "Use these MCPs: supabase"

Agent:
✓ Looks for supabase MCP tools
✓ Uses them to query the table
✓ Reports results
```

---

## PRD Configuration

**In your PRD JSON, specify MCPs per step:**

```json
{
  "userStories": [
    {
      "id": "US-001",
      "title": "Create products table",
      "mavenSteps": [1, 7],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase", "web-search-prime"]
      }
    }
  ]
}
```

**Key points:**
- `mcpTools` is optional (omit if no MCPs needed)
- Specify step-by-step which MCPs to use
- Only list MCP **names** (e.g., "supabase"), not individual tools
- Agent will automatically discover and use available tools from those MCPs
