---
name: validate-build
description: Runs phased build validation -- syntax check, full compilation, error classification against CodeLessonsLearned, and produces a validation report. Use after generating or modifying code.
argument-hint: "[ContentGenerator | LLMmanagement | ProjectExchange]"
disable-model-invocation: true
---

# Phased Build Validation

Run the validation framework to verify code compiles cleanly. Classify any errors against CodeLessonsLearned.md and attempt resolution.

## Step 1: Select Build Command

Based on the target project argument:

| Target | Build Command |
|--------|--------------|
| **ContentGenerator** | `xcodebuild build -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS'` |
| **LLMmanagement** | `swift build` (run from `LLMmanagement/` directory) |
| **ProjectExchange** | `swift build` (run from `ProjectExchange/` directory) |

## Step 2: Syntax Check (Dry Run)

For ContentGenerator:
```bash
xcodebuild -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' -dry-run build 2>&1 | grep -E "(error|warning):"
```

For Swift packages:
```bash
swift build 2>&1 | head -50
```

If the syntax check produces errors, report them and continue to Phase 2 for full detail.

## Step 3: Full Compilation

Run a clean build to get complete error output:

For ContentGenerator:
```bash
xcodebuild clean build -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' 2>&1
```

For Swift packages:
```bash
swift package clean && swift build 2>&1
```

If the build succeeds (`BUILD SUCCEEDED` or exit code 0), skip to Phase 5 (report).

## Step 4: Error Classification

On build failure, classify each error against the target project's `CodeLessonsLearned.md`:

1. Extract all error lines from the build output
2. Read `<TargetProject>/Specs/CodeLessonsLearned.md`
3. For each error, search CodeLessonsLearned.md for:
   - Matching error messages
   - Matching root causes
   - Matching categories (SWIFT, DATA, UI, RUNTIME, TEST, CONCURRENCY)
4. Classify each error as:
   - **KNOWN** -- has a matching entry with a documented Proven Fix
   - **NEW** -- no matching entry found

## Step 5: Fix and Rebuild

For each **KNOWN** error:
1. Apply the Proven Fix documented in CodeLessonsLearned.md
2. Track which fix was applied

For each **NEW** error:
1. Analyze the error and apply a fix
2. Track the fix for later documentation

After applying all fixes, rebuild (repeat Phase 2). Continue this cycle until either:
- The build succeeds, or
- No further progress is made (same errors persist after fixes)

## Step 6: Validation Report

Produce a structured validation report:

```
## Build Validation Report

**Target**: [project name]
**Result**: [PASSED | FAILED]
**Date**: [today's date]

### Build Summary
- Total errors encountered: [count]
- Errors resolved via CodeLessonsLearned: [count]
- New errors resolved: [count]
- Unresolved errors: [count]
- Warnings: [count]

### Errors Resolved from Lessons Learned
| Error ID | Error Message | Fix Applied |
|----------|--------------|-------------|
| ERR-XXX-NNN | ... | ... |

### New Errors Encountered
| Error | Root Cause | Fix Applied |
|-------|-----------|-------------|
| ... | ... | ... |

### Unresolved Errors (if any)
| Error | Notes |
|-------|-------|
| ... | ... |

### Warnings
[List any compilation warnings]
```

## Step 7: Document New Errors

If any **NEW** errors were encountered and resolved, remind the user to run `/log-error` for each one to add them to the CodeLessonsLearned database.

## Step 8: Suggest Next Steps

After a successful build:
- If the target has tests, suggest running `/run-tests <target>` to verify test suite passes
- If functionality changed, remind about `/update-specs` after all validation is complete
