# ContentGenerator (macOS App)

ContentGenerator is a native macOS application that leverages large language models to create, refine, and manage structured content. It provides a project-based workspace where AI is integrated into every stage of the content creation workflow, serving product marketers, corporate communications teams, blog authors, and business writers.

## Role in Monorepo

The main Xcode application that composes three supporting Swift packages — LLMmanagement, ProjectExchange, and AgentGen — as local SPM dependencies. All user-facing functionality lives here.

## Key Features

- Bundle-based workspace (`.cgspecs`) with SwiftData persistence and auto-save
- Project management with ordered, toggleable specification sections
- Real-time streaming content generation via Chat Completions and Responses endpoints
- Agent-based generation with Apple Intelligence and Open Responses backends
- Drag-and-drop reference file attachments stored inside the bundle
- Markdown export and JSON project import/export with schema versioning and file attachment embedding
- LLM connection management with grouped endpoint-type picker (Chat Completions / Responses)
- Dedicated generation windows for section-level and project-level content creation
- Thinking model support with collapsible chain-of-thought display

## Specs

See [Specs/](Specs/) for this target's specification files:
- [FunctionalSpecs.md](Specs/FunctionalSpecs.md) — What the app does
- [SwiftTechSpecs.md](Specs/SwiftTechSpecs.md) — How it is implemented
- [CodeLessonsLearned.md](Specs/CodeLessonsLearned.md) — Error patterns and solutions

For the comprehensive feature reference, see [AppDocumentation.md](../AppDocumentation.md).

## Building

1. Open `ContentGenerator.xcodeproj` in Xcode 26.3 or later
2. Build and run (Cmd+R)

Local package dependencies (LLMmanagement, ProjectExchange, AgentGen) resolve automatically.

---

[Back to root README](../README.md)
