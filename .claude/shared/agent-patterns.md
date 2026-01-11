# Common Agent Patterns for Maven Flow

This document provides common patterns, workflows, and conventions shared across all Maven Flow specialist agents.

---

## Commit Format (CRITICAL - ALL AGENTS)

**ALL commits MUST use this exact format:**

```bash
git commit -m "[type]: [brief description of what was done]

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"
```

**Commit Types by Agent:**
| Agent | Commit Prefix | Example |
|-------|---------------|---------|
| development-agent | `feat:` | `feat: add user authentication with Supabase` |
| refactor-agent | `refactor:` | `refactor: reorganize components to feature-based structure` |
| quality-agent | `fix:` | `fix: remove 'any' types and add proper TypeScript types` |
| security-agent | `security:` | `security: add RLS policies for tasks table` |
| design-agent | `design:` | `design: apply professional mobile UI to home screen` |

**CRITICAL RULES:**
- **NEVER** use "Co-Authored-By: Claude <noreply@anthropic.com>"
- **ALWAYS** use "Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"
- Include the Co-Authored-By line on a separate line at the end
- Use lowercase for commit type prefix
- Keep description brief but descriptive

**Examples:**
```bash
git commit -m "feat: add user authentication with Supabase

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"

git commit -m "fix: replace relative imports with @ aliases

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"

git commit -m "security: validate RLS policies on all queries

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"
```

---

## Multi-PRD Architecture

All agents work with **Multi-PRD Architecture**:

- Each feature has its own PRD file: `docs/prd-[feature-name].json`
- Each feature has its own progress file: `docs/progress-[feature-name].txt`
- Agents are invoked with a specific PRD filename to work on
- Progress files contain learnings and context from previous iterations

**Working Process:**
1. **Identify PRD file** - You'll be given a specific PRD filename
2. **Read PRD** - Use Read tool to load the PRD file
3. **Read progress** - Use Read tool to load the corresponding progress file for context
4. **Extract feature name** - Parse the PRD filename to get the feature name
5. **Research if needed** - Use web-search-prime/web-reader if you're unsure
6. **Implement** - Complete the step requirements
7. **Test** - Use appropriate testing methods
8. **Validate** - Run applicable checks
9. **Output completion** - Output `<promise>STEP_COMPLETE</promise>`

**NOTE:** PRD and progress file updates are handled by the `/flow` command directly. You do NOT need to update them.

---

## Feature-Based Architecture

Maven Flow enforces this structure:

```
src/
├── app/                    # Entry points, routing
├── features/               # Isolated feature modules
│   ├── auth/              # Cannot import from other features
│   ├── dashboard/
│   └── [feature-name]/
├── shared/                # Shared code (no feature imports)
│   ├── ui/                # Reusable components
│   ├── api/               # Backend clients
│   └── utils/             # Utilities
```

**Architecture Rules:**
- Features → Cannot import from other features
- Features → Can import from shared/
- Shared → Cannot import from features
- Use `@shared/*`, `@features/*`, `@app/*` aliases (no relative imports)

---

## Quality Standards (All Agents)

### Import Aliases (ZERO TOLERANCE)
```typescript
// ❌ BLOCKED - Relative imports
import { Button } from '../../../shared/ui/Button'
import { utils } from '../utils/helpers'

// ✅ CORRECT - Path aliases
import { Button } from '@shared/ui/Button'
import { utils } from '@shared/utils/helpers'
```

### Type Safety (ZERO TOLERANCE for quality-agent, recommended for all)
```typescript
// ❌ BLOCKED - 'any' type
function processData(data: any) {
  return data.map((item: any) => item.name);
}

// ✅ CORRECT - Proper interface
interface User {
  id: string;
  name: string;
}

function processData(data: User[]): string[] {
  return data.map(item => item.name);
}
```

### Component Size
- Components should be under 300 lines
- If larger, flag for modularization

---

## Professional UI Standards

### Colors (NO GRADIENTS)
```css
/* ❌ BLOCKED - Gradients */
background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);

/* ✅ CORRECT - Solid professional colors */
background: #2563eb; /* Royal blue */
color: #1e293b; /* Slate 800 */
```

### Professional Color Palette
| Category | Colors | Usage |
|----------|--------|-------|
| Primary | Blue (#2563eb, #3b82f6) | Actions, links, primary buttons |
| Success | Green (#10b981, #22c55e) | Success states, confirmations |
| Warning | Amber/Orange (#f59e0b, #f97316) | Warnings, important notices |
| Error | Red (#ef4444, #dc2626) | Errors, destructive actions |
| Neutral | Slate/Gray (#64748b, #94a3b8) | Secondary text, borders |

---

## Testing Practices

### For Web Applications
1. Start the dev server (`pnpm dev`)
2. Open Chrome browser
3. Navigate to the application URL
4. Use Chrome DevTools (F12) to:
   - Check Console for errors
   - Inspect Network requests
   - Verify DOM elements
   - Test responsive design (Device Toolbar)
   - Test auth flows (Application tab)

### For Database Changes
1. Verify schema changes in Supabase dashboard
2. Test queries with sample data
3. Verify RLS policies (if applicable)
4. Check migration files

---

## Error Handling

When encountering errors:
1. **Use web-search-prime** to research the error
2. **Check recent changes** that might have caused it
3. **Verify configuration** (env files, config files)
4. **Test incrementally** - isolate the problem
5. **Ask user** if you cannot resolve after research

---

## Maven Step Reference

| Step | Agent | Description |
|------|-------|-------------|
| 1 | development-agent | Foundation - Import UI with mock data or create from scratch |
| 2 | development-agent | Package Manager - Convert npm → pnpm |
| 3 | refactor-agent | Feature Structure - Restructure to feature-based folder structure |
| 4 | refactor-agent | Modularization - Modularize components >300 lines |
| 5 | quality-agent | Type Safety - No 'any' types, @ aliases |
| 6 | refactor-agent | UI Centralization - Centralize UI components to @shared/ui |
| 7 | development-agent | Data Layer - Centralized data layer with backend setup |
| 8 | security-agent | Auth Integration - Firebase + Supabase authentication flow |
| 9 | development-agent | MCP Integration - MCP integrations |
| 10 | security-agent | Security & Error Handling - Security and error handling |
| 11 | design-agent | Mobile Design - Professional UI/UX for Expo/React Native (optional) |
