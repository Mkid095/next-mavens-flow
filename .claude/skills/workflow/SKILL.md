---
name: workflow
description: "Autonomous Maven development workflow - executes 10-step development process with specialized agents. Use for starting new projects or implementing features."
---

# Maven Autonomous Development Workflow

Complete autonomous development system that manages your entire project lifecycle through 10 specialized steps with coordinated agents.

---

## System Architecture

The Maven workflow uses:
- **Skills**: Reusable capabilities invoked automatically
- **Subagents**: Specialized agents with isolated context windows
- **Hooks**: Automated triggers for quality enforcement
- **PRD System**: Task tracking in `docs/prd.json`

### Agent Coordination

```
┌─────────────────────────────────────────────────────────────┐
│                    MAVEN ORCHESTRATOR                        │
│  (Main Claude - coordinates all agents and workflow)         │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Development  │    │ Quality      │    │ Security     │
│ Agent        │    │ Agent        │    │ Auditor      │
│ (Implements) │    │ (Validates)  │    │ (Reviews)    │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        └─────────────────────┴─────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Shared Context  │
                    │  (docs/prd.json) │
                    │  (progress.txt)  │
                    └──────────────────┘
```

---

## The 10-Step Workflow

### Step 1: Project Foundation
**Agent**: Development Agent
**Action**: Import UI or create from scratch
- Web apps: Import fully working UI with mock data
- Mobile: Plan and develop UI from scratch using Expo
- Desktop: Plan and develop UI from scratch

**Hooks**: None (manual confirmation)

---

### Step 2: Package Manager Migration
**Agent**: Development Agent
**Action**: Convert npm → pnpm
**Frequency**: One-time per project
**Validation**:
- Remove `package-lock.json`
- Create `pnpm-lock.yaml`
- Update CI/CD scripts

**Hooks**: `post-tool-use.sh` validates pnpm usage

---

### Step 3: Feature-Based Folder Structure
**Agent**: Refactor Agent
**Action**: Restructure to feature-based architecture
**Frequency**: One-time, then enforced via ESLint

**Target Structure**:
```
src/
├── features/              # Feature-specific code (isolated)
│   ├── auth/             # Authentication feature
│   │   ├── components/   # Auth-only components
│   │   ├── api/          # Auth API calls
│   │   ├── hooks/        # Auth custom hooks
│   │   ├── types/        # Auth types
│   │   └── index.ts      # Public API
│   ├── products/         # Products feature
│   │   ├── components/
│   │   ├── api/
│   │   └── ...
│   └── users/            # Users feature
│       └── ...
├── shared/               # Global code (used by all features)
│   ├── components/       # Global UI components
│   ├── ui/              # Design system components
│   ├── lib/             # Utility functions
│   ├── hooks/           # Global custom hooks
│   ├── api/             # API client configuration
│   └── config/          # App configuration
├── app/                  # Route pages (composition only)
└── types/                # Global types
```

**ESLint Rules** (enforced via `eslint-plugin-boundaries`):
- Features CANNOT import from other features
- Features CAN import from shared/
- App CAN import from features and shared
- Shared CANNOT import from features or app

**Hooks**: `post-tool-use.sh` validates imports

---

### Step 4: Component Modularization
**Agent**: Refactor Agent
**Action**: Break down components >300 lines
**Frequency**: After EVERY task completion (automated via hooks)

**Automation**:
```bash
# Hook runs after every Write/Edit
# If file >300 lines, spawn modularization subagent automatically
```

**Validation**:
- No component exceeds 300 lines
- Extract to logical sub-components
- Extract custom hooks
- Extract utilities

**Hooks**: `post-tool-use.sh` auto-triggers refactor

---

### Step 5: Type Safety & Import Aliases
**Agent**: Quality Agent
**Action**: Verify @ aliases and no 'any' types
**Frequency**: After EVERY task completion (automated)

**Checks**:
```typescript
// ✅ Correct
import { Button } from '@shared/ui';
import { useAuth } from '@features/auth/hooks';

// ❌ Wrong
import { Button } from '../../../shared/ui';
import { useAuth } from '../../features/auth/hooks';

// ❌ Wrong
function foo(data: any) { }
```

