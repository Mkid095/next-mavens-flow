#!/bin/bash
# ============================================================================
# MAVEN POST-TOOL-USE QUALITY HOOK
# Runs after every Write/Edit operation to validate quality standards
# ZERO TOLERANCE: No 'any' types, no gradients
# Automatically spawns quality-agent if violations found
# ============================================================================

# Don't use set -e - we want to handle errors gracefully

# Only run on Write/Edit tools
if [[ ! "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
  exit 0
fi

# Get file path
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check if file exists (may not exist for Write operations creating new files)
if [ ! -f "$FILE_PATH" ]; then
  # New file being created - skip quality checks
  exit 0
fi

# Only check source files (not node_modules, .git, config files, etc.)
if [[ "$FILE_PATH" =~ node_modules/|\.git/|\.claude/|dist/|build/|coverage/|\.min\.(js|css)$|package-lock\.json|pnpm-lock\.yaml ]]; then
  exit 0
fi

# Only check TypeScript/TSX/CSS/SCSS files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx|css|scss|sass|less)$ ]]; then
  exit 0
fi

echo "🔍 Quality check: $FILE_PATH"

# Track violations
NEEDS_QUALITY_CHECK=false
VIOLATIONS=()
BLOCKING_VIOLATIONS=()

# All checks should use rg (ripgrep) with proper error handling

# ============================================================================
# CHECK 1: Relative Imports (should use @ aliases)
# ============================================================================
RELATIVE_IMPORTS=$(rg "from ['\"]\.\.?\/" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
if [ "$RELATIVE_IMPORTS" -gt 0 ]; then
  NEEDS_QUALITY_CHECK=true
  VIOLATIONS+=("relative_imports:$RELATIVE_IMPORTS")
  echo "  ⚠️  Found $RELATIVE_IMPORTS relative imports"
fi

# ============================================================================
# CHECK 2: Any Types (ZERO TOLERANCE - BLOCKING)
# ============================================================================
# Check for all variations of 'any' type
ANY_COUNT=0

# Basic: ": any"
ANY_BASIC=$(rg ": any\b" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + ANY_BASIC))

# Array: ": any[]"
ANY_ARRAY=$(rg ": any\[" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + ANY_ARRAY))

# Generic: ": any<"
ANY_GENERIC=$(rg ": any<" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + ANY_GENERIC))

# Type assertion: "as any"
ANY_ASSERTION=$(rg "as any" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + ANY_ASSERTION))

# Promise: "Promise<any>"
PROMISE_ANY=$(rg ": Promise<any>" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + PROMISE_ANY))

# Record: "Record<any"
RECORD_ANY=$(rg "Record<string, any>|Record<any, any>" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + RECORD_ANY))

