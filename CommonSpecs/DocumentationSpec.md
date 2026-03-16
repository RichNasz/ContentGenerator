# Swift Code Documentation Specification

## Overview

This document specifies the comprehensive documentation requirements for Swift code development projects.

### AI + Human Collaboration Context

For comprehensive AI + Human collaboration methodology, including roles, responsibilities, and full codebase regeneration requirements, see SwiftCodeGeneration.md. Documentation standards in this specification ensure consistency and quality across this collaborative workflow.

## Requirements
- **Documentation**: Include a README.md with an overview of the code base, feature descriptions, usage examples, and installation instructions
- **User Guide**: Provide user help and onboarding documentation
- **API Documentation**: Document any public APIs or frameworks
- **Implementation Guidance Reference**: Code documentation and examples should align with patterns in SwiftCodeGeneration.md
- **Testing Documentation**: Test documentation should follow patterns defined in SwiftTestingSpec.md

## Exclusions
- **DO NOT include GitHub Actions workflows or CI/CD automation**
- **DO NOT include build status badges or automated testing references**
- **DO NOT include continuous integration or continuous deployment content**
- **DO NOT include automated deployment or pipeline automation**
- **DO NOT include links to hosted DocC documentation unless actually hosted and verified**
- **DO NOT use incorrect file paths or non-prefixed article names when linking to DocC content**

## README.md Structure
The root README.md file must include the following sections in order:

1. **Project Title and Badge Section**
   - Project name and brief tagline
   - Platform compatibility badges

2. **Overview Section**
   - Clear description of what the code base does
   - Key features and capabilities as defined in any functional specification associated with the project
   - Target audience and use cases as defined in any functional specification associated with the project
   - Reference to functional specification for detailed requirements

3. **Installation Section**
   - Installation instructions (App Store, TestFlight, or development setup)
   - Minimum iOS version requirements (26.0+)
   - Device compatibility information (iPhone, iPad)

4. **Features Section**
   - Detailed feature descriptions (based on functional specification requirements)
   - Screenshots or feature highlights demonstrating functional specification capabilities
   - How-to guides for key functionality defined in the functional specification

5. **Requirements Section**
   - Platform compatibility requirements
   - Device compatibility (iPhone, iPad)
   - Dependencies and permissions

6. **Support & Contact Section**
    - Contact information for support
    - Links to community resources
    - Issue reporting guidelines

7. **Privacy Policy Section**
    - Data collection and usage policies
    - Privacy policy link
    - Compliance information

8. **Beta Testing Information Section** (Optional for TestFlight apps)
    - Beta testing release notes and build information
    - Beta testing guidelines and tester instructions
    - Feedback collection and bug reporting processes
    - Known issues and development roadmap

## Beta Testing Documentation Requirements (Optional)

### Beta Release Content
- **App Name**: Your application name
- **Release Notes**: Clear, concise notes for each beta build
- **Tester Communication**: Instructions for invited testers
- **Beta Testing Guidelines**: What testers should focus on and how to report issues
- **Support Contact**: How testers can reach the development team

### Beta Testing Screenshots and Assets
- **Screenshots**: 3-6 screenshots showing key features for beta testing
- **App Icon**: 1024x1024 pixels, following Apple's design guidelines
- **App Previews**: Optional video previews for beta builds
- **Content**: Real app UI demonstrating current functionality

### Beta Testing Documentation
- **Test Scenarios**: Specific user flows and features to test
- **Bug Report Template**: Standardized format for tester feedback
- **Known Issues**: List of current limitations and planned fixes
- **Feedback Collection**: Process for gathering tester input

## Distribution and Compliance Requirements

### TestFlight Distribution Requirements

#### Technical Requirements
- **iOS Version Support**: Minimum iOS 26.0 deployment target (to take advantage of latest features and benefits)
- **Xcode Version Support**: For version requirements, see SwiftCodeGeneration.md
- **Device Compatibility**: Support for iPhone and iPad
- **Screen Size Support**: Responsive design for all device sizes
- **Orientation Support**: Portrait and landscape orientations
- **TestFlight Limits**: Maximum 10,000 external testers per app

