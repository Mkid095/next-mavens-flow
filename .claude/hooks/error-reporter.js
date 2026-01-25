#!/usr/bin/env node
/**
 * Enhanced Error Reporter - Detailed Error Messages with Fix Suggestions
 *
 * Provides detailed error reporting for common Maven Flow violations.
 * Each error type includes:
 * - Clear description of the problem
 * - Why it's a problem
 * - How to fix it (with examples)
 * - Related violations
 *
 * Usage:
 *   const errorReporter = require('./error-reporter.js');
 *   const report = errorReporter.report('any_type', { file: 'src/test.ts', line: 10 });
 *   console.log(report.message);
 *
 * @module error-reporter
 */

const path = require('path');

/**
 * Error type definitions with fix suggestions
 */
const ERROR_TYPES = {
  // TypeScript: any types
  any_type: {
    name: 'TypeScript Any Type',
    severity: 'blocking',
    description: 'Using `any` type defeats TypeScript\'s type safety',
    why: 'The `any` type disables all type checking, allowing any operation without compile-time errors. This can lead to runtime errors that should be caught during development.',
    patterns: [': any', ': any[]', ': any<', 'as any', 'Promise<any>', 'Record<any', '<T = any>'],
    fix: [
      '1. Define a proper interface or type for the data',
      '2. Use generics: `<T>` instead of `any`',
      '3. Use `unknown` with type guards for truly unknown data',
      '4. For API responses, create a `.d.ts` declaration file'
    ],
    examples: [
      {
        bad: 'function process(data: any) { return data.value; }',
        good: 'interface Data { value: string; }\nfunction process(data: Data) { return data.value; }'
      },
      {
        bad: 'const items: any[] = [];',
        good: 'interface Item { id: number; }\nconst items: Item[] = [];'
      },
      {
        bad: 'async function fetch(): Promise<any> { ... }',
        good: 'interface Response { status: number; data: unknown; }\nasync function fetch(): Promise<Response> { ... }'
      },
      {
        bad: 'function parse(input: string): any | null { ... }',
        good: 'type Result = { value: string } | null;\nfunction parse(input: string): Result { ... }'
      }
    ],
    agent: 'quality-agent',
    command: 'Load quality-agent to audit and fix type safety issues'
  },

  // CSS: Gradients
  gradient: {
    name: 'CSS Gradients',
    severity: 'blocking',
    description: 'Using gradients in CSS/inline styles violates professional design standards',
    why: 'Gradients can look unprofessional, may cause performance issues, and don\'t align with modern flat/material design principles. Use solid colors from a defined palette.',
    patterns: ['linear-gradient', 'radial-gradient', 'conic-gradient', 'repeating-gradient'],
    fix: [
      '1. Replace gradient with solid colors from the design palette',
      '2. Use CSS variables: `var(--color-primary)`',
      '3. Use semantic color names: `--color-primary`, `--color-success`',
      '4. For depth, use subtle shadows instead of gradients'
    ],
    examples: [
      {
        bad: 'background: linear-gradient(to right, #3b82f6, #8b5cf6);',
        good: 'background: var(--color-primary, #3b82f6);'
      },
      {
        bad: 'background: radial-gradient(circle, #fff, #f3f4f6);',
        good: 'background: var(--color-background, #ffffff);'
      },
      {
        bad: 'const style = { background: "linear-gradient(...)" };',
        good: 'const style = { backgroundColor: "var(--color-primary)" };'
      }
    ],
    colors: {
      primary: '#3b82f6',
      success: '#10b981',
      warning: '#f59e0b',
      error: '#ef4444',
      neutral: '#6b7280',
      background: '#ffffff',
      surface: '#f9fafb'
    },
    agent: 'quality-agent',
    command: 'Load quality-agent to fix gradient violations'
  },

  // Relative imports
  relative_import: {
    name: 'Relative Import Paths',
    severity: 'warning',
    description: 'Using relative import paths instead of path aliases',
    why: 'Relative imports are brittle - breaking when files are moved. Path aliases (`@/`) provide stable, readable imports that survive refactoring.',
    patterns: ["from '../", 'from "../../', "from './"],
    fix: [
      '1. Use `@/` aliases for all imports',
      '2. Configure paths in tsconfig.json',
      '3. Use `@shared/*` for shared code',
      '4. Use `@features/*` for feature code'
    ],
    examples: [
      {
        bad: "import { Button } from '../../../shared/ui/Button';",
        good: "import { Button } from '@shared/ui/Button';"
      },
      {
        bad: "import { utils } from '../utils/helpers';",
        good: "import { utils } from '@shared/utils/helpers';"
      },
      {
        bad: "import { useAuth } from '../../features/auth/hooks';",
        good: "import { useAuth } from '@features/auth/hooks';"
      }
    ],
    tsconfig: {
      compilerOptions: {
        paths: {
          '@/*': ['./src/*'],
          '@shared/*': ['./src/shared/*'],
          '@features/*': ['./src/features/*'],
          '@app/*': ['./src/app/*']
        }
      }
    },
    agent: 'refactor-agent',
    command: 'Load refactor-agent to convert relative imports to aliases'
  },

  // Large component
  large_component: {
    name: 'Large Component File',
    severity: 'warning',
    description: 'Component file exceeds 300 lines - needs modularization',
    why: 'Large components are harder to understand, test, and maintain. Breaking them into smaller pieces improves code quality and developer experience.',
    threshold: 300,
    patterns: ['component.*\.tsx$', 'component.*\.jsx$', 'component.*\.vue$'],
    fix: [
      '1. Extract sub-components into separate files',
      '2. Extract custom hooks for logic',
      '3. Extract utility functions',
      '4. Extract constants/types to separate files',
      '5. Use composition to build complex UIs from simple pieces'
    ],
    examples: [
      {
        description: 'Extract sub-component',
        bad: '/* 400-line component with nested JSX */',
        good: '/* Main component (50 lines) */\n/* SubComponent1.tsx (100 lines) */\n/* SubComponent2.tsx (100 lines) */'
      },
      {
        description: 'Extract custom hook',
        bad: '/* Component with 400 lines including logic */',
        good: '/* useComponent.ts hook with logic */\n/* Component.tsx uses the hook */'
      }
    ],
    agent: 'refactor-agent',
    command: 'Load refactor-agent to modularize large components'
  },

  // Direct API calls
  direct_api_call: {
    name: 'Direct API Calls in Components',
    severity: 'warning',
    description: 'Making API calls directly in components instead of using data layer',
    why: 'Direct API calls in components make testing harder, duplicate logic, and make it difficult to change API implementations. Centralize API calls in a data layer.',
    patterns: ['fetch(', 'axios.', 'api.get(', 'api.post('],
    fix: [
      '1. Create API client functions in `@features/*/api/`',
      '2. Use React Query/SWR for data fetching',
      '3. Create custom hooks for API operations',
      '4. Centralize API configuration and error handling'
    ],
    examples: [
      {
        bad: 'function UserList() { const [users, setUsers] = useState([]); useEffect(() => { fetch("/api/users").then(r => r.json()).then(setUsers); }, []); return ...;',
        good: '// @features/users/api/list.ts\nexport async function listUsers() { const response = await fetch("/api/users"); return response.json(); }\n\n// @features/users/hooks/useUsers.ts\nexport function useUsers() { return useQuery("users", listUsers); }\n\n// components/UserList.tsx\nfunction UserList() { const { data: users } = useUsers(); return ...;'
      }
    ],
    agent: 'refactor-agent',
    command: 'Load refactor-agent to create data layer'
  },

  // UI component duplication
  duplicate_ui: {
    name: 'Duplicate UI Components',
    severity: 'warning',
    description: 'Creating UI components that already exist in @shared/ui',
    why: 'Duplicate UI code leads to inconsistency, maintenance burden, and design violations. Centralize common UI components in @shared/ui.',
    patterns: ['export (const|function) (Button|Input|Modal|Select|Card|TextField|Checkbox|Badge)'],
    fix: [
      '1. Check @shared/ui for existing components',
      '2. Use shared components instead of creating new ones',
      '3. Extend shared components if needed (composition over modification)',
      '4. Only create feature-specific components when truly unique'
    ],
    examples: [
      {
        bad: '// @features/dashboard/components/Button.tsx\nexport function Button({ children }) { return <button className="btn">{children}</button>; }',
        good: 'import { Button } from "@shared/ui/Button";\n\n// Use the shared component\n<Button variant="primary">Click me</Button>'
      }
    ],
    agent: 'refactor-agent',
    command: 'Load refactor-agent to consolidate UI components'
  },

  // Exposed secret
  exposed_secret: {
    name: 'Exposed Secret in Code',
    severity: 'blocking',
    description: 'Hardcoded secrets, API keys, or passwords in source code',
    why: 'Security vulnerability. Secrets in code can be exposed in version control, logs, or client-side bundles. Use environment variables.',
    patterns: ['api_key=', 'password=', 'secret=', 'token=', 'API_KEY=', 'SECRET_'],
    fix: [
      '1. Move secrets to environment variables',
      '2. Use .env files (add to .gitignore)',
      '3. Create .env.example with placeholder values',
      '4. For client-side, consider backend proxy',
      '5. Rotate compromised keys immediately'
    ],
    examples: [
      {
        bad: 'const API_KEY = "sk-1234567890abcdef";',
        good: 'const API_KEY = process.env.VITE_API_KEY;\n\n// .env.example\nVITE_API_KEY=your_api_key_here'
      },
      {
        bad: 'const dbConfig = { password: "admin123" };',
        good: 'const dbConfig = { password: process.env.DB_PASSWORD };'
      }
    ],
    agent: 'security-agent',
    command: 'Load security-agent for full security audit (URGENT)'
  },

  // Auth file changes
  auth_change: {
    name: 'Authentication/Authorization Changes',
    severity: 'security',
    description: 'Changes to authentication or authorization code',
    why: 'Auth changes are security-critical. Even small mistakes can expose vulnerabilities. Requires security review.',
    patterns: ['/auth/', 'login', 'logout', 'register', 'password', 'token', 'session', 'jwt', 'oauth'],
    fix: [
      '1. Review for security vulnerabilities',
      '2. Test authentication flows thoroughly',
      '3. Verify authorization checks on protected routes',
      '4. Check for session management issues',
      '5. Ensure proper error handling (no information leakage)'
    ],
    agent: 'security-agent',
    command: 'Load security-agent to audit auth changes'
  },

  // Environment file changes
  env_change: {
    name: 'Environment Configuration Changes',
    severity: 'warning',
    description: 'Changes to .env or environment configuration',
    why: 'Environment changes can break deployments or expose sensitive data. Review before committing.',
    patterns: ['.env', '.env.example', 'config/env'],
    fix: [
      '1. Verify no secrets are committed',
      '2. Update .env.example with new variables',
      '3. Document new environment variables',
      '4. Test with different environment configurations'
    ],
    agent: 'quality-agent',
    command: 'Load quality-agent to review environment changes'
  }
};

