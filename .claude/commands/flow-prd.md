---
description: Create a Product Requirements Document (PRD) for Maven Flow features
argument-hint: create [feature description...]
---

# Maven Flow PRD Generator

Create comprehensive Product Requirements Documents (PRDs) for features to be implemented by Maven Flow.

## Step 0: Determine Working Directory (CRITICAL - Do This First!)

Before creating any files, you MUST determine the user's current working directory:

1. **Use Bash tool to run:** `pwd` - this returns the current working directory
2. **The working directory is where the user invoked `/flow-prd` from**
3. **Create ALL files relative to this working directory**
4. **The docs folder path will be:** `[working-directory]/docs/`

**Example:**
- User runs: `/flow-prd create authentication` from `C:\Users\HomePC\Documents\GitHub\my-project`
- Working directory: `C:\Users\HomePC\Documents\GitHub\my-project`
- Create files at: `C:\Users\HomePC\Documents\GitHub\my-project\docs\prd-authentication.md`

**DO NOT create files in:**
- The command installation directory
- Any `.claude` subdirectory
- Any bin/ directory

**ALWAYS create files in:** `[working-directory]/docs/`

## Step 1: Create PRD First, Then Consolidated Memory

1. **Create the PRD markdown file** as normal
2. **Extract feature name** from the PRD you just created (from the project name in the PRD)
3. **Create the consolidated memory file:** `docs/consolidated-[feature].txt`

This order ensures the consolidated memory file can be created based on the actual PRD content.

**Process:**
1. Create PRD file: `docs/prd-[feature].md` with full content
2. Read the PRD to extract:
   - Feature name (from project title)
   - Description
   - Overview
3. Create consolidated memory stub: `docs/consolidated-[feature].txt` with:
   - `totalStories: 0`
   - `completedStories: 0`
   - `status: initialized`
   - Filled with content from the PRD

**Initial consolidated memory stub format:**
```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: [Feature Name from PRD]
consolidatedDate: [Current Date]
totalStories: [Count from PRD]
completedStories: 0
status: initialized
---

# [Feature Name] - Consolidated Implementation Memory

## System Overview
[Copy from PRD overview section]

## Current Status
PRD created but no stories completed yet.

## Key Architectural Decisions
[Copy key decisions from PRD if any]

## Public Interfaces
[From PRD technical requirements if present]

## Integration Patterns
[From PRD dependencies if present]

## Related PRDs
[From flow-convert relatedPRDs or empty if none]

## Consolidated From Stories
No stories completed yet. Listed below from PRD:
[List all user story titles from PRD]
```

**Example:**
- User runs: `/flow-prd create authentication`
- Working directory: `/home/user/projects/my-app`
- Step 1: Create `docs/prd-authentication.md`
- Step 2: Extract "authentication" from PRD
- Step 3: Create `docs/consolidated-authentication.txt`

This ensures the consolidated memory reflects the actual PRD content from the start.

## Commands

### Create PRD
```
/flow-prd create [feature description]
```

Creates a detailed PRD with user stories, acceptance criteria, and MCP assignments.

**What happens:**
1. Detects available MCPs by checking current environment
2. Analyzes feature description for requirements
3. Identifies related PRDs (existing features this depends on or relates to)
4. Creates `docs/prd-[feature-name].md` with:
   - Project metadata (name, branch, available MCPs)
   - User stories with acceptance criteria
   - Maven step assignments
   - MCP tool assignments per step
   - Priority ordering

**Example usage:**
```
/flow-prd create authentication system with login signup and password reset
```

**Creates:** `docs/prd-authentication.md`

### Convert PRD to JSON
```
/flow-prd convert [feature-name]
```

Converts an existing markdown PRD to JSON format for Maven Flow processing.

