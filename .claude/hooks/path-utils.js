#!/usr/bin/env node
/**
 * Path Utilities for Cross-Platform Compatibility
 *
 * Handles path normalization across different platforms and shells:
 * - Git Bash paths: /c/Users/... → C:\Users\...
 * - PowerShell paths: C:\Users\...
 * - CMD paths: C:\Users\...
 * - WSL paths: /mnt/c/Users/...
 *
 * Usage:
 *   const pathUtils = require('./path-utils.js');
 *   const normalized = pathUtils.normalizePath('/c/Users/ken/project');
 *   const resolved = pathUtils.resolveProjectPath(cwd, './docs');
 *
 * @module path-utils
 */

const path = require('path');
const os = require('os');

/**
 * Normalize a path for the current platform
 * Converts Git Bash/WSL paths to Windows paths when on Windows
 *
 * @param {string} inputPath - Path to normalize
 * @returns {string} Normalized path for current platform
 */
function normalizePath(inputPath) {
  if (!inputPath || typeof inputPath !== 'string') {
    return inputPath;
  }

  // On non-Windows platforms, return as-is
  if (process.platform !== 'win32') {
    return inputPath;
  }

  // Pattern 1: Git Bash style: /c/Users/... → C:\Users\...
  // Pattern 2: WSL style: /mnt/c/Users/... → C:\Users\...
  // Pattern 3: Already Windows style: C:\Users\...

  // Check if already a Windows path (has drive letter)
  if (/^[A-Za-z]:\\/.test(inputPath)) {
    return inputPath;
  }

  // Check for Git Bash pattern: /c/ or /C/ (drive letter)
  const gitBashMatch = inputPath.match(/^\/([A-Za-z])\/(.*)$/);
  if (gitBashMatch) {
    const drive = gitBashMatch[1].toUpperCase();
    const rest = gitBashMatch[2].replace(/\//g, '\\');
    return `${drive}:\\${rest}`;
  }

  // Check for WSL pattern: /mnt/c/ or /mnt/C/
  const wslMatch = inputPath.match(/^\/mnt\/([A-Za-z])\/(.*)$/);
  if (wslMatch) {
    const drive = wslMatch[1].toUpperCase();
    const rest = wslMatch[2].replace(/\//g, '\\');
    return `${drive}:\\${rest}`;
  }

  // Check if running under Git Bash or MSYS2
  // In these environments, /home/username maps to C:\Users\username
  if (inputPath.startsWith('/home/')) {
    const username = process.env.USER || process.env.USERNAME || os.userInfo().username;
    // Try to map /home/user to C:\Users\user
    const homePath = path.join('C:\\', 'Users', username);
    const relativePath = inputPath.substring(6); // Remove /home/
    return path.join(homePath, relativePath.replace(/\//g, '\\'));
  }

  // Forward slashes to backslashes on Windows
  if (inputPath.includes('/')) {
    return inputPath.replace(/\//g, '\\');
  }

  return inputPath;
}

/**
 * Resolve a path relative to project root
 * Handles cross-platform path resolution
 *
 * @param {string} cwd - Current working directory
 * @param {string} relativePath - Relative path to resolve
 * @returns {string} Absolute resolved path
 */
function resolveProjectPath(cwd, relativePath) {
  // Normalize cwd first
  const normalizedCwd = normalizePath(cwd);

  // Join paths
  const joined = path.join(normalizedCwd, relativePath);

  // Normalize result
  return normalizePath(joined);
}

/**
 * Get the docs directory path for the project
 * Cross-platform compatible
 *
 * @param {string} projectRoot - Project root directory
 * @returns {string} Path to docs directory
 */
function getDocsPath(projectRoot) {
  return resolveProjectPath(projectRoot, 'docs');
}

/**
 * Get the .claude directory path for the project
 * Cross-platform compatible
 *
 * @param {string} projectRoot - Project root directory
 * @returns {string} Path to .claude directory
 */
function getClaudePath(projectRoot) {
  return resolveProjectPath(projectRoot, '.claude');
}

/**
 * Convert a Windows path to Git Bash format
 * Useful for shell commands that need Git Bash paths
 *
 * @param {string} windowsPath - Windows path (e.g., C:\Users\...)
 * @returns {string} Git Bash path (e.g., /c/Users/...)
 */
function windowsToGitBashPath(windowsPath) {
  if (!windowsPath) return windowsPath;

  // C:\Users\... → /c/Users/...
  const match = windowsPath.match(/^([A-Za-z]):\\(.*)$/);
  if (match) {
    const drive = match[1].toLowerCase();
    const rest = match[2].replace(/\\/g, '/');
    return `/${drive}/${rest}`;
  }

  return windowsPath;
}

/**
 * Detect the current shell/environment
 * Useful for determining path format expectations
 *
 * @returns {string} Detected shell: 'bash', 'powershell', 'cmd', 'wsl', 'node', 'unknown'
 */
function detectShell() {
  // Check environment variables
  if (process.env.WSL_DISTRO || process.env.WSL_INTEROP) {
    return 'wsl';
  }

  if (process.env.PSModulePath) {
    return 'powershell';
  }

  if (process.env.COMSPEC && process.env.COMSPEC.includes('cmd.exe')) {
    return 'cmd';
  }

  if (process.env.SHELL || process.env.MSYS2_PATH) {
    return 'bash';
  }

  if (process.env.NODE_ENV) {
    return 'node';
  }

  return 'unknown';
}

/**
 * Check if a path exists (cross-platform)
 *
 * @param {string} filePath - Path to check
 * @returns {boolean} True if path exists
 */
function pathExists(filePath) {
  try {
    const fs = require('fs');
    return fs.existsSync(normalizePath(filePath));
  } catch (e) {
    return false;
  }
}

/**
 * Read a file (cross-platform)
 *
 * @param {string} filePath - Path to file
 * @returns {string|null} File contents or null if error
 */
function readFile(filePath) {
  try {
    const fs = require('fs');
    return fs.readFileSync(normalizePath(filePath), 'utf-8');
  } catch (e) {
    return null;
  }
}

/**
 * Write a file (cross-platform)
 *
 * @param {string} filePath - Path to file
 * @param {string} content - File contents
 * @returns {boolean} True if successful
 */
function writeFile(filePath, content) {
  try {
    const fs = require('fs');
    const normalizedPath = normalizePath(filePath);

    // Ensure directory exists
    const dir = path.dirname(normalizedPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(normalizedPath, content, 'utf-8');
    return true;
  } catch (e) {
    return false;
  }
}

// Export all functions
module.exports = {
  normalizePath,
  resolveProjectPath,
  getDocsPath,
  getClaudePath,
  windowsToGitBashPath,
  detectShell,
  pathExists,
  readFile,
  writeFile
};

// Allow running as a script for testing
if (require.main === module) {
  const testPaths = [
    '/c/Users/ken/project',
    '/mnt/c/Users/ken/project',
    'C:\\Users\\ken\\project',
    '/home/ken/project',
    './docs'
  ];

  console.log('Platform:', process.platform);
  console.log('Detected shell:', detectShell());
  console.log('\nPath normalization tests:');
  console.log('─────────────────────────────────────');

  for (const testPath of testPaths) {
    const normalized = normalizePath(testPath);
    console.log(`${testPath.padEnd(30)} → ${normalized}`);
  }
}