/**
 * Get error report for a specific error type
 *
 * @param {string} errorType - Type of error
 * @param {object} context - Additional context {file, line, code, ...}
 * @returns {object} Error report object
 */
function getReport(errorType, context = {}) {
  const errorDef = ERROR_TYPES[errorType];

  if (!errorDef) {
    return {
      type: errorType,
      found: false,
      message: `Unknown error type: ${errorType}`
    };
  }

  const { file, line, code } = context;

  return {
    type: errorType,
    found: true,
    severity: errorDef.severity,
    name: errorDef.name,
    description: errorDef.description,
    why: errorDef.why,
    patterns: errorDef.patterns,
    fix: errorDef.fix,
    examples: errorDef.examples,
    agent: errorDef.agent,
    command: errorDef.command,
    context: {
      file: file || null,
      line: line || null,
      code: code || null
    }
  };
}

/**
 * Format error report as human-readable text
 *
 * @param {object} report - Error report object
 * @param {object} options - Formatting options {verbose, color}
 * @returns {string} Formatted error message
 */
function formatReport(report, options = {}) {
  const { verbose = true, color = true } = options;

  if (!report.found) {
    return `Unknown error: ${report.type}`;
  }

  const colors = {
    reset: color ? '\x1b[0m' : '',
    red: color ? '\x1b[31m' : '',
    yellow: color ? '\x1b[33m' : '',
    blue: color ? '\x1b[34m' : '',
    cyan: color ? '\x1b[36m' : '',
    gray: color ? '\x1b[90m' : '',
    bold: color ? '\x1b[1m' : ''
  };

  let output = '';

  // Header with severity
  const severityIcon = report.severity === 'blocking' ? '🚨' :
                      report.severity === 'security' ? '🔒' :
                      report.severity === 'warning' ? '⚠️' : 'ℹ️';

  output += `${colors.bold}${severityIcon} ${report.name}${colors.reset}\n`;
  output += `${colors.gray}${'─'.repeat(50)}${colors.reset}\n`;
  output += `\n`;

  // Description
  output += `${colors.cyan}Description:${colors.reset} ${report.description}\n`;
  output += `\n`;

  // Context (file, line)
  if (report.context.file) {
    output += `${colors.cyan}Location:${colors.reset} ${report.context.file}`;
    if (report.context.line) {
      output += `:${report.context.line}\n`;
    } else {
      output += `\n`;
    }
  }

  // Why it's a problem
  if (verbose) {
    output += `\n${colors.yellow}Why it's a problem:${colors.reset}\n`;
    output += `  ${report.why}\n`;
  }

  // How to fix
  output += `\n${colors.green}How to fix:${colors.reset}\n`;
  report.fix.forEach((step, i) => {
    output += `  ${colors.bold}${i + 1}.${colors.reset} ${step}\n`;
  });

  // Examples
  if (verbose && report.examples && report.examples.length > 0) {
    output += `\n${colors.blue}Examples:${colors.reset}\n`;
    report.examples.forEach((example, i) => {
      const num = i + 1;
      output += `\n${colors.bold}Example ${num}:${colors.reset}`;
      if (example.description) {
        output += ` ${example.description}`;
      }
      output += `\n`;
      if (example.bad) {
        output += `  ${colors.red}❌ Bad:${colors.reset}\n`;
        output += `    ${example.bad.split('\n').join('\n    ')}\n`;
      }
      if (example.good) {
        output += `  ${colors.green}✅ Good:${colors.reset}\n`;
        output += `    ${example.good.split('\n').join('\n    ')}\n`;
      }
    });
  }

  // Agent suggestion
  if (report.agent) {
    output += `\n${colors.cyan}Suggested action:${colors.reset}\n`;
    output += `  ${report.command}\n`;
  }

  return output;
}

