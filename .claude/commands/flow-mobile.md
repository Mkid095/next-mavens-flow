---
description: Mobile development setup and workflow for Maven Flow
argument-hint: setup | status | sync | help
---

# Maven Flow - Mobile Development

Mobile app development workflow using React Native + Expo with shared Supabase backend.

## Overview

**Architecture:** Monorepo-style setup where the mobile app lives alongside the web app in the same repository.

**Mobile Location:** `mobile/` folder in the project root

**Shared Backend:** Uses the same Supabase project as the web app

**Tech Stack:**
- Frontend: React Native + Expo
- Auth: Firebase Authentication (synced with Supabase)
- Backend: Supabase (Postgres + Storage + Edge Functions)
- Styling: NativeWind (Tailwind for React Native)
- Routing: Expo Router (file-based routing)
- State: TanStack Query + Zustand
- Push: Firebase Cloud Messaging
- Offline: AsyncStorage with sync when online

## Commands

### Setup mobile environment

```
/flow-mobile setup
```

**Creates a complete React Native + Expo mobile app** in the `mobile/` folder with:

**1. Project Structure:**
```
mobile/
├── app/                    # Expo Router (file-based routing)
│   ├── (tabs)/            # Tab navigation screens
│   │   ├── index.tsx      # Home screen
│   │   ├── profile.tsx    # Profile screen
│   │   └── _layout.tsx    # Tab layout
│   ├── auth/              # Auth screens
│   │   ├── sign-in.tsx
│   │   ├── sign-up.tsx
│   │   └── _layout.tsx
│   └── _layout.tsx        # Root layout
├── components/            # Shared components
├── lib/                   # Utilities
│   ├── supabase/         # Supabase client
│   ├── firebase/         # Firebase config
│   └── storage/          # AsyncStorage + sync logic
├── hooks/                 # Custom hooks
│   ├── useAuth.ts        # Auth hook
│   ├── useOffline.ts     # Offline sync hook
│   └── useQuery.ts       # TanStack Query hooks
├── store/                 # Zustand store
├── constants/             # App constants
├── types/                 # TypeScript types
├── assets/                # Images, fonts
├── docs/                  # Mobile PRDs
│   ├── prd-*.json        # Mobile-specific PRDs
│   └── progress-*.txt    # Mobile progress files
└── package.json
```

**2. Dependencies Installed:**
```json
{
  "dependencies": {
    "expo": "~51.0.0",
    "expo-router": "~3.5.0",
    "nativewind": "^2.0.11",
    "react": "18.2.0",
    "react-native": "0.74.0",
    "@tanstack/react-query": "^5.0.0",
    "zustand": "^4.5.0",
    "@react-native-firebase/app": "^19.0.0",
    "@react-native-firebase/auth": "^19.0.0",
    "@react-native-firebase/messaging": "^19.0.0",
    "@supabase/supabase-js": "^2.39.0",
    " AsyncStorage": "@react-native-async-storage/async-storage"
  },
  "devDependencies": {
    "tailwindcss": "3.3.2",
    "@types/react": "~18.2.45"
  }
}
```

**3. Configuration Files:**
- `app.json` - Expo config
- `tailwind.config.js` - NativeWind config
- `tsconfig.json` - TypeScript config
- `babel.config.js` - Babel config for NativeWind
- `.env` - Environment variables (shared from web app)

**4. Supabase Integration:**
- Uses the same Supabase URL and anon key from web app
- Shares database schema and types
- Uses same RLS policies
- Syncs types from database

**5. Firebase Integration:**
- Firebase Authentication (synced with Supabase Auth)
- Firebase Cloud Messaging for push notifications
- Config files: `firebase.json`, `GoogleService-Info.plist`, `GoogleServices.plist`

**6. Offline Support:**
- AsyncStorage for local data
- Network status detection
- Automatic sync when online
- Conflict resolution strategy
- Queue for offline mutations

**Setup Process:**
1. Creates `mobile/` folder structure
2. Installs all dependencies
3. Configures Expo Router with file-based routing
4. Sets up NativeWind (Tailwind)
5. Configures Supabase client (shares web app credentials)
6. Configures Firebase Auth + FCM
7. Sets up TanStack Query for data fetching
8. Sets up Zustand for global state
9. Implements offline storage + sync logic
10. Creates base screens (Home, Profile, Auth)
11. Configures TypeScript with shared types
12. Sets up EAS Build for deployment

