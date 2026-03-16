# DocumentationGenerationSpec

> Authoritative rules for generating all monorepo-level Markdown documentation from ProjectSpecs.

---

## Generated Files

The following files are generated from ProjectSpecs and must conform to the rules in this document:

| File | Source Specs | Purpose |
|------|-------------|---------|
| `README.md` | ProjectOverviewSpec + this spec | GitHub front page |
| `CONTRIBUTING.md` | ContributingSpec + this spec | Contribution guide |
| `CODE_OF_CONDUCT.md` | ContributingSpec | Contributor Covenant v2.1 |
| `.github/ISSUE_TEMPLATE/bug_report.md` | This spec | Bug report template |
| `.github/ISSUE_TEMPLATE/feature_request.md` | This spec | Feature request template |
| `.github/PULL_REQUEST_TEMPLATE.md` | ContributingSpec + this spec | PR checklist |

## General Tone

- Professional, precise, and welcoming
- No marketing hyperbole — state capabilities factually
- Use second person ("you") when addressing the reader
- Code examples use Swift unless otherwise noted
- No emojis in headings or body text

---

## README.md Structure

The README must contain the following sections in this exact order:

### 1. Badge Row
A single line of shields.io badges:
- macOS 14+ (blue)
- Swift 6.2 (orange)
- Xcode 16+ (blue)
- License: MIT (green)

### 2. Project Title and Tagline
The project name as H1, followed by the tagline from ProjectOverviewSpec.

### 3. Description
One-paragraph description from ProjectOverviewSpec.

### 4. Key Features
Bullet list of key features from ProjectOverviewSpec.

### 5. Screenshots
Placeholder section with note: "Screenshots coming soon." (to be filled after first release).

### 6. System Requirements
From ProjectOverviewSpec.

### 7. Getting Started
Step-by-step:
1. Clone the repository
2. Open `ContentGenerator/ContentGenerator.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. Note: LLMmanagement and ProjectExchange resolve automatically as local SPM packages

### 8. Architecture
Component table from ProjectOverviewSpec, plus brief explanation of the spec-driven approach.

### 9. Documentation
Link to `AppDocumentation.md` as the comprehensive feature reference.
Link to each target's `Specs/` folder.

### 10. Contributing
Brief summary with link to `CONTRIBUTING.md`.

### 11. License
MIT — link to `LICENSE` file.

### 12. Acknowledgments
- Apple (SwiftUI, SwiftData)
- OpenAI (API compatibility standard)
- Contributors

---

## CONTRIBUTING.md Structure

Sections in order:
1. Welcome message
2. Code of Conduct reference (link to CODE_OF_CONDUCT.md)
3. Spec-driven development workflow (from ContributingSpec)
4. How to report bugs (link to issue template)
5. How to suggest features (link to issue template)
6. Pull request process (from ContributingSpec)
7. Commit conventions (from ContributingSpec)
8. Development setup (clone, build, test instructions)
9. Security policy (from ContributingSpec)

---

## CODE_OF_CONDUCT.md

Full text of Contributor Covenant v2.1. No modifications except:
- Contact method: GitHub private vulnerability reporting
- Project name: ContentGenerator

---

## Issue Templates

### bug_report.md
YAML front matter with `name`, `about`, `labels: ["bug"]`.
Sections:
- Describe the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (macOS version, Xcode version)
- Additional context

### feature_request.md
YAML front matter with `name`, `about`, `labels: ["enhancement"]`.
Sections:
- Problem or use case
- Proposed solution
- Alternatives considered
- Additional context

---

## Pull Request Template

Checklist enforcing the spec-driven workflow:
- [ ] I have run `/prep-for-coding` before making changes
- [ ] I have run `/validate-build` after making changes
- [ ] I have run `/log-error` for any resolved errors
- [ ] I have run `/update-specs` after completing functionality changes
- [ ] My changes follow the project's concurrency conventions (no GCD, no DispatchQueue)
- [ ] I have tested my changes in Xcode

Sections:
- Summary of changes
- Related specs or issues
- Test plan
