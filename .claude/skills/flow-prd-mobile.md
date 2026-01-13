---
name: flow-prd-mobile
description: Generate mobile-specific PRDs from existing web PRDs. Converts desktop features to mobile with offline support, native UI patterns, and touch-optimized interactions.
arguments:
  - name: feature-name
    description: The name of the feature to create a mobile PRD for
    required: true
---

# Flow PRD Mobile - Mobile PRD Generator

**Purpose:** Generate mobile-specific Product Requirements Documents from existing web PRDs for React Native + Expo development.

## Usage

```bash
flow-prd-mobile [feature-name]
```

**Examples:**
```bash
flow-prd-mobile task-management
flow-prd-mobile user-authentication
flow-prd-mobile inventory-system
```

## What It Does

1. **Reads existing web PRD** from `docs/prd-[feature-name].json`
2. **Analyzes web features** and acceptance criteria
3. **Adapts for mobile** with mobile-specific requirements
4. **Adds offline support** requirements
5. **Adds native UI patterns** (swipe, pull-to-refresh, etc.)
6. **Adds push notification** requirements where applicable
7. **Creates mobile PRD** at `mobile/docs/prd-[feature-name].json`

## Mobile PRD Structure

Generated mobile PRDs include:

### 1. Feature Overview
- Feature name and description
- Mobile-specific goals
- Target platforms (iOS, Android)
- Offline requirements

### 2. User Stories (Adapted for Mobile)

Each web user story is adapted with:
- **Mobile context:** How it works on mobile device
- **Touch interactions:** Tap, swipe, long-press
- **Offline behavior:** What works offline vs online
- **Native patterns:** Bottom sheets, modals, etc.

**Example transformation:**

**Web Story:**
```json
{
  "id": "US-001",
  "title": "View task list",
  "description": "User can view all their tasks in a list",
  "acceptanceCriteria": [
    "Tasks are displayed in a table",
    "User can sort by due date",
    "User can filter by status"
  ]
}
```

**Mobile Story:**
```json
{
  "id": "US-MOBILE-001",
  "title": "View task list (mobile)",
  "description": "User can view all their tasks in a scrollable list with offline support",
  "acceptanceCriteria": [
    "Tasks displayed in scrollable card list",
    "Pull-to-refresh to sync tasks",
    "Swipe left to mark complete",
    "Swipe right to delete task",
    "Tap task to view details",
    "Tasks load from cache when offline",
    "Auto-sync when back online"
  ],
  "offline": {
    "required": true,
    "behavior": "Load from AsyncStorage cache",
    "syncStrategy": "auto-on-online"
  },
  "uiPatterns": [
    "pull-to-refresh",
    "swipe-actions",
    "card-list"
  ]
}
```

### 3. Mobile-Specific Requirements

#### Offline Support
```json
"offline": {
  "required": true,
  "dataCache": {
    "storage": "AsyncStorage",
    "ttl": 300000,
    "key": "tasks-cache"
  },
  "mutationQueue": {
    "storage": "AsyncStorage",
    "key": "mutation-queue",
    "processOnConnect": true
  },
  "conflictResolution": "last-write-wins"
}
```

#### Native UI Patterns
```json
"uiPatterns": {
  "navigation": "tab-bar",
  "actions": {
    "complete": "swipe-left",
    "delete": "swipe-right",
    "edit": "tap-card",
    "details": "long-press"
  },
  "refresh": "pull-to-refresh",
  "pagination": "infinite-scroll"
}
```

#### Push Notifications
```json
"notifications": {
  "enabled": true,
  "events": [
    {
      "event": "task_assigned",
      "title": "New Task Assigned",
      "body": "You have been assigned to {task_title}",
      "tapAction": "navigate_to_task_details"
    },
    {
      "event": "task_due_soon",
      "title": "Task Due Soon",
      "body": "{task_title} is due in {hours} hours",
      "tapAction": "navigate_to_task_details"
    }
  ]
}
```

### 4. Technical Specifications

**Screen Definitions:**
```json
"screens": [
  {
    "route": "/(tabs)/tasks",
    "type": "tab-screen",
    "title": "Tasks",
    "components": ["TaskList", "TaskCard", "FilterBar"],
    "offline": true
  },
  {
    "route": "/tasks/[id]",
    "type": "modal-screen",
    "title": "Task Details",
    "components": ["TaskDetails", "CommentList", "ActionButton"],
    "offline": true
  }
]
```

**Data Models (shared with web):**
```json
"dataModels": {
  "tasks": {
    "table": "tasks",
    "sync": true,
    "offline": true,
    "relations": ["users", "comments"]
  }
}
```

**API Endpoints (shared with web):**
```json
"apiEndpoints": {
  "supabase": {
    "baseUrl": "SUPABASE_URL",
    "tables": ["tasks", "users", "comments"]
  }
}
```

### 5. Mobile Stories with Maven Steps

Each mobile story includes mavenSteps for implementation:

```json
{
  "id": "US-MOBILE-001",
  "title": "Task list with offline support",
  "mavenSteps": [1, 3, 5, 6, 9],
  "mcpTools": {
    "step1": ["supabase"],
    "step7": ["supabase"],
    "step9": ["supabase", "web-search-prime"]
  },
  "offline": {
    "required": true,
    "cacheTTL": 300000
  },
  "uiPatterns": ["pull-to-refresh", "swipe-actions"]
}
```

## Processing Steps

When you run `flow-prd-mobile [feature-name]`:

### Step 1: Read Web PRD
- Load `docs/prd-[feature-name].json`
- Parse all user stories
- Extract features and requirements

