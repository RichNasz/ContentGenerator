![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange) ![Xcode 26.3+](https://img.shields.io/badge/Xcode-26.3%2B-blue) ![License: MIT](https://img.shields.io/badge/License-MIT-green) ![CI](https://github.com/USER/ContentGenerator/actions/workflows/CI.yml/badge.svg?branch=main)

# ContentGenerator

AI-first content generation for macOS, built with spec-driven development.

## Description

ContentGenerator is a native macOS application that leverages large language models to create, refine, and manage structured content. Designed for content professionals — product marketers, corporate communications teams, blog authors, and business writers — it provides a project-based workspace where AI is integrated into every stage of the content creation workflow.

## Key Features

- **Project-Based Workspace:** Create isolated projects with their own specifications, prompts, and LLM connections
- **Structured Content Specifications:** Define content requirements through ordered, toggleable specification sections with generation and usage prompts
- **Multi-Provider LLM Support:** Connect to OpenAI, Google Gemini, xAI Grok, vLLM, and local models (Ollama, LM Studio) via OpenAI-compatible API
- **Real-Time Streaming Generation:** Character-by-character streaming display with progress indication and cancellation support
- **Dedicated AI Windows:** AI interactions happen in separate windows, clearly distinguishing AI-assisted from non-AI workflows
- **Reference File Attachments:** Drag-and-drop text files as additional context for generation, with bundle-based storage
- **Export and Import:** Markdown export, JSON project exchange (with schema versioning), and clipboard operations
- **Bundle-Based Storage:** `.cgspecs` bundle format with SwiftData persistence and automatic save with debouncing
- **Auto-Save with State Persistence:** Automatic saving, remembered selections, and window state restoration

## Screenshots

Screenshots coming soon.

## System Requirements

- **OS:** macOS 26.3 or later
- **IDE:** Xcode 26.3 or later (for building from source)
- **Language:** Swift 6.2
- **LLM Access:** At least one OpenAI-compatible API endpoint (cloud or local)

## Getting Started

1. Clone the repository
2. Open `ContentGenerator/ContentGenerator.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. Note: LLMmanagement, ProjectExchange, and AgentGen resolve automatically as local SPM packages
5. To use Claude Code, run `claude` from the repo root (not a subdirectory)

## Architecture

ContentGenerator is a monorepo containing four components:

| Component | Type | Path | Purpose |
|-----------|------|------|---------|
| **ContentGenerator** | macOS App (Xcode) | `ContentGenerator/` | Main application — UI, project management, content generation workflows |
| **LLMmanagement** | Swift Package (SPM) | `LLMmanagement/` | LLM connection management, OpenAI-compatible API client, streaming support |
| **ProjectExchange** | Swift Package (SPM) | `ProjectExchange/` | JSON import/export with schema versioning, conflict resolution |
| **AgentGen** | Swift Package (SPM) | `AgentGen/` | Agent-based content generation with pluggable inference backends (Apple Intelligence, Open Responses) |

All code changes follow a spec-driven approach: specifications in each target's `Specs/` folder define what the component does and how it is implemented. Claude Code skills enforce this workflow through mandatory read-before-code and update-after-change steps.

## Documentation

- [AppDocumentation.md](AppDocumentation.md) — Comprehensive feature reference
- [ContentGenerator/Specs/](ContentGenerator/Specs/) — App-specific specifications
- [LLMmanagement/Specs/](LLMmanagement/Specs/) — LLM package specifications
- [ProjectExchange/Specs/](ProjectExchange/Specs/) — Import/export package specifications
- [AgentGen/Specs/](AgentGen/Specs/) — Agent generation package specifications
- [CommonSpecs/](CommonSpecs/) — Shared Swift development reference

## Contributing

All contributions follow the spec-driven workflow. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the full process, including required skill invocations, commit conventions, and development environment setup.

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

- [Apple](https://developer.apple.com) for SwiftUI and SwiftData
- [OpenAI](https://openai.com) for the API compatibility standard
- All contributors to this project
