---
description: Update Maven Flow from GitHub and sync with installations
argument-hint: [check | sync | force] | help
---

# Maven Flow Updater

Fetch latest changes from GitHub and sync with your Maven Flow installations.

## Commands

### Check for updates
```
/flow-update check
```

Checks if there are updates available from the GitHub repository.

**What happens:**
1. Checks current git status
2. Fetches latest changes from remote
3. Compares local and remote commits
4. Reports if updates are available

**Example output:**
```
Checking for updates...
Connected to GitHub
Fetched latest changes
Status: Your repository is up to date
```

Or:
```
Checking for updates...
Connected to GitHub
Fetched latest changes
Status: Updates available!
  - 3 new commits ahead
  - Last update: Add memory system to flow.md

Run: /flow-update sync to apply updates
```

### Sync updates
```
/flow-update sync
```

Fetches changes from GitHub and syncs with your global installation.

**What happens:**
1. Runs `git pull` to fetch latest changes
2. Detects global installation at ~/.claude/
3. Copies updated files to installation locations:
   - Agents (~/.claude/agents/)
   - Commands (~/.claude/commands/)
   - Skills (~/.claude/skills/)
   - Hooks (~/.claude/hooks/)
   - Shell scripts (~/.claude/bin/)
4. Preserves user configurations (settings.local.json, custom modifications)
5. Reports what was updated

**Example output:**
```
Syncing Maven Flow updates...
Fetched from GitHub
3 new commits pulled

Syncing to global installation...
  Updated: flow.md (added memory system)
  Updated: flow-prd.md (enhanced with MCP detection)
  Updated: post-tool-use-quality.sh (fixed new file handling)
  Updated: bin/flow.sh (improved error handling)

Sync complete!
```

### Force update
```
/flow-update force
```

Forces a sync even if no updates are detected. Useful for:
- Reinstalling after manual changes
- Fixing corrupted installations
- Ensuring all files are up to date

**Example output:**
```
Force syncing Maven Flow...
Running forced sync
All files reinstalled from current repository
Sync complete!
```

### Help
```
/flow-update help
```

Displays help information about updating Maven Flow.

---

## How It Works

### Update Process

```
GitHub Repository (next-mavens-flow)
    git pull
Local Repository
    Copy files
Global Installation (~/.claude/)
```

### What Gets Updated

| File Type | Global Location |
|-----------|-----------------|
| Agents | ~/.claude/agents/ |
| Commands | ~/.claude/commands/ |
| Skills | ~/.claude/skills/ |
| Hooks | ~/.claude/hooks/ |
| Shell Scripts | ~/.claude/bin/ |

### What Gets Preserved

**User configurations that are preserved:**
- `settings.local.json` - Your local settings
- Custom modifications to `settings.json` (will ask before overwriting)
- Custom hooks you've added (won't be deleted)
- Your PRD files in `docs/`
- Your project code and files

**Safe operations:**
- Uses `cp -n` for new files (won't overwrite existing)
- Uses `cp -f` for updates (updates to latest version)
- Never deletes files you've created
- Never deletes your projects or code

---

## Installation Detection

The updater detects installations automatically:

**Global Installation:**
```
Checks: ~/.claude/ exists
If yes: Syncs to ~/.claude/
```

---

## File Sync Strategy

### Agents and Commands (New or Modified)
- **New files:** Copy to installation (cp -n)
- **Modified files:** Update in installation (cp -f)
- **Preserved:** Your custom agents/commands (if same name exists)

### Hooks
- **Always update:** Hooks are updated to latest version
- **Safe:** Hooks are scripts, no user data to lose

### Settings
- **settings.json:** Only updates if it's the stock version
- **settings.local.json:** NEVER touched (your settings)
- **User modifications:** Detected and prompted before overwriting

### Shell Scripts
- **Always regenerate:** Scripts are recreated from current code
- **Location:** ~/.claude/bin/ folder

---

## Common Workflows

### Update to Latest Version
```bash
# Check if updates are available
/flow-update check

# If available, sync updates
/flow-update sync
```

### Force Reinstall
```bash
# Force sync all files from current repo
/flow-update force
```

### Update After Manual Changes
```bash
# If you manually modified files and want to reset
git reset --hard HEAD
/flow-update sync
```

---

## Troubleshooting

**Updates not found:**
- Ensure you're in the Maven Flow repository directory
- Run `git remote -v` to check GitHub connection
- Run `git branch` to verify you're on main branch

**Sync fails:**
- Check write permissions to ~/.claude/
- Close any Claude Code sessions using the files
- Run `/flow-update force` to retry

**Settings reset:**
- Your settings are preserved in `settings.local.json`
- If settings.json was overwritten, check `~/.claude/settings.json.backup`

**Hooks still failing:**
- After update, hooks are updated to latest versions
- Run `claude --debug` to see hook execution details
- Check hook paths use `$CLAUDE_PROJECT_DIR`

---

## Git Repository

**Default repository:** https://github.com/your-repo/next-mavens-flow

**Check current remote:**
```bash
git remote -v
```

**Add remote if missing:**
```bash
git remote add origin https://github.com/your-repo/next-mavens-flow.git
```

---

## Best Practices

1. **Check before syncing:** Run `/flow-update check` first to see what's available
2. **Commit your work:** Commit or stash your changes before pulling
3. **Review updates:** After sync, review what changed
4. **Test after update:** Run `/flow status` to verify everything works

---

*Maven Flow Updater - Keep your installation synchronized with the latest improvements*
