# Contributing to Maven Flow

Thank you for your interest in contributing to Maven Flow! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Code Standards](#code-standards)
5. [Testing](#testing)
6. [Commit Messages](#commit-messages)
7. [Pull Requests](#pull-requests)

---

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we pledge to make participation in our project and our community a harassment-free experience for everyone.

### Our Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

---

## Getting Started

### Prerequisites

1. **Claude Code CLI v1.0.62+**
   - Required for @agent-name syntax
   - Download from: https://code.anthropic.com

2. **Bash or PowerShell**
   - Linux/macOS: Bash
   - Windows: PowerShell or CMD

3. **Git**
   - For version control

### Setting Up Development Environment

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/next-mavens-flow.git
cd next-mavens-flow

# 2. Install Maven Flow locally
./install.sh local  # Linux/macOS
# or
install.ps1 local  # Windows PowerShell

# 3. Create a feature branch
git checkout -b feature/my-feature
```

---

## Development Workflow

### Maven Flow Development Process

Maven Flow uses a structured development process:

1. **Plan Mode** - Use `/flow` command's plan mode for complex tasks
2. **Memory Creation** - Story memories created after each completion
3. **Consolidation** - Memories consolidated when PRD complete

### Making Changes

1. **Small, focused changes**
   - One logical change per commit
   - Keep commits atomic

2. **Test locally**
   - Use `/flow start` to test the flow
   - Verify quality hooks pass
   - Check memory creation

3. **Update documentation**
   - Keep README.md in sync
   - Update CHANGELOG.md
   - Document new commands/agents

### File Structure

```
next-mavens-flow/
├── .claude/
│   ├── agents/           # Specialist agent definitions
│   ├── commands/         # Claude Code commands
│   ├── skills/           # Claude Code skills
│   ├── hooks/            # Quality enforcement hooks
│   └── bin/              # Terminal scripts
├── bin/                  # User-facing terminal scripts
├── docs/                 # PRD and memory files
├── install/              # Installation helpers
└── [files in root]       # Project-level files
```

---

## Code Standards

### Zero Tolerance Rules

Maven Flow enforces strict quality standards:

1. **No 'any' Types**
   ```typescript
   // ❌ BAD
   function foo(data: any): any { return data; }

   // ✅ GOOD
   function foo<T>(data: T): T { return data; }
   ```

2. **No Gradients in CSS**
   ```css
   /* ❌ BAD */
   background: linear-gradient(to right, blue, red);

   /* ✅ GOOD */
   background: #3b82f6;
   ```

3. **No Emojis in UI**
   ```typescript
   // ❌ BAD
   return <div>Success! ✅</div>;

   // ✅ GOOD
   return <div><CheckIcon /> Success!</div>;
   ```

4. **No Relative Imports**
   ```typescript
   // ❌ BAD
   import { Foo } from './foo';
   import { Bar } from '../bar';

   // ✅ GOOD
   import { Foo } from '@features/foo/Foo';
   import { Bar } from '@shared/bar/Bar';
   ```

### TypeScript Standards

- Use strict mode: `"strict": true` in tsconfig.json
- Prefer interfaces over types for object shapes
- Use proper type guards instead of type assertions
- Document complex types with JSDoc

### Bash/PowerShell Standards

- Use `set -e` for error handling in bash
- Use `Set-StrictMode -Version Latest` in PowerShell
- Add comments for complex logic
- Use meaningful variable names

---

## Testing

### Manual Testing

```bash
# Test PRD creation
flow-prd create "test feature"

# Test conversion
flow-convert test

# Test execution
/flow start 1

# Test status
flow status
```

### Quality Hook Testing

Quality hooks run automatically. To verify:
1. Create a file with violations
2. Write/Edit should trigger hook
3. Check output for violations

### Memory System Testing

```bash
# 1. Create test PRD
flow-prd create "memory test"

# 2. Convert and verify relationships
flow-convert memory-test

# 3. Check consolidated memory exists
ls docs/consolidated-*.txt

# 4. Run flow and verify memory loading
/flow start 1

# 5. Check story memory created
ls docs/[feature]/story-*.txt
```

---

## Commit Messages

### Format

Follow the Conventional Commits specification:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat: add MCP validation hook` |
| `fix` | Bug fix | `fix: correct memory file path` |
| `docs` | Documentation only | `docs: update README with memory flow` |
| `style` | Code style changes | `style: format bash scripts` |
| `refactor` | Code refactoring | `refactor: simplify agent spawning` |
| `test` | Adding tests | `test: add memory system tests` |
| `chore` | Maintenance | `chore: update dependencies` |

### Examples

**Good:**
```
feat(memory): add consolidated memory loading

Load consolidated memories from related PRDs before spawning
agents. This provides context about existing features to
specialist agents.

Related: #42
```

**Bad:**
```
update stuff
fix bug
changes
```

---

## Pull Requests

### Before Submitting

1. **Update CHANGELOG.md**
   - Add entry under `[Unreleased]`
   - Include type, scope, and description

2. **Run quality checks**
   ```bash
   # Ensure hooks pass
   /flow start 1
   ```

3. **Test your changes**
   - Manual testing of modified features
   - Test all three phases: PRD creation, conversion, execution

4. **Update documentation**
   - README.md if user-facing
   - bin/README.md if terminal scripts changed
   - Inline code comments

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How did you test these changes?

## Checklist
- [ ] Code follows project standards
- [ ] CHANGELOG.md updated
- [ ] Documentation updated
- [ ] No 'any' types added
- [ ] No gradients added
- [ ] No emojis added to UI
- [ ] No relative imports added
```

### Review Process

1. Automated checks run on all PRs
2. Maintainer reviews manually
3. Feedback provided via comments
4. Address feedback and push commits

---

## Questions?

Feel free to open an issue with the `question` label.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Maven Flow! 🚀**
