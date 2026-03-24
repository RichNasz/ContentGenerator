# AgentGen Specifications

Target-specific specifications for the AgentGen Swift package. These specs define what the package does, how it is implemented, and lessons learned from resolved errors.

## Files

| File | Description |
|------|-------------|
| `FunctionalSpecs.md` | WHAT the package does -- features, behaviors, requirements |
| `SwiftTechSpecs.md` | HOW it is implemented -- architecture, types, patterns |
| `CodeLessonsLearned.md` | Resolved error patterns documented with 12-field templates |

## Spec-Driven Workflow

These files are maintained through Claude Code skills:

- `/prep-for-coding` reads these specs (plus CommonSpecs) before any code change
- `/update-specs` updates these files after functionality changes are validated
- `/log-error` adds entries to `CodeLessonsLearned.md` after resolving errors

---

[Back to AgentGen README](../README.md) | [Back to root README](../../README.md)
