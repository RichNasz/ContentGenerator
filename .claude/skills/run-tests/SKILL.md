---
name: run-tests
description: Runs the Swift Testing suite for a target project, classifies failures against CodeLessonsLearned, and produces a test results report. Use after validate-build passes.
argument-hint: "[ContentGenerator | LLMmanagement | ProjectExchange]"
disable-model-invocation: true
---

# Run Tests

Run the test suite for a target project. Classify any failures against CodeLessonsLearned.md and produce a structured test results report.

## Step 1: Select Test Command

Based on the target project argument:

| Target | Test Command |
|--------|-------------|
| **ContentGenerator** | `xcodebuild test -project ContentGenerator/ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS'` |
| **LLMmanagement** | `swift test` (run from `LLMmanagement/` directory) |
| **ProjectExchange** | `swift test` (run from `ProjectExchange/` directory) |

## Step 2: Run Tests

Execute the test command and capture full output:

For ContentGenerator:
```bash
cd ContentGenerator && xcodebuild test -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' 2>&1
```

For Swift packages:
```bash
cd <PackageName> && swift test 2>&1
```

## Step 3: Check Results

If all tests pass (`Test Suite passed` or exit code 0), skip to Step 6 with a success report.

If any tests fail, continue to Step 4.

## Step 4: Classify Failures

For each test failure:

1. Extract the failure message and test name from the output
2. Read `<TargetProject>/Specs/CodeLessonsLearned.md`
3. Search CodeLessonsLearned.md for:
   - Matching error messages or symptoms
   - Matching root causes
   - Matching categories (TEST, SWIFT, DATA, UI, RUNTIME, CONCURRENCY)
4. Classify each failure as:
   - **KNOWN** -- has a matching entry with a documented Proven Fix
   - **NEW** -- no matching entry found

## Step 5: Reference Known Fixes

For each **KNOWN** failure:
- Reference the Error ID and Proven Fix from CodeLessonsLearned.md
- Do NOT automatically apply fixes -- report them for the user to decide

For each **NEW** failure:
- Report the failure details for the user to investigate

## Step 6: Test Results Report

Produce a structured report:

```
## Test Results Report

**Target**: [project name]
**Result**: [PASSED | FAILED]
**Date**: [today's date]

### Test Summary
- Total tests: [count]
- Passed: [count]
- Failed: [count]
- Skipped: [count]

### Failed Tests (if any)
| Test | Failure Message | Classification | Reference |
|------|----------------|----------------|-----------|
| ... | ... | KNOWN / NEW | ERR-XXX-NNN / -- |

### Known Failure Fixes
[For each KNOWN failure, list the Error ID and Proven Fix from CodeLessonsLearned]

### New Failures
[For each NEW failure, list the failure details]
```

## Step 7: Remind About Error Logging

If any **NEW** test failures are resolved during this session, remind the user to run `/log-error` for each one to add them to the CodeLessonsLearned database.
