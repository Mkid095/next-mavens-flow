#!/usr/bin/env node
/**
 * Automatic Agent Selector - Maps Violations to Specialist Agents
 *
 * Automatically determines which Maven Flow agent should handle
 * specific violations or tasks.
 *
 * Usage:
 *   const selector = require('./agent-selector.js');
 *   const agent = selector.mapViolationToAgent('any_type');
 *   const command = selector.getAgentCommand('quality-agent');
 *
 * @module agent-selector
 */

const path = require('path');

/**
 * Violation to agent mapping
 */
const VIOLATION_AGENT_MAP = {
  // Type safety violations
  any_type: 'quality-agent',
  type_error: 'quality-agent',
  missing_type: 'quality-agent',
  type_assertion: 'quality-agent',

  // Design violations
  gradient: 'quality-agent',
  emoji: 'quality-agent',
  ui_style: 'design-agent',

  // Import violations
  relative_import: 'refactor-agent',
  import_order: 'refactor-agent',
  circular_import: 'refactor-agent',

  // Architecture violations
  large_component: 'refactor-agent',
  duplicate_ui: 'refactor-agent',
  feature_boundary: 'refactor-agent',
  cross_feature_import: 'refactor-agent',

  // Data layer violations
  direct_api_call: 'refactor-agent',
  fetch_in_component: 'development-agent',
  missing_data_layer: 'development-agent',

  // Security violations
  exposed_secret: 'security-agent',
  auth_change: 'security-agent',
  auth_vulnerability: 'security-agent',
  sql_injection: 'security-agent',
  xss_vulnerability: 'security-agent',
  csrf_vulnerability: 'security-agent',

  // Environment violations
  env_change: 'quality-agent',
  config_change: 'quality-agent',

  // Testing violations
  missing_test: 'testing-agent',
  test_failure: 'testing-agent',
  coverage_low: 'testing-agent',

  // Mobile violations
  mobile_layout: 'design-agent',
  touch_target: 'design-agent',
  responsive: 'mobile-app-agent'
};

/**
 * Agent descriptions and capabilities
 */
const AGENT_INFO = {
  'development-agent': {
    name: 'Development Agent',
    description: 'Handles feature implementation from scratch',
    capabilities: [
      'Step 1: Foundation/UI implementation',
      'Step 2: Package manager changes',
      'Step 7: Data layer implementation',
      'Step 9: MCP integration'
    ],
    typicalViolations: ['direct_api_call', 'fetch_in_component', 'missing_data_layer']
  },
  'refactor-agent': {
    name: 'Refactor Agent',
    description: 'Handles code restructuring and modularization',
    capabilities: [
      'Step 3: Feature structure changes',
      'Step 4: Component modularization (>300 lines)',
      'Step 6: UI centralization (@shared/ui)'
    ],
    typicalViolations: ['relative_import', 'large_component', 'duplicate_ui', 'feature_boundary']
  },
  'quality-agent': {
    name: 'Quality Agent',
    description: 'Enforces type safety and code quality standards',
    capabilities: [
      'Step 5: Type safety enforcement (no any types)',
      'Code quality validation',
      'Zero tolerance policy enforcement'
    ],
    typicalViolations: ['any_type', 'gradient', 'emoji', 'env_change']
  },
  'security-agent': {
    name: 'Security Agent',
    description: 'Handles authentication, authorization, and security',
    capabilities: [
      'Step 8: Authentication/authorization integration',
      'Step 10: Security hardening & error handling',
      'Security audits and vulnerability scanning'
    ],
    typicalViolations: ['exposed_secret', 'auth_change', 'auth_vulnerability', 'sql_injection', 'xss_vulnerability']
  },
  'design-agent': {
    name: 'Design Agent',
    description: 'Applies professional UI/UX design principles',
    capabilities: [
      'Step 11: Professional mobile UI/UX design',
      'Apple design methodology application',
      'Visual design improvements'
    ],
    typicalViolations: ['ui_style', 'mobile_layout', 'touch_target']
  },
  'mobile-app-agent': {
    name: 'Mobile App Agent',
    description: 'Specializes in React Native + Expo mobile development',
    capabilities: [
      'Mobile feature implementation',
      'Expo/React Native development',
      'Offline support with NativeWind'
    ],
    typicalViolations: ['responsive', 'mobile_layout']
  },
  'testing-agent': {
    name: 'Testing Agent',
    description: 'Handles comprehensive application testing',
    capabilities: [
      'End-to-end testing',
      'Browser automation testing',
      'Console log reading',
      'User flow verification'
    ],
    typicalViolations: ['missing_test', 'test_failure', 'coverage_low']
  }
};

/**
 * Map a violation type to the appropriate agent
 *
 * @param {string} violationType - Type of violation
 * @returns {string|null} Agent name or null if not found
 */
function mapViolationToAgent(violationType) {
  return VIOLATION_AGENT_MAP[violationType] || null;
}

/**
 * Map multiple violations to agents
 *
 * @param {string[]} violationTypes - Array of violation types
 * @returns {object} Agent frequency map
 */
