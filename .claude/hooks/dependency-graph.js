#!/usr/bin/env node
/**
 * Dependency Graph - Feature Impact Analysis
 *
 * Builds a dependency graph from PRD files to analyze feature relationships.
 * Provides impact analysis before making changes.
 *
 * Data sources:
 * - PRD relatedPRDs arrays
 * - memorialFile references
 * - Integration points in story descriptions
 *
 * Usage:
 *   const graph = require('./dependency-graph.js');
 *   const impact = graph.getImpact('docs/prd-authentication.json');
 *   if (impact.breaking) {
 *     console.warn('Breaking changes detected:', impact.affected);
 *   }
 *
 * @module dependency-graph
 */

const fs = require('fs');
const path = require('path');

// Cache for parsed PRDs
const prdCache = new Map();

/**
 * Find all PRD files in the docs directory
 *
 * @param {string} docsDir - Path to docs directory
 * @returns {string[]} Array of PRD file paths
 */
function findPRDFiles(docsDir = 'docs') {
  if (!fs.existsSync(docsDir)) {
    return [];
  }

  return fs.readdirSync(docsDir)
    .filter(f => f.startsWith('prd-') && f.endsWith('.json'))
    .map(f => path.join(docsDir, f));
}

/**
 * Parse a PRD file
 *
 * @param {string} prdPath - Path to PRD file
 * @returns {object|null} Parsed PRD object or null if error
 */
function parsePRD(prdPath) {
  // Check cache first
  if (prdCache.has(prdPath)) {
    return prdCache.get(prdPath);
  }

  try {
    const content = fs.readFileSync(prdPath, 'utf-8');
    const prd = JSON.parse(content);
    prdCache.set(prdPath, prd);
    return prd;
  } catch (e) {
    return null;
  }
}

/**
 * Get feature name from PRD path
 *
 * @param {string} prdPath - Path to PRD file
 * @returns {string} Feature name
 */
function getFeatureName(prdPath) {
  const basename = path.basename(prdPath);
  return basename.replace(/^prd-/, '').replace(/\.json$/, '');
}

/**
 * Extract dependencies from a PRD
 *
 * @param {object} prd - Parsed PRD object
 * @returns {Set<string>} Set of dependent feature names
 */
function extractDependencies(prd) {
  const deps = new Set();

  // From relatedPRDs field
  if (prd.relatedMemorials && Array.isArray(prd.relatedMemorials)) {
    prd.relatedMemorials.forEach(memorial => {
      // Extract feature name from memorial path
      // e.g., "docs/consolidated-authentication.txt" -> "authentication"
      const match = memorial.match(/consolidated-([^.]+)\.txt$/);
      if (match) {
        deps.add(match[1]);
      }
    });
  }

  // From user story descriptions (look for @features/ references)
  if (prd.userStories && Array.isArray(prd.userStories)) {
    prd.userStories.forEach(story => {
      const desc = (story.description || '') + ' ' + (story.notes || '');
      // Match @features/xxx patterns
      const matches = desc.matchAll(/@features\/(\w+)/g);
      for (const match of matches) {
        deps.add(match[1]);
      }
    });
  }

  return deps;
}

/**
 * Build the dependency graph from all PRD files
 *
 * @param {string} docsDir - Path to docs directory
 * @returns {object} Graph object {nodes, edges, adj}
 */
function buildGraph(docsDir = 'docs') {
  const prdFiles = findPRDFiles(docsDir);
  const nodes = [];
  const edges = [];
  const adj = {}; // Adjacency list

  // Initialize nodes
  for (const prdPath of prdFiles) {
    const feature = getFeatureName(prdPath);
    nodes.push({ id: feature, path: prdPath });
    adj[feature] = [];
  }

  // Build edges from dependencies
  for (const prdPath of prdFiles) {
    const feature = getFeatureName(prdPath);
    const prd = parsePRD(prdPath);

    if (prd) {
      const deps = extractDependencies(prd);

      for (const dep of deps) {
        // Only add edge if dependency is a known feature
        if (adj.hasOwnProperty(dep)) {
          edges.push({ from: feature, to: dep });
          adj[feature].push(dep);
        }
      }
    }
  }

  return { nodes, edges, adj };
}

