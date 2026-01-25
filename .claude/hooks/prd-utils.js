#!/usr/bin/env node
/**
 * PRD Utilities - Safe JSON Update with Rollback
 *
 * Provides safe PRD file updates with automatic backup and rollback.
 * - Creates backup before update
 * - Validates JSON before committing
 * - Rolls back on error
 * - Transaction-like behavior for PRD updates
 *
 * Usage:
 *   const prdUtils = require('./prd-utils.js');
 *   await prdUtils.updatePRD('docs/prd-feature.json', (prd) => {
 *     prd.userStories[0].passes = true;
 *     return prd;
 *   });
 *
 * @module prd-utils
 */

const fs = require('fs');
const path = require('path');

// Backup directory
const BACKUP_DIR = '.claude/.prd-backups';

// Maximum number of backups to keep per PRD
const MAX_BACKUPS = 10;

/**
 * Create a backup of a file
 *
 * @param {string} filePath - Path to file to backup
 * @returns {string} Path to backup file
 */
function createBackup(filePath) {
  const backupDir = path.join(path.dirname(filePath), BACKUP_DIR);
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = path.basename(filePath);
  const backupPath = path.join(backupDir, `${filename}.${timestamp}.bak`);

  // Create backup directory if it doesn't exist
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  // Copy file to backup location
  fs.copyFileSync(filePath, backupPath);

  // Clean old backups (keep only MAX_BACKUPS most recent)
  cleanOldBackups(filePath);

  return backupPath;
}

/**
 * Clean old backups for a file
 *
 * @param {string} originalPath - Original file path
 */
function cleanOldBackups(originalPath) {
  const backupDir = path.join(path.dirname(originalPath), BACKUP_DIR);
  const filename = path.basename(originalPath);

  if (!fs.existsSync(backupDir)) {
    return;
  }

  // Get all backup files for this PRD
  const backupFiles = fs.readdirSync(backupDir)
    .filter(f => f.startsWith(filename) && f.endsWith('.bak'))
    .map(f => ({
      name: f,
      path: path.join(backupDir, f),
      time: fs.statSync(path.join(backupDir, f)).mtime.getTime()
    }))
    .sort((a, b) => b.time - a.time); // Sort by time descending (newest first)

  // Remove backups beyond MAX_BACKUPS
  if (backupFiles.length > MAX_BACKUPS) {
    const toDelete = backupFiles.slice(MAX_BACKUPS);
    toDelete.forEach(file => {
      fs.unlinkSync(file.path);
    });
  }
}

/**
 * Rollback to a backup file
 *
 * @param {string} originalPath - Original file path
 * @param {string} backupPath - Backup file path
 * @returns {boolean} True if rollback succeeded
 */
function rollback(originalPath, backupPath) {
  try {
    fs.copyFileSync(backupPath, originalPath);
    return true;
  } catch (error) {
    console.error(`Rollback failed: ${error.message}`);
    return false;
  }
}

/**
 * Validate PRD JSON structure
 *
 * @param {object} prd - PRD object to validate
 * @returns {object} Validation result {valid: boolean, errors: string[]}
 */
