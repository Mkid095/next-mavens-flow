---
description: Create story memory file after completion - quick, actionable
argument-hint: <prd-file> <story-id>
---

# Create Story Memory - QUICK VERSION

**YOU MUST create a story memory file NOW.**

This is called after a story is complete. Work FAST - don't over-analyze.

**CRITICAL:** Work in current directory (`$PWD`), NOT command installation directory.

---

## The Job

Create a story memory file at: `docs/[feature]/story-us-[###]-[slug].txt`

**Arguments:**
- `$1` = PRD file (e.g., `docs/prd-abuse-controls.json`)
- `$2` = Story ID (e.g., `US-001`)

---

## STEP 1: Get Story Info (FAST)

**Execute:** `cat "$1" | jq ".userStories[] | select(.id == \"$2\")"`

Extract:
- `title` - Story title
- `description` - What it does
- `mavenSteps` - Steps executed

---

## STEP 2: Get Recent Changes (FAST)

**Execute:**
```bash
# Recent commits (last 3)
git log --oneline -3 2>/dev/null || echo "No git history"
```

If git fails, just note: "No git repository - memory created from PRD only"

---

## STEP 3: Get Feature Name

**Execute:**
```bash
feature=$(basename "$1" .json | sed 's/prd-//')
```

---

## STEP 4: Create Memory File

**Execute:**
```bash
mkdir -p "docs/$feature"
```

**Write to:** `docs/$feature/story-us-$(echo $2 | tr '[:upper:]' '[:lower:]' | tr ' ' '-').txt`

**Use this template (FILL IT IN):**

```
---
memoryVersion: 1
storyId: $2
storyTitle: [from jq]
completedDate: $(date +%Y-%m-%d)
---

STORY: $2 - [TITLE]
========================

DESCRIPTION:
[story description]

MAVEN STEPS COMPLETED:
[steps from jq]

IMPLEMENTATION SUMMARY:
[2-3 sentences what was built]

KEY FILES:
[List main files created/modified]

DECISIONS MADE:
[Any important choices]

INTEGRATION POINTS:
[How this connects to other features]

LESSONS LEARNED:
[What to remember for future stories]
```

---

## STEP 5: Output Marker

**Output exactly:**

```
<STORY_MEMORY_CREATED>
Story: $2 - [TITLE]
Memory File: [path to file]
Content Length: [character count]
</STORY_MEMORY_CREATED>
```

---

## CRITICAL: BE FAST

- Don't read every file - just list them
- Don't over-analyze - capture the key points
- If git fails, just use PRD info
- If unsure, keep it brief

The goal is a useful memory reference, not a comprehensive documentation.

---

## Example

Input: `/create-story-memory docs/prd-abuse-controls.json US-001`

Output:
```bash
# Get story
jq '.userStories[] | select(.id == "US-001")' docs/prd-abuse-controls.json
# → Gets title, description, steps

# Get feature name
basename docs/prd-abuse-controls.json .json | sed 's/prd-//'
# → "abuse-controls"

# Create directory
mkdir -p docs/abuse-controls

# Write memory
cat > docs/abuse-controls/story-us-001-define-hard-caps.txt << 'EOF'
---
memoryVersion: 1
storyId: US-001
storyTitle: Define Hard Caps
completedDate: 2026-01-28
---

STORY: US-001 - Define Hard Caps
========================

DESCRIPTION: Define hard caps for API rate limiting and abuse prevention

MAVEN STEPS COMPLETED: [1]

IMPLEMENTATION SUMMARY:
Created rate limiting configuration with hard caps for API endpoints. Defined maximum request rates per user and per API key.

KEY FILES:
- src/config/rate-limits.ts - Rate limit definitions
- src/middleware/rate-limit.ts - Rate limiting middleware

DECISIONS MADE:
- Used token bucket algorithm for rate limiting
- Set default caps at 1000 requests/hour per user

INTEGRATION POINTS:
- Connects to authentication system for user identification
- Will be used by abuse-detection feature

LESSONS LEARNED:
- Rate limits should be configurable per environment
- Need to add monitoring for rate limit hits
EOF

# Output marker
echo "<STORY_MEMORY_CREATED>
Story: US-001 - Define Hard Caps
Memory File: docs/abuse-controls/story-us-001-define-hard-caps.txt
Content Length: $(wc -c < docs/abuse-controls/story-us-001-define-hard-caps.txt)
</STORY_MEMORY_CREATED>"
```

Done! Returns to flow.sh immediately.
