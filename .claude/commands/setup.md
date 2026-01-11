---
description: Auto-discover and map MCP tools to Maven workflow
argument-hint: scan | map | status
---

# Maven MCP Discovery

Auto-discovers configured MCP servers and maps their tools to Maven workflow steps.

## Commands

### Scan MCPs
```
/setup scan
```
Scans `~/.claude/settings.json` for configured MCP servers and discovers available tools.

### Map Tools
```
/setup map
```
Maps discovered MCP tools to Maven workflow steps based on tool patterns.

### Show Status
```
/setup status
```
Shows current MCP configuration and tool mappings.

## How It Works

### 1. MCP Discovery Phase

Uses `claude mcp list` to find configured MCP servers:

```bash
# Example output from claude mcp list
web-search-prime: https://api.z.ai/api/mcp/web_search_prime/mcp (HTTP) - ✓ Connected
web-reader: https://api.z.ai/api/mcp/web_reader/mcp (HTTP) - ✓ Connected
supabase: npx -y @supabase/mcp-server - ✓ Connected
```

For each MCP, the system:
1. Runs `claude mcp get <name>` to get detailed information
2. Identifies available tools from the current session (tools prefixed with `mcp__`)
3. Maps tool names to Maven workflow steps based on patterns

### 2. Tool Mapping Phase

Maps discovered tools to Maven workflow steps based on patterns:

| Tool Pattern | Maven Step | Agent |
|-------------|------------|-------|
| `supabase_*`, `postgres_*`, `database_*` | 7, 8, 10 | development, security |
| `web_search_*`, `search_*` | All | development-agent (research) |
| `web_reader_*`, `fetch_*` | All | development-agent (docs) |
| `chrome_*`, `browser_*`, `puppeteer_*` | UI testing | development-agent |
| `vercel_*`, `deploy_*` | 9 | development-agent (deployment) |
| `wrangler_*`, `cloudflare_*` | 9 | development-agent (deployment) |
| `figma_*`, `design_*` | 11 | design-agent |

### 3. Configuration Generation

Creates `docs/mcp-tools.json`:

```json
{
  "lastScanned": "2025-01-11T14:00:00Z",
  "configuredMCPs": {
    "supabase": {
      "status": "connected",
      "tools": ["supabase_query", "supabase_exec", "supabase_subscribe"],
      "mappedToSteps": [7, 8, 10],
      "agents": ["development-agent", "security-agent"]
    },
    "web-search-prime": {
      "status": "connected",
      "tools": ["webSearchPrime"],
      "mappedToSteps": "all",
      "agents": ["development-agent"]
    },
    "chrome": {
      "status": "not_configured"
    }
  },
  "agentToolAssignments": {
    "development-agent": {
      "mcpTools": [
        { "mcp": "supabase", "tools": ["supabase_query", "supabase_exec"] },
        { "mcp": "web-search-prime", "tools": ["webSearchPrime"] },
        { "mcp": "web-reader", "tools": ["webReader"] }
      ]
    },
    "security-agent": {
      "mcpTools": [
        { "mcp": "supabase", "tools": ["supabase_query", "supabase_subscribe"] }
      ]
    },
    "design-agent": {
      "mcpTools": []
    }
  }
}
```

### 4. Agent Configuration Update

Updates agent definitions to include discovered MCP tools:

```yaml
# Before (development-agent)
tools: Read, Write, Edit, Bash, Grep, Glob

# After (development-agent with MCP tools)
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__supabase__supabase_query, mcp__web_search_prime__webSearchPrime
```

## Example Session

