---
name: generate-repo-docs
description: Generates or regenerates monorepo-level documentation files (README.md, CONTRIBUTING.md, issue templates, sub-project READMEs) from ProjectSpecs following DocumentationGenerationSpec rules.
argument-hint: "[file or \"all\"]"
allowed-tools: Read, Glob, Grep, Write
---

# Generate Repository Documentation

Generate or regenerate documentation files from ProjectSpecs, following the structure rules in DocumentationGenerationSpec.md.

**Edit scope constraint:** You may ONLY create or update files listed in DocumentationGenerationSpec's Generated Files table. Do not modify any source spec files.

## Step 1: Read DocumentationGenerationSpec

Read `ProjectSpecs/DocumentationGenerationSpec.md` to get:
- The complete list of generated files
- Structure rules for each file type (README, CONTRIBUTING, issue templates, etc.)
- General tone guidelines

## Step 2: Read Source Specs

Read all source specs referenced by DocumentationGenerationSpec:
- `ProjectSpecs/ProjectOverviewSpec.md`
- `ProjectSpecs/ContributingSpec.md`
- `ProjectSpecs/SkillDevelopmentSpec.md`
- `ContentGenerator/Specs/FunctionalSpecs.md`
- `LLMmanagement/Specs/FunctionalSpecs.md`
- `ProjectExchange/Specs/FunctionalSpecs.md`

## Step 3: Determine Scope

**If a specific file is named** (e.g., `README.md`, `CONTRIBUTING.md`, `LLMmanagement/README.md`):
- Generate only that file

**If `"all"` is specified:**
- Generate all files listed in DocumentationGenerationSpec's Generated Files table

## Step 4: Generate Each File

For each file in scope:
1. Follow the exact structure rules from DocumentationGenerationSpec for that file type
2. Draw content from the source specs listed in the Generated Files table
3. Apply the general tone rules (professional, precise, no emojis, second person)
4. Write the file using the Write tool

## Step 5: Generation Report

Produce a summary report:

```
## Documentation Generation Report

**Date**: [today's date]

### Files Generated/Updated
| File | Status |
|------|--------|
| ... | Created / Updated / Skipped (no changes needed) |

### Notes
[Any issues encountered or decisions made during generation]
```
