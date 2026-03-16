# validate-build

Runs phased build validation after code changes. Performs syntax checking, full compilation, error classification against CodeLessonsLearned, and produces a structured validation report.

## Workflow Position

**Category:** Required (after code)

Invoke after any code generation or modification. Uses `disable-model-invocation: true` to prevent auto-triggering.

## Invocation

```
/validate-build [ContentGenerator | LLMmanagement | ProjectExchange]
```

The argument specifies which target to build. Each target uses a different build command (xcodebuild for ContentGenerator, swift build for SPM packages).

## Inputs

- Build system output (xcodebuild or swift build)
- Target project's `Specs/CodeLessonsLearned.md` -- for error classification

## Outputs

A build validation report containing:
- Build result (PASSED/FAILED)
- Total errors encountered, resolved via CodeLessonsLearned, new errors resolved, unresolved
- Table of errors resolved from lessons learned (with Error IDs and fixes applied)
- Table of new errors encountered (with root causes and fixes)
- Compilation warnings

If new errors were resolved, reminds the user to run `/log-error` for each.

## Allowed Tools

All tools (uses `disable-model-invocation: true`)

## Related Skills

- **Previous:** Code changes informed by [prep-for-coding](../prep-for-coding/)
- **Next:** [run-tests](../run-tests/) (optional, if target has tests), [log-error](../log-error/) for any new errors resolved, then [update-specs](../update-specs/)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