/**
 * Detect error type from a pattern match
 *
 * @param {string} match - Matched pattern string
 * @returns {string|null} Detected error type
 */
function detectErrorType(match) {
  if (!match) return null;

  const lowerMatch = match.toLowerCase();

  for (const [type, def] of Object.entries(ERROR_TYPES)) {
    for (const pattern of def.patterns) {
      if (lowerMatch.includes(pattern.toLowerCase())) {
        return type;
      }
    }
  }

  return null;
}

/**
 * Get all error types
 *
 * @returns {string[]} Array of error type names
 */
function getErrorTypes() {
  return Object.keys(ERROR_TYPES);
}

/**
 * Get blocking error types
 *
 * @returns {string[]} Array of blocking error type names
 */
function getBlockingErrors() {
  return Object.entries(ERROR_TYPES)
    .filter(([_, def]) => def.severity === 'blocking')
    .map(([type, _]) => type);
}

/**
 * Get error types by severity
 *
 * @param {string} severity - Severity level
 * @returns {string[]} Array of error type names
 */
function getErrorsBySeverity(severity) {
  return Object.entries(ERROR_TYPES)
    .filter(([_, def]) => def.severity === severity)
    .map(([type, _]) => type);
}

/**
 * Create a summary report for multiple errors
 *
 * @param {array} errors - Array of {type, context} objects
 * @returns {object} Summary report
 */
