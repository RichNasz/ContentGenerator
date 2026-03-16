# API Reference

Complete API documentation for all public types and methods in ProjectExchange.

## Overview

This reference documents all public APIs in the ProjectExchange package, organized by category.

## Package Information

### ProjectExchange

The root namespace providing version information.

```swift
public enum ProjectExchange {
    /// Current schema version for project exports
    public static let schemaVersion: String  // "1.0.0"

    /// Package version
    public static let version: String  // "1.0.0"
}
```

---

## Serialization

### ProjectSerializer

Handles serialization and deserialization of project data to/from JSON.

```swift
public struct ProjectSerializer: Sendable
```

#### Initialization

```swift
public init()
```

#### Export Methods

| Method | Description |
|--------|-------------|
| `export(_:) throws -> Data` | Export project to JSON Data |
| `exportToString(_:) throws -> String` | Export project to JSON String |
| `export(_:to:) throws` | Export project to file URL |

**Export to Data**

```swift
public func export(_ project: ExportableProject) throws -> Data
```

- Parameter `project`: The project to export
- Returns: JSON-encoded data
- Throws: `ProjectExchangeError.encodingFailed` if encoding fails

**Export to String**

```swift
public func exportToString(_ project: ExportableProject) throws -> String
```

- Parameter `project`: The project to export
- Returns: JSON string representation
- Throws: `ProjectExchangeError.encodingFailed` if encoding fails

**Export to File**

```swift
public func export(_ project: ExportableProject, to fileURL: URL) throws
```

- Parameters:
  - `project`: The project to export
  - `fileURL`: The destination file URL
- Throws: `ProjectExchangeError` if encoding or file writing fails

#### Import Methods

| Method | Description |
|--------|-------------|
| `importProject(from: Data) throws` | Import from JSON Data |
| `importProject(from: String) throws` | Import from JSON String |
| `importProject(from: URL) throws` | Import from file URL |

**Import from Data**

```swift
public func importProject(from data: Data) throws -> ExportableProject
```

- Parameter `data`: The JSON data to decode
- Returns: The decoded project
- Throws: `ProjectExchangeError.decodingFailed` if decoding fails

**Import from String**

```swift
public func importProject(from jsonString: String) throws -> ExportableProject
```

- Parameter `jsonString`: The JSON string to decode
- Returns: The decoded project
- Throws: `ProjectExchangeError` if the string is invalid or decoding fails

**Import from File**

```swift
public func importProject(from fileURL: URL) throws -> ExportableProject
```

- Parameter `fileURL`: The source file URL
- Returns: The decoded project
- Throws: `ProjectExchangeError` if file reading or decoding fails

#### Validation

```swift
public func validateRoundTrip(_ project: ExportableProject) -> Bool
```

- Parameter `project`: The project to validate
- Returns: `true` if the project can be encoded and decoded without data loss

---

## Models

### ExportableProject

The root transfer object for project import/export.

```swift
public struct ExportableProject: Codable, Sendable
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `schemaVersion` | `String` | Export format version |
| `name` | `String` | Project name |
| `projectDescription` | `String?` | Optional description |
| `status` | `ExportableProjectStatus` | Project status |
| `systemPrompt` | `String?` | Default LLM system prompt |
| `specification` | `ExportableSpecification?` | Project specification |
| `attachmentMetadata` | `[ExportableFileAttachment]` | File attachment metadata |
| `llmConnectionId` | `UUID?` | Reference to project LLM |
| `llmConfigurations` | `[ExportableLLMConfiguration]` | All LLM configurations |
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last modification timestamp |

#### Static Properties

```swift
public static let currentSchemaVersion: String  // "1.0.0"
```

#### Initialization

```swift
public init(
    name: String,
    projectDescription: String?,
    status: ExportableProjectStatus,
    systemPrompt: String?,
    createdAt: Date,
    modifiedAt: Date,
    specification: ExportableSpecification?,
    attachmentMetadata: [ExportableFileAttachment],
    llmConnectionId: UUID?,
    llmConfigurations: [ExportableLLMConfiguration],
    schemaVersion: String = ExportableProject.currentSchemaVersion
)
```

---

### ExportableSpecification

A content specification containing ordered sections.

```swift
public struct ExportableSpecification: Codable, Sendable
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last modification timestamp |
| `sections` | `[ExportableSection]` | Ordered sections |

