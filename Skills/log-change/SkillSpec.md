# log-change

Proposes a changelog entry for a completed functionality change using [Keep a Changelog](https://keepachangelog.com) format. Presents the entry for user approval before writing it to CHANGELOG.md.

## Workflow Position

**Category:** Optional (after changes)

Available after completing functionality changes, typically after `update-specs`. Invoke when you want to record the change in the project changelog.

## Invocation

```
/log-change [description of the change]
```

The argument describes the completed change to be logged.

## Inputs

- Change description from the argument
- Current `CHANGELOG.md` -- to understand existing style and structure
- Source files related to the change (discovered via Glob and Grep)

## Outputs

- A proposed changelog entry classified into one of 6 categories (Added, Changed, Deprecated, Removed, Fixed, Security)
- Format: `- [ProjectName] Description of the change`
- Entry is presented for user approval before writing
- On approval, the entry is inserted under the correct category in the `[Unreleased]` section

**Edit scope:** Only `CHANGELOG.md` at the project root.

## Allowed Tools

Read, Glob, Grep, Edit

## Related Skills

- **Previous:** [update-specs](../update-specs/) (specs reflect the change before logging it)

---

[Back to Skills](../README.md) | [Back to root README](../../README.md)