**Example usage:**
```bash
# From project root
/flow-mobile setup

# The command will:
# 1. Detect existing Supabase config from web app
# 2. Create mobile/ folder with Expo app
# 3. Install all dependencies
# 4. Configure everything automatically
# 5. Create base screens and navigation
# 6. Set up offline sync
# 7. Print setup summary
```

---

### Check mobile status

```
/flow-mobile status
```

Shows the current status of the mobile app:

**Output includes:**
- Mobile folder existence
- Expo configuration status
- Dependencies installation status
- Supabase connection status
- Firebase configuration status
- Mobile PRDs (from `mobile/docs/prd-*.json`)
- Progress on mobile stories
- Offline sync status
- Build configuration (EAS)

**Example output:**
```
Maven Flow Mobile Status

✅ Mobile folder exists: mobile/
✅ Expo configured: app.json
✅ Dependencies installed: 45/45
✅ Supabase connected: [PROJECT_URL]
✅ Firebase configured: Auth + FCM
✅ Offline sync: Enabled

Mobile PRDs:
  ✓ prd-mobile-auth.json (3/3 complete)
  ○ prd-mobile-tasks.json (1/5 complete)
  ○ prd-mobile-profile.json (0/4 complete)

Current Focus: prd-mobile-tasks.json

Recent Progress:
  [2025-01-12] Created task list screen with offline support
```

---

### Sync mobile and web

```
/flow-mobile sync
```

Synchronizes types and configuration between web and mobile apps:

**What gets synced:**
1. **Database Types** - Generate TypeScript types from Supabase schema
2. **API Endpoints** - Sync API route definitions
3. **Environment Variables** - Ensure mobile has same env vars as web
4. **Shared Components** - Optionally share UI components
5. **Auth Configuration** - Sync auth providers and settings

**Sync Process:**
1. Reads Supabase schema using Supabase MCP
2. Generates TypeScript types to `mobile/types/database.types.ts`
3. Copies env vars from web app `.env` to mobile `.env`
4. Updates API endpoint configurations
5. Validates auth configuration matches
6. Reports sync status

**Example:**
```bash
/flow-mobile sync

# Output:
# Syncing web → mobile...
# ✅ Database types synced (245 types)
# ✅ Environment variables synced (12 vars)
# ✅ API endpoints synced (8 endpoints)
# ✅ Auth configuration validated
# Sync complete!
```

---

### Help

```
/flow-mobile help
```

Displays comprehensive help information about mobile development.

---

# Mobile Development Workflow

## Phase 1: Setup

**Step 1: Setup mobile environment**
```bash
/flow-mobile setup
```

This creates the complete mobile app structure in `mobile/` folder.

**Step 2: Sync with web app**
```bash
/flow-mobile sync
```

This ensures mobile has the latest types and config from web app.

---

## Phase 2: Plan Mobile Features

**Create mobile-specific PRDs:**

Use the `flow-prd-mobile` skill to convert web PRDs to mobile:

```bash
# Create mobile PRD from existing web PRD
flow-prd-mobile task-management
```

This creates `mobile/docs/prd-task-management.json` with mobile-specific requirements:
- Same backend (Supabase)
- Mobile-specific UI patterns
- Offline-first architecture
- Touch-optimized interactions
- Native navigation patterns

**Mobile PRD differences from web:**
- Includes offline requirements
- Specifies mobile-specific UI patterns (swipe, pull-to-refresh)
- Includes push notification requirements
- Specifies data sync strategies
- Includes performance optimizations

---

## Phase 3: Develop Mobile Features

**Use Maven Flow with mobile PRDs:**

```bash
# Develop mobile features
/flow start
```

The flow will:
1. Detect mobile PRDs in `mobile/docs/prd-*.json`
2. Process mobile stories with mobile-app-agent
3. Implement offline capabilities
4. Test with Expo Go
5. Commit changes

**Mobile-specific agents:**
- **mobile-app-agent** - Handles mobile development (Step 1, 2, 7, 9)
- **design-agent** - Professional mobile UI (Step 11)
- **Other agents** - Same as web development

---

## Phase 4: Test Mobile App

**Test with Expo Go:**
```bash
cd mobile
pnpm start
# Scan QR code with Expo Go app
```

**Test on device/simulator:**
```bash
cd mobile
pnpm ios     # iOS simulator
pnpm android # Android emulator
```

**Use testing-agent for mobile:**
```bash
/flow test mobile-auth
```

---

## Phase 5: Build and Deploy

**Build with EAS:**
```bash
cd mobile
eas build --platform ios
eas build --platform android
```

**Submit to stores:**
```bash
eas submit --platform ios
eas submit --platform android
```

---

# Mobile App Architecture

