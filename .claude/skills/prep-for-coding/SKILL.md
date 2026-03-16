---
name: prep-for-coding
description: Reads all applicable specs before code generation -- FunctionalSpecs, SwiftTechSpecs, CodeLessonsLearned for the target project, plus relevant CommonSpecs. Produces a synthesized implementation approach. Use before writing or modifying any code.
argument-hint: "[feature or area to implement]"
allowed-tools: Read, Glob, Grep
---

# Pre-Code Generation Specification Review

You must complete all steps below before any code is written or modified. The goal is to synthesize all applicable specifications into a comprehensive implementation approach for the requested feature area.

## Step 1: Identify the Target Project

Determine which project target the work applies to based on the feature area argument:

- **ContentGenerator** -- the main macOS app (Xcode project, uses `xcodebuild`)
- **LLMmanagement** -- Swift package for LLM connection management (uses `swift build`)
- **ProjectExchange** -- Swift package for project import/export (uses `swift build`)

If the feature area spans multiple targets, repeat the spec reads for each.

## Step 2: Read Project-Specific Specs

Read all three project-specific specification files for the identified target:

1. `<TargetProject>/Specs/FunctionalSpecs.md` -- language-agnostic WHAT requirements
2. `<TargetProject>/Specs/SwiftTechSpecs.md` -- Swift-specific HOW implementation guidance
3. `<TargetProject>/Specs/CodeLessonsLearned.md` -- error feedback loop and solution repository

## Step 3: Read Applicable CommonSpecs

Always read:
- `CommonSpecs/SwiftCodeGeneration.md` -- core Swift implementation guidance, concurrency patterns, code quality standards

Conditionally read based on feature area relevance:
- `CommonSpecs/SwiftUISpec.md` -- if the work involves any UI components
- `CommonSpecs/SwiftUIWithoutMVVM.md` -- if the work involves SwiftUI architecture decisions
- `CommonSpecs/SwiftDataPatterns.md` -- if the work involves data models or persistence
- `CommonSpecs/SwiftTestingSpec.md` -- if the work involves writing or modifying tests
- `CommonSpecs/NavigationPatterns.md` -- if the work involves navigation or routing
- `CommonSpecs/DocumentationSpec.md` -- if the work involves API documentation

## Step 4: Search for Related Error Patterns

Search the target project's `CodeLessonsLearned.md` for error patterns related to the feature area:
- Search by category keywords (SWIFT, DATA, UI, RUNTIME, TEST, CONCURRENCY)
- Search by technology keywords relevant to the feature (e.g., "SwiftData", "@Model", "NavigationStack")
- Note any High-Frequency Errors that could apply
- Record prevention patterns from matching entries

## Step 5: Produce Synthesis

Output a structured synthesis with these sections:

### Applicable Requirements
Summarize the functional requirements from FunctionalSpecs.md that apply to this feature area.

### Implementation Patterns
List the Swift implementation patterns from SwiftTechSpecs.md and CommonSpecs that must be followed. Include specific protocol conformances, architectural patterns, and code structure requirements.

### Errors to Avoid
List relevant entries from CodeLessonsLearned.md with their Error IDs and prevention patterns. Highlight any High-Frequency Errors.

### Architecture Constraints
Document constraints from the specs: Swift 6 concurrency requirements, default MainActor isolation rules, SwiftData patterns, and any cross-project dependencies.

### Pre-Generation Checklist
Present this checklist for confirmation before proceeding:

- [ ] Functional requirements understood from FunctionalSpecs.md
- [ ] Swift implementation patterns identified from SwiftTechSpecs.md
- [ ] SwiftUI requirements reviewed (if applicable)
- [ ] Testing patterns planned (if applicable)
- [ ] Code quality standards noted from SwiftCodeGeneration.md
- [ ] Known errors checked in CodeLessonsLearned.md
- [ ] Architecture compliance verified across all specs
