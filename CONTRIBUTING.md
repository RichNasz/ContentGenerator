# Contributing to ContentGenerator

Thank you for your interest in contributing to ContentGenerator. This guide explains the development workflow, conventions, and process for submitting changes.

## Code of Conduct

This project follows the [Contributor Covenant v2.1](CODE_OF_CONDUCT.md). All participants are expected to uphold this code. Unacceptable behavior can be reported via GitHub's private vulnerability reporting on this repository.

## Spec-Driven Development Workflow

ContentGenerator uses a specification-driven methodology. All code changes **must** follow this workflow:

1. **Before writing or modifying code:** Run `/prep-for-coding <feature area>` to read applicable specs and produce an implementation approach.
2. **Write or modify code.**
3. **After code changes:** Run `/validate-build <target>` (target: ContentGenerator, LLMmanagement, or ProjectExchange) to verify the build.
4. **After resolving any error:** Run `/log-error <description>` to document the error in CodeLessonsLearned.md.
5. **After completing functionality changes:** Run `/update-specs <description>` to update FunctionalSpecs, SwiftTechSpecs, and CodeLessonsLearned.
6. **Optional:** Run `/log-change <description>` to record the change in CHANGELOG.md.

The specification files are the source of truth. They enable AI-assisted development at scale by providing consistent, accurate context. Skipping spec updates degrades the quality of all future AI-assisted work on the project.

## Reporting Bugs

Use the [bug report template](https://github.com/<username>/ContentGenerator/issues/new?template=bug_report.md) to file a bug. Include:

- Steps to reproduce
- Expected vs. actual behavior
- macOS and Xcode versions

## Suggesting Features

Use the [feature request template](https://github.com/<username>/ContentGenerator/issues/new?template=feature_request.md). Describe the problem or use case, your proposed solution, and any alternatives you considered.

## Pull Request Process

1. Fork the repository and create a feature branch from `main`
2. Follow the spec-driven workflow for all changes
3. Ensure `xcodebuild` succeeds for ContentGenerator and `swift build` succeeds for SPM packages
4. Fill out the pull request template completely (all checklist items)
5. Describe what changed and why, referencing relevant specs or issues
6. Wait for review — maintainers may request spec updates or additional validation

## Commit Conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use When |
|--------|----------|
| `feat:` | Adding new functionality |
| `fix:` | Fixing a bug |
| `spec:` | Updating specification files only |
| `refactor:` | Restructuring code without changing behavior |
| `docs:` | Documentation-only changes |
| `chore:` | Build, tooling, or maintenance tasks |

Keep the subject line under 72 characters. Use imperative mood ("add feature" not "added feature"). Include `Co-Authored-By` when AI-assisted.

## Development Setup

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later
- Swift 6.2

### Building
1. Clone the repository
2. Open `ContentGenerator/ContentGenerator.xcodeproj` in Xcode
3. Build and run (Cmd+R)
4. LLMmanagement and ProjectExchange resolve automatically as local SPM packages

### Key Conventions
- No MVVM — views manage state directly with `@State`/`@Bindable`
- `@Observable` classes, not `@ObservableObject`
- Default `MainActor` isolation — no explicit `@MainActor` annotations needed
- Only Swift native concurrency (`async/await`, `Task`, `Actor`) — no GCD, no DispatchQueue
- SwiftData with `@Model` classes

## Security Policy

To report a security vulnerability:

1. **Do NOT open a public issue.**
2. Use [GitHub's private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository.
3. Maintainers will respond within 7 days and work with you on a fix.
