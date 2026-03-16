---
name: update-specs
description: Updates specification files after functionality changes. Identifies affected specs, drafts updates for FunctionalSpecs (WHAT), SwiftTechSpecs (HOW), and CodeLessonsLearned, and verifies cross-reference consistency.
argument-hint: "[description of what changed]"
allowed-tools: Read, Glob, Grep, Edit
---

# Update Specifications After Changes

Update specification files to reflect functionality changes, maintaining the spec-driven development loop. Specs must stay current with the codebase.

**Edit scope constraint:** You may ONLY edit files matching `<Project>/Specs/*.md`. All other files (source code, CommonSpecs, etc.) are read-only context. Do not modify any file outside a project's Specs directory.

## Step 1: Identify Affected Projects

Based on the change description argument, determine which project(s) are affected:

- **ContentGenerator** -- main app changes
- **LLMmanagement** -- LLM connection management changes
- **ProjectExchange** -- import/export functionality changes

If the description is ambiguous, use Glob and Grep to search for recently modified source files to clarify which project was changed.

## Step 2: Read Current Specs for Each Affected Project

Read the current versions of all specs for each affected project:

1. `<Project>/Specs/FunctionalSpecs.md`
2. `<Project>/Specs/SwiftTechSpecs.md`
3. `<Project>/Specs/CodeLessonsLearned.md`

## Step 3: Read Relevant CommonSpecs

Read CommonSpecs that relate to the area of change:

- Always read: `CommonSpecs/SwiftCodeGeneration.md`
- If UI changed: `CommonSpecs/SwiftUISpec.md`, `CommonSpecs/SwiftUIWithoutMVVM.md`
- If data models changed: `CommonSpecs/SwiftDataPatterns.md`
- If tests changed: `CommonSpecs/SwiftTestingSpec.md`
- If navigation changed: `CommonSpecs/NavigationPatterns.md`
- If documentation changed: `CommonSpecs/DocumentationSpec.md`

These are read-only -- do not edit CommonSpecs files.

## Step 4: Search for Changed Source Files

Use Glob and Grep to find the source files related to the change description. This provides concrete context for what was actually implemented:

- Search for type names, function names, or keywords from the change description
- Read relevant source files to understand the actual implementation
- Note any new protocols, types, patterns, or architectural decisions introduced

## Step 5: Classify the Change Type

Categorize the change to determine which specs need updates:

| Change Type | Files to Update |
|------------|----------------|
| **Functional** -- new or modified features | FunctionalSpecs.md |
| **Implementation Pattern** -- new Swift patterns, architecture changes | SwiftTechSpecs.md |
| **Error Solution** -- new error encountered and resolved | CodeLessonsLearned.md |
| **Cross-Project** -- changes affecting multiple targets | All affected project specs |

A single change may fall into multiple categories.

## Step 6: Draft and Apply Updates

### FunctionalSpecs.md (WHAT changed)
- Add or modify feature descriptions using language-agnostic terms
- Document new user-facing behavior
- Update acceptance criteria
- Do NOT include implementation details -- keep this file language-agnostic

### SwiftTechSpecs.md (HOW it's implemented)
- Add or modify Swift implementation guidance: protocols, method signatures, patterns
- Reference applicable CommonSpecs (SwiftCodeGeneration.md, SwiftUISpec.md, etc.)
- Do NOT include complete code implementations -- only guidance, signatures, and patterns
- Document any new architectural decisions or pattern choices

### CodeLessonsLearned.md (errors encountered)
- If new errors were encountered during the change, document them using the 12-field template
- If existing error entries are now obsolete, mark them as such
- Update frequency counts if known errors recurred

Use the Edit tool to apply each update to the spec files. Only edit files under `<Project>/Specs/`.

## Step 7: Verify Cross-Reference Consistency

After applying all updates, re-read the modified spec files and check for:

1. **Terminology alignment** -- the same concepts use the same names across all specs
2. **No contradictions** -- FunctionalSpecs WHAT and SwiftTechSpecs HOW describe the same behavior
3. **CommonSpec compliance** -- SwiftTechSpecs patterns align with referenced CommonSpecs
4. **Error database accuracy** -- CodeLessonsLearned entries reference correct file paths and patterns
5. **Completeness** -- every functional requirement has corresponding implementation guidance

If inconsistencies are found, apply corrective edits.

## Step 8: Update Last Updated Dates

Update the "Last Updated" date at the bottom of every modified specification file to today's date.

## Step 9: Present Summary

Present a summary of all changes made:

### Changes Summary

**Files Modified:**
- List each file with a one-line description of what changed

**FunctionalSpecs Changes:**
- Bullet list of WHAT changes

**SwiftTechSpecs Changes:**
- Bullet list of HOW changes

**CodeLessonsLearned Changes:**
- Bullet list of new/updated error entries

**Cross-Reference Check:**
- Confirm no contradictions found, or list any issues that were corrected