### Step 2: Analyze for Mobile
- Identify features that need mobile adaptation
- Determine offline requirements
- Plan native UI patterns
- Identify push notification opportunities

### Step 3: Generate Mobile PRD
- Create mobile-specific user stories
- Add offline requirements
- Add native UI patterns
- Add push notification specs
- Define screens and navigation
- Specify data sync strategy

### Step 4: Write Mobile PRD
- Save to `mobile/docs/prd-[feature-name].json`
- Create progress file `mobile/docs/progress-[feature-name].txt`
- Print summary of generated PRD

## Output Example

```bash
flow-prd-mobile task-management

# Reading web PRD: docs/prd-task-management.json
# Found 8 user stories
# Adapting for mobile...

# ✅ Created mobile/docs/prd-task-management.json
# ✅ Created mobile/docs/progress-task-management.txt

# Mobile PRD Summary:
# Feature: Mobile Task Management
# Stories: 8 (adapted from web)
# Offline Support: Yes
# Native Patterns: pull-to-refresh, swipe-actions, card-list
# Push Notifications: Yes (3 events)
# Screens: 5 screens defined

# Next steps:
# 1. Review mobile/docs/prd-task-management.json
# 2. Run: /flow start
# 3. Maven Flow will implement mobile stories

# Mobile PRD Location:
# 📄 mobile/docs/prd-task-management.json
# 📝 mobile/docs/progress-task-management.txt
```

## Key Differences from Web PRDs

| Aspect | Web PRD | Mobile PRD |
|--------|---------|------------|
| **UI** | Desktop/browser layout | Touch-optimized, native patterns |
| **Navigation** | Links, buttons | Tabs, stacks, gestures |
| **Offline** | Rarely required | **Always required** |
| **Data** | Fetch on demand | Cache + sync |
| **Updates** | Live/realtime | Queue + sync when online |
| **Notifications** | In-app only | Push notifications (FCM) |
| **Screen Size** | Large | Small, responsive |
| **Input** | Keyboard + mouse | Touch + keyboard |
| **Performance** | Less critical | **Critical** |
| **Battery** | Not a concern | **Optimize for battery** |

## Mobile-Specific Considerations

### 1. Offline-First Architecture
Every feature should work offline:
- Read from cache first
- Queue writes when offline
- Auto-sync when online
- Show sync status to user

### 2. Native UI Patterns
Use familiar mobile patterns:
- Pull-to-refresh for data reload
- Swipe actions for quick actions
- Bottom sheets for options
- Tab bar for main navigation
- Stack for drilling down
- Modals for focused tasks

### 3. Touch Interactions
Optimize for touch:
- Minimum 44x44pt touch targets
- Adequate spacing between targets
- Swipe gestures for common actions
- Long-press for contextual menus
- Pull gestures for refresh

### 4. Performance
Mobile performance is critical:
- Lazy load screens
- Virtualize long lists (FlatList)
- Optimize images
- Minimize re-renders
- Use caching aggressively

### 5. Battery & Network
- Minimize network requests
- Batch updates when possible
- Use push instead of poll
- Compress data
- Handle network failures gracefully

### 6. Push Notifications
Engage users with timely updates:
- Task assignments
- Due date reminders
- Status changes
- Comments/mentions
- System notifications

## Example Mobile PRD

Here's a simplified example of a generated mobile PRD:

```json
{
  "name": "Mobile Task Management",
  "description": "Mobile app for managing tasks with offline support",
  "platform": "ios, android",
  "framework": "react-native + expo",
  "offline": {
    "enabled": true,
    "strategy": "offline-first"
  },
  "stories": [
    {
      "id": "US-MOBILE-001",
      "title": "View tasks in scrollable list",
      "description": "Users can view all tasks in a scrollable card list",
      "acceptanceCriteria": [
        "Tasks displayed as cards",
        "Pull-to-refresh to sync",
        "Swipe left to complete",
        "Swipe right to delete",
        "Load from cache when offline",
        "Auto-sync when online"
      ],
      "offline": {
        "required": true,
        "cacheKey": "tasks-cache",
        "cacheTTL": 300000
      },
      "uiPatterns": ["card-list", "pull-to-refresh", "swipe-actions"],
      "mavenSteps": [1, 3, 5, 6, 9],
      "mcpTools": {
        "step1": ["supabase"],
        "step7": ["supabase"],
        "step9": ["supabase"]
      }
    }
  ],
  "notifications": {
    "enabled": true,
    "events": [
      {
        "event": "task_assigned",
        "title": "New Task",
        "body": "You've been assigned: {task_title}"
      }
    ]
  },
  "screens": [
    {
      "route": "/(tabs)/tasks",
      "title": "Tasks",
      "type": "tab-screen"
    }
  ]
}
```

## Troubleshooting

**Web PRD not found:**
- Ensure `docs/prd-[feature-name].json` exists
- Create web PRD first using `flow-prd` skill

**Mobile folder doesn't exist:**
- Run `/flow-mobile setup` first
- This creates the mobile app structure

**Error writing mobile PRD:**
- Check `mobile/docs/` folder exists
- Ensure write permissions

## Next Steps After Generating Mobile PRD

1. **Review the generated PRD:**
   ```bash
   cat mobile/docs/prd-[feature-name].json
   ```

2. **Start development:**
   ```bash
   /flow start
   ```

3. **Maven Flow will:**
   - Detect mobile PRDs in `mobile/docs/`
   - Use mobile-app-agent for implementation
   - Implement offline support
   - Test with Expo Go
   - Commit changes

---

**flow-prd-mobile: Convert web features to mobile with offline support and native patterns**