#### TestFlight Guidelines
- **Beta Testing Agreement**: Testers must accept Apple's Beta Testing Agreement
- **Data Collection**: Appropriate privacy policy for beta testing data
- **Feedback Collection**: Mechanisms for gathering tester feedback
- **Build Expiration**: Builds expire after 90 days or 30 days after new build is released

### App Store Compliance Verification
- **Code Generation Review**: Generate code from specifications and verify it doesn't violate App Store rules
- **Pre-submission Checklist**: Review all features against App Store Review Guidelines before TestFlight builds
- **Content Review**: Ensure no prohibited content, functionality, or business model violations
- **API Usage Verification**: Confirm all third-party services and APIs comply with App Store policies
- **Privacy Policy Alignment**: Verify app privacy practices align with App Store requirements

## Documentation Strategy & Planning

### Content Strategy
- **Target Audience Analysis**: Identify and prioritize different user personas:
  - App users (end users)
  - Beta testers (if applicable)
  - Internal development and QA team members
  - Stakeholders and project sponsors
  - Support team members
- **Content Maturity Model**: Define documentation progression paths from MVP to full release
- **Success Metrics**: Establish KPIs for project success including user engagement, feedback quality, and feature adoption

### Documentation Planning Process
1. **Content Inventory**: Audit existing documentation and identify gaps
2. **User Research**: Gather feedback from beta testers and target users
3. **Content Roadmap**: Plan documentation updates aligned with app releases
4. **Quality Gates**: Establish review processes for documentation and app content
5. **AI + Human Collaboration Updates**: Update specifications to reflect all joint modifications and improvements
6. **Maintenance Schedule**: Regular content updates for new features and iOS updates

### Specification Maintenance Requirements

For comprehensive specification maintenance and update requirements after AI + Human joint modifications, see SwiftCodeGeneration.md.

## In-App Documentation and Help

### User Onboarding
- **Welcome Screens**: Initial setup and feature introduction
- **Interactive Tutorials**: Step-by-step guidance for key features
- **Tooltips and Hints**: Contextual help throughout the app
- **Progressive Disclosure**: Show advanced features as users become familiar

### Help System
- **In-App Help**: Contextual help accessible from any screen
- **FAQ Section**: Common questions and answers
- **Video Tutorials**: Optional video guides for complex features
- **Search Functionality**: Allow users to search help content

## User Experience Documentation

### Accessibility Support
- **VoiceOver Compatibility**: Ensure all UI elements are accessible
- **Dynamic Type Support**: Support for different text sizes
- **Color Accessibility**: Sufficient color contrast ratios
- **Motor Accessibility**: Support for assistive touch and switch control

### Localization Requirements
- **Language Support**: Identify target languages and regions
- **Cultural Adaptation**: Adapt content for different cultures
- **Date/Time Formatting**: Localized date and time displays
- **Right-to-Left Support**: Support for RTL languages if applicable

## Technical Documentation

### Source File Header Requirements
All source files must include a standardized header comment block with the following information:

```swift
//
//  FileName.swift
//  PackageName
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
```

**Required Header Elements:**
- **File Name**: The name of the source file
- **Package/Target Name**: The containing package or target name
- **Author Attribution**: "Created by Richard Naszcyniec with AI-assisted code generation."
- **License Reference**: Reference to the license.txt file for open source terms

## Open Source Repository Files

For open source projects hosted on GitHub, the following files are required at the repository root level:

### LICENSE File (Required)
- **File Name**: `LICENSE` (no extension) at repository root
- **Content**: Full text of the chosen open source license
- **Supported Licenses**: MIT, Apache 2.0, GPL, or other OSI-approved licenses
- **Consistency**: Must match the license referenced in source file headers

