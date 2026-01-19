# Maven Flow - Installation & Sync

## Quick Start

### Windows (PowerShell)

```powershell
# Install globally
.\bin\flow-install-global.ps1

# Restart terminal, then use:
flow status
flow start
```

### Linux/macOS (Bash)

```bash
# Install globally
./bin/flow-install-global.sh

# Reload shell, then use:
flow status
flow start
```

## Syncing Changes

When you make changes to the flow scripts in the project, you need to sync them with the global installation.

### Check Sync Status

```powershell
# Windows
flow-sync status

# Linux/macOS
./flow-sync.sh status
```

### Pull from Global to Project

Use this when global has updates (e.g., after running `flow-update`):

```powershell
# Windows
flow-sync pull

# Linux/macOS
./flow-sync.sh pull
```

### Push from Project to Global

Use this when you've made changes in the project:

```powershell
# Windows
flow-sync push

# Linux/macOS
./flow-sync.sh push
```

### Force Sync

Force overwrite regardless of file timestamps:

```powershell
# Windows
flow-sync force

# Linux/macOS
./flow-sync.sh --force
```

## Auto-Detection

Running `flow-sync` without arguments auto-detects which direction to sync:

- If global files are newer → `pull` mode
- If project files are newer → `push` mode
- If same → `status` mode

```powershell
# Auto-detect (Windows)
flow-sync

# Auto-detect (Linux/macOS)
./flow-sync.sh
```

## Files That Sync

- `flow.ps1` / `flow.sh` - Main orchestrator
- `flow-prd.ps1` / `flow-prd.sh` - PRD generator
- `flow-convert.ps1` / `flow-convert.sh` - PRD to JSON converter
- `flow-update.ps1` / `flow-update.sh` - Update manager

## Installation Locations

### Windows

```
~/.claude/
├── agents/          # Agent definitions
├── commands/        # Command definitions
├── skills/          # Skill definitions
├── hooks/           # Hooks
└── bin/             # Executable scripts
    ├── flow.ps1
    ├── flow-prd.ps1
    └── ...
```

### Linux/macOS

```
~/.claude/
├── agents/          # Agent definitions
├── commands/        # Command definitions
├── skills/          # Skill definitions
├── hooks/           # Hooks
└── bin/             # Executable scripts
    ├── flow.sh
    ├── flow-prd.sh
    └── ...
```

## Updating Maven Flow

To get the latest version from the repository:

```powershell
# Windows
flow-update

# Linux/macOS
./flow-update.sh
```

Then run `flow-sync pull` to update your project.

## Troubleshooting

### Command Not Found

Make sure:
1. Installation was successful
2. Terminal has been restarted
3. `~/.claude/bin` is in your PATH

```powershell
# Check PATH (Windows)
$env:Path -split ';' | Select-String ".claude"

# Check PATH (Linux/macOS)
echo $PATH | grep -o ".claude/bin"
```

### Sync Conflicts

If files are out of sync and you're not sure which is newer:

1. Check status: `flow-sync status`
2. Review file timestamps
3. Choose appropriate direction: `flow-sync pull` or `flow-sync push`

### Force Reinstall

To completely reinstall:

```powershell
# Windows
.\bin\flow-install-global.ps1

# Linux/macOS
./bin/flow-install-global.sh
```

## Development Workflow

1. Make changes in `next-mavens-flow/bin/`
2. Test changes locally
3. Push to global: `flow-sync push`
4. Commit and push to git
5. Other users pull updates: `flow-update` → `flow-sync pull`