## Tech Stack Details

### Frontend Framework
**React Native + Expo**
- Cross-platform (iOS + Android)
- Expo SDK 51
- Over-the-air updates

### Styling
**NativeWind (Tailwind CSS for React Native)**
- Same utility classes as web
- Native performance
- Responsive design
- Dark mode support

### Routing
**Expo Router (File-based)**
- Similar to Next.js App Router
- Type-safe navigation
- Deep linking support
- Tab navigation
- Stack navigation

### State Management
**TanStack Query + Zustand**
- TanStack Query: Server state, caching, retries
- Zustand: Client state, global store
- Offline mutations queue

### Authentication
**Firebase Auth (supabase auth synced)**
- Email/password
- Google OAuth
- Phone auth
- Synced with Supabase auth via triggers

### Backend
**Supabase (Shared with web)**
- Same database
- Same RLS policies
- Same Edge Functions
- Real-time subscriptions

### Push Notifications
**Firebase Cloud Messaging**
- Push notifications
- Background messages
- Notification channels
- Topic subscriptions

### Offline Support
**AsyncStorage + Sync Logic**
- Local data persistence
- Network detection
- Automatic sync when online
- Conflict resolution
- Mutation queue

## Offline-First Architecture

### Data Sync Strategy

**Read Operations (Offline-First):**
1. Check AsyncStorage first
2. If data exists and fresh, use it
3. If missing or stale, fetch from Supabase
4. Update AsyncStorage with fresh data
5. Update UI

**Write Operations (Offline-First):**
1. Optimistically update UI
2. Queue mutation in AsyncStorage
3. If online: Execute immediately
4. If offline: Store in queue
5. When back online: Process queue
6. Handle conflicts if any

### Conflict Resolution

**Last-write-wins strategy:**
- Each mutation has timestamp
- Server timestamps override client if newer
- Client can request manual conflict resolution
- Show conflict UI to user when needed

### Network Detection

**Always know online status:**
```typescript
import { useNetInfo } from '@react-native-community/netinfo';

const netInfo = useNetInfo();
const isOnline = netInfo.isConnected === true;
```

**Sync when coming online:**
- Detect network change
- Process pending mutations
- Refresh data from server
- Update UI

---

# Best Practices

## Mobile UI Patterns

**Use native patterns:**
- Pull-to-refresh for data reload
- Swipe actions for list items
- Bottom sheets for options
- Tab bar for navigation
- Stack navigation for drilling down

**Touch targets:**
- Minimum 44x44 points (Apple)
- 48x48 dp (Android)
- Adequate spacing between targets

**Performance:**
- Lazy load screens
- Use React.memo appropriately
- Optimize images
- Use FlatList instead of ScrollView for lists
- Implement pagination

## Mobile PRD Creation

**Use flow-prd-mobile skill:**
```bash
flow-prd-mobile [feature-name]
```

**What it does:**
1. Reads existing web PRD for the feature
2. Adapts it for mobile
3. Adds offline requirements
4. Adds mobile UI patterns
5. Adds push notification requirements
6. Creates `mobile/docs/prd-[feature].json`

**Example mobile PRD structure:**
```json
{
  "name": "Mobile Task Management",
  "description": "Mobile app for task management with offline support",
  "features": [
    {
      "id": "MOBILE-001",
      "title": "Task List with Offline Support",
      "description": "View and manage tasks offline",
      "acceptanceCriteria": [
        "Tasks load from local storage when offline",
        "Pull-to-refresh syncs with server",
        "Swipe left to complete task",
        "Swipe right to delete task",
        "Push notification for task assignments"
      ],
      "offline": {
        "required": true,
        "syncStrategy": "auto-on-online",
        "conflictResolution": "last-write-wins"
      }
    }
  ]
}
```

---

# Troubleshooting

**Mobile folder not found:**
- Run `/flow-mobile setup` first

**Expo not starting:**
- Check port 8081 is available
- Stop only the Expo process, not all Node processes
- Use `lsof -ti:8081 | xargs kill -9`

**Supabase connection failed:**
- Run `/flow-mobile sync` to update config
- Check `.env` file has correct values
- Verify Supabase project is active

**Firebase not configured:**
- Add `GoogleService-Info.plist` (iOS)
- Add `google-services.json` (Android)
- Run `firebase login` to authenticate

**Offline sync not working:**
- Check AsyncStorage permissions
- Verify network detection is working
- Check mutation queue in AsyncStorage
- Review sync logs

---

*Mobile Development for Maven Flow - React Native + Expo with shared Supabase backend*
