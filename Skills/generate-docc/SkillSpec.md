# generate-docc

Generates missing DocC documentation catalogs or validates existing ones against `CommonSpecs/DocumentationSpec.md` requirements. Operates in one of two modes depending on whether the catalog already exists.

## Workflow Position

**Category:** On-demand

Invoke when explicitly requested by the user. Independent of the main development workflow. Uses `disable-model-invocation: true` to prevent auto-triggering.

## Invocation

```
/generate-docc [ContentGenerator | LLMmanagement | ProjectExchange]
```

The argument specifies which target's DocC catalog to generate or validate.

## Inputs

- `CommonSpecs/DocumentationSpec.md` -- DocC requirements and standards
- Target project's `Specs/FunctionalSpecs.md` and `SwiftTechSpecs.md`
- Target project's `.swift` source files (scanned for public API symbols)
- Existing `Documentation.docc/` directory (if validating)

## Outputs

**Generate mode** (catalog missing):
- Creates `Documentation.docc/` directory at the target path
- Creates 4 required articles: Documentation.md, Getting-Started.md, User-Guide.md, API-Reference.md
- Produces a generation report listing files created and content sources

**Validate mode** (catalog exists):
- Checks required articles are present
- Verifies content standards (overviews, code examples, cross-references, DocC formatting)
- Measures public API documentation coverage
- Validates cross-reference links
- Produces a validation report with pass/fail results and recommendations

## Allowed Tools

Read, Glob, Grep, Write, Bash

## Related Skills

- Independent -- can be invoked at any time without prerequisites

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
