#!/usr/bin/env node
/**
 * Pre-Task Hook: Validates PRD files and MCP availability before spawning Maven Flow agents
 *
 * This hook runs before Task tool calls to Maven Flow specialist agents.
 * It validates:
 * 1. PRD files exist in docs/ directory
 * 2. Required MCPs (from prompt) are available in the environment
 *
 * Agents validated:
 * - development-agent
 * - refactor-agent
 * - quality-agent
 * - security-agent
 * - design-agent
 *
 * Usage: Called by Claude Code via PreToolUse hook in flow.md
 *
 * Exit codes:
 * - 0: Allow the tool (validation passed)
 * - 3: Block the tool (validation failed)
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Maven Flow specialist agent types that require validation
const MAVEN_FLOW_AGENTS = [
  'development-agent',
  'refactor-agent',
  'quality-agent',
  'security-agent',
  'design-agent'
];

// Common MCP server names (lowercase for matching)
const COMMON_MCPS = [
  'supabase',
  'chrome-devtools',
  'web-search-prime',
  'web-reader',
  'playwright',
  'wrangler',
  'vercel',
  'figma',
  '4-5v-mcp',
  'memory-keeper',
  'filesystem',
  'sequential-thinking'
];

/**
 * Extract MCP names from agent prompt
 * Looks for patterns like "Use these MCPs: supabase, chrome-devtools"
 */
function extractMCPsFromPrompt(prompt) {
  if (!prompt) return new Set();

  const mcps = new Set();
  const lowerPrompt = prompt.toLowerCase();

  // Pattern 1: "Use these MCPs: supabase, chrome-devtools"
  const useMCPsMatch = lowerPrompt.match(/use these mcps?:\s*([^\n]+)/i);
  if (useMCPsMatch) {
    const names = useMCPsMatch[1]
      .split(/[,;\s]+/)
      .map(n => n.trim().toLowerCase())
      .filter(n => COMMON_MCPS.includes(n));
    names.forEach(n => mcps.add(n));
  }

  // Pattern 2: Direct mentions of "supabase MCP", "chrome-devtools MCP", etc.
  for (const mcp of COMMON_MCPS) {
    const regex = new RegExp(`\\b${mcp.replace(/-/g, '-')}\\s+mcp\\b`, 'i');
    if (regex.test(lowerPrompt)) {
      mcps.add(mcp);
    }
  }

  // Pattern 3: "required MCPs: ..." or "MCPs required: ..."
  const requiredMCPsMatch = lowerPrompt.match(/(?:required|mcp.*?required):\s*([^\n]+)/i);
  if (requiredMCPsMatch) {
    const names = requiredMCPsMatch[1]
      .split(/[,;\s]+/)
      .map(n => n.trim().toLowerCase())
      .filter(n => COMMON_MCPS.includes(n));
    names.forEach(n => mcps.add(n));
  }

  return mcps;
}

/**
 * Get available MCPs from Claude Code settings
 * Checks multiple possible settings file locations
 */
function getAvailableMCPs(workingDir) {
  const availableMCPs = new Set();

  // Possible settings file locations
  const possibleSettingsPaths = [
    path.join(workingDir, '.claude', 'settings.json'),
    path.join(os.homedir(), '.claude', 'settings.json'),
    path.join(os.homedir(), '.config', 'claude-code', 'settings.json'),
    path.join(os.homedir(), '.config', 'claude', 'settings.json'),
    path.join(process.env.XDG_CONFIG_HOME || '', 'claude-code', 'settings.json')
  ].filter(p => fs.existsSync(p));

  for (const settingsPath of possibleSettingsPaths) {
    try {
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'));

      // Check for mcpServers key
      if (settings.mcpServers) {
        Object.keys(settings.mcpServers).forEach(mcpName => {
          availableMCPs.add(mcpName.toLowerCase());
        });
      }

      // Check for mcp key (alternative format)
      if (settings.mcp) {
        Object.keys(settings.mcp).forEach(mcpName => {
          availableMCPs.add(mcpName.toLowerCase());
        });
      }

      // Check for enabledMCPs key
      if (settings.enabledMCPs) {
        settings.enabledMCPs.forEach(mcpName => {
          availableMCPs.add(mcpName.toLowerCase());
        });
      }
    } catch (e) {
      // Continue to next path on error
    }
  }

  // Check CLAUDE_AVAILABLE_TOOLS env var (set by Claude Code)
  if (process.env.CLAUDE_AVAILABLE_TOOLS) {
    try {
      const tools = JSON.parse(process.env.CLAUDE_AVAILABLE_TOOLS);
      // Tool names might be like "mcp__supabase__query"
      tools.forEach(tool => {
        const match = tool.match(/mcp__([^_]+)(?:__|$)/);
        if (match) {
          availableMCPs.add(match[1].toLowerCase());
        }
      });
    } catch (e) {
      // Ignore parse errors
    }
  }

  return availableMCPs;
}

