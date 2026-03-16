# ProjectOverviewSpec

> Canonical description of the ContentGenerator project. Source of truth for README and public documentation.

---

## Project Identity

- **Name:** ContentGenerator
- **Tagline:** AI-first content generation for macOS, built with spec-driven development
- **Description:** ContentGenerator is a native macOS application that leverages large language models to create, refine, and manage structured content. Designed for content professionals — product marketers, corporate communications teams, blog authors, and business writers — it provides a project-based workspace where AI is integrated into every stage of the content creation workflow.

## Design Philosophy

- **Spec-Driven Development:** All code changes are governed by specification files (FunctionalSpecs, SwiftTechSpecs, CodeLessonsLearned) that serve as the source of truth. AI-assisted coding follows a mandatory workflow: read specs → generate code → validate → update specs.
- **AI-First, AI-Always:** Every feature is designed around AI capabilities with continuous AI integration throughout all user workflows.
- **No MVVM:** Views manage state directly using `@State` and `@Bindable` with `@Observable` classes. No ViewModel layer.
- **Swift 6.2 Strict Concurrency:** Full `SWIFT_STRICT_CONCURRENCY = complete` with default `MainActor` isolation. Only Swift native concurrency (`async/await`, `Task`, `Actor`) — no GCD.
- **Apple HIG Compliance:** Native macOS interface following Apple Human Interface Guidelines.

## Key Features

- **Project-Based Workspace:** Create isolated projects with their own specifications, prompts, and LLM connections
- **Structured Content Specifications:** Define content requirements through ordered, toggleable specification sections with generation and usage prompts
- **Multi-Provider LLM Support:** Connect to OpenAI, Google Gemini, xAI Grok, vLLM, and local models (Ollama, LM Studio) via OpenAI-compatible API
- **Real-Time Streaming Generation:** Character-by-character streaming display with progress indication and cancellation support
- **Dedicated AI Windows:** AI interactions happen in separate windows, clearly distinguishing AI-assisted from non-AI workflows
- **Reference File Attachments:** Drag-and-drop text files as additional context for generation, with security-scoped bookmark support
- **Export and Import:** Markdown export, JSON project exchange (with schema versioning), and clipboard operations
- **Bundle-Based Storage:** `.cgspecs` bundle format with SwiftData persistence and automatic save with debouncing
- **Auto-Save with State Persistence:** Automatic saving, remembered selections, and window state restoration

## Target Audience

- Product marketers creating structured marketing content
- Corporate communications professionals managing messaging frameworks
- Blog authors and content creators using AI-assisted writing
- Business professionals generating text-based content with AI support

## System Requirements

- **OS:** macOS 14.0 (Sonoma) or later
- **IDE:** Xcode 16.0 or later (for building from source)
- **Language:** Swift 6.2
- **LLM Access:** At least one OpenAI-compatible API endpoint (cloud or local)

## Component Architecture

ContentGenerator is a monorepo containing three components:

| Component | Type | Path | Purpose |
|-----------|------|------|---------|
| **ContentGenerator** | macOS App (Xcode) | `ContentGenerator/` | Main application — UI, project management, content generation workflows |
| **LLMmanagement** | Swift Package (SPM) | `LLMmanagement/` | LLM connection management, OpenAI-compatible API client, streaming support |
| **ProjectExchange** | Swift Package (SPM) | `ProjectExchange/` | JSON import/export with schema versioning, conflict resolution |

The app references LLMmanagement and ProjectExchange as local SPM packages. All three components maintain their own specification files in their respective `Specs/` directories.

### Specification Hierarchy

- **`ProjectSpecs/`** — Monorepo-level specs (this folder): project overview, documentation rules, contribution guidelines, repository structure
- **`CommonSpecs/`** — Shared Swift development reference specs used across all targets
- **`<Target>/Specs/`** — Target-specific specs: FunctionalSpecs (WHAT), SwiftTechSpecs (HOW), CodeLessonsLearned (error patterns)
