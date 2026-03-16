---
name: validate-integration
description: Builds all three targets in dependency order (LLMmanagement, ProjectExchange, ContentGenerator) to verify cross-project compatibility.
argument-hint: "(no arguments)"
disable-model-invocation: true
---

# Integration Validation

Build all three targets in dependency order to verify that changes in one project do not break another.

## Step 1: Build LLMmanagement

Build the LLMmanagement package first (it has no local dependencies):

```bash
cd LLMmanagement && swift package clean && swift build 2>&1
```

Record the result (PASSED/FAILED) and any errors.

## Step 2: Build ProjectExchange

Build the ProjectExchange package next (it has no local dependencies):

```bash
cd ProjectExchange && swift package clean && swift build 2>&1
```

Record the result (PASSED/FAILED) and any errors.

## Step 3: Build ContentGenerator

Build the main app last (it depends on both packages):

```bash
cd ContentGenerator && xcodebuild clean build -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' 2>&1
```

Record the result (PASSED/FAILED) and any errors.

## Step 4: Classify Errors (if any)

If any target failed:

1. Extract all error lines from the build output
2. Identify whether the error originates in the target's own code or in a dependency
3. For cross-dependency errors (e.g., ContentGenerator fails due to an API change in LLMmanagement), note the dependency relationship

## Step 5: Integration Report

Produce a structured report:

```
## Integration Validation Report

**Date**: [today's date]

### Build Results
| Target | Result | Errors | Warnings |
|--------|--------|--------|----------|
| LLMmanagement | PASSED/FAILED | [count] | [count] |
| ProjectExchange | PASSED/FAILED | [count] | [count] |
| ContentGenerator | PASSED/FAILED | [count] | [count] |

### Overall: [PASSED / FAILED]

### Cross-Dependency Issues (if any)
| Source Target | Affected Target | Issue |
|--------------|----------------|-------|
| ... | ... | ... |

### Errors (if any)
[List errors grouped by target]
```

## Step 6: Fix Order Recommendation

If failures exist, suggest which target to fix first based on dependency order:

1. Fix **LLMmanagement** first -- other targets depend on it
2. Fix **ProjectExchange** next -- ContentGenerator depends on it
3. Fix **ContentGenerator** last -- it depends on both packages

This ensures fixes flow downstream through the dependency chain.