/**
 * Get all descendants of a feature (transitive closure)
 *
 * @param {string} feature - Feature name
 * @param {object} graph - Dependency graph
 * @param {Set<string>} visited - Visited set (for recursion)
 * @returns {Set<string>} Set of dependent features
 */
function getDescendants(feature, graph, visited = new Set()) {
  if (visited.has(feature)) {
    return visited;
  }

  visited.add(feature);

  const deps = graph.adj[feature] || [];
  for (const dep of deps) {
    getDescendants(dep, graph, visited);
  }

  return visited;
}

/**
 * Get all ancestors of a feature (what depends on it)
 *
 * @param {string} feature - Feature name
 * @param {object} graph - Dependency graph
 * @returns {Set<string>} Set of features that depend on this one
 */
function getAncestors(feature, graph) {
  const ancestors = new Set();

  for (const node in graph.adj) {
    const deps = graph.adj[node];
    if (deps.includes(feature)) {
      ancestors.add(node);
      // Also get ancestors of ancestors
      const transitive = getAncestors(node, graph);
      transitive.forEach(a => ancestors.add(a));
    }
  }

  return ancestors;
}

/**
 * Analyze impact of changes to a feature
 *
 * @param {string} prdPath - Path to PRD file being changed
 * @param {string[]} changes - List of changes being made
 * @returns {object} Impact analysis
 */
function getImpact(prdPath, changes = []) {
  const graph = buildGraph(path.dirname(prdPath) || 'docs');
  const feature = getFeatureName(prdPath);
  const dependents = getAncestors(feature, graph);

  const impact = {
    feature,
    changes,
    affected: Array.from(dependents),
    breaking: false,
    warnings: [],
    suggestions: []
  };

  // Check for breaking changes
  const breakingPatterns = [
    { pattern: /remove|delete|drop/i, message: 'Removing functionality' },
    { pattern: /break|change.*interface|modify.*api/i, message: 'Changing API interface' },
    { pattern: /rename.*field|rename.*column/i, message: 'Renaming data fields' }
  ];

  for (const change of changes) {
    for (const { pattern, message } of breakingPatterns) {
      if (pattern.test(change)) {
        impact.breaking = true;
        impact.warnings.push(`Breaking change detected: ${message}`);
        break;
      }
    }
  }

  // Add warnings for affected features
  if (dependents.size > 0) {
    if (impact.breaking) {
      impact.warnings.push(`This change affects ${dependents.size} feature(s): ${Array.from(dependents).join(', ')}`);
    } else {
      impact.suggestions.push(`Consider notifying maintainers of: ${Array.from(dependents).join(', ')}`);
    }
  }

  return impact;
}

/**
 * Get integration points for a feature
 *
 * @param {string} prdPath - Path to PRD file
 * @returns {object} Integration points
 */
function getIntegrationPoints(prdPath) {
  const prd = parsePRD(prdPath);
  if (!prd) {
    return { inbound: [], outbound: [] };
  }

  const graph = buildGraph(path.dirname(prdPath) || 'docs');
  const feature = getFeatureName(prdPath);

  const inbound = getAncestors(feature, graph);
  const outbound = new Set(graph.adj[feature] || []);

  return {
    inbound: Array.from(inbound),
    outbound: Array.from(outbound),
    total: inbound.size + outbound.size
  };
}

/**
 * Warn about potential breaking changes
 *
 * @param {string} prdPath - Path to PRD file
 * @param {string[]} changes - List of changes
 * @returns {string[]} Array of warning messages
 */
function warnBreakingChanges(prdPath, changes) {
  const impact = getImpact(prdPath, changes);
  const warnings = [];

  if (impact.breaking) {
    warnings.push(...impact.warnings);

    if (impact.affected.length > 0) {
      warnings.push('');
      warnings.push('Affected features:');
      for (const affected of impact.affected) {
        warnings.push(`  - ${affected}`);
      }
    }
  }

  return warnings;
}

