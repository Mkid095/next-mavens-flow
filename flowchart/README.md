# Maven Flow - Interactive Flowchart

Interactive flowchart visualization explaining how Maven Flow autonomous development system works.

## About

This React application visualizes the Maven Flow workflow - an autonomous AI development system for Claude Code CLI that implements PRD stories using a comprehensive 10-step workflow with coordinated specialist agents.

## Features

- **Interactive Flowchart**: Step-by-step visualization of the Maven Flow architecture
- **Color-Coded Agents**: Visual distinction for each specialist agent:
  - 🟡 flow-iteration (Coordinator)
  - 🟢 development-agent (Foundation, pnpm, data, MCP)
  - 🔵 refactor-agent (Structure, modularize, UI)
  - 🟣 quality-agent (Type safety, ZERO tolerance checks)
  - 🔴 security-agent (Auth flow, security audit)
- **Detailed Notes**: Contextual information explaining PRD format, agents, hooks, and architecture
- **Animated Transitions**: Smooth reveal of workflow steps

## Maven Flow Architecture

### 5 Coordinated Agents

1. **flow-iteration (🟡 Yellow)** - Main coordinator
   - Picks stories from PRD
   - Delegates to Maven agents
   - Manages iteration loop

2. **development-agent (🟢 Green)** - Foundation specialist
   - Step 1: Import UI/create from scratch
   - Step 2: npm → pnpm conversion
   - Step 7: Centralized data layer
   - Step 9: MCP integrations

3. **refactor-agent (🔵 Blue)** - Architecture enforcer
   - Step 3: Feature-based folder structure
   - Step 4: Modularize components (>300 lines)
   - Step 6: Centralize UI components

4. **quality-agent (🟣 Purple)** - Quality validator
   - Step 5: Type safety, @ aliases
   - **ZERO TOLERANCE**: No 'any' types
   - **ZERO TOLERANCE**: No gradients

5. **security-agent (🔴 Red)** - Security guardian
   - Step 8: Firebase + Supabase authentication
   - Step 10: Security and error handling

### Quality Standards

**ZERO TOLERANCE Policy:**
- ❌ No 'any' types (use proper TypeScript types)
- ❌ No gradients (solid professional colors only)
- ❌ No relative imports (use @ aliases)
- ❌ No components >300 lines
- ✅ Feature-based architecture
- ✅ Centralized UI components
- ✅ Centralized data layer

## Installation

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
```

## Usage

1. Open the application in your browser
2. Click "Next" to reveal each step of the Maven Flow workflow
3. Click "Reset" to start over
4. Drag and drop nodes to reorganize the view

## Technology Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **ReactFlow** - Flowchart visualization
- **ESLint** - Code quality

## Project Links

- **Maven Flow Documentation**: See `../maven-flow/README.md`
- **Installation**: See `../maven-flow/install.sh` (Linux/macOS) or `../maven-flow/install.bat` (Windows)

## License

Maven Flow - Part of the Ralph autonomous agent pattern implementation.