#### Computed Properties

```swift
public var sortedSections: [ExportableSection]
```

Returns sections sorted by `orderIndex`.

---

### ExportableSection

A specification section for content generation.

```swift
public struct ExportableSection: Codable, Sendable
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Section title |
| `sectionDescription` | `String?` | Optional description |
| `content` | `String` | Section content |
| `orderIndex` | `Int` | Display order position |
| `contentGenerationPrompt` | `String?` | AI generation prompt |
| `contentUsagePrompt` | `String?` | Content usage prompt |
| `isEnabled` | `Bool` | Included in generation |
| `llmConnectionId` | `UUID?` | Reference to section LLM |
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last modification timestamp |

---

### ExportableLLMConfiguration

LLM connection configuration for import/export.

```swift
public struct ExportableLLMConfiguration: Codable, Sendable, Identifiable
```

> Important: API keys are **never** included in exports.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier |
| `name` | `String` | Human-readable name |
| `selectedModel` | `String` | Model identifier |
| `baseUrl` | `String` | API base URL |
| `endpointType` | `ExportableEndpointType` | Endpoint type |
| `urlPath` | `String?` | Custom URL path |
| `requestTimeoutSeconds` | `Int` | Request timeout |

#### Computed Properties

```swift
public var fullApiUrl: String
```

Returns the complete API URL constructed from `baseUrl` and `urlPath` or endpoint default.

---

### ExportableFileAttachment

File attachment metadata for import/export.

```swift
public struct ExportableFileAttachment: Codable, Sendable
```

> Note: File contents are not exported, only metadata.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `originalFileName` | `String` | Original file name |
| `originalFilePath` | `String?` | File path (informational) |
| `fileExtension` | `String?` | File extension |
| `fileSizeBytes` | `Int64` | File size in bytes |
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last modification timestamp |

#### Computed Properties

```swift
public var formattedFileSize: String
```

Returns human-readable file size (e.g., "1.2 MB").

---

## Enumerations

### ExportableProjectStatus

Project status enumeration.

```swift
public enum ExportableProjectStatus: String, Codable, Sendable, CaseIterable
```

| Case | Raw Value | Description |
|------|-----------|-------------|
| `draft` | `"draft"` | Project in draft state |
| `active` | `"active"` | Active project |
| `generating` | `"generating"` | Content generation in progress |
| `completed` | `"completed"` | Project completed |

---

### ExportableEndpointType

OpenAI endpoint type enumeration.

```swift
public enum ExportableEndpointType: String, Codable, Sendable, CaseIterable
```

| Case | Raw Value | Default Path |
|------|-----------|--------------|
| `chatCompletions` | `"chat_completions"` | `/v1/chat/completions` |
| `responses` | `"responses"` | `/v1/responses` |

#### Properties

```swift
public var displayName: String
public var defaultPath: String
```

---

## Errors

### ProjectExchangeError

Errors that can occur during import/export operations.

```swift
public enum ProjectExchangeError: LocalizedError, Sendable
```

| Case | Description |
|------|-------------|
| `encodingFailed(String)` | Failed to encode project to JSON |
| `decodingFailed(String)` | Failed to decode JSON to project |
| `invalidJSONString` | Provided string is not valid JSON |
| `schemaVersionMismatch(expected:found:)` | Schema version mismatch |
| `validationFailed(String)` | Validation of project data failed |
| `fileOperationFailed(String)` | File operation failed |

All cases provide localized error descriptions via the `errorDescription` property.

---

## See Also

- <doc:Getting-Started>
- <doc:User-Guide>
