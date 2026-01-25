#!/bin/bash
# ============================================================================
# MAVEN STOP HOOK - Comprehensive Quality Check
# Runs before completing work - validates all quality standards
# ZERO TOLERANCE: No 'any' types, no gradients
# Spawns specialized agents for different issues
# ============================================================================

set -e

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Maven Comprehensive Quality Check"
echo "═══════════════════════════════════════════════════════"
echo ""

PROJECT_ROOT="$CLAUDE_PROJECT_DIR"
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(pwd)"
fi

# Check if src directory exists
if [ ! -d "$PROJECT_ROOT/src" ]; then
  echo "ℹ️  No src/ directory found - skipping quality checks"
  echo "✅ Ready to proceed!"
  exit 0
fi

# Initialize counters
TOTAL_ISSUES=0
BLOCKING_ISSUES=0
SPAWNED_AGENTS=0
mkdir -p /tmp/maven_agents

# ============================================================================
# CATEGORY 1: Large Components (Modularization Needed)
# ============================================================================
echo "📏 Checking component sizes..."

LARGE_COMPONENTS=$(find "$PROJECT_ROOT/src" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$1 > 300 {print $2, $1}' || true)

if [ ! -z "$LARGE_COMPONENTS" ]; then
  echo "  ⚠️  Found components >300 lines:"
  while IFS= read -r line; do
    FILE=$(echo "$line" | awk '{print $1}')
    LINES=$(echo "$line" | awk '{print $2}')
    echo "    - $FILE ($LINES lines)"
    TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
  done <<< "$LARGE_COMPONENTS"

  # Create modularization agent task
  cat > "/tmp/maven_agents/modularize_$SPAWNED_AGENTS.md" << EOF
# Modularization Task

Large components detected:
$LARGE_COMPONENTS

## Instructions:
For each component >300 lines:
1. Analyze component structure
2. Extract sub-components
3. Extract custom hooks
4. Extract utilities
5. Ensure all imports use @ aliases
6. Validate no functionality lost

## Target:
All components <300 lines
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ All components under 300 lines"
fi

# ============================================================================
# CATEGORY 2: Type Safety Issues (ZERO TOLERANCE - BLOCKING)
# ============================================================================
echo "🔍 Checking type safety (ZERO TOLERANCE)..."

# Count all variations of 'any' types
ANY_BASIC=$(rg ": any\b" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
ANY_ARRAY=$(rg ": any\[" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
ANY_GENERIC=$(rg ": any<" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
ANY_ASSERTION=$(rg "as any" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
PROMISE_ANY=$(rg ": Promise<any>" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
RECORD_ANY=$(rg "Record<string, any>|Record<any, any>" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
GENERIC_DEFAULT=$(rg "<[A-Za-z]* = any>" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")

ANY_COUNT=$((ANY_BASIC + ANY_ARRAY + ANY_GENERIC + ANY_ASSERTION + PROMISE_ANY + RECORD_ANY + GENERIC_DEFAULT))

if [ "$ANY_COUNT" -gt 0 ]; then
  echo "  🚨 BLOCKING: Found $ANY_COUNT 'any' type(s) - ZERO TOLERANCE"
  echo "     → Commit blocked until fixed"
  TOTAL_ISSUES=$((TOTAL_ISSUES + ANY_COUNT))
  BLOCKING_ISSUES=$((BLOCKING_ISSUES + ANY_COUNT))

  # Show breakdown
  if [ "$ANY_BASIC" -gt 0 ]; then
    echo "       - : any → $ANY_BASIC instances"
  fi
  if [ "$ANY_ARRAY" -gt 0 ]; then
    echo "       - : any[] → $ANY_ARRAY instances"
  fi
  if [ "$ANY_ASSERTION" -gt 0 ]; then
    echo "       - as any → $ANY_ASSERTION instances"
  fi

  # Create type fix agent task
  cat > "/tmp/maven_agents/fix_types_$SPAWNED_AGENTS.md" << EOF
# Type Safety Fix Task - BLOCKING

Found $ANY_COUNT instances of 'any' type (ZERO TOLERANCE).

## Breakdown:
- : any → $ANY_BASIC instances
- : any[] → $ANY_ARRAY instances
- : any< → $ANY_GENERIC instances
- as any → $ANY_ASSERTION instances
- Promise<any> → $PROMISE_ANY instances
- Record<any> → $RECORD_ANY instances
- <T = any> → $GENERIC_DEFAULT instances

## Instructions:
1. Find all 'any' types: \`rg ": any\b" -t ts\`
2. For each instance:
   - Analyze usage context
   - Define proper interface or type
   - Replace 'any' with proper type
3. Validate TypeScript compiles

## Replacement Strategies:
- Unknown data → 'unknown' + type guard
- Generic objects → 'Record<string, T>'
- Function params → Define interface
- Third-party → Create .d.ts declaration
- Event handlers → Use proper React types

## ZERO TOLERANCE:
ALL 'any' types must be removed before commit.
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ No 'any' types found"
fi

# ============================================================================
# CATEGORY 3: Gradients (ZERO TOLERANCE - BLOCKING)
# ============================================================================
echo "🎨 Checking for gradients (ZERO TOLERANCE)..."

# Check CSS/SCSS files
LINEAR=$(rg "linear-gradient\(" -t css -t scss -t sass -t less "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
RADIAL=$(rg "radial-gradient\(" -t css -t scss -t sass -t less "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
CONIC=$(rg "conic-gradient\(" -t css -t scss -t sass -t less "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")
REPEATING=$(rg "repeating-(linear|radial|conic)-gradient\(" -t css -t scss -t sass -t less "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")

# Check TSX/JSX for inline gradients
INLINE_GRADIENT=$(rg "linear-gradient|radial-gradient|conic-gradient" -t tsx -t jsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")

GRADIENT_COUNT=$((LINEAR + RADIAL + CONIC + REPEATING + INLINE_GRADIENT))

if [ "$GRADIENT_COUNT" -gt 0 ]; then
  echo "  🚨 BLOCKING: Found $GRADIENT_COUNT gradient(s) - ZERO TOLERANCE"
  echo "     → Commit blocked until removed (use solid professional colors only)"
  TOTAL_ISSUES=$((TOTAL_ISSUES + GRADIENT_COUNT))
  BLOCKING_ISSUES=$((BLOCKING_ISSUES + GRADIENT_COUNT))

  # Show breakdown
  if [ "$LINEAR" -gt 0 ]; then
    echo "       - linear-gradient → $LINEAR instances"
  fi
  if [ "$RADIAL" -gt 0 ]; then
    echo "       - radial-gradient → $RADIAL instances"
  fi
  if [ "$CONIC" -gt 0 ]; then
    echo "       - conic-gradient → $CONIC instances"
  fi
  if [ "$INLINE_GRADIENT" -gt 0 ]; then
    echo "       - inline (TSX/JSX) → $INLINE_GRADIENT instances"
  fi

  # Create gradient fix agent task
  cat > "/tmp/maven_agents/fix_gradients_$SPAWNED_AGENTS.md" << EOF
# Gradient Fix Task - BLOCKING

Found $GRADIENT_COUNT gradient(s) in codebase (ZERO TOLERANCE).

## Breakdown:
- linear-gradient → $LINEAR instances
- radial-gradient → $RADIAL instances
- conic-gradient → $CONIC instances
- repeating gradients → $REPEATING instances
- inline gradients → $INLINE_GRADIENT instances

## Instructions:
1. Find all gradients: \`rg "gradient" -t css -t scss -t tsx\`
2. Replace with solid professional colors:
   - Use hex: #3b82f6, #10b981, #ef4444
   - Use CSS variables: var(--color-primary)
   - Use RGB/RGBA: rgb(59, 130, 246), rgba(59, 130, 246, 0.5)
   - Use HSL/HSLA: hsl(217, 91%, 60%)

## Professional Color Palette:
\`\`\`css
:root {
  --color-blue-50: #eff6ff;
  --color-blue-500: #3b82f6;
  --color-blue-600: #2563eb;
  --color-gray-50: #f9fafb;
  --color-gray-500: #6b7280;
  --color-gray-900: #111827;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
}
\`\`\`

## ZERO TOLERANCE:
ALL gradients must be removed before commit.
Use solid professional colors only.
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ No gradients found (solid colors only)"
fi

# ============================================================================
# CATEGORY 4: Import Path Violations
# ============================================================================
echo "📦 Checking import paths..."

RELATIVE_COUNT=$(rg "from ['\"]\.\.?\/" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | wc -l || echo "0")

if [ "$RELATIVE_COUNT" -gt 0 ]; then
  echo "  ⚠️  Found $RELATIVE_COUNT relative import(s)"
  TOTAL_ISSUES=$((TOTAL_ISSUES + RELATIVE_COUNT))

  # Create import fix agent task
  cat > "/tmp/maven_agents/fix_imports_$SPAWNED_AGENTS.md" << EOF
# Import Path Fix Task

Found $RELATIVE_COUNT relative imports that should use @ aliases.

## Instructions:
1. Find all relative imports: \`rg "from ['\\"]\\.\\.?/" -t ts\`
2. Convert to @ aliases:
   - '../shared/X' → '@shared/X'
   - '../../features/Y' → '@features/Y'
   - './utils/Z' → Keep local if within same feature
3. Verify tsconfig.json has paths configured
4. Validate all imports resolve

## tsconfig.json should have:
\`\`\`json
{
  "compilerOptions": {
    "paths": {
      "@shared/*": ["./src/shared/*"],
      "@features/*": ["./src/features/*"],
      "@app/*": ["./src/app/*"],
      "@/*": ["./src/*"]
    }
  }
}
\`\`\`
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ All imports use @ aliases"
fi

# ============================================================================
# CATEGORY 5: Cross-Feature Imports (Architecture Violation)
# ============================================================================
echo "🏗️  Checking feature isolation..."

if [ -f "$PROJECT_ROOT/eslint.config.mjs" ] || [ -f "$PROJECT_ROOT/.eslintrc.js" ]; then
  # Get TypeScript files changed in this session (staged + unstaged)
  CHANGED_TS_FILES=$(cd "$PROJECT_ROOT" && git diff --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' || true)
  CHANGED_TS_FILES="$CHANGED_TS_FILES$(cd "$PROJECT_ROOT" && git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' || true)"

  if [ -n "$CHANGED_TS_FILES" ]; then
    # Run ESLint only on changed TypeScript files
    ESLINT_RESULT=$(cd "$PROJECT_ROOT" && echo "$CHANGED_TS_FILES" | xargs -r pnpm eslint --quiet 2>&1 || true)

    if echo "$ESLINT_RESULT" | grep -q "boundaries\|error\|warning"; then
      echo "  ⚠️  ESLint violations detected in changed files:"
      echo "$ESLINT_RESULT" | head -10
      TOTAL_ISSUES=$((TOTAL_ISSUES + $(echo "$ESLINT_RESULT" | grep -c "error\|warning" || echo "0")))

      cat > "/tmp/maven_agents/fix_boundaries_$SPAWNED_AGENTS.md" << EOF
# Feature Boundary Violation Fix

ESLint detected violations in changed files.

## Files checked:
$(echo "$CHANGED_TS_FILES" | sed 's/^/  - /')

## Instructions:
1. Review ESLint output for violations
2. Move shared code to appropriate location:
   - If used by multiple features → Move to shared/
   - If feature-specific → Keep in feature/
   - Update imports to respect boundaries
3. Re-run ESLint to verify

## Architecture Rules:
- Features CANNOT import from other features
- Features CAN import from shared/
- App CAN import from features and shared
- Shared CANNOT import from features or app
EOF
      SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
    else
      echo "  ✅ Feature boundaries respected (checked $(echo "$CHANGED_TS_FILES" | wc -l) changed files)"
    fi
  else
    echo "  ℹ️  No TypeScript files changed - skipping ESLint check"
  fi
else
  echo "  ⚠️  ESLint boundaries not configured"
  echo "    Run: Load refactor-agent and setup ESLint boundaries"
fi

# ============================================================================
# CATEGORY 6: UI Component Duplication
# ============================================================================
echo "🎨 Checking UI component consolidation..."

# Find duplicate Button components (excluding shared/ui)
DUPLICATE_BUTTON=$(rg "export (const|function) Button" -t ts -t tsx "$PROJECT_ROOT/src/features" 2>/dev/null | wc -l || echo "0")

if [ "$DUPLICATE_BUTTON" -gt 0 ]; then
  echo "  ⚠️  Found $DUPLICATE_BUTTON duplicate Button component(s)"
  echo "    Should consolidate to @shared/ui"
  TOTAL_ISSUES=$((TOTAL_ISSUES + DUPLICATE_BUTTON))

  cat > "/tmp/maven_agents/consolidate_ui_$SPAWNED_AGENTS.md" << EOF
# UI Consolidation Task

Found duplicate UI components.

## Instructions:
1. Identify all duplicate components
2. Create canonical version in @shared/ui/
3. Replace all usages with @shared/ui/X
4. Remove duplicate implementations
5. Update @shared/ui/index.ts to export
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ UI components centralized"
fi

# ============================================================================
# CATEGORY 7: Security Scan
# ============================================================================
echo "🔒 Running security scan..."

SECRET_FINDINGS=()

# Check for exposed API keys
if rg "api_key\s*=\s*['\"][^'\"]{20,}" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | grep -q .; then
  SECRET_FINDINGS+=("exposed_api_keys")
fi

# Check for hardcoded passwords
if rg "password\s*=\s*['\"]" -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | grep -q .; then
  SECRET_FINDINGS+=("hardcoded_passwords")
fi

# Check for tokens in code
if rg "token\s*=\s*['\"]ya29\." -t ts -t tsx "$PROJECT_ROOT/src" 2>/dev/null | grep -q .; then
  SECRET_FINDINGS+=("exposed_tokens")
fi

# Check .env files
if [ -f "$PROJECT_ROOT/.env" ]; then
  if grep -q "VITE_.*=.*\.\.\|API_KEY.*=.*\w{20,}" "$PROJECT_ROOT/.env" 2>/dev/null; then
    SECRET_FINDINGS+=("env_secrets")
  fi
fi

if [ ${#SECRET_FINDINGS[@]} -gt 0 ]; then
  echo "  🚨 Security issues detected:"
  for finding in "${SECRET_FINDINGS[@]}"; do
    echo "    - $finding"
  done
  TOTAL_ISSUES=$((TOTAL_ISSUES + ${#SECRET_FINDINGS[@]}))
  BLOCKING_ISSUES=$((BLOCKING_ISSUES + ${#SECRET_FINDINGS[@]}))

  cat > "/tmp/maven_agents/security_fix_$SPAWNED_AGENTS.md" << EOF
# Security Fix - URGENT (BLOCKING)

Security vulnerabilities detected: ${SECRET_FINDINGS[@]}

## Instructions:
1. IMMEDIATE: Remove any exposed secrets
2. Move secrets to environment variables
3. Update .env.example (without real values)
4. Regenerate any compromised keys/tokens
5. Verify .gitignore excludes .env
6. Run: Load security-agent for full audit
EOF
  SPAWNED_AGENTS=$((SPAWNED_AGENTS + 1))
else
  echo "  ✅ No security issues detected"
fi

# ============================================================================
# SUMMARY & DECISION
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Quality Check Summary"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check for blocking issues first
if [ $BLOCKING_ISSUES -gt 0 ]; then
  echo "❌ COMMIT BLOCKED - $BLOCKING_ISSUES blocking issue(s)"
  echo ""
  echo "Zero Tolerance Violations:"
  echo "  • 'any' types: $ANY_COUNT instances - MUST BE FIXED"
  echo "  • Gradients: $GRADIENT_COUNT instances - MUST BE REMOVED"
  echo "  • Security issues: ${#SECRET_FINDINGS[@]} findings - MUST BE FIXED"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  BLOCKING: Fix all zero tolerance violations before commit"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Agent tasks created: $SPAWNED_AGENTS"
  echo "Available in: /tmp/maven_agents/"
  echo ""
  echo "Load quality-agent to assist with fixes."
  echo ""
  exit 2
fi

if [ $TOTAL_ISSUES -eq 0 ]; then
  echo "✅ ALL CHECKS PASSED!"
  echo ""
  echo "Your code meets all Maven quality standards:"
  echo "  • Components under 300 lines"
  echo "  • No 'any' types (ZERO TOLERANCE)"
  echo "  • No gradients (ZERO TOLERANCE) - solid professional colors only"
  echo "  • All imports use @ aliases"
  echo "  • Feature boundaries respected"
  echo "  • UI components centralized"
  echo "  • No security issues"
  echo ""
  echo "🎉 Ready to commit!"
  exit 0
fi

echo "Issues found: $TOTAL_ISSUES"
echo "Agent tasks created: $SPAWNED_AGENTS"
echo ""
echo "Agent tasks available in: /tmp/maven_agents/"
echo ""

if [ $SPAWNED_AGENTS -gt 0 ]; then
  echo "🤖 Recommended: Spawn agents to fix issues automatically"
  echo ""
  echo "Available agents:"
  ls -1 /tmp/maven_agents/ | sed 's/.md$/ → /'
  echo ""
  echo "These agents can run in parallel to fix issues faster."
  echo ""
fi

echo "⚠️  Please review and fix issues before committing"
exit 1