function mapViolationsToAgents(violationTypes) {
  const agentMap = {};

  for (const violation of violationTypes) {
    const agent = mapViolationToAgent(violation);
    if (agent) {
      agentMap[agent] = (agentMap[agent] || 0) + 1;
    }
  }

  return agentMap;
}

/**
 * Select the best agent for a set of violations
 *
 * @param {string[]} violationTypes - Array of violation types
 * @returns {string} Selected agent name
 */
function selectAgent(violationTypes) {
  const agentMap = mapViolationsToAgents(violationTypes);

  // Priority order for agents when there are multiple violations
  const priority = [
    'security-agent',      // Security first
    'quality-agent',       // Then quality (blocking)
    'testing-agent',       // Then testing
    'refactor-agent',      // Then refactoring
    'development-agent',   // Then new development
    'design-agent',        // Then design
    'mobile-app-agent'     // Then mobile
  ];

  // Find highest priority agent with violations
  for (const agent of priority) {
    if (agentMap[agent]) {
      return agent;
    }
  }

  // Default to quality-agent if no specific mapping
  return 'quality-agent';
}

/**
 * Get agent information
 *
 * @param {string} agentName - Name of the agent
 * @returns {object|null} Agent info or null if not found
 */
function getAgentInfo(agentName) {
  return AGENT_INFO[agentName] || null;
}

/**
 * Get Task tool command for an agent
 *
 * @param {string} agentName - Name of the agent
 * @param {object} options - Options {description, prompt}
 * @returns {string} Task tool command
 */
function getAgentCommand(agentName, options = {}) {
  const { description, prompt } = options;

  let command = `Task tool -> ${agentName}`;

  if (description) {
    command += `\nDescription: ${description}`;
  }

  if (prompt) {
    command += `\n\nPrompt:\n${prompt}`;
  }

  return command;
}

/**
 * Generate a prompt for an agent based on violations
 *
 * @param {string} agentName - Name of the agent
 * @param {string[]} violationTypes - Array of violation types
 * @param {object} context - Additional context {file, line, code}
 * @returns {string} Generated prompt
 */
function generateAgentPrompt(agentName, violationTypes, context = {}) {
  const info = getAgentInfo(agentName);
  if (!info) {
    return '';
  }

  let prompt = `You are the ${info.name}.\n\n`;
  prompt += `## Your Role\n${info.description}\n\n`;

  if (violationTypes && violationTypes.length > 0) {
    prompt += `## Violations to Fix\n`;
    for (const violation of violationTypes) {
      prompt += `- ${violation}\n`;
    }
    prompt += `\n`;
  }

  if (context.file) {
    prompt += `## File to Fix\n${context.file}`;
    if (context.line) {
      prompt += `:${context.line}\n\n`;
    } else {
      prompt += `\n\n`;
    }
  }

  if (context.code) {
    prompt += `## Problematic Code\n\`\`\`\n${context.code}\n\`\`\`\n\n`;
  }

  prompt += `## Instructions\n`;
  prompt += `1. Analyze the violation(s)\n`;
  prompt += `2. Implement the fix according to Maven Flow standards\n`;
  prompt += `3. Ensure no new violations are introduced\n`;
  prompt += `4. Run quality checks to verify\n\n`;

  prompt += `## Quality Standards\n`;
  prompt += `- No 'any' types (ZERO TOLERANCE)\n`;
  prompt += `- No gradients (use solid colors)\n`;
  prompt += `- Use @ aliases for imports\n`;
  prompt += `- Components < 300 lines\n`;

  return prompt;
}

/**
 * Get all available agents
 *
 * @returns {string[]} Array of agent names
 */
function getAvailableAgents() {
  return Object.keys(AGENT_INFO);
}

/**
 * Get agents for a specific Maven step
 *
 * @param {number} step - Maven step number (1-10)
 * @returns {string[]} Array of agent names for that step
 */
function getAgentsForStep(step) {
  const stepAgentMap = {
    1: ['development-agent'],
    2: ['development-agent'],
    3: ['refactor-agent'],
    4: ['refactor-agent'],
    5: ['quality-agent'],
    6: ['refactor-agent'],
    7: ['development-agent'],
    8: ['security-agent'],
    9: ['development-agent'],
    10: ['security-agent'],
    11: ['design-agent']
  };

  return stepAgentMap[step] || ['development-agent'];
}

/**
 * Create an agent execution plan
 *
 * @param {object} violations - Violations by type
 * @returns {object} Execution plan
 */
function createExecutionPlan(violations) {
  const violationTypes = Object.keys(violations);
  const selectedAgent = selectAgent(violationTypes);
  const agentInfo = getAgentInfo(selectedAgent);

  // Group violations by agent
  const agentsNeeded = {};
  for (const violation of violationTypes) {
    const agent = mapViolationToAgent(violation);
    if (agent) {
      if (!agentsNeeded[agent]) {
        agentsNeeded[agent] = [];
      }
      agentsNeeded[agent].push(violation);
    }
  }

  return {
    primaryAgent: selectedAgent,
    primaryAgentInfo: agentInfo,
    allAgents: Object.keys(agentsNeeded),
    violationsByAgent: agentsNeeded,
    totalViolations: violationTypes.length,
    recommendedOrder: Object.keys(agentsNeeded).sort((a, b) => {
      // Security first, then quality, then others
      const priority = { 'security-agent': 1, 'quality-agent': 2 };
      const pa = priority[a] || 99;
      const pb = priority[b] || 99;
      return pa - pb;
    })
  };
}

