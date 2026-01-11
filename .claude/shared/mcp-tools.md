# MCP Tools Reference for Maven Flow Agents

This document provides comprehensive reference for all MCP tools available to Maven Flow specialist agents. Each agent file contains a concise summary; see this file for detailed usage instructions.

---

## Dynamic MCP Discovery (CRITICAL)

**Maven Flow is designed to work with ANY MCP servers available on your system.**

### How MCP Discovery Works

1. **At runtime**, the flow command scans for available MCP servers using `claude mcp list`
2. **Agents receive** the list of available MCP servers dynamically
3. **Agents use** whatever MCP tools are available - no hardcoded expectations
4. **System works** even without any MCP servers (falls back to standard tools)

### Checking Your Available MCPs

```bash
# List all configured MCP servers
claude mcp list

# Get detailed info about a specific MCP server
claude mcp get <server-name>
```

---

## Common MCP Use Cases (Examples)

**Note:** These are examples of common MCP servers. Your system may have different MCPs available. The flow command will discover and use whatever MCPs you have configured.

### Database Operations
**Typical MCPs:** supabase, postgres, mysql, mongo, sqlite
**Use for:** Creating tables, querying data, running migrations
**When available:** Use MCP tools instead of writing raw SQL
**Fallback:** Use standard database clients or SQL files

### Web Research
**Typical MCPs:** web-search, web-reader, fetch, brave-search
**Use for:** Researching best practices, finding documentation, looking up errors
**When available:** Use MCP tools instead of guessing
**Fallback:** Use Read tool to check local docs, AskUserQuestion

### Browser Testing
**Typical MCPs:** chrome-devtools, browser, puppeteer, playwright
**Use for:** Testing web applications, debugging UI, checking console
**When available:** Use MCP tools for automated testing
**Fallback:** Manual browser testing instructions

### Deployment
**Typical MCPs:** vercel, wrangler, cloudflare, netlify
**Use for:** Deploying applications, managing deployments
**When available:** Use MCP tools for streamlined deployment
**Fallback:** Standard CLI commands (vercel CLI, wrangler CLI, etc.)

### Design
**Typical MCPs:** figma, design, canva
**Use for:** UI/UX design, design system integration
**When available:** Use MCP tools for design-to-code workflow
**Fallback:** Manual design implementation

---

## Working Without MCPs

**Maven Flow works perfectly without any MCP servers.** The system will:

1. **Use standard tools** (Read, Write, Edit, Bash, Grep, Glob)
2. **Ask for help** when needed (AskUserQuestion)
3. **Provide clear instructions** for manual steps
4. **Never require** a specific MCP to be present

---

## Story-Level MCP Assignment

**MCP configuration in PRD files is OPTIONAL and HINT-BASED.**

### When `availableMcpTools` is specified:

```json
{
  "id": "US-001",
  "mavenSteps": [1, 7],
  "availableMcpTools": {
    "development-agent": [
      { "mcp": "database" },
      { "mcp": "web-search" }
    ]
  }
}
```

This means:
- **If** these MCPs are available, prioritize them
- **If not available**, use alternative approaches (standard tools)
- **Never fail** just because a specific MCP isn't installed

### When `availableMcpTools` is NOT specified:

The flow command will:
1. Scan all available MCPs
2. Identify relevant tools based on the step requirements
3. Use whatever is available

---

## Agent Guidelines for MCP Usage

### When You ARE Spawned as an Agent:

1. **Check your available tool set** - See what MCP tools you have
2. **Use MCPs when helpful** - They can speed up your work
3. **Fall back gracefully** - If MCPs aren't available, use standard tools
4. **Never assume** - Don't write code that requires a specific MCP

### Example: Database Operations

**WITH Supabase MCP:**
```
1. Use Supabase MCP tools to query/create tables
2. Verify results
3. Done
```

**WITHOUT Supabase MCP:**
```
1. Read existing migration files to understand schema
2. Write new migration file
3. Use Bash to run migration: pnpm exec supabase db push
4. Verify results
```

Both approaches work - the system adapts to what's available.

---

## Step-to-MCP Mapping (Guidelines Only)

**Note:** These are general guidelines for when certain MCP types are helpful. The system will work with whatever MCPs you have.

| Maven Step | Helpful MCP Types | If Unavailable, Use |
|------------|-------------------|---------------------|
| 1 (Foundation) | design, browser | Manual design implementation |
| 2 (Package Manager) | None required | Standard CLI tools |
| 3 (Feature Structure) | None required | Read, Edit, Glob tools |
| 4 (Modularization) | None required | Read, Edit tools |
| 5 (Type Safety) | None required | TypeScript compiler |
| 6 (UI Centralization) | None required | Read, Edit, Glob tools |
| 7 (Data Layer) | database (supabase, postgres, etc.) | Migration files, SQL scripts |
| 8 (Auth) | database, firebase | SDK documentation, direct API calls |
| 9 (MCP Integration) | Whatever MCPs you have | Manual configuration |
| 10 (Security) | database (for RLS) | SQL migration files |
| 11 (Mobile Design) | design, figma | Manual design implementation |
