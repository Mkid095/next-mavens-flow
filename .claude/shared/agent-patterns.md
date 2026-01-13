# Common Agent Patterns for Maven Flow

This document provides common patterns, workflows, and conventions shared across all Maven Flow specialist agents.

---

## MCP Tool Usage Pattern (CRITICAL)

**When an agent is told to use MCP tools, the instruction MUST appear at the VERY START of the task prompt:**

```markdown
*** CRITICAL: MCP TOOLS INSTRUCTION ***
You MUST use the Supabase MCP tools for ALL database operations.
DO NOT read migration files or create scripts.
Query the database DIRECTLY using Supabase MCP tools.

[Rest of task prompt...]
```

**For database verification tasks:**
1. **FIRST:** Use Supabase MCP to query the database directly
2. **DON'T** read migration files or type files
3. **DON'T** create scripts - use the MCP server
4. **ONLY** fall back to files if MCP is unavailable

**When told to use "supabase" MCP:**
- Use it to check tables, query schema, read/write data, apply migrations
- Use it to generate TypeScript types from the actual database
- Use it to get project configuration (API keys, URLs)
- Always verify the actual database state, not files

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

## Browser Testing Pattern (CRITICAL for playwright, chrome-devtools MCPs)

**When using browser MCPs (playwright, chrome-devtools) for live testing:**

### Always Read Console Logs
- **ALWAYS check browser console** for errors, warnings, and failed requests
- **FIX any issues found** before marking the step complete
- Common issues to fix: JavaScript errors, failed API calls, network errors, missing resources

### Test User Credentials (Standard Across All Projects)
- **Email:** `revccnt@gmail.com`
- **Password:** `Elishiba!90`

**Process:**
1. **Create this user** first during account/signup testing
2. **Use this account** for all subsequent testing
3. **Keep account logged in** during testing session
4. **Clear data between tests** if needed (delete test data, keep account)

### Role Switching for Multi-Role Testing
When testing features that require different user roles (e.g., SUPER_ADMIN, SHOP_OWNER, SHOP_EMPLOYEE):
- **First:** Create the base user with `revccnt@gmail.com`
- **Then:** Add role switching functionality to the application
- **Switch roles** within the same portal/session to test each role
- **Do NOT** create separate accounts for each role - use role switching

**Example Role Switching Flow:**
1. Log in as `revccnt@gmail.com`
2. Use role switcher to change to SUPER_ADMIN role
3. Test SUPER_ADMIN features
4. Switch to SHOP_OWNER role
5. Test SHOP_OWNER features
6. Switch to SHOP_EMPLOYEE role
7. Test SHOP_EMPLOYEE features

### Testing Checklist
- [ ] Console is clear (no errors, no warnings)
- [ ] All API calls succeed (check Network tab)
- [ ] Test user `revccnt@gmail.com` can log in
- [ ] All user flows work end-to-end
- [ ] Role switching works (if multi-role app)
- [ ] Fix any console errors found
- [ ] Re-test after fixes

### Common Console Issues to Fix
- `ReferenceError`: Variable or function not found
- `TypeError`: Null/undefined access
- `Failed to fetch`: API endpoint issues
- `CORS`: Cross-origin errors
- `404 / 500`: Backend errors
- Missing assets or imports

**Remember:** A clean console = working application. Never mark testing complete with console errors.

---
---

## Server Management Pattern (CRITICAL - ALL AGENTS)

**NEVER stop all Node.js servers.** Always stop only the specific server you intend to stop.

### The Problem with Broad Server Killing

**❌ FORBIDDEN:**
```bash
# ❌ Kills ALL Node processes (including other projects!)
pkill -9 node
killall node
taskkill /F /IM node.exe (Windows)
lsof -ti:3000-9000 | xargs kill -9
```

**Why this is dangerous:**
- Stops servers from OTHER projects you might have running
- Stops background processes that may be important
- Can corrupt database connections
- Can interrupt other development work
- Unprofessional and destructive

### ✅ CORRECT: Stop Specific Server Only

**Identify and stop ONLY the specific server:**

