# build-distribution

Builds an unsigned distribution package (ZIP + DMG + SHA-256 checksums) for team distribution. Performs pre-flight checks (git cleanliness, version confirmation, CHANGELOG coverage), invokes the existing distribution script, and produces a structured artifact summary with inline checksums.

## Workflow Position

**Category:** On-demand (release)

Invoke when a release is ready to share with the team. Typically invoked after `/update-specs` and `/log-change` have been completed for the release, but can be run independently.

## Invocation

```
/build-distribution
```

No arguments -- version is extracted automatically from the Xcode project's `MARKETING_VERSION` build setting.

## Inputs

- `git status` -- to detect uncommitted changes
- `ContentGenerator/ContentGenerator.xcodeproj` -- for `MARKETING_VERSION` extraction
- `CHANGELOG.md` -- to verify the version has a documented entry
- `ContentGenerator/Scripts/build_for_distribution.sh` -- the distribution script (not modified)
- `ContentGenerator/Scripts/ExportOptions.plist` -- referenced by the script (not modified)

## Outputs

A distribution build report containing:
- Pre-flight summary (git status, version, CHANGELOG check)
- User confirmation prompt **only when warnings exist** (dirty git tree or missing CHANGELOG entry);
  proceeds automatically when git is clean and a CHANGELOG entry is found
- Build result (PASSED / FAILED)
- Table of output artifacts with file sizes (`ContentGenerator/dist/`)
- SHA-256 checksums displayed inline for copy-pasting
- Reminder to share `ContentGenerator/TEAM_DISTRIBUTION.md` with recipients
- Follow-on prompts: offer to invoke `/log-change`, remind to bump the version

**Edit scope:** None. This skill does not edit source files. It invokes a shell script and reads existing files. Follow-on edits (e.g., CHANGELOG.md) are delegated to `/log-change`.

## Allowed Tools

Read, Bash (for git status, xcodebuild -showBuildSettings, script invocation, ls, cat)

## Related Skills

- **Typically preceded by:** [log-change](../log-change/) (CHANGELOG entry for the release)
- **May follow with:** [log-change](../log-change/) (if no CHANGELOG entry exists yet)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
