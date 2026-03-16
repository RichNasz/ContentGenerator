---
name: generate-docc
description: Generates missing DocC documentation catalogs or validates existing ones against DocumentationSpec.md requirements. Creates the 4 required articles populated from specs and source files, or audits existing catalogs for gaps.
argument-hint: "[ContentGenerator | LLMmanagement | ProjectExchange]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Bash
---

# DocC Documentation Generation and Validation

Generate a missing DocC documentation catalog or validate an existing one against `CommonSpecs/DocumentationSpec.md` requirements for the specified target project.

## Step 1: Read the DocC Requirements

Read `CommonSpecs/DocumentationSpec.md` (the "DocC Documentation" section) to confirm the current requirements for:
- Required articles (Documentation.md, Getting-Started.md, User-Guide.md, API-Reference.md)
- DocC metadata standards (Overview, Usage, Parameters, Returns, Throws sections)
- Cross-reference syntax (`<doc:ArticleName>`)
- Best practices

## Step 2: Identify Target and Determine DocC Catalog Path

Identify the target project from the argument. Valid targets:
- **ContentGenerator**: `ContentGenerator/ContentGenerator/Documentation.docc/`
- **LLMmanagement**: `LLMmanagement/Sources/LLMmanagement/Documentation.docc/`
- **ProjectExchange**: `ProjectExchange/Sources/ProjectExchange/Documentation.docc/`

If the argument does not match one of these targets, report an error and stop.

## Step 3: Check Whether DocC Catalog Exists

Use Glob to check for `Documentation.docc/` at the target path:
- If the directory does **not** exist, proceed to **Step 4 (Generate Mode)**.
- If the directory **does** exist, skip to **Step 5 (Validate Mode)**.

## Step 4: Generate Mode (Catalog Missing)

### 4a: Read Project Specs

Read the target project's specification files:
- `<Project>/Specs/FunctionalSpecs.md`
- `<Project>/Specs/SwiftTechSpecs.md`

For ContentGenerator, the specs path is `ContentGenerator/Specs/`.

### 4b: Scan Source Files for Public API Symbols

Use Glob to find all `.swift` source files in the target project. Use Grep to identify public types, methods, and properties (`public class`, `public struct`, `public enum`, `public func`, `public var`, `public let`, `public protocol`).

### 4c: Create the Documentation.docc Directory

Use Bash to create the `Documentation.docc/` directory at the target path.

### 4d: Generate the 4 Required Articles

Create each article using Write, following the DocumentationSpec.md structure:

1. **Documentation.md** -- Main landing page:
   - Module-level overview summarizing the project's purpose (from FunctionalSpecs)
   - Topic sections organizing articles and key public symbols
   - Cross-references to the other 3 required articles using `<doc:Getting-Started>`, `<doc:User-Guide>`, `<doc:API-Reference>`

2. **Getting-Started.md** -- Installation and setup:
   - Prerequisites and dependencies (from SwiftTechSpecs)
   - Basic setup and configuration steps
   - Minimal usage example to get started
   - Cross-reference to User-Guide for deeper coverage

3. **User-Guide.md** -- Feature documentation:
   - Feature-by-feature documentation (from FunctionalSpecs)
   - Usage patterns and workflows (from SwiftTechSpecs)
   - Code examples demonstrating key features
   - Cross-references to API-Reference for detailed API information

4. **API-Reference.md** -- Public API catalog:
   - Organized by type category (classes, structs, enums, protocols)
   - Each public symbol listed with a brief description
   - Cross-references to source documentation using DocC symbol links
   - Grouped into logical sections matching the module structure

### 4e: Produce Generation Report

Output a structured report:

```
## DocC Generation Report -- <Target>

### Files Created
- <path>/Documentation.md
- <path>/Getting-Started.md
- <path>/User-Guide.md
- <path>/API-Reference.md

### Content Sources
- FunctionalSpecs.md: [sections referenced]
- SwiftTechSpecs.md: [sections referenced]
- Public symbols found: [count] types, [count] methods, [count] properties

### Next Steps
- Review generated articles for accuracy
- Add additional code examples where helpful
- Run `xcodebuild docbuild` to verify DocC compilation
```

Then stop. Do not proceed to Step 5.

## Step 5: Validate Mode (Catalog Exists)

### 5a: Check Required Articles Are Present

Verify all 4 required articles exist in the `Documentation.docc/` directory:
- `Documentation.md`
- `Getting-Started.md`
- `User-Guide.md`
- `API-Reference.md`

### 5b: Verify Article Content Standards

Read each article and check for:
- **Overview section**: Every article must have a clear overview/summary
- **Code examples**: Articles should include Swift code examples
- **Cross-references**: Articles should use `<doc:ArticleName>` links to other articles
- **DocC formatting**: Proper use of DocC Markdown syntax (##, ###, ```, etc.)

### 5c: Check Public API Coverage

Scan source files for public symbols (same as Step 4b). Compare against what is documented in `API-Reference.md` and the other articles. Identify any public symbols that are not referenced in the documentation.

### 5d: Verify Cross-Reference Validity

Extract all `<doc:...>` references from all articles. Verify each reference resolves to an existing article filename (without extension) in the same `Documentation.docc/` directory.

### 5e: Check DocumentationSpec.md Compliance

Verify compliance with best practices from DocumentationSpec.md:
- Progressive disclosure (simple to complex)
- Comprehensive coverage of public APIs
- Proper metadata sections (Overview, Usage, Parameters, Returns, Throws) in source documentation

### 5f: Produce Validation Report

Output a structured report:

```
## DocC Validation Report -- <Target>

### Required Articles
| Article | Status |
|---------|--------|
| Documentation.md | PASS / MISSING |
| Getting-Started.md | PASS / MISSING |
| User-Guide.md | PASS / MISSING |
| API-Reference.md | PASS / MISSING |

### Content Standards
| Check | Status | Details |
|-------|--------|---------|
| Overview sections | PASS / FAIL | [details] |
| Code examples | PASS / FAIL | [details] |
| Cross-references | PASS / FAIL | [details] |
| DocC formatting | PASS / FAIL | [details] |

### Public API Coverage
- Total public symbols: [count]
- Documented symbols: [count]
- Coverage: [percentage]%
- Undocumented symbols: [list if any]

### Cross-Reference Validity
- Total references: [count]
- Valid references: [count]
- Invalid references: [list if any]

### Recommendations
[Actionable items to improve documentation quality]
```