#### Option 1: Find the process by port
```bash
# List what's running on a specific port
lsof -ti:3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Stop ONLY that specific process
kill -9 $(lsof -ti:3000)  # macOS/Linux
taskkill /PID <PID> /F  # Windows (replace <PID> with actual PID)
```

#### Option 2: Use the package manager
```bash
# If started with pnpm
pnpm dev --kill
pnpm --filter <project-name> stop

# If started with npm
npm run stop  # if stop script defined
```

#### Option 3: Find the process by name
```bash
# Find Next.js dev server specifically
ps aux | grep "next dev"  # macOS/Linux
tasklist | findstr "node"  # Windows

# Kill ONLY that specific PID
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### If You Can't Stop the Server

**Research the correct way before using force:**

1. **Use web-search-prime MCP** to research:
   - "how to stop Next.js dev server on port 3000"
   - "how to stop Expo server on port 8081"
   - "how to stop Vite dev server"
   - "proper way to stop [specific framework] server"

2. **Check the documentation** for the specific framework

3. **Try Ctrl+C in the terminal** where the server is running first

4. **Only as last resort**, kill by specific port/PID (not all Node processes)

### Standard Process for Development Agents

**When you need to restart a server:**

1. **First:** Try Ctrl+C in the terminal
2. **Second:** Find the specific port the server is using
3. **Third:** Kill ONLY that specific port's process
4. **Fourth:** Research online if unsure
5. **NEVER:** Kill all Node processes

**Example workflow:**
```bash
# 1. Check what's on port 3000
lsof -ti:3000
# Output: 12345

# 2. Kill ONLY that process
kill -9 12345

# 3. Verify it's stopped
lsof -ti:3000
# Output: (empty - good!)

# 4. Start new server
pnpm dev
```

### Agent Responsibility

**ALL agents must:**
- **development-agent:** When restarting dev servers, stop only the specific server
- **testing-agent:** When starting/stopping servers for testing, be specific
- **mobile-app-agent:** When managing Expo/React Native servers, stop only those
- **Any agent:** Never use `pkill node`, `killall node`, or similar broad commands

**quality-agent will block commits that:**
- Use broad process killing commands in scripts
- Don't specify which server to stop
- Kill all Node processes instead of specific ones

---

## UI/UX Standards (CRITICAL - ALL AGENTS)

### NO EMOJOS - Use Professional Icons Only

**ZERO TOLERANCE RULE:**

**NEVER use emojis in any UI component.**

Emojis are unprofessional and inconsistent across platforms. Always use professional icon libraries.

**❌ FORBIDDEN:**
```tsx
// ❌ Emojis in text
<span>Hello 👋</span>
<button>Submit ✅</button>
<div>Status: ⏳ Processing</div>

// ❌ Emojis as icons
<span>🗑️</span>
<span>✏️</span>
<span>🔔</span>
```

**✅ CORRECT - Use Professional Icon Libraries:**
```tsx
// ✅ Import from icon libraries
import { Trash2, Edit, Bell } from 'lucide-react';
// or
import { TrashIcon, PencilIcon, BellIcon } from '@heroicons/react/24/outline';
// or
import { Icon } from '@/shared/ui/icons';

// ✅ Use as components
<Trash2 className="w-4 h-4" />
<Edit className="w-4 h-4" />
<Bell className="w-4 h-4" />

// ✅ With proper styling
<button className="flex items-center gap-2">
  <Bell className="w-4 h-4" />
  <span>Notifications</span>
