# MCP Tools Reference for Maven Flow Agents

This document provides comprehensive reference for all MCP tools available to Maven Flow specialist agents. Each agent file contains a concise summary; see this file for detailed usage instructions.

---

## 1. Supabase MCP (Database Operations)

**Available to:** development-agent, security-agent (when specified in PRD story's `availableMcpTools`)

**Use for:**
- Creating tables
- Adding columns
- Running migrations
- Querying data
- Setting up relationships
- Verifying RLS (Row Level Security) policies
- Checking database permissions

**Before using Supabase MCP:**
1. **CONFIRM the Supabase project ID** - Check environment files, config files
2. **NEVER assume** - Always verify the project ID before operations
3. **Common locations:** `.env.local`, `.env`, `supabase/config.toml`, `src/lib/supabase.ts`

```bash
# Check for project ID first
grep -r "SUPABASE_PROJECT_ID" .env* src/lib/ 2>/dev/null
grep -r "supabase" . --include="*.ts" --include="*.js" --include="*.tsx" | head -5

# If not found, ASK THE USER for the Supabase project URL/ID
```

---

## 2. Chrome DevTools (Web Application Testing)

**Available to:** All agents (for web app testing)

**Use for:**
- React/Next.js/Vue web app testing
- Debugging UI issues
- Checking console errors
- Inspecting network requests
- Testing auth flows
- Checking token storage

**How to use:**
1. Start the dev server (e.g., `pnpm dev`)
2. Open Chrome browser
3. Navigate to `http://localhost:3000` (or appropriate port)
4. Open Chrome DevTools (F12 or Right-click → Inspect)
5. Test the functionality
6. Check Console tab for errors
7. Check Network tab for API calls
8. Verify DOM elements in Elements tab
9. Check Application tab for token storage (security testing)
10. Test auth flows (login, logout, session management)

---

## 3. Web Search Prime (Research)

**Available to:** All agents

**Use for:**
- Research best practices
- Find documentation for libraries
- Look up error messages
- Check for updated APIs
- Verify implementation approaches
- Security research (OWASP, vulnerabilities)
- Design pattern research

**When to use:**
```
❌ DON'T GUESS: "I think this might work like..."
✅ DO RESEARCH: Use web-search-prime to find the correct approach

Examples:
- "How do I use Supabase MCP with TypeScript?"
- "Best practices for ESLint configuration in Next.js 15"
- "Error: 'Cannot find module @shared/ui'"
- "OWASP best practices for authentication in 2025"
- "Supabase RLS policies security guide"
```

---

## 4. Web Reader (Documentation Reading)

**Available to:** All agents

**Use for:**
- Reading documentation pages
- Extracting code examples from docs
- Parsing API references
- Security documentation
- Design guidelines

---

## Story-Level MCP Assignment

**CRITICAL:** MCP tools are assigned PER STORY in the PRD JSON's `availableMcpTools` object, not at the PRD level.

Example story configuration:
```json
{
  "id": "US-001",
  "mavenSteps": [1, 7],
  "availableMcpTools": {
    "development-agent": [
      { "mcp": "supabase", "tools": ["supabase_query", "supabase_exec"] },
      { "mcp": "web-search-prime", "tools": ["webSearchPrime"] }
    ]
  }
}
```

When processing a story:
1. Check the story's `availableMcpTools` object
2. Use ONLY the MCP tools listed for your agent type
3. If no MCP tools are listed for your agent, do not use any

---

## MCP Tool Pattern Reference

| Tool Pattern | Use For Steps | Example Tools | Primary Agents |
|-------------|---------------|---------------|----------------|
| supabase_* | 7, 8, 10 | supabase_query, supabase_exec | development, security |
| postgres_*, mysql_*, mongo_* | 7, 8, 10 | Database operations | development, security |
| web_search_*, search_* | All steps | Research, documentation | All agents |
| web_reader_*, fetch_* | All steps | Reading web content | All agents |
| chrome_*, browser_*, puppeteer_* | Testing | Browser automation | All agents |
| vercel_*, wrangler_*, cloudflare_* | 9 | Deployment | development |
| figma_*, design_* | 11 | UI/UX design | design |

---

## Checking Available MCPs

```bash
# List all configured MCP servers
claude mcp list

# Get detailed info about a specific MCP server
claude mcp get <server-name>
```
