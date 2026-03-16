# update-specs

Updates specification files after functionality changes to keep specs current with the codebase. Identifies affected specs, drafts updates for FunctionalSpecs (WHAT), SwiftTechSpecs (HOW), and CodeLessonsLearned, then verifies cross-reference consistency.

## Workflow Position

**Category:** Required (after changes)

Invoke after functionality changes are complete and validated. Typically follows a successful `validate-build`.

## Invocation

```
/update-specs [description of what changed]
```

The argument describes the functionality change that was implemented.

## Inputs

- Changed source files (discovered via Glob and Grep based on the description)
- Target project's `Specs/FunctionalSpecs.md`, `SwiftTechSpecs.md`, `CodeLessonsLearned.md`
- Relevant CommonSpecs (read-only context)

## Outputs

- Updated FunctionalSpecs.md with new or modified feature descriptions
- Updated SwiftTechSpecs.md with new implementation patterns and guidance
- Updated CodeLessonsLearned.md if new errors were encountered
- Cross-reference consistency verification (including dead reference detection and terminology drift fixes)
- Summary of all changes made

**Edit scope:** Only files matching `<Project>/Specs/*.md`. All other files are read-only.

## Allowed Tools

Read, Glob, Grep, Edit

## Related Skills

- **Previous:** [validate-build](../validate-build/) (confirms code compiles), [log-error](../log-error/) (documents any errors)
- **Next:** [log-change](../log-change/) (optional changelog entry)
- **Data used by:** [prep-for-coding](../prep-for-coding/) (reads updated specs for future code generation)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