function createSummary(errors) {
  const summary = {
    total: errors.length,
    byType: {},
    bySeverity: { blocking: 0, warning: 0, security: 0 },
    agents: new Set(),
    hasBlocking: false
  };

  for (const error of errors) {
    const report = getReport(error.type);
    if (!report.found) continue;

    // Count by type
    summary.byType[error.type] = (summary.byType[error.type] || 0) + 1;

    // Count by severity
    if (report.severity) {
      summary.bySeverity[report.severity]++;
    }

    // Track blocking
    if (report.severity === 'blocking') {
      summary.hasBlocking = true;
    }

    // Collect agents
    if (report.agent) {
      summary.agents.add(report.agent);
    }
  }

  summary.agents = Array.from(summary.agents);
  return summary;
}

// Export all functions
module.exports = {
  getReport,
  formatReport,
  detectErrorType,
  getErrorTypes,
  getBlockingErrors,
  getErrorsBySeverity,
  createSummary,
  ERROR_TYPES
};

// Allow running as a script for testing
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === 'help' || args[0] === '--help') {
    console.log('Enhanced Error Reporter');
    console.log('');
    console.log('Usage: node error-reporter.js <error-type> [--file <path>] [--line <n>]');
    console.log('');
    console.log('Available error types:');
    for (const type of getErrorTypes()) {
      const report = getReport(type);
      const icon = report.severity === 'blocking' ? '🚨' :
                   report.severity === 'security' ? '🔒' : '⚠️';
      console.log(`  ${icon} ${type} - ${report.name}`);
    }
    console.log('');
    console.log('Examples:');
    console.log('  node error-reporter.js any_type');
    console.log('  node error-reporter.js gradient --file src/styles.css --line 15');
    process.exit(0);
  }

  const errorType = args[0];
  let context = {};

  // Parse additional context
  for (let i = 1; i < args.length; i++) {
    if (args[i] === '--file' && args[i + 1]) {
      context.file = args[++i];
    } else if (args[i] === '--line' && args[i + 1]) {
      context.line = parseInt(args[++i]);
    } else if (args[i] === '--code' && args[i + 1]) {
      context.code = args[++i];
    }
  }

  const report = getReport(errorType, context);
  console.log(formatReport(report, { verbose: true, color: true }));
}
