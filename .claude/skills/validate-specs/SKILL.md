---
name: validate-specs
description: Checks spec consistency, cross-references, terminology, and completeness for a target project or all projects. Reports issues but does not fix them.
argument-hint: "[project name or \"all\"]"
allowed-tools: Read, Glob, Grep
---

# Specification Validation

Validate specification files for consistency, cross-references, terminology, and completeness. This is a read-only operation -- it reports issues but does not fix them.

## Step 1: Read Target Specs

**If a specific project is named** (ContentGenerator, LLMmanagement, or ProjectExchange):
- Read all files in `<Project>/Specs/` (FunctionalSpecs.md, SwiftTechSpecs.md, CodeLessonsLearned.md, and any supplemental specs)

**If `"all"` is specified:**
- Read all files in each project's `Specs/` directory

## Step 2: Read Shared Specs

Read all CommonSpecs:
- Use `Glob` to find all `.md` files in `CommonSpecs/`
- Read each file

Read all ProjectSpecs:
- Use `Glob` to find all `.md` files in `ProjectSpecs/`
- Read each file

## Step 3: Cross-Reference Check

For every file path referenced in any spec (e.g., `CommonSpecs/SwiftCodeGeneration.md`, `ContentGenerator/Specs/FunctionalSpecs.md`):
- Use `Glob` to verify the referenced file exists
- Flag any dead references as **error**

## Step 4: Terminology Consistency Check

Scan for terminology drift across specs:
- Same concepts should use the same names (e.g., "MainActor isolation" vs "main actor isolation" vs "@MainActor")
- Same types should be referenced consistently (e.g., `@Observable` vs `ObservableObject`)
- Same tools should be named consistently (e.g., "SwiftData" vs "Swift Data")
- Flag inconsistencies as **warning**

## Step 5: Completeness Check

For each feature listed in FunctionalSpecs.md:
- Check that SwiftTechSpecs.md has corresponding implementation guidance
- Check that the feature area references applicable CommonSpecs patterns
- Flag missing guidance as **warning**

## Step 6: Error Pattern Currency Check

For each entry in CodeLessonsLearned.md (if present):
- Check that the referenced error pattern category is valid (SWIFT, DATA, UI, RUNTIME, TEST, CONCURRENCY)
- Check that the entry follows the 12-field template
- Flag incomplete entries as **warning**

## Step 7: Validation Report

Produce a structured report with issues categorized by severity:

```
## Spec Validation Report

**Scope**: [project name or "all"]
**Date**: [today's date]

### Summary
- Errors: [count]
- Warnings: [count]
- Info: [count]

### Errors (must fix)
| # | File | Issue |
|---|------|-------|
| 1 | ... | Dead reference to ... |

### Warnings (should fix)
| # | File | Issue |
|---|------|-------|
| 1 | ... | Terminology inconsistency: ... |
| 2 | ... | Missing SwiftTechSpecs guidance for feature: ... |

### Info (consider)
| # | File | Issue |
|---|------|-------|
| 1 | ... | ... |
```
