# prep-for-coding

Reads all applicable specifications before code generation and produces a synthesized implementation approach. This ensures every code change is informed by functional requirements, implementation patterns, known error patterns, and architecture constraints.

## Workflow Position

**Category:** Required (before code)

Invoke before writing or modifying any code. This is the first step in the development workflow.

## Invocation

```
/prep-for-coding [feature or area to implement]
```

The argument describes the feature area or implementation task. If the area spans multiple targets, the skill repeats its spec reads for each.

## Inputs

- Target project's `Specs/FunctionalSpecs.md` -- functional requirements
- Target project's `Specs/SwiftTechSpecs.md` -- implementation guidance
- Target project's `Specs/CodeLessonsLearned.md` -- known error patterns
- `CommonSpecs/SwiftCodeGeneration.md` -- always read
- Additional CommonSpecs as relevant (SwiftUISpec, SwiftDataPatterns, NavigationPatterns, SwiftTestingSpec, DocumentationSpec)

## Outputs

A structured synthesis containing:
- Applicable requirements from FunctionalSpecs
- Implementation patterns from SwiftTechSpecs and CommonSpecs
- Errors to avoid from CodeLessonsLearned (with Error IDs and prevention patterns)
- Architecture constraints
- Pre-generation checklist for confirmation

## Allowed Tools

Read, Glob, Grep (read-only -- no code generation)

## Related Skills

- **Next:** Write code, then invoke [validate-build](../validate-build/)
- **Uses data from:** [update-specs](../update-specs/) (keeps specs current), [log-error](../log-error/) (populates CodeLessonsLearned)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
