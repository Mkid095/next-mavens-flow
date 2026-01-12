#!/usr/bin/env node
/**
 * Convert PRD files from old availableMcpTools format to new mcpTools format
 * 
 * Old: { "availableMcpTools": { "development-agent": [{ "mcp": "supabase", "tools": [...] }] } }
 * New: { "mcpTools": { "step1": ["supabase"], "step7": ["supabase", "web-search-prime"] } }
 */

const fs = require('fs');
const path = require('path');

// Maven step to agent mapping
const STEP_TO_AGENT = {
  1: 'development-agent',
  2: 'development-agent',
  3: 'refactor-agent',
  4: 'refactor-agent',
  5: 'quality-agent',
  6: 'refactor-agent',
  7: 'development-agent',
  8: 'security-agent',
  9: 'development-agent',
  10: 'security-agent',
  11: 'design-agent'
};

function convertPrdFile(filePath) {
  console.log(`\n🔄 Converting: ${filePath}`);
  
  // Read PRD file
  const content = fs.readFileSync(filePath, 'utf8');
  let prd;
  
  try {
    prd = JSON.parse(content);
  } catch (e) {
    console.error(`❌ Failed to parse JSON: ${e.message}`);
    return false;
  }
  
  let convertedCount = 0;
  
  // Convert each user story
  if (prd.userStories && Array.isArray(prd.userStories)) {
    prd.userStories.forEach((story, index) => {
      const storyId = story.id || `Story ${index + 1}`;
      
      if (story.availableMcpTools) {
        const mcpTools = {};
        
        // Get mavenSteps for this story
        const mavenSteps = story.mavenSteps || [];
        
        // For each step, get the MCPs for that agent
        mavenSteps.forEach(step => {
          const agent = STEP_TO_AGENT[step];
          const agentMcpTools = story.availableMcpTools[agent];
          
          if (agentMcpTools && Array.isArray(agentMcpTools)) {
            // Extract just the MCP names
            const mcpNames = agentMcpTools
              .map(item => typeof item === 'string' ? item : item.mcp)
              .filter(mcp => mcp); // Remove nulls/undefined
            
            if (mcpNames.length > 0) {
              mcpTools[`step${step}`] = [...new Set(mcpNames)]; // Dedupe
            }
          }
        });
        
        // Replace availableMcpTools with mcpTools
        delete story.availableMcpTools;
        
        // Only add mcpTools if there are MCPs to add
        if (Object.keys(mcpTools).length > 0) {
          story.mcpTools = mcpTools;
        }
        
        convertedCount++;
        console.log(`  ✓ Converted ${storyId}: ${Object.keys(mcpTools).length} steps with MCPs`);
      }
    });
  }
  
  // Remove mcpDiscovery if present (no longer needed)
  if (prd.mcpDiscovery) {
    delete prd.mcpDiscovery;
    console.log(`  ✓ Removed mcpDiscovery metadata`);
  }
  
  // Write back with pretty formatting
  const newContent = JSON.stringify(prd, null, 2);
  fs.writeFileSync(filePath, newContent, 'utf8');
  
  console.log(`✅ Successfully converted ${convertedCount} stories`);
  return true;
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('Usage: node convert-prd-mcp.js <prd-file.json>');
    console.log('       node convert-prd-mcp.js <prd-file.json> <another-prd.json>');
    console.log('');
    console.log('Examples:');
    console.log('  node convert-prd-mcp.js docs/prd-admin-dashboard.json');
    console.log('  node convert-prd-mcp.js docs/prd-*.json');
    process.exit(1);
  }
  
  console.log('🔧 Maven Flow PRD MCP Format Converter');
  console.log('====================================\n');
  
  let successCount = 0;
  
  args.forEach(arg => {
    // Handle glob patterns
    if (arg.includes('*')) {
      const { glob } = require('glob');
      const files = glob.sync(arg);
      
      if (files.length === 0) {
        console.log(`⚠ No files found matching: ${arg}`);
        return;
      }
      
      files.forEach(file => {
        if (convertPrdFile(file)) {
          successCount++;
        }
      });
    } else {
      // Single file
      if (fs.existsSync(arg)) {
        if (convertPrdFile(arg)) {
          successCount++;
        }
      } else {
        console.log(`⚠ File not found: ${arg}`);
      }
    }
  });
  
  console.log(`\n✨ Conversion complete! ${successCount} file(s) converted.`);
}

main();
