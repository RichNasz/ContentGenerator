# ContentGenerator Specifications

Target-specific specifications for the ContentGenerator macOS app. These specs define what the app does, how it is implemented, and lessons learned from resolved errors.

## Core Files

| File | Description |
|------|-------------|
| `FunctionalSpecs.md` | WHAT the app does -- features, behaviors, requirements |
| `SwiftTechSpecs.md` | HOW it is implemented -- architecture, types, patterns |
| `CodeLessonsLearned.md` | Resolved error patterns documented with 12-field templates |

## Supplemental Files

| File | Description |
|------|-------------|
| `AICodeGenerationSpec.md` | AI code generation rules specific to this target |
| `ValidationFramework.md` | Build validation framework |

## Spec-Driven Workflow

These files are maintained through Claude Code skills:

- `/prep-for-coding` reads these specs (plus CommonSpecs) before any code change
- `/update-specs` updates these files after functionality changes are validated
- `/log-error` adds entries to `CodeLessonsLearned.md` after resolving errors

---

[Back to ContentGenerator README](../README.md) | [Back to root README](../../README.md)
