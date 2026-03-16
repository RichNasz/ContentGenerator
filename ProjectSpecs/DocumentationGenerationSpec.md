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
| `ContentGenerator/README.md` | This spec + ContentGenerator FunctionalSpecs | App sub-project README |
| `LLMmanagement/README.md` | This spec + LLMmanagement FunctionalSpecs | Package sub-project README |
| `ProjectExchange/README.md` | This spec + ProjectExchange FunctionalSpecs | Package sub-project README |
| `CommonSpecs/README.md` | This spec | Shared specs folder README |
| `ContentGenerator/Specs/README.md` | This spec | App specs folder README |
| `LLMmanagement/Specs/README.md` | This spec | Package specs folder README |
| `ProjectExchange/Specs/README.md` | This spec | Package specs folder README |
| `Skills/README.md` | SkillDevelopmentSpec + this spec | Skills system overview |
| `Skills/prep-for-coding/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/validate-build/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/log-error/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/update-specs/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/log-change/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/evaluate-specs/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/generate-docc/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/generate-repo-docs/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/run-tests/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/validate-integration/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/validate-specs/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/validate-commit/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |
| `Skills/build-distribution/SkillSpec.md` | SkillDevelopmentSpec + this spec | Skill documentation |

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

## Sub-Project README Files

Each subproject directory (`ContentGenerator/`, `LLMmanagement/`, `ProjectExchange/`) has its own README.md. These are generated from the target's FunctionalSpecs and must conform to the following rules.

### Structure (all sub-READMEs)

1. **H1 Title** — Component name with type in parentheses (e.g., "LLMmanagement (Swift Package)")
2. **Description** — One paragraph from the target's FunctionalSpecs overview
3. **Role in Monorepo** — How the app references this component (local SPM package, Xcode project)
4. **Key Features** — Brief bullet list drawn from FunctionalSpecs core functionality
5. **Specs** — Link to the target's `Specs/` folder
6. **Building** — Target-specific build instructions:
   - App: open `.xcodeproj` in Xcode, Cmd+R
   - SPM packages: `swift build` / `swift test`
7. **Back Link** — Link back to root `../README.md`

### Rules

- No badge row (badges are root-level only)
- No duplicate of root README content (architecture, contributing, license)
- Keep concise — sub-READMEs orient the reader, not replicate AppDocumentation.md
- Same tone rules as root README (professional, precise, no emojis)

---

## Specs Folder README Files

Each `Specs/` folder and the root `CommonSpecs/` folder has a README.md that renders on GitHub when browsing the directory. These READMEs must conform to the following rules.

### Structure

1. **H1 Title** — Folder name with role in parentheses (e.g., "CommonSpecs (Shared Development Reference)")
2. **Description** — One paragraph explaining what the folder contains and how it is used in the spec-driven workflow
3. **Files Table** — Markdown table listing every `.md` file in the folder with a one-line description
4. **Spec-Driven Workflow** — Brief explanation of which Claude Code skills maintain these files
5. **Back Link** — Link back to the parent README and root README

### Rules

- No badge row (badges are root-level only)
- Same tone rules as root README (professional, precise, no emojis)
- Keep concise — these orient the reader, not replicate spec content
- CommonSpecs README links back to root README only (no parent README)
- Target Specs READMEs link to both the target README and root README

---

## Skills Documentation Files

The `Skills/` folder and each skill subdirectory has documentation files that render on GitHub. These must conform to the following rules.

### Skills/README.md Structure

1. **H1 Title** -- folder name with role in parentheses
2. **Description paragraph** -- explains the skills system and dual-folder relationship
3. **Skills table** -- all skills with columns: Skill (linked), Category, Description
4. **Workflow diagram** -- text-based diagram showing skill invocation order
5. **Relationship to .claude/skills/** -- explains executable vs documentation split
6. **Skill Development link** -- link to `ProjectSpecs/SkillDevelopmentSpec.md`
7. **Back link** -- link to root README

### Skills/\<name\>/SkillSpec.md Structure

1. **H1 Title** -- skill name in human-readable form
2. **Description** -- one paragraph explaining purpose
3. **Workflow Position** -- category and when to invoke
4. **Invocation** -- slash command syntax with argument description
5. **Inputs** -- files and data the skill reads
6. **Outputs** -- what the skill produces
7. **Allowed Tools** -- tools the skill is permitted to use
8. **Related Skills** -- skills typically invoked before or after
9. **Back Links** -- links to Skills/README.md and root README

### Rules

- No badge row (badges are root-level only)
- Same tone rules as root README (professional, precise, no emojis)
- Keep concise -- describe what the skill does, do not replicate SKILL.md step-by-step instructions
- SkillSpec.md files orient the reader and point to .claude/skills/ for execution details

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
- [ ] I have run `/run-tests` after successful build (if target has tests)
- [ ] I have run `/log-error` for any resolved errors
- [ ] I have run `/update-specs` after completing functionality changes
- [ ] My changes follow the project's concurrency conventions (no GCD, no DispatchQueue)
- [ ] I have tested my changes in Xcode

Sections:
- Summary of changes
- Related specs or issues
- Test plan