</button>
```

**Approved Icon Libraries:**
- `lucide-react` - Lightweight, consistent, tree-shakeable
- `@heroicons/react` - Official Tailwind icons
- `@radix-ui/react-icons` - Radix UI component icons
- Custom SVG icons in `@/shared/ui/icons`

**When Creating New Components:**
1. Check if icon already exists in `@/shared/ui/icons`
2. If not, import from lucide-react or heroicons
3. NEVER use emoji as fallback
4. NEVER use emoji in placeholder text

**Agent Responsibility:**
- **quality-agent:** Block any commits with emojis in UI components
- **development-agent:** Use icon libraries, never emojis
- **refactor-agent:** Replace emojis with proper icons
- **design-agent:** Use professional icons for mobile apps

**Search Pattern to Find Emojis:**
When reviewing code, search for these emoji patterns:
- `[\u{1F300}-\u{1F9FF}]` - Unicode emoji ranges
- Common emoji strings: "🗑️", "✏️", "🔔", "✅", "❌", "⏳", etc.

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

---

## Mobile Development Pattern (CRITICAL for mobile-app-agent)

**When developing mobile features with React Native + Expo:**

### Mobile App Location
**ALL mobile development happens in the `mobile/` folder:**
```
mobile/
├── app/              # Expo Router screens (file-based routing)
├── components/       # Mobile-specific components
├── lib/              # Utilities (Supabase, Firebase, Storage)
├── hooks/            # Custom React hooks
├── store/            # Zustand state management
├── constants/        # App constants
├── types/            # TypeScript types
├── docs/             # Mobile PRDs (prd-*.json, progress-*.txt)
└── assets/           # Images, fonts, icons
```

### Offline-First Architecture (MANDATORY for mobile)

**ALL mobile features MUST work offline:**

**Read Pattern:**
1. Check AsyncStorage cache first
2. If data exists and is fresh (< 5 min), use it
3. If missing/stale, fetch from Supabase
4. Update AsyncStorage cache
5. Display data to user

**Write Pattern:**
1. Optimistically update UI immediately
2. If online: Execute mutation immediately
3. If offline: Queue in AsyncStorage
4. When back online: Process queue automatically
5. Handle conflicts (last-write-wins)

**TanStack Query with Offline Support:**
```typescript
import { useQuery, useMutation } from '@tanstack/react-query';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Fetch with cache
function useTasks() {
  return useQuery({
    queryKey: ['tasks'],
    queryFn: async () => {
      // Check cache first
      const cached = await AsyncStorage.getItem('tasks');
      if (cached) {
        const { data, timestamp } = JSON.parse(cached);
        if (Date.now() - timestamp < 300000) { // 5 min
          return data;
        }
      }

      // Fetch from Supabase
      const { data } = await supabase.from('tasks').select('*');

      // Update cache
      await AsyncStorage.setItem('tasks', JSON.stringify({
        data,
        timestamp: Date.now()
      }));

      return data;
    }
  });
}
```

### Native UI Patterns (Use These, Not Web Patterns)

**Mobile-specific interactions:**
- **Pull-to-refresh** for data reload (not refresh buttons)
- **Swipe actions** for quick actions (delete, complete, etc.)
- **Bottom sheets** for options/modals (not dropdowns)
- **Tab bar** for main navigation (not sidebar)
- **Stack navigation** for drilling down (not links)
- **Long-press** for context menus (not right-click)
- **Card layouts** for list items (not tables)

**Example swipe actions:**
```typescript
import { Swipeable } from 'react-native-gesture-handler';

<Swipeable
  renderRightActions={() => (
    <View style={{ backgroundColor: 'red' }}>
      <Text>Delete</Text>
    </View>
  )}
  onSwipeableOpen={() => deleteTask(task.id)}
>
  <TaskCard task={task} />
</Swipeable>
```

### NativeWind Styling (Tailwind for React Native)

**Use Tailwind utility classes, NOT inline styles:**
```typescript
// ✅ CORRECT - NativeWind classes
<View className="flex-1 bg-white dark:bg-gray-900 p-4">
  <Text className="text-xl font-bold text-gray-900 dark:text-white">
    Tasks
  </Text>
</View>

// ❌ AVOID - Inline styles
<View style={{ flex: 1, backgroundColor: 'white', padding: 16 }}>
  <Text style={{ fontSize: 20, fontWeight: 'bold', color: '#111827' }}>
    Tasks
  </Text>
</View>
```

**Professional mobile colors:**
- Primary: `bg-blue-600` (iOS blue)
- Success: `bg-green-600`
- Warning: `bg-orange-600`
- Error: `bg-red-600`
- Background: `bg-white dark:bg-gray-900`
- Text: `text-gray-900 dark:text-white`

### Touch Targets (Accessibility)

**MINIMUM 44x44 points for all touch targets:**
```typescript
// ✅ CORRECT - 44pt minimum
<TouchableOpacity style={{ minHeight: 44, minWidth: 44 }}>
  <Trash2 size={20} />
