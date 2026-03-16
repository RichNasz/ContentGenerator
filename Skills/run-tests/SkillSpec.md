# run-tests

Runs the Swift Testing suite for a target project, captures results, and classifies any test failures against CodeLessonsLearned.md. Produces a test results report with pass/fail counts and failure classification.

## Workflow Position

**Category:** Optional (after validate-build)

Available after `/validate-build` passes. Invoke when you want to run tests for a target.

## Invocation

```
/run-tests [ContentGenerator | LLMmanagement | ProjectExchange]
```

The argument specifies which target to test. Each target uses a different test command (xcodebuild test for ContentGenerator, swift test for SPM packages).

## Inputs

- Test output (xcodebuild test or swift test)
- Target project's `Specs/CodeLessonsLearned.md` -- for failure classification

## Outputs

A test results report containing:
- Test result (PASSED/FAILED)
- Pass/fail counts
- Failure classification (KNOWN vs NEW) against CodeLessonsLearned.md
- For KNOWN failures, references to the documented proven fix
- Coverage summary (if available)

If new test failures were resolved, reminds the user to run `/log-error` for each.

## Allowed Tools

All tools (uses `disable-model-invocation: true`)

## Related Skills

- **Previous:** [validate-build](../validate-build/) (build must pass before testing)
- **Next:** [log-error](../log-error/) for any new test failures resolved

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