### CONTRIBUTING.md (Required)
Guidelines for contributors must include:
- **Code of Conduct Reference**: Link to CODE_OF_CONDUCT.md
- **Getting Started**: How to set up the development environment
- **Contribution Process**: Steps for submitting contributions
- **Pull Request Guidelines**: Requirements for PR submissions
- **Code Style**: Reference to coding standards (SwiftCodeGeneration.md patterns)
- **Testing Requirements**: How to run tests before submitting (SwiftTestingSpec.md)
- **Documentation Requirements**: Expectations for documenting new features

Example structure:
```markdown
# Contributing to [Project Name]

Thank you for your interest in contributing!

## Code of Conduct
Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Getting Started
1. Fork the repository
2. Clone your fork locally
3. Open the project in Xcode 26.1.1+
4. Build and run to verify setup

## How to Contribute
1. Create a branch for your feature or fix
2. Make your changes following our coding standards
3. Write or update tests as needed
4. Update documentation if applicable
5. Submit a pull request

## Pull Request Process
- Provide a clear description of changes
- Reference any related issues
- Ensure all tests pass
- Update relevant documentation
```

### CODE_OF_CONDUCT.md (Required)
Community behavior standards must include:
- **Standards**: Expected behavior from community members
- **Responsibilities**: Maintainer responsibilities
- **Enforcement**: How violations are handled
- **Contact**: How to report issues

