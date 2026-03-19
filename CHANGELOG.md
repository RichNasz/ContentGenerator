# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- [OpenResponsesAgentGen] Add reasoning effort picker (None/Low/Medium/High/xHigh, default Medium), ReasoningItem.contentText capture for structured reasoning display, and detailed token breakdowns (reasoning tokens, cached input tokens) in the live token usage summary; update SwiftOpenResponsesDSL pin to revision 11391d7
- [OpenResponsesAgentGen] Add reasoning summary streaming support by parsing `response.reasoning_summary_part.added` and `response.reasoning_summary_part.done` SSE events from SwiftOpenResponsesDSL, surfacing reasoning/thinking content from models that emit these events (e.g. nemotron-3-nano on OpenRouter)
- [ChatCompletionsAgentGen] Add token usage display specs: completion summary (prompt/completion/total tokens), Column 2 placement below tool call log, and DSL gap note for future per-iteration usage tracking
- [ChatCompletionsAgentGen] Add get_unread_sections_tool and SectionReadTracker actor to enforce harness-side section completeness, guaranteeing the agent reads all enabled sections before writing its response
- [Project] Add GitHub Actions workflows for CI (SPM package builds/tests + Xcode app build/test), PR validation (conventional commit title check + changelog presence check), and tag-triggered release builds with artifact upload and GitHub Release creation
- [Project] Document .claude/ AI tooling structure in ProjectOverviewSpec, listing all 13 workflow skills and noting sub-project settings.local.json files are gitignored and skill-free

### Changed

- [OpenResponsesAgentGen, ChatCompletionsAgentGen] Derive maxIterations dynamically from enabled section count (enabledSections + 5) instead of static max(15, sections.count + 5), tightening the iteration limit to match the expected tool call flow
- [ContentGenerator] Fill spec completeness gaps for duplicate attachment replacement: add exact dialog title/message/button-label copy, full replaceAttachment(_:withFileAt:) signature and execution sequence, FileAttachmentSection @State property inventory, FileSelectionResult tuple field semantics, and selectAndAttachFiles catch-behaviour notes

### Deprecated

### Removed

### Fixed

- [ContentGenerator] Fix orphaned bundle directories accumulating on project deletion by removing each project's `projects/<uuid>/` directory from disk after the SwiftData delete is committed

### Security

## [2.0] - 2026-03-16

### Added

- [ContentGenerator] Introduce .cgspecs bundle-based storage, replacing the centralized
  SwiftData store with per-bundle isolated data stores and persistent bundle selection
  across sessions
- [LLMmanagement] Add LLM connection management library with OpenAI Chat Completions and
  Responses endpoint support, custom URL paths, per-connection model and timeout
  configuration, and persistent connection storage
- [ProjectExchange] Add portable project import/export library with JSON serialization,
  schema versioning, and file attachment metadata support
- [ContentGenerator] Add file attachment support with reference file selection and
  security-scoped bookmark management
- [ContentGenerator] Add project-level and section-level LLM connection references,
  enabling independent generation configuration per project and per section
- [ContentGenerator] Add project export/import workflow via ProjectExchange integration,
  including LLM connection conflict resolution on import

## [1.0] - 2026-03-16

### Added

- [Project] Add README.md files to CommonSpecs/ and each target's Specs/ folder for GitHub discoverability
- [ContentGenerator] Add log-change skill for proposing and writing changelog entries to CHANGELOG.md using Keep a Changelog format

### Changed

- [Project] Rename GitHub repository from ContentCreator to ContentGenerator to align with project name

### Fixed

- [ContentGenerator] Fix inconsistent font in specification section editors after programmatic text updates (content generation, expand/collapse sheet) by preserving typingAttributes during NSTextStorage replacement
