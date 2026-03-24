# ContentGenerator (macOS App)

ContentGenerator is the main macOS application — an AI-infused content generation tool that leverages large language models to create, refine, and manage structured content. It provides a project-based workspace where AI is integrated into every stage of the content creation workflow.

## Role in Monorepo

This is the primary application target. It references [LLMmanagement](../LLMmanagement/), [ProjectExchange](../ProjectExchange/), and [AgentGen](../AgentGen/) as local Swift packages via relative paths in the Xcode project.

## Key Features

- **Bundle Management** — `.cgspecs` bundle format for portable project storage with SwiftData persistence
- **Project Management** — Create, edit, delete, and organize isolated content projects
- **Content Specifications** — Ordered, toggleable specification sections with generation and usage prompts
- **Multi-Provider LLM Generation** — Real-time streaming from OpenAI, Gemini, Grok, vLLM, and local models
- **Dedicated AI Windows** — Separate windows for AI interactions, distinguishing AI-assisted from non-AI workflows
- **Reference File Attachments** — Drag-and-drop text files with security-scoped bookmark support
- **Export and Import** — Markdown export, JSON project exchange, clipboard operations
- **Auto-Save** — Automatic persistence with debouncing and save state indicators

## Specs

See [Specs/](Specs/) for this target's specification files:
- [FunctionalSpecs.md](Specs/FunctionalSpecs.md) — What the app does
- [SwiftTechSpecs.md](Specs/SwiftTechSpecs.md) — How it's implemented
- [CodeLessonsLearned.md](Specs/CodeLessonsLearned.md) — Error patterns and solutions

For the comprehensive feature reference, see [AppDocumentation.md](../AppDocumentation.md).

## Building

1. Open `ContentGenerator.xcodeproj` in Xcode 16+
2. Build and run (Cmd+R)

Local package dependencies (LLMmanagement, ProjectExchange, AgentGen) resolve automatically.

---

[Back to root README](../README.md)