function main() {
  try {
    // Read JSON from STDIN (Claude Code hooks pass input via stdin)
    const stdinBuffer = fs.readFileSync(0, 'utf-8');
    let input;

    if (stdinBuffer.trim()) {
      try {
        input = JSON.parse(stdinBuffer);
      } catch (parseError) {
        // Input is not valid JSON, exit silently
        process.exit(0);
      }
    } else {
      // No input received, exit silently
      process.exit(0);
    }

    // Extract tool_input from the hook JSON structure
    const toolInput = input.tool_input || {};

    // Only validate Maven Flow agent spawns
    if (!toolInput.subagent_type || !MAVEN_FLOW_AGENTS.includes(toolInput.subagent_type)) {
      process.exit(0);
    }

    // Get working directory from Claude or use current directory
    const workingDir = input.cwd || process.cwd();

    // ============================================================================
    // VALIDATION 1: Check if docs/ directory exists
    // ============================================================================
    const docsDir = path.join(workingDir, 'docs');
    if (!fs.existsSync(docsDir)) {
      console.error('\n❌ PRD Validation Failed\n');
      console.error('No docs/ directory found.');
      console.error('Create a PRD first using the flow-prd skill.\n');
      process.exit(3); // Exit code 3 tells Claude to block the tool
    }

    // ============================================================================
    // VALIDATION 2: Check if any PRD files exist
    // ============================================================================
    const prdFiles = fs.readdirSync(docsDir)
      .filter(f => f.startsWith('prd-') && f.endsWith('.json'));

    if (prdFiles.length === 0) {
      console.error('\n❌ PRD Validation Failed\n');
      console.error('No PRD files found in docs/.');
      console.error('Create a PRD first using the flow-prd skill.\n');
      process.exit(3); // Exit code 3 tells Claude to block the tool
    }

    // ============================================================================
    // VALIDATION 3: Check MCP availability
    // ============================================================================
    const prompt = toolInput.prompt || '';
    const requiredMCPs = extractMCPsFromPrompt(prompt);

    if (requiredMCPs.size > 0) {
      const availableMCPs = getAvailableMCPs(workingDir);
      const missingMCPs = [...requiredMCPs].filter(mcp => !availableMCPs.has(mcp));

      if (missingMCPs.length > 0) {
        console.error('\n❌ MCP Validation Failed\n');
        console.error(`The following required MCPs are not available:`);
        missingMCPs.forEach(mcp => {
          console.error(`  - ${mcp}`);
        });
        console.error(`\nAvailable MCPs in this environment:`);
        if (availableMCPs.size === 0) {
          console.error(`  (None detected)`);
        } else {
          [...availableMCPs].sort().forEach(mcp => {
            console.error(`  ✓ ${mcp}`);
          });
        }
        console.error(`\nTo fix:`);
        console.error(`  1. Configure the missing MCP servers in Claude Code settings`);
        console.error(`  2. Or update the PRD mcpTools to remove the missing MCP`);
        console.error(`  3. Or modify the prompt to not require that MCP\n`);
        process.exit(3); // Exit code 3 tells Claude to block the tool
      }

      // Log successful MCP validation if DEBUG is set
      if (process.env.DEBUG) {
        console.error(`✓ MCP validation passed: ${[...requiredMCPs].join(', ')}`);
      }
    }

    // All validations passed
    process.exit(0);

  } catch (error) {
    // Log error but don't block execution
    // This prevents the hook from breaking the flow if something unexpected happens
    if (process.env.DEBUG) {
      console.error('Hook error:', error.message);
    }
    process.exit(0);
  }
}

main();
