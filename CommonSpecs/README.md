# CommonSpecs (Shared Development Reference)

Shared Swift development reference specifications used across all four targets (ContentGenerator, LLMmanagement, ProjectExchange, AgentGen). These specs are read by `/prep-for-coding` to inform code generation with consistent patterns and conventions.

## Files

| File | Description |
|------|-------------|
| `SwiftCodeGeneration.md` | Core Swift implementation guidance, concurrency patterns, code quality |
| `SwiftUISpec.md` | SwiftUI component patterns and requirements |
| `SwiftUIWithoutMVVM.md` | Direct state management without ViewModels |
| `SwiftDataPatterns.md` | SwiftData usage patterns (`@Model`, `ModelContext`) |
| `NavigationPatterns.md` | SwiftUI navigation patterns (`NavigationSplitView`) |
| `SwiftTestingSpec.md` | Swift Testing framework patterns |
| `DocumentationSpec.md` | DocC documentation standards |
| `SpecificationQualitySpec.md` | Spec quality evaluation criteria |

## How These Are Used

The spec-driven workflow reads these files before any code generation or modification. The `/prep-for-coding` skill synthesizes guidance from both these shared specs and the target-specific specs in each project's `Specs/` folder.

---

[Back to root README](../README.md)