/**
 * Visualize the dependency graph as ASCII
 *
 * @param {object} graph - Dependency graph
 * @returns {string} ASCII visualization
 */
function visualizeGraph(graph) {
  let output = 'Dependency Graph:\n';
  output += '================\n\n';

  for (const feature of Object.keys(graph.adj).sort()) {
    const deps = graph.adj[feature];
    if (deps.length > 0) {
      output += `${feature} ->\n`;
      deps.forEach(dep => {
        output += `  └─ ${dep}\n`;
      });
    } else {
      output += `${feature} (no dependencies)\n`;
    }
    output += '\n';
  }

  return output;
}

/**
 * Get circular dependencies in the graph
 *
 * @param {object} graph - Dependency graph
 * @returns {string[][]} Array of cycles
 */
function findCycles(graph) {
  const cycles = [];
  const visited = new Set();
  const recursionStack = new Set();

  function dfs(node, path) {
    visited.add(node);
    recursionStack.add(node);
    path.push(node);

    for (const dep of graph.adj[node] || []) {
      if (recursionStack.has(dep)) {
        // Found a cycle
        const cycleStart = path.indexOf(dep);
        const cycle = path.slice(cycleStart).concat(dep);
        cycles.push(cycle);
      } else if (!visited.has(dep)) {
        dfs(dep, path);
      }
    }

    path.pop();
    recursionStack.delete(node);
  }

  for (const node of Object.keys(graph.adj)) {
    if (!visited.has(node)) {
      dfs(node, []);
    }
  }

  return cycles;
}

/**
 * Get recommended development order based on dependencies
 *
 * @param {object} graph - Dependency graph
 * @returns {string[]} Array of feature names in order
 */
function getDevelopmentOrder(graph) {
  const order = [];
  const visited = new Set();

  function visit(feature) {
    if (visited.has(feature)) {
      return;
    }

    visited.add(feature);

    // Visit dependencies first
    for (const dep of graph.adj[feature] || []) {
      visit(dep);
    }

    order.push(feature);
  }

  for (const feature of Object.keys(graph.adj)) {
    if (!visited.has(feature)) {
      visit(feature);
    }
  }

  return order;
}

/**
 * Get statistics about the dependency graph
 *
 * @param {object} graph - Dependency graph
 * @returns {object} Statistics
 */
function getStats(graph) {
  const nodeCount = Object.keys(graph.adj).length;
  let edgeCount = 0;
  let maxDeps = 0;
  let mostConnected = null;

  for (const feature in graph.adj) {
    const deps = graph.adj[feature].length;
    edgeCount += deps;
    if (deps > maxDeps) {
      maxDeps = deps;
      mostConnected = feature;
    }
  }

  const cycles = findCycles(graph);

  return {
    features: nodeCount,
    dependencies: edgeCount,
    maxDeps,
    mostConnected,
    hasCycles: cycles.length > 0,
    cycleCount: cycles.length
  };
}

// Export all functions
module.exports = {
  findPRDFiles,
  parsePRD,
  getFeatureName,
  extractDependencies,
  buildGraph,
  getDescendants,
  getAncestors,
  getImpact,
  getIntegrationPoints,
  warnBreakingChanges,
  visualizeGraph,
  findCycles,
  getDevelopmentOrder,
  getStats
};

