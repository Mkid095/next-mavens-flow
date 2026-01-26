---
description: Create intelligent story memory after story completion. Analyzes git diff, implementation details, and generates comprehensive memory file.
argument-hint: [prd-file] [story-id]
---

# Story Memory Creation Command

You are creating a story memory file after a story has been completed. This memory will be used for context in future stories.

## Trigger
This command is automatically triggered after a story is marked complete and committed.

## Input
- PRD file path: $1
- Story ID: $2

## Your Task

### Step 1: Extract Story Details

1. Read the PRD to get story information:
   jq ".userStories[] | select(.id == \"$STORY_ID\")" "$PRD_FILE"

2. Extract:
   - Story title
   - Description
   - Maven steps executed
   - Acceptance criteria
   - Priority

### Step 2: Analyze Implementation

1. Get files changed from the most recent commit:
   git diff --name-only --diff-filter=A HEAD~1  # Created
   git diff --name-only --diff-filter=M HEAD~1  # Modified
   git diff --stat HEAD~1                       # Summary

2. Read key files to understand implementation:
   - Focus on main implementation files
   - Look for patterns and decisions
   - Note challenges and solutions

### Step 3: Generate Memory Content

Create a comprehensive story memory file with actual content (not placeholders):

STORY MEMORY: US-XXX - Story Title
=========================================================

COMPLETED: YYYY-MM-DD

STORY DETAILS:
- ID: US-XXX
- Title: Story Title
- Priority: 1
- Maven Steps: [1, 2, 3, 5]
- Status: Complete

IMPLEMENTATION SUMMARY:
[2-3 sentences describing what was actually implemented.
Include key components, features, and how they work.]

FILES CREATED (X):
- path/to/file1.ts (Y lines) - [Brief purpose]
- path/to/file2.tsx (Y lines) - [Brief purpose]
- path/to/api/resource.ts (Y lines) - [Brief purpose]

FILES MODIFIED (X):
- path/to/file.ts - [What changed]
- path/to/config.json - [What changed]

KEY DECISIONS:
1. [Decision 1]
   - Rationale: [Why this decision was made]
   - Impact: [What this enables]

2. [Decision 2]
   - Rationale: [Why this decision was made]
   - Impact: [What this enables]

INTEGRATION POINTS:
- [Connection to Feature A]: [How it integrates]
- [Uses Shared Component X]: [For what purpose]
- [Will Connect to Future Feature Y]: [How it's prepared]

CHALLENGES RESOLVED:
1. [Challenge]
   - Problem: [What was wrong]
   - Solution: [How it was fixed]
   - Lesson: [What to remember]

2. [Challenge]
   - Problem: [What was wrong]
   - Solution: [How it was fixed]
   - Lesson: [What to remember]

LESSONS LEARNED:
1. [Learning about development process]
2. [Learning about the tech stack]
3. [Learning about architecture]

CODE PATTERNS ESTABLISHED:
typescript
// [Pattern name]
[Show actual code example of pattern used]
```

- Usage: [When to use this pattern]
- Benefits: [Why this pattern is good]

ACCEPTANCE CRITERIA:
- [Criteria 1] - [How it was verified]
- [Criteria 2] - [How it was verified]
- [Criteria 3] - [How it was verified]

### Step 4: Write Memory File

1. Determine file location:
   - Feature name from PRD filename
   - Format: docs/[feature]/story-us-[###]-[slug-title].txt

2. Create directory if needed:
   mkdir -p "docs/[feature]"

3. Write memory file

### Step 5: Commit Memory File

git add "docs/[feature]/story-*.txt"
git commit -m "docs: add story memory for US-XXX"

## Output

When complete, output:

<STORY_MEMORY_CREATED>
Story: US-XXX - Story Title
Memory File: docs/[feature]/story-us-xxx-title.txt
Content Length: [characters]
</STORY_MEMORY_CREATED>

## Important Notes

- Be specific: Use actual filenames, line counts, code examples
- Be meaningful: Fill all sections with real content, not placeholders
- Be useful: Write for your future self (or another developer)
- Be honest: Include challenges and what didn't work
- Think forward: What would help someone working on a related story?

The story memory will be:
1. Included in consolidated memory when PRD is complete
2. Available as context for future stories
3. A reference for understanding implementation decisions
