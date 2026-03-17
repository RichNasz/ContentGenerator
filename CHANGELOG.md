# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- [Project] Add GitHub Actions workflows for CI (SPM package builds/tests + Xcode app build/test), PR validation (conventional commit title check + changelog presence check), and tag-triggered release builds with artifact upload and GitHub Release creation
- [Project] Document .claude/ AI tooling structure in ProjectOverviewSpec, listing all 13 workflow skills and noting sub-project settings.local.json files are gitignored and skill-free

### Changed

- [ContentGenerator] Fill spec completeness gaps for duplicate attachment replacement: add exact dialog title/message/button-label copy, full replaceAttachment(_:withFileAt:) signature and execution sequence, FileAttachmentSection @State property inventory, FileSelectionResult tuple field semantics, and selectAndAttachFiles catch-behaviour notes

### Deprecated

### Removed

### Fixed

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