</TouchableOpacity>

// ❌ AVOID - Too small
<TouchableOpacity style={{ height: 24, width: 24 }}>
  <Trash2 size={16} />
</TouchableOpacity>
```

### Navigation with Expo Router

**File-based routing (similar to Next.js):**
```
app/
├── (tabs)/
│   ├── index.tsx      # Home screen (/)
│   ├── tasks.tsx      # Tasks screen (/tasks)
│   ├── profile.tsx    # Profile screen (/profile)
│   └── _layout.tsx    # Tab layout
├── tasks/
│   ├── [id].tsx       # Task details (/tasks/123)
│   └── _layout.tsx    # Stack layout
└── _layout.tsx        # Root layout
```

**Type-safe navigation:**
```typescript
import { useRouter, useLocalSearchParams } from 'expo-router';

// Navigate with params
router.push('/tasks/123');

// Receive params
const { id } = useLocalSearchParams<{ id: string }>();
```

### Push Notifications (Firebase Cloud Messaging)

**Implement FCM for engagement:**
```typescript
import messaging from '@react-native-firebase/messaging';

// Request permission
const authStatus = await messaging().requestPermission();
const token = await messaging().getToken();

// Listen for messages
messaging().onMessage(async remoteMessage => {
  Alert.alert('New message', remoteMessage.notification?.body);
});

// Background messages
messaging().setBackgroundMessageHandler(async remoteMessage => {
  // Handle background message
});
```

### Performance Optimization

**Use FlatList for long lists (not ScrollView):**
```typescript
<FlatList
  data={tasks}
  renderItem={({ item }) => <TaskCard task={item} />}
  keyExtractor={item => item.id}
  onEndReached={loadMore}
  onEndReachedThreshold={0.5}
  refreshControl={
    <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
  }
/>
```

**Lazy load screens:**
- Use Expo Router's automatic lazy loading
- Implement code splitting for large features
- Use dynamic imports for expensive components

### Testing on Mobile

**Test with Expo Go (quickest):**
```bash
cd mobile
pnpm start
# Scan QR code with Expo Go app
```

**Test on iOS simulator:**
```bash
cd mobile
pnpm ios
```

**Test on Android emulator:**
```bash
cd mobile
pnpm android
```

**Test offline functionality:**
1. Load app and data
2. Enable Airplane mode
3. Navigate around (data should load from cache)
4. Create/update/delete items
5. Disable Airplane mode
6. Verify sync happens automatically

### Server Management for Mobile

**Expo server runs on port 8081. Stop ONLY Expo:**

**❌ FORBIDDEN:**
```bash
pkill -9 node
killall node
```

**✅ CORRECT:**
```bash
# Find Expo server
lsof -ti:8081
# Kill ONLY that process
kill -9 $(lsof -ti:8081)
```

### Shared Backend with Web App

**Mobile uses SAME Supabase project as web:**
- Same database schema
- Same RLS policies
- Same API endpoints
- Same types (generated from schema)

**Sync types from web:**
```bash
/flow-mobile sync
```

This generates `mobile/types/database.types.ts` from Supabase schema.

### Mobile Commit Format

**Use mobile-specific commit prefix:**
```bash
git commit -m "mobile: [description]

Co-Authored-By: NEXT MAVENS <info@nextmavens.com>"
```

**Examples:**
```bash
mobile: implement task list with offline support
mobile: add pull-to-refresh for tasks
mobile: integrate Firebase Cloud Messaging
```

### Mobile PRDs

**Mobile PRDs live in `mobile/docs/`:**
- `mobile/docs/prd-[feature].json` - Mobile PRDs
- `mobile/docs/progress-[feature].txt` - Progress tracking

**Generate mobile PRDs from web PRDs:**
```bash
flow-prd-mobile [feature-name]
```

This reads web PRD and adapts it for mobile with:
- Offline requirements
- Native UI patterns
- Touch interactions
- Push notifications

---

