# ProjectExchange

A Swift package for importing and exporting ContentGenerator projects to a portable JSON format.

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![visionOS 1+](https://img.shields.io/badge/visionOS-1.0+-blue.svg)

## Overview

ProjectExchange provides a structured, secure way to serialize and deserialize ContentGenerator projects for backup, sharing, and cross-application portability. The package produces human-readable JSON with schema versioning for forward compatibility.

### Key Features

- **Portable JSON Format**: Export projects to a standardized JSON format
- **Security-First Design**: API keys are never included in exports
- **Schema Versioning**: Built-in version tracking for migration support
- **Round-Trip Validation**: Verify data integrity during import/export
- **Human-Readable Output**: Pretty-printed JSON for easy inspection
- **Sendable Conformance**: Full Swift 6 concurrency support

## Installation

### Swift Package Manager

Add ProjectExchange to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../ProjectExchange")
]
```

Or add it through Xcode:
1. File > Add Package Dependencies
2. Navigate to the ProjectExchange directory
3. Add to your target

### Requirements

- Swift 6.2+
- iOS 17.0+ / macOS 14.0+ / visionOS 1.0+
- Xcode 26.1.1+

## Features

### Project Export

Export ContentGenerator projects to JSON format for backup or sharing:

```swift
import ProjectExchange

let serializer = ProjectSerializer()

// Export to Data
let jsonData = try serializer.export(project)

// Export to String
let jsonString = try serializer.exportToString(project)

// Export to file
try serializer.export(project, to: fileURL)
```

### Project Import

Import projects from JSON format:

```swift
// Import from Data
let project = try serializer.importProject(from: jsonData)

// Import from String
let project = try serializer.importProject(from: jsonString)

// Import from file
let project = try serializer.importProject(from: fileURL)
```

### What's Included in Exports

| Content | Exported |
|---------|----------|
| Project metadata (name, description, status) | Yes |
| System prompts | Yes |
| Specification sections | Yes |
| Section prompts (generation, usage) | Yes |
| LLM connection configurations | Yes (without API keys) |
| File attachment metadata | Yes (paths only) |
| API keys | **Never** |
| File contents | No |
| Generated content | No |
| Security-scoped bookmarks | No |

### Round-Trip Validation

Verify export/import data integrity:

```swift
let isValid = serializer.validateRoundTrip(project)
```

## Requirements

### Platform Support

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 17.0 |
| macOS | 14.0 |
| visionOS | 1.0 |

### Dependencies

- Foundation framework only (no external dependencies)

## Support & Contact

### Reporting Issues

For bugs or feature requests related to ProjectExchange:
1. Check existing issues in the project repository
2. Create a new issue with reproduction steps
3. Include the schema version from your export file

### Getting Help

- Review the DocC documentation in `Sources/ProjectExchange/Documentation.docc/`
- Check the inline code documentation
- Examine the test cases in `Tests/ProjectExchangeTests/`

## Privacy & Security

### Data Protection

- **No API Keys**: API keys are explicitly excluded from all exports
- **Metadata Only**: File attachments export paths only, not contents
- **No Generated Content**: Users regenerate content after import
- **No Bookmarks**: Security-scoped bookmarks are not portable and are excluded

### Post-Import Requirements

After importing a project:
1. Re-enter API keys for LLM connections
2. Re-attach files using the Locate button
3. Regenerate AI-generated content

## Schema Version

Current schema version: **1.0.0**

The `schemaVersion` field in exports enables:
- Detection of older/newer export formats
- Migration logic for compatibility
- Graceful handling of format changes

---

**Package Version**: 1.0.0
**Last Updated**: 2026-01-05
