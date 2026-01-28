---
description: Consolidate story memories when PRD complete - quick, actionable
argument-hint: [prd-file]
---

# Consolidate Memory - QUICK VERSION

**YOU MUST consolidate all story memories into ONE file NOW.**

This is called when ALL stories in a PRD are complete. Work FAST.

**CRITICAL:** Work in current directory (`$PWD`), NOT command installation directory.

---

## The Job

Read all story memory files and create ONE consolidated memory file at: `docs/consolidated-[feature].txt`

---

## STEP 1: Get Feature Name

**Execute:**
```bash
if [ -n "$1" ]; then
    feature=$(basename "$1" .json | sed 's/prd-//')
else
    # Find first PRD if not specified
    prd=$(find docs -name "prd-*.json" -type f | head -1)
    feature=$(basename "$prd" .json | sed 's/prd-//')
fi
```

---

## STEP 2: Find All Story Memories

**Execute:**
```bash
find docs/$feature/story-*.txt -type f | sort
```

---

## STEP 3: Read and Synthesize

**For each story memory:**
1. Read the file
2. Extract key info (story ID, title, what was built, decisions, lessons)
3. Keep it brief - 5-10 lines per story max

---

## STEP 4: Create Consolidated Memory

**Write to:** `docs/consolidated-$feature.txt`

**Use this template:**

```
---
memoryType: consolidated
feature: [feature name]
createdDate: $(date +%Y-%m-%d)
totalStories: [count]
---

CONSOLIDATED MEMORY: [FEATURE NAME]
====================================

TECH STACK:
[Main technologies, frameworks, libraries used]

ARCHITECTURE:
[Project structure, key patterns, organization]

STORY SUMMARIES:
================

[STORY-ID] - [Title]
- Implemented: [what was built]
- Key decisions: [important choices]
- Lessons: [what to remember]

[STORY-ID] - [Title]
- Implemented: [what was built]
- Key decisions: [important choices]
- Lessons: [what to remember]

[Continue for all stories...]

INTEGRATION POINTS:
[How this feature connects to others]

IMPORTANT PATTERNS:
[Reusable code patterns, conventions established]

KNOWN ISSUES / FUTURE WORK:
[What's left todo, known limitations, future improvements]
```

---

## STEP 5: Output Marker

**Output exactly:**

```
<CONSOLIDATED_MEMORY_CREATED>
Feature: [feature name]
Memory File: docs/consolidated-[feature].txt
Stories Processed: [count]
Total Length: [character count]
</CONSOLIDATED_MEMORY_CREATED>
```

---

## CRITICAL: BE FAST

- Don't over-analyze - capture the essentials
- Don't read every source file - use what's in story memories
- Keep summaries brief (5-10 lines per story)
- If something is unclear, make a reasonable judgment
- The goal is useful context, not perfect documentation

---

## Example

Input: `/consolidate-memory docs/prd-abuse-controls.json`

```bash
# Get feature name
feature="abuse-controls"

# Find story memories
find docs/abuse-controls/story-*.txt
# → docs/abuse-controls/story-us-001-define-hard-caps.txt
# → docs/abuse-controls/story-us-002-rate-limiting.txt

# Read each memory, extract key info

# Create consolidated memory
cat > docs/consolidated-abuse-controls.txt << 'EOF'
---
memoryType: consolidated
feature: abuse-controls
createdDate: 2026-01-28
totalStories: 2
---

CONSOLIDATED MEMORY: ABUSE CONTROLS
====================================

TECH STACK:
- Next.js 14 with App Router
- Supabase for rate limit storage
- Redis for distributed caching
- TypeScript

ARCHITECTURE:
- Feature-based structure under src/features/abuse-controls/
- Middleware layer for request interception
- Config-driven rate limiting rules

STORY SUMMARIES:
================

US-001 - Define Hard Caps
- Implemented: Rate limit configuration system with hard caps
- Key decisions: Used token bucket algorithm, set 1000 req/hour default
- Lessons: Rate limits should be environment-configurable

US-002 - Rate Limiting Middleware
- Implemented: Express middleware for rate limit enforcement
- Key decisions: IP-based and user-based limiting, Redis for distributed state
- Lessons: Need monitoring for rate limit hits, consider burst allowances

INTEGRATION POINTS:
- Connects to authentication system for user identification
- API gateway uses these limits for all endpoints
- Will be extended by abuse-detection feature

IMPORTANT PATTERNS:
- Rate limit rules are defined in config files, not hardcoded
- Middleware chain: rate limiting → auth → handler
- Fallback to local limits if Redis unavailable

KNOWN ISSUES / FUTURE WORK:
- Add admin UI for managing rate limits
- Implement burst allowance for traffic spikes
- Add metrics/monitoring for limit violations
- Consider per-endpoint rate limits
EOF

# Output marker
echo "<CONSOLIDATED_MEMORY_CREATED>
Feature: abuse-controls
Memory File: docs/consolidated-abuse-controls.txt
Stories Processed: 2
Total Length: $(wc -c < docs/consolidated-abuse-controls.txt)
</CONSOLIDATED_MEMORY_CREATED>"
```

Done! Returns immediately.