```
/setup scan

Scanning for configured MCP servers using claude mcp list...

$ claude mcp list
web-search-prime: https://api.z.ai/api/mcp/web_search_prime/mcp (HTTP) - ✓ Connected
web-reader: https://api.z.ai/api/mcp/web_reader/mcp (HTTP) - ✓ Connected
supabase: npx -y @supabase/mcp-server - ✓ Connected

Configured MCPs: 3 found

Discovering available tools...

supabase:
  • supabase_query - Execute SQL queries
  • supabase_exec - Execute database commands
  • supabase_subscribe - Subscribe to realtime changes

web-search-prime:
  • webSearchPrime - Search the web

web-reader:
  • webReader - Fetch and read web content

Tools discovered: 5 total

Running /setup map...
```

```
/setup map

Mapping discovered tools to Maven workflow...

Pattern matches:
  • supabase_query → Steps 7, 8, 10 (database, auth, security)
  • supabase_exec → Steps 7, 8, 10 (database operations)
  • supabase_subscribe → Step 7 (realtime features)
  • webSearchPrime → All steps (web research)
  • webReader → All steps (documentation)

Generated docs/mcp-tools.json

Agent assignments:
  • development-agent: 5 MCP tools
  • security-agent: 3 MCP tools
  • refactor-agent: 0 MCP tools
  • quality-agent: 0 MCP tools
  • design-agent: 0 MCP tools

✅ Mapping complete!

Run /setup status to see the final configuration.
```

```
/setup status

MCP Configuration Status:

Configured MCPs: 3/4
  ✅ supabase - 3 tools available
  ✅ web-search-prime - 1 tool available
  ✅ web-reader - 1 tool available
  ⚠️  chrome - Not configured (optional for testing)

Tool Mapping:

Step 1 (Foundation) - development-agent:
  • webSearchPrime - Web research for dependencies

Step 7 (Data Layer) - development-agent:
  • supabase_query - Database operations
  • supabase_exec - Run migrations
  • supabase_subscribe - Realtime subscriptions
  • webReader - Fetch Supabase docs

Step 8 (Auth Integration) - security-agent:
  • supabase_query - Verify auth tables
  • webSearchPrime - Research auth best practices

Step 10 (Security) - security-agent:
  • supabase_query - Audit RLS policies
  • webSearchPrime - Security research

Agent Tool Assignments:
  development-agent: 5 MCP tools
  security-agent: 2 MCP tools
  refactor-agent: 0 MCP tools
  quality-agent: 0 MCP tools
  design-agent: 0 MCP tools

Ready to run /flow start!
```

## Tool Pattern Mappings

The system uses these patterns to map tools:

```javascript
const TOOL_PATTERNS = {
  database: {
    patterns: [/supabase/, /postgres/, /mysql/, /mongo/, /database/, /db_/],
    steps: [7, 8, 10],
    agents: ['development-agent', 'security-agent']
  },
  web_search: {
    patterns: [/web.*search/, /search/, /google/],
    steps: 'all',
    agents: ['development-agent']
  },
  web_reader: {
    patterns: [/web.*reader/, /fetch/, /reader/, /scrape/],
    steps: 'all',
    agents: ['development-agent']
  },
  browser: {
    patterns: [/chrome/, /browser/, /puppeteer/, /playwright/],
    steps: 'testing',
    agents: ['development-agent']
  },
  deployment: {
    patterns: [/vercel/, /deploy/, /netlify/, /wrangler/, /cloudflare/],
    steps: [9],
    agents: ['development-agent']
  },
  design: {
    patterns: [/figma/, /design/, /sketch/],
    steps: [11],
    agents: ['design-agent']
  }
};
```

## Benefits

- **Auto-discovery**: No manual MCP configuration needed
- **Dynamic mapping**: New MCPs are automatically integrated
- **Flexible**: Works with any MCP server
- **Transparent**: See exactly what tools are available and where they're used
- **No hardcoding**: System adapts to your MCP setup

## File Structure

```
docs/
├── mcp-tools.json          # Auto-generated tool mappings
├── prd-[feature].json      # PRD files (unchanged)
└── progress-[feature].txt  # Progress files (unchanged)
```

---

*Maven MCP Discovery: Automatically find and use your existing MCP tools*