**What happens:**
1. Reads `docs/prd-[feature-name].md`
2. Parses frontmatter and stories
3. Intelligently detects related PRDs
4. Creates `docs/prd-[feature-name].json` with:
   - Boolean `passes` fields (true/false)
   - `relatedPRDs` array with paths to related PRD JSONs
   - `consolidatedMemory` path (points to THIS PRD's own memory file)
   - Proper `mcpTools` mapping per step

**Example usage:**
```
/flow-prd convert authentication
```

**Creates:** `docs/prd-authentication.json`

### Help
```
/flow-prd help
```

Displays help information about PRD creation.

---

## PRD Format

### Markdown Structure

The markdown PRD format includes:

**Frontmatter:**
```yaml
---
project: Authentication System
branch: flow/authentication
availableMCPs:
  - supabase
  - web-search-prime
  - chrome-devtools
  - web-reader
---
```

**Story Format:**
```markdown
### US-001: User login
**Priority:** 1
**Maven Steps:** [1, 7, 10]
**MCP Tools:**
- step1: [supabase]
- step7: [supabase]
- step10: []

As a user, I want to log in with email and password so that I can access my account.

**Acceptance Criteria:**
- Create users table with id, email, password_hash
- Add login UI with email/password fields
- Implement server action for authentication
- Add session management
- Typecheck passes

**Status:** false (informational - will be true when complete)
```

### JSON Structure

After conversion, the JSON PRD includes:

```json
{
  "schemaVersion": 1,
  "project": "Authentication System",
  "branchName": "flow/authentication",
  "description": "Complete user authentication...",
  "availableMCPs": ["supabase", "web-search-prime"],
  "consolidatedMemory": "docs/consolidated-authentication.txt",
  "relatedPRDs": [],
  "userStories": [
    {
      "id": "US-001",
      "title": "User login",
      "description": "As a user, I want to log in...",
      "acceptanceCriteria": ["Create users table...", ...],
      "mavenSteps": [1, 7, 10],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase"],
        "step10": []
      },
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Key Fields:**
- `passes`: Boolean (true/false) - authoritative status for story completion
- `consolidatedMemory`: Path to THIS PRD's OWN consolidated memory
- `relatedPRDs`: Array of OTHER PRD JSON files this PRD depends on
- `availableMCPs`: Detected from environment during PRD creation

---

## Memory System Architecture

### Story-Level Memory

Each story gets a permanent memory file: `docs/[feature]/story-US-[###]-[title].txt`

```markdown
---
memoryVersion: 1
schemaVersion: 1
storyId: US-001
storyTitle: User Login
feature: Authentication System
completedDate: 2025-01-18
agents: development-agent, security-agent
---

# Story US-001: User Login

## Implemented
- Created users table with id, email, password_hash columns
- Built login UI with email/password fields and validation
- Implemented authenticate() server action
- Added session management with cookies

## Database Decisions
- Users table in Supabase with RLS policies
- Password hashing using bcrypt (cost factor 10)
- Session tokens stored in supabase_auth.sessions (Supabase managed)

## UI/UX Patterns
- Login form uses centralized Form component
- Error messages display inline below fields
- Success redirects to /dashboard

## Integration Points
- Authentication state managed via React Context (AuthContext)
- Server actions in src/actions/auth.ts
- Session validation middleware for protected routes

## Lessons Learned
- Always use Supabase MCP for database operations
- Test authentication flow with real credentials
- RLS policies must be applied before testing

## Commit
feat: add user login with email/password authentication
```

### Consolidated Memory (PRD-Level)

After ALL stories complete, consolidates into `docs/consolidated-[feature].txt` (~15K tokens max)

**Consolidation Rules:**
- Summarize AGGRESSIVELY - focus on patterns, decisions, interfaces
- AVOID repeating step-by-step details from story files
- Target ~15K tokens maximum
- Story files remain detailed source; consolidation is for cross-PRD context

```markdown
---
memoryVersion: 1
schemaVersion: 1
feature: Authentication System
consolidatedDate: 2025-01-18
totalStories: 5
---

# Authentication System - Consolidated Implementation Memory

## System Overview
Complete user authentication supporting login, signup, password reset, and session management.

## Key Architectural Decisions

### Database
- **Supabase as single source of truth** - Always use MCP for queries
- **users table**: id, email, password_hash, created_at, updated_at
- **RLS**: Authenticated users read/write own data only

### Authentication Flow
1. Email/password → authenticate() action
2. Session token → HTTP-only cookie
3. Protected routes → middleware validation
4. Logout → clear cookie + Supabase session

## Public Interfaces

### Server Actions (`src/actions/auth.ts`)
```typescript
authenticate(email, password) → { success, error, data }
register(email, password) → { success, error, data }
requestPasswordReset(email) → { success, error }
resetPassword(token, newPassword) → { success, error }
logout() → { success }
```

## Integration Patterns

### For New Features Requiring Auth
1. Wrap with `AuthContext` provider
2. Check `user` state before allowing access
3. Use `authenticate()` for credential validation
4. Apply RLS policies to new tables with `user_id` FK

## Related PRDs
- **Dashboard PRD**: Requires auth, loads this memory

## Consolidated From Stories
US-001: User login | US-002: User signup | US-003: Password reset | US-004: Session management | US-005: Logout
```

---

## Cross-PRD Memory Loading

When Dashboard PRD depends on Authentication PRD:

1. **Load related consolidated memory**: `docs/consolidated-authentication.txt` (~15K tokens)
2. **Pre-analyze and summarize**: Agent creates focused summary (~3-5K tokens)
3. **Inject into story context**: Only relevant parts

**Total context budget:** ~35K tokens per story
- Main prompt: ~5K
- Previous stories in same PRD: ~10K
- Related PRD summaries: ~15K
- Buffer: ~5K

---

## Signal Format

### Story Complete Signal
```xml
<STORY_COMPLETE>
<story_id>US-001</story_id>
<story_title>User login</story_title>
<feature>Authentication System</feature>
<agents_used>development-agent, security-agent</agents_used>
<commit>feat: add user login with email/password authentication</commit>
<memory_file>docs/authentication/story-US-001-login.txt</memory_file>
</STORY_COMPLETE>
```

### All Complete Signal
```xml
<ALL_COMPLETE>
<feature>Authentication System</feature>
<total_stories>5</total_stories>
<completed_stories>5</completed_stories>
<consolidated_memory>docs/consolidated-authentication.txt</consolidated_memory>
</ALL_COMPLETE>
```

---

## Best Practices

1. **Keep stories small** - Max ~10 stories per PRD, each atomic and focused
2. **Order by dependency** - Schema → Backend → UI
3. **Specify MCPs clearly** - Each step should list required MCP tools
4. **Mark dependencies** - Use `relatedPRDs` to indicate feature dependencies
5. **Test acceptance criteria** - Each story should have verifiable criteria

---

## Troubleshooting

**No MCPs detected:**
- Check MCP servers are configured in Claude Code settings
- Verify MCP servers are running
- Restart Claude Code if needed

**Related PRDs not found:**
- Ensure related PRD JSON files exist in `docs/`
- Run `/flow-prd convert` on related PRDs first
- Check `relatedPRDs` array paths are correct

**Stories not progressing:**
- Check `docs/` directory exists
- Verify PRD JSON is valid
- Run `/flow status` for diagnostics

---

*Maven Flow PRD Generator - Create comprehensive requirements for autonomous AI development*