/**
 * Format execution plan as readable text
 *
 * @param {object} plan - Execution plan from createExecutionPlan
 * @returns {string} Formatted plan
 */
function formatExecutionPlan(plan) {
  let output = '';
  output += `Execution Plan\n`;
  output += `═══════════════\n\n`;
  output += `Primary Agent: ${plan.primaryAgent}\n`;
  output += `Total Violations: ${plan.totalViolations}\n\n`;

  if (Object.keys(plan.violationsByAgent).length > 1) {
    output += `Agents Needed:\n`;
    for (const [agent, violations] of Object.entries(plan.violationsByAgent)) {
      output += `  - ${agent}: ${violations.length} violation(s)\n`;
    }
    output += `\n`;

    output += `Recommended Order:\n`;
    for (const agent of plan.recommendedOrder) {
      const violations = plan.violationsByAgent[agent];
      output += `  ${1 + plan.recommendedOrder.indexOf(agent)}. ${agent}\n`;
      output += `     Violations: ${violations.join(', ')}\n`;
    }
  }

  return output;
}

// Export all functions
module.exports = {
  mapViolationToAgent,
  mapViolationsToAgents,
  selectAgent,
  getAgentInfo,
  getAgentCommand,
  generateAgentPrompt,
  getAvailableAgents,
  getAgentsForStep,
  createExecutionPlan,
  formatExecutionPlan,
  VIOLATION_AGENT_MAP,
  AGENT_INFO
};

// Allow running as a script for testing
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === 'help' || args[0] === '--help') {
    console.log('Automatic Agent Selector');
    console.log('');
    console.log('Usage: node agent-selector.js <command> [args]');
    console.log('');
    console.log('Commands:');
    console.log('  map <violation-type>          - Map violation to agent');
    console.log('  select <violation1> <...>     - Select best agent for violations');
    console.log('  agents                        - List all available agents');
    console.log('  step <n>                      - Get agents for Maven step');
    console.log('  plan <violation1> <...>       - Create execution plan');
    console.log('');
    console.log('Examples:');
    console.log('  node agent-selector.js map any_type');
    console.log('  node agent-selector.js select any_type gradient');
    console.log('  node agent-selector.js agents');
    console.log('  node agent-selector.js step 5');
    console.log('  node agent-selector.js plan any_type relative_import');
    process.exit(0);
  }

  const [command, ...cmdArgs] = args;

  switch (command) {
    case 'map': {
      const violation = cmdArgs[0];
      if (!violation) {
        console.error('Error: Violation type required');
        process.exit(1);
      }
      const agent = mapViolationToAgent(violation);
      if (agent) {
        const info = getAgentInfo(agent);
        console.log(`Violation: ${violation}`);
        console.log(`Agent: ${agent}`);
        console.log(`Description: ${info?.description || 'N/A'}`);
        console.log(`\nSuggested: Load ${agent} to handle this violation`);
      } else {
        console.log(`No agent mapping for violation: ${violation}`);
      }
      break;
    }

    case 'select': {
      if (cmdArgs.length === 0) {
        console.error('Error: At least one violation type required');
        process.exit(1);
      }
      const agent = selectAgent(cmdArgs);
      const info = getAgentInfo(agent);
      console.log(`Selected Agent: ${agent}`);
      console.log(`Description: ${info?.description || 'N/A'}`);
      console.log(`\nViolations: ${cmdArgs.join(', ')}`);
      console.log(`\nSuggested: Load ${agent} to fix these violations`);
      break;
    }

    case 'agents': {
      const agents = getAvailableAgents();
      console.log('Available Agents:');
      console.log('==================');
      for (const agent of agents) {
        const info = getAgentInfo(agent);
        console.log(`\n${agent}`);
        console.log(`  ${info?.description || 'No description'}`);
        if (info?.typicalViolations) {
          console.log(`  Typical: ${info.typicalViolations.join(', ')}`);
        }
      }
      break;
    }

    case 'step': {
      const step = parseInt(cmdArgs[0]);
      if (!step || step < 1 || step > 11) {
        console.error('Error: Step must be between 1 and 11');
        process.exit(1);
      }
      const agents = getAgentsForStep(step);
      console.log(`Maven Step ${step}:`);
      console.log(`Agents: ${agents.join(', ')}`);
      break;
    }

    case 'plan': {
      if (cmdArgs.length === 0) {
        console.error('Error: At least one violation type required');
        process.exit(1);
      }
      const violations = {};
      for (const v of cmdArgs) {
        violations[v] = true;
      }
      const plan = createExecutionPlan(violations);
      console.log(formatExecutionPlan(plan));
      break;
    }

    default:
      console.error(`Unknown command: ${command}`);
      console.log('Run "node agent-selector.js help" for usage');
      process.exit(1);
  }
}
