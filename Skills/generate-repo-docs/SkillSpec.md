# generate-repo-docs

Generates or regenerates monorepo-level documentation files (README.md, CONTRIBUTING.md, issue templates, sub-project READMEs, etc.) from ProjectSpecs. Follows the structure rules defined in DocumentationGenerationSpec.md.

## Workflow Position

**Category:** On-demand

Invoke when explicitly requested by the user. Independent of the main development workflow.

## Invocation

```
/generate-repo-docs [file or "all"]
```

The argument is a specific file name (e.g., `README.md`, `CONTRIBUTING.md`, `LLMmanagement/README.md`) or `"all"` to generate all files listed in DocumentationGenerationSpec.md.

## Inputs

- `ProjectSpecs/DocumentationGenerationSpec.md` -- file list, structure rules, and tone guidelines
- `ProjectSpecs/ProjectOverviewSpec.md` -- project identity, features, architecture
- `ProjectSpecs/ContributingSpec.md` -- contribution workflow, commit conventions
- `ProjectSpecs/SkillDevelopmentSpec.md` -- skill creation template and governance
- Each target's `Specs/FunctionalSpecs.md` -- for sub-project READMEs

## Outputs

- Generated or updated markdown files per DocumentationGenerationSpec rules
- Generation report listing files created/updated

**Edit scope:** Only files listed in DocumentationGenerationSpec's Generated Files table.

## Allowed Tools

Read, Glob, Grep, Write

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