**Automation**:
- Hooks scan for violations after each edit
- Auto-spawn fix subagent if violations found

**Hooks**: `post-tool-use.sh` + `stop.sh` validate

---

### Step 6: Centralized UI Components
**Agent**: Refactor Agent
**Action**: Consolidate UI to `@shared/ui`
**Frequency**: After EVERY task completion

**Target**:
```typescript
// @shared/ui/index.ts - Central design system
export * from './Button';
export * from './Input';
export * from './Modal';
export * from './Select';
// ... ALL UI components

// Theme system for easy theming
export const themes = {
  light: lightTheme,
  dark: darkTheme,
  custom: customTheme,
};
```

**Hooks**: `post-tool-use.sh` detects duplicate UI patterns

---

### Step 7: Centralized Data Layer
**Agent**: Development Agent
**Action**: Establish data layer foundation
**Frequency**: After EVERY task completion (validation)

**Architecture**:
```typescript
// @shared/api/ - Centralized data layer
├── client/              # API client configuration
│   └── supabase.ts      # Supabase client
│   └── firebase.ts      # Firebase client
├── features/           # Feature-specific API functions
│   ├── auth.ts         # Auth API calls
│   ├── products.ts     # Products API calls
│   └── ...
├── middleware/         # Request/response middleware
│   ├── auth.ts         # Auth middleware
│   ├── error.ts        # Error handling
│   └── cache.ts        # Caching logic
└── types/             # API types
```

**Benefits**:
- Single source of truth for data fetching
- Centralized error handling
- Unified caching strategy
- Easy permission system integration
- Smooth future integrations

**Hooks**: `post-tool-use.sh` validates API calls use central layer

---

### Step 8: Firebase + Supabase Auth Integration
**Agent**: Auth Specialist Agent
**Action**: Implement complete auth flow
**Frequency**: One-time setup + validation checks

**Auth Flow**:
```
Sign Up:
1. Firebase creates user → returns Firebase UID
2. App saves profile to Supabase with firebase_uid
3. User logged in with complete profile

Login:
1. Firebase verifies email/password → returns Firebase UID
2. App fetches profile from Supabase using firebase_uid
3. User logged in with profile data

Password Reset:
1. Firebase sends reset email with oobCode
2. User clicks link → /reset-password?mode=resetPassword&oobCode=...
3. User enters new password → Firebase updates
```

**Implementation**:
```typescript
// @features/auth/api/
- firebase.ts         # Firebase Auth operations
- supabase.ts        # Supabase profile operations
- integration.ts     # Unified auth flow

// @features/auth/hooks/
- useAuth.ts         # Main auth hook
- useSignIn.ts       # Sign in flow
- useSignUp.ts       # Sign up flow
- usePasswordReset.ts # Password reset flow
```

**Hooks**: `post-tool-use.sh` validates auth files use integration layer

---

### Step 9: MCP Server Integrations
**Agent**: Development Agent
**Available MCPs**:
- `web-search-prime` - Web research (always)
- `web-reader` - Web content fetching (always)
- `chromedev-tools` - Web app testing (for web apps)
- `supabase` - Supabase operations (when using Supabase)
- `expo` - Mobile testing via QR (for mobile apps)

**Usage**:
```
# Research
Use web-search-prime for: "best practices for X"
Use web-reader for: "Read documentation at URL"

# Testing (Web)
Use chromedev-tools for: Browser automation tests

# Testing (Mobile)
Use expo for: "Start dev server and show QR"
Use expo for: "Run mobile tests"

# Database
Use supabase for: "Create table", "Run query", "Check migrations"
```

**Hooks**: `session-start.sh` validates MCP connections

---

### Step 10: Security & Error Handling
**Agent**: Security Auditor Agent
**Action**: Comprehensive security validation
**Frequency**: Before commits, on auth changes, after major features