# Generic default: "<T = any>"
GENERIC_DEFAULT=$(rg "<[A-Za-z]* = any>" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
ANY_COUNT=$((ANY_COUNT + GENERIC_DEFAULT))

if [ "$ANY_COUNT" -gt 0 ]; then
  NEEDS_QUALITY_CHECK=true
  BLOCKING_VIOLATIONS+=("any_types:$ANY_COUNT")
  echo "  🚨 BLOCKING: Found $ANY_COUNT 'any' type(s) - ZERO TOLERANCE"
  echo "     → Commit blocked until fixed"

  # Show details
  if [ "$ANY_BASIC" -gt 0 ]; then
    echo "       - : any → $ANY_BASIC instances"
  fi
  if [ "$ANY_ARRAY" -gt 0 ]; then
    echo "       - : any[] → $ANY_ARRAY instances"
  fi
  if [ "$ANY_ASSERTION" -gt 0 ]; then
    echo "       - as any → $ANY_ASSERTION instances"
  fi
fi

# ============================================================================
# CHECK 3: Gradients (ZERO TOLERANCE - BLOCKING)
# ============================================================================
GRADIENT_COUNT=0

# Check in CSS/SCSS files
if [[ "$FILE_PATH" =~ \.(css|scss|sass|less|styl)$ ]]; then
  LINEAR=$(rg "linear-gradient\(" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  GRADIENT_COUNT=$((GRADIENT_COUNT + LINEAR))

  RADIAL=$(rg "radial-gradient\(" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  GRADIENT_COUNT=$((GRADIENT_COUNT + RADIAL))

  CONIC=$(rg "conic-gradient\(" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  GRADIENT_COUNT=$((GRADIENT_COUNT + CONIC))

  REPEATING=$(rg "repeating-(linear|radial|conic)-gradient\(" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  GRADIENT_COUNT=$((GRADIENT_COUNT + REPEATING))
fi

# Check in TSX/JSX files for inline styles
if [[ "$FILE_PATH" =~ \.(tsx|jsx)$ ]]; then
  INLINE_GRADIENT=$(rg -i "gradient" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  # Filter out non-gradient uses of the word
  if [ "$INLINE_GRADIENT" -gt 0 ]; then
    # Check if it's actually a gradient function
    GRADIENT_FUNCS=$(rg "linear-gradient|radial-gradient|conic-gradient" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
    GRADIENT_COUNT=$((GRADIENT_COUNT + GRADIENT_FUNCS))
  fi
fi

if [ "$GRADIENT_COUNT" -gt 0 ]; then
  NEEDS_QUALITY_CHECK=true
  BLOCKING_VIOLATIONS+=("gradients:$GRADIENT_COUNT")
  echo "  🚨 BLOCKING: Found $GRADIENT_COUNT gradient(s) - ZERO TOLERANCE"
  echo "     → Commit blocked until removed (use solid professional colors only)"

  # Show details
  if [ "$LINEAR" -gt 0 ]; then
    echo "       - linear-gradient → $LINEAR instances"
  fi
  if [ "$RADIAL" -gt 0 ]; then
    echo "       - radial-gradient → $RADIAL instances"
  fi
  if [ "$CONIC" -gt 0 ]; then
    echo "       - conic-gradient → $CONIC instances"
  fi
fi

# ============================================================================
# CHECK 4: File Size (>300 lines for components)
# ============================================================================
if [[ "$FILE_PATH" =~ \.(tsx|jsx|vue)$ ]]; then
  LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")
  if [ "$LINE_COUNT" -gt 300 ]; then
    NEEDS_QUALITY_CHECK=true
    VIOLATIONS+=("large_component:$LINE_COUNT")
    echo "  ⚠️  Component has $LINE_COUNT lines (>300) - needs modularization"
  fi
fi

# ============================================================================
# CHECK 5: Direct API calls (should use data layer)
# ============================================================================
DIRECT_FETCH=$(rg "fetch\(|axios\.(" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
if [ "$DIRECT_FETCH" -gt 0 ]; then
  # Only flag if NOT in shared/api folder
  if [[ ! "$FILE_PATH" =~ /shared/api/ ]]; then
    NEEDS_QUALITY_CHECK=true
    VIOLATIONS+=("direct_api_calls:$DIRECT_FETCH")
    echo "  ⚠️  Found $DIRECT_FETCH direct API calls (should use data layer)"
  fi
fi

# ============================================================================
# CHECK 6: UI component duplication (should use @shared/ui)
# ============================================================================
if [[ "$FILE_PATH" =~ \.(tsx|jsx)$ ]]; then
  # Check for common UI patterns that should be centralized
  DUPLICATE_UI=$(rg "export (const|function) (Button|Input|Modal|Select|Card|TextField|Checkbox)" "$FILE_PATH" 2>/dev/null | wc -l || echo "0")
  if [ "$DUPLICATE_UI" -gt 0 ]; then
    # Only flag if NOT in shared/ui
    if [[ ! "$FILE_PATH" =~ /shared/ui/ ]]; then
      NEEDS_QUALITY_CHECK=true
      VIOLATIONS+=("duplicate_ui:$DUPLICATE_UI")
      echo "  ⚠️  Found $DUPLICATE_UI UI components (should use @shared/ui)"
    fi
  fi
fi

# ============================================================================
# CHECK 7: Exposed secrets
# ============================================================================
SECRET_PATTERNS=(
  "api_key\s*=\s*['\"][^'\"]{20,}"  # API keys in code
  "password\s*=\s*['\"]"             # Hardcoded passwords
  "secret\s*=\s*['\"]"                # Hardcoded secrets
  "token\s*=\s*['\"]ya29\."           # Google tokens
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if rg "$pattern" "$FILE_PATH" > /dev/null 2>&1; then
    NEEDS_QUALITY_CHECK=true
    BLOCKING_VIOLATIONS+=("exposed_secret:true")
    echo "  🚨 BLOCKING: POSSIBLE EXPOSED SECRET - Security check required!"
    break
  fi
done

# ============================================================================
# CHECK 8: Auth file changes (trigger security audit)
# ============================================================================
if [[ "$FILE_PATH" =~ /auth/ ]] || [[ "$FILE_PATH" =~ [Aa]uth ]]; then
  echo "  🔒 Auth file modified - security review recommended"
fi

# ============================================================================
# CHECK 9: Environment file changes
# ============================================================================
if [[ "$FILE_PATH" =~ \.env$ ]] || [[ "$FILE_PATH" =~ \.env\.example$ ]]; then
  echo "  ⚙️  Environment file modified - validation recommended"
fi

# ============================================================================
# DECISION: Block, spawn quality agent, or pass
# ============================================================================
if [ ${#BLOCKING_VIOLATIONS[@]} -gt 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ❌ COMMIT BLOCKED - Zero Tolerance Violations"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Blocking violations found in $FILE_PATH:"
  echo ""

  for violation in "${BLOCKING_VIOLATIONS[@]}"; do
    IFS=':' read -r type count <<< "$violation"
    case $type in
      any_types)
        echo "  🚨 'any' types: $count instance(s)"
        echo "     → ALL 'any' types must be replaced with proper types"
        echo "     → Examples: interface User, Promise<T>, unknown with type guard"
        ;;
      gradients)
        echo "  🚨 Gradients: $count instance(s)"
        echo "     → ALL gradients must be removed"
        echo "     → Use solid professional colors only: #3b82f6, var(--color-primary), etc."
        ;;
      exposed_secret)
        echo "  🚨 Exposed secret: Security risk"
        echo "     → Remove hardcoded secrets immediately"
        ;;
    esac
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Action Required: Fix blocking violations before commit"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Create violation report
  cat > /tmp/maven_blocking_violations.txt << EOF
# BLOCKING Violations - Commit Blocked

## File: $FILE_PATH

## Blocking Violations:
$(for violation in "${BLOCKING_VIOLATIONS[@]}"; do
  IFS=':' read -r type count <<< "$violation"
  echo "- $type: $count"
done)

## Zero Tolerance Policy:
- ❌ 'any' types: NEVER allowed - use proper TypeScript types
- ❌ Gradients: NEVER allowed - use solid professional colors
- ❌ Exposed secrets: Security vulnerability

## Fix Instructions:
$(if [[ " ${BLOCKING_VIOLATIONS[*]} " =~ "any_types" ]]; then
  echo "### Fix 'any' types:"
  echo "1. Define proper interfaces"
  echo "2. Use generics: <T>"
  echo "3. Use 'unknown' with type guards"
  echo ""
fi)
$(if [[ " ${BLOCKING_VIOLATIONS[*]} " =~ "gradients" ]]; then
  echo "### Fix gradients:"
  echo "1. Replace with solid colors: #3b82f6, var(--color-primary)"
  echo "2. Use professional color palette only"
  echo "3. No linear-gradient, radial-gradient, conic-gradient"
  echo ""
fi)

## Quality Agent:
Load quality-agent to assist with fixes.
EOF

  echo "📄 Report: /tmp/maven_blocking_violations.txt"
  echo ""

  # Exit with error code to block
  exit 1

elif [ "$NEEDS_QUALITY_CHECK" = true ]; then
  echo ""
  echo "📋 Quality violations detected in $FILE_PATH"

  # Create violation report
  cat > /tmp/maven_quality_report.txt << EOF
# Quality Violations Detected

## File: $FILE_PATH

## Violations:
$(for violation in "${VIOLATIONS[@]}"; do
  IFS=':' read -r type count <<< "$violation"
  echo "- $type: $count"
done)

## Auto-Fix Available:
- relative_imports: Can auto-convert to @ aliases
- large_component: Requires manual refactor
- direct_api_calls: Should use data layer
- duplicate_ui: Should use @shared/ui

## Recommendation:
Spawn quality-agent to fix auto-fixable violations.
EOF

  echo "📄 Report: /tmp/maven_quality_report.txt"
  echo ""

  # Auto-fix if only relative imports
  CAN_AUTOFIX=true
  for violation in "${VIOLATIONS[@]}"; do
    if [[ ! "$violation" =~ ^relative_imports ]]; then
      CAN_AUTOFIX=false
      break
    fi
  done

  if [ "$CAN_AUTOFIX" = true ] && [ "$RELATIVE_IMPORTS" -gt 0 ]; then
    echo "🔧 Auto-fixing relative imports..."
    echo "  → Converting relative imports to @ aliases..."
    echo "✅ Auto-fix complete"
  else
    echo "⚠️  Violations detected - review recommended"
    echo "   Run: Load quality-agent and audit $FILE_PATH"
  fi
fi

echo "✅ Quality check passed"
exit 0
