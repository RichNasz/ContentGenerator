![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange) ![Xcode 16+](https://img.shields.io/badge/Xcode-16%2B-blue) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

# ContentGenerator

**AI-first content generation for macOS, built with spec-driven development**

ContentGenerator is a native macOS application that leverages large language models to create, refine, and manage structured content. Designed for content professionals — product marketers, corporate communications teams, blog authors, and business writers — it provides a project-based workspace where AI is integrated into every stage of the content creation workflow.

## Key Features

- **Project-Based Workspace** — Create isolated projects with their own specifications, prompts, and LLM connections
- **Structured Content Specifications** — Define content requirements through ordered, toggleable specification sections with generation and usage prompts
- **Multi-Provider LLM Support** — Connect to OpenAI, Google Gemini, xAI Grok, vLLM, and local models (Ollama, LM Studio) via OpenAI-compatible API
- **Real-Time Streaming Generation** — Character-by-character streaming display with progress indication and cancellation support
- **Dedicated AI Windows** — AI interactions happen in separate windows, clearly distinguishing AI-assisted from non-AI workflows
- **Reference File Attachments** — Drag-and-drop text files as additional context for generation, with security-scoped bookmark support
- **Export and Import** — Markdown export, JSON project exchange with schema versioning, and clipboard operations
- **Bundle-Based Storage** — `.cgspecs` bundle format with SwiftData persistence and automatic save with debouncing

## Screenshots

*Screenshots coming soon.*

## System Requirements

- **OS:** macOS 14.0 (Sonoma) or later
- **IDE:** Xcode 16.0 or later (for building from source)
- **Language:** Swift 6.2
- **LLM Access:** At least one OpenAI-compatible API endpoint (cloud or local)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/<username>/ContentGenerator.git
   ```
2. Open `ContentGenerator/ContentGenerator.xcodeproj` in Xcode
3. Build and run (Cmd+R)

LLMmanagement and ProjectExchange resolve automatically as local SPM packages — no manual dependency setup required.

## Architecture

ContentGenerator is a monorepo containing three components:

| Component | Type | Path | Purpose |
|-----------|------|------|---------|
| **ContentGenerator** | macOS App | `ContentGenerator/` | UI, project management, content generation workflows |
| **LLMmanagement** | Swift Package | `LLMmanagement/` | LLM connection management, OpenAI-compatible API client, streaming |
| **ProjectExchange** | Swift Package | `ProjectExchange/` | JSON import/export with schema versioning, conflict resolution |

### Spec-Driven Development

This project follows a spec-driven development methodology where specification files are the source of truth for all code changes. Each target maintains its own `Specs/` folder with FunctionalSpecs (WHAT), SwiftTechSpecs (HOW), and CodeLessonsLearned (error patterns). See [CLAUDE.md](CLAUDE.md) for the full workflow.

## Documentation

- **[AppDocumentation.md](AppDocumentation.md)** — Comprehensive feature reference covering all application functionality
- **[ContentGenerator/Specs/](ContentGenerator/Specs/)** — App specifications
- **[LLMmanagement/Specs/](LLMmanagement/Specs/)** — LLM package specifications
- **[ProjectExchange/Specs/](ProjectExchange/Specs/)** — Exchange package specifications
- **[CommonSpecs/](CommonSpecs/)** — Shared Swift development reference specs
- **[ProjectSpecs/](ProjectSpecs/)** — Monorepo-level project specs

## Contributing

Contributions are welcome. Please read the [Contributing Guide](CONTRIBUTING.md) before submitting changes. This project uses a spec-driven workflow — all code changes must follow the specification update process.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Apple](https://developer.apple.com) — SwiftUI, SwiftData, and the macOS platform
- [OpenAI](https://openai.com) — API compatibility standard adopted by multiple providers
- All contributors to this project