**Checklist**:
```typescript
// Security
✅ No exposed API keys (check .env, .env.example)
✅ No sensitive data in error messages
✅ Proper input validation on all forms
✅ SQL injection prevention (parameterized queries)
✅ XSS prevention (React escaping, CSP headers)
✅ CSRF protection on mutations
✅ Proper route protection
✅ Rate limiting on API endpoints

// Error Handling
✅ Try-catch on all async operations
✅ Error boundaries for React components
✅ User-friendly error messages
✅ Error logging (Sentry, etc.)
✅ Graceful degradation

// Confirmations
✅ Destructive actions have confirmations
✅ Forms have proper validation feedback
✅ Loading states on all async actions
```

**Hooks**: `pre-commit.sh` runs security check

---

## PRD Integration

**Location**: `docs/prd.json` (not root!)

**Format**:
```json
{
  "project": "ProjectName",
  "branchName": "feature/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "STEP-1",
      "title": "Project Foundation",
      "description": "Set up project foundation",
      "acceptanceCriteria": [
        "UI imported or created",
        "Development environment ready",
        "Initial commit made"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
    // ... Steps 2-10
  ]
}
```

**Progress Tracking**: `docs/progress.txt`

---

## Workflow Orchestration

### Starting a New Project

```
User: Load maven-workflow skill and start new project for [description]

Maven Orchestrator:
1. Creates docs/prd.json with 10 steps
2. Spawns Development Agent for Step 1
3. Agent works in isolated context
4. On completion, updates PRD
5. Hooks validate quality automatically
6. If issues found, spawn Quality Agent
7. When step passes, move to next step
8. Repeat until all 10 steps complete
```

### Continuing Work

```
User: /maven-status

Maven Orchestrator:
1. Reads docs/prd.json
2. Shows current step
3. Shows completed steps
4. Shows any issues from hooks

User: /maven-continue

Maven Orchestrator:
1. Resumes from current step
2. Spawns appropriate agent
3. Continues workflow
```

---

## Hooks: The Automation Engine

Hooks automatically:
1. **Validate after every edit** (`post-tool-use.sh`)
2. **Check quality on stop** (`stop.sh`)
3. **Validate imports** (`import-validator.sh`)
4. **Check component size** (`size-checker.sh`)
5. **Run security audit** (`security-audit.sh`)
6. **Spawn fix agents** when issues found

---

## Subagent System

Specialized agents with isolated contexts:

| Agent | Purpose | When Invoked |
|-------|---------|--------------|
| **Development Agent** | Implements features | Step 1, 2, 7, 9 |
| **Refactor Agent** | Restructures code | Step 3, 4, 6 |
| **Quality Agent** | Validates quality | Step 5, repetitive checks |
| **Auth Specialist** | Auth implementation | Step 8 |
| **Security Auditor** | Security review | Step 10, auth changes |
| **Fix Agent** | Auto-fixes issues | Spawned by hooks |

Each agent has:
- Own context window
- Specific tools and permissions
- Focused system prompt
- Validation requirements

---

## Getting Started

1. **Install Maven Workflow**:
   ```bash
   cp -r maven-workflow ~/.claude/skills/
   ```

2. **Start New Project**:
   ```
   Load maven-workflow skill and create new project for [description]
   ```

3. **Or Use Slash Commands**:
   ```
   /maven-start [project description]
   /maven-status
   /maven-continue
   /maven-validate
   ```

---

## Key Principles

1. **Agents Own Their Context** - Each agent works in isolation
2. **Hooks Automate Quality** - No manual validation needed
3. **Steps Are Idempotent** - Can re-run steps safely
4. **Progress Tracked** - PRD system tracks everything
5. **Fixes Automatic** - Hooks spawn fix agents when needed

---

## Example Session

```
You: Load maven-workflow and create project for task management app

Maven: Creating docs/prd.json with 10 steps...

[Step 1: Project Foundation]
Spawning Development Agent...

Agent: Importing UI with mock data...
✅ Complete

[Quality Check]
Hook: Running post-edit validation...
✅ No issues

[Step 2: Package Manager]
Spawning Development Agent...

Agent: Converting to pnpm...
- Removing package-lock.json
- Running pnpm import
✅ Complete

[Continuing through all 10 steps...]

Maven: 🎉 All steps complete! Project ready for development.
```

---

This is the complete autonomous development system. Each component works together to automate your entire workflow while maintaining quality and security standards.
