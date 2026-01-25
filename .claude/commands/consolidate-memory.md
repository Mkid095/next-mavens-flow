---
name: consolidate-memory
description: Consolidate all story memories into PRD when all stories complete. AI-powered analysis and synthesis of implementation patterns, decisions, and learnings.
---

# Memory Consolidation Command

You are consolidating all story memories from a completed PRD into a single, coherent consolidated memory.

## Trigger
This command is automatically triggered when all stories in a PRD are marked as complete (`passes: true`).

## Input
- PRD file path provided as argument: `$1`
- All story memory files in `docs/[feature]/story-*.txt`

## Your Task

### Step 1: Read and Understand

1. **Read the PRD file** to understand the feature:
   ```bash
   cat "$PRD_FILE"
   ```

2. **Find all story memory files**:
   ```bash
   find docs/[feature]/story-*.txt -type f | sort
   ```

3. **Read each story memory file** to understand:
   - What was implemented
   - Key decisions made
   - Challenges resolved
   - Lessons learned
   - Code patterns established

### Step 2: Extract and Synthesize

From all story memories, extract and organize:

**Architecture Decisions:**
- Tech stack choices
- Project structure
- Design patterns
- Integration approaches

**Implementation Patterns:**
- Component structure
- API patterns
- State management
- Error handling

**Key Learnings:**
- What worked well
- What didn't work
- Lessons for future work

**Story Summaries:**
- Brief summary of each story
- What each story accomplished

### Step 3: Create Consolidated Memory

Write a comprehensive consolidated memory following this structure:

```markdown
# Consolidated Memory: [Feature Name]

## Project Overview
[Brief 2-3 sentence description of what was built]

## Architecture Decisions

### Tech Stack
- **Framework**: [Why this choice]
- **Database**: [Why this choice]
- **Language**: [TypeScript approach, strict mode]
- **Styling**: [Tailwind/CSS approach]
- **State Management**: [Approach and why]

### Project Structure
```
src/
├── features/[feature-name]/
│   ├── components/     [What goes here]
│   ├── api/            [What goes here]
│   ├── hooks/          [What goes here]
│   ├── types/          [What goes here]
│   └── index.ts        [Public API]
└── shared/
    ├── ui/             [Shared components]
    ├── lib/            [Utilities]
    └── [other shared]   [As needed]
```

**Key Principles:**
- [Principle 1 from implementation]
- [Principle 2 from implementation]

## Integration Patterns

### Data Layer
[How database/API integration works]

### State Management
[How state is managed across the app]

### Component Communication
[How components talk to each other]

## Common Patterns

### Component Structure
```typescript
// Standard component pattern
[Show actual pattern used]
```

### API Pattern
```typescript
// Standard API call pattern
[Show actual pattern used]
```

### Error Handling
```typescript
// Error handling approach
[Show actual pattern used]
```

### Type Safety
```typescript
// Type definitions approach
[Show actual pattern used]
```

## Story Summaries

### US-XXX-001: [Story Title]
[Brief summary of what was implemented]

### US-XXX-002: [Story Title]
[Brief summary of what was implemented]

[... one summary per story ...]

## Key Learnings

### What Worked Well
- [Learning 1]
- [Learning 2]

### Challenges Resolved
- [Challenge 1 and how it was solved]
- [Challenge 2 and how it was solved]

### Lessons for Future Work
- [Lesson 1]
- [Lesson 2]

## Integration Points
- [How this feature connects to other features]
- [What other features need to know]

## Next Considerations
- [What to consider for future enhancements]
- [Technical debt items]
- [Improvement opportunities]
```

### Step 4: Update PRD

1. Read the current PRD
2. Update the `consolidatedMemory` field with your consolidated memory
3. Write the updated PRD back

```bash
# Use jq to update the PRD
jq --arg memory "$CONSOLIDATED_MEMORY" \
   '.consolidatedMemory = $memory' \
   "$PRD_FILE" > /tmp/prd-temp.json && \
   mv /tmp/prd-temp.json "$PRD_FILE"
```

### Step 5: Commit Changes

```bash
git add "$PRD_FILE"
git commit -m "docs: consolidate memory for [feature-name]"
git push
```

## Output

When complete, output:

```
<MEMORY_CONSOLIDATED>
Feature: [feature-name]
Stories Processed: [count]
Consolidated Memory Length: [characters]
</MEMORY_CONSOLIDATED>
```

## Important Notes

- **Be comprehensive**: Include all meaningful patterns and learnings
- **Be specific**: Use actual examples from the codebase
- **Be organized**: Group related information together
- **Be concise**: Avoid repetition, focus on what matters
- **Think forward**: Write for someone who will work on this next

The consolidated memory will be loaded as context for future stories in related PRDs, so make it useful!