Recommended: Use the [Contributor Covenant](https://www.contributor-covenant.org/) as a template.

### CHANGELOG.md (Required)
Version history following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
### Added
- New features not yet released

## [1.0.0] - YYYY-MM-DD
### Added
- Initial release features

### Changed
- Modified behaviors

### Fixed
- Bug fixes

### Removed
- Removed features

### Security
- Security-related changes
```

### SECURITY.md (Required)
Vulnerability reporting process must include:
- **Supported Versions**: Which versions receive security updates
- **Reporting Process**: How to report vulnerabilities privately
- **Response Timeline**: Expected response time for reports
- **Disclosure Policy**: How vulnerabilities are disclosed after fixes

Example:
```markdown
# Security Policy

## Supported Versions
| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability
Please report security vulnerabilities by emailing [security contact].
Do not create public issues for security vulnerabilities.

We will respond within 48 hours and work with you to understand and resolve the issue.
```

## GitHub Community Files

### Issue Templates (Required)
Create `.github/ISSUE_TEMPLATE/` directory with the following templates:

#### Bug Report Template (`bug_report.md`)
```markdown
---
name: Bug Report
about: Report a bug to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
A clear and concise description of the bug.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- macOS/iOS Version:
- App Version:
- Device (if applicable):

## Screenshots
If applicable, add screenshots.

## Additional Context
Any other relevant information.
```

#### Feature Request Template (`feature_request.md`)
```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Problem Statement
A clear description of the problem this feature would solve.

## Proposed Solution
Your suggested approach to solving the problem.

## Alternatives Considered
Other solutions you've considered.

## Additional Context
Any other relevant information or mockups.
```

### Pull Request Template (Required)
Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Description
Brief description of the changes.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Related Issues
Closes #(issue number)

## Testing
Describe testing performed.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Documentation updated (if applicable)
- [ ] Tests added/updated (if applicable)
- [ ] All tests pass locally
```

## README.md Open Source Enhancements

In addition to the README.md Structure defined above, open source projects must include:

### License Badge (Required)
Add a license badge in the badge section:
```markdown
![License](https://img.shields.io/badge/License-MIT-blue.svg)
```
Or use shields.io for other license types.

### Platform and Version Badges (Required)
```markdown
![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2026.0%2B%20%7C%20iOS%2026.0%2B-lightgrey.svg)
```

### Swift Package Manager Installation (Required for Packages)
For Swift packages, include SPM installation instructions:
```markdown
## Installation

### Swift Package Manager
Add the following to your `Package.swift`:

\`\`\`swift
dependencies: [
    .package(url: "https://github.com/username/package-name", from: "1.0.0")
]
\`\`\`

Or in Xcode: File → Add Package Dependencies → Enter repository URL
```

### Acknowledgments Section (Required)
Credit contributors, dependencies, and inspirations:
```markdown
## Acknowledgments

- [Dependency Name](link) - Description of use
- Contributors listed in [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Inspired by [Project Name](link)
```

## API Stability and Versioning

### Semantic Versioning (Required)
All releases must follow [Semantic Versioning 2.0.0](https://semver.org/):
- **MAJOR**: Breaking changes to public API
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### API Stability Indicators
Document API stability in code comments:

```swift
/// Fetches user data from the server.
///
/// - Important: This API is stable and will maintain backward compatibility.
/// - Note: Available since version 1.0.0
public func fetchUser(id: UUID) async throws -> User

/// Experimental feature for batch processing.
///
/// - Warning: This API is experimental and may change in future versions.
/// - Note: Added in version 1.2.0
@available(*, message: "Experimental API - subject to change")
public func batchProcess(_ items: [Item]) async throws -> [Result]
```

### Deprecation Notices
Document deprecated APIs with migration guidance:

```swift
/// Old method for fetching data.
///
/// - Warning: Deprecated in 2.0.0. Use ``fetchUser(id:)`` instead.
/// - Note: Will be removed in version 3.0.0
@available(*, deprecated, renamed: "fetchUser(id:)", message: "Use fetchUser(id:) for improved performance")
public func getUser(_ id: UUID) async throws -> User
```

### Migration Guides
For breaking changes, create migration documentation:
- **Version-specific guides**: `Migration-1.x-to-2.x.md`
- **Change summaries**: List all breaking changes
- **Code examples**: Before/after code comparisons
- **Timeline**: Deprecation and removal schedules

### Code Documentation Standards
All public APIs and classes must include comprehensive documentation comments following Apple's Swift documentation guidelines.

### Swift Documentation Guidelines
- **Triple-slash comments (///)** for all public APIs
- **Complete parameter documentation** with types and descriptions
- **Return value documentation** for functions and computed properties
- **Error documentation** for throwing functions
- **Usage examples** for complex APIs

## DocC Documentation

Documentation must be generated using DocC, Apple's documentation compiler for Swift. All public APIs in source files must include triple-slash (///) comments structured with Markdown sections (e.g., Summary, Discussion, Parameters, Returns, Throws) as per Apple standards.

**CRITICAL REQUIREMENT**: The documentation must include comprehensive example guides that make usage accessible to developers at all experience levels. DocC is the standard documentation tool for Swift projects and significantly lowers the barrier to entry for new users.

### DocC Best Practices
- **Progressive Disclosure**: Present information from simple to complex
- **Cross-Platform Consistency**: Ensure documentation works across all supported platforms
- **Version Awareness**: Clearly indicate feature availability by platform/version
- **Interactive Elements**: Leverage DocC's capabilities for enhanced user experience
- **Comprehensive Coverage**: Document all public APIs, classes, and structs

### DocC Documentation Structure
- **Main Documentation File**: Create a main documentation file (e.g., `Documentation.md`) in the project root
- **Article Organization**: Organize documentation articles by category (Getting Started, User Guide, API Reference)
- **Code Examples**: Include practical, runnable code examples with proper Swift syntax highlighting, aligned with SwiftCodeGeneration.md patterns
- **Cross-References**: Use DocC cross-reference syntax (`<doc:ArticleName>`) for linking between articles

### DocC Generation for iOS Apps
For iOS applications, DocC documentation is generated using Xcode's toolchain with the following command:

```bash
xcodebuild docbuild -scheme YourAppScheme -destination generic/platform=iOS
```

This generates `.doccarchive` files that can be viewed in Xcode or hosted online. For Swift and Xcode version requirements, see SwiftCodeGeneration.md.

### DocC Article Requirements
Create the following documentation articles for comprehensive iOS app documentation:

- **Documentation.md** (REQUIRED): Main documentation landing page with API overview
- **Getting-Started.md** (REQUIRED): Installation and basic usage guide
- **User-Guide.md** (REQUIRED): Comprehensive user guide and feature documentation
- **API-Reference.md** (REQUIRED): Complete API reference for public interfaces
- **Migration-Guide.md**: Guide for updating between app versions (when applicable)

### DocC Metadata Standards
All public symbols must include appropriate metadata following Apple's guidelines:

```swift
/// A view model managing user authentication state.
///
/// Use this view model to handle user login, logout, and authentication state
/// management throughout the application.
///
/// ## Overview
/// The `AuthenticationViewModel` provides a centralized way to manage user
/// authentication state and coordinate authentication-related UI updates.
///
/// ## Usage
/// ```swift
/// @StateObject private var authViewModel = AuthenticationViewModel()
///
/// var body: some View {
///     if authViewModel.isAuthenticated {
///         MainView()
///     } else {
///         LoginView(viewModel: authViewModel)
///     }
/// }
/// ```
///
/// - Note: This view model requires iOS 26.0 or later.
/// - Important: Always check authentication state before accessing protected resources.
///
/// - Parameters:
///   - service: The authentication service to use for user verification
/// - Returns: An initialized authentication view model
/// - Throws: `AuthenticationError.invalidConfiguration` if the service is misconfigured
@MainActor
@Observable
public class AuthenticationViewModel {
    // Implementation
}
```

### DocC Integration Best Practices
- **Xcode Integration**: Use Xcode's built-in DocC viewer for real-time documentation preview
- **Build Integration**: Generate documentation locally during development (CI/CD pipelines excluded per project constraints)
- **Version Control**: Keep documentation synchronized with code changes
- **Accessibility**: Ensure documentation is accessible and follows WCAG guidelines
- **Localization**: Prepare documentation structure for multiple languages when needed

## Development Standards

### Code Documentation Requirements
- **View Models**: Document all observable properties and their purposes
- **UI Components**: Document customization options and usage patterns
- **Data Models**: Document all properties and relationships
- **Business Logic**: Document complex algorithms and decision points
- **Error Handling**: Document error scenarios and recovery strategies

## Claude Code Skills Documentation

This project uses Claude Code skills to enforce a specification-driven development workflow. Each skill automates a specific workflow step -- reading specs before coding, validating builds, logging errors, updating specs, and auditing quality. This section defines the documentation requirements for these skills.

### Skills Reference Table

The following table lists all project skills. This table must be kept current whenever skills are added, removed, or renamed.

| Skill | Slash Command | Purpose | Automatic Trigger | Arguments |
|-------|---------------|---------|-------------------|-----------|
| prep-for-coding | `/project:prep-for-coding <feature area>` | Reads all applicable specs and produces a synthesized implementation approach | Before writing or modifying any code | Feature or area to implement |
| validate-build | `/project:validate-build <target>` | Runs phased build validation and classifies errors against CodeLessonsLearned | After any code generation or modification | `ContentGenerator`, `LLMmanagement`, or `ProjectExchange` |
| log-error | `/project:log-error <description>` | Documents a resolved error in CodeLessonsLearned.md using the 12-field template | After resolving any compilation error, test failure, or runtime issue | Description of the error and its resolution |
| update-specs | `/project:update-specs <description>` | Updates FunctionalSpecs, SwiftTechSpecs, and CodeLessonsLearned to reflect changes and verifies cross-reference consistency | After functionality changes are complete and validated | Description of what changed |
| evaluate-specs | `/project:evaluate-specs <project or "all">` | Runs the formal 5-criterion quality evaluation from SpecificationQualitySpec.md | On-demand when explicitly requested by the user | Project name or `"all"` |
| generate-docc | `/project:generate-docc <target>` | Generates missing DocC catalogs or validates existing ones against DocumentationSpec.md | On-demand when explicitly requested by the user | `ContentGenerator`, `LLMmanagement`, or `ProjectExchange` |

### Automatic Invocation Workflow

Skills are invoked automatically at five workflow points. The root `CLAUDE.md` file is the authoritative source for when each skill fires. The workflow proceeds as follows:

1. **Before Writing or Modifying Code** -- Invoke `prep-for-coding` to read all applicable specs and produce an implementation approach. This step is required for every code change.
2. **After Generating or Modifying Code** -- Invoke `validate-build` to run phased build validation against the target project and classify any errors against CodeLessonsLearned.
3. **After Resolving Any Error** -- Invoke `log-error` to document the resolved error in CodeLessonsLearned.md using the 12-field template. Every resolved error must be logged.
4. **After Completing Functionality Changes** -- Invoke `update-specs` to update FunctionalSpecs, SwiftTechSpecs, and CodeLessonsLearned to reflect the changes and verify cross-reference consistency.
5. **On-Demand: Specification Quality Audit** -- Invoke `evaluate-specs` when explicitly requested by the user to run a formal quality evaluation.
6. **On-Demand: DocC Documentation Generation** -- Invoke `generate-docc` when explicitly requested by the user to generate or validate DocC documentation for a target project.

### Manual Invocation

Users can invoke any skill manually in the Claude Code CLI using the slash command format:

```
/project:<skill-name> <arguments>
```

For example:
- `/project:prep-for-coding authentication flow`
- `/project:validate-build ContentGenerator`
- `/project:log-error Fixed missing Sendable conformance on UserData model`
- `/project:update-specs Added project export feature`
- `/project:evaluate-specs all`

### Skill File Documentation Standards

Each skill is defined by a `SKILL.md` file located at `.claude/skills/<skill-name>/SKILL.md`. Every `SKILL.md` file must include the following:

**Required YAML Front Matter:**
- **name**: The skill's identifier (used in the slash command)
- **description**: A concise summary of what the skill does
- **argument-hint**: Placeholder text describing expected arguments

**Optional YAML Front Matter:**
- **allowed-tools**: List of Claude Code tools the skill may use (e.g., `Read, Glob, Grep`)
- **disable-model-invocation**: Set to `true` if the skill should not invoke the model autonomously

**Required Body Sections:**
- **Title**: A descriptive heading for the skill's purpose
- **Step-by-step instructions**: Numbered steps that define the skill's behavior, inputs, and outputs
- **Output format**: The expected structure of the skill's output (e.g., report template, checklist, summary format)

### Maintenance

- The **Skills Reference Table** in this section and the **Skill-Driven Development Workflow** section in the root `CLAUDE.md` must stay in sync. When a skill is added, removed, or renamed, both locations must be updated.
- Each skill's `SKILL.md` file must be updated when its behavior, arguments, or trigger conditions change.
- Changes to skill documentation should follow the same specification update workflow: invoke `/project:update-specs` after modifications are complete.

## Summary

This documentation specification provides comprehensive guidelines for documenting Swift iOS/macOS applications and Swift packages. The focus is on creating clear, user-friendly documentation that supports the entire app lifecycle from development through distribution, with specific requirements for open source projects.

Key areas covered include:
- README.md structure for repository documentation
- Beta testing documentation and guidelines (optional)
- In-app help and user onboarding
- API documentation and DocC standards
- Accessibility and localization support
- Integration with functional specifications
- Compliance with Swift-specific implementation patterns (SwiftCodeGeneration.md)
- Source file header requirements with author attribution and license reference
- **Open source repository files** (LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, CHANGELOG.md, SECURITY.md)
- **GitHub community files** (issue templates, pull request templates)
- **README enhancements for open source** (badges, acknowledgments, SPM installation)
- **API stability and versioning** (semantic versioning, deprecation notices, migration guides)
- Specification quality evaluation framework (SpecificationQualitySpec.md)
- **Claude Code skills documentation** (skills reference table, automatic invocation workflow, skill file standards, maintenance)

Following these guidelines ensures Swift applications and packages are well-documented for users, testers, contributors, and developers, facilitating effective development, community contribution, and user adoption. All documentation must remain aligned with the functional specification and Swift-specific implementation guidance (SwiftCodeGeneration.md) throughout the project lifecycle.
