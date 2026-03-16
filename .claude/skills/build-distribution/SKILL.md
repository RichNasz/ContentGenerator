---
name: build-distribution
description: Builds an unsigned distribution package (ZIP + DMG + SHA-256 checksums) for team distribution. Runs pre-flight checks, invokes the build script, and summarizes artifacts. Use when a release is ready to share with the team.
argument-hint: ""
disable-model-invocation: true
---

# Build Distribution Package

Perform pre-flight validation, run the distribution build script, and produce a structured artifact summary for team distribution.

**Edit scope constraint:** This skill does not edit any source files. All edits are limited to workflow follow-on actions (e.g., CHANGELOG.md via `/log-change`). Do not modify source files.

## Step 1: Pre-flight — Git Status

Run `git status --porcelain` from the repository root.

```bash
git status --porcelain
```

If the output is non-empty (uncommitted changes exist), warn the user:

> **Warning:** The working tree is not clean. Distributing a build from a dirty working tree may include uncommitted changes. Proceed with caution.

List the modified/untracked files so the user can assess the situation. Do not abort automatically — let the user decide whether to continue.

## Step 2: Pre-flight — Extract Version

Extract the current `MARKETING_VERSION` from the Xcode project build settings:

```bash
cd ContentGenerator && xcodebuild -project ContentGenerator.xcodeproj -scheme ContentGenerator -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | awk '{print $3}'
```

If extraction fails, read `ContentGenerator/ContentGenerator.xcodeproj/project.pbxproj` and search for `MARKETING_VERSION` to obtain the value manually.

## Step 3: Pre-flight — CHANGELOG Check

Read `CHANGELOG.md` at the repository root. Check whether the `[Unreleased]` section or any versioned section contains an entry for the version extracted in Step 2.

Report one of:
- **CHANGELOG entry found** — version is documented
- **No CHANGELOG entry found** — version has no recorded changes (recommend running `/log-change` before distributing)

## Step 4: Confirm with User (if warnings exist)

Evaluate whether any pre-flight warnings were raised in Steps 1–3:
- **Dirty tree warning**: git status was non-empty
- **CHANGELOG warning**: no entry found for the version being built

**If one or more warnings exist**, present the pre-flight summary and ask the user to confirm:

    ## Distribution Pre-flight Summary

    **Version:** [MARKETING_VERSION]
    **Git status:** [Dirty — N files modified/untracked]
    **CHANGELOG:** [No entry found for this version]

    ⚠️ One or more pre-flight warnings require your attention. Proceed with distribution build? (yes / no)

Wait for confirmation. If the user says no, stop here.

**If no warnings exist** (git is clean AND CHANGELOG entry found), display a brief summary and
proceed directly to Step 5 without asking:

    ## Distribution Pre-flight Summary

    **Version:** [MARKETING_VERSION]
    **Git status:** Clean
    **CHANGELOG:** Entry found

    All pre-flight checks passed — proceeding with build.

## Step 5: Run the Distribution Script

Execute the distribution script from the repository root:

```bash
ContentGenerator/Scripts/build_for_distribution.sh 2>&1
```

Stream meaningful progress output to the user as the script runs. Key milestones to surface:
- Archive step started / completed
- Export step started / completed
- ZIP packaging completed
- DMG creation completed
- Checksum generation completed

If the script exits with a non-zero status, report **FAILED** with the relevant error output and stop.

## Step 6: Post-build Artifact Summary

On successful completion, locate the output artifacts. The script places outputs in `ContentGenerator/dist/`. List artifacts with their sizes:

```bash
ls -lh ContentGenerator/dist/
```

Then display the checksum file contents inline:

```bash
cat ContentGenerator/dist/*.sha256 2>/dev/null || cat ContentGenerator/dist/checksums.txt 2>/dev/null
```

Present a structured summary:

```
## Distribution Build Report

**Result:** PASSED
**Version:** [version]
**Date:** [today's date]

### Output Artifacts

| File | Size |
|------|------|
| ContentGenerator-[version].zip | [size] |
| ContentGenerator-[version].dmg | [size] |
| [checksum file] | [size] |

### SHA-256 Checksums

```
[checksum file contents — copy-paste ready]
```

### Distribution Guide

Share `ContentGenerator/TEAM_DISTRIBUTION.md` with recipients alongside the ZIP or DMG.
```

## Step 7: Follow-on Workflow Prompts

After presenting the artifact summary, prompt the user for next steps:

1. **CHANGELOG entry:** "Would you like to run `/log-change` to record this release in CHANGELOG.md?"
2. **Version bump reminder:** "Remember to increment `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project for the next development cycle."
