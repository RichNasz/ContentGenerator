# validate-specs

Checks specification consistency, cross-references, terminology, and completeness for a target project or all projects. Reports issues but does not fix them -- the user decides how to address them.

## Workflow Position

**Category:** On-demand

Invoke when explicitly requested by the user. Independent of the main development workflow.

## Invocation

```
/validate-specs [project name or "all"]
```

The argument is a specific project name (ContentGenerator, LLMmanagement, ProjectExchange) or `"all"` to validate every project.

## Inputs

- Target project's `Specs/` files (FunctionalSpecs, SwiftTechSpecs, CodeLessonsLearned, and any supplemental specs)
- All CommonSpecs files
- All ProjectSpecs files

## Outputs

A spec validation report containing:
- Cross-reference check (every file referenced in a spec must exist)
- Terminology consistency check (same concepts should use same names)
- Completeness check (features in FunctionalSpecs should have SwiftTechSpecs guidance)
- Error pattern currency check (CodeLessonsLearned entries should reference existing patterns)
- Issues categorized by severity (error/warning/info)

## Allowed Tools

Read, Glob, Grep (read-only -- no edits)

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
