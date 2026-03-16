# validate-integration

Builds all three targets in dependency order to verify cross-project compatibility. LLMmanagement and ProjectExchange are built first as SPM packages, then ContentGenerator (which depends on both).

## Workflow Position

**Category:** On-demand

Invoke when you want to verify that all three projects build together, especially after changes to a shared package.

## Invocation

```
/validate-integration
```

No argument -- always validates all three targets in dependency order.

## Inputs

- Build output from all three targets (xcodebuild for ContentGenerator, swift build for SPM packages)

## Outputs

An integration validation report containing:
- Per-target build status (PASSED/FAILED)
- Cross-dependency issues identified
- Suggestion for which target to fix first based on dependency order

## Allowed Tools

All tools (uses `disable-model-invocation: true`)

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
