---
name: log-error
description: Documents a resolved error in CodeLessonsLearned.md using the project's 12-field template. Use after resolving any compilation error, test failure, or runtime issue.
argument-hint: "[description of the error and its resolution]"
disable-model-invocation: true
---

# Log Resolved Error to CodeLessonsLearned

Document a resolved error using the project's standardized 12-field template. This maintains the error feedback loop that prevents re-solving the same problems.

## Step 1: Determine Target CodeLessonsLearned.md

Based on the error context (which files were affected, which project the error occurred in), identify the correct file:

- `ContentGenerator/Specs/CodeLessonsLearned.md`
- `LLMmanagement/Specs/CodeLessonsLearned.md`
- `ProjectExchange/Specs/CodeLessonsLearned.md`

If the error affects shared patterns across projects, log it in the project where it was first encountered.

## Step 2: Check for Duplicate Entries

Search the target CodeLessonsLearned.md for the error message or root cause to avoid duplicates:
- Search for the exact error message text
- Search for similar root cause descriptions
- If a matching entry exists, update its **Frequency** count and **Last Updated** date instead of creating a new entry

## Step 3: Classify the Error Category

Assign one of these categories based on the error type:

| Category | Use When |
|----------|----------|
| SWIFT | General Swift language errors (type mismatches, access control, generics) |
| DATA | SwiftData model errors, persistence issues, relationship problems |
| UI | SwiftUI view errors, layout issues, rendering problems |
| RUNTIME | Crashes, unexpected behavior at runtime |
| TEST | Unit test failures, testing framework issues |
| CONCURRENCY | Actor isolation, Sendable conformance, async/await issues |

## Step 4: Generate the Error ID

Read the existing entries in the target file to find the highest number for the chosen category, then increment by 1.

Format: `ERR-[CATEGORY]-[NUMBER]` (e.g., `ERR-SWIFT-015`, `ERR-DATA-003`)

## Step 5: Create the Entry

Write the entry using all 12 required fields. Every field must be populated -- do not leave any as "TBD" or empty:

```markdown
### ERR-[CATEGORY]-[NUMBER]: [Short descriptive title]
- **Discovery Method**: [Compilation | Unit Test | Integration Test | Runtime]
- **Frequency**: 1
- **Error Message**: `[Exact error text from compiler/test/runtime]`
- **Context**: [When/where this occurs -- file types, operations, patterns]
- **Root Cause**: [Technical explanation of why this happens]
- **Proven Fix**: [Step-by-step resolution that has been verified]
- **Code Before**: [Example of error-causing code]
- **Code After**: [Example of fixed code]
- **Prevention Pattern**: [How to avoid this error in future code generation]
- **Verification**: [How to confirm the fix works]
- **Related Errors**: [Links to similar error IDs, or "None"]
- **Last Updated**: [Today's date in YYYY-MM-DD format]
```

## Step 6: Place Under the Correct Section

Insert the new entry under the appropriate section heading in CodeLessonsLearned.md:

- **Compilation Errors** section for compilation failures
- **SwiftData Errors** section for data model issues
- **SwiftUI Errors** section for UI-related errors
- **Test Failure Errors** section for test failures
- **Runtime Errors** section for runtime issues

## Step 7: Update High-Frequency Errors

If this error (or its duplicate) has a **Frequency** of 3 or more occurrences, add or update its entry in the **High-Frequency Errors** section at the top of the file.