function validatePRD(prd) {
  const errors = [];

  // Required top-level fields
  const requiredFields = ['project', 'branchName', 'description', 'memorialFile', 'userStories'];
  for (const field of requiredFields) {
    if (!prd[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Validate userStories array
  if (!Array.isArray(prd.userStories)) {
    errors.push('userStories must be an array');
  } else {
    prd.userStories.forEach((story, index) => {
      const storyPrefix = `userStories[${index}]`;

      // Required story fields
      const requiredStoryFields = ['id', 'title', 'description', 'acceptanceCriteria', 'mavenSteps', 'mcpTools', 'priority', 'passes', 'notes'];
      for (const field of requiredStoryFields) {
        if (story[field] === undefined) {
          errors.push(`${storyPrefix}: missing required field: ${field}`);
        }
      }

      // Validate mavenSteps is array
      if (story.mavenSteps && !Array.isArray(story.mavenSteps)) {
        errors.push(`${storyPrefix}: mavenSteps must be an array`);
      }

      // Validate mcpTools is object
      if (story.mcpTools && typeof story.mcpTools !== 'object') {
        errors.push(`${storyPrefix}: mcpTools must be an object`);
      }

      // Validate acceptanceCriteria is array
      if (story.acceptanceCriteria && !Array.isArray(story.acceptanceCriteria)) {
        errors.push(`${storyPrefix}: acceptanceCriteria must be an array`);
      }

      // Validate priority is number >= 1
      if (typeof story.priority !== 'number' || story.priority < 1) {
        errors.push(`${storyPrefix}: priority must be a number >= 1`);
      }

      // Validate passes is boolean
      if (typeof story.passes !== 'boolean') {
        errors.push(`${storyPrefix}: passes must be a boolean`);
      }
    });
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Update a PRD file with automatic backup and rollback
 *
 * @param {string} filePath - Path to PRD JSON file
 * @param {function} updateFn - Function that takes the PRD object and returns the updated version
 * @param {object} options - Options {createBackup: true, validate: true}
 * @returns {object} Result {success: boolean, backupPath: string, error: string}
 */
function updatePRD(filePath, updateFn, options = {}) {
  const opts = {
    createBackup: true,
    validate: true,
    ...options
  };

  let backupPath = null;

  try {
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return {
        success: false,
        error: `File not found: ${filePath}`
      };
    }

    // Create backup
    if (opts.createBackup) {
      backupPath = createBackup(filePath);
    }

    // Read current PRD
    const content = fs.readFileSync(filePath, 'utf-8');
    let prd;

    try {
      prd = JSON.parse(content);
    } catch (parseError) {
      return {
        success: false,
        error: `Invalid JSON in ${filePath}: ${parseError.message}`,
        backupPath
      };
    }

    // Apply update function
    let updatedPRD;
    try {
      updatedPRD = updateFn(prd);
    } catch (updateError) {
      // Rollback on update function error
      if (backupPath) {
        rollback(filePath, backupPath);
      }
      return {
        success: false,
        error: `Update function failed: ${updateError.message}`,
        backupPath
      };
    }

    // Validate updated PRD
    if (opts.validate) {
      const validation = validatePRD(updatedPRD);
      if (!validation.valid) {
        // Rollback on validation failure
        if (backupPath) {
          rollback(filePath, backupPath);
        }
        return {
          success: false,
          error: `Validation failed:\n${validation.errors.join('\n')}`,
          backupPath
        };
      }
    }

    // Write updated PRD
    const updatedContent = JSON.stringify(updatedPRD, null, 2);
    fs.writeFileSync(filePath, updatedContent, 'utf-8');

    return {
      success: true,
      backupPath
    };

  } catch (error) {
    // Rollback on unexpected error
    if (backupPath) {
      rollback(filePath, backupPath);
    }
    return {
      success: false,
      error: error.message,
      backupPath
    };
  }
}

/**
 * Mark a story as passed in a PRD
 *
 * @param {string} filePath - Path to PRD JSON file
 * @param {string} storyId - Story ID to mark as passed
 * @returns {object} Result {success: boolean, error: string}
 */
function markStoryPassed(filePath, storyId) {
  return updatePRD(filePath, (prd) => {
    const story = prd.userStories.find(s => s.id === storyId);
    if (!story) {
      throw new Error(`Story ${storyId} not found`);
    }
    story.passes = true;
    return prd;
  });
}

/**
 * Update story notes in a PRD
 *
 * @param {string} filePath - Path to PRD JSON file
 * @param {string} storyId - Story ID to update
 * @param {string} notes - New notes content
 * @returns {object} Result {success: boolean, error: string}
 */
function updateStoryNotes(filePath, storyId, notes) {
  return updatePRD(filePath, (prd) => {
    const story = prd.userStories.find(s => s.id === storyId);
    if (!story) {
      throw new Error(`Story ${storyId} not found`);
    }
    story.notes = notes;
    return prd;
  });
}

/**
 * Get all backup files for a PRD
 *
 * @param {string} filePath - Original PRD file path
 * @returns {array} Array of backup file info {path, timestamp}
 */
function listBackups(filePath) {
  const backupDir = path.join(path.dirname(filePath), BACKUP_DIR);
  const filename = path.basename(filePath);

  if (!fs.existsSync(backupDir)) {
    return [];
  }

  const backupFiles = fs.readdirSync(backupDir)
    .filter(f => f.startsWith(filename) && f.endsWith('.bak'))
    .map(f => {
      const backupPath = path.join(backupDir, f);
      const stats = fs.statSync(backupPath);
      // Extract timestamp from filename
      const timestampMatch = f.match(/\.(\d{4}-\d{2}-\d{2}T[\d-]+)\.bak$/);
      return {
        path: backupPath,
        filename: f,
        timestamp: timestampMatch ? timestampMatch[1] : stats.mtime.toISOString(),
        mtime: stats.mtime
      };
    })
    .sort((a, b) => b.mtime - a.mtime); // Sort by time descending

  return backupFiles;
}

/**
 * Restore a PRD from a backup
 *
 * @param {string} originalPath - Original PRD file path
 * @param {string} backupFilename - Backup filename to restore
 * @returns {object} Result {success: boolean, error: string}
 */
function restoreBackup(originalPath, backupFilename) {
  const backupDir = path.join(path.dirname(originalPath), BACKUP_DIR);
  const backupPath = path.join(backupDir, backupFilename);

  if (!fs.existsSync(backupPath)) {
    return {
      success: false,
      error: `Backup not found: ${backupFilename}`
    };
  }

  try {
    // Create backup of current file before restoring
    const currentBackup = createBackup(originalPath);

    // Copy backup to original location
    fs.copyFileSync(backupPath, originalPath);

    return {
      success: true,
      previousBackup: currentBackup
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// Export all functions
module.exports = {
  updatePRD,
  markStoryPassed,
  updateStoryNotes,
  validatePRD,
  createBackup,
  rollback,
  listBackups,
  restoreBackup,
  BACKUP_DIR,
  MAX_BACKUPS
};

// Allow running as a script for testing
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('PRD Utilities - Safe JSON Update with Rollback');
    console.log('');
    console.log('Usage:');
    console.log('  node prd-utils.js <prd-file> <command> [args]');
    console.log('');
    console.log('Commands:');
    console.log('  validate              - Validate PRD structure');
    console.log('  mark-passed <story-id> - Mark story as passed');
    console.log('  list-backups          - List all backups');
    console.log('  restore <backup-file>  - Restore from backup');
    console.log('');
    process.exit(0);
  }

  const [prdFile, command, ...cmdArgs] = args;

  switch (command) {
    case 'validate': {
      const content = fs.readFileSync(prdFile, 'utf-8');
      const prd = JSON.parse(content);
      const result = validatePRD(prd);
      if (result.valid) {
        console.log('✅ PRD is valid');
        process.exit(0);
      } else {
        console.log('❌ PRD validation failed:');
        result.errors.forEach(e => console.log(`  - ${e}`));
        process.exit(1);
      }
    }

    case 'mark-passed': {
      const storyId = cmdArgs[0];
      const result = markStoryPassed(prdFile, storyId);
      if (result.success) {
        console.log(`✅ Marked ${storyId} as passed`);
        console.log(`   Backup: ${result.backupPath}`);
      } else {
        console.log(`❌ Failed: ${result.error}`);
        process.exit(1);
      }
      break;
    }

    case 'list-backups': {
      const backups = listBackups(prdFile);
      if (backups.length === 0) {
        console.log('No backups found');
      } else {
        console.log(`Backups for ${prdFile}:`);
        backups.forEach(b => {
          console.log(`  ${b.filename} (${b.timestamp})`);
        });
      }
      break;
    }

    case 'restore': {
      const backupFile = cmdArgs[0];
      const result = restoreBackup(prdFile, backupFile);
      if (result.success) {
        console.log(`✅ Restored from ${backupFile}`);
      } else {
        console.log(`❌ Failed: ${result.error}`);
        process.exit(1);
      }
      break;
    }

    default:
      console.log(`Unknown command: ${command}`);
      process.exit(1);
  }
}
