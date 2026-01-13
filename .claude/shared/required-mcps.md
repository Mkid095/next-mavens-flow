# Required MCPs for Maven Flow Projects

This document specifies the **MANDATORY MCPs** that must be configured for Maven Flow projects to function correctly.

---

## Overview

Maven Flow requires certain MCP servers to be available for autonomous development and testing. These MCPs are NOT optional - they are core to the workflow.

---

## Mandatory MCPs

### 1. Supabase MCP (REQUIRED)

**Purpose:** Direct database access, schema verification, migrations, and type generation.

**Why it's mandatory:**
- Agents need to QUERY the actual database (not read files)
- Agents need to VERIFY tables and schema exist
- Agents need to CREATE tables and run migrations
- Agents need to GENERATE TypeScript types from live schema

**Without Supabase MCP:**
- Agents will fall back to reading migration files (doesn't verify actual database)
- Agents will create migration scripts manually (error-prone)
- Agents cannot verify what's actually in the database

**Setup Instructions:**
1. Install Supabase CLI: `npm install -g supabase`
2. Configure MCP in Claude Code settings with your Supabase project
3. Verify MCP is available: Check Claude Code MCP server list

**Used by these Maven Steps:**
- Step 1 (Foundation) - Create tables, verify schema
- Step 7 (Data Layer) - Set up database, migrations
- Step 8 (Auth) - Configure authentication
- Step 10 (Security) - Verify RLS policies

---

### 2. chrome-devtools MCP (REQUIRED)

**Purpose:** Live browser testing, console log reading, application verification.

**Why it's mandatory:**
- Testing-agent MUST open the application to test features
- Agents MUST read console logs to find errors
- Agents MUST verify UI works in real browser
- Agents MUST test user flows end-to-end

**Without chrome-devtools MCP:**
- Testing-agent cannot test the application
- Console errors go undetected
- Features cannot be verified in browser
- Testing becomes manual and incomplete

**Setup Instructions:**
1. Install chrome-devtools MCP in Claude Code
2. Configure with browser path (Chrome/Chromium)
3. Verify MCP can launch browser and navigate to pages

**Used by these Maven Steps:**
- Step 9 (MCP Integration) - Test browser automation
- Testing-agent - Complete application testing

---

## How to Verify MCPs Are Configured

**Before starting Maven Flow:**

1. **Check Claude Code MCP Settings:**
   - Open Claude Code Settings
   - Go to MCP Servers section
   - Verify "supabase" is in the list
   - Verify "chrome-devtools" is in the list

2. **Test MCPs are working:**
   - Start a conversation
   - Ask agent to list tables using Supabase MCP
   - Ask agent to open browser using chrome-devtools MCP

3. **If MCPs are missing:**
   - DO NOT start `/flow start`
   - Configure the missing MCP first
   - Restart Claude Code
   - Verify again

---

## MCP Enforcement in PRDs

**When creating PRD JSON files, always include these MCPs:**

```json
{
  "id": "US-001",
  "title": "Create users table",
  "mavenSteps": [1, 7],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase", "chrome-devtools"]
  }
}
```

**Rules:**
- **ALL database stories** MUST include `"supabase"` in mcpTools
- **ALL stories with UI/testing** MUST include `"chrome-devtools"` in mcpTools
- **Step 9 (MCP Integration)** should list both MCPs

---

## Optional MCPs (Recommended but Not Required)

These MCPs are useful but not mandatory:

| MCP Name | Purpose | When to Include |
|----------|---------|-----------------|
| web-search-prime | Research documentation | All steps |
| web-reader | Read web pages | All steps |
| playwright | Browser automation testing | Testing phases |
| wrangler | Cloudflare Workers deployment | Step 9 |
| vercel | Vercel deployment | Step 9 |
| figma | Design work | Step 11 (mobile) |

**Only include these MCPs if:**
- They are actually configured in your environment
- The story specifically needs them
- You've verified they're available

---

## Troubleshooting MCP Issues

### Supabase MCP Not Working

**Symptoms:**
- Agent says "Supabase MCP not available"
- Agent reads migration files instead of querying database
- Type files don't match actual database

**Solutions:**
1. Check Supabase project is linked in MCP settings
2. Verify project ID is correct
3. Check MCP server is running
4. Try restarting Claude Code

### chrome-devtools MCP Not Working

**Symptoms:**
- Testing-agent cannot open browser
- Agent says "browser automation not available"
- Console logs cannot be read

**Solutions:**
1. Verify browser path in MCP settings
2. Check Chrome/Chromium is installed
3. Test MCP manually: "Open browser to http://localhost:3000"
4. Restart Claude Code if needed

---

## Summary

**MANDATORY MCPs (Must Have):**
- ✅ supabase
- ✅ chrome-devtools

**OPTIONAL MCPs (Nice to Have):**
- web-search-prime
- web-reader
- playwright
- wrangler
- vercel
- figma

**Before running `/flow start`:**
1. Verify supabase MCP is configured
2. Verify chrome-devtools MCP is configured
3. Test both MCPs work correctly
4. Only then start the flow

**Remember:** Without these MCPs, Maven Flow cannot function as designed. Agents will fall back to less reliable methods (reading files instead of querying database, manual testing instead of automated browser testing).
