---
name: validate-commit
description: Validates a commit message against the Conventional Commits format defined in ContributingSpec.md. Checks type prefix, format, and description quality.
argument-hint: "[commit ref or \"HEAD\"]"
allowed-tools: Read, Glob, Grep, Bash
---

# Commit Message Validation

Validate a git commit message against the project's Conventional Commits conventions defined in ContributingSpec.md.

## Step 1: Read Commit Conventions

Read `ProjectSpecs/ContributingSpec.md` to get the current commit conventions:
- Allowed type prefixes (feat, fix, spec, refactor, docs, chore)
- Commit message format rules
- Subject line length limit

## Step 2: Get the Commit Message

Determine the commit reference from the argument (default to `HEAD` if omitted).

```bash
git log -1 --format="%B" <ref>
```

If the ref does not exist, report an error and stop.

## Step 3: Validate Format

Check the commit message subject line against the format:
```
<type>: <short description>
```

Validate:
1. **Type prefix exists** -- the subject starts with one of the allowed types followed by a colon
2. **Colon and space** -- the type is followed by `: ` (colon then space)
3. **Description present** -- text follows the colon and space

## Step 4: Validate Type Prefix

Check that the type is one of the allowed prefixes from ContributingSpec:
- `feat:` -- adding new functionality
- `fix:` -- fixing a bug
- `spec:` -- updating specification files only
- `refactor:` -- restructuring code without changing behavior
- `docs:` -- documentation-only changes
- `chore:` -- build, tooling, or maintenance tasks

## Step 5: Check Description Quality

- Subject line is not empty after the type prefix
- Subject line is under 72 characters (from ContributingSpec)
- Subject line uses imperative mood (heuristic: does not start with past tense -ed suffix)

## Step 6: Validation Report

Produce a structured report:

```
## Commit Validation Report

**Ref**: [commit ref]
**Subject**: [commit subject line]
**Result**: [PASSED | FAILED]

### Checks
| Check | Result | Details |
|-------|--------|---------|
| Type prefix | PASS/FAIL | [found type or "missing"] |
| Format (type: description) | PASS/FAIL | [details] |
| Allowed type | PASS/FAIL | [type or "not in allowed list"] |
| Subject length (<=72) | PASS/FAIL | [length] characters |
| Description quality | PASS/FAIL | [details] |

### Issues (if any)
[List specific issues with the commit message]
```
