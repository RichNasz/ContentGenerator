# validate-commit

Validates a commit message against the Conventional Commits format defined in ContributingSpec.md. Checks type prefix, format, and description quality.

## Workflow Position

**Category:** On-demand

Invoke when you want to verify a commit message follows project conventions.

## Invocation

```
/validate-commit [commit ref or "HEAD"]
```

The argument is a git commit reference (SHA, branch name, tag) or `"HEAD"` for the latest commit. Defaults to HEAD if omitted.

## Inputs

- Git commit message for the specified ref
- `ProjectSpecs/ContributingSpec.md` -- commit conventions (read at runtime to stay in sync)

## Outputs

A validation report containing:
- Pass/fail result
- Type prefix validation (must be one of: feat, fix, spec, refactor, docs, chore)
- Format validation (type, colon, space, description)
- Description quality check (not empty, meaningful)
- Specific issues if validation fails

## Allowed Tools

Read, Glob, Grep, Bash

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
