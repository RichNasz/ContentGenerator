# log-error

Documents a resolved error in CodeLessonsLearned.md using the project's standardized 12-field template. This maintains the error feedback loop that prevents re-solving the same problems.

## Workflow Position

**Category:** Required (after errors)

Invoke after resolving any compilation error, test failure, or runtime issue. Uses `disable-model-invocation: true` to prevent auto-triggering.

## Invocation

```
/log-error [description of the error and its resolution]
```

The argument describes what error occurred and how it was resolved.

## Inputs

- Error context from the argument description
- Target project's `Specs/CodeLessonsLearned.md` -- to check for duplicates and find the next Error ID

## Outputs

A new or updated entry in CodeLessonsLearned.md with all 12 required fields:
- Discovery Method, Frequency, Error Message, Context, Root Cause, Proven Fix
- Code Before, Code After, Prevention Pattern, Verification, Related Errors, Last Updated

If a matching entry already exists, updates its Frequency count and Last Updated date instead of creating a duplicate.

## Allowed Tools

All tools (uses `disable-model-invocation: true`)

## Related Skills

- **Previous:** [validate-build](../validate-build/) (identifies errors to log)
- **Next:** [update-specs](../update-specs/) (specs may reference new error patterns)
- **Data used by:** [prep-for-coding](../prep-for-coding/) (reads CodeLessonsLearned to prevent known errors)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