// Allow running as a script for testing
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === 'help' || args[0] === '--help') {
    console.log('Dependency Graph - Feature Impact Analysis');
    console.log('');
    console.log('Usage: node dependency-graph.js <command> [args]');
    console.log('');
    console.log('Commands:');
    console.log('  build [docs-dir]         - Build dependency graph');
    console.log('  visualize [docs-dir]     - Visualize dependency graph');
    console.log('  impact <prd-file>        - Analyze impact of changes');
    console.log('  integration <prd-file>   - Get integration points');
    console.log('  cycles [docs-dir]        - Find circular dependencies');
    console.log('  order [docs-dir]         - Get recommended development order');
    console.log('  stats [docs-dir]         - Get graph statistics');
    console.log('');
    console.log('Examples:');
    console.log('  node dependency-graph.js visualize');
    console.log('  node dependency-graph.js impact docs/prd-auth.json');
    console.log('  node dependency-graph.js cycles');
    process.exit(0);
  }

  const [command, ...cmdArgs] = args;

  switch (command) {
    case 'build': {
      const docsDir = cmdArgs[0] || 'docs';
      const graph = buildGraph(docsDir);
      console.log(JSON.stringify(graph, null, 2));
      break;
    }

    case 'visualize': {
      const docsDir = cmdArgs[0] || 'docs';
      const graph = buildGraph(docsDir);
      console.log(visualizeGraph(graph));
      break;
    }

    case 'impact': {
      const prdPath = cmdArgs[0];
      if (!prdPath) {
        console.error('Error: PRD file path required');
        process.exit(1);
      }
      const impact = getImpact(prdPath);
      console.log(`Impact Analysis for ${impact.feature}`);
      console.log('=====================================');
      console.log(`Affected: ${impact.affected.join(', ') || 'None'}`);
      console.log(`Breaking: ${impact.breaking ? 'Yes' : 'No'}`);
      if (impact.warnings.length > 0) {
        console.log('');
        console.log('Warnings:');
        impact.warnings.forEach(w => console.log(`  ⚠️  ${w}`));
      }
      if (impact.suggestions.length > 0) {
        console.log('');
        console.log('Suggestions:');
        impact.suggestions.forEach(s => console.log(`  💡 ${s}`));
      }
      break;
    }

    case 'integration': {
      const prdPath = cmdArgs[0];
      if (!prdPath) {
        console.error('Error: PRD file path required');
        process.exit(1);
      }
      const points = getIntegrationPoints(prdPath);
      console.log(`Integration Points for ${getFeatureName(prdPath)}`);
      console.log('========================================');
      console.log(`Inbound (features using this): ${points.inbound.join(', ') || 'None'}`);
      console.log(`Outbound (dependencies): ${points.outbound.join(', ') || 'None'}`);
      console.log(`Total: ${points.total}`);
      break;
    }

    case 'cycles': {
      const docsDir = cmdArgs[0] || 'docs';
      const graph = buildGraph(docsDir);
      const cycles = findCycles(graph);
      if (cycles.length === 0) {
        console.log('✅ No circular dependencies found');
      } else {
        console.log(`⚠️  Found ${cycles.length} circular dependency(ies):`);
        cycles.forEach((cycle, i) => {
          console.log(`  ${i + 1}. ${cycle.join(' -> ')}`);
        });
      }
      break;
    }

    case 'order': {
      const docsDir = cmdArgs[0] || 'docs';
      const graph = buildGraph(docsDir);
      const order = getDevelopmentOrder(graph);
      console.log('Recommended Development Order:');
      console.log('==============================');
      order.forEach((feature, i) => {
        console.log(`  ${i + 1}. ${feature}`);
      });
      break;
    }

    case 'stats': {
      const docsDir = cmdArgs[0] || 'docs';
      const graph = buildGraph(docsDir);
      const stats = getStats(graph);
      console.log('Dependency Graph Statistics:');
      console.log('============================');
      console.log(`  Features: ${stats.features}`);
      console.log(`  Dependencies: ${stats.dependencies}`);
      console.log(`  Max Dependencies: ${stats.maxDeps}`);
      console.log(`  Most Connected: ${stats.mostConnected || 'N/A'}`);
      console.log(`  Has Cycles: ${stats.hasCycles ? 'Yes' : 'No'}`);
      if (stats.hasCycles) {
        console.log(`  Cycle Count: ${stats.cycleCount}`);
      }
      break;
    }

    default:
      console.error(`Unknown command: ${command}`);
      console.log('Run "node dependency-graph.js help" for usage');
      process.exit(1);
  }
}
