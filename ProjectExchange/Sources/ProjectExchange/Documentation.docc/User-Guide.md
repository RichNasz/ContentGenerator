# User Guide

Comprehensive guide to using ProjectExchange for project import and export operations.

## Overview

This guide covers all aspects of using ProjectExchange, including data model design, security considerations, migration strategies, and best practices for production use.

## Understanding the Data Model

### Project Structure

An ``ExportableProject`` is the root container for all project data:

```
ExportableProject
├── schemaVersion: String
├── name: String
├── projectDescription: String?
├── status: ExportableProjectStatus
├── systemPrompt: String?
├── specification: ExportableSpecification?
│   └── sections: [ExportableSection]
├── attachmentMetadata: [ExportableFileAttachment]
├── llmConnectionId: UUID?
├── llmConfigurations: [ExportableLLMConfiguration]
├── createdAt: Date
└── modifiedAt: Date
```

### Specification Sections

Each section contains content and configuration for AI-assisted generation:

| Property | Type | Description |
|----------|------|-------------|
| `name` | String | Section title |
| `sectionDescription` | String? | Optional description |
| `content` | String | Section content text |
| `orderIndex` | Int | Display order position |
| `contentGenerationPrompt` | String? | Prompt for generating content |
| `contentUsagePrompt` | String? | Prompt for using content |
| `isEnabled` | Bool | Include in generation |
| `llmConnectionId` | UUID? | Reference to LLM for assistant |

### LLM Configurations

LLM connections are stored with the project but **never include API keys**:

```swift
let llmConfig = ExportableLLMConfiguration(
    id: UUID(),
    name: "OpenAI GPT-4",
    selectedModel: "gpt-4",
    baseUrl: "https://api.openai.com",
    endpointType: .chatCompletions,
    urlPath: nil,  // Uses default /v1/chat/completions
    requestTimeoutSeconds: 60
)
```

## Security Considerations

### What's Excluded from Exports

For security reasons, the following are **never** exported:

1. **API Keys**: Users must re-enter credentials after import
2. **Security-Scoped Bookmarks**: Not portable between machines
3. **File Contents**: Only metadata (paths, sizes) is included
4. **Generated Content**: Users regenerate after import

### Handling Sensitive Data

When integrating ProjectExchange into your application:

```swift
// Create exportable project from your internal model
func createExportable(from internalProject: ContentProject) -> ExportableProject {
    // Convert LLM connections WITHOUT API keys
    let llmConfigs = internalProject.llmConnections.map { connection in
        ExportableLLMConfiguration(
            id: connection.id,
            name: connection.name,
            selectedModel: connection.selectedModel,
            baseUrl: connection.baseUrl,
            endpointType: mapEndpointType(connection.endpointType),
            urlPath: connection.urlPath,
            requestTimeoutSeconds: connection.requestTimeoutSeconds
            // Note: apiKey is intentionally omitted
        )
    }

    return ExportableProject(
        name: internalProject.name,
        // ... other properties
        llmConfigurations: llmConfigs
    )
}
```

## Working with File Attachments

### Export Behavior

File attachments export metadata only:

```swift
let attachment = ExportableFileAttachment(
    originalFileName: "reference.txt",
    originalFilePath: "/Users/name/Documents/reference.txt",  // Informational only
    fileExtension: "txt",
    fileSizeBytes: 1024,
    createdAt: Date(),
    modifiedAt: Date()
)
```

### Post-Import Requirements

After importing a project with file attachments:

1. Display inaccessible file indicators to users
2. Provide "Locate" functionality to re-attach files
3. Validate file types match original extensions
4. Update security-scoped bookmarks for sandbox compliance

## Schema Versioning

### Version Detection

Check the schema version when importing:

```swift
let project = try serializer.importProject(from: data)

if project.schemaVersion != ExportableProject.currentSchemaVersion {
    // Handle version mismatch
    if project.schemaVersion < ExportableProject.currentSchemaVersion {
        // Older format - may need migration
        migrateFromOlderVersion(project)
    } else {
        // Newer format - may have unsupported features
        throw ProjectExchangeError.schemaVersionMismatch(
            expected: ExportableProject.currentSchemaVersion,
            found: project.schemaVersion
        )
    }
}
```

### Migration Strategy

For future schema changes, implement migration logic:

```swift
func migrateProject(_ project: ExportableProject) -> ExportableProject {
    switch project.schemaVersion {
    case "1.0.0":
        return project  // Current version
    case "0.9.0":
        return migrateFrom0_9_0(project)
    default:
        // Unknown version - attempt best-effort import
        return project
    }
}
```

## Error Handling Best Practices

### Comprehensive Error Handling

```swift
func importProjectSafely(from url: URL) -> Result<ExportableProject, Error> {
    do {
        let project = try serializer.importProject(from: url)

        // Validate round-trip integrity
        guard serializer.validateRoundTrip(project) else {
            return .failure(ProjectExchangeError.validationFailed(
                "Round-trip validation failed"
            ))
        }

        return .success(project)

    } catch let error as ProjectExchangeError {
        // Handle known errors
        return .failure(error)

    } catch {
        // Wrap unknown errors
        return .failure(ProjectExchangeError.decodingFailed(
            error.localizedDescription
        ))
    }
}
```

### User-Friendly Error Messages

Map errors to user-friendly messages:

```swift
func userMessage(for error: ProjectExchangeError) -> String {
    switch error {
    case .encodingFailed:
        return "Unable to save the project. Please try again."
    case .decodingFailed:
        return "The file appears to be corrupted or in an unsupported format."
    case .invalidJSONString:
        return "The imported text is not a valid project file."
    case .schemaVersionMismatch(_, let found):
        return "This project was created with a newer version (\(found))."
    case .validationFailed:
        return "The project data could not be verified."
    case .fileOperationFailed:
        return "Unable to access the file. Check permissions and try again."
    }
}
```

## Concurrency Support

All types in ProjectExchange conform to `Sendable` for safe use with Swift concurrency:

```swift
// Safe to use across actors
actor ProjectManager {
    private let serializer = ProjectSerializer()

    func exportProject(_ project: ExportableProject) async throws -> Data {
        try serializer.export(project)
    }

    func importProject(from url: URL) async throws -> ExportableProject {
        try serializer.importProject(from: url)
    }
}
```

## Testing Strategies

### Unit Testing Exports

```swift
import Testing
@testable import ProjectExchange

@Suite("ProjectSerializer Tests")
struct ProjectSerializerTests {

    @Test("Round-trip preserves data")
    func testRoundTrip() throws {
        let original = ExportableProject(
            name: "Test Project",
            // ... other properties
        )

        let serializer = ProjectSerializer()
        let data = try serializer.export(original)
        let imported = try serializer.importProject(from: data)

        #expect(imported.name == original.name)
        #expect(imported.schemaVersion == original.schemaVersion)
    }
}
```

### Integration Testing

```swift
@Test("File export creates valid JSON file")
func testFileExport() throws {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("test-export.json")

    defer { try? FileManager.default.removeItem(at: tempURL) }

    try serializer.export(project, to: tempURL)

    let reimported = try serializer.importProject(from: tempURL)
    #expect(reimported.name == project.name)
}
```

## See Also

- <doc:Getting-Started>
- <doc:API-Reference>
- ``ProjectSerializer``
- ``ExportableProject``
