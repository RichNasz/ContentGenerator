# RepositoryStructureSpec

> Documents the monorepo layout and how the components fit together.

---

## Directory Tree

```
ContentGenerator/                    # Repository root
├── CLAUDE.md                        # AI assistant instructions (spec-driven workflow)
├── CHANGELOG.md                     # Project changelog (Keep a Changelog format)
├── README.md                        # Generated — GitHub front page
├── CONTRIBUTING.md                  # Generated — contribution guide
├── CODE_OF_CONDUCT.md               # Generated — Contributor Covenant v2.1
├── LICENSE                          # MIT license
├── AppDocumentation.md              # Comprehensive feature reference (515+ lines)
├── .gitignore                       # Root-level gitignore
│
├── ProjectSpecs/                    # Monorepo-level specs (source of truth for docs)
│   ├── ProjectOverviewSpec.md       # Project identity, features, architecture
│   ├── DocumentationGenerationSpec.md # Rules for generating README, CONTRIBUTING, etc.
│   ├── ContributingSpec.md          # Contribution workflow, commit conventions
│   ├── SkillDevelopmentSpec.md      # Skill creation template and governance rules
│   └── RepositoryStructureSpec.md   # This file — repo layout documentation
│
├── CommonSpecs/                     # Shared Swift development reference specs
│   ├── DocumentationSpec.md         # DocC documentation standards
│   ├── NavigationPatterns.md        # SwiftUI navigation patterns
│   ├── SpecificationQualitySpec.md  # Spec quality criteria
│   ├── SwiftCodeGeneration.md       # Swift code generation rules
│   ├── SwiftDataPatterns.md         # SwiftData usage patterns
│   ├── SwiftTestingSpec.md          # Swift Testing framework patterns
│   ├── SwiftUISpec.md               # SwiftUI component patterns
│   └── SwiftUIWithoutMVVM.md        # Direct state management (no MVVM)
│
├── Skills/                          # Claude Code skill documentation and assets
│   ├── README.md                    # Skills system overview and table of all skills
│   ├── prep-for-coding/
│   │   └── SkillSpec.md             # Skill specification
│   ├── validate-build/
│   │   └── SkillSpec.md
│   ├── log-error/
│   │   └── SkillSpec.md
│   ├── update-specs/
│   │   └── SkillSpec.md
│   ├── log-change/
│   │   └── SkillSpec.md
│   ├── evaluate-specs/
│   │   └── SkillSpec.md
│   └── generate-docc/
│       └── SkillSpec.md
│
├── ContentGenerator/                # macOS application (Xcode project)
│   ├── ContentGenerator.xcodeproj/  # Xcode project file
│   ├── ContentGenerator/            # App source code
│   │   ├── App/                     # App entry point, lifecycle
│   │   ├── ContentGeneration/       # Content generation features
│   │   │   └── Views/              # Generation-related views
│   │   └── ...                      # Other source directories
│   ├── Specs/                       # Target-specific specs
│   │   ├── FunctionalSpecs.md       # WHAT the app does
│   │   ├── SwiftTechSpecs.md        # HOW it's implemented
│   │   ├── CodeLessonsLearned.md    # Error patterns and solutions
│   │   ├── AICodeGenerationSpec.md  # AI code generation rules
│   │   └── ValidationFramework.md   # Build validation framework
│   └── .gitignore                   # Package-level gitignore
│
├── LLMmanagement/                   # Swift package — LLM connection management
│   ├── Package.swift                # SPM manifest (swift-tools-version: 6.2)
│   ├── Sources/                     # Package source code
│   ├── Tests/                       # Package tests
│   ├── Specs/                       # Target-specific specs
│   │   ├── FunctionalSpecs.md
│   │   ├── SwiftTechSpecs.md
│   │   └── CodeLessonsLearned.md
│   └── .gitignore                   # Package-level gitignore
│
├── ProjectExchange/                 # Swift package — JSON import/export
│   ├── Package.swift                # SPM manifest (swift-tools-version: 6.2)
│   ├── Sources/                     # Package source code
│   ├── Tests/                       # Package tests
│   └── Specs/                       # Target-specific specs
│       ├── FunctionalSpecs.md
│       └── SwiftTechSpecs.md
│
├── ContentGenerator.xcworkspace/    # Xcode workspace (aggregates all components)
├── ContentGenerator.icon/           # App icon assets
│
└── .github/                         # GitHub configuration
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   └── feature_request.md
    └── PULL_REQUEST_TEMPLATE.md
```

## How Xcode References SPM Packages

The Xcode project (`ContentGenerator/ContentGenerator.xcodeproj`) references LLMmanagement and ProjectExchange as **local Swift packages** using relative paths:

- `../LLMmanagement` — resolves to the LLMmanagement directory at the repo root
- `../ProjectExchange` — resolves to the ProjectExchange directory at the repo root

These references are stored in the `.xcodeproj` file. When you open the project in Xcode, the packages resolve automatically — no `swift package resolve` or manual setup required.

## Role of Each Specs Folder

### ProjectSpecs/ (Monorepo-Level)
Project-wide specifications that govern documentation generation, contribution guidelines, and repository structure. These are human-authored and serve as the source of truth for generated files like README.md and CONTRIBUTING.md.

### CommonSpecs/ (Shared Reference)
Swift development reference specifications shared across all three targets. These encode patterns and conventions (SwiftUI without MVVM, SwiftData patterns, concurrency rules) that apply uniformly. They are read by `/prep-for-coding` to inform code generation.

### \<Target\>/Specs/ (Target-Specific)
Each target maintains three core spec files:
- **FunctionalSpecs.md** — WHAT the target does (features, behaviors, requirements)
- **SwiftTechSpecs.md** — HOW it's implemented (architecture, types, protocols, patterns)
- **CodeLessonsLearned.md** — Resolved error patterns with 12-field templates

These are updated by the `/update-specs` skill after functionality changes and read by `/prep-for-coding` before code generation.

### Skills/ (Skill Documentation)
Human-readable specifications for the Claude Code skills defined in `.claude/skills/`. Each skill has a `SkillSpec.md` describing its purpose, workflow position, inputs, and outputs. The SKILL.md executable definitions remain in `.claude/skills/` where Claude Code expects them. Governance rules for creating and maintaining skills are in `ProjectSpecs/SkillDevelopmentSpec.md`.

## Build Instructions

1. **Clone:** `git clone <repository-url>`
2. **Open:** `ContentGenerator/ContentGenerator.xcodeproj` in Xcode 16+
3. **Build:** Cmd+R (or Product → Run)
4. **SPM Packages:** Resolve automatically — no manual steps needed

For package-only work:
- `cd LLMmanagement && swift build`
- `cd ProjectExchange && swift build`
