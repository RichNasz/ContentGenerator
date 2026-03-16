# evaluate-specs

Runs the formal 5-criterion quality evaluation defined in `CommonSpecs/SpecificationQualitySpec.md`. Scores each criterion 0-10, calculates a weighted overall score, and produces a report with strengths, areas for improvement, and actionable recommendations.

## Workflow Position

**Category:** On-demand

Invoke when explicitly requested by the user. Independent of the main development workflow. Uses `disable-model-invocation: true` to prevent auto-triggering.

## Invocation

```
/evaluate-specs [project name or "all"]
```

The argument is a specific project name (ContentGenerator, LLMmanagement, ProjectExchange) or "all" to evaluate every project.

## Inputs

- Target project's `Specs/` files (FunctionalSpecs, SwiftTechSpecs, CodeLessonsLearned, and any supplemental specs)
- All 8 CommonSpecs files
- `CommonSpecs/SpecificationQualitySpec.md` -- the evaluation framework itself

## Outputs

A structured evaluation report containing:
- Scores table with 5 criteria (Human-AI Interaction, Error-Free Code Generation, Documentation Quality, Code Quality, Holistic Suite Integration), each weighted 20%
- Overall weighted score mapped to a rating category (Exceptional/Good/Adequate/Poor/Unacceptable)
- Per-file scores (0-10) attributing quality to individual spec files
- 3-5 specific strengths referencing spec files and sections
- 3-5 areas for improvement with criteria references
- 3-5 actionable, prioritized recommendations identifying files and changes

## Allowed Tools

Read, Glob, Grep (read-only -- no edits)

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
