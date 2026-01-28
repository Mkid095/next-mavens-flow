---
description: Work on ONE story through Maven workflow - loads memory, spawns agents, marks complete
argument-hint: <prd-file> <story-id>
---

# Flow Work Story - Process ONE Story

**YOU MUST process exactly ONE story through the Maven 10-Step Workflow.**

This command is called by `flow.sh` for each iteration. You will:
1. Read the story from the PRD
2. Load memory from relatedPRDs and previous stories
3. Process each mavenStep by spawning the appropriate agent
4. Mark the story complete and commit

**CRITICAL:** Work in the current working directory (`$PWD`), NOT in the command installation directory.

---

## The Job

Process ONE user story through all its mavenSteps. Load context from memory. Spawn specialist agents. Mark complete when done.

**Arguments provided:**
- `$1` = PRD file path (e.g., `docs/prd-auth.json`)
- `$2` = Story ID (e.g., `US-001`)

---

## STEP 1: Read the Story Details

**Execute:** `cat "$1" | jq '.userStories[] | select(.id == "$2")'`

**Extract:**
- `title`: Story title
- `description`: Story description
- `acceptanceCriteria`: Array of criteria
- `mavenSteps`: Array of step numbers (e.g., `[1, 3, 5, 6, 10]`)
- `mcpTools`: Object mapping steps to MCP arrays

**Example output:**
```json
{
  "id": "US-001",
  "title": "User Login Component",
  "description": "Create login form with email/password",
  "acceptanceCriteria": ["Create users table", "Login UI", "Auth action", "Typecheck passes"],
  "mavenSteps": [1, 7, 10],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase"],
    "step10": []
  }
}
```

---

## STEP 2: MEMORY LOADING PHASE (CRITICAL)

**You MUST load memory before spawning any agents.**

### 2a. Load Related PRDs Consolidated Memory

**Execute:** `cat "$1" | jq '.relatedPRDs'`

For each PRD in `relatedPRDs`:

1. **Check if consolidated memory exists:**
   - Path: `docs/consolidated-[feature].md` (extract from PRD filename)

2. **If exists, read the memory:**
   - Execute: `cat docs/consolidated-[feature].md`

3. **Extract key information (~3K tokens max):**
   - Tech stack used
   - Architecture patterns
   - Integration points (APIs, database, authentication)
   - Public interfaces (endpoints, components)
   - Key lessons learned

**Build context summary:**
```
## CONTEXT FROM RELATED PRDs

### [Feature Name]
- Tech: [stack]
- Integration: [how it connects]
- Lessons: [key learnings]
```

### 2b. Load Previous Story Memories

**Execute:**
```bash
# Get feature name from PRD file
feature=$(basename "$1" .json | sed 's/prd-//')

# Find story memories
find docs/$feature/story-*.txt -type f 2>/dev/null | sort
```

For each story memory file:

1. **Read the memory:** `cat docs/$feature/story-*.txt`

2. **Extract key information:**
   - Story ID and title
   - What was implemented (files, components, functions)
   - Key decisions made
   - Challenges resolved
   - Integration points created
   - Lessons learned for future stories

**Build context summary:**
```
## CONTEXT FROM PREVIOUS STORIES IN THIS PRD

### [STORY-ID] - [Title]
- Implemented: [files, components]
- Decisions: [key choices]
- Integration: [connections to other features]
- Lessons: [what to remember]
```

---

## STEP 3: Process Each Maven Step

**For EACH step in `mavenSteps`:**

### 3a. Determine Agent Type

| Step | Agent | Purpose |
|------|-------|---------|
| 1, 2, 7, 9 | development-agent | Foundation, package manager, data layer, integration |
| 3, 4, 6 | refactor-agent | Structure, modularization, UI centralization |
| 5 | quality-agent | Type safety |
| 8, 10 | security-agent | Auth, error handling |
| 11 | design-agent | Mobile design (optional) |

### 3b. Get MCP Tools for This Step

**Execute:** `cat "$1" | jq ".userStories[] | select(.id == \"$2\") | .mcpTools.step[N]"`

Where N is the current step number.

### 3c. SPAWN THE AGENT

**Use this exact format:**

```
Use the [AGENT_TYPE] to work on Step [N] of Maven Workflow for story: [STORY-ID] - [TITLE]

PRD: $1
MCPs to use for this step: [from step N mcpTools]

## CONTEXT FROM RELATED PRDs:
[Paste the context summary from Step 2a]

## CONTEXT FROM PREVIOUS STORIES:
[Paste the context summary from Step 2b]

## Your Task (Step [N]):
[Paste the acceptance criteria for this step]

## Quality Standards (ZERO TOLERANCE):
- No 'any' types - use proper TypeScript
- No gradients - use solid professional colors
- No relative imports - use @/ aliases
- Components < 300 lines

## After Completion:
1. Run: pnpm run typecheck
2. If errors remain, fix them
3. Output: [STEP_COMPLETE] when done

Begin Step [N] now.
```

### 3d. Wait for Agent Completion

**Wait until you see:** `[STEP_COMPLETE]`

Then continue to the next step.

---

## STEP 4: Completion Steps (After All Steps Done)

### 4a. Run Typecheck

**Execute:** `pnpm run typecheck`

**Or:** `pnpm tsc`

### 4b. Update PRD - Mark Story Complete

**Execute:**
```bash
cat "$1" | jq "(.userStories[] | select(.id == \"$2\") | .passes) = true" > tmp.json && mv tmp.json "$1"
```

### 4c. Commit Changes

**Execute:**
```bash
git add -A
story_title=$(cat "$1" | jq -r ".userStories[] | select(.id == \"$2\") | .title")
git commit -m "feat: $2 - $story_title"
```

### 4d. Create Story Memory

**Execute:** Call the story memory creation
```
/create-story-memory "$1" "$2"
```

### 4e. Output Completion Marker

**Output exactly:**
```
<STORY_COMPLETE>
```

---

## Example Usage

When `flow.sh` calls:

```bash
claude "/flow-work-story docs/prd-auth.json US-001"
```

You will:

1. **Read US-001** from `docs/prd-auth.json`
2. **Load memory** from relatedPRDs and previous stories
3. **For step 1:** Spawn development-agent with context
4. **Wait for [STEP_COMPLETE]**
5. **For step 7:** Spawn security-agent with context
6. **Wait for [STEP_COMPLETE]**
7. **For step 10:** Spawn security-agent with context
8. **Wait for [STEP_COMPLETE]**
9. **Run typecheck**
10. **Mark US-001 complete** in PRD
11. **Commit changes**
12. **Create story memory**
13. **Output:** `<STORY_COMPLETE>`

Then `flow.sh` will continue to the next iteration.

---

## CRITICAL REMINDERS

- **Work in current directory** (`$PWD`), NOT command installation directory
- **Load memory BEFORE** spawning agents
- **Wait for [STEP_COMPLETE]** before continuing
- **Mark story complete** in JSON (passes: true)
- **Commit changes** when done
- **Output exactly:** `<STORY_COMPLETE>`
