---
name: log-change
description: Proposes a changelog entry for a completed functionality change using Keep a Changelog format. Presents the entry for user approval before writing it.
argument-hint: "[description of the change]"
allowed-tools: Read, Glob, Grep, Edit
---

# Log Change to CHANGELOG.md

Propose a changelog entry for a completed functionality change, present it for user approval, and write it to CHANGELOG.md using [Keep a Changelog](https://keepachangelog.com) format.

**Edit scope constraint:** You may ONLY edit `CHANGELOG.md` at the project root. All other files are read-only context. Do not modify any file other than CHANGELOG.md.

## Step 1: Read Current CHANGELOG.md

Read `CHANGELOG.md` at the project root to understand:

- Existing entries and their style/tone
- The current structure of the `[Unreleased]` section
- Which category headings are present (Added, Changed, Deprecated, Removed, Fixed, Security)

## Step 2: Understand the Change

Use the argument description to understand what was implemented:

- Use Glob and Grep to find source files related to the change description
- Read relevant source files to understand the scope and nature of the change
- Identify which project(s) were affected:
  - **ContentGenerator** -- main app changes
  - **LLMmanagement** -- LLM connection management changes
  - **ProjectExchange** -- import/export functionality changes

## Step 3: Classify the Change

Classify the change into exactly one Keep a Changelog category:

| Category | When to Use |
|----------|------------|
| **Added** | New features or capabilities |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features marked for future removal |
| **Removed** | Features that were removed |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability fixes |

If a change spans multiple categories, create separate entries for each.

## Step 4: Present the Proposed Entry

Present the proposed changelog entry to the user for approval before writing. Show:

1. The **category** the entry will be placed under (e.g., Added, Changed, Fixed)
2. The **exact text** of the entry, formatted as a bullet point with a project prefix:
   - Format: `- [ProjectName] Description of the change`
   - Example: `- [ContentGenerator] Add prompt template selection to content generation view`
3. Where it will appear in the `[Unreleased]` section

Ask the user to approve, modify, or reject the entry. Do NOT write anything until the user approves.

## Step 5: Apply the Edit on Approval

Once the user approves (with or without modifications):

- Use Edit to insert the entry under the correct category heading within the `[Unreleased]` section
- Place the new entry as the first bullet under its category heading
- Preserve all existing entries and formatting
- Do NOT modify any other file

If the user rejects the entry, stop without making any changes.
